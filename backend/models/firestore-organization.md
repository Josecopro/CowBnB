/**
 * FIRESTORE COLLECTIONS ORGANIZATION STRATEGY
 * Etapa A Data Architecture for CowBnB
 * 
 * This document defines:
 * - Root-level collection structure
 * - Subcollection strategy
 * - Document ID strategy (auto vs. custom)
 * - Database growth projections
 * - Query patterns and optimization
 */

// ============================================================================
// 1. COLLECTION HIERARCHY & ORGANIZATION
// ============================================================================

/**
 * ROOT COLLECTIONS (read/write at top level):
 * 
 * users/
 *   └─ {uid}          Documents identified by Firebase Auth UID
 * 
 * terrenos/
 *   └─ {auto-id}      Auto-generated document IDs for land listings
 * 
 * reservas/
 *   └─ {auto-id}      Auto-generated reservation records
 * 
 * payment_events/
 *   └─ {auto-id}      Immutable audit trail of payment transactions
 *                      (Etapa C: payment processing & webhooks)
 * 
 * conversaciones/
 *   └─ {auto-id}      Conversation records linking owner + renter + reservation
 *         └─ mensajes/
 *            └─ {auto-id}   Individual messages (Etapa D: messaging)
 * 
 * reviews/
 *   └─ {auto-id}      Review/rating records (Etapa F: reviews & scoring)
 * 
 * FUTURE (placeholder structure):
 * 
 * ndvi_checks/        (Etapa E: satellite monitoring)
 * action_tokens/      (Etapa E: one-time reactivation links)
 * recommendations/    (Etapa F: personalized suggestions)
 */

// ============================================================================
// 2. DOCUMENT ID STRATEGY
// ============================================================================

/**
 * DECISION RATIONALE FOR ETAPA A:
 * 
 * (A) AUTO-GENERATED (Firestore default: random alphanumeric, ~20 chars)
 *     Pros: Distributed write performance, impossible collisions
 *     Cons: IDs not human-readable, cannot control ordering in URLs
 *     Use for: terrenos, reservas, reviews, payment_events, conversaciones, mensajes
 * 
 * (B) CUSTOM (application-generated: uid, email hash, etc.)
 *     Pros: Human-readable, semantic meaning, deduplication when retrying creates
 *     Cons: Hot spots under concurrent writes to same custom ID, slower on distributed systems
 *     Use for: users (as Firebase Auth UID directly)
 * 
 * (C) TIMESTAMP-BASED (YYYYMMDD_HHmmss_xxx)
 *     Pros: Sortable in lexicographic order, human-readable
 *     Cons: Potential collisions if not salted with random suffix, hot spots on latest timestamp
 *     Use for: None in Etapa A (Firebase already sorts by ID for collection group queries)
 * 
 * ETAPA A DECISION:
 * - users/{uid}                         → Custom: Firebase Auth UID
 * - terrenos/{id}                       → Auto-generated (Firestore default)
 * - reservas/{id}                       → Auto-generated
 * - payment_events/{id}                 → Auto-generated
 * - conversaciones/{id}                 → Auto-generated
 * - conversaciones/{id}/mensajes/{id}   → Auto-generated
 * - reviews/{id}                        → Auto-generated
 * 
 * RATIONALE for users/{uid}:
 * - Simplifies security rules: match auth.uid == resource.id
 * - Eliminates need for uid field in document (deduplication)
 * - Faster permission checks (direct path lookup vs. query)
 * - Prevents account linkage bugs (1:1 mapping between Auth & Firestore)
 * 
 * RATIONALE for auto-generated for other collections:
 * - Enables high-frequency writes (terrenos updates, reserva creation)
 * - No application logic for ID collision handling needed in Etapa A
 * - Query patterns don't rely on ID sorting (use indexed fields instead)
 * - Simpler error handling on retried creates
 */

// ============================================================================
// 3. SUBCOLLECTION VS ROOT COLLECTION DECISION
// ============================================================================

