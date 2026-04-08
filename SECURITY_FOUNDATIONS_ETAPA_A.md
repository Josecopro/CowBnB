# SECURITY FOUNDATIONS - ETAPA A
## CowBnB Backend Authentication, Authorization & Secret Management

**Status**: Foundation Planning (Pre-Implementation)  
**Last Updated**: 2026-04-07  
**Target Stage**: Etapa A - Technical Foundation

---

## TABLE OF CONTENTS

1. [Firestore Security Rules Skeleton](#1-firestore-security-rules-skeleton)
2. [Authentication Middleware Pattern](#2-authentication-middleware-pattern)
3. [Secret Management](#3-secret-management)
4. [Idempotency & Token Strategy](#4-idempotency--token-strategy)
5. [Risk Mitigations for Foundation Stage](#5-risk-mitigations-for-foundation-stage)
6. [Implementation Checklist](#6-implementation-checklist)

---

## 1. FIRESTORE SECURITY RULES SKELETON

### 1.1 Collections Requiring Rules in Etapa A

| Collection | Rule Type | Owner Field | Public Read | Backend-Only Operations |
|------------|-----------|-------------|-------------|-------------------------|
| `users` | Ownership-based | N/A (doc ID = uid) | No | role, emailVerified updates |
| `terrenos` | Ownership-based + Resource | `ownerId` | Partial (disponible only) | state transitions, NDVI updates |
| `reservas` | Participation-based | N/A (renterId + ownerId) | No | payment flow, state changes |
| `pagos` | Event-driven | `reservaId` | No (via parent) | All writes (webhook only) |
| `action_tokens` | Backend-only | N/A (token admin) | No | All (backend generation/validation) |
| `ndvi_checks` | Event log | N/A (terreno related) | No | All (NDVI job) |

### 1.2 Rule Validation Strategy by Role

```
User Role Validation Matrix:

┌─────────────────┬──────────────┬────────────┬──────────────┐
│ Resource        │ Owner        │ Renter     │ Unauthorized │
├─────────────────┼──────────────┼────────────┼──────────────┤
│ users/{uid}     │ READ/WRITE   │ NONE       │ NONE         │
│ terrenos (own)  │ R/W/DELETE   │ NONE       │ NONE         │
│ terrenos (pub)  │ READ (own)   │ READ list  │ NONE (only   │
│                 │ + edit       │ +details   │ disponible)  │
│ reservas (own)  │ R/W create   │ R/W create │ NONE         │
│ pagos           │ READ (own)   │ READ (own) │ NONE         │
│ action_tokens   │ NONE         │ NONE       │ NONE (read   │
│                 │              │            │ via bearer)  │
└─────────────────┴──────────────┴────────────┴──────────────┘
```

### 1.3 Base Rules Structure (firestore.rules)

```javascript
// ===============================================================
// FIRESTORE SECURITY RULES - ETAPA A
// ===============================================================
// 
// ASSUMPTIONS:
// - All operations verified by request.auth (Firebase Auth token)
// - Backend Functions run with admin privileges
// - No unauthenticated access except public listed terrenos
//
// ===============================================================

// ===============================================================
// HELPER FUNCTIONS
// ===============================================================

// Authentication check
function isAuth() {
  return request.auth != null;
}

// User owns resource by uid
function isUidOwner() {
  return isAuth() && request.auth.uid == resource.data.uid;
}

// User is owner of terreno
function isTerrenoOwner(ownerId) {
  return isAuth() && request.auth.uid == ownerId;
}

// User is participant in reserva (owner or renter)
function isReservaParticipant(renterId, ownerId) {
  return isAuth() && (request.auth.uid == renterId || request.auth.uid == ownerId);
}

// Immutable field check
function fieldUnchanged(field) {
  return !(field in request.resource.data) || 
         request.resource.data[field] == resource.data[field];
}

// Required fields present
function hasRequiredFields(fields) {
  return request.resource.data.keys().hasAll(fields);
}

// UID tampering protection (create)
function uidUntouchedOnCreate() {
  return !('uid' in request.resource.data) ||
         request.resource.data.uid == request.auth.uid;
}

// Valid email format
function isValidEmail(email) {
  return email is string &&
    email.matches("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$");
}

// Valid phone format (international prefix + digits)
function isValidPhone(phone) {
  return phone is string &&
    phone.matches("^\\+[0-9]{1,3}\\d{6,14}$");
}

// Valid hectares (positive float)
function isValidHectares(hectares) {
  return hectares is number && hectares > 0 && hectares <= 10000;
}

// Valid price (positive float/int)
function isValidPrice(price) {
  return price is number && price > 0;
}

// Valid timestamp (firestore server timestamp)
function isValidTimestamp(ts) {
  return ts == request.time;
}

// ===============================================================
// DATABASE RULES
// ===============================================================

service cloud.firestore {
  match /databases/{document=**} {
    
    // ----- USERS COLLECTION -----
    // Rule: Each user can only read/write their own document
    match /users/{userId} {
      allow read: if isAuth() && request.auth.uid == userId;
      
      allow create: if isAuth() && 
        request.auth.uid == userId &&
        uidUntouchedOnCreate() &&
        hasRequiredFields(['fullName', 'email', 'role', 'createdAt']) &&
        request.resource.data.role in ['owner', 'renter'] &&
        isValidEmail(request.resource.data.email) &&
        request.resource.data.fullName is string &&
        request.resource.data.fullName.size() > 0 &&
        request.resource.data.fullName.size() < 100 &&
        isValidTimestamp(request.resource.data.createdAt);
      
      allow update: if isAuth() && 
        isUidOwner() &&
        // Only allow updates to non-critical fields
        !('role' in request.resource.data.diff(resource.data).affectedKeys()) &&
        !('uid' in request.resource.data.diff(resource.data).affectedKeys()) &&
        hasRequiredFields(['fullName', 'email', 'role']) &&
        isValidEmail(request.resource.data.email) &&
        request.resource.data.fullName is string &&
        request.resource.data.fullName.size() > 0 &&
        request.resource.data.fullName.size() < 100;
      
      allow delete: if false; // Users cannot be deleted by client
    }
    
    // ----- TERRENOS COLLECTION -----
    match /terrenos/{terrenoId} {
      // Read: Owner full access + public for "disponible"
      allow read: if 
        isAuth() && request.auth.uid == resource.data.ownerId ||
        resource.data.status == 'disponible' && isAuth();
      
      allow create: if isAuth() &&
        hasRequiredFields(['ownerId', 'title', 'description', 'sizeHectares', 
                          'priceMonthly', 'createdAt', 'status']) &&
        request.resource.data.ownerId == request.auth.uid &&
        request.resource.data.status == 'disponible' &&
        request.resource.data.title is string &&
        request.resource.data.title.size() > 0 &&
        request.resource.data.title.size() < 200 &&
        isValidHectares(request.resource.data.sizeHectares) &&
        isValidPrice(request.resource.data.priceMonthly) &&
        isValidTimestamp(request.resource.data.createdAt);
      
      allow update: if isAuth() &&
        request.auth.uid == resource.data.ownerId &&
        // State transitions ONLY via backend Functions
        fieldUnchanged('status') &&
        fieldUnchanged('ownerId') &&
        // Cannot create new status by editing
        !('status' in request.resource.data.diff(resource.data).affectedKeys()) &&
        // Allow other field edits
        request.resource.data.title is string &&
        request.resource.data.title.size() > 0 &&
        isValidHectares(request.resource.data.sizeHectares) &&
        isValidPrice(request.resource.data.priceMonthly);
      
      allow delete: if false; // Terrenos archived via status, not deleted
    }
    
    // ----- RESERVAS COLLECTION -----
    match /reservas/{reservaId} {
      // Read: Only participants
      allow read: if isAuth() &&
        (request.auth.uid == resource.data.renterId ||
         request.auth.uid == resource.data.ownerId);
      
      allow create: if isAuth() &&
        hasRequiredFields(['renterId', 'ownerId', 'terrenoId', 'startDate', 
                          'endDate', 'totalPrice', 'status', 'createdAt']) &&
        request.resource.data.renterId == request.auth.uid &&
        request.resource.data.status == 'en_espera' &&
        isValidTimestamp(request.resource.data.createdAt) &&
        request.resource.data.startDate is timestamp &&
        request.resource.data.endDate is timestamp &&
        request.resource.data.endDate > request.resource.data.startDate &&
        isValidPrice(request.resource.data.totalPrice);
      
      // State transitions via backend only (payment flow)
      allow update: if false;
      allow delete: if false;
    }
    
    // ----- PAGOS COLLECTION -----
    // Backend-only writes via webhook
    match /pagos/{pagoId} {
      allow read: if isAuth() &&
        exists(/databases/$(database)/documents/reservas/$(resource.data.reservaId)) &&
        get(/databases/$(database)/documents/reservas/$(resource.data.reservaId)).data.renterId == request.auth.uid ||
        get(/databases/$(database)/documents/reservas/$(resource.data.reservaId)).data.ownerId == request.auth.uid;
      
      allow create, update, delete: if false; // Backend only
    }
    
    // ----- ACTION_TOKENS COLLECTION -----
    // Backend-only: one-time use tokens for email confirmations
    match /action_tokens/{tokenId} {
      allow read: if false;
      allow write: if false; // Backend only
    }
    
    // ----- NDVI_CHECKS COLLECTION -----
    // Event log from satellite monitoring job
    match /ndvi_checks/{checkId} {
      allow read: if false; // Not directly read by clients
      allow write: if false; // Backend/job only
    }
    
    // Catch-all deny
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 1.4 Backend-Only Operations Decision Matrix

| Operation | Reason | Trigger | Location |
|-----------|--------|---------|----------|
| State: `disponible` → `reservado` | Atomic with payment | Webhook callback | `functions/pagos/handleWebhook` |
| State: any → `en_espera` | Satellite decision | NDVI job | `functions/satelital/ndviCheck` |
| Terreno role+permissions | Prevent privilege escalation | Signup | `functions/auth/onUserCreate` |
| Payment event creation | Idempotency + immutability | Webhook | `functions/pagos/handleWebhook` |
| Action token hashing | Prevent token leakage | Validator call | `functions/satelital/validateToken` |

---

## 2. AUTHENTICATION MIDDLEWARE PATTERN

### 2.1 Firebase Token Verification Flow

```
Client Request
    ↓
Express Middleware: verifyFirebaseToken()
    ├─ Extract Authorization: Bearer <token>
    ├─ Verify with Firebase Admin SDK
    ├─ Attach auth context to req
    └─ Attach requestId to req
    ↓
Route Handler
    ├─ Check req.user (populated by middleware)
    ├─ Validate business logic
    └─ Return response
    ↓
Error Handler (if auth fails)
    ├─ 401 Unauthorized
    ├─ Log with requestId
    └─ Return safe error message
```

### 2.2 Middleware Chain Order (Critical)

```
1. requestIdMiddleware()         - Generate/extract requestId
2. loggingMiddleware()           - Log incoming request with requestId
3. verifyFirebaseToken()         - Extract & verify token
4. rateLimitMiddleware()         - Rate limit per userId
5. Route Handler
6. errorHandlerMiddleware()      - Catch errors, return 401/403/500
```

### 2.3 Implementation Skeleton (Node.js + Express)

```typescript
// backend/shared/middleware/auth.middleware.ts

interface AuthRequest extends express.Request {
  user?: {
    uid: string;
    email?: string;
    role?: string;
  };
  requestId?: string;
}

// Middleware 1: Generate requestId
export const requestIdMiddleware = (
  req: AuthRequest,
  res: express.Response,
  next: express.NextFunction
) => {
  const requestId = req.headers['x-request-id'] as string || generateUUID();
  req.requestId = requestId;
  res.setHeader('x-request-id', requestId);
  next();
};

// Middleware 2: Verify Firebase Token
export const verifyFirebaseToken = async (
  req: AuthRequest,
  res: express.Response,
  next: express.NextFunction
) => {
  try {
    const token = extractBearerToken(req.headers.authorization);
    
    if (!token) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Missing authentication token',
        requestId: req.requestId,
      });
    }
    
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    // Attach user info to request
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      // role will be fetched from Firestore if needed
    };
    
    // Log successful auth with requestId
    console.log({
      level: 'INFO',
      message: 'User authenticated',
      requestId: req.requestId,
      userId: req.user.uid,
      timestamp: new Date().toISOString(),
    });
    
    next();
  } catch (error) {
    console.error({
      level: 'WARN',
      message: 'Token verification failed',
      requestId: req.requestId,
      error: error.message,
      timestamp: new Date().toISOString(),
    });
    
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid authentication token',
      requestId: req.requestId,
    });
  }
};

