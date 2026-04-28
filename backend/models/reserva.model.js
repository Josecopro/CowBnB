/**
 * models/reserva.model.js
 * Modelo de reserva con estados de pago y control de expiración.
 */

"use strict";

const admin = require("../shared/firestore/admin");

const RESERVA_STATUS = {
  EN_ESPERA: "en_espera",
  RESERVADO: "reservado",
  CANCELADO: "cancelado",
  FINALIZADO: "finalizado",
};

const PAYMENT_STATUS = {
  PENDIENTE: "pendiente",
  APROBADO: "aprobado",
  RECHAZADO: "rechazado",
  REEMBOLSADO: "reembolsado",
};

// Tiempo máximo para completar el pago (30 minutos)
const EXPIRATION_MINUTES = 30;

class ReservaModel {
  static get STATUS() { return RESERVA_STATUS; }
  static get PAYMENT_STATUS() { return PAYMENT_STATUS; }

  static create({ renterId, ownerId, terrenoId, startDate, endDate, amount }) {
    const now = admin.firestore.FieldValue.serverTimestamp();
    const expiresAt = new Date(Date.now() + EXPIRATION_MINUTES * 60 * 1000);

    return {
      renterId,
      ownerId,
      terrenoId,
      startDate: new Date(startDate),
      endDate: new Date(endDate),
      amount,
      status: RESERVA_STATUS.EN_ESPERA,
      paymentStatus: PAYMENT_STATUS.PENDIENTE,
      expiresAt,
      boldReference: null,
      boldCheckoutUrl: null,
      boldEventId: null,
      cancelReason: null,
      createdAt: now,
      updatedAt: now,
    };
  }

  static fromFirestore(snap) {
    if (!snap.exists) return null;
    const d = snap.data();
    return {
      id: snap.id,
      renterId: d.renterId,
      ownerId: d.ownerId,
      terrenoId: d.terrenoId,
      startDate: d.startDate?.toDate?.() ?? null,
      endDate: d.endDate?.toDate?.() ?? null,
      amount: d.amount,
      status: d.status,
      paymentStatus: d.paymentStatus,
      expiresAt: d.expiresAt?.toDate?.() ?? null,
      boldReference: d.boldReference,
      boldCheckoutUrl: d.boldCheckoutUrl,
      boldEventId: d.boldEventId,
      cancelReason: d.cancelReason,
      createdAt: d.createdAt?.toDate?.() ?? null,
      updatedAt: d.updatedAt?.toDate?.() ?? null,
    };
  }

  static toJson(reserva) {
    return { ...reserva };
  }

  /**
   * Calcula el monto total en base a fechas (por mes completo o fracción).
   */
  static calculateAmount(priceMonthly, startDate, endDate) {
    const start = new Date(startDate);
    const end = new Date(endDate);
    const diffMs = end - start;
    const diffDays = diffMs / (1000 * 60 * 60 * 24);
    const months = diffDays / 30;
    return Math.round(priceMonthly * months * 100) / 100;
  }

  static isExpired(reserva) {
    return reserva.expiresAt && new Date() > new Date(reserva.expiresAt);
  }
}

module.exports = ReservaModel;
