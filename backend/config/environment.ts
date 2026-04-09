// ============================================================================
// ENVIRONMENT CONFIGURATION
// Validation and loading of environment variables
// ============================================================================

import { z } from 'zod';

// Environment schema
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  FIREBASE_PROJECT_ID: z.string().min(1),
  FIREBASE_SERVICE_ACCOUNT_KEY: z.string().optional(), // For local dev
  LOG_LEVEL: z.enum(['error', 'warn', 'info', 'debug']).default('info'),
  PORT: z.coerce.number().default(5001),
  // Add more as needed for future etapas
});

// Parse and validate environment
let env: z.infer<typeof envSchema>;

try {
  env = envSchema.parse(process.env);
} catch (error) {
  console.error('Environment validation failed:', error);
  process.exit(1);
}

export { env };