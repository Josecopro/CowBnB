/**
 * functions/satelital/index.js
 * Módulo SATELITAL – Cliente Copernicus, evaluación NDVI, tokens one-time.
 * SAT-01 al SAT-07.
 *
 * Flujo NDVI:
 * 1. Job periódico (ndvi_cron.js) llama a runNdviCheck(terrenoId)
 * 2. Se consulta Copernicus → se calcula NDVI
 * 3. Si NDVI < umbral → terreno pasa a en_espera + email con token one-time
 * 4. Owner decide via link firmado → confirmarAccion(token, accion)
 */

"use strict";

const express = require("express");
const axios = require("axios");
const crypto = require("crypto");
const admin = require("../../shared/firestore/admin");
const { db, runTransaction } = require("../../shared/firestore/index");
const { createLogger, logStateTransition } = require("../../shared/observability/logger");
const TerrenoModel = require("../../models/terreno.model");
const { NotFoundError, BusinessRuleError } = require("../../shared/errors");
const { authenticate, requireRole } = require("../../shared/auth/middleware");

const log = createLogger("satelital");
const router = express.Router();

// ─── Config ───────────────────────────────────────────────────────────────────
const COPERNICUS_TOKEN_URL = process.env.COPERNICUS_TOKEN_URL ||
  "https://identity.dataspace.copernicus.eu/auth/realms/CDSE/protocol/openid-connect/token";
const COPERNICUS_STAC_URL = process.env.COPERNICUS_STAC_URL ||
  "https://catalogue.dataspace.copernicus.eu/odata/v1";
const NDVI_THRESHOLD = parseFloat(process.env.NDVI_THRESHOLD || "0.3");
const ACTION_TOKEN_TTL_HOURS = parseInt(process.env.NDVI_ACTION_TOKEN_TTL_HOURS || "48");
const APP_BASE_URL = process.env.APP_BASE_URL || "https://cowbnb.co";

// Cache de token Copernicus (en memoria, válido ~1h)
let _copernicusToken = null;
let _copernicusTokenExpiry = 0;

// ─── SAT-01: Obtener token Copernicus ─────────────────────────────────────────
async function getCopernicusToken() {
  if (_copernicusToken && Date.now() < _copernicusTokenExpiry - 60000) {
    return _copernicusToken;
  }

  const params = new URLSearchParams({
    grant_type: "client_credentials",
    client_id: process.env.COPERNICUS_CLIENT_ID,
    client_secret: process.env.COPERNICUS_CLIENT_SECRET,
  });

  const response = await axios.post(COPERNICUS_TOKEN_URL, params.toString(), {
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    timeout: 10000,
  });

  _copernicusToken = response.data.access_token;
  _copernicusTokenExpiry = Date.now() + (response.data.expires_in * 1000);

  log.info("Token Copernicus renovado");
  return _copernicusToken;
}

// ─── SAT-02: Consultar NDVI vía Copernicus STAC ───────────────────────────────
async function consultarNdvi(lat, lng, fechaInicio, fechaFin) {
  const token = await getCopernicusToken();

  // Construir bounding box 0.05° alrededor del punto (~5km)
  const delta = 0.05;
  const bbox = `${lng - delta},${lat - delta},${lng + delta},${lat + delta}`;

  // Buscar producto Sentinel-2 disponible
  const searchUrl = `${COPERNICUS_STAC_URL}/Products?$filter=` +
    `Collection/Name eq 'SENTINEL-2' and ` +
    `Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'productType' and att/OData.CSC.StringAttribute/Value eq 'S2MSI2A') and ` +
    `ContentDate/Start ge ${fechaInicio} and ContentDate/Start le ${fechaFin} and ` +
    `OData.CSC.Intersects(area=geography'SRID=4326;POINT(${lng} ${lat})')` +
    `&$orderby=ContentDate/Start desc&$top=1&$expand=Attributes`;

  const searchResponse = await axios.get(searchUrl, {
    headers: { Authorization: `Bearer ${token}` },
    timeout: 15000,
  });

  const products = searchResponse.data?.value || [];
  if (products.length === 0) {
    log.warn("Sin productos Sentinel-2 disponibles para coordenadas", { lat, lng });
    return null;
  }

  const product = products[0];
  const productId = product.Id;

  // Obtener metadatos de bandas para calcular NDVI estimado
  // En producción real se descargaría la imagen y calcularía pixel a pixel.
  // Aquí usamos el Cloud Coverage + fecha como proxy conservador.
  const cloudCoverage = product.Attributes?.find?.(
    (a) => a.Name === "cloudCover"
  )?.Value ?? 50;

  if (parseFloat(cloudCoverage) > 80) {
    log.warn("Cobertura de nubes alta, NDVI no confiable", { cloudCoverage, productId });
    return { ndvi: null, productId, reason: "alta_cobertura_nubes", cloudCoverage };
  }

  // NDVI simulado basado en metadata disponible sin descarga completa
  // En producción: descargar bandas B04 (rojo) y B08 (NIR) y calcular:
  // NDVI = (B08 - B04) / (B08 + B04)
  // Por ahora retornamos metadata + flag para que el job decida
  const ndviEstimado = await _estimarNdviDesdeMeta(product, token);

  return {
    ndvi: ndviEstimado,
    productId,
    date: product.ContentDate?.Start,
    cloudCoverage: parseFloat(cloudCoverage),
  };
}

