# IMPLEMENTATION_PLAN

## 1) Objetivo del Producto

CowBnB es una plataforma de arriendo de terrenos para pastoreo de ganado entre propietarios y arrendatarios.
No se tratará como un marketplace abierto de publicaciones anónimas, sino como una plataforma transaccional con:

- Identidad validada de usuarios.
- Flujo de reserva y pago con estado controlado.
- Seguimiento operativo del terreno (incluyendo señal satelital NDVI).
- Trazabilidad de eventos para soporte y supervisión.

Este documento define el plan de implementación para que otro responsable técnico lo ejecute y tú puedas supervisar avance, calidad y riesgos.

---

## 2) Hallazgos Reales del Frontend Actual

### 2.1 Estructura detectada

Se encontró frontend Flutter en `frontend/lib` con estas pantallas:

- `pages/onboarding_page.dart`
- `pages/registration_page.dart`
- `pages/dashboard_owner_page.dart`
- `pages/dashboard_renter_page.dart`
- `pages/map_discovery_page.dart`
- `pages/listing_details_page.dart`
- `pages/checkout_page.dart`
- `pages/create_listing_page.dart`

Rutas activas en `frontend/lib/router.dart`:

- `/`
- `/register`
- `/owner`
- `/renter`
- `/map`
- `/listing`
- `/checkout`
- `/create-listing`

### 2.2 Integraciones y modelos

- Modelos con `fromJson/toJson`: **NO ENCONTRADO**.
- Integración Firebase (`firebase_auth`, `cloud_firestore`, `firebase_storage`): **NO ENCONTRADO**.
- Capa de servicios HTTP/Dio: **NO ENCONTRADO**.
- Carpeta backend/functions: **NO ENCONTRADO**.
- `pubspec.yaml` en el workspace visible: **NO ENCONTRADO**.

### 2.3 Formularios y campos ya esperados por UI

Registro (`registration_page.dart`):

- `role` (`owner` o `renter`)
- `fullName`
- `email`
- `password`
- `phonePrefix`
- `phone`

Crear anuncio (`create_listing_page.dart`):

- `title`
- `description`
- `sizeHectares`
- `priceMonthly`
- `features[]` (riego, energía, caminos, certificación)
- `images[]` (UI presente, flujo real no implementado)

Checkout (`checkout_page.dart`):

- `startDate`
- `endDate`
- aceptación de términos

Estados actuales visibles en UI:

- `Activo`
- `Confirmado`
- `Pendiente`

Estados canónicos objetivo backend:

- `disponible`
- `reservado`
- `en_espera`
- `inactivo`

---

## 3) Arquitectura Objetivo

## 3.1 Decisión principal

Stack base: Firebase full-stack con Cloud Functions + Firestore + Storage + Authentication.

Pagos: Bold con checkout en navegador externo + webhook backend.

Satelital: Copernicus Data Space (STAC/OData) para NDVI.

## 3.2 Dominios backend

Estructura propuesta:

- `backend/functions/terrenos`
- `backend/functions/pagos`
- `backend/functions/satelital`
- `backend/functions/mensajeria`
- `backend/functions/notificaciones`
- `backend/functions/reviews`
- `backend/functions/recomendaciones`
- `backend/jobs/ndvi_cron.js`
- `backend/models/terreno.model.js`
- `backend/models/usuario.model.js`
- `backend/models/reserva.model.js`
- `backend/shared/auth`
- `backend/shared/validation`
- `backend/shared/firestore`
- `backend/shared/observability`
- `backend/shared/idempotency`

## 3.3 Vistas nuevas frontend

Solo vistas no existentes hoy:

- `frontend_new_views/satelital_status`
- `frontend_new_views/pagos_result`

---

## 4) Modelo Operativo de Negocio (No Marketplace Abierto)

Para asegurar que el producto sea una plataforma de arriendo operativa y no un marketplace genérico:

- Solo usuarios autenticados pueden reservar o publicar terrenos.
- Los terrenos tienen estado operativo y trazabilidad.
- El pago aprobado es requisito para transición a `reservado`.
- El monitoreo NDVI puede mover automáticamente un terreno a `en_espera` y requerir acción del arrendatario.
- Las conversaciones PTP están vinculadas a una reserva (no chat abierto sin contexto).
- Reviews se habilitan post-reserva finalizada.

---

## 5) Requisitos Funcionales por Módulo

### 5.1 AUTH

