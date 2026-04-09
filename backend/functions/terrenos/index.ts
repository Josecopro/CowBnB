// ============================================================================
// TERRENOS ROUTER
// Etapa A - Stub implementations
// ============================================================================

import express from 'express';
import { verifyFirebaseToken, requireRole } from '../../shared/auth';
import { asyncHandler } from '../../shared/errors';

const router = express.Router();

// Create terreno (owner only)
router.post('/', verifyFirebaseToken, requireRole('owner'), asyncHandler(async (req, res) => {
  // STUB - Implementation in Etapa B
  res.json({
    message: 'Create terreno - Not implemented in Etapa A',
    user: req.user,
    requestId: req.requestId,
  });
}));

// Get terreno by ID
router.get('/:id', verifyFirebaseToken, asyncHandler(async (req, res) => {
  // STUB - Implementation in Etapa B
  res.json({
    message: `Get terreno ${req.params.id} - Not implemented in Etapa A`,
    requestId: req.requestId,
  });
}));

// List terrenos
router.get('/', verifyFirebaseToken, asyncHandler(async (req, res) => {
  // STUB - Implementation in Etapa B
  res.json({
    message: 'List terrenos - Not implemented in Etapa A',
    requestId: req.requestId,
  });
}));

export default router;