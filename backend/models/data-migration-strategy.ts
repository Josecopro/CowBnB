/**
 * DATA MIGRATION & SEEDING STRATEGY FOR ETAPA A
 * 
 * Current State: No backend exists, frontend uses hardcoded UI routes
 * Challenge: Need test data for local development + staging
 * Solution: Multi-layer seeding strategy
 * 
 * This document covers:
 * 1. Seed data fixtures (JSON)
 * 2. Loader functions (TypeScript)
 * 3. Emulator setup & reset
 * 4. Staging deployment data
 * 5. Production clean start
 */

// ============================================================================
// 1. SEED DATA FIXTURES (test-data.json)
// ============================================================================

export const SEED_DATA_STRUCTURE = {
  users: [
    {
      uid: 'owner-001',
      email: 'owner@example.com',
      fullName: 'Juan García',
      phonePrefix: '+56',
      phone: '912345678',
      role: 'owner',
      status: 'active',
      bio: 'Criador de ovinos con 15 años de experiencia',
      createdAt: 1704067200000, // 2024-01-01
      updatedAt: 1704067200000,
    },
    {
      uid: 'owner-002',
      email: 'owner2@example.com',
      fullName: 'María López',
      phonePrefix: '+56',
      phone: '987654321',
      role: 'owner',
      status: 'active',
      bio: 'Terrenos de pastoreo en Los Lagos',
      createdAt: 1704067200000,
      updatedAt: 1704067200000,
    },
    {
      uid: 'renter-001',
      email: 'renter@example.com',
      fullName: 'Carlos Rodríguez',
      phonePrefix: '+56',
      phone: '912111111',
      role: 'renter',
      status: 'active',
      createdAt: 1704067200000,
      updatedAt: 1704067200000,
    },
    {
      uid: 'renter-002',
      email: 'renter2@example.com',
      fullName: 'Sofía Martínez',
      phonePrefix: '+56',
      phone: '987222222',
      role: 'renter',
      status: 'active',
      createdAt: 1704067200000,
      updatedAt: 1704067200000,
    },
  ],
  
  terrenos: [
    {
      id: 'terreno-001',
      ownerId: 'owner-001',
      title: 'Pastore en Los Lagos - 20 hectáreas',
      description: 'Terreno de pastoreo de excelente calidad en Los Lagos con riego automático y acceso por camino principal. Ideal para ganado ovino y bovino.',
      sizeHectares: 20.5,
      location: {
        latitude: -41.475,
        longitude: -72.267,
        geohash: '9q9h12',
      },
      priceMonthly: 500000, // CLP
      features: ['irrigation', 'roads', 'certification'],
      images: [
        {
          id: 'img-001',
          url: 'https://storage.googleapis.com/cowbnb-dev/terreno-001/image-1.jpg',
          thumbnailUrl: 'https://storage.googleapis.com/cowbnb-dev/terreno-001/thumb-1.jpg',
          uploadedAt: 1704067200000,
          uploadedBy: 'owner-001',
          order: 0,
        },
        {
          id: 'img-002',
          url: 'https://storage.googleapis.com/cowbnb-dev/terreno-001/image-2.jpg',
          thumbnailUrl: 'https://storage.googleapis.com/cowbnb-dev/terreno-001/thumb-2.jpg',
          uploadedAt: 1704067200000,
          uploadedBy: 'owner-001',
          order: 1,
        },
      ],
      coverImageUrl: 'https://storage.googleapis.com/cowbnb-dev/terreno-001/image-1.jpg',
      status: 'disponible',
      ratingAvg: 4.5,
      ratingCount: 2,
      createdAt: 1704067200000,
      updatedAt: 1704153600000,
    },
    {
      id: 'terreno-002',
      ownerId: 'owner-001',
      title: 'Terreno para pastoreo - 30 hectáreas',
      description: 'Propiedad grande con energía eléctrica y caminos de acceso bien mantenidos. Perfecto para producción ganadera intensiva.',
      sizeHectares: 30,
      location: {
        latitude: -41.472,
        longitude: -72.265,
        geohash: '9q9h12',
      },
      priceMonthly: 750000,
      features: ['power', 'roads'],
      images: [],
      status: 'disponible',
      ratingAvg: null,
      ratingCount: 0,
      createdAt: 1704153600000,
      updatedAt: 1704153600000,
    },
    {
      id: 'terreno-003',
      ownerId: 'owner-002',
      title: 'Hectáreas en Palena',
      description: 'Excelente terreno para ovinos con certificación ambiental. Acceso por ruta principal.',
      sizeHectares: 15,
      location: {
        latitude: -43.85,
        longitude: -71.95,
        geohash: '9q8hmx',
      },
      priceMonthly: 350000,
      features: ['certification', 'roads'],
      images: [],
      status: 'reservado', // Simulates existing reservation
      ratingAvg: 5,
      ratingCount: 1,
      createdAt: 1704067200000,
      updatedAt: 1704240000000,
    },
    {
      id: 'terreno-004',
      ownerId: 'owner-002',
      title: 'Terreno con riego completo',
      description: 'Sistema de riego automático profesional. Agua disponible todo el año desde pozo profundo.',
      sizeHectares: 12.5,
      location: {
        latitude: -43.852,
        longitude: -71.952,
        geohash: '9q8hmx',
      },
      priceMonthly: 600000,
      features: ['irrigation', 'power', 'roads'],
      images: [],
      status: 'disponible',
      createdAt: 1704240000000,
      updatedAt: 1704240000000,
    },
  ],
  
  reservas: [
    {
      id: 'reserva-001',
      terrenoId: 'terreno-003',
      renterId: 'renter-001',
      ownerId: 'owner-002',
      startDate: 1704412800000, // 2024-01-05
      endDate: 1712188800000,   // 2024-04-04 (90 days)
      durationDays: 90,
      pricePerMonth: 350000,
      estimatedTotal: 1050000,
      status: 'reservado',
      paymentStatus: 'approved',
      paymentReference: 'bold-ref-001',
      expiresAt: 1704240000000, // Already passed
      createdAt: 1704067200000,
      updatedAt: 1704153600000,
      conversationId: 'conversacion-001',
    },
  ],
  
  payment_events: [
    {
      id: 'payment-event-001',
      reservaId: 'reserva-001',
      terrenoId: 'terreno-003',
      externalReference: 'bold-ref-001',
      eventType: 'approved',
      amount: 1050000,
      currency: 'CLP',
      status: 'approved',
      paymentMethod: 'credit_card',
      createdAt: 1704153600000,
      recordedAt: 1704153600000,
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    },
  ],
  
  conversaciones: [
    {
      id: 'conversacion-001',
      ownerId: 'owner-002',
      renterId: 'renter-001',
      reservaId: 'reserva-001',
      createdAt: 1704153600000,
      updatedAt: 1704240000000,
      lastMessageAt: 1704240000000,
      lastMessageText: 'Perfecto, nos vemos el 5 de enero',
      lastMessageSenderId: 'renter-001',
      ownerLastReadAt: 1704240000000,
      renterLastReadAt: 1704240000000,
      messageCount: 5,
      unreadByOwner: 0,
      unreadByRenter: 0,
    },
  ],
  
  mensajes: [
    {
      // SubCollection: conversaciones/conversacion-001/mensajes
      id: 'msg-001',
      conversationId: 'conversacion-001',
      senderId: 'renter-001',
      text: 'Hola, ¿cuándo puedo empezar?',
      createdAt: 1704153600000,
    },
    {
      id: 'msg-002',
      conversationId: 'conversacion-001',
      senderId: 'owner-002',
      text: 'El 5 de enero está disponible',
      createdAt: 1704153700000,
    },
    {
      id: 'msg-003',
      conversationId: 'conversacion-001',
      senderId: 'renter-001',
      text: 'Perfecto, nos vemos el 5 de enero',
      createdAt: 1704240000000,
    },
  ],
};

