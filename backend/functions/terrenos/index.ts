// ============================================================================
// TERRENOS ROUTER
// Etapa A - Read-first endpoints for frontend
// ============================================================================

import express from 'express';
import { asyncHandler, createError } from '../../shared/errors';
import { firestore } from '../../shared/auth';

const router = express.Router();

// Create terreno (owner only - optional auth in Etapa A)
router.post('/', asyncHandler(async (req, res) => {
  const data = req.body || {};

  if (!data.ownerId) {
    throw createError('VALIDATION_FAILED', 'ownerId is required');
  }

  const docRef = firestore.collection('terrenos').doc();
  const docData = {
    ...data,
    id: docRef.id,
    status: data.status || 'disponible',
    createdAt: Date.now(),
    updatedAt: Date.now(),
  };

  await docRef.set(docData);

  res.json({ item: docData, requestId: req.requestId });
}));

// Get terreno by ID
router.get('/:id', asyncHandler(async (req, res) => {
  const doc = await firestore.collection('terrenos').doc(req.params.id).get();
  if (!doc.exists) {
    throw createError('RESOURCE_NOT_FOUND', 'Terreno not found');
  }
  res.json({ item: { id: doc.id, ...doc.data() }, requestId: req.requestId });
}));

// List terrenos
router.get('/', asyncHandler(async (req, res) => {
  const { status, ownerId, orderBy, order, limit } = req.query;
  let query: FirebaseFirestore.Query = firestore.collection('terrenos');

  if (status) {
    query = query.where('status', '==', status);
  }
  if (ownerId) {
    query = query.where('ownerId', '==', ownerId);
  }

  const sortField = typeof orderBy === 'string' ? orderBy : 'createdAt';
  const sortDir = order === 'asc' ? 'asc' : 'desc';
  query = query.orderBy(sortField, sortDir);

  const limitValue = Number(limit) > 0 ? Number(limit) : 50;
  query = query.limit(limitValue);

  const snapshot = await query.get();
  const items = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

  res.json({ items, requestId: req.requestId });
}));

export default router;