// ============================================================================
// LOGIN FUNCTION
// Etapa A - Stub implementation
// ============================================================================

import * as functions from 'firebase-functions';

export const login = functions.https.onCall(async (data, context) => {
  // Login is handled client-side with Firebase Auth
  return {
    message: 'Login handled client-side',
    success: true,
  };
});