/**
 * FIRESTORE CRITICAL INDEXES FOR ETAPA A
 * firestore.indexes.json Configuration
 * 
 * This document defines:
 * - Which indexes are CRITICAL for Etapa A queries
 * - Performance impact of each index
 * - Deployment priority and rollout strategy
 * - Query pattern each index enables
 * 
 * INDEX TYPES:
 * 1. Composite (2+ fields): MUST be manually created
 * 2. Single-field: Auto-created by Firestore on first query
 * 3. Collection group: For querying across subcollections
 */

// ============================================================================
// 1. CRITICAL INDEXES FOR ETAPA A (MUST CREATE)
// ============================================================================

/**
 * PRIORITY TIER 1: BLOCKING (Build cannot launch without these)
 * Affects: Core discovery, listing, dashboard functionality
 */
export const TIER_1_BLOCKING_INDEXES = [
  {
    collectionGroup: 'terrenos',
    fields: [
      { fieldPath: 'ownerId', order: 'ASCENDING' },
      { fieldPath: 'createdAt', order: 'DESCENDING' }
    ],
    queryPurpose: 'Owner dashboard: list all my listings',
    queryExample: `db.collection('terrenos')
      .where('ownerId', '==', uid)
      .orderBy('createdAt', 'desc')
      .limit(50)`,
    estimatedDocsReturned: '10-100 per owner',
    performanceImpact: 'High - owner dashboard loads on every session',
    createdAt: 'Etapa A week 1',
  },
  
  {
    collectionGroup: 'terrenos',
    fields: [
      { fieldPath: 'status', order: 'ASCENDING' },
      { fieldPath: 'createdAt', order: 'DESCENDING' }
    ],
    queryPurpose: 'Available properties sorted by newest first',
    queryExample: `db.collection('terrenos')
      .where('status', '==', 'disponible')
      .orderBy('createdAt', 'desc')
      .limit(50)`,
    estimatedDocsReturned: '50-500',
    performanceImpact: 'High - discovery page primary query',
    createdAt: 'Etapa A week 1',
  },
  
  {
    collectionGroup: 'terrenos',
    fields: [
      { fieldPath: 'status', order: 'ASCENDING' },
      { fieldPath: 'priceMonthly', order: 'ASCENDING' }
    ],
    queryPurpose: 'Price filtering: available properties from cheapest',
    queryExample: `db.collection('terrenos')
      .where('status', '==', 'disponible')
      .where('priceMonthly', '>=', minPrice)
      .where('priceMonthly', '<=', maxPrice)
      .orderBy('priceMonthly', 'asc')`,
    estimatedDocsReturned: '10-100',
    performanceImpact: 'Very High - main filter UI interaction',
    createdAt: 'Etapa A week 1',
  },
  
  {
    collectionGroup: 'terrenos',
    fields: [
      { fieldPath: 'status', order: 'ASCENDING' },
      { fieldPath: 'priceMonthly', order: 'DESCENDING' }
    ],
    queryPurpose: 'Price filtering: available properties from most expensive',
    queryExample: `db.collection('terrenos')
      .where('status', '==', 'disponible')
      .orderBy('priceMonthly', 'desc')`,
    estimatedDocsReturned: '10-100',
    performanceImpact: 'High - alternative sort direction',
    createdAt: 'Etapa A week 1',
  },
  
  {
    collectionGroup: 'reservas',
    fields: [
      { fieldPath: 'renterId', order: 'ASCENDING' },
      { fieldPath: 'createdAt', order: 'DESCENDING' }
    ],
    queryPurpose: 'Renter dashboard: my reservations',
    queryExample: `db.collection('reservas')
      .where('renterId', '==', uid)
      .orderBy('createdAt', 'desc')`,
    estimatedDocsReturned: '5-50 per renter',
    performanceImpact: 'High - renter dashboard',
    createdAt: 'Etapa A week 1',
  },
  
  {
    collectionGroup: 'reservas',
    fields: [
      { fieldPath: 'ownerId', order: 'ASCENDING' },
      { fieldPath: 'createdAt', order: 'DESCENDING' }
    ],
    queryPurpose: 'Owner dashboard: incoming reservations',
    queryExample: `db.collection('reservas')
      .where('ownerId', '==', uid)
      .orderBy('createdAt', 'desc')`,
    estimatedDocsReturned: '5-50 per owner',
    performanceImpact: 'High - owner notifications',
    createdAt: 'Etapa A week 1',
  },
];

/**
 * PRIORITY TIER 2: ESSENTIAL (Launch blocked if completely missing, but can MVP with subset)
 * Affects: Geographic queries (map), messaging, message history
 */
