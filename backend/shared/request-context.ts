import { AsyncLocalStorage } from 'async_hooks';

// ============================================================================
// REQUEST CONTEXT MANAGEMENT
// AsyncLocalStorage for requestId propagation
// ============================================================================

interface RequestContext {
  requestId: string;
  userId?: string;
  startTime: number;
}

// AsyncLocalStorage instance
export const requestContext = new AsyncLocalStorage<RequestContext>();

// Generate unique request ID
export function generateRequestId(): string {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 10);
  return `${timestamp}-${random}`;
}

// Get current request ID
export function getCurrentRequestId(): string | undefined {
  const context = requestContext.getStore();
  return context?.requestId;
}

// Get current user ID
export function getCurrentUserId(): string | undefined {
  const context = requestContext.getStore();
  return context?.userId;
}

// Set user ID in context
export function setCurrentUserId(userId: string): void {
  const context = requestContext.getStore();
  if (context) {
    context.userId = userId;
  }
}

// Run function within request context
export function runInRequestContext<T>(
  requestId: string,
  fn: () => T
): T {
  const context: RequestContext = {
    requestId,
    startTime: Date.now(),
  };

  return requestContext.run(context, fn);
}

// Middleware to set up request context
export function requestContextMiddleware() {
  return (req: any, res: any, next: any) => {
    const requestId = req.headers['x-request-id'] as string || generateRequestId();
    req.requestId = requestId;

    runInRequestContext(requestId, () => {
      next();
    });
  };
}