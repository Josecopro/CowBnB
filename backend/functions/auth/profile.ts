// ============================================================================
// PROFILE FUNCTION
// Etapa A - Stub implementation
// ============================================================================

import * as functions from 'firebase-functions';
import { verifyFirebaseToken } from '../../shared/auth';

export const profile = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  // STUB - Implementation in Etapa B
  return {
    message: 'User profile - Not implemented in Etapa A',
    uid: context.auth.uid,
    success: false,
  };
});