import { z } from 'zod';

// ============================================================================
// ZOD SCHEMAS FOR VALIDATION
// Based on validation-rules.ts
// ============================================================================

// User Schema
export const UserSchema = z.object({
  uid: z.string().regex(/^[a-zA-Z0-9]{20,}$/, 'Invalid Firebase UID format'),
  email: z.string().email().min(5).max(254),
  fullName: z.string().min(2).max(100).regex(/^[a-zA-Z\s\-áéíóúñÁÉÍÓÚÑ]+$/, 'Only letters, spaces, hyphens allowed'),
  phone: z.string().regex(/^[0-9]{7,15}$/, 'Phone must be 7-15 digits only'),
  phonePrefix: z.string().regex(/^\+[0-9]{1,3}$/, 'Invalid phone prefix format'),
  role: z.enum(['owner', 'renter']),
  status: z.enum(['active', 'suspended', 'deleted']).default('active'),
  createdAt: z.number().int().positive(),
  updatedAt: z.number().int().positive(),
  profileImageUrl: z.string().url().regex(/^https:\/\/.*\.(jpeg|jpg|png|webp)$/).optional(),
  bio: z.string().max(500).optional(),
});

// Terreno Schema
export const TerrenoSchema = z.object({
  id: z.string(),
  ownerId: z.string(),
  title: z.string().min(5).max(100),
  description: z.string().min(20).max(2000),
  sizeHectares: z.number().positive().max(100000),
  location: z.object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
    geohash: z.string().min(6).max(8),
  }),
  priceMonthly: z.number().int().positive().max(10000000),
  features: z.array(z.enum(['irrigation', 'power', 'roads', 'certification'])).max(10),
  images: z.array(z.object({
    url: z.string().url(),
    alt: z.string().optional(),
  })).max(10),
  status: z.enum(['disponible', 'reservado', 'en_espera', 'inactivo']).default('disponible'),
  createdAt: z.number().int().positive(),
  updatedAt: z.number().int().positive(),
  ratingAvg: z.number().min(0).max(5).optional(),
  ratingCount: z.number().int().min(0).optional(),
  lastNdviCheck: z.number().int().positive().optional(),
  ndviStatus: z.enum(['green', 'yellow', 'red']).optional(),
});

// Reserva Schema (stub for Etapa A)
export const ReservaSchema = z.object({
  id: z.string(),
  terrenoId: z.string(),
  renterId: z.string(),
  ownerId: z.string(),
  startDate: z.number().int().positive(),
  endDate: z.number().int().positive(),
  durationDays: z.number().int().positive().max(9999),
  pricePerMonth: z.number().int().positive(),
  estimatedTotal: z.number().positive(),
  status: z.enum(['en_espera', 'reservado', 'activa', 'finalizada', 'cancelada']).default('en_espera'),
  createdAt: z.number().int().positive(),
  updatedAt: z.number().int().positive(),
});

// PaymentEvent Schema (stub)
export const PaymentEventSchema = z.object({
  id: z.string(),
  reservaId: z.string(),
  terrenoId: z.string(),
  amount: z.number().positive(),
  currency: z.string().default('CLP'),
  boldReference: z.string(),
  status: z.enum(['pending', 'approved', 'rejected', 'cancelled']),
  createdAt: z.number().int().positive(),
  updatedAt: z.number().int().positive(),
});

// Validation Result Type
export interface ValidationResult {
  valid: boolean;
  errors: Array<{
    field: string;
    code: string;
    message: string;
  }>;
}

// Generic Validation Function
export function validateSchema<T>(schema: z.ZodSchema<T>, data: unknown): ValidationResult {
  const result = schema.safeParse(data);
  if (result.success) {
    return { valid: true, errors: [] };
  } else {
    const errors = result.error.errors.map(err => ({
      field: err.path.join('.'),
      code: err.code.toUpperCase(),
      message: err.message,
    }));
    return { valid: false, errors };
  }
}

// Specific Validators
export function validateUser(data: unknown): ValidationResult {
  return validateSchema(UserSchema, data);
}

export function validateTerreno(data: unknown): ValidationResult {
  return validateSchema(TerrenoSchema, data);
}

export function validateReserva(data: unknown): ValidationResult {
  return validateSchema(ReservaSchema, data);
}

export function validatePaymentEvent(data: unknown): ValidationResult {
  return validateSchema(PaymentEventSchema, data);
}