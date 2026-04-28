/**
 * shared/idempotency/index.js
 * Garantiza procesamiento exactamente-una-vez para webhooks y eventos críticos.
 * Almacena claves en Firestore colección `idempotency_keys`.
 */

"use strict";

const { db } = require("../firestore/index");
const { IdempotencyError } = require("../errors");
const { createLogger } = require("../observability/logger");

const log = createLogger("idempotency");
const COLLECTION = "idempotency_keys";
const DEFAULT_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 días

/**
 * Verifica si una clave ya fue procesada.
 * Si no existe, crea el registro atómicamente (transacción).
 *
 * @param {string} key - Clave única del evento (ej: "bold_webhook_evt_xxx")
 * @param {object} metadata - Datos adicionales para auditoría
 * @throws {IdempotencyError} si ya fue procesada
 */
async function checkAndMark(key, metadata = {}) {
  const ref = db.collection(COLLECTION).doc(key);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists) {
      const data = snap.data();
      log.warn("Clave de idempotencia ya procesada", { key, processedAt: data.processedAt });
      throw new IdempotencyError(`Evento ya procesado: ${key}`);
    }

    tx.set(ref, {
      key,
      processedAt: new Date(),
      expiresAt: new Date(Date.now() + DEFAULT_TTL_MS),
      ...metadata,
    });
  });

  log.info("Clave de idempotencia marcada", { key });
}

/**
 * Elimina claves expiradas (llamar desde job de limpieza).
 */
async function pruneExpired() {
  const snap = await db
    .collection(COLLECTION)
    .where("expiresAt", "<", new Date())
    .limit(500)
    .get();

  if (snap.empty) return 0;

  const batch = db.batch();
  snap.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();

  log.info("Claves de idempotencia expiradas eliminadas", { count: snap.size });
  return snap.size;
}

module.exports = { checkAndMark, pruneExpired };
