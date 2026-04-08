# FASE PLAN: ETAPA A - FUNDACIÓN BACKEND Y CONVENCIONES COMPARTIDAS

**Fecha de Planificación**: 2026-04-07  
**Módulo**: Etapa A del IMPLEMENTATION_PLAN.md  
**Método**: Coordinación de 5 subagentes especializados  
**Resultado**: Plan de ejecución sin implementación de código  

---

## 1. ALCANCE DEL MÓDULO

### Definición

**Etapa A** establece la fundación técnica completa del backend CowBnB.  
No implementa lógica de negocio, sino la **arquitectura base, convenciones compartidas e estructuras de datos canónicas** que todas las etapas posteriores requieren.

### Línites de Alcance

#### ✅ INCLUYE:
- Estructura de carpetas backend (`functions/`, `shared/`, `models/`, `config/`, `tests/`)
- Inicialización Firebase Admin SDK  
- Convenciones de error, logging, requestId y idempotencia
- Modelos de datos canónicos (usuario, terreno, reserva, pago) con TypeScript interfaces
- Validadores de entrada para todos los campos
- Firestore rules skeleton (no implementadas, solo estructura)
- Índices Firestore Tier-1 definidos (6 críticos)
- Seed fixtures para emulador local
- Test setup (Jest + Firestore emulator)
- Documentación de arquitectura

#### ❌ EXCLUYE:
- Implementación de endpoints funcionales (AUTH-01, T-01, etc.)
- Lógica de negocio (flujos de reserva, pagos, NDVI)
- Integración con Bold, Copernicus, o proveedores externos
- Despliegue a Firebase Cloud (solo setup local)
- Interfaz frontend (solo backend)

### Objetivos Específicos

1. **Cumplir modelo de plataforma operativa**: No marketplace abierto
2. **Estructurar para escalabilidad**: Dominios separados, convenciones claras
3. **Garantizar seguridad desde base**: Reglas por rol, tokens hashed, secrets cifrados
4. **Habilitar testing automatizado**: Emulator setup + jsUnit + integration
5. **Trazabilidad operativa**: RequestId en todas las operaciones

---

## 2. DEPENDENCIAS PREVIAS

### 2.1 Requisitos de Entorno

| Requisito | Mínimo | Recomendado | Verificación |
|-----------|--------|-------------|--------------|
| Node.js | 18.x | 20.x LTS | `node --version` |
| npm | 9.x | 10.x | `npm --version` |
| Firebase CLI | 13.0 | 13.5+ | `firebase --version` |
| Dart/Flutter | 3.x | 3.24+ | `flutter --version` (para frontend) |
| Docker | No requerido | Recomendado | Para Firestore emulator |
| Git | 2.40+ | 2.45+ | `git --version` |

### 2.2 Artefactos Previos Requeridos

| Artefacto | Tipo | Estado Actual | Acción |
|-----------|------|---------------|--------|
| IMPLEMENTATION_PLAN.md | Documento | ✅ Existe | Fuente de verdad funcional |
| Estructura frontend Flutter | Código | ✅ Existe | 8 rutas + UI skeleton listos |
| Proyecto Firebase (Google Cloud) | Infraestructura | ❌ NO CREADO | **Crear antes de Etapa A** |
| Google Service Account JSON | Credencial | ❌ NO GENERADO | **Generar antes de setup** |

### 2.3 Decisiones Aprobadas Previamente

Estas decisiones **deben estar confirmadas** antes de iniciar implementación:

1. **Stack**: Firebase full-stack (Cloud Functions + Firestore + Storage + Auth)
2. **Lenguaje backend**: Node.js + TypeScript
3. **Validador**: Zod (o Joi si se prefiere)
4. **Logger**: Winston o Pino (structured JSON)
5. **Testing**: Jest + Firestore emulator
6. **Moneda de operación**: Definir por país (USD, CLP, etc.)
7. **Dueño técnico del repositorio**: ¿Quién tiene permisos de merging?

---

## 3. ARCHIVOS A CREAR / MODIFICAR

### 3.1 Archivos Nuevos a Crear

#### **Carpeta: `backend/functions/`** (punto entrada HTTP)

```
backend/functions/index.ts                    # CRÍTICO: Registro de todas las funciones HTTP
backend/functions/auth/index.ts               # Router auth
backend/functions/auth/register.ts            # Lógica registro (stub)
backend/functions/auth/login.ts               # Lógica login (stub)
backend/functions/auth/profile.ts             # Lógica perfil (stub)
backend/functions/terrenos/index.ts           # Router terrenos
backend/functions/terrenos/create.ts          # Lógica crear (stub)
backend/functions/terrenos/get.ts             # Lógica get (stub)
backend/functions/terrenos/list.ts            # Lógica listar (stub)
backend/functions/terrenos/update.ts          # Lógica actualizar (stub)
backend/functions/terrenos/state-transitions.ts  # Máquina de estados
backend/functions/health/index.ts             # Health check
backend/functions/webhooks/placeholder.ts     # Reserved para Bold/futuro
```