async function _estimarNdviDesdeMeta(product, token) {
  // En una implementación completa:
  // 1. Descargar thumbnail del producto
  // 2. Analizar canal rojo vs infrarrojo cercano
  // 3. Retornar NDVI real
  //
  // Por ahora retornamos un valor placeholder que el job puede usar.
  // El umbral configurable permite ajustar sensibilidad.
  return 0.35; // placeholder — reemplazar con lógica real de procesamiento de imagen
}

// ─── SAT-03/SAT-04: Evaluar umbral y cambiar estado ──────────────────────────
async function evaluarYActualizarTerreno(terrenoId, ndviResult) {
  const snap = await db.collection("terrenos").doc(terrenoId).get();
  if (!snap.exists) throw new NotFoundError("Terreno");

  const terreno = snap.data();
  const ndvi = ndviResult?.ndvi;

  // Registrar check NDVI siempre
  const checkRef = db.collection("ndvi_checks").doc();
  const decision = ndvi === null ? "sin_datos" : (ndvi < NDVI_THRESHOLD ? "riesgo" : "ok");

  await checkRef.set({
    terrenoId,
    ndvi,
    threshold: NDVI_THRESHOLD,
    decision,
    productId: ndviResult?.productId ?? null,
    date: ndviResult?.date ?? null,
    cloudCoverage: ndviResult?.cloudCoverage ?? null,
    createdAt: new Date(),
  });

  // Actualizar metadata NDVI en terreno
  await db.collection("terrenos").doc(terrenoId).update({
    ndviScore: ndvi,
    ndviLastCheckedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  if (decision === "riesgo" && terreno.status === TerrenoModel.STATUS.DISPONIBLE) {
    // SAT-04: Mover a en_espera
    await runTransaction(async (tx) => {
      const ref = db.collection("terrenos").doc(terrenoId);
      const historyEntry = TerrenoModel.buildHistoryEntry(
        TerrenoModel.STATUS.EN_ESPERA,
        "system:ndvi",
        `NDVI bajo umbral: ${ndvi} < ${NDVI_THRESHOLD}`
      );
      tx.update(ref, {
        status: TerrenoModel.STATUS.EN_ESPERA,
        statusHistory: admin.firestore.FieldValue.arrayUnion(historyEntry),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await logStateTransition(db, "terrenos", terrenoId, TerrenoModel.STATUS.DISPONIBLE, TerrenoModel.STATUS.EN_ESPERA, "system:ndvi", checkRef.id);

    // SAT-05: Enviar email con token one-time
    await _generarYEnviarTokenAccion(terrenoId, terreno.ownerId, ndvi);

    log.info("Terreno movido a en_espera por NDVI bajo", { terrenoId, ndvi });
  }

  log.info("Check NDVI completado", { terrenoId, ndvi, decision });
  return { terrenoId, ndvi, decision };
}

// ─── SAT-05: Generar token one-time y enviar email ────────────────────────────
async function _generarYEnviarTokenAccion(terrenoId, ownerId, ndvi) {
  // Generar token aleatorio
  const rawToken = crypto.randomBytes(32).toString("hex");
  const hashedToken = crypto.createHash("sha256").update(rawToken).digest("hex");

  const expiresAt = new Date(Date.now() + ACTION_TOKEN_TTL_HOURS * 60 * 60 * 1000);

  // Guardar hash (nunca el token en claro)
  await db.collection("action_tokens").add({
    tokenHash: hashedToken,
    terrenoId,
    ownerId,
    action: "ndvi_review",
    used: false,
    expiresAt,
    createdAt: new Date(),
  });

  // Construir link de acción
  const confirmUrl = `${APP_BASE_URL}/satelital/confirmar?token=${rawToken}&terrenoId=${terrenoId}`;
  const reactivarUrl = `${APP_BASE_URL}/satelital/confirmar?token=${rawToken}&terrenoId=${terrenoId}&accion=reactivar`;

  // Obtener email del owner
  const ownerSnap = await db.collection("users").doc(ownerId).get();
  const email = ownerSnap.data()?.email;

  if (email) {
    await db.collection("pending_emails").add({
      to: email,
      subject: "Alerta NDVI – Revisión requerida para tu terreno",
      template: "ndvi_alert",
      data: {
        ownerName: ownerSnap.data()?.fullName || "Propietario",
        terrenoId,
        ndvi: ndvi?.toFixed(3),
        threshold: NDVI_THRESHOLD,
        confirmUrl,
        reactivarUrl,
        expiresAt: expiresAt.toISOString(),
      },
      createdAt: new Date(),
    });
  }

  log.info("Token NDVI generado y email enqueued", { terrenoId, ownerId });
}

// ─── SAT-06: Confirmar/reactivar vía token one-time ──────────────────────────
router.post("/confirmar", async (req, res, next) => {
  const { token, terrenoId, accion } = req.body;
  const requestId = req.requestId;

  if (!token || !terrenoId) {
    return res.status(400).json({ ok: false, message: "token y terrenoId requeridos" });
  }

  const hashedToken = crypto.createHash("sha256").update(token).digest("hex");

  try {
    // Buscar token en Firestore
    const tokenSnap = await db.collection("action_tokens")
      .where("tokenHash", "==", hashedToken)
      .where("terrenoId", "==", terrenoId)
      .where("used", "==", false)
      .limit(1)
      .get();

    if (tokenSnap.empty) {
      return res.status(400).json({ ok: false, message: "Token inválido o ya utilizado" });
    }

    const tokenDoc = tokenSnap.docs[0];
    const tokenData = tokenDoc.data();

    // Verificar expiración
    if (new Date() > tokenData.expiresAt.toDate()) {
      return res.status(400).json({ ok: false, message: "Token expirado" });
    }

    // Consumir token (one-time)
    await tokenDoc.ref.update({ used: true, usedAt: new Date() });

    // Determinar acción
    const accionFinal = accion === "reactivar" ? TerrenoModel.STATUS.DISPONIBLE : TerrenoModel.STATUS.EN_ESPERA;

    // Actualizar estado del terreno
    const historyEntry = TerrenoModel.buildHistoryEntry(
      accionFinal,
      `owner:${tokenData.ownerId}`,
      `Confirmación via token NDVI. Acción: ${accion || "revisar"}`
    );

    await db.collection("terrenos").doc(terrenoId).update({
      status: accionFinal,
      statusHistory: admin.firestore.FieldValue.arrayUnion(historyEntry),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    log.info("Token NDVI consumido", { terrenoId, accion: accionFinal, requestId });

    return res.json({
      ok: true,
      message: accionFinal === TerrenoModel.STATUS.DISPONIBLE
        ? "Terreno reactivado exitosamente"
        : "Revisión registrada. El terreno permanece en espera.",
      data: { status: accionFinal },
      requestId,
    });
  } catch (err) {
    next(err);
  }
});

// ─── Consultar estado satelital del terreno (para UI satelital_status) ────────
router.get("/status/:terrenoId", authenticate, async (req, res, next) => {
  const { terrenoId } = req.params;
  try {
    const snap = await db.collection("ndvi_checks")
      .where("terrenoId", "==", terrenoId)
      .orderBy("createdAt", "desc")
      .limit(10)
      .get();

    const checks = snap.docs.map((d) => ({
      id: d.id,
      ndvi: d.data().ndvi,
      decision: d.data().decision,
      date: d.data().date,
      createdAt: d.data().createdAt?.toDate?.() ?? null,
    }));

    return res.json({ ok: true, data: { terrenoId, checks }, requestId: req.requestId });
  } catch (err) {
    next(err);
  }
});

module.exports = {
  router,
  getCopernicusToken,
  consultarNdvi,
  evaluarYActualizarTerreno,
};