/**
 * DECISION: Use ROOT COLLECTIONS for core entities, SUBCOLLECTIONS only for:
 * - Entities logically grouped and queried exclusively within parent
 * - High fan-out scenarios where pagination per parent is critical
 * 
 * ETAPA A STRUCTURE:
 * 
 * mensajes as SUBCOLLECTION under conversaciones:
 *   ✓ Messages are accessed in batches per conversation
 *   ✓ Prevents "read all messages" queries (security boundary)
 *   ✓ Natural pagination: load 50 messages per chat session
 *   ✓ Limits: max 100MB per Conversacion doc = ~500k messages
 *   ✓ Collection group query still possible if analytics needed
 * 
 * WHAT NOT TO USE SUBCOLLECTIONS FOR:
 * 
 * ✗ images (as terrenos/{id}/images)
 *   Reason: Images are metadata within Terreno, not independent entities
 *           Solution: Store as array field TerrenoImage[] in document
 *           Limit: Max ~100 images per Terreno before hitting doc size limit (1MB)
 * 
 * ✗ payment_events (as reservas/{id}/payment_events)
 *   Reason: Payment audit trail requires independent querying
 *          (e.g., "find all failed payments" across all reservas)
 *           Solution: Root collection with reference to reservaId
 * 
 * ✗ reviews (as terrenos/{id}/reviews)
 *   Reason: Reviews need independent aggregation queries
 *          (e.g., "calculate average rating across all reviews")
 *           Solution: Root collection with indexed reference to terrenoId
 */

// ============================================================================
// 4. RELATIONSHIP PATTERNS & DENORMALIZATION STRATEGY
// ============================================================================

/**
 * PATTERN 1: Direct Reference (Foreign Key)
 * 
 *   Terreno.ownerId → references User.uid
 *   Reserva.terrenoId → references Terreno.id
 *   Reserva.renterId → references User.uid
 * 
 * Use when:
 *   - Relationship is 1:N or N:1
 *   - Both documents accessed frequently
 *   - No need to cascade updates
 * 
 * Query pattern:
 *   GET terrenos WHERE ownerId == currentUser.uid (indexed)
 *   GET user WHERE uid == terreno.ownerId (direct lookup)
 * 
 * ---
 * 
 * PATTERN 2: Denormalization (Copy field from parent)
 * 
 * Example: Reserva includes:
 *   - terrenoId (reference)
 *   - ownerId (denormalized from Terreno for quick filtering)
 *   - pricePerMonth (denormalized snapshot of Terreno.priceMonthly at time of booking)
 * 
 * Why denormalize pricePerMonth?
 *   - Historical accuracy: price may change after reservation created
 *   - Avoids N+1 joins when listing reservations with prices
 *   - Payment receipt shows exact price that was charged
 * 
 * Cost of denormalization:
 *   - Update Terreno.priceMonthly → must NOT update existing Reserva.pricePerMonth
 *   - Storage: +4-8 bytes per document
 *   - Consistency maintained by backend logic (not auto-sync)
 * 
 * When to denormalize:
 *   ✓ Field is frequently queried/displayed with parent
 *   ✓ Field rarely changes
 *   ✓ Snapshot accuracy matters (financial, historical)
 * 
 * When NOT to denormalize:
 *   ✗ Field changes frequently (would require updating many documents)
 *   ✗ Field is rarely accessed alongside parent
 *   ✗ Storage cost outweighs query savings
 * 
 * ---
 * 
 * PATTERN 3: Count Aggregation (Denormalized counter)
 * 
 * Example: Terreno includes:
 *   - ratingCount: number of reviews
 *   - ratingAvg: average review score
 * 
 * Why aggregated?
 *   - Avoids COUNT query on reviews collection each time Terreno displayed
 *   - Enables sorting by rating efficiently
 * 
 * Consistency challenge:
 *   - When Review created/deleted → must increment/decrement counters
 *   - Solution in Etapa F: Cloud Function trigger on reviews collection
 * 
 * Implementation detail (Etapa F):
 *   onCreate: increment Terreno.ratingCount, recalculate ratingAvg
 *   onDelete: decrement, recalculate
 *   onUpdate: only if rating changed, recalculate
 */