#### **Carpeta: `backend/shared/`** (utilidades compartidas)

```
backend/shared/auth.ts                        # CRÍTICO: Firebase Auth + claims
backend/shared/firestore.ts                   # CRÍTICO: Firestore Admin + CRUD
backend/shared/validation.ts                  # CRÍTICO: Schemas Zod
backend/shared/errors.ts                      # CRÍTICO: Unified errors
backend/shared/logging.ts                     # Logger con requestId
backend/shared/request-context.ts             # AsyncLocalStorage para requestId
backend/shared/idempotency.ts                 # Tracking idempotency (reservado)
backend/shared/types.ts                       # TypeScript interfaces
backend/shared/constants.ts                   # Enums y constantes
```

#### **Carpeta: `backend/models/`** (esquemas de datos)

```
backend/models/usuario.model.ts               # User schema + validation
backend/models/terreno.model.ts               # Terreno schema + state machine
backend/models/reserva.model.ts               # Reserva schema (stub)
backend/models/pago.model.ts                  # Pago schema (stub)
```

#### **Carpeta: `backend/config/`** (configuración)

```
backend/config/firebase.config.ts             # CRÍTICO: Admin SDK init
backend/config/environment.ts                 # Env var validation
backend/config/constants.config.ts            # Domain constants
```

#### **Carpeta: `backend/tests/`** (testing)

```
backend/tests/unit/validation.test.ts         # Tests unitarios validadores
backend/tests/unit/models.test.ts             # Tests modelos
backend/tests/unit/errors.test.ts             # Tests error handling
backend/tests/integration/auth.test.ts        # Tests integración auth
backend/tests/integration/terrenos.test.ts    # Tests integración terrenos
backend/tests/integration/firestore-emulator.setup.ts  # Emulator config
backend/tests/fixtures/mock-users.ts          # Seed data usuarios
backend/tests/fixtures/mock-terrenos.ts       # Seed data terrenos
backend/tests/fixtures/firebase-emulator.ts   # Emulator helper
```

#### **Configuración y Documentación**

```
backend/.env.example                          # Template variables de entorno
backend/.env.local                            # Dev local (git-ignored)
backend/.gitignore                            # Ignorar node_modules, .env.local, etc.
backend/firebase.json                         # CRÍTICO: CLI config + emulator
backend/firestore.rules                       # Skeleton de reglas (no implementado)
backend/firestore.indexes.json                # Skeleton de índices
backend/package.json                          # CRÍTICO: npm dependencies + scripts
backend/tsconfig.json                         # TypeScript config
backend/jest.config.js                        # Jest test config
backend/README.md                             # Setup + architecture doc
```

### 3.2 Archivos a Modificar

| Archivo | Motivo | Cambios |
|---------|--------|---------|
| `frontend/pubspec.yaml` | Agregar Firebase SDK | Agregar: `firebase_auth: >=X.X.0`, `cloud_firestore: >=X.X.0`, `firebase_storage: >=X.X.0` |
| `frontend/lib/main.dart` | Inicializar Firebase | Llamar `Firebase.initializeApp()` en platform-specific setup |
| `.gitignore` (root) | Ignora backend secretos | Agregar `backend/.env.local`, `backend/node_modules`, `backend/dist/` |
| `package.json` (root) | Workspace setup | Opcional: Agregar workspace script para monorepo |

---

## 4. CONTRATOS DE ENTRADA / SALIDA

### 4.1 Contrato de Entrada: Estado del Repositorio

**Input**: Resultado del descubrimiento (Discovery Agent)

```json
{
  "backend_status": "NO_ENCONTRADO",
  "frontend_status": "UI_SKELETON",
  "firebase_status": "NOT_INITIALIZED",
  "key_assumptions": [
    "Backend creado desde cero",
    "No migraciones de datos legacy",
    "Firebase project debe crearse aparte"
  ]
}
```

### 4.2 Contrato de Salida: Estructura Backend Funcional

**Output esperado al completar Etapa A**:

```bash
backend/
├── functions/            # ✅ 4 dominios + health + placeholders
├── shared/              # ✅ 9 utilidades compartidas
├── models/              # ✅ 4 esquemas tipados (2 stub)
├── config/              # ✅ Firebase init + env validation
├── tests/               # ✅ Unit + integration + fixtures
├── package.json         # ✅ Deps instalados y scripts npm
├── firebase.json        # ✅ Emulator config
├── firestore.rules      # ✅ Skeleton (no lógica)
├── firestore.indexes.json  # ✅ Tier-1 indexes (no deployed)
└── README.md            # ✅ Setup guide + architecture

firebase emulators:start  # ✅ Arranca sin errores
npm test                  # ✅ Todos los tests pasan (unit + integration)
```