// ============================================================================
// 2. LOADER FUNCTIONS (TypeScript)
// ============================================================================

/**
 * seedFirestoreEmulator: Populate local Firestore emulator with test data
 * 
 * Usage in tests or local setup:
 *   await seedFirestoreEmulator(testData);
 *   // Now queries work with populated data
 */
export async function seedFirestoreEmulator(
  db: any, // Firebase Firestore instance (admin or client SDK)
  data: typeof SEED_DATA_STRUCTURE
): Promise<void> {
  console.log('[SEEDING] Starting Firestore emulator population...');
  
  try {
    // 1. Populate users collection
    for (const user of data.users) {
      await db.collection('users').doc(user.uid).set(user);
      console.log(`  ✓ Created user: ${user.uid}`);
    }
    
    // 2. Populate terrenos collection
    for (const terreno of data.terrenos) {
      await db.collection('terrenos').doc(terreno.id).set(terreno);
      console.log(`  ✓ Created terreno: ${terreno.id}`);
    }
    
    // 3. Populate reservas collection
    for (const reserva of data.reservas) {
      await db.collection('reservas').doc(reserva.id).set(reserva);
      console.log(`  ✓ Created reserva: ${reserva.id}`);
    }
    
    // 4. Populate payment_events collection
    for (const event of data.payment_events) {
      await db.collection('payment_events').doc(event.id).set(event);
      console.log(`  ✓ Created payment_event: ${event.id}`);
    }
    
    // 5. Populate conversaciones collection
    for (const conv of data.conversaciones) {
      await db.collection('conversaciones').doc(conv.id).set(conv);
      console.log(`  ✓ Created conversacion: ${conv.id}`);
    }
    
    // 6. Populate mensajes (subcollection)
    for (const msg of data.mensajes) {
      await db
        .collection('conversaciones')
        .doc(msg.conversationId)
        .collection('mensajes')
        .doc(msg.id)
        .set({
          ...msg,
          conversationId: undefined, // Don't duplicate in subcollection
        });
      console.log(`  ✓ Created mensaje: ${msg.id}`);
    }
    
    console.log('[SEEDING] ✅ Firestore emulator population complete!');
  } catch (error) {
    console.error('[SEEDING] ❌ Error populating emulator:', error);
    throw error;
  }
}

