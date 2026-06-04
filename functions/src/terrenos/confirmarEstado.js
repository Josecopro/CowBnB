"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.confirmarEstadoTerreno = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
exports.confirmarEstadoTerreno = (0, https_1.onRequest)(async (req, res) => {
    const { token, accion } = req.query;
    // accion: 'confirmar' (sí está crecido) | 'reactivar' (no está crecido)
    if (!token || !accion) {
        return res.status(400).send("Parámetros inválidos");
    }
    const snap = await db
        .collection("terrenos")
        .where("tokenConfirmacion", "==", token)
        .limit(1)
        .get();
    if (snap.empty) {
        return res.status(404).send("Token inválido o expirado");
    }
    const doc = snap.docs[0];
    const terreno = doc.data();
    // Verificar que el token no expiró
    if (terreno.tokenExpira.toDate() < new Date()) {
        return res.status(410).send("Este enlace ha expirado");
    }
    if (accion === "confirmar") {
        // El arrendatario confirma que el pasto está crecido → queda en espera
        await doc.ref.update({
            estado: "en_espera",
            confirmadoPorArrendatario: true,
            tokenConfirmacion: null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return res.redirect("https://tu-app.com/terreno/en-espera-confirmado");
    }
    if (accion === "reactivar") {
        // El arrendatario dice que no está crecido → reactivar
        await doc.ref.update({
            estado: "disponible",
            confirmadoPorArrendatario: false,
            tokenConfirmacion: null,
            ndviIgnorado: true,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return res.redirect("https://tu-app.com/terreno/reactivado");
    }
    res.status(400).send("Acción no reconocida");
});
