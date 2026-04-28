/**
 * functions/terrenos/images.js
 * Módulo IMÁGENES – Upload, portada y eliminación.
 * IMG-01 al IMG-04.
 *
 * Nota: El upload real usa Firebase Storage directamente desde el cliente
 * con signed URLs generados aquí. El cliente sube la imagen y luego llama
 * confirmImage() para registrar la URL en Firestore.
 */

"use strict";

const express = require("express");
const admin = require("../../shared/firestore/admin");
const { db } = require("../../shared/firestore/index");
const { authenticate, requireRole } = require("../../shared/auth/middleware");
const {
  NotFoundError,
  ForbiddenError,
  BusinessRuleError,
  ValidationError,
} = require("../../shared/errors");
const { createLogger } = require("../../shared/observability/logger");
const { v4: uuidv4 } = require("uuid");

const log = createLogger("images");
const router = express.Router({ mergeParams: true }); // hereda :terrenoId

const MAX_IMAGES = 10;
const ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/webp"];
const MAX_FILE_SIZE_MB = 10;
const BUCKET_NAME = process.env.FIREBASE_STORAGE_BUCKET;

// ─── IMG-01: Generar signed URL de upload ────────────────────────────────────
router.post("/upload-url", authenticate, requireRole("owner"), async (req, res, next) => {
  const requestId = req.requestId;
  const { terrenoId } = req.params;
  const { mimeType, fileSize } = req.body;

  try {
    if (!ALLOWED_MIME_TYPES.includes(mimeType)) {
      throw new ValidationError(`Tipo de archivo no permitido. Use: ${ALLOWED_MIME_TYPES.join(", ")}`);
    }
    if (fileSize > MAX_FILE_SIZE_MB * 1024 * 1024) {
      throw new ValidationError(`El archivo no puede superar ${MAX_FILE_SIZE_MB}MB`);
    }

    // Verificar ownership
    const terrenoSnap = await db.collection("terrenos").doc(terrenoId).get();
    if (!terrenoSnap.exists) throw new NotFoundError("Terreno");
    if (terrenoSnap.data().ownerId !== req.user.uid) throw new ForbiddenError();

    // IMG-02: Verificar límite de galería
    const currentImages = terrenoSnap.data().images || [];
    if (currentImages.length >= MAX_IMAGES) {
      throw new BusinessRuleError(`El terreno ya tiene el máximo de ${MAX_IMAGES} imágenes`);
    }

    const imageId = uuidv4();
    const extension = mimeType.split("/")[1];
    const storagePath = `terrenos/${terrenoId}/images/${imageId}.${extension}`;

    const bucket = admin.storage().bucket(BUCKET_NAME);
    const file = bucket.file(storagePath);

    const [signedUrl] = await file.getSignedUrl({
      version: "v4",
      action: "write",
      expires: Date.now() + 15 * 60 * 1000, // 15 minutos
      contentType: mimeType,
    });

    log.info("Signed URL generado", { terrenoId, imageId, requestId });
    return res.json({
      ok: true,
      data: { imageId, signedUrl, storagePath },
      requestId,
    });
  } catch (err) {
    next(err);
  }
});