// ============================================================================
// 5. DATA GROWTH & CAPACITY PROJECTIONS
// ============================================================================

/**
 * ESTIMATED DATA VOLUMES FOR ETAPA A (3-6 months MVP):
 * 
 * Test Data (Local Development):
 *   - 10 users (5 owners, 5 renters)
 *   - 20 terrenos (listings with 5 images each)
 *   - 10 reservas (partial checkout flow)
 *   - 50 messages across all conversations
 *   Total: ~100-200 documents, <2MB storage
 * 
 * Staging Environment (10-50 users):
 *   - 50 users
 *   - 100 terrenos (5 images each)
 *   - 50 reservas
 *   - 1000 messages
 *   - 200 payment_events
 *   Total: ~1500 documents, ~15-20MB storage
 * 
 * Production After 3 months (1000 users):
 *   - 1000 users (average 50% owner, 50% renter, but overlap)
 *   - 500 terrenos (20,000 Terreno documents over time)
 *   - 1000 reservas (both active and archived)
 *   - 5000 messages
 *   - 1500 payment_events
 *   - 500 reviews
 *   Total: ~30,000 documents, ~100-150MB storage
 * 
 * Growth after 1 year:
 *   - 10-50k users
 *   - 5-10k active terrenos
 *   - 50k+ reservas (historical)
 *   - 100k+ messages
 *   - 20k+ payment_events
 *   Total: potentially 200k+ documents, 1-2GB storage
 * 
 * Firestore Capacity (Standard Edition):
 *   - Read ops: 50,000 per second (theoretical max)
 *   - Write ops: 20,000 per second (theoretical max)
 *   - Storage: 50GB included free tier, then metered
 * 
 * Etapa A expectations: well within limits
 * Scaling considerations (future):
 *   - Collection sharding if writes to same doc exceed 1000/sec
 *   - Caching layer (Redis/Memcache) for popular queries
 *   - Cloud Datastore export for reporting/analytics
 */

// ============================================================================
// 6. CRITICAL QUERY PATTERNS FOR ETAPA A
// ============================================================================

/**
 * Q1: List terrenos by owner (dashboard view)
 *     Firebase: db.collection('terrenos').where('ownerId', '==', uid).orderBy('createdAt', 'desc')
 *     needs INDEX: {ownerId ASC, createdAt DESC}
 *     reasons: Owner dashboard shows their listings most recent first
 * 
 * Q2: Find available terrenos with filters
 *     Firebase: db.collection('terrenos')
 *               .where('status', '==', 'disponible')
 *               .where('priceMonthly', '>=', minPrice)
 *               .where('priceMonthly', '<=', maxPrice)
 *               .orderBy('priceMonthly', 'asc')
 *     needs INDEXES:
 *       - {status ASC, priceMonthly ASC}
 *       - {status ASC, priceMonthly DESC}  (if clients also sort descending)
 *     reasons: Map discovery, filtering by available + price range
 * 
 * Q3: Terrenos by geohash + status + price
 *     Firebase: db.collection('terrenos')
 *               .where('geohash', '==', '<6-digit hash>')
 *               .where('status', '==', 'disponible')
 *               .where('priceMonthly', '>=', minPrice)
 *               .orderBy('priceMonthly', 'asc')
 *     needs INDEX: {geohash ASC, status ASC, priceMonthly ASC}
 *     reasons: Viewport-based map queries (Etapa A MVP query pattern)
 * 
 * Q4: List reservas by renter
 *     Firebase: db.collection('reservas').where('renterId', '==', uid).where('status', '==', 'reservado')
 *     needs INDEX: {renterId ASC, status ASC}
 *     reasons: Renter dashboard shows their active and past bookings
 * 
 * Q5: Find reserved terrenos for time range (conflict detection)
 *     Firebase: db.collection('reservas')
 *               .where('terrenoId', '==', terreno_id)
 *               .where('status', '==', 'reservado')
 *               .where('startDate', '<', proposed_end)
 *               .where('endDate', '>', proposed_start)
 *     needs INDEX: {terrenoId ASC, status ASC, startDate ASC, endDate ASC}
 *     reasons: Validate no double-bookings in Etapa B/C (optional for MVP)
 * 
 * Q6: List messages in conversation
 *     Firebase: db.collection('conversaciones').doc(convo_id).collection('mensajes')
 *               .orderBy('createdAt', 'desc')
 *               .limit(50)
 *     needs SUBCOLLECTION INDEX: {createdAt DESC}
 *     reasons: Chat pagination, latest messages first
 * 
 * Q7: List conversations by user, sorted by recent activity
 *     Firebase: db.collection('conversaciones')
 *               .where('ownerId', '==', uid)
 *               .orderBy('lastMessageAt', 'desc')
 *     needs INDEX: {ownerId ASC, lastMessageAt DESC}
 *     reasons: Inbox view shows most active chats first
 * 
 * Q8: Find payment events for audit
 *     Firebase: db.collection('payment_events')
 *               .where('reservaId', '==', reserva_id)
 *               .orderBy('createdAt', 'desc')
 *     needs INDEX: {reservaId ASC, createdAt DESC}
 *     reasons: Payment audit trail, troubleshooting failed payments
 */

