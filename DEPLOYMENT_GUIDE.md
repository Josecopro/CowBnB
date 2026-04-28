# 🚀 GUÍA DE DEPLOYMENT Y CONFIGURACIÓN - CowBnB

**Última actualización:** 28 de Abril, 2026  
**Audiencia:** DevOps, Backend Engineers, QA

---

## 📋 TABLA DE CONTENIDOS

1. [Requisitos Previos](#requisitos-previos)
2. [Setup Local](#setup-local)
3. [Configuración Firebase](#configuración-firebase)
4. [Deployment Backend](#deployment-backend)
5. [Deployment Frontend](#deployment-frontend)
6. [Validación E2E](#validación-e2e)
7. [Troubleshooting](#troubleshooting)

---

## 📦 REQUISITOS PREVIOS

### Sistema
- Node.js 18+ (LTS recomendado)
- Flutter 3.10+ (o Android/iOS SDK)
- Firebase CLI 13+
- Git

### Cuentas
- Google Firebase Project (gratuito o pagado)
- GitHub (para CI/CD futuro)
- Bold (para pagos) - opcional para MVP

### Credenciales
- Firebase Service Account JSON
- Google Cloud Project ID
- API Keys para plataformas

---

## 🔧 SETUP LOCAL

### 1. Clonar & Preparar

```bash
# Clone repo
git clone <repo-url>
cd cowbnb

# Setup Node.js
node --version  # Debe ser 18+

# Setup Flutter
flutter doctor  # Verificar setup completo
```

### 2. Backend Setup

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Login a Firebase
firebase login

# Instalar dependencias backend
cd backend/functions
npm install

# Volver a root
cd ../..

# Seleccionar proyecto Firebase
firebase use <PROJECT_ID>
```

### 3. Configurar Ambiente Backend

**Crear `backend/.env.local` (NO commitar a git):**
```env
# Firebase
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account",...}  # JSON de SA

# App Config
NODE_ENV=development
PORT=5001
LOG_LEVEL=debug

# Servicios Externos (Etapa B+)
BOLD_API_KEY=your-bold-api-key
BOLD_WEBHOOK_SECRET=your-webhook-secret
COPERNICUS_USERNAME=your-copernicus-user
COPERNICUS_PASSWORD=your-copernicus-pass
```

**Obtener Service Account:**
1. Ir a Firebase Console → Project Settings
2. Service Accounts → Generate New Private Key
3. Guardar JSON en archivo local
4. Copiar contenido a `.env.local`

### 4. Frontend Setup

```bash
# Navegar a frontend
cd frontend

# Instalar dependencias Flutter
flutter pub get

# Generar riverpod code (si usas)
flutter pub run build_runner build

# Volver a root
cd ..
```

### 5. Configurar Opciones Firebase (Frontend)

**Editar `frontend/lib/services/firebase_options.dart`:**

1. Ir a Firebase Console → Project Settings
2. Copy los valores por plataforma:

```dart
// Web
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxx',
  appId: '1:123456789:web:abcdef123456',
  messagingSenderId: '123456789',
  projectId: 'cowbnb-prod',  // ← TU PROJECT ID
  authDomain: 'cowbnb-prod.firebaseapp.com',
  databaseURL: 'https://cowbnb-prod.firebaseio.com',
  storageBucket: 'cowbnb-prod.appspot.com',
  measurementId: 'G-XXXXXXXXXXXX',
);

// Android (si deployas a Android)
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxx',
  appId: '1:123456789:android:xxxxx',
  messagingSenderId: '123456789',
  projectId: 'cowbnb-prod',
  databaseURL: 'https://cowbnb-prod.firebaseio.com',
  storageBucket: 'cowbnb-prod.appspot.com',
);

// iOS (si deployas a iOS)
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxx',
  appId: '1:123456789:ios:xxxxx',
  messagingSenderId: '123456789',
  projectId: 'cowbnb-prod',
  databaseURL: 'https://cowbnb-prod.firebaseio.com',
  storageBucket: 'cowbnb-prod.appspot.com',
  iosBundleId: 'com.example.cowbnb',
);
```

---

## 🔐 CONFIGURACIÓN FIREBASE

### 1. Crear Proyecto

```bash
# En Firebase Console o via CLI:
firebase projects:create cowbnb-prod

# O usar proyecto existente
firebase use cowbnb-prod
```

### 2. Habilitar Servicios

**En Firebase Console:**
- [ ] Authentication → Email/Password
- [ ] Firestore Database → Create collection
- [ ] Cloud Storage
- [ ] Cloud Messaging (para push notifs)
- [ ] Cloud Functions

### 3. Deploy Firestore Rules & Indexes

```bash
# Desde root del proyecto

# Deploy reglas de seguridad
firebase deploy --only firestore:rules

# Esperará confirmación de colecciones faltantes
# Crear las colecciones base:
- users
- terrenos
- reservas
- conversaciones
- reviews
- favorites

# Deploy índices compuestos
firebase deploy --only firestore:indexes

# Esto puede tomar 5-10 minutos
```

### 4. Inicializar Firestore Data

```bash
# Crear colecciones base (via Firebase Console o script)
# O ejecutar seed script (crear luego):
node backend/scripts/seed-firestore.js
```

### 5. Configurar CORS (Backend)

**En `backend/functions/index.ts`:**
```typescript
import cors from 'cors';

// Whitelist de dominios permitidos
const corsOptions = {
  origin: [
    'http://localhost:5000',        // Local dev
    'https://yourdomain.com',        // Production domain
    'https://app.yourdomain.com',   // App domain
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
};

// Aplicar a todas las rutas
app.use(cors(corsOptions));
```

---

## 🚀 DEPLOYMENT BACKEND

### Opción 1: Deploy a Firebase Functions (Recomendado)

```bash
# Desde root del proyecto

# Build TypeScript
cd backend/functions
npm run build
cd ../..

# Deploy funciones
firebase deploy --only functions:api

# Output mostrará URL de función:
# ✔ functions[api]: http trigger deployed at 
#   https://us-central1-cowbnb-prod.cloudfunctions.net/api

# Actualizar frontend con nueva URL
# En firebase_service.dart o .env si aplica
```

### Opción 2: Deploy a Cloud Run (Para escala mayor)

```bash
# Crear Dockerfile
# Build imagen
docker build -t gcr.io/cowbnb-prod/api:latest .

# Push a Container Registry
docker push gcr.io/cowbnb-prod/api:latest

# Deploy a Cloud Run
gcloud run deploy api \
  --image gcr.io/cowbnb-prod/api:latest \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated
```

### Post-Deploy

```bash
# Verificar funciones
firebase functions:list

# Ver logs
firebase functions:log

# O en Cloud Console:
# Functions → Logs
```

---

## 📱 DEPLOYMENT FRONTEND

### Para Web

```bash
# Test local
cd frontend
flutter run -d web

# Build production
flutter build web --release

# Deploy a Firebase Hosting
firebase deploy --only hosting:frontend
```

### Para Android

```bash
# Build APK
flutter build apk --release

# O build en Android Studio
# Luego upload a Google Play Store
```

### Para iOS

```bash
# Build IPA
flutter build ios --release

# Luego upload a TestFlight/App Store
```

---

## ✅ VALIDACIÓN E2E

### 1. Test Básico de Registro

```bash
# Terminal 1: Backend Functions (emulador)
cd backend/functions
npm run serve

# Terminal 2: Test registro
curl -X POST http://localhost:5001/YOUR_PROJECT_ID/us-central1/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test@123456",
    "fullName": "Test User",
    "phonePrefix": "+1",
    "phone": "5551234567",
    "role": "renter",
    "acceptedTerms": true
  }'

# Esperado:
# {
#   "success": true,
#   "user": {
#     "uid": "firebase-uid",
#     "email": "test@example.com",
#     ...
#   }
# }
```

### 2. Test Crear Terreno

```bash
# 1. Get ID token del usuario creado
# En Firebase Console → Authentication → Copy custom token
TOKEN="eyJhbGciOiJSUzI1NiIs..."

# 2. Crear terreno
curl -X POST http://localhost:5001/YOUR_PROJECT_ID/us-central1/api/terrenos \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "ownerId": "firebase-uid",
    "title": "Terreno Productivo",
    "description": "10 hectáreas aptas para cultivo",
    "sizeHectares": 10,
    "priceMonthly": 500,
    "location": {
      "city": "Santiago",
      "country": "Chile",
      "lat": -33.8688,
      "lng": -51.2093
    },
    "features": ["riego", "energía"]
  }'

# Esperado: terreno creado con ID
```

### 3. Test Listar Terrenos

```bash
curl -X GET http://localhost:5001/YOUR_PROJECT_ID/us-central1/api/terrenos \
  -H "Authorization: Bearer $TOKEN"

# Esperado: lista de terrenos
```

### 4. Test Firebase Auth (Frontend)

```dart
// En main.dart o test file
await FirebaseService.initialize();

final firebase = FirebaseService();
final result = await firebase.signUp(
  email: 'test@example.com',
  password: 'Test@123456',
  fullName: 'Test User',
  phonePrefix: '+1',
  phone: '5551234567',
  role: 'renter',
);

expect(result, isNotNull);
expect(result!.user!.email, 'test@example.com');
```

---

## 🐛 TROUBLESHOOTING

### Error: "Firebase Service Account Key not found"

**Causa:** `.env.local` no configurado  
**Solución:**
```bash
# Crear .env.local con credenciales
echo 'FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account",...}' > backend/.env.local

# O configurar variables de entorno del sistema
export FIREBASE_SERVICE_ACCOUNT_KEY='{"type":"service_account",...}'
```

### Error: "CORS policy: No 'Access-Control-Allow-Origin' header"

**Causa:** CORS no configurado en backend  
**Solución:**
```typescript
// En backend/functions/index.ts, antes de rutas:
import cors from 'cors';
app.use(cors());

// O con config específica:
app.use(cors({
  origin: true,  // Allow all (NO usar en prod)
  credentials: true
}));
```

### Error: "auth/user-not-found" en login

**Causa:** Usuario no existe en Firebase Auth  
**Solución:**
1. Verificar email correcto
2. Verificar usuario existe en Firestore (`users/{uid}`)
3. Recrear usuario si es necesario

### Error: "PERMISSION_DENIED" en Firestore

**Causa:** Firestore rules restrictivas  
**Solución:**
```
Opciones:
1. Verificar usuario autenticado
2. Revisar firestore.rules - usuario tiene permiso?
3. Usar emulador para debug: firebase emulators:start
4. Check Firestore Security Rules en Console
```

### Error: "Cannot find module 'firebase-admin'"

**Causa:** Dependencias no instaladas  
**Solución:**
```bash
cd backend/functions
npm install
npm run build
```

### Flutter: "No Firebase App initialized"

**Causa:** FirebaseService.initialize() no ejecutado  
**Solución:**
```dart
// En main()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();  // ← Agregar esto
  runApp(const MyApp());
}
```

---

## 📊 CHECKLIST DEPLOYMENT

### Pre-Deployment
- [ ] Todas las dependencias instaladas (`npm install`, `flutter pub get`)
- [ ] `.env.local` configurado con credenciales
- [ ] `firebase_options.dart` actualizado con Firebase config
- [ ] Tests E2E locales pasando
- [ ] Firestore rules deployadas
- [ ] Firestore indexes creados
- [ ] CORS configurado en backend

### Deployment
- [ ] Backend functions desplegadas (`firebase deploy --only functions`)
- [ ] Frontend deployado (web, Android, iOS según corresponda)
- [ ] URLs actualizadas en configuración
- [ ] CDN/Cache headers configurados
- [ ] Monitoring habilitado (logs, errors)

### Post-Deployment
- [ ] Tests E2E en staging/producción
- [ ] Usuarios reales pueden registrarse
- [ ] Terrenos pueden ser creados
- [ ] Imágenes se cargan a Storage
- [ ] Firestore queries funcionan
- [ ] Notificaciones (si aplica) funcionan
- [ ] Logs monitoreados para errores
- [ ] Performance acceptable (< 200ms respuesta)

---

## 🔍 MONITOREO POST-DEPLOYMENT

### Firebase Console

1. **Functions:**
   - Cloud Functions → Logs
   - Ver ejecuciones, errores, latencia

2. **Firestore:**
   - Database → Firestore Database
   - Monitor reads/writes/deletes
   - Check indexes en uso

3. **Authentication:**
   - Authentication → Users
   - Ver usuarios creados, último login

4. **Storage:**
   - Storage → Files
   - Ver imágenes subidas, uso de espacio

### Logging

```bash
# Ver logs en tiempo real
firebase functions:log --follow

# O en Cloud Logging Console
gcloud functions log list --follow
```

### Alertas

Configurar en Cloud Monitoring:
- [ ] Error rate > 1%
- [ ] Response time > 1s
- [ ] Disk usage > 80%
- [ ] Quota usage > 90%

---

## 📞 SUPPORT & ESCALATION

**Issues Comunes:**
- Firebase Console: https://console.firebase.google.com
- Cloud Functions Docs: https://cloud.google.com/functions/docs
- Flutter Docs: https://flutter.dev/docs
- Firebase Auth: https://firebase.google.com/docs/auth

**Contacto:**
- Technical Lead: [Email]
- DevOps: [Email]
- QA: [Email]

---

**Documento creado:** 28 de Abril, 2026  
**Versión:** 1.0  
**Status:** ✅ Ready for use
