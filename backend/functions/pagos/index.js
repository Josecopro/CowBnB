/**
 * functions/pagos/index.js
 * Módulo PAGOS – Reservas, checkout Bold, webhook idempotente, expiración.
 * PAY-01 al PAY-07.
 *
 * Flujo:
 * 1. POST /pagos/reservas          → crea reserva en_espera (PAY-01)
 * 2. POST /pagos/checkout/:id       → genera Bold checkout URL (PAY-02)
 * 3. POST /pagos/webhook            → recibe evento Bold, idempotente (PAY-03/04)
 * 4. POST /pagos/expirar            → (Scheduler) expira reservas vencidas (PAY-05)
 */

"use strict";

const express = require("express");
const axios = require("axios");
const admin = require("../../shared/firestore/admin");
const { db, runTransaction } = require("../../shared/firestore/index");
const { authenticate, requireRole } = require("../../shared/auth/middleware");
const { validate, createReservaSchema } = require("../../shared/validation/index");
const {
  NotFoundError,
  ForbiddenError,
  BusinessRuleError,
  ValidationError,
} = require("../../shared/errors");
const { checkAndMark } = require("../../shared/idempotency/index");
const { createLogger, logStateTransition } = require("../../shared/observability/logger");
const ReservaModel = require("../../models/reserva.model");
const TerrenoModel = require("../../models/terreno.model");

const log = createLogger("pagos");
const router = express.Router();

// ─── Config Bold ──────────────────────────────────────────────────────────────
const BOLD_API_KEY = process.env.BOLD_API_KEY;
const BOLD_BASE_URL = process.env.BOLD_BASE_URL || "https://integrations.api.bold.co";
const APP_BASE_URL = process.env.APP_BASE_URL || "https://cowbnb.co";

