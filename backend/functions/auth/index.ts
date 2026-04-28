// ============================================================================
// AUTH ROUTER - COMPLETE IMPLEMENTATION
// Register, Login, and Profile endpoints
// ============================================================================

import express, { Request, Response } from 'express';
import * as admin from 'firebase-admin';
import {
  verifyFirebaseToken,
  AuthRequest,
  createUserWithRole,
  getUserByUid,
  setUserRole,
  firestore,
  auth,
} from '../../shared/auth';
import {
  asyncHandler,
  createError,
  validateData,
} from '../../shared/errors';
import { logInfo, logError } from '../../shared/logging';
import { getCurrentRequestId } from '../../shared/request-context';

const router = express.Router();

// ============================================================================
// REGISTER ENDPOINT
// Creates user in Firebase Auth + Firestore users collection
// ============================================================================

router.post(
  '/register',
  asyncHandler(async (req: Request, res: Response) => {
    const requestId = getCurrentRequestId();
    const {
      email,
      password,
      fullName,
      phonePrefix,
      phone,
      role,
      acceptedTerms,
    } = req.body;

    // Validate input
    const validation = validateRegisterInput({
      email,
      password,
      fullName,
      phonePrefix,
      phone,
      role,
      acceptedTerms,
    });

    if (!validation.valid) {
      return res.status(400).json({
        error: 'VALIDATION_ERROR',
        message: validation.errors.join('; '),
        requestId,
      });
    }

    // Check if user already exists
    try {
      await auth.getUserByEmail(email);
      // If we reach here, user exists
      return res.status(409).json({
        error: 'USER_EXISTS',
        message: 'Email already registered',
        requestId,
      });
    } catch (error: any) {
      // Expected: user not found (code 'auth/user-not-found')
      if (error.code !== 'auth/user-not-found') {
        logError('Error checking user existence', error, { email }, requestId);
        return res.status(500).json({
          error: 'INTERNAL_ERROR',
          message: 'Failed to check email availability',
          requestId,
        });
      }
    }

    // Create Firebase Auth user
    let userRecord;
    try {
      userRecord = await createUserWithRole(
        email,
        password,
        role as 'owner' | 'renter'
      );
      logInfo('Firebase Auth user created', { uid: userRecord.uid, email, role }, requestId);
    } catch (error) {
      logError('Failed to create Firebase user', error as Error, { email, role }, requestId);
      return res.status(500).json({
        error: 'INTERNAL_ERROR',
        message: 'Failed to create user account',
        requestId,
      });
    }

    // Create Firestore user document
    const userData = {
      uid: userRecord.uid,
      fullName,
      email,
      phonePrefix,
      phone,
      role,
      acceptedTerms: acceptedTerms === true,
      onboardingComplete: false,
      status: 'active',
      bio: null,
      location: null,
      profileImageUrl: null,
      fcmTokens: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    try {
      await firestore.collection('users').doc(userRecord.uid).set(userData);
      logInfo('Firestore user document created', { uid: userRecord.uid }, requestId);
    } catch (error) {
      logError('Failed to create Firestore user', error as Error, { uid: userRecord.uid }, requestId);
      // Try to delete the Auth user since Firestore creation failed
      try {
        await auth.deleteUser(userRecord.uid);
      } catch (deleteError) {
        logError('Failed to clean up Auth user', deleteError as Error, { uid: userRecord.uid }, requestId);
      }
      return res.status(500).json({
        error: 'INTERNAL_ERROR',
        message: 'Failed to complete registration',
        requestId,
      });
    }

    logInfo('User registration successful', { uid: userRecord.uid, email }, requestId);

    res.status(201).json({
      success: true,
      user: {
        uid: userRecord.uid,
        email: userRecord.email,
        fullName,
        role,
        createdAt: new Date().toISOString(),
      },
      message: 'User registered successfully',
      requestId,
    });
  })
);

// ============================================================================
// LOGIN ENDPOINT
// Note: Client-side should use Firebase Auth SDK
// This endpoint returns user profile after auth verification
// ============================================================================

router.post(
  '/login',
  asyncHandler(async (req: Request, res: Response) => {
    const requestId = getCurrentRequestId();
    
    // In production, login is handled entirely by client-side Firebase SDK
    // This endpoint is for reference or CLI-based testing
    res.status(200).json({
      message: 'Login should be performed using Firebase Auth SDK on client',
      instructions: {
        step1: 'Use FirebaseAuth.instance.signInWithEmailAndPassword(email, password)',
        step2: 'Retrieve ID token using await FirebaseAuth.instance.currentUser?.getIdToken()',
        step3: 'Use token in Authorization header for protected endpoints',
      },
      requestId,
    });
  })
);

// ============================================================================
// GET PROFILE ENDPOINT
// Returns authenticated user profile from Firestore
// ============================================================================

router.get(
  '/profile',
  verifyFirebaseToken,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const requestId = getCurrentRequestId();
    const uid = req.user!.uid;

    try {
      const userDoc = await firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        logError('User document not found', new Error('Missing user doc'), { uid }, requestId);
        return res.status(404).json({
          error: 'RESOURCE_NOT_FOUND',
          message: 'User profile not found',
          requestId,
        });
      }

      const userData = userDoc.data();

      logInfo('User profile retrieved', { uid }, requestId);

      res.status(200).json({
        success: true,
        user: {
          uid,
          fullName: userData?.fullName,
          email: userData?.email,
          phonePrefix: userData?.phonePrefix,
          phone: userData?.phone,
          role: userData?.role,
          bio: userData?.bio,
          onboardingComplete: userData?.onboardingComplete,
          profileImageUrl: userData?.profileImageUrl,
          createdAt: userData?.createdAt?.toDate?.(),
          updatedAt: userData?.updatedAt?.toDate?.(),
        },
        requestId,
      });
    } catch (error) {
      logError('Failed to retrieve user profile', error as Error, { uid }, requestId);
      return res.status(500).json({
        error: 'INTERNAL_ERROR',
        message: 'Failed to retrieve profile',
        requestId,
      });
    }
  })
);