// Middleware 3: Rate Limiting Hook
export const rateLimitMiddleware = (
  req: AuthRequest,
  res: express.Response,
  next: express.NextFunction
) => {
  // Store rate limit state in Redis or memory
  const userId = req.user?.uid;
  const key = `rate_limit:${userId}`;
  
  // Example: 100 requests per minute per user
  // Implementation: Check Redis counter, increment, set TTL
  
  // Pseudo-code:
  // const count = redis.incr(key);
  // if (count == 1) redis.expire(key, 60);
  // if (count > 100) {
  //   return res.status(429).json({ error: 'Too many requests' });
  // }
  
  next();
};

// Helper: Extract bearer token
function extractBearerToken(authHeader?: string): string | null {
  if (!authHeader) return null;
  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') return null;
  return parts[1];
}

// Helper: Generate UUID for requestId
function generateUUID(): string {
  return require('crypto').randomUUID();
}
```

### 2.4 Auth Failure Response Format (Standardized)

```json
{
  "error": "Unauthorized|Forbidden|InvalidToken",
  "message": "Human-readable reason",
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-04-07T12:34:56Z"
}
```

**Do NOT expose**:
- Token internals
- Which field failed validation
- Internal stack traces
- User existence confirmation (use same error for no user + invalid token)

### 2.5 Where requestId Fits in Middleware Chain

```typescript
// backend/functions/terrenos/index.ts
const terrenos = functions.https.onCall(async (req, res) => {
  // requestId already attached by middleware
  const { requestId, user } = req;
  
  // Logging with context
  console.log({
    operation: 'CREATE_TERRENO',
    requestId,
    userId: user.uid,
    timestamp: new Date().toISOString(),
  });
  
  // All logs/errors inherit requestId for tracing
  // Distribute requestId to nested service calls
  // Return requestId in response header
  res.set('x-request-id', requestId);
  res.json({ data: terreno, requestId });
});
```

---

## 3. SECRET MANAGEMENT

### 3.1 Secrets Required for Etapa A

| Secret | Purpose | Etapa A Use | Storage |
|--------|---------|------------|---------|
| `FIREBASE_CONFIG` | Initialize Firebase Admin SDK | Cloud Functions | `backend/.env.local` (dev only) |
| `FIREBASE_PROJECT_ID` | Workspace identifier | Cloud Functions | `firebase.json` (public) |
| `BOLD_API_KEY` | Checkout.Bold integration | Webhook signing | `Firebase Secret Manager` |
| `BOLD_WEBHOOK_SECRET` | Verify webhook signature | Payment verification | `Firebase Secret Manager` |
| `COPERNICUS_USERNAME` | Satellite data access | NDVI queries (Etapa E) | `Firebase Secret Manager` |
| `COPERNICUS_PASSWORD` | Satellite data access | NDVI queries (Etapa E) | `Firebase Secret Manager` |
| `JWT_SECRET` (optional) | Custom token signing | Action tokens | `Firebase Secret Manager` |
| `EMAIL_API_KEY` | Email delivery | Notifications | `Firebase Secret Manager` |

### 3.2 Storage Decision: .env vs Firebase Secret Manager

```
╔════════════════════════════════════════════════════════════════╗
║ DEVELOPMENT (.env.local)                                       ║
╠════════════════════════════════════════════════════════════════╣
║ ✓ Local testing only                                           ║
║ ✓ File: backend/.env.local (in .gitignore)                    ║
║ ✓ Secrets:                                                     ║
║   - FIREBASE_CONFIG (dev credentials)                         ║
║   - Test API keys (non-production)                            ║
║ ✗ Never production values                                      ║
╚════════════════════════════════════════════════════════════════╝

