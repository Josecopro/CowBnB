import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

export const confirmarEstadoTerreno = onRequest((req, res) => {
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