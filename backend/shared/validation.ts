export function validatePaymentEvent(data: any): ValidationResult {
  return validateData(PAYMENT_EVENT_VALIDATION_RULES, data);
}

/**
 * Centralized Data Validation Module
 * Implements a generic validator and per-model wrappers.
 * All errors are structured as { field, code, message }.
 */

import {
  USER_VALIDATION_RULES,
  TERRENO_VALIDATION_RULES,
  RESERVA_VALIDATION_RULES,
  PAYMENT_EVENT_VALIDATION_RULES,
  CONVERSACION_VALIDATION_RULES,
  MENSAJE_VALIDATION_RULES,
  REVIEW_VALIDATION_RULES,
} from '../models/validation-rules';

export interface ValidationError {
  field: string;
  code: string;
  message: string;
}

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
}

// Generic validator
export function validateData(rules: any, data: any): ValidationResult {
  const errors: ValidationError[] = [];
  for (const field in rules) {
    const rule = rules[field];
    const value = data[field];

    // Required
    if (rule.required && (value === undefined || value === null || value === '')) {
      errors.push({ field, code: 'REQUIRED', message: `${field} is required` });
      continue;
    }
    if (value === undefined || value === null) continue;

    // Type
    if (rule.type && typeof value !== rule.type && rule.type !== 'enum' && rule.type !== 'array<string>' && rule.type !== 'object') {
      errors.push({ field, code: 'TYPE', message: `${field} must be of type ${rule.type}` });
      continue;
    }

    // Enum
    if (rule.type === 'enum' && rule.enum && !rule.enum.includes(value)) {
      errors.push({ field, code: 'ENUM', message: `${field} must be one of: ${rule.enum.join(', ')}` });
      continue;
    }

    // Pattern
    if (rule.pattern && typeof value === 'string' && !rule.pattern.test(value)) {
      errors.push({ field, code: 'PATTERN', message: `${field} does not match required pattern` });
      continue;
    }

    // Min/Max Length
    if (rule.minLength && value.length < rule.minLength) {
      errors.push({ field, code: 'MIN_LENGTH', message: `${field} must be at least ${rule.minLength} chars` });
    }
    if (rule.maxLength && value.length > rule.maxLength) {
      errors.push({ field, code: 'MAX_LENGTH', message: `${field} must be at most ${rule.maxLength} chars` });
    }

    // Min/Max Value
    if (rule.minValue && typeof value === 'number' && value <= parseFloat(rule.minValue.replace('> ', ''))) {
      errors.push({ field, code: 'MIN_VALUE', message: `${field} must be > ${rule.minValue.replace('> ', '')}` });
    }
    if (rule.maxValue && typeof value === 'number' && value > parseFloat(rule.maxValue)) {
      errors.push({ field, code: 'MAX_VALUE', message: `${field} must be <= ${rule.maxValue}` });
    }

    // Array validation
    if (rule.type && rule.type.startsWith('array')) {
      if (!Array.isArray(value)) {
        errors.push({ field, code: 'TYPE', message: `${field} must be an array` });
        continue;
      }
      if (rule.minItems !== undefined && value.length < rule.minItems) {
        errors.push({ field, code: 'MIN_ITEMS', message: `${field} must have at least ${rule.minItems} items` });
      }
      if (rule.maxItems !== undefined && value.length > rule.maxItems) {
        errors.push({ field, code: 'MAX_ITEMS', message: `${field} must have at most ${rule.maxItems} items` });
      }
      if (rule.validValues) {
        for (const v of value) {
          if (!rule.validValues.includes(v)) {
            errors.push({ field, code: 'INVALID_VALUE', message: `${field} contains invalid value: ${v}` });
          }
        }
      }
    }

    // Object validation (for subfields)
    if (rule.type === 'object' && rule.subfields) {
      for (const sub in rule.subfields) {
        const subRule = rule.subfields[sub];
        const subValue = value[sub];
        if (subRule.required && (subValue === undefined || subValue === null)) {
          errors.push({ field: `${field}.${sub}`, code: 'REQUIRED', message: `${field}.${sub} is required` });
        }
        // Type, range, pattern, etc. for subfields
        if (subRule.type && typeof subValue !== subRule.type) {
          errors.push({ field: `${field}.${sub}`, code: 'TYPE', message: `${field}.${sub} must be of type ${subRule.type}` });
        }
        if (subRule.pattern && typeof subValue === 'string' && !subRule.pattern.test(subValue)) {
          errors.push({ field: `${field}.${sub}`, code: 'PATTERN', message: `${field}.${sub} does not match required pattern` });
        }
        if (subRule.range) {
          const [min, max] = subRule.range.replace('[', '').replace(']', '').split(',').map(Number);
          if (typeof subValue === 'number' && (subValue < min || subValue > max)) {
            errors.push({ field: `${field}.${sub}`, code: 'RANGE', message: `${field}.${sub} must be in range [${min}, ${max}]` });
          }
        }
      }
    }
  }
  return errors.length === 0 ? { valid: true, errors: [] } : { valid: false, errors };
}


// Per-model wrappers
export function validateUser(data: any): ValidationResult {
  return validateData(USER_VALIDATION_RULES, data);
}
export function validateTerreno(data: any): ValidationResult {
  return validateData(TERRENO_VALIDATION_RULES, data);
}
export function validateReserva(data: any): ValidationResult {
  return validateData(RESERVA_VALIDATION_RULES, data);
}
export function validateConversacion(data: any): ValidationResult {
  return validateData(CONVERSACION_VALIDATION_RULES, data);
}
export function validateMensaje(data: any): ValidationResult {
  return validateData(MENSAJE_VALIDATION_RULES, data);
}
export function validateReview(data: any): ValidationResult {
  return validateData(REVIEW_VALIDATION_RULES, data);
}