### 4.3 Interfaces/Modelos de Salida (TypeScript)

#### Usuario

```typescript
interface Usuario {
  uid: string;                 // Firebase auth.uid (PK)
  fullName: string;           // Nombre completo
  email: string;              // Email único
  role: 'owner' | 'renter';   // Rol asignado y inmutable
  phonePrefix: string;        // Ej: "+56", "+1"
  phone: string;              // Número sin prefijo
  status: 'active' | 'inactive' | 'suspended'; // Estado
  profilePicture?: string;    // URL en Storage (opcional)
  createdAt: number;          // Timestamp
  updatedAt: number;          // Timestamp
  customClaims: {
    role: string;             // Para Firebase Auth
    verified: boolean;        // Email verificado
  };
}
```

#### Terreno

```typescript
interface Terreno {
  id: string;                                   // Firestore doc ID
  ownerId: string;                              // FK a usuarios (inmutable)
  title: string;                                // Título anuncio
  description: string;                          // Descripción
  sizeHectares: number;                         // Hectáreas (> 0)
  pricePerMonth: number;                        // Precio mensual (> 0, inmutable en reserva)
  location: {
    latitude: number;                           // Geolocalización
    longitude: number;
    address: string;            // Dirección legible
    geohash: string;            // 6-char para queries geográficas
    regionCode: string;         // "RM", "Valparaíso", etc.
  };
  features: string[];           // ["riego", "energía", "caminos", "certificación"]
  images: Array<{               // Hasta 10 imágenes
    id: string;
    url: string;                // Storage URL
    priority: number;           // 0-9, menor = portada
  }>;
  status: 'disponible' | 'reservado' | 'en_espera' | 'inactivo';
  ratingAvg?: number;           // Agregado (0-5, 1 decimal)
  ratingCount?: number;         // Cantidad reviews
  createdAt: number;            // Timestamp
  updatedAt: number;            // Timestamp
  lastStatusChangeAt?: number;  // Para auditoria
}
```

#### Reserva

```typescript
interface Reserva {
  id: string;                           // Firestore doc ID
  terrenoId: string;                    // FK a terrenos
  ownerId: string;                      // FK a usuarios (owner del terreno, desnormalizado)
  renterId: string;                     // FK a usuarios (renter)
  startDate: string;                    // ISO 8601 (YYYY-MM-DD)
  endDate: string;                      // ISO 8601 (YYYY-MM-DD)
  monthlyPrice: number;                 // Snapshot del precio (inmutable)
  status: 'en_espera' | 'reservado' | 'en_curso' | 'completada' | 'cancelada';
  paymentStatus: 'pending' | 'approved' | 'failed' | 'refunded';
  expiresAt: number;                    // TTL para en_espera (24h)
  reasonIfCanceled?: string;
  createdAt: number;
  updatedAt: number;
}
```

#### Pago (evento)

```typescript
interface PaymentEvent {
  id: string;                           // Firestore doc ID
  reservaId: string;                    // FK a reservas
  externalReference: string;            // Bold checkout ID (unique)
  amount: number;                       // Monto en centavos (para precisión)
  currency: string;                     // "CLP", "USD", etc.
  status: 'pending' | 'approved' | 'failed' | 'refunded';
  boldWebhookTimestamp?: number;        // Cuando Bold notificó
  boldSignature?: string;               // HMAC verificada (hashed)
  createdAt: number;
  updatedAt: number;
}
```

### 4.4 Contratos de Función (Ejemplos de Stub)

#### Ejemplo: `backend/functions/auth/register.ts`

```typescript
/**
 * @function register
 * @type HTTP Cloud Function
 * @route POST /auth/register
 * 
 * Input Contract:
 * {
 *   "fullName": string (1-100 chars, no special chars except spaces)
 *   "email": string (valid email format, must not exist in users collection)
 *   "password": string (min 8 chars, 1 uppercase, 1 number, 1 special char)
 *   "phonePrefix": string (starts with +, 1-3 digits)
 *   "phone": string (numeric, 7-15 digits)
 *   "role": "owner" | "renter"
 * }
 * 
 * Output Success (201 Created):
 * {
 *   "requestId": string (uuid),
 *   "uid": string (Firebase auth.uid),
 *   "usuario": Usuario,
 *   "token": string (JWT idToken)
 * }
 * 
 * Output Error (400/409):
 * {
 *   "requestId": string,
 *   "code": "VALIDATION_FAILED" | "EMAIL_EXISTS",
 *   "message": string,
 *   "timestamp": ISO8601,
 *   "details": { fieldErrors: {...} }
 * }
 */
export async function register(req: Request, res: Response) {
  // STUB - no implementar en Etapa A
  return res.status(501).json({
    requestId: getRequestId(),
    code: 'NOT_IMPLEMENTED',
    message: 'Etapa B: AUTH-01'
  });
}
```

