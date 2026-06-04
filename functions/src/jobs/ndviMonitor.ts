import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import { obtenerNDVI } from "../services/ndviService";

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Ejecutar cada 7 días (puedes ajustar la frecuencia)
export const monitoreoNDVI = onSchedule(
  { schedule: "0 6 * * 1", timeZone: "America/Bogota" },
  async () => {
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
        const { ndvi, fecha, muestreos } = await obtenerNDVI(terreno.coordenadas, 30);

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
            tokenExpira: admin.firestore.Timestamp.fromDate(
              new Date(Date.now() + 72 * 60 * 60 * 1000), // 72 horas
            ),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          await enviarEmailConfirmacion(
            terreno,
            doc.id,
            ndvi,
            tokenConfirmacion,
          );
        }

        // Si NDVI bajó y estaba en espera por ndvi_alto, reactivar automáticamente
        if (
          ndvi <= UMBRAL_PASTO_CRECIDO &&
          terreno.estado === "en_espera" &&
          terreno.razonEspera === "ndvi_alto"
        ) {
          await doc.ref.update({
            estado: "disponible",
            razonEspera: null,
            tokenConfirmacion: null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      } catch (error) {
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
  }
);

function generarTokenUnico(terrenoId: string): string {
  const crypto = require("crypto");
  return crypto.randomBytes(32).toString("hex");
}

async function enviarEmailConfirmacion(terreno: any, terrenoId: string, ndvi: number, token: string) {
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