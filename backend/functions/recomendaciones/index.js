/**
 * functions/recomendaciones/index.js
 * Módulo RECOMENDACIONES – Señales de comportamiento + heurística v1.
 * REC-01 al REC-03.
 *
 * Heurística v1:
 * Score = (distancia_inversa × 0.4) + (rating × 0.3) + (disponible × 0.2) + (historial_reservas × 0.1)
 */

"use strict";

const express = require("express");
const admin = require("../../shared/firestore/admin");
const { db } = require("../../shared/firestore/index");
const { authenticate } = require("../../shared/auth/middleware");
const { validate, behaviorSignalSchema } = require("../../shared/validation/index");
const { createLogger } = require("../../shared/observability/logger");
const TerrenoModel = require("../../models/terreno.model");

const log = createLogger("recomendaciones");
const router = express.Router();

const TOP_N = 10;

// ─── REC-01: Capturar señal de comportamiento ─────────────────────────────────
router.post("/signals", authenticate, validate(behaviorSignalSchema), async (req, res, next) => {
  const { type, terrenoId, searchQuery } = req.body;
  const userId = req.user.uid;

  try {
    await db.collection("behavior_signals").add({
      userId,
      type,       // view | search | favorite | book
      terrenoId: terrenoId || null,
      searchQuery: searchQuery || null,
      timestamp: new Date(),
    });

    return res.status(201).json({ ok: true, requestId: req.requestId });
  } catch (err) {
    next(err);
  }
});

// ─── REC-03: Feed de recomendaciones materializado ───────────────────────────
router.get("/feed", authenticate, async (req, res, next) => {
  const userId = req.user.uid;

  try {
    // Intentar leer recomendaciones pre-calculadas
    const snap = await db.collection("recommendations")
      .where("userId", "==", userId)
      .orderBy("generatedAt", "desc")
      .limit(1)
      .get();

    if (!snap.empty) {
      const data = snap.docs[0].data();
      const ageHours = (Date.now() - data.generatedAt.toDate().getTime()) / 3600000;

      // Si el feed tiene menos de 2 horas, servir desde caché
      if (ageHours < 2) {
        return res.json({ ok: true, data: data.items, cached: true, requestId: req.requestId });
      }
    }

    // Calcular en tiempo real si no hay caché
    const items = await _calcularRecomendaciones(userId);

    // Materializar para próxima llamada
    db.collection("recommendations").add({
      userId,
      items,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }).catch(() => {});

    return res.json({ ok: true, data: items, cached: false, requestId: req.requestId });
  } catch (err) {
    next(err);
  }
});

// ─── Trigger: recalcular recomendaciones (llamado por scheduler o eventos) ────
router.post("/recalcular/:userId", async (req, res, next) => {
  const schedulerSecret = req.headers["x-scheduler-secret"];
  if (schedulerSecret !== process.env.SCHEDULER_SECRET) {
    return res.status(403).json({ ok: false });
  }

  try {
    const { userId } = req.params;
    const items = await _calcularRecomendaciones(userId);

    await db.collection("recommendations").add({
      userId,
      items,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.json({ ok: true, count: items.length, requestId: req.requestId });
  } catch (err) {
    next(err);
  }
});

// ─── REC-02: Motor heurístico v1 ──────────────────────────────────────────────
async function _calcularRecomendaciones(userId) {
  // 1. Obtener historial de señales del usuario
  const signalsSnap = await db.collection("behavior_signals")
    .where("userId", "==", userId)
    .orderBy("timestamp", "desc")
    .limit(100)
    .get();

  const signals = signalsSnap.docs.map((d) => d.data());

  // Extraer terrenos vistos/favoritos/reservados
  const viewedIds = new Set(signals.filter((s) => s.type === "view").map((s) => s.terrenoId).filter(Boolean));
  const bookedIds = new Set(signals.filter((s) => s.type === "book").map((s) => s.terrenoId).filter(Boolean));

  // 2. Obtener terrenos disponibles
  const terrenosSnap = await db.collection("terrenos")
    .where("status", "==", TerrenoModel.STATUS.DISPONIBLE)
    .orderBy("createdAt", "desc")
    .limit(100)
    .get();

  // 3. Obtener ubicación del usuario (si existe)
  const userSnap = await db.collection("users").doc(userId).get();
  const userLocation = userSnap.data()?.location ?? null;

  // 4. Calcular score heurístico por terreno
  const scored = terrenosSnap.docs.map((doc) => {
    const t = doc.data();
    const terrenoId = doc.id;

    let score = 0;
    const motivos = [];

    // Factor: distancia inversa (si hay ubicación del usuario)
    if (userLocation && t.location) {
      const dist = _haversineKm(userLocation.lat, userLocation.lng, t.location.lat, t.location.lng);
      const distScore = Math.max(0, 1 - dist / 500); // normalizado a 500km
      score += distScore * 0.4;
      if (distScore > 0.7) motivos.push("Cerca de ti");
    }

    // Factor: rating
    const ratingScore = (t.ratingAvg || 0) / 5;
    score += ratingScore * 0.3;
    if (t.ratingAvg >= 4.5) motivos.push(`Muy bien calificado (${t.ratingAvg}★)`);

    // Factor: estado disponible (ya filtrado, pero ponderamos por tiempo de disponibilidad)
    score += 0.2;

    // Factor: historial de reservas del usuario en zona similar
    if (viewedIds.has(terrenoId)) score += 0.05;
    if (bookedIds.has(terrenoId)) score -= 0.1; // ya lo reservó, bajar prioridad

    if (t.features?.includes("riego")) motivos.push("Riego disponible");
    if (t.features?.includes("certificacion")) motivos.push("Certificado orgánico");

    return {
      terrenoId,
      title: t.title,
      priceMonthly: t.priceMonthly,
      sizeHectares: t.sizeHectares,
      coverImageUrl: t.coverImageUrl,
      ratingAvg: t.ratingAvg || 0,
      location: t.location,
      features: t.features || [],
      score: Math.round(score * 100) / 100,
      motivos: motivos.slice(0, 3),
    };
  });

  // Ordenar por score descendente y tomar top N
  scored.sort((a, b) => b.score - a.score);
  return scored.slice(0, TOP_N);
}

/**
 * Distancia Haversine en kilómetros.
 */
function _haversineKm(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

module.exports = router;