---

## 5. RIESGOS Y MITIGACIONES

### 5.1 Riesgos Identificados

| Risk ID | Descripción | Probabilidad | Impacto | Severidad | Mitigación | Responsable |
|---------|-------------|--------------|---------|-----------|-----------|-------------|
| **R1** | Setup Firebase incompleto causa errores de auth | Media | Alto | 🔴 **ALTA** | Checklist Firebase pre-requisites; audit firebase.json antes de deploy | Tech Lead |
| **R2** | Modelos de datos inconsistentes entre backend/frontend | Media | Alto | 🔴 **ALTA** | Single source of truth: interfaces TypeScript en `backend/models/`; generar automaticamente para Dart via tooling | Data Architect |
| **R3** | Validación inconsistente permite datos inválidos | Baja | Medio | 🟡 **MEDIA** | Zod schemas centralizados en `backend/shared/validation.ts`; tests unitarios 100% coverage | QA |
| **R4** | RequestId no propagado causa imposibilidad de debugging | Baja | Alto | 🟡 **MEDIA** | AsyncLocalStorage en middleware; tests verifican requestId en logs | DevOps |
| **R5** | Tokens secretos (Firebase keys, webhook secrets) en git | Alta | Crítico | 🔴 **MÁS ALTO** | .env.local git-ignored; Firebase Secret Manager en prod; código no hardcodea secrets | Security |
| **R6** | Firestore rules insuficientes permite bypass de seguridad | Media | Crítico | 🔴 **MÁXIMO** | Default-deny rules; tests contra emulator verifican role-based access; code review antes de deploy | Security |
| **R7** | Emulator local no sincroniza con Firestore prod (confusión) | Baja | Medio | 🟡 **MEDIA** | Documentar en README diferencias dev/prod; usar --only argument en emulator start; ambiente CI separado | QA |
| **R8** | Índices Firestore no creados causa queries lentas en Etapa B | Baja | Medio | 🟡 **MEDIA** | Definir índices Tier-1 ahora en `firestore.indexes.json`; deploy en staging antes de prod | Data Architect |

### 5.2 Decisiones Arquitectónicas Mitigando Riesgos

| Riesgo | Decisión Arquitectónica | Por Qué |
|--------|------------------------|--------|
| R2, R6 | TypeScript interfaces tipadas | Evita ambigüedad modelo unificado |
| R3 | Zod schemas centralizados | Validación única fuente verdad |
| R5 | .env.local + Firebase Secret Manager | Separación clear dev/prod |
| R6 | Default-deny Firestore rules | Seguridad "fail closed" |
| R7 | Emulator flags explícitos | Prev confusión dev/prod |

---

## 6. CRITERIOS DE DONE

Tomado y convertido a **criterios testables** del IMPLEMENTATION_PLAN.md sección 6 (Etapa A).

### CRITERIO 1: Servicios Arrancan Localmente Sin Errores

**Original**: "Servicios arrancan en entorno local."

**Testeable**:
```bash
# Precondition: Node 20.x, npm 10.x, Firebase CLI 13.5, .env.local presente
firebase emulators:start --only firestore,auth --project test 2>&1 | tee emulator.log
# ✅ PASS: Mensaje "All emulators started successfully" en log
# ✅ PASS: Firestore emulator listening on localhost:8080
# ✅ PASS: Auth emulator listening on localhost:9099

npm run start:local 2>&1 | grep -E "Functions listening|listening on port"
# ✅ PASS: Cloud Functions running locally on port 5001
```

### CRITERIO 2: Estructura Base Aprobada por Supervisor

**Original**: "Estructura base aprobada por supervisor."

**Testeable**:
```bash
# Archivo check
ls -la backend/{functions,shared,models,config,tests}/*.ts | wc -l
# ✅ PASS: >= 30 archivos TypeScript

# Specific files mandatory
for f in backend/{functions/index,shared/{auth,firestore,validation,errors}}.ts; do
  test -f "$f" || { echo "FAIL: $f missing"; exit 1; }
done
# ✅ PASS: Todos los archivos críticos existen

# README verificación
grep -q "Arquitectura" backend/README.md && grep -q "Setup" backend/README.md
# ✅ PASS: README tiene secciones Arquitectura + Setup
```

### CRITERIO 3: Contratos Documentados en Cada Dominio

**Original**: "Documentados contratos mínimos de cada dominio."

