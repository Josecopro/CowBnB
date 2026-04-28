/**
 * functions/terrenos/index.js
 * Módulo TERRENOS – CRUD, estados canónicos, filtros, geohash.
 * T-01 al T-06, FIL-01 al FIL-05.
 */

"use strict";

const express = require("express");
const admin = require("../../shared/firestore/admin");
const { db, buildTerrenosQuery, calcGeohash, getGeohashNeighbors } = require("../../shared/firestore/index");
const { authenticate, requireRole } = require("../../shared/auth/middleware");
const {
  validate,
  createTerrenoSchema,
  updateTerrenoSchema,
  changeStatusSchema,
} = require("../../shared/validation/index");
const {
  NotFoundError,
  ForbiddenError,
  BusinessRuleError,
} = require("../../shared/errors");
const { createLogger, logStateTransition } = require("../../shared/observability/logger");
const TerrenoModel = require("../../models/terreno.model");

const log = createLogger("terrenos");
const router = express.Router();

// ─── T-01: Crear terreno ──────────────────────────────────────────────────────
router.post("/", authenticate, requireRole("owner"), validate(createTerrenoSchema), async (req, res, next) => {
  const requestId = req.requestId;
  try {
    const terrenoData = TerrenoModel.create({ ...req.body, ownerId: req.user.uid });
    const ref = await db.collection("terrenos").add(terrenoData);

    log.info("Terreno creado", { terrenoId: ref.id, ownerId: req.user.uid, requestId });
    return res.status(201).json({
      ok: true,
      data: { id: ref.id, status: TerrenoModel.STATUS.DISPONIBLE },
      requestId,
    });
  } catch (err) {
    next(err);
  }
});

// ─── T-03: Ver detalle de terreno ─────────────────────────────────────────────
router.get("/:terrenoId", authenticate, async (req, res, next) => {
  try {
    const snap = await db.collection("terrenos").doc(req.params.terrenoId).get();
    if (!snap.exists) throw new NotFoundError("Terreno");

    const terreno = TerrenoModel.fromFirestore(snap);

    // Renters solo ven terrenos disponibles (excepto los reservados por ellos mismos)
    if (req.user.role === "renter" && terreno.status === TerrenoModel.STATUS.INACTIVO) {
      throw new NotFoundError("Terreno");
    }

    return res.json({ ok: true, data: TerrenoModel.toJson(terreno), requestId: req.requestId });
  } catch (err) {
    next(err);
  }
});

// ─── T-02: Editar terreno ─────────────────────────────────────────────────────
router.patch("/:terrenoId", authenticate, requireRole("owner"), validate(updateTerrenoSchema), async (req, res, next) => {
  const requestId = req.requestId;
  const { terrenoId } = req.params;

  try {
    const snap = await db.collection("terrenos").doc(terrenoId).get();
    if (!snap.exists) throw new NotFoundError("Terreno");

    const terreno = snap.data();
    if (terreno.ownerId !== req.user.uid) throw new ForbiddenError("No eres el propietario de este terreno");

    // Solo editable si no está reservado
    if (terreno.status === TerrenoModel.STATUS.RESERVADO) {
      throw new BusinessRuleError("No se puede editar un terreno con reserva activa");
    }

    const updateData = { ...req.body, updatedAt: admin.firestore.FieldValue.serverTimestamp() };

    // Recalcular geohash si cambia la ubicación
    if (req.body.location) {
      updateData.geohash = calcGeohash(req.body.location.lat, req.body.location.lng);
    }

    await db.collection("terrenos").doc(terrenoId).update(updateData);

    log.info("Terreno actualizado", { terrenoId, requestId });
    return res.json({ ok: true, message: "Terreno actualizado", requestId });
  } catch (err) {
    next(err);
  }
});

