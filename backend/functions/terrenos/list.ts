// ============================================================================
// LIST TERRENOS FUNCTION
// Etapa A - Stub implementation
// ============================================================================

import * as functions from 'firebase-functions';
import { verifyFirebaseToken } from '../../shared/auth';

export const listTerrenos = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  // STUB - Implementation in Etapa B
  return {
    message: 'List terrenos - Not implemented in Etapa A',
    success: false,
  };
});