**Testeable**:
```typescript
// Verificar JSDoc en archivos de entrada HTTP
grep -l "/**" backend/functions/{auth,terrenos,health}/index.ts
# ✅ PASS: >= 3 archivos tienen JSDoc

// Verificar TypeScript interfaces
grep -c "^interface\|^type" backend/shared/types.ts
# ✅ PASS: >= 10 interfaces/types definidas

// Verificar error codes documentados
grep -c "enum ErrorCode" backend/shared/errors.ts
# ✅ PASS: Enum ErrorCode con >= 6 estados
```

### CRITERIO 4: Validación Centralizada Funcional

**Original**: No explícitamente en 6.0A, derivado de requisitos comunes.

**Testeable**:
```bash
npm test -- backend/tests/unit/validation.test.ts --coverage
# ✅ PASS: >= 70% coverage en validation.ts
# ✅ PASS: Todos los tests "PASS" (0 FAIL)

# Específicamente: validar usuario, terreno, reserva
npm test -- --testNamePattern="usuario|terreno|reserva"
# ✅ PASS: Tests para 3+ dominios
```

### CRITERIO 5: RequestId Propagación Completa

**Original**: No explícito, requerido por observabilidad (sección 9).

**Testeable**:
```bash
npm test -- backend/tests/integration/ --testNamePattern="requestId"
# ✅ PASS: RequestId presente en req.headers.x-request-id
# ✅ PASS: RequestId presente en response headers
# ✅ PASS: RequestId presente en structured logs

# Verificar 20+ ejecuciones tienen requestId único
npm test -- backend/tests/integration/ 2>&1 | grep "requestId:" | sort -u | wc -l
# ✅ PASS: >= 20 requestIds únicos detectados
```

### CRITERIO 6: Reglas Firestore por Rol Bloquean Acceso No Autorizado

**Original**: Reglas de seguridad definidas (sección 8).

**Testeable**:
```bash
# Usar firebase emulator + test suite
npm test -- backend/tests/integration/firestore-emulator.setup.ts

# Verificar 3 casos por rol
# Case 1: Renter intenta crear terreno → BLOCKED
# Case 2: Owner intenta leer reserva de otro owner → BLOCKED
# Case 3: Unauthenticated intenta escribir → BLOCKED
# Case 4: Owner puede leer propios terrenos → ALLOWED

# ✅ PASS: 3 casos bloqueados + 1 caso permitido
```

### CRITERIO 7: Índices Firestore Tier-1 Definidos

**Original**: "Índices compuestos documentados."

**Testeable**:
```bash
cat backend/firestore.indexes.json | jq '.indexes | length'
# ✅ PASS: >= 6 índices definidos (Tier-1 críticos)

# Verificar estructura
cat backend/firestore.indexes.json | jq '.indexes[0] | keys'
# ✅ PASS: Campos presentes: "collectionGroup", "fields", "queryScope"

# Documentar en README cuál índice para cuál query
grep -A20 "## Índices" backend/README.md | grep -E "ownerId ASC|status ASC"
# ✅ PASS: Documentación de qué query cada índice soporta
```

### CRITERIO 8: Testing Setup (Unit + Integration) Funcional

**Original**: No explícito, requerido por observabilidad/QA.

**Testeable**:
```bash
npm test -- --listTests | wc -l
# ✅ PASS: >= 10 archivos de test

npm test -- --coverage --collectCoverageFrom="backend/shared/**/*.ts"
# ✅ PASS: >= 70% coverage global
# ✅ PASS: Todos los tests PASS (0 FAIL)

npm run test:integration 2>&1 | tail -10
# ✅ PASS: "PASS" y "Tests: X passed, X total"
```

---

## 7. CHECKLIST DE SUPERVISIÓN

Use este checklist para aceptar/rechazar la entrega de Etapa A. Cada item es verificable automáticamente o manualmente.

### 7.1 Estructura y Archivos (Verificable Automáticamente)

- [ ] **DIR-001**: Carpeta `backend/` creada en raíz del repositorio
- [ ] **DIR-002**: 5 subcarpetas presentes: `functions/`, `shared/`, `models/`, `config/`, `tests/`
- [ ] **FIL-001**: `backend/functions/index.ts` existe y exporta función (no stub)
- [ ] **FIL-002**: `backend/shared/{auth,firestore,validation,errors}.ts` existen (4+ archivos críticos)
- [ ] **FIL-003**: `backend/models/{usuario,terreno}.model.ts` existen con interfaces TypeScript
- [ ] **FIL-004**: `backend/package.json` define scripts: `start:local`, `test`, `build`
- [ ] **FIL-005**: `backend/firebase.json` configura emulator flags
- [ ] **FIL-006**: `.gitignore` ignora `backend/.env.local`, `backend/node_modules/`

### 7.2 Dependencies y Setup (Verificable)

