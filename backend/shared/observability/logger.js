/**
 * shared/observability/logger.js
 * Logger estructurado por dominio con requestId.
 * Emite JSON para ingestión en Cloud Logging / cualquier agregador.
 */

"use strict";

const LOG_LEVEL_ORDER = { debug: 0, info: 1, warn: 2, error: 3 };
const CURRENT_LEVEL = LOG_LEVEL_ORDER[process.env.LOG_LEVEL || "info"] ?? 1;

function emit(level, domain, message, meta = {}) {
  if (LOG_LEVEL_ORDER[level] < CURRENT_LEVEL) return;

  const entry = {
    severity: level.toUpperCase(),
    domain,
    message,
    timestamp: new Date().toISOString(),
    ...meta,
  };

  // Cloud Logging captura stdout estructurado automáticamente
  if (level === "error") {
    console.error(JSON.stringify(entry));
  } else {
    console.log(JSON.stringify(entry));
  }
}

/**
 * Crea un logger específico de dominio.
 * Uso: const log = createLogger("terrenos");
 *      log.info("Terreno creado", { terrenoId, requestId });
 */
function createLogger(domain) {
  return {
    debug: (msg, meta) => emit("debug", domain, msg, meta),
    info: (msg, meta) => emit("info", domain, msg, meta),
    warn: (msg, meta) => emit("warn", domain, msg, meta),
    error: (msg, meta) => emit("error", domain, msg, meta),
  };
}

/**
 * Middleware Express que inyecta requestId en cada solicitud.
 */
const { v4: uuidv4 } = require("uuid");

function requestIdMiddleware(req, res, next) {
  req.requestId = req.headers["x-request-id"] || uuidv4();
  res.setHeader("x-request-id", req.requestId);
  next();
}

/**
 * Registra transiciones de estado (auditoría).
 */
async function logStateTransition(db, collection, docId, fromStatus, toStatus, actorId, requestId) {
  try {
    await db.collection("state_transitions").add({
      collection,
      docId,
      fromStatus,
      toStatus,
      actorId,
      requestId,
      timestamp: new Date(),
    });
  } catch (e) {
    // No debe romper el flujo principal
    emit("warn", "observability", "No se pudo registrar transición de estado", {
      error: e.message,
      docId,
    });
  }
}

module.exports = { createLogger, requestIdMiddleware, logStateTransition };
