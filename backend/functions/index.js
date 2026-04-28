/**
 * backend/functions/index.js
 * Punto de entrada de Cloud Functions.
 * Registra todos los routers de dominio y exporta las funciones.
 */

"use strict";

const functions = require("firebase-functions");
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

const { requestIdMiddleware } = require("../shared/observability/logger");
const { errorHandler } = require("../shared/errors");

// ─── Routers de dominio ───────────────────────────────────────────────────────
const authRouter = require("./auth/index");
const terrenosRouter = require("./terrenos/index");
const imagesRouter = require("./terrenos/images");
const pagosRouter = require("./pagos/index");
const mensajeriaRouter = require("./mensajeria/index");
const reviewsRouter = require("./reviews/index");
const recomendacionesRouter = require("./recomendaciones/index");
const { router: satelitalRouter } = require("./satelital/index");
const { processPendingNotification } = require("./notificaciones/index");
const { runNdviJob } = require("../jobs/ndvi_cron");

// ─── App Express ─────────────────────────────────────────────────────────────
const app = express();

app.use(helmet({
  contentSecurityPolicy: false, // Cloud Functions no sirve HTML
}));
app.use(cors({ origin: true }));
app.use(express.json({ limit: "1mb" }));
app.use(requestIdMiddleware);

// ─── Rutas ────────────────────────────────────────────────────────────────────
app.use("/auth", authRouter);
app.use("/terrenos", terrenosRouter);
app.use("/terrenos/:terrenoId/images", (req, res, next) => {
  // Propagar params para el sub-router de imágenes
  req.params.terrenoId = req.params.terrenoId;
  next();
}, imagesRouter);
app.use("/pagos", pagosRouter);
app.use("/mensajeria", mensajeriaRouter);
app.use("/reviews", reviewsRouter);
app.use("/recomendaciones", recomendacionesRouter);
app.use("/satelital", satelitalRouter);

// ─── Job NDVI ────────────────────────────────────────────────────────────────
app.post("/jobs/ndvi", runNdviJob);

// ─── Health check ─────────────────────────────────────────────────────────────
app.get("/health", (req, res) => {
  res.json({ ok: true, service: "cowbnb-backend", version: "1.0.0" });
});

// ─── Error handler (siempre al final) ─────────────────────────────────────────
app.use(errorHandler);

// ─── Exportar Cloud Function HTTP principal ───────────────────────────────────
exports.api = functions
  .runWith({
    timeoutSeconds: 60,
    memory: "512MB",
  })
  .https.onRequest(app);

// ─── Firestore Trigger: procesar notificaciones pendientes ────────────────────
exports.onNotificacionPendiente = functions.firestore
  .document("pending_notifications/{docId}")
  .onCreate(processPendingNotification);

// ─── Scheduler: expirar reservas (cada 5 minutos) ─────────────────────────────
exports.expirarReservas = functions
  .runWith({ timeoutSeconds: 120 })
  .pubsub.schedule("every 5 minutes")
  .onRun(async () => {
    const { db } = require("../shared/firestore/index");
    const ReservaModel = require("../models/reserva.model");
    const TerrenoModel = require("../models/terreno.model");
    const admin = require("../shared/firestore/admin");

    const now = new Date();
    const snap = await db.collection("reservas")
      .where("status", "==", ReservaModel.STATUS.EN_ESPERA)
      .where("expiresAt", "<", now)
      .limit(100)
      .get();

    if (snap.empty) return null;

    const batch = db.batch();
    const terrenoIds = [];

    snap.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: ReservaModel.STATUS.CANCELADO,
        cancelReason: "Expiración automática de ventana de pago",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      if (doc.data().terrenoId) terrenoIds.push(doc.data().terrenoId);
    });

    await batch.commit();

    const terrenoBatch = db.batch();
    for (const id of terrenoIds) {
      const entry = TerrenoModel.buildHistoryEntry("disponible", "system:scheduler", "Reserva expirada");
      terrenoBatch.update(db.collection("terrenos").doc(id), {
        status: TerrenoModel.STATUS.DISPONIBLE,
        statusHistory: admin.firestore.FieldValue.arrayUnion(entry),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await terrenoBatch.commit();

    console.log(`[scheduler] ${snap.size} reservas expiradas liberadas`);
    return null;
  });

// ─── Scheduler: job NDVI (cada 6 horas) ──────────────────────────────────────
exports.ndviScheduler = functions
  .runWith({ timeoutSeconds: 540, memory: "1GB" })
  .pubsub.schedule("every 6 hours")
  .onRun(async () => {
    const { consultarNdvi, evaluarYActualizarTerreno } = require("./satelital/index");
    const { db } = require("../shared/firestore/index");

    const snap = await db.collection("terrenos")
      .where("status", "in", ["disponible", "reservado"])
      .limit(50)
      .get();

    for (const doc of snap.docs) {
      const t = doc.data();
      if (!t.location?.lat) continue;
      try {
        const fechaFin = new Date().toISOString();
        const fechaInicio = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
        const result = await consultarNdvi(t.location.lat, t.location.lng, fechaInicio, fechaFin);
        if (result) await evaluarYActualizarTerreno(doc.id, result);
        await new Promise(r => setTimeout(r, 500));
      } catch (e) {
        console.error(`[ndvi] Error en ${doc.id}:`, e.message);
      }
    }
    return null;
  });