╔════════════════════════════════════════════════════════════════╗
║ PRODUCTION (Firebase Secret Manager)                           ║
╠════════════════════════════════════════════════════════════════╣
║ ✓ All production secrets                                       ║
║ ✓ Automatic rotation support                                  ║
║ ✓ Audit logs for access                                       ║
║ ✓ Secrets accessed at runtime:                                ║
║   - BOLD_API_KEY                                              ║
║   - BOLD_WEBHOOK_SECRET                                       ║
║   - COPERNICUS_*                                              ║
║   - EMAIL_API_KEY                                             ║
║ ✓ IAM integration (Functions have specific permissions)       ║
╚════════════════════════════════════════════════════════════════╝
```

### 3.3 How Functions Access Secrets Securely

```typescript
// backend/shared/secrets.ts

import { SecretManagerServiceClient } from '@google-cloud/secret-manager';

interface SecretConfig {
  BOLD_API_KEY: string;
  BOLD_WEBHOOK_SECRET: string;
  COPERNICUS_USERNAME: string;
  COPERNICUS_PASSWORD: string;
}

let cachedSecrets: SecretConfig | null = null;
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes
let lastFetchTime = 0;

export async function getSecrets(): Promise<SecretConfig> {
  // Return cached secrets if still valid
  if (cachedSecrets && Date.now() - lastFetchTime < CACHE_TTL_MS) {
    return cachedSecrets;
  }
  
  const client = new SecretManagerServiceClient();
  const projectId = process.env.FIREBASE_PROJECT_ID;
  
  const fetchSecret = async (secretName: string) => {
    const name = client.secretVersionPath(projectId, secretName);
    const [version] = await client.accessSecretVersion({ name });
    return version.payload?.data?.toString() || '';
  };
  
  try {
    const [boldKey, boldSecret, copernicusUser, copernicusPass, emailKey] = 
      await Promise.all([
        fetchSecret('BOLD_API_KEY'),
        fetchSecret('BOLD_WEBHOOK_SECRET'),
        fetchSecret('COPERNICUS_USERNAME'),
        fetchSecret('COPERNICUS_PASSWORD'),
        fetchSecret('EMAIL_API_KEY'),
      ]);
    
    cachedSecrets = {
      BOLD_API_KEY: boldKey,
      BOLD_WEBHOOK_SECRET: boldSecret,
      COPERNICUS_USERNAME: copernicusUser,
      COPERNICUS_PASSWORD: copernicusPass,
    };
    
    lastFetchTime = Date.now();
    console.log({
      level: 'INFO',
      message: 'Secrets fetched from Secret Manager',
      timestamp: new Date().toISOString(),
    });
    
    return cachedSecrets;
  } catch (error) {
    console.error({
      level: 'ERROR',
      message: 'Failed to fetch secrets',
      error: error.message,
      timestamp: new Date().toISOString(),
    });
    throw new Error('Secret retrieval failed');
  }
}

