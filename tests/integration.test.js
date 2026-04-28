/**
 * tests/integration.test.js
 * Tests de integración – idempotencia de webhook, token one-time, expiración de reservas.
 * Usa mocks de Firestore para no requerir emulador.
 */

"use strict";

// ─── Mock Firestore ───────────────────────────────────────────────────────────
const mockFirestoreData = new Map();
const mockTransactionGet = jest.fn();
const mockTransactionSet = jest.fn();
const mockTransactionUpdate = jest.fn();

const mockTransaction = {
  get: mockTransactionGet,
  set: mockTransactionSet,
  update: mockTransactionUpdate,
};

const mockAdd = jest.fn().mockResolvedValue({ id: "mock-id" });
const mockUpdate = jest.fn().mockResolvedValue({});
const mockSet = jest.fn().mockResolvedValue({});
const mockGet = jest.fn();
const mockWhere = jest.fn();
const mockLimit = jest.fn();
const mockOrderBy = jest.fn();
const mockRunTransaction = jest.fn((fn) => fn(mockTransaction));

// Chainable mock
const makeQueryChain = (finalGet) => {
  const chain = {
    where: jest.fn(() => chain),
    limit: jest.fn(() => chain),
    orderBy: jest.fn(() => chain),
    get: finalGet || jest.fn().mockResolvedValue({ empty: true, docs: [] }),
  };
  return chain;
};

jest.mock("../backend/shared/firestore/admin", () => ({
  apps: [{}],
  initializeApp: jest.fn(),
  firestore: Object.assign(
    jest.fn(() => ({
      collection: jest.fn((name) => ({
        doc: jest.fn((id) => ({
          get: mockGet,
          set: mockSet,
          update: mockUpdate,
          ref: { update: mockUpdate },
          collection: jest.fn(() => ({
            doc: jest.fn(() => ({ set: jest.fn(), get: jest.fn(), id: "msg-id" })),
            orderBy: jest.fn(() => ({ limit: jest.fn(() => ({ get: jest.fn().mockResolvedValue({ docs: [] }) })) })),
          })),
        })),
        add: mockAdd,
        where: () => makeQueryChain(),
        orderBy: () => makeQueryChain(),
        limit: () => ({ get: jest.fn().mockResolvedValue({ empty: true, docs: [] }) }),
      })),
      runTransaction: mockRunTransaction,
      batch: jest.fn(() => ({
        update: jest.fn(),
        set: jest.fn(),
        commit: jest.fn().mockResolvedValue({}),
      })),
    })),
    {
      FieldValue: {
        serverTimestamp: () => new Date(),
        arrayUnion: (...args) => args,
        increment: (n) => n,
      },
    }
  ),
  auth: jest.fn(() => ({ verifyIdToken: jest.fn(), setCustomUserClaims: jest.fn() })),
  messaging: jest.fn(() => ({ sendEachForMulticast: jest.fn().mockResolvedValue({ successCount: 1, failureCount: 0, responses: [] }) })),
  storage: jest.fn(() => ({ bucket: jest.fn(() => ({ file: jest.fn(() => ({ getSignedUrl: jest.fn(), exists: jest.fn().mockResolvedValue([true]), makePublic: jest.fn(), delete: jest.fn(), getMetadata: jest.fn().mockResolvedValue([{}]) })) })) })),
}));

jest.mock("ngeohash", () => ({
  encode: () => "abc123",
  neighbors: () => ["abc124", "abc125"],
}));

jest.mock("axios", () => ({
  post: jest.fn(),
  get: jest.fn(),
}));

const crypto = require("crypto");

// ─── Test: Idempotencia de Webhook ────────────────────────────────────────────

describe("Idempotencia de Webhook Bold", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test("Primer evento se procesa (checkAndMark no lanza)", async () => {
    // Simular que el documento NO existe
    mockTransactionGet.mockResolvedValueOnce({ exists: false });

    const { checkAndMark } = require("../backend/shared/idempotency/index");

    await expect(checkAndMark("bold_txn_001", { reference: "REF-001" }))
      .resolves.not.toThrow();
  });

  test("Segundo evento idéntico lanza IdempotencyError", async () => {
    // Simular que el documento YA existe
    mockTransactionGet.mockResolvedValueOnce({
      exists: true,
      data: () => ({ processedAt: new Date() }),
    });

    const { checkAndMark } = require("../backend/shared/idempotency/index");
    const { IdempotencyError } = require("../backend/shared/errors");

    await expect(checkAndMark("bold_txn_001", {})).rejects.toThrow(IdempotencyError);
  });
});

