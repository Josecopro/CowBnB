/**
 * tests/unit.test.js
 * Tests unitarios de validaciones, máquina de estados, modelos e idempotencia.
 * No requieren Firebase emulador.
 */

"use strict";

// Mock firebase-admin para tests unitarios
jest.mock("firebase-admin", () => ({
  apps: [{}],
  initializeApp: jest.fn(),
  firestore: Object.assign(
    jest.fn(() => ({ collection: jest.fn() })),
    {
      FieldValue: {
        serverTimestamp: () => new Date(),
        arrayUnion: (...args) => args,
        increment: (n) => n,
      },
    }
  ),
  auth: jest.fn(() => ({ verifyIdToken: jest.fn() })),
  messaging: jest.fn(),
  storage: jest.fn(() => ({ bucket: jest.fn() })),
}));

jest.mock("ngeohash", () => ({
  encode: (lat, lng) => `gh_${lat}_${lng}`,
  neighbors: () => ["abc", "def", "ghi"],
}));

const TerrenoModel = require("../backend/models/terreno.model");
const ReservaModel = require("../backend/models/reserva.model");
const { registerSchema, createTerrenoSchema, createReservaSchema } = require("../backend/shared/validation/index");

// ─── TerrenoModel: máquina de estados ────────────────────────────────────────

describe("TerrenoModel – Máquina de estados", () => {
  test("Transición válida: disponible → en_espera", () => {
    expect(() => TerrenoModel.validateTransition("disponible", "en_espera", false)).not.toThrow();
  });

  test("Transición válida: disponible → inactivo (owner)", () => {
    expect(() => TerrenoModel.validateTransition("disponible", "inactivo", false)).not.toThrow();
  });

  test("Transición inválida: disponible → reservado desde cliente", () => {
    expect(() => TerrenoModel.validateTransition("disponible", "reservado", false)).toThrow(
      "solo puede ser iniciada por el backend"
    );
  });

  test("Transición válida: disponible → reservado desde backend", () => {
    expect(() => TerrenoModel.validateTransition("disponible", "reservado", true)).not.toThrow();
  });

  test("Transición inválida: inactivo → reservado", () => {
    expect(() => TerrenoModel.validateTransition("inactivo", "reservado", true)).toThrow(
      "Transición inválida"
    );
  });

  test("Transición válida: reservado → disponible (finalización)", () => {
    expect(() => TerrenoModel.validateTransition("reservado", "disponible", true)).not.toThrow();
  });
});

describe("TerrenoModel – Mapeo legacy UI", () => {
  test("'Activo' → 'disponible'", () => {
    expect(TerrenoModel.mapLegacyStatus("Activo")).toBe("disponible");
  });

  test("'Confirmado' → 'reservado'", () => {
    expect(TerrenoModel.mapLegacyStatus("Confirmado")).toBe("reservado");
  });

  test("'Pendiente' → 'en_espera'", () => {
    expect(TerrenoModel.mapLegacyStatus("Pendiente")).toBe("en_espera");
  });

  test("Label desconocido → null", () => {
    expect(TerrenoModel.mapLegacyStatus("Desconocido")).toBeNull();
  });
});

// ─── ReservaModel: cálculo de monto y expiración ─────────────────────────────

describe("ReservaModel – calculateAmount", () => {
  test("30 días = 1 mes exacto al precio mensual", () => {
    const start = "2025-01-01";
    const end = "2025-01-31";
    const amount = ReservaModel.calculateAmount(1200, start, end);
    expect(amount).toBeCloseTo(1200, 0);
  });

  test("60 días = 2 meses", () => {
    const start = "2025-01-01";
    const end = "2025-03-02";
    const amount = ReservaModel.calculateAmount(1200, start, end);
    expect(amount).toBeGreaterThan(2300);
    expect(amount).toBeLessThan(2500);
  });
});

describe("ReservaModel – isExpired", () => {
  test("Reserva con expiresAt pasado está expirada", () => {
    const reserva = { expiresAt: new Date(Date.now() - 1000) };
    expect(ReservaModel.isExpired(reserva)).toBe(true);
  });

  test("Reserva con expiresAt futuro no está expirada", () => {
    const reserva = { expiresAt: new Date(Date.now() + 60000) };
    expect(ReservaModel.isExpired(reserva)).toBe(false);
  });

  test("Reserva sin expiresAt no está expirada", () => {
    const reserva = { expiresAt: null };
    expect(ReservaModel.isExpired(reserva)).toBeFalsy();
  });
});

