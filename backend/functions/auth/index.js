/**
 * functions/auth/index.js
 * Módulo AUTH – Registro, perfil y onboarding.
 * AUTH-01 al AUTH-05.
 */

"use strict";

const express = require("express");
const admin = require("../../shared/firestore/admin");
const { db } = require("../../shared/firestore/index");
const { authenticate } = require("../../shared/auth/middleware");
const { validate, registerSchema, onboardingSchema } = require("../../shared/validation/index");
const { ValidationError, ConflictError, NotFoundError } = require("../../shared/errors");
const { createLogger, logStateTransition } = require("../../shared/observability/logger");
const UsuarioModel = require("../../models/usuario.model");

const log = createLogger("auth");
const router = express.Router();

// ─── AUTH-01: Registro con rol ────────────────────────────────────────────────
router.post("/register", validate(registerSchema), async (req, res, next) => {
  const requestId = req.requestId;
  const { fullName, email, password, phonePrefix, phone, role } = req.body;

  try {
    // Crear usuario en Firebase Auth
    let userRecord;
    try {
      userRecord = await admin.auth().createUser({
        email,
        password,
        displayName: fullName,
      });
    } catch (err) {
      if (err.code === "auth/email-already-exists") {
        throw new ConflictError("El email ya está registrado");
      }
      throw err;
    }

    // Crear documento en Firestore (colección users)
    const userData = UsuarioModel.create({
      uid: userRecord.uid,
      fullName,
      email,
      phonePrefix,
      phone,
      role,
    });

    await db.collection("users").doc(userRecord.uid).set(userData);

    // Establecer custom claim de rol (para reglas Firestore futuras)
    await admin.auth().setCustomUserClaims(userRecord.uid, { role });

    log.info("Usuario registrado", { uid: userRecord.uid, role, requestId });

    return res.status(201).json({
      ok: true,
      message: "Usuario creado exitosamente",
      data: { uid: userRecord.uid, role },
      requestId,
    });
  } catch (err) {
    next(err);
  }
});

// ─── AUTH-03: Perfil del usuario autenticado ──────────────────────────────────
router.get("/profile", authenticate, async (req, res, next) => {
  try {
    const snap = await db.collection("users").doc(req.user.uid).get();
    if (!snap.exists) throw new NotFoundError("Usuario");

    const usuario = UsuarioModel.fromFirestore(snap);
    return res.json({ ok: true, data: UsuarioModel.toJson(usuario), requestId: req.requestId });
  } catch (err) {
    next(err);
  }
});

// ─── AUTH-03: Completar onboarding ───────────────────────────────────────────
router.patch("/onboarding", authenticate, validate(onboardingSchema), async (req, res, next) => {
  const requestId = req.requestId;
  const { uid } = req.user;
  const { bio, location, acceptedTerms } = req.body;

  try {
    const updateData = {
      onboardingComplete: true,
      acceptedTerms,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (bio) updateData.bio = bio;
    if (location) updateData.location = location;

    await db.collection("users").doc(uid).update(updateData);

    log.info("Onboarding completado", { uid, requestId });
    return res.json({ ok: true, message: "Onboarding completado", requestId });
  } catch (err) {
    next(err);
  }
});

// ─── AUTH-05: Logout (invalidar sesión del lado servidor) ─────────────────────
// Firebase Auth maneja sesiones del lado cliente; aquí revocamos tokens para
// invalidar sesiones activas (útil para dispositivos comprometidos).
router.post("/logout", authenticate, async (req, res, next) => {
  try {
    await admin.auth().revokeRefreshTokens(req.user.uid);
    log.info("Tokens revocados", { uid: req.user.uid, requestId: req.requestId });
    return res.json({ ok: true, message: "Sesión cerrada exitosamente", requestId: req.requestId });
  } catch (err) {
    next(err);
  }
});

// ─── AUTH-01: Actualizar FCM token (para push notifications) ─────────────────
router.post("/fcm-token", authenticate, async (req, res, next) => {
  const { token } = req.body;
  if (!token) return res.status(400).json({ ok: false, message: "Token requerido" });

  try {
    await db.collection("users").doc(req.user.uid).update({
      fcmTokens: admin.firestore.FieldValue.arrayUnion(token),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return res.json({ ok: true, requestId: req.requestId });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