// ─── T-05: Cambio de estado (owner puede solo → inactivo / disponible) ────────
router.patch("/:terrenoId/status", authenticate, validate(changeStatusSchema), async (req, res, next) => {
  const requestId = req.requestId;
  const { terrenoId } = req.params;
  const { status: newStatus, reason } = req.body;

  try {
    const snap = await db.collection("terrenos").doc(terrenoId).get();
    if (!snap.exists) throw new NotFoundError("Terreno");

    const terreno = snap.data();
    if (terreno.ownerId !== req.user.uid && req.user.role !== "admin") {
      throw new ForbiddenError("Solo el propietario puede cambiar el estado");
    }

    // Validar transición. isBackend=false bloquea estados críticos (reservado, en_espera)
    // desde el cliente. El owner solo puede hacer: disponible→inactivo, inactivo→disponible.
    TerrenoModel.validateTransition(terreno.status, newStatus, false);

    const historyEntry = TerrenoModel.buildHistoryEntry(newStatus, req.user.uid, reason);

    await db.collection("terrenos").doc(terrenoId).update({
      status: newStatus,
      statusHistory: admin.firestore.FieldValue.arrayUnion(historyEntry),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await logStateTransition(db, "terrenos", terrenoId, terreno.status, newStatus, req.user.uid, requestId);

    log.info("Estado de terreno cambiado", { terrenoId, from: terreno.status, to: newStatus, requestId });
    return res.json({ ok: true, data: { status: newStatus }, requestId });
  } catch (err) {
    next(err);
  }
});

// ─── T-04: Listar terrenos con filtros (FIL-01 al FIL-05) ────────────────────
router.get("/", authenticate, async (req, res, next) => {
  const requestId = req.requestId;
  try {
    const filters = {
      status: req.query.status,
      minPrice: req.query.minPrice,
      maxPrice: req.query.maxPrice,
      minHectares: req.query.minHectares,
      maxHectares: req.query.maxHectares,
      feature: req.query.feature,
      sortBy: req.query.sortBy,
      sortDir: req.query.sortDir,
      limit: req.query.limit,
    };

    // FIL-05: Búsqueda por zona visible (geohash / bbox)
    if (req.query.lat && req.query.lng) {
      const lat = parseFloat(req.query.lat);
      const lng = parseFloat(req.query.lng);
      const neighbors = getGeohashNeighbors(calcGeohash(lat, lng));

      // Ejecutar consultas paralelas para cada geohash vecino
      const queries = neighbors.map((gh) =>
        db.collection("terrenos")
          .where("geohash", "==", gh)
          .where("status", "==", filters.status || TerrenoModel.STATUS.DISPONIBLE)
          .limit(20)
          .get()
      );
      const results = await Promise.all(queries);
      const terrenos = results.flatMap((snap) =>
        snap.docs.map((d) => TerrenoModel.toJson(TerrenoModel.fromFirestore(d)))
      );

      // Deduplicar por id
      const unique = Array.from(new Map(terrenos.map((t) => [t.id, t])).values());
      return res.json({ ok: true, data: unique, requestId });
    }

    // Consulta estándar con filtros
    const { query } = buildTerrenosQuery(filters);

    // Paginación con cursor
    let finalQuery = query;
    if (req.query.startAfterId) {
      const cursorSnap = await db.collection("terrenos").doc(req.query.startAfterId).get();
      if (cursorSnap.exists) {
        finalQuery = query.startAfter(cursorSnap);
      }
    }

    const snap = await finalQuery.get();
    const terrenos = snap.docs.map((d) => TerrenoModel.toJson(TerrenoModel.fromFirestore(d)));

    return res.json({
      ok: true,
      data: terrenos,
      pagination: {
        count: terrenos.length,
        lastId: terrenos.length > 0 ? terrenos[terrenos.length - 1].id : null,
      },
      requestId,
    });
  } catch (err) {
    next(err);
  }
});

// ─── Owner: mis terrenos ──────────────────────────────────────────────────────
router.get("/my/listings", authenticate, requireRole("owner"), async (req, res, next) => {
  try {
    const snap = await db.collection("terrenos")
      .where("ownerId", "==", req.user.uid)
      .orderBy("createdAt", "desc")
      .limit(50)
      .get();

    const terrenos = snap.docs.map((d) => TerrenoModel.toJson(TerrenoModel.fromFirestore(d)));
    return res.json({ ok: true, data: terrenos, requestId: req.requestId });
  } catch (err) {
    next(err);
  }
});

// ─── T-06: Mapeo de etiqueta legacy UI ───────────────────────────────────────
router.post("/legacy-status-map", authenticate, async (req, res, next) => {
  const { legacyLabel } = req.body;
  const canonical = TerrenoModel.mapLegacyStatus(legacyLabel);
  if (!canonical) {
    return res.status(400).json({ ok: false, message: `Etiqueta legacy desconocida: ${legacyLabel}` });
  }
  return res.json({ ok: true, data: { legacyLabel, canonicalStatus: canonical } });
});

module.exports = router;