| ID      | Requisito            | Input esperado                                      | Output esperado                  | Skill/API a usar                 | Dependencia |
| ------- | -------------------- | --------------------------------------------------- | -------------------------------- | -------------------------------- | ----------- |
| AUTH-01 | Registro con rol     | fullName, email, password, phonePrefix, phone, role | usuario Auth + documento `users` | Firebase Auth + Firestore        | Ninguna     |
| AUTH-02 | Login email/password | email, password                                     | sesión válida y UID              | Firebase Auth                    | AUTH-01     |
| AUTH-03 | Perfil onboarding    | userId + datos iniciales                            | documento actualizado            | Firestore                        | AUTH-01     |
| AUTH-04 | Control por rol      | token + role                                        | acceso permitido o bloqueo       | Firebase Auth + reglas Firestore | AUTH-02     |
| AUTH-05 | Logout               | sesión activa                                       | sesión cerrada                   | Firebase Auth                    | AUTH-02     |

### 5.2 TERRENOS

| ID   | Requisito          | Input esperado                            | Output esperado                    | Skill/API a usar      | Dependencia |
| ---- | ------------------ | ----------------------------------------- | ---------------------------------- | --------------------- | ----------- |
| T-01 | Crear terreno      | ownerId + datos de formulario             | terreno creado estado `disponible` | Firestore             | AUTH-01     |
| T-02 | Editar terreno     | terrenoId + cambios                       | terreno actualizado                | Firestore             | T-01        |
| T-03 | Ver detalle        | terrenoId                                 | payload completo del terreno       | Firestore             | T-01        |
| T-04 | Listar con filtros | zona, precio, hectáreas, estado, features | lista paginada                     | Firestore + índices   | T-01        |
| T-05 | Cambio de estado   | terrenoId + estado destino                | estado actualizado + auditoría     | Firestore + Functions | T-01        |
| T-06 | Mapeo legacy UI    | `Activo/Confirmado/Pendiente`             | mapeo a estados canónicos          | Functions             | T-05        |

### 5.3 IMÁGENES

| ID     | Requisito          | Input esperado                | Output esperado             | Skill/API a usar     | Dependencia |
| ------ | ------------------ | ----------------------------- | --------------------------- | -------------------- | ----------- |
| IMG-01 | Subir imagen       | archivo + terrenoId           | URL segura + metadata       | Storage + Firestore  | T-01        |
| IMG-02 | Límite de galería  | terrenoId + imágenes actuales | máximo 10 imágenes          | Functions validación | IMG-01      |
| IMG-03 | Portada de terreno | terrenoId + imageId           | `coverImageUrl` actualizado | Firestore            | IMG-01      |
| IMG-04 | Eliminar imagen    | terrenoId + imageId           | borrado físico + referencia | Storage + Firestore  | IMG-01      |

### 5.4 MAPAS

| ID     | Requisito               | Input esperado          | Output esperado               | Skill/API a usar           | Dependencia |
| ------ | ----------------------- | ----------------------- | ----------------------------- | -------------------------- | ----------- |
| MAP-01 | Geolocalización usuario | permiso del dispositivo | lat/lng actual                | Flutter + geolocator       | AUTH-02     |
| MAP-02 | Búsqueda ubicación      | texto libre             | coordenadas de centro         | geocoding provider         | MAP-01      |
| MAP-03 | Consulta por viewport   | bbox/geohash + filtros  | lista de pines                | Firestore geohash strategy | T-04        |
| MAP-04 | Resaltado disponibles   | flag UI                 | pines destacados `disponible` | Firestore + UI             | T-06        |

### 5.5 SATELITAL

| ID     | Requisito                | Input esperado                   | Output esperado                | Skill/API a usar            | Dependencia |
| ------ | ------------------------ | -------------------------------- | ------------------------------ | --------------------------- | ----------- |
| SAT-01 | Token Copernicus         | credenciales servicio            | token activo                   | Copernicus OData/STAC       | T-01        |
| SAT-02 | Consulta NDVI            | coordenadas o polígono + fecha   | NDVI calculado                 | Copernicus API              | SAT-01      |
| SAT-03 | Evaluación umbral        | NDVI actual + histórico + umbral | riesgo/no riesgo               | Functions                   | SAT-02      |
| SAT-04 | Cambio automático estado | terrenoId + decisión NDVI        | `en_espera` o `disponible`     | Firestore transaction       | SAT-03      |
| SAT-05 | Email acción one-time    | userId + evento                  | correo con enlace firmado      | Functions + proveedor email | SAT-04      |
| SAT-06 | Confirmar/reactivar      | token + acción usuario           | estado final y token consumido | HTTPS Function              | SAT-05      |
| SAT-07 | Job periódico NDVI       | scheduler 6h                     | corrida y logs persistidos     | Scheduler + jobs            | SAT-02      |