// Usage in a function:
// const secrets = await getSecrets();
// const boldClient = new BoldAPI(secrets.BOLD_API_KEY);
```

### 3.4 Environment-Specific Configuration

```bash
# backend/.env.local (dev only - NEVER commit to git)
FIREBASE_PROJECT_ID=cowbnb-dev
FIREBASE_EMULATOR_HOST=localhost:4000

# backend/.env.production (template - fill from Secret Manager)
FIREBASE_PROJECT_ID=cowbnb-prod
# BOLD_API_KEY=<from Secret Manager>
# BOLD_WEBHOOK_SECRET=<from Secret Manager>
```

### 3.5 Firebase IAM Permissions for Functions

```yaml
# Only Functions service account needs Secret Manager access
roles/secretmanager.secretAccessor:
  - serviceAccount: <PROJECT_ID>@appspot.gserviceaccount.com
  
roles/secretmanager.admin:
  - roles/owner (for setup only)
  
# Developers:
# - No direct Secret Manager access
# - Test via `firebase emulator:start`
```

---

## 4. IDEMPOTENCY & TOKEN STRATEGY

### 4.1 Idempotent Operations for Etapa A

| Operation | Why | Token Location | Idempotency Key | Storage | TTL |
|-----------|-----|-----------------|-----------------|---------|-----|
| Webhook payment confirmation | May retry/duplicate | Webhook body | `externalReference` | Firestore `pagos.externalReference` | 24h |
| Confirm NDVI action | May retry manually | Email link | Hash(token) | Firestore `action_tokens` | 7 days |
| Create reservation | User may double-click | Client header | `x-idempotency-key` | Firestore metadata | 24h |

### 4.2 XXX Format for Idempotent Operations

```
Operation Type: XXX-{timestamp}-{randomSuffix}