/**
 * clearFirestoreEmulator: Reset emulator to clean state
 * 
 * Usage:
 *   await clearFirestoreEmulator(db);
 *   await seedFirestoreEmulator(db, testData);
 */
export async function clearFirestoreEmulator(db: any): Promise<void> {
  console.log('[CLEAR] Resetting Firestore emulator...');
  
  const collections = [
    'users',
    'terrenos',
    'reservas',
    'payment_events',
    'conversaciones',
    'reviews',
  ];
  
  for (const colName of collections) {
    const docs = await db.collection(colName).get();
    for (const doc of docs.docs) {
      await doc.ref.delete();
    }
    console.log(`  ✓ Cleared ${colName} (${docs.size} documents)`);
  }
  
  console.log('[CLEAR] ✅ Firestore emulator reset complete!');
}

// ============================================================================
// 3. EMULATOR SETUP & LOCAL DEVELOPMENT
// ============================================================================

export const EMULATOR_SETUP_GUIDE = `
# Firestore Emulator Setup for Etapa A

## Prerequisites
- Firebase CLI: npm install -g firebase-tools
- Docker (optional, for cleaner isolation)
- Java 11+ (required for emulator)

## Quick Start (Option A: Direct Running)

1. Enable emulator in firebase.json:
   \`\`\`json
   {
     "emulators": {
       "firestore": {
         "host": "127.0.0.1",
         "port": 8080
       },
       "auth": {
         "host": "127.0.0.1",
         "port": 9099
       }
     }
   }
   \`\`\`

2. Start emulator:
   \`\`\`bash
   firebase emulators:start --import ./emulator-data
   \`\`\`

3. In application code, connect to emulator:
   \`\`\`typescript
   import { initializeApp } from 'firebase/app';
   import { connectFirestoreEmulator, getFirestore } from 'firebase/firestore';
   import { connectAuthEmulator, getAuth } from 'firebase/auth';
   
   const app = initializeApp(firebaseConfig);
   const db = getFirestore(app);
   const auth = getAuth(app);
   
   // Connect to emulator if in development
   if (location.hostname === 'localhost') {
     connectFirestoreEmulator(db, '127.0.0.1', 8080);
     connectAuthEmulator(auth, 'http://127.0.0.1:9099');
   }
   \`\`\`

4. Seed data:
   \`\`\`bash
   node scripts/seed-emulator.js
   \`\`\`

5. View emulator UI:
   Open http://localhost:4000

## Option B: Docker (Recommended for CI/CD)

\`\`\`dockerfile
FROM node:18-alpine
WORKDIR /app
COPY . .
RUN npm install
RUN npm install -g firebase-tools
EXPOSE 8080 9099
CMD ["firebase", "emulators:start", "--import", "./emulator-data"]
\`\`\`

\`\`\`bash
docker build -t cowbnb-emulator .
docker run -p 8080:8080 -p 9099:9099 cowbnb-emulator
\`\`\`

## Data Persistence

Save emulator state between sessions:
\`\`\`bash
firebase emulators:start --import ./emulator-data --export-on-exit ./emulator-data
\`\`\`

This creates/updates \`emulator-data/\` directory with saved Firestore + Auth state.

## Troubleshooting

Q: "Firestore is offline" error
A: Emulator UI shows "Offline" despite running
  - Check port 8080 is open: \`lsof -i :8080\`
  - Kill process: \`lsof -i :8080 | grep LISTEN | awk '{print $2}' | xargs kill\`
  - Restart emulator

Q: "Auth is not initialized" error
A: Firebase Auth emulator needs explicit connection
  - See connectAuthEmulator() call above
  - Create test user in emulator UI (Accounts tab)

Q: Seed data not appearing
A: Check seed script ran successfully
  - Add console.log statements
  - View in Firebase Emulator UI (Firestore tab)
  - Verify JSON structure matches models

Q: Performance is slow
A: Emulator is slower than production
  - Expected for local testing
  - Consider pre-loading only essential data
  - Use fixtures with 10-20 docs instead of 1000
`;