### 5.6 RESERVAS/PAGOS

| ID     | Requisito             | Input esperado                     | Output esperado                           | Skill/API a usar                | Dependencia |
| ------ | --------------------- | ---------------------------------- | ----------------------------------------- | ------------------------------- | ----------- |
| PAY-01 | Crear intento reserva | renterId, terrenoId, fechas, monto | reserva `en_espera` con expiración        | Firestore + Functions           | T-03        |
| PAY-02 | Iniciar checkout Bold | reservaId + monto + metadata       | checkoutUrl + reference                   | Bold API                        | PAY-01      |
| PAY-03 | Webhook Bold          | evento firmado                     | firma verificada + evento idempotente     | HTTPS Function                  | PAY-02      |
| PAY-04 | Confirmar reserva     | evento aprobado                    | reserva `reservado` + terreno `reservado` | Firestore transaction           | PAY-03      |
| PAY-05 | Expirar pendiente     | reserva vencida o pago fallido     | reserva cancelada + terreno disponible    | Scheduler + Firestore           | PAY-01      |
| PAY-06 | Trazabilidad pagos    | eventos de pago                    | colección `payment_events`                | Firestore                       | PAY-03      |
| PAY-07 | Resultado pago UI     | referencia de pago                 | pantalla de estado final                  | frontend_new_views/pagos_result | PAY-03      |

### 5.7 MENSAJERÍA PTP

| ID     | Requisito                      | Input esperado                     | Output esperado               | Skill/API a usar      | Dependencia |
| ------ | ------------------------------ | ---------------------------------- | ----------------------------- | --------------------- | ----------- |
| MSG-01 | Crear conversación por reserva | reservaId, ownerId, renterId       | conversación única            | Firestore             | PAY-04      |
| MSG-02 | Enviar mensaje                 | conversationId, senderId, text     | mensaje persistido            | Firestore             | MSG-01      |
| MSG-03 | Listar conversaciones          | userId                             | ordenadas por `lastMessageAt` | Firestore + índices   | MSG-01      |
| MSG-04 | Marcar leído                   | conversationId, userId, lastReadAt | contador unread actualizado   | Firestore             | MSG-02      |
| MSG-05 | Trigger notificación           | evento nuevo mensaje               | push/email enviado            | Functions + FCM/email | MSG-02      |

### 5.8 CALIFICACIONES

| ID     | Requisito      | Input esperado                        | Output esperado                         | Skill/API a usar      | Dependencia |
| ------ | -------------- | ------------------------------------- | --------------------------------------- | --------------------- | ----------- |
| REV-01 | Crear review   | reserva finalizada, score, comentario | review persistida                       | Firestore + Functions | PAY-04      |
| REV-02 | Antiduplicado  | reservaId + reviewerId                | rechazo duplicado                       | Functions validación  | REV-01      |
| REV-03 | Agregado score | cambio en review                      | `ratingAvg`, `ratingCount` actualizados | Firestore transaction | REV-01      |
| REV-04 | Listar reviews | terrenoId + paginación                | reseñas ordenadas por fecha             | Firestore + índices   | REV-01      |

### 5.9 RECOMENDACIONES

| ID     | Requisito          | Input esperado                                  | Output esperado           | Skill/API a usar        | Dependencia |
| ------ | ------------------ | ----------------------------------------------- | ------------------------- | ----------------------- | ----------- |
| REC-01 | Captura de señales | búsquedas, clics, reservas, ubicación           | eventos de comportamiento | Firestore               | AUTH-02     |
| REC-02 | Heurística v1      | historial + distancia + disponibilidad + rating | score por terreno         | Functions               | REC-01      |
| REC-03 | Feed recomendado   | userId                                          | top N con motivos         | Firestore materializado | REC-02      |

### 5.10 FILTROS

| ID     | Requisito       | Input esperado           | Output esperado  | Skill/API a usar              | Dependencia |
| ------ | --------------- | ------------------------ | ---------------- | ----------------------------- | ----------- |
| FIL-01 | Rango precio    | minPrice, maxPrice       | lista filtrada   | Firestore + índices           | T-04        |
| FIL-02 | Rango hectáreas | minHectares, maxHectares | lista filtrada   | Firestore + índices           | T-04        |
| FIL-03 | Estado canónico | status                   | lista filtrada   | Firestore + índices           | T-06        |
| FIL-04 | Amenities       | features[]               | lista compatible | Firestore array strategy      | T-04        |
| FIL-05 | Zona visible    | geohash/bbox             | lista por área   | Firestore geospatial strategy | MAP-03      |