export const TIER_2_ESSENTIAL_INDEXES = [
  {
    collectionGroup: 'terrenos',
    fields: [
      { fieldPath: 'geohash', order: 'ASCENDING' },
      { fieldPath: 'status', order: 'ASCENDING' }
    ],
    queryPurpose: 'Map viewport query: terrenos in geographic area',
    queryExample: `db.collection('terrenos')
      .where('geohash', '==', '9q9h')  // 6-char geohash for ~1.2km area
      .where('status', '==', 'disponible')`,
    estimatedDocsReturned: '1-100 per viewport',
    performanceImpact: 'High - map page interaction (MVP may not use geohash in Etapa A)',
    note: 'Can be deferred to Etapa B if map not critical',
    createdAt: 'Etapa A week 2',
  },
  
  {
    collectionGroup: 'terrenos',
    fields: [
      { fieldPath: 'geohash', order: 'ASCENDING' },
      { fieldPath: 'status', order: 'ASCENDING' },
      { fieldPath: 'priceMonthly', order: 'ASCENDING' }
    ],
    queryPurpose: 'Map filter: terrenos in area + price range',
    queryExample: `db.collection('terrenos')
      .where('geohash', '==', '9q9h')
      .where('status', '==', 'disponible')
      .where('priceMonthly', '>=', minPrice)
      .orderBy('priceMonthly', 'asc')`,
    estimatedDocsReturned: '1-50',
    performanceImpact: 'High - filtered map results',
    note: 'Geohash + status + price triple index',
    createdAt: 'Etapa B',
  },
  
  {
    collectionGroup: 'conversaciones',
    fields: [
      { fieldPath: 'ownerId', order: 'ASCENDING' },
      { fieldPath: 'lastMessageAt', order: 'DESCENDING' }
    ],
    queryPurpose: "Owner message inbox: conversations by recency",
    queryExample: `db.collection('conversaciones')
      .where('ownerId', '==', uid)
      .orderBy('lastMessageAt', 'desc')`,
    estimatedDocsReturned: '1-100',
    performanceImpact: 'Medium - messaging UI (Etapa D)',
    createdAt: 'Etapa D',
  },
  
  {
    collectionGroup: 'conversaciones',
    fields: [
      { fieldPath: 'renterId', order: 'ASCENDING' },
      { fieldPath: 'lastMessageAt', order: 'DESCENDING' }
    ],
    queryPurpose: "Renter message inbox: conversations by recency",
    queryExample: `db.collection('conversaciones')
      .where('renterId', '==', uid)
      .orderBy('lastMessageAt', 'desc')`,
    estimatedDocsReturned: '1-100',
    performanceImpact: 'Medium - messaging UI (Etapa D)',
    createdAt: 'Etapa D',
  },
  
  {
    collectionGroup: 'mensajes',  // Collection group query
    fields: [
      { fieldPath: '__name__', order: 'ASCENDING' },  // Document ID (automatic for collection groups)
      { fieldPath: 'createdAt', order: 'DESCENDING' }
    ],
    queryPurpose: 'List all messages in conversation, paginated',
    queryExample: `db.collectionGroup('mensajes')
      .where('conversationId', '==', convId)
      .orderBy('createdAt', 'desc')
      .limit(50)`,
    estimatedDocsReturned: '1-50 per page',
    performanceImpact: 'Medium - chat history (Etapa D)',
    note: 'Collection group index for analytics (optional in Etapa A)',
    createdAt: 'Etapa D (optional)',
  },
  
  {
    collectionGroup: 'payment_events',
    fields: [
      { fieldPath: 'externalReference', order: 'ASCENDING' },
      { fieldPath: 'createdAt', order: 'DESCENDING' }
    ],
    queryPurpose: 'Idempotent webhook lookup: find existing event by reference',
    queryExample: `db.collection('payment_events')
      .where('externalReference', '==', boldWebhookId)
      .limit(1)`,
    estimatedDocsReturned: '0-1',
    performanceImpact: 'Critical for webhook handling (Etapa C)',
    createdAt: 'Etapa C',
  },
  
  {
    collectionGroup: 'payment_events',
    fields: [
      { fieldPath: 'reservaId', order: 'ASCENDING' },
      { fieldPath: 'createdAt', order: 'DESCENDING' }
    ],
    queryPurpose: 'Payment audit trail: all events for reservation',
    queryExample: `db.collection('payment_events')
      .where('reservaId', '==', reservaId)
      .orderBy('createdAt', 'desc')`,
    estimatedDocsReturned: '1-5 per reservation',
    performanceImpact: 'Medium - payment troubleshooting (Etapa C)',
    createdAt: 'Etapa C',
  },
];