Examples:
─────────────────────────────────────────────────────

PAYMENT-2026-04-07T12:34:56Z-abc123
├─ Type: PAYMENT (webhook from Bold)
├─ ISO 8601 timestamp
└─ Random suffix (prevents collisions within same second)

NDVI-2026-04-07T12:34:56Z-xyz789
├─ Type: NDVI (satellite check result)
├─ Timestamp of check
└─ Unique per job run

RES-2026-04-07T12:34:56Z-user123
├─ Type: RES (reservation creation)
├─ Client-initiated timestamp
└─ UserId to ensure uniqueness
```

### 4.3 Token Hashing for Action Tokens

```typescript
// backend/shared/tokens.ts

import crypto from 'crypto';

// Generate one-time action token for email confirmations
export function generateActionToken(): {
  token: string;
  hashedToken: string;
} {
  const token = crypto.randomBytes(32).toString('hex');
  const hashedToken = crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');
  
  return { token, hashedToken };
}

// Store HASHED token only:
// {
//   tokenId: uuid(),
//   hashedToken: '8d969eef6ecad3c29a3a873fba8fe814f8c3c9b5',
//   action: 'reactivate_terreno',
//   terrenoId: 'terreno123',
//   expiresAt: timestamp + 7 days,
//   used: false
// }

