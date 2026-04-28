// ============================================================================
// RESERVAS ROUTER
// Etapa A - Read/Write endpoints for frontend
// ============================================================================

declare const require: any;
// eslint-disable-next-line @typescript-eslint/no-var-requires
const express = require('express');
import { asyncHandler, createError } from '../../shared/errors';
import { firestore } from '../../shared/auth';

const router = express.Router();

// Create reserva
router.post('/', asyncHandler(async (req: any, res: any) => {
  const data = req.body || {};

  if (!data.terrenoId || !data.renterId || !data.ownerId) {
    throw createError('VALIDATION_FAILED', 'terrenoId, renterId, ownerId are required');
  }

  const docRef = firestore.collection('reservas').doc();
  const docData = {
    ...data,
    id: docRef.id,
    status: data.status || 'pendiente',
    createdAt: Date.now(),
    updatedAt: Date.now(),
  };

  await docRef.set(docData);

  res.json({ item: docData, requestId: req.requestId });
}));

// List reservas
router.get('/', asyncHandler(async (req: any, res: any) => {
  const { renterId, ownerId, order, limit } = req.query;
  let query: any = firestore.collection('reservas');

  if (renterId) {
    query = query.where('renterId', '==', renterId);
  }
  if (ownerId) {
    query = query.where('ownerId', '==', ownerId);
  }

  const sortDir = order === 'asc' ? 'asc' : 'desc';
  query = query.orderBy('createdAt', sortDir);

  const limitValue = Number(limit) > 0 ? Number(limit) : 50;
  query = query.limit(limitValue);

  const snapshot = await query.get();
  const items = snapshot.docs.map((doc: any) => ({ id: doc.id, ...doc.data() }));

  res.json({ items, requestId: req.requestId });
}));

export default router;