/**
 * PRIORITY TIER 3: NICE-TO-HAVE (Performance optimization, not blocking)
 * Affects: Analytics, reporting, edge cases
 */
export const TIER_3_NICE_TO_HAVE_INDEXES = [
  {
    collectionGroup: 'terrenos',
    fields: [
      { fieldPath: 'status', order: 'ASCENDING' },
      { fieldPath: 'ratingAvg', order: 'DESCENDING' }
    ],
    queryPurpose: 'Sort available properties by highest rating',
    queryExample: `db.collection('terrenos')
      .where('status', '==', 'disponible')
      .orderBy('ratingAvg', 'desc')`,
    estimatedDocsReturned: '50-500',
    performanceImpact: 'Low - optional UI sort',
    createdAt: 'Etapa F (after reviews implemented)',
  },
  
  {
    collectionGroup: 'terrenos',
    fields: [
      { fieldPath: 'status', order: 'ASCENDING' },
      { fieldPath: 'hectares', order: 'ASCENDING' }
    ],
    queryPurpose: 'Filter by land size',
    queryExample: `db.collection('terrenos')
      .where('status', '==', 'disponible')
      .where('sizeHectares', '>=', minSize)
      .orderBy('sizeHectares', 'asc')`,
    estimatedDocsReturned: '10-100',
    performanceImpact: 'Low - optional filter (size range not in MVP filters)',
    createdAt: 'Future',
  },
  
  {
    collectionGroup: 'reviews',
    fields: [
      { fieldPath: 'terrenoId', order: 'ASCENDING' },
      { fieldPath: 'createdAt', order: 'DESCENDING' }
    ],
    queryPurpose: 'List reviews for terreno, newest first',
    queryExample: `db.collection('reviews')
      .where('terrenoId', '==', terrenoId)
      .orderBy('createdAt', 'desc')
      .limit(10)`,
    estimatedDocsReturned: '1-50',
    performanceImpact: 'Low - reviews not critical in Etapa A/B',
    createdAt: 'Etapa F',
  },
];

// ============================================================================
// 2. INDEX DEPLOYMENT MANIFEST
// ============================================================================

/**
 * DEPLOYMENT MANIFEST: firestore.indexes.json
 * 
 * To generate this file:
 * 1. Run: firebase firestore:indexes --export-to ./firestore.indexes.json
 * 2. Manually add indexes from TIER_1_BLOCKING_INDEXES
 * 3. Deploy: firebase deploy --only firestore:indexes
 * 
 * Backfill time: 1-10 minutes depending on collection size
 * Cost: ~$0.10 per million documents indexed
 */

export const FIRESTORE_INDEXES_CONFIG = {
  indexes: [
    // === TIER 1: BLOCKING ===
    {
      collectionGroup: 'terrenos',
      queryScope: 'COLLECTION',
      fields: [
        { fieldPath: 'ownerId', order: 'ASCENDING' },
        { fieldPath: 'createdAt', order: 'DESCENDING' }
      ]
    },
    {
      collectionGroup: 'terrenos',
      queryScope: 'COLLECTION',
      fields: [
        { fieldPath: 'status', order: 'ASCENDING' },
        { fieldPath: 'createdAt', order: 'DESCENDING' }
      ]
    },
    {
      collectionGroup: 'terrenos',
      queryScope: 'COLLECTION',
      fields: [
        { fieldPath: 'status', order: 'ASCENDING' },
        { fieldPath: 'priceMonthly', order: 'ASCENDING' }
      ]
    },
    {
      collectionGroup: 'terrenos',
      queryScope: 'COLLECTION',
      fields: [
        { fieldPath: 'status', order: 'ASCENDING' },
        { fieldPath: 'priceMonthly', order: 'DESCENDING' }
      ]
    },
    {
      collectionGroup: 'reservas',
      queryScope: 'COLLECTION',
      fields: [
        { fieldPath: 'renterId', order: 'ASCENDING' },
        { fieldPath: 'createdAt', order: 'DESCENDING' }
      ]
    },
    {
      collectionGroup: 'reservas',
      queryScope: 'COLLECTION',
      fields: [
        { fieldPath: 'ownerId', order: 'ASCENDING' },
        { fieldPath: 'createdAt', order: 'DESCENDING' }
      ]
    },
    
    // === TIER 2: ESSENTIAL (Etapa B+) ===
    {
      collectionGroup: 'conversaciones',
      queryScope: 'COLLECTION',
      fields: [
        { fieldPath: 'ownerId', order: 'ASCENDING' },
        { fieldPath: 'lastMessageAt', order: 'DESCENDING' }
      ]
    },
    {
      collectionGroup: 'conversaciones',
      queryScope: 'COLLECTION',
      fields: [
        { fieldPath: 'renterId', order: 'ASCENDING' },
        { fieldPath: 'lastMessageAt', order: 'DESCENDING' }
      ]
    },
    {
      collectionGroup: 'payment_events',
      queryScope: 'COLLECTION',
      fields: [
        { fieldPath: 'externalReference', order: 'ASCENDING' },
        { fieldPath: 'createdAt', order: 'DESCENDING' }
      ]
    },
    {
      collectionGroup: 'payment_events',
      queryScope: 'COLLECTION',
      fields: [
        { fieldPath: 'reservaId', order: 'ASCENDING' },
        { fieldPath: 'createdAt', order: 'DESCENDING' }
      ]
    },
  ],
  fieldOverrides: []
};