// ============================================================================
// 7. INDEXES: AUTO-CREATED VS MANUAL CONFIGURATION
// ============================================================================

/**
 * FIRESTORE INDEX BEHAVIOR:
 * 
 * Single-field indexes (auto-created):
 *   - Firestore automatically creates when first query needs it
 *   - No configuration required
 *   - Examples: filtering by ownerId alone, orderBy on single field
 * 
 * Composite indexes (manual):
 *   - Required when query has 2+ fields AND ordering/inequality
 *   - Must be explicitly created in firestore.indexes.json or Firebase Console
 *   - Example: WHERE status AND orderBy createdAt
 *   - NOT needed: WHERE status AND WHERE priceMonthly without orderBy
 * 
 * ETAPA A INDEX CREATION STRATEGY:
 * 
 * 1. Deploy without indexes first (local emulator testing)
 * 2. Firestore SDK logs errors if missing composite index
 * 3. Extract from logs → add to firestore.indexes.json
 * 4. Deploy indexes via: firebase deploy --only firestore:indexes
 * 
 * Note: Composite index creation takes minutes to hours
 * Backfill cost: ~$0.10 per million documents indexed
 * Ongoing cost: queries using index cost 1 read operation per doc returned + 1 index entry
 */

// ============================================================================
// 8. SECURITY RULES: IMPACT ON DATA STRUCTURE
// ============================================================================

/**
 * Security rules influence how data should be organized:
 * 
 * RULE: "Only users can read their own user document"
 *   Implication: User data MUST be at users/{uid}
 *               Cannot put user data in terrenos/{id}/owner_info
 *   Benefit: Simple rule: match /databases/{database}/documents/users/{uid} {
 *              allow read, write: if request.auth.uid == uid;
 *            }
 * 
 * RULE: "Terrenos are publicly readable if status='disponible'"
 *   Implication: Read field access depends only on status, not user role
 *               No need to replicate terreno data per-user
 *   Query pattern: db.collection('terrenos').where('status', '==', 'disponible')
 * 
 * RULE: "Messages only readable by conversation participants"
 *   Implication: Messages MUST include senderId, receiverId for rule check
 *               Cannot use implicit parent-child relationship alone
 *   Security rule: allow read: if resource.data.senderId == request.auth.uid
 *                            || resource.data.receiverId == request.auth.uid
 * 
 * RESULT: Data structure must contain fields needed for security rule evaluation
 *         This sometimes conflicts with normalization (accept it)
 */

// ============================================================================
// 9. DOCUMENT SIZE MANAGEMENT
// ============================================================================