// ============================================================================
// 4. STAGING ENVIRONMENT DEPLOYMENT
// ============================================================================

export const STAGING_DEPLOYMENT_STRATEGY = `
# Staging Deployment (After Etapa A approved)

## Step 1: Create Firebase Project (staging)

\`\`\`bash
firebase projects:create cowbnb-staging
firebase use cowbnb-staging --add
\`\`\`

## Step 2: Initialize Firestore (Staging)

\`\`\`bash
firebase firestore:delete --database (default)  # Confirm deletion
firebase init firestore
# Select: Use existing Firestore rules
\`\`\`

## Step 3: Deploy Indexes + Rules

\`\`\`bash
firebase deploy --only firestore:indexes,firestore:rules
\`\`\`

## Step 4: Seed Staging Data

\`\`\`bash
node scripts/seed-staging.js --project=cowbnb-staging
\`\`\`

This runs same seedFirestoreEmulator() but targets real Firestore:

\`\`\`typescript
import * as admin from 'firebase-admin';

admin.initializeApp({
  projectId: 'cowbnb-staging',
});

const db = admin.firestore();
await seedFirestoreEmulator(db, SEED_DATA_STRUCTURE);
\`\`\`

## Step 5: Verify Staging

\`\`\`bash
firebase:login
firebase firestore:list --project=cowbnb-staging
# Should show: users (4), terrenos (4), reservas (1), etc.
\`\`\`

## Step 6: Invite Beta Testers

- Generate one-time registration links
- Seed data includes test accounts for demo
  - Owner: owner@example.com / password
  - Renter: renter@example.com / password
- Share Firebase Console link for monitoring

## Staging Data Lifecycle

- Seed data resets weekly (Monday 00:00 UTC)
- Beta testers can register new accounts (will persist until reset)
- Logs exported to GCS bucket for analysis
- Do NOT use for performance load testing (use production-like setup)

## Safety Rules for Staging

1. Security Rules: MUST be identical to what ships in production
2. Indexes: Deploy all TIER_1_BLOCKING before opening to testers
3. Backups: Enable daily snapshots (Firebase Console)
4. Cost: Set budget alert at $50/month to catch runaway queries
`;

// ============================================================================
// 5. PRODUCTION DEPLOYMENT (Fresh Start)
// ============================================================================