- [ ] **DEP-001**: `npm install` en `backend/` completa sin errores
- [ ] **DEP-002**: `firebase emulators:start` inicia sin errores (min 10 segundos)
- [ ] **DEP-003**: TypeScript compila sin errores: `npx tsc --noEmit`
- [ ] **DEP-004**: Firebase Admin SDK v12+ instalado

### 7.3 Modelos de Datos (Verificable)

- [ ] **DAT-001**: 4 interfaces TypeScript tipadas (Usuario, Terreno, Reserva, Pago)
- [ ] **DAT-002**: Enums para status: `terreno.status`, `reserva.status`, `usuario.role`
- [ ] **DAT-003**: Cada modelo tiene campos `createdAt`, `updatedAt` (timestamp)
- [ ] **DAT-004**: Modelos reflejan requirements del IMPLEMENTATION_PLAN.md sección 5
- [ ] **DAT-005**: `Usuario.role` es inmutable post-creación (anotado en interface)
- [ ] **DAT-006**: `Terreno.pricePerMonth` es inmutable en reserva (documentado)

### 7.4 Convenciones y Patterns (Verificable + Manual)

- [ ] **CONV-001**: Error handling: `AppError` con `code` + `statusCode` + `details`
- [ ] **CONV-002**: RequestId injection: middleware presente, propagado a logs y responses
- [ ] **CONV-003**: Logging: formato JSON estructurado con `{timestamp, requestId, level, service, message}`
- [ ] **CONV-004**: Validación: Zod schemas en `backend/shared/validation.ts`
- [ ] **CONV-005**: Constantes: Enums en `backend/shared/constants.ts`
- [ ] **CONV-006**: NO hay strings mágicos en código funcional (todo en constantes)

### 7.5 Seguridad (Verificable + Manual)

- [ ] **SEC-001**: `firestore.rules` existe con skeleton (default-deny presente)
- [ ] **SEC-002**: Reglas por colección: `users`, `terrenos`, `reservas` especificadas (aunque no implementadas)
- [ ] **SEC-003**: Secrets NO en código: Firebase keys en `firebase.json` o variable de entorno
- [ ] **SEC-004**: `.env.example` documenta todas las variables requeridas
- [ ] **SEC-005**: Token hashing pattern documentado en `backend/shared/idempotency.ts`
- [ ] **SEC-006**: Webhook signature verification stub presente (para Etapa C)

### 7.6 Testing (Verificable Automáticamente)

- [ ] **TEST-001**: Jest config presente: `jest.config.js`
- [ ] **TEST-002**: Unit tests para validadores: `backend/tests/unit/validation.test.ts`
- [ ] **TEST-003**: Unit tests para modelos: `backend/tests/unit/models.test.ts`
- [ ] **TEST-004**: Integration tests setup: `backend/tests/integration/firestore-emulator.setup.ts`
- [ ] **TEST-005**: Fixtures seed data: `backend/tests/fixtures/{mock-users,mock-terrenos}.ts`
- [ ] **TEST-006**: Comando `npm test` ejecuta todos exitosamente
- [ ] **TEST-007**: Coverage >= 70% en `backend/shared/`
- [ ] **TEST-008**: Tests validan role-based access (renter vs owner)

### 7.7 Índices y Queries (Verificable)

- [ ] **IDX-001**: `firestore.indexes.json` define 6 índices Tier-1 (mínimo)
- [ ] **IDX-002**: Cada índice tiene al menos 2 campos compuestos
- [ ] **IDX-003**: Documentación en `backend/README.md` mapea cada índice a query esperada

### 7.8 Documentación (Verificable)

- [ ] **DOC-001**: `backend/README.md` existe y documenta:
  - [ ] Setup local (Firebase emulator + npm install)
  - [ ] Estructura de directorios
  - [ ] Convenciones (error codes, logging)
  - [ ] Cómo correr tests
- [ ] **DOC-002**: Cada archivo crítico tiene comentario de propósito en encabezado
- [ ] **DOC-003**: Funciones HTTP tienen JSDoc con Input/Output contracts
- [ ] **DOC-004**: README lista dependencias Node/Firebase mínimas

### 7.9 Modelo de Negocio (Manual - Supervisor)

- [ ] **BIZ-001**: Revisándose: Plataforma de arriendo operativa (no marketplace abierto)
- [ ] **BIZ-002**: Estados canónicos reflejan modelo: `disponible`, `reservado`, `en_espera`, `inactivo`
- [ ] **BIZ-003**: Operaciones críticas (cambio estado, pagos) serán backend-only (documentado)
- [ ] **BIZ-002**: No hay operaciones directas desde cliente en fundación

---

## 8. HALLAZGOS POR SUBAGENTE Y CONSOLIDACIÓN

### 8.1 Reporte Discovery Agent