/**
 * FIRESTORE LIMITS (Standard):
 * - Max document size: 1 MB
 * - Max array size: no limit, but counts toward doc size
 * - Max string size: no limit, but counts toward doc size
 * 
 * ETAPA A STRUCTURE SIZES (estimated):
 * 
 * User document: ~500 bytes
 *   - uid (36 bytes)
 *   - email (50 bytes)
 *   - fullName (50 bytes)
 *   - phone (15 bytes)
 *   - other fields (~200 bytes)
 * 
 * Terreno document with 10 images: ~50-100 KB
 *   - Basic fields: ~500 bytes
 *   - 10 TerrenoImage objects: ~5-10 KB each
 *   - descriptions: ~5 KB
 * 
 * Reserva document: ~1-2 KB
 * 
 * Conversacion document: ~1-2 KB
 * 
 * SAFE LIMITS:
 * ✓ Terrenos with up to 10 images: well within 1 MB
 * ✓ Array fields safely store 100+ messages (use subcollection instead)
 * ✗ Do NOT store message history in Conversacion doc (use subcollection)
 * ✗ Do NOT store all payment events in Reserva (use root collection)
 * 
 * MONITORING:
 *   - Use Firebase Console to check largest documents
 *   - Alert if any doc exceeds 500 KB
 *   - Refactor early: extract to subcollection or separate document
 */

// ============================================================================
// 10. MIGRATION PATH FROM CURRENT STATE
// ============================================================================

/**
 * TODAY: No backend exists. Frontend has mock routes but no persistence.
 * 
 * ETAPA A: Local-only data model that can scale.
 * 
 * STEPS:
 * 
 * 1. EMULATOR SETUP (developers)
 *    - Run: firebase emulators:start
 *    - Frontend connects to emulator (localhost:8080)
 *    - No real Firebase project needed until Etapa B
 * 
 * 2. SEED DATA (test fixtures)
 *    - Create test-data.json with sample users, terrenos, reservas
 *    - Loader function: seedEmulator(testData) - populates in-memory Firestore
 *    - Used for: unit tests, local development, demo builds
 * 
 * 3. STAGING DEPLOYMENT (Etapa B)
 *    - Deploy to real Firebase project
 *    - Import seed data from test-data.json
 *    - Restrict to staging URL, require invite to register
 * 
 * 4. PRODUCTION DEPLOYMENT (Etapa B+)
 *    - Fresh Firestore instance
 *    - Security rules enforced
 *    - Backup strategy activated
 *    - Monitoring & alerting configured
 * 
 * DATA ARCHITECTURE REMAINS SAME:
 * - Etapa A data structure works in emulator, staging, and production
 * - Zero schema changes after Etapa A ships (add collections in B/C/D/E/F, not modify core ones)
 * - Backward compatible if we add nullable fields (avoid removing fields)
 */

export const ETAPA_A_STRUCTURE_SUMMARY = `
COLLECTIONS (Etapa A):
✓ users/{uid}
✓ terrenos/{id}
✓ reservas/{id}
✓ conversaciones/{id} + conversaciones/{id}/mensajes/{id}
✓ payment_events/{id}
✓ reviews/{id}

INDEXES NEEDED (Etapa A - Critical):
✓ terrenos: {ownerId ASC, createdAt DESC}
✓ terrenos: {status ASC, createdAt DESC}
✓ terrenos: {status ASC, priceMonthly ASC}
✓ terrenos: {status ASC, priceMonthly DESC}
✓ terrenos: {geohash ASC, status ASC}
✓ terrenos: {geohash ASC, status ASC, priceMonthly ASC}
✓ reservas: {renterId ASC, createdAt DESC}
✓ reservas: {ownerId ASC, createdAt DESC}
✓ payment_events: {reservaId ASC, createdAt DESC}
✓ conversaciones: {ownerId ASC, lastMessageAt DESC}
✓ conversaciones: {renterId ASC, lastMessageAt DESC}
✓ mensajes (collection group): {conversationId ASC, createdAt DESC}

REMAINING COLLECTIONS (Future Etapas):
- ndvi_checks (Etapa E)
- action_tokens (Etapa E)
- recommendations (Etapa F)
- user_analytics (Etapa F)

CAPACITY: Etapa A fully supports 100-1000 active users with <500MB storage
`;