// On confirmation, hash the provided token and compare
export function validateActionToken(
  providedToken: string,
  storedHashedToken: string
): boolean {
  const hashedProvided = crypto
    .createHash('sha256')
    .update(providedToken)
    .digest('hex');
  
  return crypto.timingSafeEqual(
    Buffer.from(hashedProvided),
    Buffer.from(storedHashedToken)
  );
}
```

### 4.4 Idempotency Enforcement (Database Pattern)

```typescript
// backend/shared/firestore/idempotency.ts

export async function writeIdempotent(
  db: admin.firestore.Firestore,
  collection: string,
  docId: string,
  data: any,
  idempotencyKey: string
): Promise<{ success: boolean; reason?: string }> {
  
  const idempotencyRef = db
    .collection('_idempotency')
    .doc(`${collection}:${idempotencyKey}`);
  
  // Check if already processed
  const existing = await idempotencyRef.get();
  if (existing.exists) {
    console.log({
      level: 'WARN',
      message: 'Idempotent operation already processed',
      idempotencyKey,
      previousDocId: existing.data().docId,
    });
    return {
      success: true,
      reason: 'Already processed',
    };
  }
  
  // Mark as processing + execute write
  try {
    await db.runTransaction(async (transaction) => {
      // 1. Mark idempotency key as used
      transaction.set(idempotencyRef, {
        docId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24h
      });
      
      // 2. Write actual data
      transaction.set(db.collection(collection).doc(docId), data);
    });
    
    return { success: true };
  } catch (error) {
    console.error({
      level: 'ERROR',
      message: 'Idempotent write failed',
      idempotencyKey,
      error: error.message,
    });
    return {
      success: false,
      reason: error.message,
    };
  }
}
```

### 4.5 Storage Location Decisions

```
IDEMPOTENCY METADATA:
├─ _idempotency (system collection)
│  ├─ Keys: {collection}:{idempotencyKey}
│  ├─ TTL: 24-48 hours (cleanup job)
│  └─ Purpose: Prevent duplicate writes
│
ACTION_TOKENS:
├─ action_tokens (collection for confirmations)
│  ├─ Stored: { hashedToken, action, terrenoId, expiresAt, used: bool }
│  ├─ Never: plain token
│  └─ TTL: 7 days or on use
│
PAYMENT EVENTS:
├─ pagos (transactions)
│  ├─ Key: externalReference (from Bold webhook)
│  ├─ Prevents: Duplicate payment processing
│  └─ TTL: Permanent (audit trail)
```

---

## 5. RISK MITIGATIONS FOR FOUNDATION STAGE

### 5.1 Authorization Bypass Prevention

#### Risk A: User changes own role
**Scenario**: POST `/users/{uid}` changes `role: 'user'` → `role: 'admin'`

**Rule**: Firestore rules prevent role modifications
```javascript
allow update: 
  if isUidOwner() &&
  !('role' in request.resource.data.diff(resource.data).affectedKeys());
```

**Backend**: Admin SDK (trusted context) sets role on user creation
```typescript
// backend/functions/auth/onCreate.ts
// ONLY Functions sets role, never from client
await admin.firestore()
  .doc(`users/${uid}`)
  .set({ role: userRole }, { merge: true });
```

---

#### Risk B: Renter modifies terreno they don't own
**Scenario**: GET `/terrenos/{id}` → PATCH with new price

**Rule**: Firestore rules check ownerId match
```javascript
allow update: 
  if request.auth.uid == resource.data.ownerId;
