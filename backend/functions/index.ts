// ============================================================================
// CLOUD FUNCTIONS MAIN ENTRY POINT
// Etapa A - Basic structure with health check
// ============================================================================

import * as functions from 'firebase-functions';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';

// Import shared utilities
import { initializeFirebase } from '../config/firebase.config';
import { env } from '../config/environment';
import { requestContextMiddleware } from '../shared/request-context';
import { createRequestLogger } from '../shared/logging';
import { verifyFirebaseToken } from '../shared/auth';
import { errorHandler } from '../shared/errors';

// Routers
import authRouter from './auth';
import terrenosRouter from './terrenos';
import reservasRouter from './reservas';
import dashboardRouter from './dashboard';
import favoritesRouter from './favorites';
import conversationsRouter from './conversations';
import notificationsRouter from './notifications';

// Initialize Firebase
initializeFirebase();

// Create Express app
const app = express();

// Security middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));

// CORS configuration
app.use(cors({
  origin: env.NODE_ENV === 'production'
    ? ['https://yourdomain.com'] // Replace with actual domain
    : true, // Allow all in development
  credentials: true,
}));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Compression
app.use(compression());

// Request context
app.use(requestContextMiddleware());

// Request logging
app.use(createRequestLogger());

// Health check endpoint (no auth required)
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: Date.now(),
    version: 'etapa-a',
    environment: env.NODE_ENV,
  });
});

// Protected routes placeholder
app.get('/protected', verifyFirebaseToken, (req: any, res) => {
  res.json({
    message: 'This is a protected route',
    user: req.user,
    requestId: req.requestId,
  });
});

// API routes
app.use('/auth', authRouter);
app.use('/terrenos', terrenosRouter);
app.use('/reservas', reservasRouter);
app.use('/dashboard', dashboardRouter);
app.use('/favorites', favoritesRouter);
app.use('/conversations', conversationsRouter);
app.use('/notifications', notificationsRouter);

// Error handling (must be last)
app.use(errorHandler);

// Export the Express app as a Firebase Function
export const api = functions.https.onRequest(app);

// Export individual functions (for future modularization)
// export { register } from './auth/register';
// export { createTerreno } from './terrenos/create';
// etc.