// ============================================================================
// UPDATE PROFILE ENDPOINT
// Allows users to update their own profile information
// ============================================================================

router.put(
  '/profile',
  verifyFirebaseToken,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const requestId = getCurrentRequestId();
    const uid = req.user!.uid;
    const { fullName, bio, phone, phonePrefix, onboardingComplete } = req.body;

    // Validate updatable fields
    const updates: Record<string, any> = {};

    if (fullName !== undefined) {
      if (!/^[a-zA-Z\s\-áéíóúñÁÉÍÓÚÑ]{2,100}$/.test(fullName)) {
        return res.status(400).json({
          error: 'VALIDATION_ERROR',
          message: 'fullName must be 2-100 characters, letters only',
          requestId,
        });
      }
      updates.fullName = fullName;
    }

    if (bio !== undefined) {
      if (bio && bio.length > 500) {
        return res.status(400).json({
          error: 'VALIDATION_ERROR',
          message: 'bio must be max 500 characters',
          requestId,
        });
      }
      updates.bio = bio;
    }

    if (phone !== undefined) {
      if (!/^[0-9]{7,15}$/.test(phone)) {
        return res.status(400).json({
          error: 'VALIDATION_ERROR',
          message: 'phone must be 7-15 digits',
          requestId,
        });
      }
      updates.phone = phone;
    }

    if (phonePrefix !== undefined) {
      if (!/^\+[0-9]{1,3}$/.test(phonePrefix)) {
        return res.status(400).json({
          error: 'VALIDATION_ERROR',
          message: 'phonePrefix must be in format +CC',
          requestId,
        });
      }
      updates.phonePrefix = phonePrefix;
    }

    if (onboardingComplete !== undefined) {
      updates.onboardingComplete = Boolean(onboardingComplete);
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({
        error: 'VALIDATION_ERROR',
        message: 'No valid fields to update',
        requestId,
      });
    }

    updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    try {
      await firestore.collection('users').doc(uid).update(updates);
      logInfo('User profile updated', { uid, updates: Object.keys(updates) }, requestId);

      const updatedDoc = await firestore.collection('users').doc(uid).get();
      const userData = updatedDoc.data();

      res.status(200).json({
        success: true,
        user: {
          uid,
          fullName: userData?.fullName,
          email: userData?.email,
          phonePrefix: userData?.phonePrefix,
          phone: userData?.phone,
          role: userData?.role,
          bio: userData?.bio,
          onboardingComplete: userData?.onboardingComplete,
          profileImageUrl: userData?.profileImageUrl,
        },
        requestId,
      });
    } catch (error) {
      logError('Failed to update user profile', error as Error, { uid }, requestId);
      return res.status(500).json({
        error: 'INTERNAL_ERROR',
        message: 'Failed to update profile',
        requestId,
      });
    }
  })
);

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function validateRegisterInput(data: any): {
  valid: boolean;
  errors: string[];
} {
  const errors: string[] = [];

  // Email validation
  if (!data.email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.email)) {
    errors.push('Email must be valid');
  }

  // Password validation
  if (!data.password || data.password.length < 8) {
    errors.push('Password must be at least 8 characters');
  }

  // Full name validation
  if (
    !data.fullName ||
    !/^[a-zA-Z\s\-áéíóúñÁÉÍÓÚÑ]{2,100}$/.test(data.fullName)
  ) {
    errors.push('Full name must be 2-100 characters, letters only');
  }

  // Phone prefix validation
  if (!data.phonePrefix || !/^\+[0-9]{1,3}$/.test(data.phonePrefix)) {
    errors.push('Phone prefix must be in format +CC (e.g., +56)');
  }

  // Phone validation
  if (!data.phone || !/^[0-9]{7,15}$/.test(data.phone)) {
    errors.push('Phone must be 7-15 digits');
  }

  // Role validation
  if (!['owner', 'renter'].includes(data.role)) {
    errors.push('Role must be "owner" or "renter"');
  }

  // Terms acceptance
  if (data.acceptedTerms !== true) {
    errors.push('Must accept terms and conditions');
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

export default router;