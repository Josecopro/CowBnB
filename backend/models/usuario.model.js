/**
 * models/usuario.model.js
 * Contrato de datos del usuario en Firestore.
 */

"use strict";

const admin = require("../shared/firestore/admin");

class UsuarioModel {
  /**
   * Crea la estructura canónica de un usuario nuevo.
   */
  static create({ uid, fullName, email, phonePrefix, phone, role }) {
    const now = admin.firestore.FieldValue.serverTimestamp();
    return {
      uid,
      fullName,
      email,
      phonePrefix,
      phone,
      role, // "owner" | "renter"
      onboardingComplete: false,
      bio: null,
      location: null,
      acceptedTerms: false,
      fcmTokens: [],     // para push notifications
      createdAt: now,
      updatedAt: now,
    };
  }

  /**
   * Deserializa un documento Firestore a objeto plano.
   */
  static fromFirestore(snap) {
    if (!snap.exists) return null;
    const data = snap.data();
    return {
      uid: snap.id,
      fullName: data.fullName,
      email: data.email,
      phonePrefix: data.phonePrefix,
      phone: data.phone,
      role: data.role,
      onboardingComplete: data.onboardingComplete,
      bio: data.bio ?? null,
      location: data.location ?? null,
      acceptedTerms: data.acceptedTerms ?? false,
      createdAt: data.createdAt?.toDate?.() ?? null,
      updatedAt: data.updatedAt?.toDate?.() ?? null,
    };
  }

  /**
   * Serializa para respuesta JSON (omite campos sensibles).
   */
  static toJson(usuario) {
    return {
      uid: usuario.uid,
      fullName: usuario.fullName,
      email: usuario.email,
      phonePrefix: usuario.phonePrefix,
      phone: usuario.phone,
      role: usuario.role,
      onboardingComplete: usuario.onboardingComplete,
      bio: usuario.bio,
      location: usuario.location,
      createdAt: usuario.createdAt,
    };
  }
}

module.exports = UsuarioModel;
