/**
 * jobs/ndvi_cron.js
 * SAT-07 – Job periódico NDVI (cada 6 horas).
 * Se ejecuta como Cloud Scheduler → Cloud Function HTTP trigger.
 *
 * Para registrar en Firebase Scheduler:
 *   schedule: "every 6 hours"
 *   endpoint: /api/jobs/ndvi
 */

"use strict";

const { db } = require("../shared/firestore/index");
const { consultarNdvi, evaluarYActualizarTerreno } = require("../functions/satelital/index");
const { createLogger } = require("../shared/observability/logger");

const log = createLogger("ndvi-cron");

// Terrenos elegibles: estado disponible o en_espera con reserva activa
const ELIGIBLE_STATUSES = ["disponible", "reservado"];

/**
 * Punto de entrada del job NDVI.
 * Procesa en lotes para respetar límites de cuota de Copernicus.
 */
async function runNdviJob(req, res) {
  const jobId = `ndvi_${Date.now()}`;
  const startTime = Date.now();

  log.info("Job NDVI iniciado", { jobId });

  // Verificar header de autorización del Scheduler
  const schedulerSecret = req.headers["x-scheduler-secret"];
  if (schedulerSecret !== process.env.SCHEDULER_SECRET) {
    return res.status(403).json({ ok: false, message: "No autorizado" });
  }

  try {
    // Obtener terrenos activos con coordenadas
    const snap = await db.collection("terrenos")
      .where("status", "in", ELIGIBLE_STATUSES)
      .limit(50)  // Procesar de a 50 por corrida para no agotar cuota
      .get();

    if (snap.empty) {
      log.info("Sin terrenos elegibles para NDVI", { jobId });
      return res.json({ ok: true, processed: 0, jobId });
    }

    const resultados = [];
    const errores = [];

    // Procesar en serie (no en paralelo) para respetar rate limits de Copernicus
    for (const doc of snap.docs) {
      const terreno = doc.data();
      const terrenoId = doc.id;

      if (!terreno.location?.lat || !terreno.location?.lng) {
        log.warn("Terreno sin coordenadas, saltando", { terrenoId, jobId });
        continue;
      }

      try {
        const fechaFin = new Date().toISOString();
        const fechaInicio = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(); // últimos 30 días

        const ndviResult = await consultarNdvi(
          terreno.location.lat,
          terreno.location.lng,
          fechaInicio,
          fechaFin
        );

        if (ndviResult === null) {
          log.warn("Sin datos NDVI para terreno", { terrenoId, jobId });
          continue;
        }

        const resultado = await evaluarYActualizarTerreno(terrenoId, ndviResult);
        resultados.push(resultado);

        // Pausa corta entre consultas para respetar rate limits
        await _sleep(500);

      } catch (terrenoErr) {
        log.error("Error procesando terreno NDVI", {
          terrenoId,
          error: terrenoErr.message,
          jobId,
        });
        errores.push({ terrenoId, error: terrenoErr.message });
      }
    }

    // Registrar corrida del job
    await db.collection("ndvi_job_runs").add({
      jobId,
      processed: resultados.length,
      errors: errores.length,
      errorDetails: errores,
      durationMs: Date.now() - startTime,
      results: resultados,
      completedAt: new Date(),
    });

    log.info("Job NDVI completado", {
      jobId,
      processed: resultados.length,
      errors: errores.length,
      durationMs: Date.now() - startTime,
    });

    return res.json({
      ok: true,
      jobId,
      processed: resultados.length,
      errors: errores.length,
      results: resultados,
    });

  } catch (err) {
    log.error("Job NDVI fallido", { error: err.message, jobId });
    return res.status(500).json({ ok: false, error: err.message, jobId });
  }
}

function _sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

module.exports = { runNdviJob };