// ─── PAY-01: Crear intento de reserva ────────────────────────────────────────
router.post("/reservas", authenticate, requireRole("renter"), validate(createReservaSchema), async (req, res, next) => {
  const requestId = req.requestId;
  const { terrenoId, startDate, endDate } = req.body;
  const renterId = req.user.uid;

  try {
    // Verificar terreno disponible
    const terrenoSnap = await db.collection("terrenos").doc(terrenoId).get();
    if (!terrenoSnap.exists) throw new NotFoundError("Terreno");

    const terreno = terrenoSnap.data();
    if (terreno.status !== TerrenoModel.STATUS.DISPONIBLE) {
      throw new BusinessRuleError(`El terreno no está disponible (estado actual: ${terreno.status})`);
    }

    // Calcular monto
    const amount = ReservaModel.calculateAmount(terreno.priceMonthly, startDate, endDate);

    // Crear reserva en transacción atómica
    let reservaId;
    await runTransaction(async (tx) => {
      const terrenoRef = db.collection("terrenos").doc(terrenoId);
      const tSnap = await tx.get(terrenoRef);

      // Re-verificar estado dentro de la transacción
      if (tSnap.data().status !== TerrenoModel.STATUS.DISPONIBLE) {
        throw new BusinessRuleError("El terreno fue reservado por otro usuario");
      }

      const reservaRef = db.collection("reservas").doc();
      reservaId = reservaRef.id;

      const reservaData = ReservaModel.create({
        renterId,
        ownerId: terreno.ownerId,
        terrenoId,
        startDate,
        endDate,
        amount,
      });

      tx.set(reservaRef, reservaData);

      // Poner terreno en_espera para bloquear dobles reservas
      const historyEntry = TerrenoModel.buildHistoryEntry(
        TerrenoModel.STATUS.EN_ESPERA,
        "system:reserva",
        `Reserva iniciada por ${renterId}`
      );
      tx.update(terrenoRef, {
        status: TerrenoModel.STATUS.EN_ESPERA,
        statusHistory: admin.firestore.FieldValue.arrayUnion(historyEntry),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await logStateTransition(db, "terrenos", terrenoId, TerrenoModel.STATUS.DISPONIBLE, TerrenoModel.STATUS.EN_ESPERA, renterId, requestId);

    log.info("Reserva creada", { reservaId, terrenoId, renterId, amount, requestId });

    return res.status(201).json({
      ok: true,
      data: {
        reservaId,
        amount,
        currency: "COP",
        expiresIn: "30 minutos",
      },
      requestId,
    });
  } catch (err) {
    next(err);
  }
});

// ─── PAY-02: Iniciar checkout Bold ───────────────────────────────────────────
router.post("/checkout/:reservaId", authenticate, requireRole("renter"), async (req, res, next) => {
  const requestId = req.requestId;
  const { reservaId } = req.params;

  try {
    const reservaSnap = await db.collection("reservas").doc(reservaId).get();
    if (!reservaSnap.exists) throw new NotFoundError("Reserva");

    const reserva = ReservaModel.fromFirestore(reservaSnap);

    if (reserva.renterId !== req.user.uid) throw new ForbiddenError();
    if (reserva.status !== ReservaModel.STATUS.EN_ESPERA) {
      throw new BusinessRuleError(`La reserva ya no está en espera (estado: ${reserva.status})`);
    }
    if (ReservaModel.isExpired(reserva)) {
      throw new BusinessRuleError("La reserva ha expirado. Por favor crea una nueva.");
    }

    // Generar reference único: reservaId + timestamp nanosegundos
    const reference = `${reservaId}-${Date.now()}`;

    // Expiración del link = expiración de la reserva
    const expirationNano = reserva.expiresAt
      ? BigInt(reserva.expiresAt.getTime()) * 1000000n
      : BigInt(Date.now() + 30 * 60 * 1000) * 1000000n;

    const boldBody = {
      amount_type: "CLOSE",
      amount: {
        currency: "COP",
        total_amount: Math.round(reserva.amount),
        tip_amount: 0,
        taxes: [],
      },
      description: `Arriendo CowBnB - Reserva ${reservaId.slice(0, 8)}`,
      reference,
      expiration_date: expirationNano.toString(),
      callback_url: `${APP_BASE_URL}/pago/resultado?reservaId=${reservaId}`,
    };

    const boldResponse = await axios.post(`${BOLD_BASE_URL}/online/link/v1`, boldBody, {
      headers: {
        Authorization: `x-api-key ${BOLD_API_KEY}`,
        "Content-Type": "application/json",
      },
      timeout: 10000,
    });

    const { payment_link, url } = boldResponse.data.payload;

    // Guardar referencia Bold en la reserva
    await db.collection("reservas").doc(reservaId).update({
      boldReference: reference,
      boldPaymentLink: payment_link,
      boldCheckoutUrl: url,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    log.info("Checkout Bold iniciado", { reservaId, reference, requestId });

    return res.json({
      ok: true,
      data: { checkoutUrl: url, reference },
      requestId,
    });
  } catch (err) {
    // Si Bold falla, liberar el terreno
    if (err.response?.status >= 400) {
      log.error("Bold API error", { status: err.response.status, data: err.response.data, requestId });
      const reservaSnap = await db.collection("reservas").doc(req.params.reservaId).get().catch(() => null);
      if (reservaSnap?.exists) {
        const { terrenoId } = reservaSnap.data();
        await db.collection("terrenos").doc(terrenoId).update({
          status: TerrenoModel.STATUS.DISPONIBLE,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }).catch(() => {});
        await db.collection("reservas").doc(req.params.reservaId).update({
          status: ReservaModel.STATUS.CANCELADO,
          cancelReason: "Error al iniciar checkout Bold",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }).catch(() => {});
      }
      return next(new BusinessRuleError("No se pudo iniciar el pago. Inténtalo de nuevo."));
    }
    next(err);
  }
});

// ─── PAY-03 / PAY-04: Webhook Bold (público, sin authenticate) ───────────────
router.post("/webhook", async (req, res) => {
  const requestId = req.requestId;
  const evento = req.body;

  log.info("Webhook Bold recibido", {
    reference: evento.reference,
    payment_status: evento.payment_status,
    transaction_id: evento.transaction_id,
    requestId,
  });

  // Idempotencia: clave = transaction_id
  const idempotencyKey = `bold_${evento.transaction_id || evento.reference}`;

  try {
    await checkAndMark(idempotencyKey, {
      reference: evento.reference,
      status: evento.payment_status,
    });
  } catch (idempError) {
    // Ya procesado → responder 200 para que Bold no reintente
    log.info("Webhook ya procesado, ignorando", { idempotencyKey, requestId });
    return res.status(200).json({ received: true, duplicate: true });
  }

  const { reference, payment_status, transaction_id, amount } = evento;

  try {
    // Buscar reserva por boldReference
    const reservasSnap = await db.collection("reservas")
      .where("boldReference", "==", reference)
      .limit(1)
      .get();

    if (reservasSnap.empty) {
      log.warn("Webhook: reserva no encontrada para reference", { reference, requestId });
      return res.status(200).json({ received: true, warning: "Reserva no encontrada" });
    }

    const reservaDoc = reservasSnap.docs[0];
    const reserva = ReservaModel.fromFirestore(reservaDoc);

    // PAY-06: Registrar evento de pago (trazabilidad)
    await db.collection("payment_events").add({
      eventId: idempotencyKey,
      reservaId: reservaDoc.id,
      boldReference: reference,
      boldTransactionId: transaction_id,
      status: payment_status,
      amount,
      rawPayload: evento,
      processedAt: new Date(),
      requestId,
    });

    if (payment_status === "APPROVED") {
      // PAY-04: Transacción atómica: reserva → reservado + terreno → reservado
      await runTransaction(async (tx) => {
        const reservaRef = db.collection("reservas").doc(reservaDoc.id);
        const terrenoRef = db.collection("terrenos").doc(reserva.terrenoId);

        const [rSnap, tSnap] = await Promise.all([tx.get(reservaRef), tx.get(terrenoRef)]);

        if (!rSnap.exists || !tSnap.exists) throw new Error("Documentos no encontrados en transacción");

        const historyEntry = TerrenoModel.buildHistoryEntry(
          TerrenoModel.STATUS.RESERVADO,
          "system:webhook",
          `Pago aprobado. Transaction: ${transaction_id}`
        );

        tx.update(reservaRef, {
          status: ReservaModel.STATUS.RESERVADO,
          paymentStatus: ReservaModel.PAYMENT_STATUS.APROBADO,
          boldEventId: transaction_id,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        tx.update(terrenoRef, {
          status: TerrenoModel.STATUS.RESERVADO,
          statusHistory: admin.firestore.FieldValue.arrayUnion(historyEntry),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      // Crear conversación automática (MSG-01)
      await _crearConversacionReserva(reservaDoc.id, reserva);

      // Notificación push al owner y renter
      await _notificarPagoAprobado(reserva, transaction_id);

      await logStateTransition(db, "reservas", reservaDoc.id, ReservaModel.STATUS.EN_ESPERA, ReservaModel.STATUS.RESERVADO, "system:webhook", requestId);
      log.info("Reserva confirmada por pago", { reservaId: reservaDoc.id, requestId });

    } else if (["REJECTED", "FAILED"].includes(payment_status)) {
      // Liberar terreno y cancelar reserva
      await runTransaction(async (tx) => {
        const reservaRef = db.collection("reservas").doc(reservaDoc.id);
        const terrenoRef = db.collection("terrenos").doc(reserva.terrenoId);

        const historyEntry = TerrenoModel.buildHistoryEntry(
          TerrenoModel.STATUS.DISPONIBLE,
          "system:webhook",
          `Pago ${payment_status}`
        );

        tx.update(reservaRef, {
          status: ReservaModel.STATUS.CANCELADO,
          paymentStatus: payment_status === "REJECTED"
            ? ReservaModel.PAYMENT_STATUS.RECHAZADO
            : "fallido",
          cancelReason: `Pago ${payment_status} por Bold`,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        tx.update(terrenoRef, {
          status: TerrenoModel.STATUS.DISPONIBLE,
          statusHistory: admin.firestore.FieldValue.arrayUnion(historyEntry),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      log.info("Reserva cancelada por pago fallido", { reservaId: reservaDoc.id, payment_status, requestId });
    }

    return res.status(200).json({ received: true });

  } catch (err) {
    log.error("Error procesando webhook Bold", { error: err.message, reference, requestId });
    // Responder 200 de todos modos para evitar reintentos infinitos de Bold
    // pero registrar el error para reconciliación manual
    await db.collection("webhook_errors").add({
      reference,
      error: err.message,
      payload: evento,
      timestamp: new Date(),
    }).catch(() => {});
    return res.status(200).json({ received: true, error: "procesamiento_fallido" });
  }
});

// ─── PAY-05: Expirar reservas pendientes (llamado por Scheduler) ─────────────
router.post("/expirar", async (req, res, next) => {
  // Solo callable desde el Scheduler (verificar header interno)
  const schedulerSecret = req.headers["x-scheduler-secret"];
  if (schedulerSecret !== process.env.SCHEDULER_SECRET) {
    return res.status(403).json({ ok: false, message: "No autorizado" });
  }

  try {
    const now = new Date();
    const snap = await db.collection("reservas")
      .where("status", "==", ReservaModel.STATUS.EN_ESPERA)
      .where("expiresAt", "<", now)
      .limit(100)
      .get();

    if (snap.empty) {
      log.info("No hay reservas expiradas", { requestId: req.requestId });
      return res.json({ ok: true, expired: 0 });
    }

    const batch = db.batch();
    const terrenoIds = [];

    snap.docs.forEach((doc) => {
      const data = doc.data();
      batch.update(doc.ref, {
        status: ReservaModel.STATUS.CANCELADO,
        cancelReason: "Expiración de ventana de pago",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      if (data.terrenoId) terrenoIds.push(data.terrenoId);
    });

    await batch.commit();

    // Liberar terrenos en lote
    const terrenoBatch = db.batch();
    for (const terrenoId of terrenoIds) {
      const ref = db.collection("terrenos").doc(terrenoId);
      const historyEntry = TerrenoModel.buildHistoryEntry(
        TerrenoModel.STATUS.DISPONIBLE,
        "system:scheduler",
        "Reserva expirada"
      );
      terrenoBatch.update(ref, {
        status: TerrenoModel.STATUS.DISPONIBLE,
        statusHistory: admin.firestore.FieldValue.arrayUnion(historyEntry),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await terrenoBatch.commit();

    log.info("Reservas expiradas procesadas", { count: snap.size, requestId: req.requestId });
    return res.json({ ok: true, expired: snap.size });

  } catch (err) {
    next(err);
  }
});

// ─── Consultar estado de reserva (para pagos_result UI) ───────────────────────
router.get("/reservas/:reservaId", authenticate, async (req, res, next) => {
  try {
    const snap = await db.collection("reservas").doc(req.params.reservaId).get();
    if (!snap.exists) throw new NotFoundError("Reserva");

    const reserva = ReservaModel.fromFirestore(snap);

    // Solo owner o renter de la reserva pueden verla
    if (reserva.renterId !== req.user.uid && reserva.ownerId !== req.user.uid) {
      throw new ForbiddenError();
    }

    return res.json({ ok: true, data: ReservaModel.toJson(reserva), requestId: req.requestId });
  } catch (err) {
    next(err);
  }
});

// ─── Listar reservas del renter ───────────────────────────────────────────────
router.get("/mis-reservas", authenticate, requireRole("renter"), async (req, res, next) => {
  try {
    const snap = await db.collection("reservas")
      .where("renterId", "==", req.user.uid)
      .orderBy("createdAt", "desc")
      .limit(50)
      .get();

    const reservas = snap.docs.map((d) => ReservaModel.toJson(ReservaModel.fromFirestore(d)));
    return res.json({ ok: true, data: reservas, requestId: req.requestId });
  } catch (err) {
    next(err);
  }
});

// ─── Helpers internos ─────────────────────────────────────────────────────────

async function _crearConversacionReserva(reservaId, reserva) {
  try {
    // Verificar que no existe ya
    const existing = await db.collection("conversaciones")
      .where("reservaId", "==", reservaId)
      .limit(1)
      .get();

    if (!existing.empty) return;

    await db.collection("conversaciones").add({
      reservaId,
      terrenoId: reserva.terrenoId,
      ownerId: reserva.ownerId,
      renterId: reserva.renterId,
      lastMessageAt: null,
      lastMessageText: null,
      unreadOwner: 0,
      unreadRenter: 0,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    log.info("Conversación creada para reserva", { reservaId });
  } catch (err) {
    log.warn("No se pudo crear conversación automática", { error: err.message, reservaId });
  }
}

async function _notificarPagoAprobado(reserva, transactionId) {
  try {
    // Obtener tokens FCM de owner y renter
    const [ownerSnap, renterSnap] = await Promise.all([
      db.collection("users").doc(reserva.ownerId).get(),
      db.collection("users").doc(reserva.renterId).get(),
    ]);

    const tokens = [
      ...((ownerSnap.data()?.fcmTokens) || []),
      ...((renterSnap.data()?.fcmTokens) || []),
    ].filter(Boolean);

    if (tokens.length === 0) return;

    // Guardar notificación en Firestore para procesamiento
    await db.collection("pending_notifications").add({
      tokens,
      title: "Reserva Confirmada",
      body: `Tu reserva fue confirmada. Transacción: ${transactionId}`,
      data: { reservaId: reserva.id, type: "reserva_confirmada" },
      createdAt: new Date(),
    });
  } catch (err) {
    log.warn("Error preparando notificación de pago", { error: err.message });
  }
}

module.exports = router;
