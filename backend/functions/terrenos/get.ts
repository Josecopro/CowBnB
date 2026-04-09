// ============================================================================
// GET TERRENO FUNCTION
// Etapa A - Stub implementation
// ============================================================================

import * as functions from 'firebase-functions';
import { verifyFirebaseToken } from '../../shared/auth';

export const getTerreno = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  const { id } = data;

  // STUB - Implementation in Etapa B
  return {
    message: `Get terreno ${id} - Not implemented in Etapa A`,
    success: false,
  };
});