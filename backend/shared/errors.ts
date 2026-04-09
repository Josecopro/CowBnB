import { Request, Response, NextFunction } from 'express';

// ============================================================================
// UNIFIED ERROR HANDLING
// Based on SECURITY_FOUNDATIONS_ETAPA_A.md
// ============================================================================

export interface AppError extends Error {
  code: string;
  statusCode: number;
  timestamp: number;
  requestId?: string;
  details?: Record<string, any>;
}

// Error Codes and Status Codes
export const ERROR_CODES = {
  // Authentication
  UNAUTHORIZED: { message: 'Authentication required', statusCode: 401 },
  FORBIDDEN: { message: 'Access denied', statusCode: 403 },
  INVALID_TOKEN: { message: 'Invalid authentication token', statusCode: 401 },

  // Validation
  VALIDATION_FAILED: { message: 'Input validation failed', statusCode: 400 },
  INVALID_EMAIL_FORMAT: { message: 'Invalid email format', statusCode: 400 },
  INVALID_PHONE_FORMAT: { message: 'Invalid phone format', statusCode: 400 },
  INVALID_ROLE: { message: 'Invalid user role', statusCode: 400 },
  INVALID_STATE_TRANSITION: { message: 'Invalid state transition', statusCode: 400 },

  // Business Logic
  RESOURCE_NOT_FOUND: { message: 'Resource not found', statusCode: 404 },
  RESOURCE_ALREADY_EXISTS: { message: 'Resource already exists', statusCode: 409 },
  INSUFFICIENT_PERMISSIONS: { message: 'Insufficient permissions', statusCode: 403 },

  // System
  INTERNAL_ERROR: { message: 'Internal server error', statusCode: 500 },
  SERVICE_UNAVAILABLE: { message: 'Service temporarily unavailable', statusCode: 503 },
} as const;

// Create App Error
export function createError(
  code: keyof typeof ERROR_CODES,
  message?: string,
  details?: Record<string, any>
): AppError {
  const errorConfig = ERROR_CODES[code];
  const error = new Error(message || errorConfig.message) as AppError;
  error.code = code;
  error.statusCode = errorConfig.statusCode;
  error.timestamp = Date.now();
  error.details = details;
  error.name = 'AppError';
  return error;
}

// Check if error is AppError
export function isAppError(error: any): error is AppError {
  return error && typeof error === 'object' && error.name === 'AppError';
}

// Truncate error for client (remove sensitive data)
export function truncateErrorForClient(error: AppError): {
  code: string;
  message: string;
  statusCode: number;
  timestamp: number;
  requestId?: string;
} {
  return {
    code: error.code,
    message: error.message,
    statusCode: error.statusCode,
    timestamp: error.timestamp,
    requestId: error.requestId,
  };
}

// Error Handler Middleware
export function errorHandler(
  error: Error | AppError,
  req: Request & { requestId?: string },
  res: Response,
  next: NextFunction
): void {
  // Attach requestId to error
  if (isAppError(error)) {
    error.requestId = req.requestId;
  }

  // Log full error (server-side)
  console.error('Error occurred:', {
    code: isAppError(error) ? error.code : 'UNKNOWN_ERROR',
    message: error.message,
    stack: error.stack,
    requestId: req.requestId,
    timestamp: Date.now(),
    details: isAppError(error) ? error.details : undefined,
  });

  // Determine response
  let responseError: AppError;
  if (isAppError(error)) {
    responseError = error;
  } else {
    // Unknown error
    responseError = createError('INTERNAL_ERROR');
  }

  // Send truncated error to client
  const clientError = truncateErrorForClient(responseError);
  res.status(responseError.statusCode).json({ error: clientError });
}

// Async Error Wrapper
export function asyncHandler(fn: Function) {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}