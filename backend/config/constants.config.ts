// ============================================================================
// DOMAIN CONSTANTS
// Business logic constants and enums
// ============================================================================

// User roles
export const USER_ROLES = {
  OWNER: 'owner',
  RENTER: 'renter',
} as const;

// Terreno statuses
export const TERRENO_STATUSES = {
  DISPONIBLE: 'disponible',
  RESERVADO: 'reservado',
  EN_ESPERA: 'en_espera',
  INACTIVO: 'inactivo',
} as const;

// Reserva statuses
export const RESERVA_STATUSES = {
  EN_ESPERA: 'en_espera',
  RESERVADO: 'reservado',
  ACTIVA: 'activa',
  FINALIZADA: 'finalizada',
  CANCELADA: 'cancelada',
} as const;

// Payment statuses
export const PAYMENT_STATUSES = {
  PENDING: 'pending',
  APPROVED: 'approved',
  REJECTED: 'rejected',
  CANCELLED: 'cancelled',
} as const;

// NDVI statuses
export const NDVI_STATUSES = {
  GREEN: 'green',
  YELLOW: 'yellow',
  RED: 'red',
} as const;

// Features disponibles
export const TERRENO_FEATURES = {
  IRRIGATION: 'irrigation',
  POWER: 'power',
  ROADS: 'roads',
  CERTIFICATION: 'certification',
} as const;

// Valid state transitions
export const VALID_TRANSITIONS = {
  TERRENO: {
    [TERRENO_STATUSES.DISPONIBLE]: [TERRENO_STATUSES.RESERVADO, TERRENO_STATUSES.EN_ESPERA],
    [TERRENO_STATUSES.RESERVADO]: [TERRENO_STATUSES.DISPONIBLE],
    [TERRENO_STATUSES.EN_ESPERA]: [TERRENO_STATUSES.DISPONIBLE, TERRENO_STATUSES.RESERVADO],
    [TERRENO_STATUSES.INACTIVO]: [],
  },
  RESERVA: {
    [RESERVA_STATUSES.EN_ESPERA]: [RESERVA_STATUSES.RESERVADO, RESERVA_STATUSES.CANCELADA],
    [RESERVA_STATUSES.RESERVADO]: [RESERVA_STATUSES.ACTIVA, RESERVA_STATUSES.CANCELADA],
    [RESERVA_STATUSES.ACTIVA]: [RESERVA_STATUSES.FINALIZADA],
    [RESERVA_STATUSES.FINALIZADA]: [],
    [RESERVA_STATUSES.CANCELADA]: [],
  },
} as const;

// Business rules constants
export const BUSINESS_RULES = {
  MIN_TERRENO_TITLE_LENGTH: 5,
  MAX_TERRENO_TITLE_LENGTH: 100,
  MIN_TERRENO_DESCRIPTION_LENGTH: 20,
  MAX_TERRENO_DESCRIPTION_LENGTH: 2000,
  MAX_TERRENO_IMAGES: 10,
  MAX_TERRENO_SIZE_HECTARES: 100000,
  MAX_PRICE_MONTHLY: 10000000,
  MIN_RESERVATION_DAYS: 1,
  MAX_RESERVATION_DAYS: 9999,
  IDEMPOTENCY_TTL_SECONDS: 86400, // 24 hours
  ACTION_TOKEN_TTL_SECONDS: 604800, // 7 days
} as const;

// Error messages (English for consistency)
export const ERROR_MESSAGES = {
  INVALID_EMAIL_FORMAT: 'Invalid email format',
  INVALID_PHONE_FORMAT: 'Invalid phone format',
  INVALID_ROLE: 'Invalid user role',
  INVALID_STATE_TRANSITION: 'Invalid state transition',
  RESOURCE_NOT_FOUND: 'Resource not found',
  RESOURCE_ALREADY_EXISTS: 'Resource already exists',
  INSUFFICIENT_PERMISSIONS: 'Insufficient permissions',
  UNAUTHORIZED: 'Authentication required',
  FORBIDDEN: 'Access denied',
} as const;