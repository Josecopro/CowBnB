# CowBnB Data Model Foundation - Etapa A Complete Reference

**Status:** ✅ Complete  
**Created:** 2024-01-XX  
**Supervised by:** Data Agent  
**Implementation guidance:** See sections 3.2 and 5-7 of IMPLEMENTATION_PLAN.md

---

## 📋 Document Map

This data model foundation consists of **5 integrated documents** + this index:

| Document | Purpose | Audience |
|----------|---------|----------|
| [data-models.ts](data-models.ts) | TypeScript interfaces for all collections | Developers (backend + frontend) |
| [firestore-organization.md](firestore-organization.md) | Collection strategy, relationships, patterns | Architects |
| [validation-rules.ts](validation-rules.ts) | Field constraints & business logic | Backend developers |
| [firestore-indexes.ts](firestore-indexes.ts) | Composite indexes & query optimization | DevOps / Backend |
| [data-migration-strategy.ts](data-migration-strategy.ts) | Seeding, emulator setup, deployment | All developers |

**Quick links:**
- 🗂️ [Collection Structure Diagram](#collection-structure)
- 🔍 [Query Patterns & Indexes](#query-patterns)
- ✅ [Validation Checklist](#validation-checklist)
- 🚀 [Deployment Roadmap](#deployment-roadmap)

---

## 🗂️ Collection Structure

### Collections for Etapa A (REQUIRED)

```
Firestore Database (cowbnb-prod / cowbnb-staging)
├── users/ {7 collections minimum}
│   ├── uid (document ID) - Firebase Auth UID
│   └── Fields: email, fullName, phone, role, status, etc.
│
├── terrenos/
│   ├── id (auto-generated document ID)
│   └── Fields: ownerId, title, location, priceMonthly, status, images[], etc.
│
├── reservas/
│   ├── id (auto-generated document ID)
│   └── Fields: renterId, ownerId, terrenoId, startDate, endDate, status, paymentStatus, etc.
│
├── conversaciones/
│   ├── id (auto-generated document ID)
│   ├── Fields: ownerId, renterId, reservaId, lastMessageAt, etc.
│   └── [SUBCOLLECTION] mensajes/
│       ├── id (auto-generated document ID)
│       └── Fields: senderId, text, createdAt, etc.
│
├── payment_events/
│   ├── id (auto-generated document ID)
│   └── Fields: externalReference, reservaId, status, amount, etc.
│
├── reviews/  (prepared for Etapa F)
│   ├── id (auto-generated document ID)
│   └── Fields: terrenoId, reservaId, rating, comment, etc.
│
└── [FUTURE] ndvi_checks/, action_tokens/, recommendations/
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| `users/{uid}` as document ID | Simplifies security rules, enables direct lookup by auth.uid |
| Auto-generated IDs for others | Enables distributed writes, prevents hot spots |
| `mensajes` as subcollection | Logical grouping, enables per-conversation pagination |
| `payment_events` as root collection | Independent querying needed (not nested in reservas) |
| Denormalization of `pricePerMonth` in reservas | Historical accuracy, avoids N+1 joins |
| Geohash in terreno location | Enables efficient geographic queries |

---

## 🔍 Query Patterns & Indexes

### Tier 1: Blocking Indexes (Must create - Week 1)

These indexes **BLOCK** Etapa A launch if missing:

```typescript
// MUST have these 6 composite indexes deployed:

1. terrenos: {ownerId ASC, createdAt DESC}
   → Owner dashboard: list "my listings"

2. terrenos: {status ASC, createdAt DESC}
   → Discovery: available properties sorted by newest

3. terrenos: {status ASC, priceMonthly ASC}
   → Discovery: price filter from cheapest

4. terrenos: {status ASC, priceMonthly DESC}
   → Discovery: price filter from most expensive

5. reservas: {renterId ASC, createdAt DESC}
   → Renter dashboard: "my bookings"

6. reservas: {ownerId ASC, createdAt DESC}
   → Owner dashboard: incoming reservations
```

**Deployment:**
```bash
# Add indexes to firestore.indexes.json, then deploy:
firebase deploy --only firestore:indexes
# Wait for backfill: 2-10 minutes depending on data size
```

### Tier 2: Essential Indexes (Etapa B+)

```typescript
7. conversaciones: {ownerId ASC, lastMessageAt DESC}
8. conversaciones: {renterId ASC, lastMessageAt DESC}
9. payment_events: {externalReference ASC, createdAt DESC}  // Idempotence
10. payment_events: {reservaId ASC, createdAt DESC}
11. mensajes collection group: {conversationId ASC, createdAt DESC}
12. terrenos: {geohash ASC, status ASC}  // Map queries
```

### Tier 3: Nice-to-Have Indexes (Etapa F+)

```typescript
13. terrenos: {status ASC, ratingAvg DESC}
14. reviews: {terrenoId ASC, createdAt DESC}
// ... others in firestore-indexes.ts
```

**Index Query Performance Targets:**
- P50 latency: < 100 ms
- P99 latency: < 500 ms
- Backfill time: < 10 minutes

---

## ✅ Validation Checklist

### Field-Level Validations

| Collection | Field | Constraint | Validation Method |
|-----------|-------|-----------|------------------|
| users | uid | Must match Firebase Auth UID | Server-side check |
| users | email | Unique, valid format | Query before insert |
| users | phone | 7-15 digits, E.164 format | Regex validation |
| users | role | 'owner' or 'renter' | Enum validation |
| terrenos | sizeHectares | > 0 and <= 100,000 | Range check |
| terrenos | priceMonthly | > 0 and <= 10,000,000 CLP | Range check |
| terrenos | location.geohash | 6-8 character Geohash | String length + format |
| terrenos | images | Max 10 per terreno | Array length check |
| reservas | startDate | >= today + 7 days | Timestamp range |
| reservas | endDate | > startDate (min 1 day) | Timestamp comparison |
| reservas | durationDays | Derived: (endDate - startDate)/86400000 | Calculated field |
| mensajes | text | 1-5000 characters | String length |

### Business Logic Validations

```typescript
// Examples from validation-rules.ts

1. User creation
   ✓ email must be unique across collection
   ✓ phone + phonePrefix must form valid number
   ✓ role is immutable after creation

2. Terreno creation
   ✓ Only ownerId can create (security rule)
   ✓ Default status = 'disponible'
   ✓ Cannot have both terreno with same title + owner + createdAt (accidental dupes)

3. Reserva creation
   ✓ renterId != ownerId (cannot book own property)
   ✓ terrenoId.status must be 'disponible'
   ✓ No double-bookings (startDate/endDate check)
   ✓ price locked at reservation time (immutable after)

4. Payment event webhook
   ✓ externalReference must be unique (idempotence)
   ✓ amount must match Reserva.estimatedTotal
   ✓ approved event triggered state transition

5. Conversacion creation
   ✓ Only created when Reserva status → 'reservado'
   ✓ 1:1 mapping per (ownerId, renterId, terrenoId)
   ✓ Only participants can read/write

6. Mensaje creation
   ✓ senderId must be participant (owner or renter)
   ✓ text non-empty, max 5000 chars
   ✓ immutable after creation (no editing in Etapa A)
```

### Security Rules Validation

**By Role (Firebase Auth):**
- `owner`: Can create/edit own terrenos; read own reservas
- `renter`: Can create reservas; read own reservas; read terrenos (if disponible)
- `public`: Can read available terrenos (status='disponible') without auth
- `admin` (backend): Manages state transitions, deletes (future)

---

## 🚀 Deployment Roadmap

### Week 1: Local Development (Emulator)

```bash
# Start emulator
firebase emulators:start

# Seed test data
npm run seed:emulator

# Run tests
npm test

# Check data in UI
# Open http://localhost:4000
```

**Verification checklist:**
- ✅ All collections appear in Firestore UI
- ✅ Seed data loads: 4 users, 4 terrenos, 1 reserva
- ✅ Tier 1 indexes created (may show "auto-created")
- ✅ Security rules pass local test suite
- ✅ Queries return expected results

### Week 2: Staging Deployment

```bash
# Create staging project
firebase projects:create cowbnb-staging

# Deploy infrastructure
firebase deploy --only firestore:rules,firestore:indexes --project=cowbnb-staging

# Seed staging data
npm run seed:staging

# Verify
firebase firestore:list --project=cowbnb-staging
```

**Approval gate:**
- ✅ Data model reviewed by 2+ engineers
- ✅ Security rules approved by security lead
- ✅ Performance targets met (query latency < 500ms)
- ✅ Backup strategy configured
- ✅ Cost estimate reviewed and approved

### Etapa B: Production Deployment

```bash
# Pre-flight checks
npm run validate:data-model
npm run test:firestore-rules

# Create production project
firebase projects:create cowbnb-prod

# Deploy
firebase deploy --only firestore:rules,firestore:indexes --project=cowbnb-prod

# Production starts empty (no seed data)
# First registrations use normal flow
```

---

## 📊 Data Volume Estimates

### Local Development (Emulator)
- **Scale:** 10 users, 20 terrenos, 10 reservas
- **Storage:** < 2 MB
- **Duration:** Indefinite (testing)

### Staging Environment
- **Scale:** 50-100 beta testers, 100+ terrenos, 50 reservas
- **Storage:** 15-50 MB
- **Duration:** Until production launch
- **Reset:** Weekly (Monday 00:00 UTC)

### Production (3 months)
- **Scale:** 1,000 active users, 500 available terrenos, 1,000 reservas
- **Storage:** 100-150 MB
- **Cost estimate:** $10-50/month (pay-as-you-go)
- **Growth rate:** 2x every 6 months

### Production (1 year)
- **Scale:** 10-50k users, 5-10k terrenos, 50k reservas
- **Storage:** 1-2 GB
- **Cost estimate:** $100-500/month
- **Indexes:** Consider denormalization if query P99 > 1 sec

---

## 🔗 Integration Points with Frontend

### Frontend Expects These Document Structures

From `IMPLEMENTATION_PLAN.md` section 2.3:

**Registration Form (registration_page.dart) → users collection**
```typescript
// Frontend sends → Backend creates
{
  email: string,
  fullName: string,
  phonePrefix: string,
  phone: string,
  role: 'owner' | 'renter',
  // password handled by Firebase Auth separately
}
```

**Create Listing (create_listing_page.dart) → terrenos collection**
```typescript
{
  title: string,
  description: string,
  sizeHectares: number,
  priceMonthly: number,
  features: string[],
  images: File[], // uploaded to Storage, then referenced in Terreno.images[]
}
```

**Checkout (checkout_page.dart) → reservas + payment_events collections**
```typescript
// Frontend sends
{
  terrenoId: string,
  startDate: Date,
  endDate: Date,
  // Triggers Payment flow
}
// Backend creates Reserva + Payment event
```

### Frontend Receives These Query Results

**Owner Dashboard:**
```typescript
terrenos WHERE ownerId==uid ORDER BY createdAt DESC
// Fields displayed: title, images[0], priceMonthly, status, ratingAvg
```

**Renter Dashboard:**
```typescript
reservas WHERE renterId==uid ORDER BY createdAt DESC
// Fields: terreno title, startDate, endDate, status, pricePerMonth
```

**Discovery/Map:**
```typescript
terrenos WHERE status=='disponible' ORDER BY priceMonthly ASC (or geohash)
// Fields: title, images[0], location, priceMonthly, ratingAvg
```

---

## 🛡️ Security Considerations

### Critical Security Decisions for Etapa A

1. **User document ID strategy**
   - ✅ Using `users/{uid}` (Firebase Auth UID as doc ID)
   - Benefit: Firestore rules can match `auth.uid == resource.id`
   - Risk: Account linkage bugs eliminated
   
2. **Payment webhook signature**
   - ✓ Included webhookSignature in PaymentEvent doc
   - ✓ Verify signature server-side before processing
   - ✓ Implement in Cloud Function (Etapa C)

3. **One-time tokens (NDVI reactivation)**
   - ✓ Design skeleton in action_tokens collection (Etapa E)
   - ✓ Token expires after 7 days
   - ✓ Token consumed after single use (immutable)

4. **Field-level access control**
   - ✓ Backend controls: status, ratingAvg, ratingCount, payment fields
   - ✓ Users cannot modify these via client SDK
   - ✓ Enforced in Firestore rules + application validation

### Security Audit Checklist

- [ ] Have 2+ security engineers reviewed `firestore.rules`
- [ ] All collections have explicit read/write rules (no wildcards)
- [ ] User can only read own documents (except terrenos if public)
- [ ] User can only create documents for themselves (except via backend)
- [ ] Tests prove role-based access works (owner cannot edit renter's reserva)
- [ ] Webhook signature verification implemented (Etapa C)
- [ ] PII fields encrypted in transit and at rest (if required by GDPR/local law)

---

## 📞 Support & Troubleshooting

### Common Issues & Solutions

**Q: "Firestore is offline" when running emulator**
A: Check `connectFirestoreEmulator()` was called before creating queries
   - See data-migration-strategy.ts section 3

**Q: Indexes not being used (slow queries)**
A: Firebase doesn't automatically use indexes
   - Verify index exists in firestore.indexes.json
   - Run `firebase deploy --only firestore:indexes`
   - Check Firestore console "Indexes" tab
   - Test query with "Explain" feature

**Q: Duplicate messages or payment events**
A: Idempotence keys missing
   - Ensure `externalReference` is unique (payment_events)
   - Check `MessageId` is unique (mensajes)
   - Implement retry logic with exponential backoff

**Q: Security rules rejecting valid requests**
A: Rule too restrictive or auth context missing
   - Verify `request.auth` is present (user must be signed in)
   - Check field references match document structure
   - Use Firebase Rules Emulator to debug
   - Run: `firebase emulators:start` then test in Emulator UI

**Q: Query latency > 1 second**
A: Missing index or over-broad query
   - Check query is using composite index (Firestore console)
   - Add pagination: `.limit(50)`
   - Consider denormalization (cache frequently accessed fields)
   - Run load test: `npm run test:performance`

### Getting Help

1. **Firebase Documentation:** https://firebase.google.com/docs/firestore
2. **Cloud Firestore Pricing:** https://firebase.google.com/pricing?hl=es
3. **Team Contact:** [Data Agent] for model questions
4. **Backend Lead:** For integration issues

---

## 📝 Implementation Checklist Before Etapa B

- [ ] All 5 model documents reviewed and approved
- [ ] TypeScript interfaces used in backend code
- [ ] Firestore rules deployed to staging
- [ ] Tier 1 indexes created and verified
- [ ] Seed data loads successfully in emulator
- [ ] 3 developers can boot local environment in < 5 minutes
- [ ] Integration tests pass (models + validation)
- [ ] Security tests prove role-based access works
- [ ] Performance targets met (query P99 < 500ms)
- [ ] Backup strategy documented (staging + future prod)
- [ ] Data privacy policy reviewed (PII handling)
- [ ] Cost monitoring alerts configured

---

## 📦 Deliverables

✅ **Complete**

- [x] Core model structures (users, terrenos, reservas, conversaciones, mensajes, payment_events, reviews)
- [x] Firestore collections organization (hierarchy, strategy, relationships)
- [x] Validation rules (field constraints, business logic, role-based access)
- [x] Critical indexes manifest (Tier 1/2/3, deployment priority)
- [x] Data migration strategy (local seeding, staging deployment, production checklist)

---

## 🎯 Next Steps (Etapa B Kickoff)

1. **Code Generation**
   - Generate backend Cloud Function stubs from models
   - Generate frontend Models + API client code from interfaces

2. **Auth Implementation**
   - Implement Firebase Auth registration/login (AUTH-01 to AUTH-05)
   - Test email verification + password reset

3. **Terreno CRUD**
   - Implement T-01 to T-03 (create, edit, view)
   - Test with seed data in emulator

4. **Validation Framework**
   - Build validation middleware for Cloud Functions
   - Implement security rules enforcement

5. **Testing Infrastructure**
   - Set up integration test suite using Firestore emulator
   - Implement performance benchmarking

---

**Document Version:** 1.0  
**Last Updated:** 2024-01-XX  
**Status:** Ready for Implementation  
**Approval:** [Supervisor signature]
