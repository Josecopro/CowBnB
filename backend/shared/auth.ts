import * as admin from 'firebase-admin';
import { Request, Response, NextFunction } from 'express';
import { createError } from './errors';
import { logInfo, logError } from './logging';
import { getCurrentRequestId, setCurrentUserId } from './request-context';

// ============================================================================
// FIREBASE AUTH UTILITIES
// Authentication middleware and helpers
// ============================================================================

// Extended Request interface
export interface AuthRequest extends Request {
  user?: {
    uid: string;
    email?: string;
    role?: 'owner' | 'renter';
    customClaims?: Record<string, any>;
  };
  requestId?: string;
}

// Initialize Firebase Admin SDK (called in config)
export function initializeFirebaseAdmin() {
  if (!admin.apps.length) {
    // In production, use default credentials
    // In development, load from .env.local
    const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_KEY
      ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY)
      : undefined;

    admin.initializeApp({
      credential: serviceAccount
        ? admin.credential.cert(serviceAccount)
        : admin.credential.applicationDefault(),
      projectId: process.env.FIREBASE_PROJECT_ID,
    });

    logInfo('Firebase Admin SDK initialized');
  }
}

// Get Auth instance
export const auth = admin.auth();

// Get Firestore instance
export const firestore = admin.firestore();

// Verify Firebase token middleware
export async function verifyFirebaseToken(
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw createError('UNAUTHORIZED', 'Missing or invalid authorization header');
    }

    const token = authHeader.substring(7); // Remove 'Bearer '

    // Verify token
    const decodedToken = await auth.verifyIdToken(token);

    // Set user in request
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      role: decodedToken.role as 'owner' | 'renter',
      customClaims: decodedToken,
    };

    // Set in context
    setCurrentUserId(decodedToken.uid);

    const requestId = getCurrentRequestId();
    logInfo('Token verified successfully', {
      uid: decodedToken.uid,
      role: decodedToken.role,
    }, requestId);

    next();
  } catch (error) {
    const requestId = getCurrentRequestId();
    logError('Token verification failed', error as Error, {}, requestId);
    next(error);
  }
}

// Check user role middleware
export function requireRole(requiredRole: 'owner' | 'renter') {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(createError('UNAUTHORIZED'));
    }

    if (req.user.role !== requiredRole) {
      return next(createError('FORBIDDEN', `Role '${requiredRole}' required`));
    }

    next();
  };
}

// Get user by UID
export async function getUserByUid(uid: string) {
  try {
    const userRecord = await auth.getUser(uid);
    return userRecord;
  } catch (error) {
    logError('Failed to get user by UID', error as Error, { uid });
    throw createError('RESOURCE_NOT_FOUND', 'User not found');
  }
}

// Set custom claims (for role assignment)
export async function setUserRole(uid: string, role: 'owner' | 'renter') {
  try {
    await auth.setCustomUserClaims(uid, { role });
    logInfo('User role set', { uid, role });
  } catch (error) {
    logError('Failed to set user role', error as Error, { uid, role });
    throw createError('INTERNAL_ERROR', 'Failed to update user role');
  }
}

// Create user with role
export async function createUserWithRole(
  email: string,
  password: string,
  role: 'owner' | 'renter',
  additionalData?: Record<string, any>
) {
  try {
    const userRecord = await auth.createUser({
      email,
      password,
      ...additionalData,
    });

    // Set role
    await setUserRole(userRecord.uid, role);

    logInfo('User created with role', { uid: userRecord.uid, email, role });
    return userRecord;
  } catch (error) {
    logError('Failed to create user', error as Error, { email, role });
    throw createError('INTERNAL_ERROR', 'Failed to create user');
  }
}