export const PRODUCTION_DEPLOYMENT_CHECKLIST = `
# Production Deployment Checklist (Etapa B+)

## Pre-Deployment (1 week before)

- [ ] Code review of all data models and validation
- [ ] Security rules audit by 2+ reviewers
- [ ] Load testing on production-like environment
- [ ] Backup/disaster recovery plan documented
- [ ] Data retention policy decided
- [ ] PII encryption strategy confirmed (if applicable)

## Deployment Day

### 00:00 - Prepare environment

- [ ] Create Firebase project: \`firebase projects:create cowbnb-prod\`
- [ ] Set to "Standard" plan (pay-as-you-go)
- [ ] Enable Firestore + Storage + Authentication
- [ ] Deploy indexes: \`firebase deploy --only firestore:indexes\`
- [ ] Deploy security rules: \`firebase deploy --only firestore:rules\`
- [ ] Wait for index backfill to complete (2-10 minutes)

### 02:00 - Smoke tests

- [ ] Run integration tests against production Firestore
- [ ] Verify all indexes working (query latency < 500ms)
- [ ] Check security rules with public user (should fail)
- [ ] Authenticate test user, verify read/write permissions

### 04:00 - Go-live

- [ ] Switch frontend to production Firebase config
- [ ] Update backend environment variables
- [ ] Deploy Cloud Functions (will be done in Etapa B)
- [ ] Enable production security rules (lock down)

### 06:00 - Post-deployment

- [ ] Monitor error rates (target: < 0.1%)
- [ ] Watch query latency (target: P99 < 1 sec)
- [ ] Check for 403 Forbidden errors (rules too strict)
- [ ] First user registrations should succeed

### 12:00 - Monitoring period

- [ ] Continue monitoring for 24 hours
- [ ] Rollback plan: have previous config ready
- [ ] Keep on-call support available

## Critical Rules for Production

1. **NO automatic seeding**: Production starts empty
2. **First users register via UI**: Normal registration flow
3. **Backups enabled**: Firebase Console > Backups
4. **Access logs enabled**: For audit trail
5. **Cost monitoring**: Set budget alerts
6. **Deletion protection**: Enable "prevent accidental deletion"

## Data Retention Policy (To Define)

- User data: Keep indefinitely (except soft-deleted accounts after 90 days)
- Reservation history: Keep 3 years (legal requirements)
- Payment events: Keep 7 years (tax requirements)
- Logs: Keep 30 days in Cloud Logging
- Backups: Weekly export to GCS (keep 12 months)

## Disaster Recovery Plan

If Firestore becomes corrupted/deleted:

1. Restore from daily backup (Firebase Console)
2. Last resort: Restore from GCS export (if available)
3. Communication: Notify users of data loss
4. RTO: < 4 hours (restore from backup takes ~1 hour)
5. RPO: Last 24 hours (data loss exposure)
`;

// ============================================================================
// 6. MINIMAL VIABLE SEED DATA (For Demo/MVP)
// ============================================================================

export const MINIMAL_SEED_DATA = {
  description: 'Bare minimum to demonstrate app functionality',
  users: [
    {
      uid: 'owner-demo',
      email: 'demo.owner@test.local',
      fullName: 'Demo Owner',
      phonePrefix: '+56',
      phone: '900000001',
      role: 'owner',
      status: 'active',
      createdAt: Date.now(),
      updatedAt: Date.now(),
    },
    {
      uid: 'renter-demo',
      email: 'demo.renter@test.local',
      fullName: 'Demo Renter',
      phonePrefix: '+56',
      phone: '900000002',
      role: 'renter',
      status: 'active',
      createdAt: Date.now(),
      updatedAt: Date.now(),
    },
  ],
  terrenos: [
    {
      id: 'terreno-demo-1',
      ownerId: 'owner-demo',
      title: 'Demo Property - 20 hectares',
      description: 'This is a demo property for testing the application.',
      sizeHectares: 20,
      location: {
        latitude: -33.8688197,
        longitude: -51.2093613,
        geohash: '9q8vx0',
      },
      priceMonthly: 500000,
      features: [],
      images: [],
      status: 'disponible',
      createdAt: Date.now(),
      updatedAt: Date.now(),
    },
  ],
  // No reservas/conversations in minimal seed
};
`;

export default {
  SEED_DATA_STRUCTURE,
  EMULATOR_SETUP_GUIDE,
  STAGING_DEPLOYMENT_STRATEGY,
  PRODUCTION_DEPLOYMENT_CHECKLIST,
  MINIMAL_SEED_DATA,
};
