// ============================================================================
// IDEMPOTENCY TRACKING
// Reserved for Etapa A - Basic skeleton
// Full implementation in Etapa C (payments)
// ============================================================================

import { firestore } from './auth';
import { createError } from './errors';
import { logInfo } from './logging';
import { getCurrentRequestId } from './request-context';

interface IdempotencyRecord {
  id: string;
  operationId: string; // e.g., 'payment_webhook_bold_ref_123'
  result: any;
  expiresAt: number; // TTL timestamp
  createdAt: number;
}

// Check if operation was already processed
export async function checkIdempotency(operationId: string): Promise<any | null> {
  try {
    // In Etapa A, this is a stub - always return null (not processed)
    // Implementation will use Firestore collection with TTL
    const requestId = getCurrentRequestId();
    logInfo('Idempotency check (stub)', { operationId }, requestId);
    return null;
  } catch (error) {
    throw createError('INTERNAL_ERROR', 'Idempotency check failed');
  }
}

// Record operation result for idempotency
export async function recordIdempotency(
  operationId: string,
  result: any,
  ttlSeconds = 86400 // 24 hours
): Promise<void> {
  try {
    // In Etapa A, this is a stub - no-op
    // Implementation will write to _idempotency collection
    const requestId = getCurrentRequestId();
    logInfo('Idempotency record (stub)', { operationId }, requestId);
  } catch (error) {
    throw createError('INTERNAL_ERROR', 'Failed to record idempotency');
  }
}

// Clean up expired records (background job)
export async function cleanupExpiredIdempotency(): Promise<void> {
  // Stub for Etapa A
  logInfo('Idempotency cleanup (stub)');
}