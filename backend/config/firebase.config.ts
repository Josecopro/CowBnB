import { initializeFirebaseAdmin } from '../shared/auth';

// ============================================================================
// FIREBASE CONFIGURATION
// Initialize Admin SDK and environment validation
// ============================================================================

// Environment variables validation
const requiredEnvVars = [
  'FIREBASE_PROJECT_ID',
  // Add more as needed
];

export function validateEnvironment(): void {
  const missing = requiredEnvVars.filter(key => !process.env[key]);

  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
}

// Initialize Firebase
export function initializeFirebase(): void {
  validateEnvironment();
  initializeFirebaseAdmin();
}

// Export for use in functions
export { auth, firestore } from '../shared/auth';