// ─── Test: Token One-Time ─────────────────────────────────────────────────────

describe("Token NDVI one-time", () => {
  test("Token SHA-256 es diferente al raw token", () => {
    const raw = crypto.randomBytes(32).toString("hex");
    const hashed = crypto.createHash("sha256").update(raw).digest("hex");
    expect(raw).not.toBe(hashed);
    expect(hashed).toHaveLength(64);
  });

  test("Mismo raw token siempre produce mismo hash", () => {
    const raw = "test-token-123";
    const hash1 = crypto.createHash("sha256").update(raw).digest("hex");
    const hash2 = crypto.createHash("sha256").update(raw).digest("hex");
    expect(hash1).toBe(hash2);
  });

  test("Tokens distintos producen hashes distintos", () => {
    const hash1 = crypto.createHash("sha256").update("token1").digest("hex");
    const hash2 = crypto.createHash("sha256").update("token2").digest("hex");
    expect(hash1).not.toBe(hash2);
  });

  test("Token expirado es detectado correctamente", () => {
    const expiresAt = { toDate: () => new Date(Date.now() - 1000) };
    const isExpired = new Date() > expiresAt.toDate();
    expect(isExpired).toBe(true);
  });

  test("Token válido no está expirado", () => {
    const expiresAt = { toDate: () => new Date(Date.now() + 3600000) };
    const isExpired = new Date() > expiresAt.toDate();
    expect(isExpired).toBe(false);
  });
});

// ─── Test: Expiración de reservas ────────────────────────────────────────────

describe("Expiración de reservas", () => {
  const { isExpired } = require("../backend/models/reserva.model");

  test("Reserva vencida hace 1 hora está expirada", () => {
    const reserva = { expiresAt: new Date(Date.now() - 60 * 60 * 1000) };
    expect(isExpired(reserva)).toBe(true);
  });

  test("Reserva que vence en 5 minutos no está expirada", () => {
    const reserva = { expiresAt: new Date(Date.now() + 5 * 60 * 1000) };
    expect(isExpired(reserva)).toBe(false);
  });
});

// ─── Test: Mapeo de estados legacy ───────────────────────────────────────────

describe("Mapeo estados UI legacy → canónicos", () => {
  const TerrenoModel = require("../backend/models/terreno.model");

  const casos = [
    ["Activo", "disponible"],
    ["Confirmado", "reservado"],
    ["Pendiente", "en_espera"],
  ];

  test.each(casos)("'%s' se mapea a '%s'", (legacy, canonical) => {
    expect(TerrenoModel.mapLegacyStatus(legacy)).toBe(canonical);
  });
});

// ─── Test: Error handler ──────────────────────────────────────────────────────

describe("Error handler Express", () => {
  const { AppError, ValidationError, NotFoundError, errorHandler } = require("../backend/shared/errors");

  function mockResponse() {
    const res = {};
    res.status = jest.fn(() => res);
    res.json = jest.fn(() => res);
    return res;
  }

  test("AppError se mapea al httpStatus correcto", () => {
    const err = new ValidationError("Campo inválido", ["email inválido"]);
    const req = { requestId: "test-req" };
    const res = mockResponse();
    const next = jest.fn();

    errorHandler(err, req, res, next);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ ok: false, code: "VALIDATION_ERROR" })
    );
  });

  test("NotFoundError retorna 404", () => {
    const err = new NotFoundError("Terreno");
    const req = { requestId: "x" };
    const res = mockResponse();

    errorHandler(err, req, res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(404);
  });

  test("Error genérico retorna 500", () => {
    const err = new Error("Error inesperado");
    const req = { requestId: "x" };
    const res = mockResponse();

    errorHandler(err, req, res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ code: "INTERNAL_ERROR" })
    );
  });
});