---

## 6) Plan de Ejecución (Orden Real de Trabajo)

Sin calendario por semanas, ordenado por criticidad para supervisión.

### Etapa A: Fundación Técnica

- [ ] Crear base de proyecto backend Firebase Functions.
- [ ] Crear carpetas por dominio (`terrenos`, `pagos`, `satelital`, etc.).
- [ ] Definir convenciones de errores, logs, requestId e idempotencia.
- [ ] Definir modelos y validadores (`usuario`, `terreno`, `reserva`).

Archivos a crear/modificar:

- `backend/functions/index.js`
- `backend/shared/*`
- `backend/models/*`

Criterio de done:

- Servicios arrancan en entorno local.
- Estructura base aprobada por supervisor.
- Documentados contratos mínimos de cada dominio.

### Etapa B: Paridad con UI Existente

- [ ] AUTH completo (registro/login/perfil).
- [ ] CRUD de terrenos con estados canónicos.
- [ ] Upload de imágenes y portada.
- [ ] Endpoint de listado con filtros base.

Archivos:

- `backend/functions/auth/*`
- `backend/functions/terrenos/*`

Criterio de done:

- Formularios de registro y crear anuncio pueden persistir datos reales.
- Dashboard owner/renter deja de depender de mocks para entidades core.

### Etapa C: Flujo de Reserva y Pago

- [ ] Reserva en estado `en_espera` con expiración.
- [ ] Inicio checkout Bold (browser externo).
- [ ] Webhook Bold con verificación de firma e idempotencia.
- [ ] Confirmación atómica de reserva + estado de terreno.
- [ ] Implementar vista `frontend_new_views/pagos_result`.

Archivos:

- `backend/functions/pagos/*`
- `frontend_new_views/pagos_result/*`

Criterio de done:

- Flujo end-to-end completo: crear reserva -> pagar -> confirmar.
- Reintento de webhook no genera duplicados.

### Etapa D: Mensajería y Notificaciones

- [ ] Crear conversación automática al confirmar reserva.
- [ ] Enviar y leer mensajes PTP.
- [ ] Trigger de notificación por nuevo mensaje.

Archivos:

- `backend/functions/mensajeria/*`
- `backend/functions/notificaciones/*`

Criterio de done:

- Mensajería disponible solo para usuarios vinculados por reserva.
- Notificaciones llegan con metadata mínima útil.

### Etapa E: Satelital NDVI

- [ ] Implementar cliente Copernicus (auth + consulta NDVI).
- [ ] Programar job NDVI periódico (cada 6 horas).
- [ ] Aplicar regla de umbral y cambio automático de estado.
- [ ] Email de confirmación/reactivación con token one-time.
- [ ] Implementar vista `frontend_new_views/satelital_status`.

Archivos:

- `backend/functions/satelital/*`
- `backend/jobs/ndvi_cron.js`
- `frontend_new_views/satelital_status/*`

Criterio de done:

- Corridas NDVI trazables y reproducibles.
- Token de acción cumple one-time + expiración.

### Etapa F: Calidad, Reviews y Recomendación

- [ ] Reviews post-reserva finalizada.
- [ ] Agregación de score del terreno.
- [ ] Recomendación heurística v1.
- [ ] Hardening de reglas, índices y observabilidad.

Archivos:

- `backend/functions/reviews/*`
- `backend/functions/recomendaciones/*`
- `firestore.rules`
- `firestore.indexes.json`

Criterio de done:

- Recomendados en mapa/dashboard con lógica explicable.
- Reglas de seguridad pasan pruebas por rol.

---

## 7) Índices Compuestos Firestore Necesarios

### terrenos

- `ownerId ASC, createdAt DESC`
- `status ASC, createdAt DESC`
- `status ASC, priceMonthly ASC`
- `status ASC, priceMonthly DESC`
- `status ASC, hectares ASC`
- `status ASC, hectares DESC`
- `status ASC, ratingAvg DESC`
- `geohash ASC, status ASC`
- `geohash ASC, status ASC, priceMonthly ASC`
- `geohash ASC, status ASC, priceMonthly DESC`
- `geohash ASC, status ASC, hectares ASC`
- `geohash ASC, status ASC, hectares DESC`
- `features ARRAY, status ASC`

### reservas

- `renterId ASC, createdAt DESC`
- `ownerId ASC, createdAt DESC`
- `terrenoId ASC, createdAt DESC`
- `status ASC, expiresAt ASC`
- `paymentStatus ASC, updatedAt DESC`
- `renterId ASC, status ASC, startDate ASC`
- `ownerId ASC, status ASC, startDate ASC`

