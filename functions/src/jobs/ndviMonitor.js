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
exports.monitoreoNDVI = void 0;
const schedule_1 = require("firebase-functions/v2/schedule");
const admin = __importStar(require("firebase-admin"));
const ndviService_1 = require("../services/ndviService");
// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
// Ejecutar cada 7 días (puedes ajustar la frecuencia)
exports.monitoreoNDVI = (0, schedule_1.onSchedule)({ schedule: "0 6 * * 1", timeZone: "America/Bogota" }, async () => {
    // Obtener solo terrenos activos y disponibles
    const terrenosSnap = await db
        .collection("terrenos")
        .where("estado", "in", ["disponible", "en_espera"])
        .get();
    const tareas = terrenosSnap.docs.map(async (doc) => {
        const terreno = doc.data();
        // El terreno debe tener coordenadas de polígono guardadas
        if (!terreno.coordenadas || terreno.coordenadas.length < 3) {
            console.warn(`Terreno ${doc.id} no tiene coordenadas de polígono`);
            return;
        }
        try {
            const { ndvi, fecha, muestreos } = await (0, ndviService_1.obtenerNDVI)(terreno.coordenadas, 30);
            // Guardar historial NDVI
            await doc.ref.collection("ndviHistorial").add({
                ndvi,
                fecha,
                muestreos,
                evaluadoEn: admin.firestore.FieldValue.serverTimestamp(),
            });
            // Umbral configurable — pasto crecido si NDVI > 0.5
            const UMBRAL_PASTO_CRECIDO = 0.5;
            if (ndvi > UMBRAL_PASTO_CRECIDO && terreno.estado === "disponible") {
                // Cambiar estado a 'en_espera' y notificar arrendatario
                const tokenConfirmacion = generarTokenUnico(doc.id);
                await doc.ref.update({
                    estado: "en_espera",
                    razonEspera: "ndvi_alto",
                    ndviDetectado: ndvi,
                    tokenConfirmacion,
                    tokenExpira: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 72 * 60 * 60 * 1000)),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                await enviarEmailConfirmacion(terreno, doc.id, ndvi, tokenConfirmacion);
            }
            // Si NDVI bajó y estaba en espera por ndvi_alto, reactivar automáticamente
            if (ndvi <= UMBRAL_PASTO_CRECIDO &&
                terreno.estado === "en_espera" &&
                terreno.razonEspera === "ndvi_alto") {
                await doc.ref.update({
                    estado: "disponible",
                    razonEspera: null,
                    tokenConfirmacion: null,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        }
        catch (error) {
            // No cambiar estado si no hay imagen disponible (nubes, etc.)
            console.error(`Error NDVI terreno ${doc.id}:`, error.message);
            await doc.ref.collection("ndviHistorial").add({
                error: error.message,
                evaluadoEn: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
    });
    await Promise.allSettled(tareas);
    return null;
});
function generarTokenUnico(terrenoId) {
    const crypto = require("crypto");
    return crypto.randomBytes(32).toString("hex");
}
async function enviarEmailConfirmacion(terreno, terrenoId, ndvi, token) {
    const baseUrl = process.env.FUNCTIONS_BASE_URL; // URL de tus Cloud Functions
    const urlConfirmar = `${baseUrl}/confirmarEstadoTerreno?token=${token}&accion=confirmar`;
    const urlReactivar = `${baseUrl}/confirmarEstadoTerreno?token=${token}&accion=reactivar`;
    const html = `
    <h2>Alerta de vegetación en tu terreno</h2>
    <p>Nuestro sistema de monitoreo satelital detectó un índice de vegetación 
    elevado (NDVI: ${ndvi.toFixed(2)}) en tu terreno <strong>${terreno.nombre}</strong>.</p>
    <p>Esto puede indicar que el pasto está crecido. Por favor confirma:</p>
    <p>
      <a href="${urlConfirmar}" style="background:#f44336;color:white;padding:10px 20px;text-decoration:none;border-radius:4px;">
        Sí, el pasto está crecido
      </a>
      &nbsp;&nbsp;
      <a href="${urlReactivar}" style="background:#4CAF50;color:white;padding:10px 20px;text-decoration:none;border-radius:4px;">
        No, reactivar mi terreno
      </a>
    </p>
    <p><small>Este enlace expira en 72 horas.</small></p>
  `;
    // Usar Firebase Extension "Trigger Email" o SendGrid
    await db.collection("mail").add({
        to: terreno.arrendatarioEmail,
        message: {
            subject: `⚠️ Alerta satelital: ${terreno.nombre}`,
            html,
        },
    });
}
