// ============================================================================
// CREATE TERRENO FUNCTION
// Etapa A - Stub implementation
// ============================================================================

import * as functions from 'firebase-functions';
import { verifyFirebaseToken } from '../../shared/auth';

export const createTerreno = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  // Check role (owner only)
  if (context.auth.token.role !== 'owner') {
    throw new functions.https.HttpsError('permission-denied', 'Only owners can create terrenos');
  }

  // STUB - Implementation in Etapa B
  return {
    message: 'Create terreno - Not implemented in Etapa A',
    uid: context.auth.uid,
    success: false,
  };
});