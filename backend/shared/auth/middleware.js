/**
 * shared/auth/middleware.js
 * Middleware de autenticación y control de roles para Express.
 * Verifica tokens Firebase Auth y enriquece req.user.
 */

"use strict";

const admin = require("../firestore/admin");
const { UnauthorizedError, ForbiddenError } = require("../errors");
const { createLogger } = require("../observability/logger");

const log = createLogger("auth-middleware");

/**
 * Verifica el Bearer token de Firebase Auth.
 * Añade req.user = { uid, email, role } si es válido.
 */
async function authenticate(req, res, next) {
  try {
    const header = req.headers.authorization || "";
    if (!header.startsWith("Bearer ")) {
      throw new UnauthorizedError("Token de autorización requerido");
    }

    const token = header.slice(7);
    const decoded = await admin.auth().verifyIdToken(token);

    // Obtener rol desde Firestore (fuente de verdad, no el token)
    const userSnap = await admin.firestore().collection("users").doc(decoded.uid).get();
    if (!userSnap.exists) {
      throw new UnauthorizedError("Usuario no encontrado en el sistema");
    }

    const userData = userSnap.data();
    req.user = {
      uid: decoded.uid,
      email: decoded.email,
      role: userData.role,
      fullName: userData.fullName,
    };

    log.debug("Usuario autenticado", { uid: decoded.uid, role: userData.role, requestId: req.requestId });
    next();
  } catch (err) {
    if (err.code === "auth/id-token-expired") {
      return next(new UnauthorizedError("Token expirado"));
    }
    if (err.code === "auth/argument-error" || err.code === "auth/id-token-revoked") {
      return next(new UnauthorizedError("Token inválido"));
    }
    next(err);
  }
}

/**
 * Guard de rol. Usar después de authenticate.
 * Uso: requireRole("owner") o requireRole(["owner", "renter"])
 */
function requireRole(roles) {
  const allowed = Array.isArray(roles) ? roles : [roles];
  return (req, res, next) => {
    if (!req.user) return next(new UnauthorizedError());
    if (!allowed.includes(req.user.role)) {
      return next(new ForbiddenError(`Se requiere rol: ${allowed.join(" o ")}`));
    }
    next();
  };
}

/**
 * Verifica que el uid autenticado sea el dueño del recurso.
 * Uso: requireOwnership("ownerId") referencia al campo del body/param
 */
function requireOwnership(ownerField = "ownerId") {
  return (req, res, next) => {
    const resourceOwner = req.body?.[ownerField] || req.params?.[ownerField];
    if (!req.user) return next(new UnauthorizedError());
    if (resourceOwner && resourceOwner !== req.user.uid) {
      return next(new ForbiddenError("No eres el propietario de este recurso"));
    }
    next();
  };
}

module.exports = { authenticate, requireRole, requireOwnership };
