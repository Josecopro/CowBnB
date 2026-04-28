/**
 * functions/reviews/index.js
 * Módulo REVIEWS – Calificaciones post-reserva finalizada.
 * REV-01 al REV-04.
 */

"use strict";

const express = require("express");
const admin = require("../../shared/firestore/admin");
const { db, runTransaction } = require("../../shared/firestore/index");
const { authenticate } = require("../../shared/auth/middleware");
const { validate, createReviewSchema } = require("../../shared/validation/index");
const {
  NotFoundError,
  ForbiddenError,
  BusinessRuleError,
  ConflictError,
} = require("../../shared/errors");
const { createLogger } = require("../../shared/observability/logger");
const ReservaModel = require("../../models/reserva.model");

const log = createLogger("reviews");
const router = express.Router();

// Ventana de edición de review (72 horas)
const EDIT_WINDOW_HOURS = 72;

// ─── REV-01/REV-02: Crear review ─────────────────────────────────────────────
router.post("/", authenticate, validate(createReviewSchema), async (req, res, next) => {
  const requestId = req.requestId;
  const { reservaId, score, comment } = req.body;
  const reviewerId = req.user.uid;

  try {
    // Verificar que la reserva exista y sea del reviewer
    const reservaSnap = await db.collection("reservas").doc(reservaId).get();
    if (!reservaSnap.exists) throw new NotFoundError("Reserva");

    const reserva = ReservaModel.fromFirestore(reservaSnap);

    // Solo el renter puede hacer review
    if (reserva.renterId !== reviewerId) {
      throw new ForbiddenError("Solo el arrendatario puede calificar el terreno");
    }

    // La reserva debe estar finalizada
    if (reserva.status !== ReservaModel.STATUS.FINALIZADO) {
      throw new BusinessRuleError("Solo puedes calificar reservas finalizadas");
    }

    // REV-02: Anti-duplicado
    const existingSnap = await db.collection("reviews")
      .where("reservaId", "==", reservaId)
      .where("reviewerId", "==", reviewerId)
      .limit(1)
      .get();

    if (!existingSnap.empty) {
      throw new ConflictError("Ya calificaste esta reserva");
    }

    // REV-01 + REV-03: Crear review y actualizar score del terreno en transacción
    let reviewId;
    await runTransaction(async (tx) => {
      const reviewRef = db.collection("reviews").doc();
      reviewId = reviewRef.id;

      const terrenoRef = db.collection("terrenos").doc(reserva.terrenoId);
      const terrenoSnap = await tx.get(terrenoRef);

      if (!terrenoSnap.exists) throw new NotFoundError("Terreno");

      const terrenoData = terrenoSnap.data();
      const currentAvg = terrenoData.ratingAvg || 0;
      const currentCount = terrenoData.ratingCount || 0;

      // Calcular nuevo promedio incremental
      const newCount = currentCount + 1;
      const newAvg = ((currentAvg * currentCount) + score) / newCount;

      tx.set(reviewRef, {
        reservaId,
        terrenoId: reserva.terrenoId,
        ownerId: reserva.ownerId,
        reviewerId,
        score,
        comment,
        editableUntil: new Date(Date.now() + EDIT_WINDOW_HOURS * 60 * 60 * 1000),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.update(terrenoRef, {
        ratingAvg: Math.round(newAvg * 10) / 10,
        ratingCount: newCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    log.info("Review creada", { reviewId, reservaId, score, requestId });

    return res.status(201).json({
      ok: true,
      data: { id: reviewId, score, comment },
      requestId,
    });
  } catch (err) {
    next(err);
  }
});

// ─── REV-04: Listar reviews de un terreno ────────────────────────────────────
router.get("/terreno/:terrenoId", authenticate, async (req, res, next) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    let query = db.collection("reviews")
      .where("terrenoId", "==", req.params.terrenoId)
      .orderBy("createdAt", "desc")
      .limit(limit);

    if (req.query.startAfterId) {
      const cursor = await db.collection("reviews").doc(req.query.startAfterId).get();
      if (cursor.exists) query = query.startAfter(cursor);
    }

    const snap = await query.get();
    const reviews = snap.docs.map((d) => ({
      id: d.id,
      score: d.data().score,
      comment: d.data().comment,
      reviewerId: d.data().reviewerId,
      createdAt: d.data().createdAt?.toDate?.() ?? null,
    }));

    return res.json({ ok: true, data: reviews, requestId: req.requestId });
  } catch (err) {
    next(err);
  }
});

// ─── Editar review dentro de ventana de tiempo ───────────────────────────────
router.patch("/:reviewId", authenticate, async (req, res, next) => {
  const requestId = req.requestId;
  const { score, comment } = req.body;

  if (!score && !comment) {
    return res.status(400).json({ ok: false, message: "score o comment requerido" });
  }

  try {
    const reviewSnap = await db.collection("reviews").doc(req.params.reviewId).get();
    if (!reviewSnap.exists) throw new NotFoundError("Review");

    const review = reviewSnap.data();
    if (review.reviewerId !== req.user.uid) throw new ForbiddenError();

    // Verificar ventana de edición
    const editableUntil = review.editableUntil?.toDate?.();
    if (editableUntil && new Date() > editableUntil) {
      throw new BusinessRuleError("El período de edición ha vencido");
    }

    // Si cambia el score, recalcular promedio del terreno
    if (score && score !== review.score) {
      await runTransaction(async (tx) => {
        const reviewRef = db.collection("reviews").doc(req.params.reviewId);
        const terrenoRef = db.collection("terrenos").doc(review.terrenoId);

        const terrenoSnap = await tx.get(terrenoRef);
        const terrenoData = terrenoSnap.data();
        const count = terrenoData.ratingCount || 1;
        const currentAvg = terrenoData.ratingAvg || review.score;

        // Ajustar promedio
        const newAvg = ((currentAvg * count) - review.score + score) / count;

        tx.update(reviewRef, {
          score,
          ...(comment && { comment }),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        tx.update(terrenoRef, {
          ratingAvg: Math.round(newAvg * 10) / 10,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
    } else {
      await db.collection("reviews").doc(req.params.reviewId).update({
        ...(comment && { comment }),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    log.info("Review actualizada", { reviewId: req.params.reviewId, requestId });
    return res.json({ ok: true, message: "Review actualizada", requestId });
  } catch (err) {
    next(err);
  }
});

// ─── Finalizar reserva (Owner o sistema confirma fin del arriendo) ────────────
router.post("/finalizar-reserva/:reservaId", authenticate, async (req, res, next) => {
  const requestId = req.requestId;
  const { reservaId } = req.params;

  try {
    const snap = await db.collection("reservas").doc(reservaId).get();
    if (!snap.exists) throw new NotFoundError("Reserva");

    const reserva = ReservaModel.fromFirestore(snap);

    // Solo el owner puede finalizar
    if (reserva.ownerId !== req.user.uid) throw new ForbiddenError();
    if (reserva.status !== ReservaModel.STATUS.RESERVADO) {
      throw new BusinessRuleError("La reserva no está activa");
    }

    await runTransaction(async (tx) => {
      const reservaRef = db.collection("reservas").doc(reservaId);
      const terrenoRef = db.collection("terrenos").doc(reserva.terrenoId);

      const historyEntry = require("../../models/terreno.model").buildHistoryEntry(
        "disponible",
        req.user.uid,
        "Reserva finalizada por propietario"
      );

      tx.update(reservaRef, {
        status: ReservaModel.STATUS.FINALIZADO,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.update(terrenoRef, {
        status: "disponible",
        statusHistory: admin.firestore.FieldValue.arrayUnion(historyEntry),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    log.info("Reserva finalizada", { reservaId, requestId });
    return res.json({ ok: true, message: "Reserva finalizada. El arrendatario puede dejar su calificación.", requestId });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
