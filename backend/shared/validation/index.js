/**
 * shared/validation/index.js
 * Schemas de validación Joi para todos los dominios.
 * Importar el schema específico en cada controlador.
 */

"use strict";

const Joi = require("joi");

// ─── Helpers comunes ─────────────────────────────────────────────────────────
const phonePrefix = Joi.string().pattern(/^\+\d{1,4}$/).required();
const phone = Joi.string().pattern(/^\d{7,15}$/).required();
const latLng = Joi.object({
  lat: Joi.number().min(-90).max(90).required(),
  lng: Joi.number().min(-180).max(180).required(),
});

// ─── AUTH ────────────────────────────────────────────────────────────────────
const registerSchema = Joi.object({
  fullName: Joi.string().min(2).max(100).required(),
  email: Joi.string().email().required(),
  password: Joi.string().min(8).max(128).required(),
  phonePrefix,
  phone,
  role: Joi.string().valid("owner", "renter").required(),
});

const onboardingSchema = Joi.object({
  bio: Joi.string().max(500).optional(),
  location: latLng.optional(),
  acceptedTerms: Joi.boolean().valid(true).required(),
});

// ─── TERRENOS ────────────────────────────────────────────────────────────────
const VALID_FEATURES = ["riego", "energia", "caminos", "certificacion"];
const CANONICAL_STATUSES = ["disponible", "reservado", "en_espera", "inactivo"];

const createTerrenoSchema = Joi.object({
  title: Joi.string().min(5).max(120).required(),
  description: Joi.string().min(10).max(2000).required(),
  sizeHectares: Joi.number().positive().max(100000).required(),
  priceMonthly: Joi.number().positive().required(),
  features: Joi.array().items(Joi.string().valid(...VALID_FEATURES)).default([]),
  location: latLng.required(),
  address: Joi.string().max(200).optional(),
});

const updateTerrenoSchema = Joi.object({
  title: Joi.string().min(5).max(120),
  description: Joi.string().min(10).max(2000),
  sizeHectares: Joi.number().positive().max(100000),
  priceMonthly: Joi.number().positive(),
  features: Joi.array().items(Joi.string().valid(...VALID_FEATURES)),
  address: Joi.string().max(200),
}).min(1);

const changeStatusSchema = Joi.object({
  status: Joi.string().valid(...CANONICAL_STATUSES).required(),
  reason: Joi.string().max(500).optional(),
});

// ─── RESERVAS / PAGOS ────────────────────────────────────────────────────────
const createReservaSchema = Joi.object({
  terrenoId: Joi.string().required(),
  startDate: Joi.date().iso().greater("now").required(),
  endDate: Joi.date().iso().greater(Joi.ref("startDate")).required(),
  acceptedTerms: Joi.boolean().valid(true).required(),
});

// ─── MENSAJERÍA ──────────────────────────────────────────────────────────────
const sendMessageSchema = Joi.object({
  text: Joi.string().min(1).max(2000).required(),
});

// ─── REVIEWS ─────────────────────────────────────────────────────────────────
const createReviewSchema = Joi.object({
  reservaId: Joi.string().required(),
  score: Joi.number().integer().min(1).max(5).required(),
  comment: Joi.string().min(5).max(1000).required(),
});

// ─── SEÑALES DE COMPORTAMIENTO ───────────────────────────────────────────────
const behaviorSignalSchema = Joi.object({
  type: Joi.string().valid("view", "search", "favorite", "book").required(),
  terrenoId: Joi.string().when("type", {
    is: Joi.valid("view", "favorite"),
    then: Joi.required(),
    otherwise: Joi.optional(),
  }),
  searchQuery: Joi.object().when("type", {
    is: "search",
    then: Joi.required(),
    otherwise: Joi.optional(),
  }),
});

/**
 * Middleware de validación reutilizable.
 * Uso: router.post("/", validate(createTerrenoSchema), handler)
 */
function validate(schema, property = "body") {
  return (req, res, next) => {
    const { error, value } = schema.validate(req[property], { abortEarly: false, stripUnknown: true });
    if (error) {
      const { ValidationError } = require("../errors");
      return next(new ValidationError(
        "Datos de entrada inválidos",
        error.details.map((d) => d.message)
      ));
    }
    req[property] = value;
    next();
  };
}

module.exports = {
  registerSchema,
  onboardingSchema,
  createTerrenoSchema,
  updateTerrenoSchema,
  changeStatusSchema,
  createReservaSchema,
  sendMessageSchema,
  createReviewSchema,
  behaviorSignalSchema,
  CANONICAL_STATUSES,
  VALID_FEATURES,
  validate,
};