**Responsabilidad**: Explorar estado actual del repositorio.

**Hallazgos Clave**:

| Item | Estado | Implicación |
|------|--------|------------|
| `backend/` | NO ENCONTRADO | Crear desde cero; zero tech debt |
| `firebase.json` | NO ENCONTRADO | Crear config Firebase Cloud |
| `pubspec.yaml` | NO ENCONTRADO (pero `pubspec.lock` existe) | Agregar Firebase SDK deps |
| 8 rutas frontend | ✅ ENCONTRADO | Excelente base para mocking inicialmente |
| HTTP client | NO ENCONTRADO | Frontend requiere servicios backend primero |
| State management | NO ENCONTRADO | No bloqueante para Etapa A (backend) |

**Conclusión**: Frontend skeleton UI listo, backend ausente completamente. Esto es **ventaja**: cero legacy to migrate.

---

### 8.2 Reporte Architecture Agent

**Responsabilidad**: Diseñar estructura backend y convenciones.

**Hallazgos Clave**:

1. **Estructura propuesta**:
   - 4 dominios HTTP (`auth/`, `terrenos/`, `health/`, `webhooks/`)
   - 9 módulos shared (`auth.ts`, `firestore.ts`, `validation.ts`, etc.)
   - 4 modelos (`usuario`, `terreno`, `reserva`, `pago`)
   - Tests organizados por tipo (unit/integration)

2. **Patrones Recomendados**:
   - **Router pattern**: Express.js con función por endpoint
   - **Error handling**: AppError clase unificada
   - **Logging**: JSON estructurado con requestId
   - **Validación**: Zod schemas centralizados

3. **Decisiones Técnicas**:
   - Node.js 20 LTS (soporte 12 años)
   - TypeScript para type safety
   - Jest para testing (familiar, fast)
   - Firestore emulator para dev (sin infraestructura)

**Consolidación**: Arquitectura aligns con Firebase best practices. Escalable a múltiples dominios.

---

### 8.3 Reporte Security Agent

**Responsabilidad**: Planificar seguridad y convenciones.

**Hallazgos Clave**:

1. **Firestore Rules**:
   - Default-deny base
   - 6 colecciones con rules skeleton
   - Role-based access matrix (owner/renter/public)

2. **Authentication**:
   - Firebase Auth token verification en middleware
   - Custom claims para role inmutable

3. **Secrets Management**:
   - .env.local para dev (git-ignored)
   - Firebase Secret Manager para prod
   - No hardcoding de API keys

4. **Idempotency**:
   - XXX format: `OPERATION-TIMESTAMP-RANDOM`
   - SHA-256 hashing para one-time tokens
   - 24h TTL para deduplication

5. **Risk Mitigation**:
   - Authorization bypass: redundant (rules + backend)
   - Token leakage: hashing + no logs
   - Webhook security: HMAC-SHA256 verification

**Consolidación**: Security-first mindset from foundation. 7 decision points await supervisor approval (cf. section 5).

---

### 8.4 Reporte Data Agent

**Responsibilidad**: Diseñar modelos y estructura Firestore.

**Hallazgos Clave**:

1. **Collections** (7 root + 1 subcollection):
   - `users/` — 16 fields, UID as doc ID
   - `terrenos/` — 30 fields, auto-generated ID
   - `reservas/` — 18 fields, status machine
   - `conversaciones/` with `→ mensajes/`
   - `payment_events/`, `reviews/`, `ndvi_checks/$, action_tokens/`

2. **Status Enums** (canonical):
   - Terreno: `disponible` → `reservado` → `en_espera` → `inactivo`
   - Reserva: `en_espera` → `reservado` → `en_curso` → `completada` | `cancelada`
   - Usuario: `active` | `inactive` | `suspended`

3. **Indexes** (Tier-1 critical for Etapa A):
   - 6 mandatory indexes unlock core queries (owner dashboard, price filter)
   - 9 additional for Etapa B+ (payment events, reviews)

4. **Validation**:
   - 30+ business logic rules per entity
   - State machines prevent invalid transitions
   - Role-based field access

5. **Performance Targets**:
   - Query P50: <100ms
   - Query P99: <500ms

**Consolidación**: Data model comprehensive and production-ready. Matches IMPLEMENTATION_PLAN requirements exactly.

---

### 8.5 Reporte QA Agent

**Responsabilidad**: Definir criterios de aceptación y testing estrategia.

**Hallazgos Clave**:

1. **Unit Testing**:
   - Jest config, 70%+ coverage threshold
   - Tests for validation, models, error handling
   - File structure: `featureName.test.js` colocalized with source

2. **Integration Testing**:
   - Firestore emulator (`--only firestore` mode)
   - Auth emulator for test users
   - Webhook idempotency tests

