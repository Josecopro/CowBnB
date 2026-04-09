// ============================================================================
// STATE TRANSITIONS FUNCTION
// Etapa A - Stub implementation
// ============================================================================

import * as functions from 'firebase-functions';
import { verifyFirebaseToken } from '../../shared/auth';
import { VALID_TRANSITIONS, TERRENO_STATUSES } from '../../config/constants.config';

export const transitionTerrenoState = functions.https.onCall(async (data, context) => {
  // Verify authentication (backend only in production)
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  const { terrenoId, newStatus } = data;

  // Validate transition
  const validTransitions = VALID_TRANSITIONS.TERRENO[TERRENO_STATUSES.DISPONIBLE] || [];
  if (!validTransitions.includes(newStatus)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid state transition');
  }

  // STUB - Implementation in Etapa B
  return {
    message: `Transition terreno ${terrenoId} to ${newStatus} - Not implemented in Etapa A`,
    success: false,
  };
});