// ─── IMG-01: Confirmar imagen subida ─────────────────────────────────────────
router.post("/confirm", authenticate, requireRole("owner"), async (req, res, next) => {
  const requestId = req.requestId;
  const { terrenoId } = req.params;
  const { imageId, storagePath } = req.body;

  if (!imageId || !storagePath) {
    return res.status(400).json({ ok: false, message: "imageId y storagePath requeridos" });
  }

  try {
    const terrenoSnap = await db.collection("terrenos").doc(terrenoId).get();
    if (!terrenoSnap.exists) throw new NotFoundError("Terreno");
    if (terrenoSnap.data().ownerId !== req.user.uid) throw new ForbiddenError();

    const currentImages = terrenoSnap.data().images || [];
    if (currentImages.length >= MAX_IMAGES) {
      throw new BusinessRuleError(`Límite de ${MAX_IMAGES} imágenes alcanzado`);
    }

    // Obtener URL pública del archivo en Storage
    const bucket = admin.storage().bucket(BUCKET_NAME);
    const file = bucket.file(storagePath);
    const [exists] = await file.exists();
    if (!exists) throw new NotFoundError("Imagen en Storage");

    const [metadata] = await file.getMetadata();
    // Hacer el archivo público (lectura)
    await file.makePublic();
    const publicUrl = `https://storage.googleapis.com/${BUCKET_NAME}/${storagePath}`;

    const imageEntry = {
      id: imageId,
      url: publicUrl,
      storagePath,
      uploadedAt: new Date().toISOString(),
    };

    const updateData = {
      images: admin.firestore.FieldValue.arrayUnion(imageEntry),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Si es la primera imagen, asignar como portada
    if (currentImages.length === 0) {
      updateData.coverImageUrl = publicUrl;
    }

    await db.collection("terrenos").doc(terrenoId).update(updateData);

    log.info("Imagen confirmada", { terrenoId, imageId, requestId });
    return res.status(201).json({ ok: true, data: imageEntry, requestId });
  } catch (err) {
    next(err);
  }
});

// ─── IMG-03: Establecer portada ───────────────────────────────────────────────
router.patch("/cover/:imageId", authenticate, requireRole("owner"), async (req, res, next) => {
  const requestId = req.requestId;
  const { terrenoId, imageId } = req.params;

  try {
    const terrenoSnap = await db.collection("terrenos").doc(terrenoId).get();
    if (!terrenoSnap.exists) throw new NotFoundError("Terreno");
    const terreno = terrenoSnap.data();
    if (terreno.ownerId !== req.user.uid) throw new ForbiddenError();

    const image = (terreno.images || []).find((img) => img.id === imageId);
    if (!image) throw new NotFoundError("Imagen");

    await db.collection("terrenos").doc(terrenoId).update({
      coverImageUrl: image.url,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    log.info("Portada actualizada", { terrenoId, imageId, requestId });
    return res.json({ ok: true, data: { coverImageUrl: image.url }, requestId });
  } catch (err) {
    next(err);
  }
});

// ─── IMG-04: Eliminar imagen ──────────────────────────────────────────────────
router.delete("/:imageId", authenticate, requireRole("owner"), async (req, res, next) => {
  const requestId = req.requestId;
  const { terrenoId, imageId } = req.params;

  try {
    const terrenoSnap = await db.collection("terrenos").doc(terrenoId).get();
    if (!terrenoSnap.exists) throw new NotFoundError("Terreno");
    const terreno = terrenoSnap.data();
    if (terreno.ownerId !== req.user.uid) throw new ForbiddenError();

    const image = (terreno.images || []).find((img) => img.id === imageId);
    if (!image) throw new NotFoundError("Imagen");

    // Borrar físicamente de Storage
    try {
      const bucket = admin.storage().bucket(BUCKET_NAME);
      await bucket.file(image.storagePath).delete();
    } catch (storageErr) {
      log.warn("No se pudo borrar imagen de Storage", { imageId, error: storageErr.message, requestId });
      // Continúa para borrar la referencia en Firestore
    }

    const updatedImages = (terreno.images || []).filter((img) => img.id !== imageId);

    const updateData = {
      images: updatedImages,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Si era la portada, asignar la primera imagen restante
    if (terreno.coverImageUrl === image.url) {
      updateData.coverImageUrl = updatedImages.length > 0 ? updatedImages[0].url : null;
    }

    await db.collection("terrenos").doc(terrenoId).update(updateData);

    log.info("Imagen eliminada", { terrenoId, imageId, requestId });
    return res.json({ ok: true, message: "Imagen eliminada", requestId });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