3. **Manual QA**:
   - 8-step checklist for verification
   - RequestId traceability in logs
   - Role-based access rejection tests

4. **Observability**:
   - JSON logs mandatory (not plain text)
   - Error codes categorized (`INVALID_*`, `AUTH_*`, etc.)
   - Extraction pattern: jq by requestId

5. **Done Criteria** (8 testeable from original 6.0A):
   - Services start locally
   - Structure approved
   - Contracts documented
   - Validation centralized
   - RequestId propagated
   - Firestore rules by role
   - Indexes defined
   - Tests pass

**Consolidación**: QA-first thinking. All acceptance criteria are mechanically testable, not subjective.

---

### 8.6 Consolidación Final

#### ✅ Consenso Entre Subagentes

All 5 subagents align on:
1. **Firebase full-stack** is correct choice (Cloud Functions + Firestore)
2. **TypeScript + Zod** for type safety and validation
3. **Default-deny security** rules from day 1
4. **RequestId propagation** for all operations
5. **Firestore emulator** for local dev
6. **Jest + integration tests** for Etapa A validation

#### ⚠️ Decisiones Pendientes (Sin Conflicto)

| Decisión | Opciones | Impacto |
|----------|----------|--------|
| Email provider | SendGrid vs Firebase Extension | Etapa D (Mensajería) |
| Geocoding | Google Maps API vs Mapbox | Etapa B (Búsqueda) |
| NDVI threshold | Configurable por tipo terreno | Etapa E (NDVI) |
| Idempotency window | 24h vs 48h | Etapa C (Pagos) |

#### 🔴 Riesgos Críticos Requerir Mitigación Inmediata

1. **R5 - Token leakage**: Secrets must NEVER be in `git`
2. **R6 - Security bypass**: Firestore rules must default-deny
3. **R1 - Firebase setup**: Project must exist BEFORE implementation starts

---

## 9. PRÓXIMOS PASOS

### Fase 1: Supervisión (Esta sesión)

- ✅ Planificación completada con 5 subagentes
- ✅ Hallazgos consolidados en este documento
- ⏳ **Supervisor review** (2-3 días esperados)
  - Validar decisiones arquitectónicas
  - Confirmar o no decisiones pendientes (sección 8.6)
  - Aprobar o rechazar riesgos mitigaciones

### Fase 2: Implementación (Próxima sesión)

Una vez aprobada por supervisor:

1. **Setup Firebase** (1 día):
   - Crear Google Cloud project
   - Generar service account JSON
   - Test de credenciales

2. **Crear estructura backend** (2 días):
   - `npm init` + `firebase init functions`
   - Scaffolding carpetas + archivos stub
   - npm install dependencies

3. **Implementar convenciones shared** (3 días):
   - Error handling (`backend/shared/errors.ts`)
   - Logging + requestId (`backend/shared/logging.ts`, `request-context.ts`)
   - Validation schemas (`backend/shared/validation.ts`)

4. **Implementar modelos canónicos** (2 días):
   - TypeScript interfaces (`backend/models/`)
   - Firestore schemas
   - Seed fixtures

5. **Setup testing** (2 días):
   - Jest configuration
   - Firestore emulator integration
   - Mock data fixtures

6. **Crear documentación** (1 día):
   - `backend/README.md` completo
   - JSDoc en funciones HTTP
   - Contracts mapping

7. **Validar Criteria de Done** (1 día):
   - Ejecutar 8 test commands (sección 6)
   - Supervisorir checklist 7.1-7.9
   - Fix cualquier falla

**Timeline esperado**: 12-14 días de trabajo para un implementador full-time.

---

## 10. REFERENCIAS

- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) — Fuente de verdad funcional
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices) — Google docs
- [Cloud Functions Node.js Guide](https://firebase.google.com/docs/functions/get-started/deploy-functions) — Firebase
- [Zod Documentation](https://zod.dev/) — Validation library
- [Jest Documentation](https://jestjs.io/) — Testing framework
- [TypeScript Handbook](https://www.typescriptlang.org/docs/) — Language reference

---

## 11. FIRMAS Y APROBACIONES

### Documento Generado Por

- **Método**: 5 subagentes especializados (Discovery, Architecture, Security, Data, QA)
- **Fecha**: 2026-04-07
- **Fuente**: IMPLEMENTATION_PLAN.md secciones 3, 5, 6, 8, 9, 11

### Pendiente: Aprobación del Supervisor

```
☐ Supervisor Técnico: ________________  Fecha: ______
   Comentarios: ________________________________

☐ Product Owner: ________________  Fecha: ______
   Comentarios: ________________________________

☐ Lead Implementador: ________________  Fecha: ______
   Comentarios: ________________________________
```

---

**Fin de ETAPA_A_PLAN.md**
