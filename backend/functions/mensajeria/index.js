/**
 * functions/mensajeria/index.js
 * Módulo MENSAJERÍA – Conversaciones PTP vinculadas a reserva.
 * MSG-01 al MSG-05.
 *
 * Regla de acceso: solo owner y renter de la reserva vinculada.
 * No existe chat sin contexto de reserva.
 */

"use strict";

const express = require("express");
const admin = require("../../shared/firestore/admin");
const { db } = require("../../shared/firestore/index");
const { authenticate } = require("../../shared/auth/middleware");
const { validate, sendMessageSchema } = require("../../shared/validation/index");
const {
  NotFoundError,
  ForbiddenError,
  BusinessRuleError,
} = require("../../shared/errors");
const { createLogger } = require("../../shared/observability/logger");

const log = createLogger("mensajeria");
const router = express.Router();

// Límite de mensajes por minuto por usuario (anti-abuso)
const RATE_LIMIT_MAP = new Map();
const MAX_MSGS_PER_MINUTE = 20;

function checkRateLimit(userId) {
  const now = Date.now();
  const key = `${userId}:${Math.floor(now / 60000)}`; // ventana por minuto
  const count = (RATE_LIMIT_MAP.get(key) || 0) + 1;
  RATE_LIMIT_MAP.set(key, count);
  // Limpiar entradas antiguas (máx 200 en memoria)
  if (RATE_LIMIT_MAP.size > 200) {
    const oldest = [...RATE_LIMIT_MAP.keys()][0];
    RATE_LIMIT_MAP.delete(oldest);
  }
  return count <= MAX_MSGS_PER_MINUTE;
}

// ─── Helper: verificar participante ──────────────────────────────────────────
async function getConversacionOrThrow(conversationId, userId) {
  const snap = await db.collection("conversaciones").doc(conversationId).get();
  if (!snap.exists) throw new NotFoundError("Conversación");

  const conv = { id: snap.id, ...snap.data() };
  if (conv.ownerId !== userId && conv.renterId !== userId) {
    throw new ForbiddenError("No eres participante de esta conversación");
  }
  return conv;
}

// ─── MSG-03: Listar conversaciones del usuario ────────────────────────────────
router.get("/", authenticate, async (req, res, next) => {
  try {
    const uid = req.user.uid;
    const role = req.user.role;

    // Buscar conversaciones donde el usuario es owner o renter
    const field = role === "owner" ? "ownerId" : "renterId";
    const snap = await db.collection("conversaciones")
      .where(field, "==", uid)
      .orderBy("lastMessageAt", "desc")
      .limit(50)
      .get();

    const conversaciones = snap.docs.map((d) => {
      const data = d.data();
      return {
        id: d.id,
        reservaId: data.reservaId,
        terrenoId: data.terrenoId,
        ownerId: data.ownerId,
        renterId: data.renterId,
        lastMessageText: data.lastMessageText,
        lastMessageAt: data.lastMessageAt?.toDate?.() ?? null,
        unread: role === "owner" ? (data.unreadOwner || 0) : (data.unreadRenter || 0),
        updatedAt: data.updatedAt?.toDate?.() ?? null,
      };
    });

    return res.json({ ok: true, data: conversaciones, requestId: req.requestId });
  } catch (err) {
    next(err);
  }
});

// ─── MSG-03: Obtener una conversación ────────────────────────────────────────
router.get("/:conversationId", authenticate, async (req, res, next) => {
  try {
    const conv = await getConversacionOrThrow(req.params.conversationId, req.user.uid);
    return res.json({ ok: true, data: conv, requestId: req.requestId });
  } catch (err) {
    next(err);
  }
});

