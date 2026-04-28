/**
 * shared/firestore/index.js
 * Helpers para operaciones Firestore: transacciones, paginación, geohash.
 */

"use strict";

const admin = require("./admin");
const ngeohash = require("ngeohash");
const { createLogger } = require("../observability/logger");

const log = createLogger("firestore");
const db = admin.firestore();

/**
 * Ejecuta una transacción con reintentos automáticos y logging.
 */
async function runTransaction(fn, requestId) {
  try {
    return await db.runTransaction(fn);
  } catch (err) {
    log.error("Transacción fallida", { error: err.message, requestId });
    throw err;
  }
}

/**
 * Calcula geohash con precisión configurable.
 * Precisión 6 ≈ celdas de ~1.2km x 0.6km (adecuado para terrenos rurales).
 */
function calcGeohash(lat, lng, precision = 6) {
  return ngeohash.encode(lat, lng, precision);
}

/**
 * Obtiene los vecinos de un geohash para búsqueda de rango.
 */
function getGeohashNeighbors(geohash) {
  return [geohash, ...ngeohash.neighbors(geohash)];
}

/**
 * Construye query Firestore con filtros opcionales.
 * Soporta: status, minPrice, maxPrice, minHectares, maxHectares, features, geohash.
 */
function buildTerrenosQuery(filters = {}) {
  let query = db.collection("terrenos");

  // Filtro de estado (siempre aplicado para lecturas públicas)
  if (filters.status) {
    query = query.where("status", "==", filters.status);
  } else {
    // Por defecto, solo terrenos disponibles para renters
    query = query.where("status", "==", "disponible");
  }

  if (filters.geohash) {
    query = query.where("geohash", "==", filters.geohash);
  }

  if (filters.minPrice != null) {
    query = query.where("priceMonthly", ">=", Number(filters.minPrice));
  }

  if (filters.maxPrice != null) {
    query = query.where("priceMonthly", "<=", Number(filters.maxPrice));
  }

  if (filters.minHectares != null) {
    query = query.where("sizeHectares", ">=", Number(filters.minHectares));
  }

  if (filters.maxHectares != null) {
    query = query.where("sizeHectares", "<=", Number(filters.maxHectares));
  }

  // Array-contains solo acepta un valor; para múltiples features usar intersección en JS
  if (filters.feature) {
    query = query.where("features", "array-contains", filters.feature);
  }

  // Ordenamiento
  const validSortFields = ["priceMonthly", "sizeHectares", "ratingAvg", "createdAt"];
  const sortField = validSortFields.includes(filters.sortBy) ? filters.sortBy : "createdAt";
  const sortDir = filters.sortDir === "asc" ? "asc" : "desc";
  query = query.orderBy(sortField, sortDir);

  // Paginación
  const limit = Math.min(parseInt(filters.limit) || 20, 100);
  query = query.limit(limit);

  if (filters.startAfter) {
    // startAfter espera un DocumentSnapshot; se maneja en el controlador
  }

  return { query, limit };
}

/**
 * Verifica que un documento exista o lanza NotFoundError.
 */
async function getDocOrThrow(collection, docId, ErrorClass) {
  const snap = await db.collection(collection).doc(docId).get();
  if (!snap.exists) {
    throw new ErrorClass(docId);
  }
  return { id: snap.id, ...snap.data() };
}

module.exports = {
  db,
  runTransaction,
  calcGeohash,
  getGeohashNeighbors,
  buildTerrenosQuery,
  getDocOrThrow,
};
