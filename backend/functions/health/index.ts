// ============================================================================
// HEALTH CHECK FUNCTION
// Etapa A - Basic health check
// ============================================================================

import * as functions from 'firebase-functions';

export const health = functions.https.onCall(async (data, context) => {
  return {
    status: 'ok',
    timestamp: Date.now(),
    version: 'etapa-a',
    uptime: process.uptime(),
  };
});