// ─── MSG-02: Listar mensajes de una conversación ──────────────────────────────
router.get("/:conversationId/mensajes", authenticate, async (req, res, next) => {
  try {
    await getConversacionOrThrow(req.params.conversationId, req.user.uid);

    const limit = Math.min(parseInt(req.query.limit) || 50, 100);
    let query = db.collection("conversaciones")
      .doc(req.params.conversationId)
      .collection("mensajes")
      .orderBy("sentAt", "desc")
      .limit(limit);

    if (req.query.before) {
      const cursorSnap = await db
        .collection("conversaciones")
        .doc(req.params.conversationId)
        .collection("mensajes")
        .doc(req.query.before)
        .get();
      if (cursorSnap.exists) query = query.startAfter(cursorSnap);
    }

    const snap = await query.get();
    const mensajes = snap.docs.map((d) => ({
      id: d.id,
      text: d.data().text,
      senderId: d.data().senderId,
      sentAt: d.data().sentAt?.toDate?.() ?? null,
      readAt: d.data().readAt ?? null,
    }));

    return res.json({ ok: true, data: mensajes.reverse(), requestId: req.requestId });
  } catch (err) {
    next(err);
  }
});

// ─── MSG-02: Enviar mensaje ───────────────────────────────────────────────────
router.post("/:conversationId/mensajes", authenticate, validate(sendMessageSchema), async (req, res, next) => {
  const requestId = req.requestId;
  const { conversationId } = req.params;
  const { text } = req.body;
  const senderId = req.user.uid;

  try {
    // Rate limit
    if (!checkRateLimit(senderId)) {
      throw new BusinessRuleError("Demasiados mensajes. Espera un momento.");
    }

    const conv = await getConversacionOrThrow(conversationId, senderId);

    const sentAt = new Date();
    const mensajeRef = db
      .collection("conversaciones")
      .doc(conversationId)
      .collection("mensajes")
      .doc();

    const mensajeData = {
      text,
      senderId,
      sentAt,
      readAt: null,
    };

    // Actualizar conversación y agregar mensaje en batch
    const batch = db.batch();
    batch.set(mensajeRef, mensajeData);

    // Incrementar contador de no leídos del destinatario
    const isOwner = senderId === conv.ownerId;
    batch.update(db.collection("conversaciones").doc(conversationId), {
      lastMessageText: text.length > 80 ? text.slice(0, 80) + "…" : text,
      lastMessageAt: sentAt,
      updatedAt: sentAt,
      [isOwner ? "unreadRenter" : "unreadOwner"]: admin.firestore.FieldValue.increment(1),
    });

    await batch.commit();

    // MSG-05: Disparar notificación (asincrónico, no bloquea respuesta)
    _triggerNotificacion(conv, senderId, text).catch(() => {});

    log.info("Mensaje enviado", { conversationId, senderId, requestId });

    return res.status(201).json({
      ok: true,
      data: { id: mensajeRef.id, text, senderId, sentAt },
      requestId,
    });
  } catch (err) {
    next(err);
  }
});

// ─── MSG-04: Marcar conversación como leída ───────────────────────────────────
router.patch("/:conversationId/leido", authenticate, async (req, res, next) => {
  const requestId = req.requestId;
  const { conversationId } = req.params;
  const uid = req.user.uid;

  try {
    const conv = await getConversacionOrThrow(conversationId, uid);

    const isOwner = uid === conv.ownerId;
    const updateData = {
      [isOwner ? "unreadOwner" : "unreadRenter"]: 0,
      updatedAt: new Date(),
    };

    await db.collection("conversaciones").doc(conversationId).update(updateData);

    log.info("Conversación marcada como leída", { conversationId, uid, requestId });
    return res.json({ ok: true, requestId });
  } catch (err) {
    next(err);
  }
});

// ─── Helper: notificación de nuevo mensaje ────────────────────────────────────
async function _triggerNotificacion(conv, senderId, text) {
  const recipientId = senderId === conv.ownerId ? conv.renterId : conv.ownerId;
  const recipientSnap = await db.collection("users").doc(recipientId).get();
  const tokens = recipientSnap.data()?.fcmTokens || [];

  if (tokens.length === 0) return;

  await db.collection("pending_notifications").add({
    tokens,
    title: "Nuevo mensaje",
    body: text.length > 60 ? text.slice(0, 60) + "…" : text,
    data: {
      conversationId: conv.id,
      reservaId: conv.reservaId,
      type: "nuevo_mensaje",
    },
    createdAt: new Date(),
  });
}

module.exports = router;
