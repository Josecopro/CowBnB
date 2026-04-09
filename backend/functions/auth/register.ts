// ============================================================================
// REGISTER FUNCTION
// Etapa A - Stub implementation
// ============================================================================

import * as functions from 'firebase-functions';
import { verifyFirebaseToken } from '../../shared/auth';
import { asyncHandler } from '../../shared/errors';

export const register = functions.https.onCall(async (data, context) => {
  // STUB - No implementation in Etapa A
  return {
    message: 'User registration - Not implemented in Etapa A',
    success: false,
  };
});