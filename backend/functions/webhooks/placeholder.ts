// ============================================================================
// WEBHOOK PLACEHOLDER
// Etapa A - Reserved for Bold payment webhooks
// ============================================================================

import * as functions from 'firebase-functions';

export const boldWebhook = functions.https.onRequest(async (req, res) => {
  // STUB - Implementation in Etapa C
  res.status(200).json({
    message: 'Webhook placeholder - Not implemented in Etapa A',
    timestamp: Date.now(),
  });
});