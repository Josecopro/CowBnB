# CowBnB Backend Runbook

Guia reproducible para levantar CowBnB (frontend + backend) en desarrollo local.

## 1. Requisitos

- Linux con Flutter instalado y en PATH
- Node.js 18+ (recomendado 20+)
- npm
- Firebase CLI (se recomienda usar siempre `npx -y firebase-tools@latest`)

Verificacion rapida:

```bash
flutter --version
node --version
npm --version
npx -y firebase-tools@latest --version
```

## 2. Frontend (Flutter Linux)

Desde la raiz del repo:

```bash
cd frontend
flutter clean
flutter pub get
flutter run -d linux
```

Si `flutter run -d linux` falla por tema de runtime Linux, usar build release:

```bash
cd frontend
flutter build linux
./build/linux/x64/release/bundle/cowbnb
```

## 3. Backend (Firebase Functions)

### 3.1 Primera vez (bootstrap)

Desde la raiz del repo:

```bash
cd /home/josecoprolovespenguins/Projects/CowBnB
npx -y firebase-tools@latest login
npx -y firebase-tools@latest use --add <TU_PROJECT_ID>
npx -y firebase-tools@latest init functions emulators
```

Durante `firebase init` usar estas opciones:

1. Seleccionar `Functions` y `Emulators`.
2. Lenguaje de Functions: `TypeScript`.
3. Habilitar linting: opcional (recomendado si el equipo lo usa).
4. Instalar dependencias al final: `Yes`.
5. Carpeta de Functions: `backend`.

### 3.2 Ejecutar backend local

```bash
cd /home/josecoprolovespenguins/Projects/CowBnB/backend
npm install
npm run build

cd /home/josecoprolovespenguins/Projects/CowBnB
npx -y firebase-tools@latest emulators:start --only functions
```

## 4. Problemas comunes

### Error: `Cannot find module 'firebase-functions'`

Faltan dependencias del backend. Ejecutar:

```bash
cd /home/josecoprolovespenguins/Projects/CowBnB/backend
npm install
```

Si aun no existe `package.json` en `backend`, primero correr:

```bash
cd /home/josecoprolovespenguins/Projects/CowBnB
npx -y firebase-tools@latest init functions
```

Y elegir `backend` como carpeta de Functions.

### Error CMake cruzado al correr Flutter en Linux

Si aparece conflicto entre rutas `build/` de distintas carpetas:

```bash
cd /home/josecoprolovespenguins/Projects/CowBnB/frontend
flutter clean
rm -rf build/linux
flutter pub get
flutter run -d linux
```

## 5. Flujo recomendado del equipo

1. Cada dev ejecuta primero frontend con `flutter pub get`.
2. Cada dev valida backend con `npm install` dentro de `backend`.
3. Backend siempre se levanta con emuladores Firebase usando `npx -y firebase-tools@latest`.
4. Si hay cambios de dependencias, actualizar este README.