```

**Backend Enforcement**: Functions validate ownership redundantly
```typescript
const terreno = await db.collection('terrenos').doc(docId).get();
if (terreno.data().ownerId !== req.user.uid) {
  throw new Error('Unauthorized: Not terreno owner');
}
```

---

#### Risk C: Bypass payments (create reserva as `reservado`)
**Scenario**: POST `/reservas` with `status: 'reservado'` (payment skipped)

**Rule**: Client can only create with `status: 'en_espera'`
```javascript
allow create: 
  if request.resource.data.status == 'en_espera';
```

**State Transitions**: Only backend advances status
- `en_espera` → `reservado` via webhook signature verification
- `reservado` → `cancelado` via TTL scheduler

---

### 5.2 Token Leakage Prevention

#### Risk A: Auth tokens exposed in logs
**Mitigation**:
```typescript
// ✓ SAFE: Log only parts of token
console.log({
  message: 'Token verified',
  tokenIssuer: decodedToken.iss,
  userId: decodedToken.uid,
  expiresAt: new Date(decodedToken.exp * 1000).toISOString(),
});

// ✗ UNSAFE: Log full token
console.log('Token:', authHeader); // NEVER
```

#### Risk B: Bearer token in error messages
**Mitigation**:
```typescript
// ✗ UNSAFE
throw new Error(`Token verification failed: ${token}`);

// ✓ SAFE
console.error({
  level: 'ERROR',
  message: 'Token verification failed',
  userId: req.user?.uid, // only if already verified
  error: error.message, // not the token itself
});
res.status(401).json({ error: 'Unauthorized' });
```

#### Risk C: Action tokens stored in plain text
**Mitigation**:
```typescript
// ✓ Store only SHA-256 hash
const { token, hashedToken } = generateActionToken();
await db.collection('action_tokens').add({
  hashedToken, // Never store token
  action: 'reactivate',
  expiresAt: newDate(),
});

// Send email with plain token
await sendEmail({
  to: user.email,
  subject: 'Reactivate Your Terreno',
  confirmLink: `${BASE_URL}/confirm?token=${token}`,
});

// Validate by hashing provided token
validateActionToken(providedToken, storedHashedToken);
```

---

### 5.3 Webhook Signature Verification Pattern (for Future PAY Module)

#### Risk: Attacker sends fake webhook (pretends to be Bold)

**Pattern** (Etapa C - Payments):

```typescript
// backend/functions/pagos/webhook.ts

import crypto from 'crypto';

export const handleBoldWebhook = functions.https.onRequest(
  async (req, res) => {
    const requestId = generateUUID();
    
    // 1. Extract signature and payload
    const signature = req.headers['x-bold-signature'] as string;
    const payload = req.rawBody; // Raw buffer, not parsed JSON
    
    // 2. Verify signature
    const secrets = await getSecrets();
    const expectedSignature = crypto
      .createHmac('sha256', secrets.BOLD_WEBHOOK_SECRET)
      .update(payload)
      .digest('hex');
    
    if (!crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(expectedSignature)
    )) {
      console.warn({
        level: 'WARN',
        message: 'Invalid webhook signature',
        requestId,
        timestamp: new Date().toISOString(),
      });
      return res.status(401).json({ error: 'Unauthorized' });
    }
    
    // 3. Parse (safe after verification)
    const event = JSON.parse(payload.toString());
    const { externalReference, status } = event;
    
    // 4. Idempotency check
    const idempotencyResult = await checkIdempotency(
      'pagos',
      externalReference
    );
    if (idempotencyResult.alreadyProcessed) {
      console.log({
        level: 'INFO',
        message: 'Webhook already processed',
        requestId,
        externalReference,
      });
      return res.status(200).json({ received: true });
    }
    
    // 5. Process payment state transition
    if (status === 'APPROVED') {
      await confirmReservation(externalReference, requestId);
    }
    
    // 6. Respond with 200 immediately
    return res.status(200).json({ received: true });
  }
);
```

**Key Decisions**:
- ✓ Verify signature before parsing JSON (prevents injection)
- ✓ Use `timingSafeEqual` (prevents timing attacks)
- ✓ Check idempotency **after** verification (prevent DoS with bad sigs)
- ✓ Return 200 immediately (Bold expects quick response)
- ✓ Process async (don't block webhook response)

---

### 5.4 Defense in Depth Summary

```
Layer 1: Network
├─ HTTPS enforced
├─ CORS restrict origins
└─ Rate limiting per user/IP

Layer 2: Authentication
├─ Firebase Auth tokens (JWT, short-lived)
├─ requestId for traceability
└─ Automatic token refresh

