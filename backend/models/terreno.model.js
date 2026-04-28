/**
 * models/terreno.model.js
 * Modelo de terreno con máquina de estados canónicos y mapeo legacy UI.
 */

"use strict";

const admin = require("../shared/firestore/admin");

// ─── Estados canónicos ────────────────────────────────────────────────────────
const STATUS = {
  DISPONIBLE: "disponible",
  RESERVADO: "reservado",
  EN_ESPERA: "en_espera",
  INACTIVO: "inactivo",
};

// Mapeo de etiquetas legacy del frontend (UI actual) a estados canónicos
const LEGACY_UI_MAP = {
  Activo: STATUS.DISPONIBLE,
  Confirmado: STATUS.RESERVADO,
  Pendiente: STATUS.EN_ESPERA,
};

// Transiciones válidas (origen → destinos permitidos)
const VALID_TRANSITIONS = {
  [STATUS.DISPONIBLE]: [STATUS.EN_ESPERA, STATUS.RESERVADO, STATUS.INACTIVO],
  [STATUS.EN_ESPERA]: [STATUS.DISPONIBLE, STATUS.RESERVADO, STATUS.INACTIVO],
  [STATUS.RESERVADO]: [STATUS.DISPONIBLE, STATUS.INACTIVO],
  [STATUS.INACTIVO]: [STATUS.DISPONIBLE],
};

// Transiciones que solo puede hacer el backend (no directamente el owner)
const BACKEND_ONLY_TRANSITIONS = [STATUS.RESERVADO, STATUS.EN_ESPERA];

class TerrenoModel {
  static get STATUS() { return STATUS; }
  static get LEGACY_UI_MAP() { return LEGACY_UI_MAP; }

  /**
   * Crea la estructura canónica de un terreno nuevo.
   */
  static create({ ownerId, title, description, sizeHectares, priceMonthly, features, location, address }) {
    const now = admin.firestore.FieldValue.serverTimestamp();
    const geohash = require("../shared/firestore/index").calcGeohash(location.lat, location.lng);
    return {
      ownerId,
      title,
      description,
      sizeHectares,
      priceMonthly,
      features: features || [],
      location,
      address: address || null,
      geohash,
      status: STATUS.DISPONIBLE,
      images: [],        // [{ id, url, storagePath, uploadedAt }]
      coverImageUrl: null,
      ratingAvg: 0,
      ratingCount: 0,
      ndviScore: null,
      ndviLastCheckedAt: null,
      statusHistory: [
        {
          status: STATUS.DISPONIBLE,
          changedAt: new Date().toISOString(),
          changedBy: "system:create",
          reason: "Terreno creado",
        },
      ],
      createdAt: now,
      updatedAt: now,
    };
  }

  static fromFirestore(snap) {
    if (!snap.exists) return null;
    const d = snap.data();
    return {
      id: snap.id,
      ownerId: d.ownerId,
      title: d.title,
      description: d.description,
      sizeHectares: d.sizeHectares,
      priceMonthly: d.priceMonthly,
      features: d.features || [],
      location: d.location,
      address: d.address,
      geohash: d.geohash,
      status: d.status,
      images: d.images || [],
      coverImageUrl: d.coverImageUrl ?? null,
      ratingAvg: d.ratingAvg ?? 0,
      ratingCount: d.ratingCount ?? 0,
      ndviScore: d.ndviScore ?? null,
      ndviLastCheckedAt: d.ndviLastCheckedAt?.toDate?.() ?? null,
      statusHistory: d.statusHistory || [],
      createdAt: d.createdAt?.toDate?.() ?? null,
      updatedAt: d.updatedAt?.toDate?.() ?? null,
    };
  }

  static toJson(terreno) {
    return { ...terreno };
  }

  /**
   * Valida si la transición de estado es permitida.
   * @param {string} from - Estado actual
   * @param {string} to - Estado destino
   * @param {boolean} isBackend - true si lo ejecuta el backend (Cloud Function)
   */
  static validateTransition(from, to, isBackend = false) {
    const allowed = VALID_TRANSITIONS[from] || [];
    if (!allowed.includes(to)) {
      throw new Error(`Transición inválida: ${from} → ${to}`);
    }
    if (!isBackend && BACKEND_ONLY_TRANSITIONS.includes(to)) {
      throw new Error(`La transición a '${to}' solo puede ser iniciada por el backend`);
    }
    return true;
  }

  /**
   * Mapea label legacy UI al estado canónico.
   */
  static mapLegacyStatus(legacyLabel) {
    return LEGACY_UI_MAP[legacyLabel] ?? null;
  }

  /**
   * Construye una entrada de historial de estado.
   */
  static buildHistoryEntry(status, actorId, reason = "") {
    return {
      status,
      changedAt: new Date().toISOString(),
      changedBy: actorId,
      reason,
    };
  }
}

module.exports = TerrenoModel;
