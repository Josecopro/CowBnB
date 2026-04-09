// ============================================================================
// AUTH ROUTER
// Etapa A - Stub implementations
// ============================================================================

import express from 'express';
import { verifyFirebaseToken } from '../../shared/auth';
import { asyncHandler } from '../../shared/errors';

const router = express.Router();

// Register user (stub)
router.post('/register', asyncHandler(async (req, res) => {
  // STUB - Implementation in Etapa B
  res.json({
    message: 'Registration endpoint - Not implemented in Etapa A',
    requestId: req.requestId,
  });
}));

// Login (handled by Firebase Auth client-side)
router.post('/login', asyncHandler(async (req, res) => {
  res.json({
    message: 'Login handled client-side with Firebase Auth',
    requestId: req.requestId,
  });
}));

// Get profile
router.get('/profile', verifyFirebaseToken, asyncHandler(async (req, res) => {
  // STUB - Implementation in Etapa B
  res.json({
    message: 'Profile endpoint - Not implemented in Etapa A',
    user: req.user,
    requestId: req.requestId,
  });
}));

export default router;