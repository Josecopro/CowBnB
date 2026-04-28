/**
 * functions/notificaciones/index.js
 * Módulo NOTIFICACIONES – Envío FCM y email desde cola Firestore.
 * Consumido por Firestore trigger en `pending_notifications`.
 */

"use strict";

const admin = require("../../shared/firestore/admin");
const { db } = require("../../shared/firestore/index");
const { createLogger } = require("../../shared/observability/logger");

const log = createLogger("notificaciones");

/**
 * Envía notificación FCM a uno o varios tokens.
 * Si un token está inválido, lo elimina del perfil del usuario.
 */
async function sendPushNotification({ tokens, title, body, data = {} }) {
  if (!tokens || tokens.length === 0) return;

  const message = {
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    ),
    tokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);

    log.info("FCM enviado", {
      successCount: response.successCount,
      failureCount: response.failureCount,
    });

    // Eliminar tokens inválidos
    const invalidTokens = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const code = resp.error?.code;
        if (
          code === "messaging/invalid-registration-token" ||
          code === "messaging/registration-token-not-registered"
        ) {
          invalidTokens.push(tokens[idx]);
        }
      }
    });

    if (invalidTokens.length > 0) {
      await _removeInvalidTokens(invalidTokens);
    }
  } catch (err) {
    log.error("Error enviando FCM", { error: err.message });
  }
}

/**
 * Elimina tokens FCM inválidos de los documentos de usuario.
 */
async function _removeInvalidTokens(tokens) {
  const usersSnap = await db.collection("users")
    .where("fcmTokens", "array-contains-any", tokens.slice(0, 10))
    .limit(20)
    .get();

  const batch = db.batch();
  usersSnap.docs.forEach((doc) => {
    const currentTokens = doc.data().fcmTokens || [];
    const cleaned = currentTokens.filter((t) => !tokens.includes(t));
    if (cleaned.length !== currentTokens.length) {
      batch.update(doc.ref, { fcmTokens: cleaned });
    }
  });

  await batch.commit().catch(() => {});
}

/**
 * Procesador de la cola `pending_notifications`.
 * Se ejecuta como Cloud Function Firestore trigger.
 */
async function processPendingNotification(snap, context) {
  const data = snap.data();
  if (!data) return;

  try {
    await sendPushNotification({
      tokens: data.tokens,
      title: data.title,
      body: data.body,
      data: data.data || {},
    });

    // Marcar como procesado
    await snap.ref.update({
      processed: true,
      processedAt: new Date(),
    });
  } catch (err) {
    log.error("Error procesando notificación pendiente", {
      error: err.message,
      docId: snap.id,
    });
    await snap.ref.update({
      error: err.message,
      retryAt: new Date(Date.now() + 5 * 60 * 1000),
    });
  }
}

module.exports = { sendPushNotification, processPendingNotification };
