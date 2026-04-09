import winston from 'winston';

// ============================================================================
// LOGGING UTILITY
// Structured JSON logging with requestId support
// ============================================================================

// Log levels
export const LOG_LEVELS = {
  error: 0,
  warn: 1,
  info: 2,
  debug: 3,
} as const;

// Create logger instance
export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'cowbnb-backend' },
  transports: [
    // Console transport for development
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      ),
    }),
    // File transport for production (optional)
    ...(process.env.NODE_ENV === 'production' ? [
      new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
      new winston.transports.File({ filename: 'logs/combined.log' }),
    ] : []),
  ],
});

// Helper functions for logging with requestId
export function logInfo(message: string, meta?: Record<string, any>, requestId?: string) {
  logger.info(message, { ...meta, requestId });
}

export function logError(message: string, error?: Error, meta?: Record<string, any>, requestId?: string) {
  logger.error(message, {
    ...meta,
    requestId,
    error: error ? {
      message: error.message,
      stack: error.stack,
      name: error.name,
    } : undefined,
  });
}

export function logWarn(message: string, meta?: Record<string, any>, requestId?: string) {
  logger.warn(message, { ...meta, requestId });
}

export function logDebug(message: string, meta?: Record<string, any>, requestId?: string) {
  logger.debug(message, { ...meta, requestId });
}

// Request logging middleware helper
export function createRequestLogger() {
  return (req: any, res: any, next: any) => {
    const start = Date.now();
    const requestId = req.requestId;

    logInfo('Request started', {
      method: req.method,
      url: req.url,
      userAgent: req.get('User-Agent'),
      ip: req.ip,
    }, requestId);

    res.on('finish', () => {
      const duration = Date.now() - start;
      logInfo('Request completed', {
        method: req.method,
        url: req.url,
        statusCode: res.statusCode,
        duration: `${duration}ms`,
      }, requestId);
    });

    next();
  };
}