// ============================================================================
// VALIDATION UNIT TESTS
// Etapa A - Test Zod schemas and validation functions
// ============================================================================

import { validateUser, validateTerreno, validateReserva, validatePaymentEvent } from '../shared/validation';

describe('Validation Tests', () => {
  describe('validateUser', () => {
    it('should validate valid user data', () => {
      const validUser = {
        uid: 'a'.repeat(20),
        email: 'user@example.com',
        fullName: 'John Doe',
        phone: '912345678',
        phonePrefix: '+1',
        role: 'owner' as const,
        status: 'active' as const,
        createdAt: Date.now(),
        updatedAt: Date.now(),
      };

      const result = validateUser(validUser);
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should reject invalid email', () => {
      const invalidUser = {
        uid: 'a'.repeat(20),
        email: 'invalid-email',
        fullName: 'John Doe',
        phone: '912345678',
        phonePrefix: '+1',
        role: 'owner' as const,
        status: 'active' as const,
        createdAt: Date.now(),
        updatedAt: Date.now(),
      };

      const result = validateUser(invalidUser);
      expect(result.valid).toBe(false);
      expect(result.errors).toContainEqual(
        expect.objectContaining({
          field: 'email',
          code: 'INVALID_STRING',
        })
      );
    });

    it('should reject invalid role', () => {
      const invalidUser = {
        uid: 'a'.repeat(20),
        email: 'user@example.com',
        fullName: 'John Doe',
        phone: '912345678',
        phonePrefix: '+1',
        role: 'admin', // Invalid role
        status: 'active' as const,
        createdAt: Date.now(),
        updatedAt: Date.now(),
      };

      const result = validateUser(invalidUser);
      expect(result.valid).toBe(false);
    });
  });

  describe('validateTerreno', () => {
    it('should validate valid terreno data', () => {
      const validTerreno = {
        id: 'test-id',
        ownerId: 'owner-uid',
        title: 'Beautiful Land',
        description: 'A great piece of land for pasture'.repeat(5),
        sizeHectares: 50,
        location: {
          latitude: -33.4489,
          longitude: -70.6693,
          geohash: '66j',
        },
        priceMonthly: 100000,
        features: ['irrigation', 'power'],
        images: [{ url: 'https://example.com/image.jpg' }],
        status: 'disponible' as const,
        createdAt: Date.now(),
        updatedAt: Date.now(),
      };

      const result = validateTerreno(validTerreno);
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should reject title too short', () => {
      const invalidTerreno = {
        id: 'test-id',
        ownerId: 'owner-uid',
        title: 'Hi', // Too short
        description: 'A great piece of land for pasture'.repeat(5),
        sizeHectares: 50,
        location: {
          latitude: -33.4489,
          longitude: -70.6693,
          geohash: '66j',
        },
        priceMonthly: 100000,
        features: [],
        images: [],
        status: 'disponible' as const,
        createdAt: Date.now(),
        updatedAt: Date.now(),
      };

      const result = validateTerreno(invalidTerreno);
      expect(result.valid).toBe(false);
    });
  });

  describe('validateReserva', () => {
    it('should validate valid reserva data', () => {
      const validReserva = {
        id: 'reserva-id',
        terrenoId: 'terreno-id',
        renterId: 'renter-uid',
        ownerId: 'owner-uid',
        startDate: Date.now() + 86400000, // Tomorrow
        endDate: Date.now() + 86400000 * 30, // 30 days later
        durationDays: 30,
        pricePerMonth: 100000,
        estimatedTotal: 3000000,
        status: 'en_espera' as const,
        createdAt: Date.now(),
        updatedAt: Date.now(),
      };

      const result = validateReserva(validReserva);
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });
  });

  describe('validatePaymentEvent', () => {
    it('should validate valid payment event', () => {
      const validPayment = {
        id: 'payment-id',
        reservaId: 'reserva-id',
        terrenoId: 'terreno-id',
        amount: 3000000,
        currency: 'CLP',
        boldReference: 'bold-ref-123',
        status: 'pending' as const,
        createdAt: Date.now(),
        updatedAt: Date.now(),
      };

      const result = validatePaymentEvent(validPayment);
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });
  });
});