Layer 3: Authorization
├─ Firestore rules (client validation)
├─ Functions re-validate ownership (server validation)
└─ Role-based permissions

Layer 4: Data Validation
├─ Schema validation on create/update
├─ Type checking
└─ Field immutability checks

Layer 5: Operation Safety
├─ Idempotency via externalReference/idempotencyKey
├─ Atomic transactions
├─ State machine enforcement (no invalid transitions)
└─ Webhook signature verification

Layer 6: Secret Protection
├─ Firebase Secret Manager (not .env in prod)
├─ No tokens in logs
├─ Action tokens hashed (SHA-256)
└─ Secrets cached to avoid leakage on every request
```

---

## 6. IMPLEMENTATION CHECKLIST

### Phase 1: Firestore Rules Setup (Week 1)
- [ ] Deploy `firestore.rules` skeleton to development
- [ ] Enable Firestore emulator for local testing
- [ ] Validate rules with emulator using role-based test suite
- [ ] Document each collection's permission model
- [ ] Test invalid access patterns (should all fail)
- [ ] Approval: Supervisor reviews rules

### Phase 2: Auth Middleware (Week 1-2)
- [ ] Implement `verifyFirebaseToken` middleware
- [ ] Add `requestId` generation/propagation
- [ ] Set up structured logging with requestId
- [ ] Implement `rateLimitMiddleware` (Redis/memory)
- [ ] Create standardized auth error responses
- [ ] Test: Invalid token → 401
- [ ] Test: Missing token → 401
- [ ] Test: Valid token → req.user populated
- [ ] Approval: Middleware passes security review

### Phase 3: Secret Management (Week 2)
- [ ] Set up `backend/.env.local` for local dev
- [ ] Implement `getSecrets` function (caching + error handling)
- [ ] Configure Firebase Secret Manager for prod secrets
- [ ] Set IAM permissions for Functions service account
- [ ] Test: Secrets fetched successfully in emulator
- [ ] Test: Cache invalidation after TTL
- [ ] Document: How to add new secrets
- [ ] Approval: Secrets never hardcoded in repo

### Phase 4: Idempotency System (Week 2-3)
- [ ] Implement token generation + hashing (`generateActionToken`)
- [ ] Create `_idempotency` collection for tracking
- [ ] Implement `writeIdempotent` transaction pattern
- [ ] Add idempotency key generation (client-side)
- [ ] Test: Duplicate requests → same result
- [ ] Test: Token validation succeeds once, fails on reuse
- [ ] Test: Expired tokens rejected
- [ ] Approval: Idempotency verified with double-send tests

### Phase 5: Risk Mitigations (Week 3)
- [ ] Audit: No role changes from client code
- [ ] Audit: No state transitions via client
- [ ] Audit: No tokens in logs/errors
- [ ] Audit: Action tokens hashed, never plain-text
- [ ] Implement webhook signature verification (skeleton)
- [ ] Security test: Try all bypass patterns (should all fail)
- [ ] Load test: Rate limiting works under stress
- [ ] Approval: Security team sign-off

### Etapa A Done Criteria
```
✓ All Firestore rules deployed and tested
✓ Auth middleware integrated in all endpoints
✓ Secrets managed via Secret Manager (production)
✓ Idempotency system operational
✓ All 5 risk categories mitigated
✓ Supervisor approval on security document
✓ No security issues found in code review
```

---

## DECISION POINTS FOR SUPERVISOR

1. **Firestore Rules Approach**: Use proposed skeleton or different pattern?
2. **Rate Limiting**: Redis implementation or in-memory for Etapa A?
3. **Action Token TTL**: 7 days acceptable or longer/shorter?
4. **Log Verbosity**: Include request/response bodies in logs or header-only?
5. **Error Messages**: Generic "Unauthorized" or more specific reasons?
6. **Token Caching**: 5 minutes acceptable or different TTL?
7. **Idempotency Window**: 24 hours acceptable for duplicate detection?

---

## RELATED DOCUMENTS

- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) - Section 8 (Firestore Rules), Section 10 (Risk Mitigation)
- `backend/shared/middleware/auth.middleware.ts` (to be created)
- `backend/shared/secrets.ts` (to be created)
- `firestore.rules` (to be deployed)
- `backend/shared/firestore/idempotency.ts` (to be created)

---

**Next Step**: Await supervisor approval on decision points before implementation begins.