### conversaciones

- `ownerId ASC, lastMessageAt DESC`
- `renterId ASC, lastMessageAt DESC`
- `reservaId ASC, updatedAt DESC`

### mensajes (collection group)

- `conversationId ASC, sentAt DESC`
- `senderId ASC, sentAt DESC`

### reviews

- `terrenoId ASC, createdAt DESC`
- `reviewerId ASC, createdAt DESC`

### recommendations

- `userId ASC, score DESC`
- `userId ASC, generatedAt DESC`

### pagos

- `externalReference ASC, createdAt DESC`
- `reservaId ASC, createdAt DESC`
- `status ASC, createdAt DESC`

### ndvi_checks

- `terrenoId ASC, createdAt DESC`
- `decision ASC, createdAt DESC`

---

## 8) Reglas de Seguridad Firestore por Colección

### users

- Lectura: solo `auth.uid == userId`.
- Escritura: solo dueño del documento.
- `role` y banderas críticas: solo backend Functions.

### terrenos

- Crear/editar: solo propietario (`ownerId == auth.uid`).
- Cambio a estados críticos (`reservado`, `en_espera`): solo backend.
- Lectura pública controlada para `disponible`.

### reservas

- Crear: solo arrendatario autenticado.
- Lectura: solo owner o renter de la reserva.
- Estados de pago/reserva: solo backend.

### pagos

- Escritura: solo webhook/backend.
- Lectura: usuarios asociados a la reserva.

### conversaciones/mensajes

- Solo participantes pueden leer/escribir.
- `senderId` debe ser el usuario autenticado.

### reviews

- Crear: usuario autenticado con reserva finalizada.
- Editar: autor dentro de ventana limitada.

### recommendations

- Lectura: solo dueño del `userId`.
- Escritura: solo backend.

### action_tokens y ndvi_checks

- Lectura/escritura: solo backend.
- No exponer tokens en claro.

---

## 9) Observabilidad y Control de Calidad

### 9.1 Señales mínimas de observabilidad

- `requestId` por operación crítica.
- logs estructurados por dominio.
- registro de transiciones de estado.
- conteo de errores por endpoint.

### 9.2 Set de pruebas obligatorias para aprobar etapa

- Pruebas unitarias de validaciones y mapeo de estados.
- Pruebas de integración Firestore emulador.
- Prueba de idempotencia webhook Bold (doble evento).
- Prueba de expiración de reservas pendientes.
- Prueba de token one-time (uso único + expiración).
- Pruebas de seguridad por rol owner/renter/no-auth.

---

## 10) Riesgos Principales y Mitigación

- Riesgo: webhook duplicado o fuera de orden.
- Mitigación: idempotencia por eventId + transacciones.

- Riesgo: consultas geográficas costosas.
- Mitigación: geohash + paginación + límites estrictos.

- Riesgo: falsos positivos en NDVI.
- Mitigación: umbral configurable + confirmación humana vía enlace.

- Riesgo: abuso de mensajería.
- Mitigación: rate limit por usuario y validación de participantes.

- Riesgo: fuga de tokens de acción.
- Mitigación: token one-time hasheado + TTL corto + revocación inmediata.

---

## 11) Checklist de Supervisión (para revisión humana)

Usar este checklist para aceptar/rechazar cada entrega del implementador:

- [ ] Cumple el modelo de plataforma de arriendo (no marketplace abierto).
- [ ] No hay operaciones críticas directamente desde cliente.
- [ ] Estados canónicos del terreno implementados y auditables.
- [ ] Webhook de pagos es idempotente y verifica firma.
- [ ] NDVI corre por job y modifica estado con trazabilidad.
- [ ] Firestore rules restringen acceso por ownership/rol.
- [ ] Índices compuestos documentados y desplegados.
- [ ] E2E principal funciona sin datos mock.

---

## 12) Decisiones Pendientes

- Definir proveedor de email final (`SendGrid` o extensión Firebase).
- Definir proveedor de geocoding para búsqueda por texto.
- Confirmar umbral NDVI inicial por tipo de terreno/cultivo.
- Confirmar política de cancelación y penalidades.
- Confirmar estrategia fiscal (impuestos/moneda por país).
- Confirmar moderación de reviews (manual, automática o híbrida).
- Confirmar SLA esperado para notificaciones críticas.

---

## 13) Cierre

Este plan está listo para ejecución por un tercero y revisión por supervisión.
No incluye implementación de código; solo define qué construir, en qué orden, y bajo qué criterio de calidad y seguridad.