// ─── Validaciones Joi ─────────────────────────────────────────────────────────

describe("registerSchema – validación", () => {
  const validData = {
    fullName: "Carlos Rodríguez",
    email: "carlos@agro.co",
    password: "SuperSecure123",
    phonePrefix: "+57",
    phone: "3001234567",
    role: "owner",
  };

  test("Datos válidos pasan validación", () => {
    const { error } = registerSchema.validate(validData);
    expect(error).toBeUndefined();
  });

  test("Falta fullName → error", () => {
    const { error } = registerSchema.validate({ ...validData, fullName: undefined });
    expect(error).toBeDefined();
  });

  test("Rol inválido → error", () => {
    const { error } = registerSchema.validate({ ...validData, role: "admin" });
    expect(error).toBeDefined();
    expect(error.message).toContain("role");
  });

  test("Password muy corta → error", () => {
    const { error } = registerSchema.validate({ ...validData, password: "123" });
    expect(error).toBeDefined();
  });

  test("Email inválido → error", () => {
    const { error } = registerSchema.validate({ ...validData, email: "no-es-email" });
    expect(error).toBeDefined();
  });

  test("Phone prefix inválido → error", () => {
    const { error } = registerSchema.validate({ ...validData, phonePrefix: "57" }); // falta +
    expect(error).toBeDefined();
  });
});

describe("createTerrenoSchema – validación", () => {
  const validTerreno = {
    title: "Rancho del Sur",
    description: "Excelente terreno con riego y certificación",
    sizeHectares: 25,
    priceMonthly: 1500,
    features: ["riego", "caminos"],
    location: { lat: 4.5, lng: -74.2 },
  };

  test("Terreno válido pasa", () => {
    const { error } = createTerrenoSchema.validate(validTerreno);
    expect(error).toBeUndefined();
  });

  test("Feature inválida → error", () => {
    const { error } = createTerrenoSchema.validate({
      ...validTerreno,
      features: ["feature_inexistente"],
    });
    expect(error).toBeDefined();
  });

  test("sizeHectares negativo → error", () => {
    const { error } = createTerrenoSchema.validate({
      ...validTerreno,
      sizeHectares: -5,
    });
    expect(error).toBeDefined();
  });

  test("Sin location → error", () => {
    const { error } = createTerrenoSchema.validate({
      ...validTerreno,
      location: undefined,
    });
    expect(error).toBeDefined();
  });
});

// ─── TerrenoModel: buildHistoryEntry ─────────────────────────────────────────

describe("TerrenoModel – buildHistoryEntry", () => {
  test("Genera entrada con campos correctos", () => {
    const entry = TerrenoModel.buildHistoryEntry("disponible", "user123", "Test");
    expect(entry.status).toBe("disponible");
    expect(entry.changedBy).toBe("user123");
    expect(entry.reason).toBe("Test");
    expect(entry.changedAt).toBeDefined();
  });
});

// ─── STATUS constants ─────────────────────────────────────────────────────────

describe("Constantes de estados canónicos", () => {
  test("TerrenoModel.STATUS tiene todos los estados requeridos", () => {
    expect(TerrenoModel.STATUS.DISPONIBLE).toBe("disponible");
    expect(TerrenoModel.STATUS.RESERVADO).toBe("reservado");
    expect(TerrenoModel.STATUS.EN_ESPERA).toBe("en_espera");
    expect(TerrenoModel.STATUS.INACTIVO).toBe("inactivo");
  });

  test("ReservaModel.STATUS tiene todos los estados requeridos", () => {
    expect(ReservaModel.STATUS.EN_ESPERA).toBe("en_espera");
    expect(ReservaModel.STATUS.RESERVADO).toBe("reservado");
    expect(ReservaModel.STATUS.CANCELADO).toBe("cancelado");
    expect(ReservaModel.STATUS.FINALIZADO).toBe("finalizado");
  });

  test("ReservaModel.PAYMENT_STATUS tiene los estados de pago", () => {
    expect(ReservaModel.PAYMENT_STATUS.PENDIENTE).toBe("pendiente");
    expect(ReservaModel.PAYMENT_STATUS.APROBADO).toBe("aprobado");
    expect(ReservaModel.PAYMENT_STATUS.RECHAZADO).toBe("rechazado");
    expect(ReservaModel.PAYMENT_STATUS.REEMBOLSADO).toBe("reembolsado");
  });
});