// ============================================================================
// 3. PERFORMANCE BENCHMARKS & MONITORING
// ============================================================================

export const INDEX_PERFORMANCE_TARGETS = {
  queryLatencyP50: '< 100ms',          // 50th percentile
  queryLatencyP99: '< 500ms',          // 99th percentile
  indexBackfillTime: '< 10 minutes',   // Composite index creation
  indexStoragePerDoc: '< 100 bytes',   // Approximate index entry size
  
  // Monitoring alerts
  alerts: [
    {
      metric: 'query latency P99',
      threshold: '> 1000ms',
      action: 'Review query plan, consider denormalization or caching'
    },
    {
      metric: 'index backfill incomplete',
      threshold: '> 30 minutes',
      action: 'Check Firestore console, contact Firebase support'
    },
    {
      metric: 'composite index count',
      threshold: '> 30',
      action: 'Review unused indexes, consider consolidation'
    }
  ]
};

// ============================================================================
// 4. SINGLE-FIELD INDEX STRATEGY
// ============================================================================

/**
 * SINGLE-FIELD INDEXES (AUTO-CREATED, NO CONFIGURATION)
 * 
 * Firestore automatically creates these when queries are executed:
 * 
 * terrenos:
 *   - ownerId (first query filters by owner)
 *   - status (first query filters by status)
 *   - geohash (first geohash query)
 *   - priceMonthly (first price sorting)
 *   - createdAt (first date sorting)
 *   - ratingAvg (if rating sort requested)
 *   - features (if array query executed)
 * 
 * reservas:
 *   - renterId
 *   - ownerId
 *   - terrenoId
 *   - status
 *   - paymentStatus
 *   - expiresAt
 * 
 * users:
 *   - email (for uniqueness check)
 *   - status
 * 
 * conversaciones:
 *   - reservaId
 * 
 * No action needed: Firestore handles automatically
 * Cost: No extra charge for single-field indexes
 */

// ============================================================================
// 5. MIGRATION STRATEGY FOR EXISTING DATA
// ============================================================================

/**
 * ETAPA A: Getting indexes right from the start
 * 
 * Timeline:
 * Week 1: Deploy TIER_1_BLOCKING indexes
 * Week 2-3: Deploy TIER_2_ESSENTIAL indexes as features implemented
 * Week 4+: Deploy TIER_3_NICE_TO_HAVE as bandwidth allows
 * 
 * Verification:
 * 1. Run test query for each index in Firestore console
 * 2. Check "Explain" tab shows index is used (not full collection scan)
 * 3. Monitor latency metrics in Cloud Console
 * 
 * Rollback strategy:
 * Indexes can be deleted without affecting data
 * Run: firebase firestore:delete-index <index-id>
 * Queries revert to full collection scan (slow but still work)
 */

export const ETAPA_A_INDEX_ROADMAP = `
WEEK 1 (MVP Launch):
- Deploy TIER_1_BLOCKING indexes
- Test: owner dashboard, discovery page, filter queries
- Verify: query latency < 500ms on emulator
- Estimate: ~15 minutes deployment time

WEEK 2 (Etapa B starts):
- Deploy TIER_2_ESSENTIAL indexes (payment events)
- Add messaging indexes when Etapa D starts
- Monitor: query latency in staging environment

WEEK 3+:
- Deploy TIER_3_NICE_TO_HAVE as features added
- Audit: unused indexes, consolidate if needed
- Optimize: if query latency degrading, add denormalization
`;
