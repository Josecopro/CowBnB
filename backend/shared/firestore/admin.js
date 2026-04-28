/**
 * shared/firestore/admin.js
 * Singleton de Firebase Admin SDK.
 * Inicializa una sola vez en todo el proceso.
 */

"use strict";

const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

module.exports = admin;
