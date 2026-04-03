# SKILL: Sentinel-2 / NDVI — Copernicus Data Space Ecosystem

> Fuente oficial: https://dataspace.copernicus.eu  
> API usada: Sentinel Hub (Process API + Statistical API)  
> Última verificación: Abril 2026  
> Stack objetivo: Node.js (Cloud Functions / Cron Job)

---

## ¿Qué es esto y por qué usarlo?

Copernicus es el programa de observación terrestre de la Unión Europea.
Sentinel-2 es un satélite que captura imágenes multiespectrales cada ~5 días.
**El acceso es completamente gratuito** registrándose en dataspace.copernicus.eu.

**NDVI** (Normalized Difference Vegetation Index) mide la salud y densidad de
la vegetación usando las bandas B04 (rojo) y B08 (infrarrojo cercano):

```
NDVI = (B08 - B04) / (B08 + B04)
```

| Valor NDVI | Interpretación                                             |
| ---------- | ---------------------------------------------------------- |
| < 0.1      | Suelo desnudo, agua, urbano                                |
| 0.1 – 0.3  | Vegetación escasa o seca                                   |
| 0.3 – 0.5  | Pasto moderado                                             |
| **> 0.5**  | **Vegetación densa / pasto crecido** ← umbral para alertar |
| > 0.7      | Bosque denso / cultivo maduro                              |

---

## Registro y credenciales

1. Crear cuenta gratuita en: https://dataspace.copernicus.eu
2. Ir a **Dashboard → User Settings → OAuth Clients → New OAuth Client**
3. Guardar `client_id` y `client_secret` (solo se muestran una vez)

> Estas credenciales son para Sentinel Hub APIs (Process API, Statistical API).  
> Son distintas a las credenciales OData (username/password).

---

## Autenticación: Obtener Access Token

El token expira cada **~1 hora**. Implementar cache o renovación automática.

```js
// functions/services/sentinelAuth.js

const axios = require("axios");

let cachedToken = null;
let tokenExpiry = null;

async function getSentinelToken() {
  if (cachedToken && Date.now() < tokenExpiry) {
    return cachedToken;
  }

  const params = new URLSearchParams({
    grant_type: "client_credentials",
    client_id: process.env.SENTINEL_CLIENT_ID,
    client_secret: process.env.SENTINEL_CLIENT_SECRET,
  });

  const response = await axios.post(
    "https://identity.dataspace.copernicus.eu/auth/realms/CDSE/protocol/openid-connect/token",
    params.toString(),
    { headers: { "Content-Type": "application/x-www-form-urlencoded" } },
  );

  cachedToken = response.data.access_token;
  // Renovar 5 minutos antes de que expire
  tokenExpiry = Date.now() + (response.data.expires_in - 300) * 1000;

  return cachedToken;
}

module.exports = { getSentinelToken };
```

---

## Process API: Obtener NDVI promedio de un polígono

Este es el endpoint principal. Devuelve el valor estadístico de NDVI
para un área geográfica sin necesidad de descargar imágenes completas.

```
POST https://sh.dataspace.copernicus.eu/api/v1/process
Authorization: Bearer <access_token>
Content-Type: application/json
```

### Evalscript para NDVI

```js
// El evalscript es JavaScript que corre en los servidores de Sentinel Hub
const NDVI_EVALSCRIPT = `
//VERSION=3
function setup() {
  return {
    input: [{ bands: ["B04", "B08", "dataMask"] }],
    output: { bands: 1, sampleType: "FLOAT32" }
  };
}
function evaluatePixel(sample) {
  if (sample.dataMask === 0) return [NaN];
  let ndvi = (sample.B08 - sample.B04) / (sample.B08 + sample.B04);
  return [ndvi];
}
`;
```

### Función completa para consultar NDVI de un terreno

```js
// functions/services/ndviService.js

const axios = require("axios");
const { getSentinelToken } = require("./sentinelAuth");

/**
 * Obtiene el NDVI promedio de un polígono en los últimos N días.
 * @param {Array} coordenadas - Array de [lng, lat] que forman el polígono del terreno
 * @param {number} diasAtras - Cuántos días hacia atrás buscar imágenes (default: 30)
 * @returns {Promise<{ndvi: number, fecha: string, cloudCover: number}>}
 */
async function obtenerNDVI(coordenadas, diasAtras = 30) {
  const token = await getSentinelToken();

  const fechaFin = new Date().toISOString().split("T")[0];
  const fechaInicio = new Date(Date.now() - diasAtras * 86400000)
    .toISOString()
    .split("T")[0];

  // Asegurar que el polígono esté cerrado (primer punto = último punto)
  const poligonoCerrado = [...coordenadas];
  if (
    JSON.stringify(coordenadas[0]) !==
    JSON.stringify(coordenadas[coordenadas.length - 1])
  ) {
    poligonoCerrado.push(coordenadas[0]);
  }

  const body = {
    input: {
      bounds: {
        geometry: {
          type: "Polygon",
          coordinates: [poligonoCerrado],
        },
      },
      data: [
        {
          type: "sentinel-2-l2a",
          dataFilter: {
            timeRange: {
              from: `${fechaInicio}T00:00:00Z`,
              to: `${fechaFin}T23:59:59Z`,
            },
            maxCloudCoverage: 30, // Rechazar imágenes con >30% de nubes
          },
        },
      ],
    },
    evalscript: NDVI_EVALSCRIPT,
    output: {
      responses: [
        {
          identifier: "default",
          format: { type: "application/json" },
        },
      ],
    },
  };

  // Usar Statistical API para obtener estadísticas sin descargar imagen
  const statBody = {
    input: body.input,
    aggregation: {
      timeRange: {
        from: `${fechaInicio}T00:00:00Z`,
        to: `${fechaFin}T23:59:59Z`,
      },
      aggregationInterval: { of: "P30D" }, // Agrupar en período de 30 días
      evalscript: NDVI_EVALSCRIPT,
      resx: 10, // Resolución 10m (Sentinel-2 nativo)
      resy: 10,
    },
    calculations: { default: {} },
  };

  const response = await axios.post(
    "https://sh.dataspace.copernicus.eu/api/v1/statistics",
    statBody,
    {
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
    },
  );

  const datos = response.data;

  // Extraer NDVI promedio del intervalo más reciente
  const intervalos = datos.data?.[0]?.intervals || [];
  if (intervalos.length === 0) {
    throw new Error(
      "No hay imágenes Sentinel-2 disponibles para este período (posible cobertura de nubes)",
    );
  }

  const ultimo = intervalos[intervalos.length - 1];
  const ndviMean = ultimo.outputs?.default?.bands?.B0?.stats?.mean;

  return {
    ndvi: ndviMean,
    fecha: ultimo.to,
    muestreos: ultimo.outputs?.default?.bands?.B0?.stats?.sampleCount,
  };
}

module.exports = { obtenerNDVI };
```

---

## Cron Job: Monitoreo automático de terrenos

```js
// functions/jobs/ndviMonitor.js

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { obtenerNDVI } = require("../services/ndviService");

const db = admin.firestore();

// Ejecutar cada 7 días (puedes ajustar la frecuencia)
exports.monitoreoNDVI = functions.pubsub
  .schedule("0 6 * * 1") // Cada lunes a las 6am UTC
  .timeZone("America/Bogota")
  .onRun(async () => {
    // Obtener solo terrenos activos y disponibles
    const terrenosSnap = await db
      .collection("terrenos")
      .where("estado", "in", ["disponible", "en_espera"])
      .get();

    const tareas = terrenosSnap.docs.map(async (doc) => {
      const terreno = doc.data();

      // El terreno debe tener coordenadas de polígono guardadas
      if (!terreno.coordenadas || terreno.coordenadas.length < 3) {
        console.warn(`Terreno ${doc.id} no tiene coordenadas de polígono`);
        return;
      }

      try {
        const { ndvi, fecha } = await obtenerNDVI(terreno.coordenadas, 30);

        // Guardar historial NDVI
        await doc.ref.collection("ndviHistorial").add({
          ndvi,
          fecha,
          evaluadoEn: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Umbral configurable — pasto crecido si NDVI > 0.5
        const UMBRAL_PASTO_CRECIDO = 0.5;

        if (ndvi > UMBRAL_PASTO_CRECIDO && terreno.estado === "disponible") {
          // Cambiar estado a 'en_espera' y notificar arrendatario
          const tokenConfirmacion = generarTokenUnico(doc.id);

          await doc.ref.update({
            estado: "en_espera",
            razonEspera: "ndvi_alto",
            ndviDetectado: ndvi,
            tokenConfirmacion,
            tokenExpira: admin.firestore.Timestamp.fromDate(
              new Date(Date.now() + 72 * 60 * 60 * 1000), // 72 horas
            ),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          await enviarEmailConfirmacion(
            terreno,
            doc.id,
            ndvi,
            tokenConfirmacion,
          );
        }

        // Si NDVI bajó y estaba en espera por ndvi_alto, reactivar automáticamente
        if (
          ndvi <= UMBRAL_PASTO_CRECIDO &&
          terreno.estado === "en_espera" &&
          terreno.razonEspera === "ndvi_alto"
        ) {
          await doc.ref.update({
            estado: "disponible",
            razonEspera: null,
            tokenConfirmacion: null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      } catch (error) {
        // No cambiar estado si no hay imagen disponible (nubes, etc.)
        console.error(`Error NDVI terreno ${doc.id}:`, error.message);
        await doc.ref.collection("ndviHistorial").add({
          error: error.message,
          evaluadoEn: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });

    await Promise.allSettled(tareas);
    return null;
  });

function generarTokenUnico(terrenoId) {
  const crypto = require("crypto");
  return crypto.randomBytes(32).toString("hex");
}
```

---

## Endpoint: Confirmar/Reactivar desde email

```js
// functions/terrenos/confirmarEstado.js

exports.confirmarEstadoTerreno = functions.https.onRequest(async (req, res) => {
  const { token, accion } = req.query;
  // accion: 'confirmar' (sí está crecido) | 'reactivar' (no está crecido)

  if (!token || !accion) {
    return res.status(400).send("Parámetros inválidos");
  }

  const snap = await db
    .collection("terrenos")
    .where("tokenConfirmacion", "==", token)
    .limit(1)
    .get();

  if (snap.empty) {
    return res.status(404).send("Token inválido o expirado");
  }

  const doc = snap.docs[0];
  const terreno = doc.data();

  // Verificar que el token no expiró
  if (terreno.tokenExpira.toDate() < new Date()) {
    return res.status(410).send("Este enlace ha expirado");
  }

  if (accion === "confirmar") {
    // El arrendatario confirma que el pasto está crecido → queda en espera
    await doc.ref.update({
      estado: "en_espera",
      confirmadoPorArrendatario: true,
      tokenConfirmacion: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return res.redirect("https://tu-app.com/terreno/en-espera-confirmado");
  }

  if (accion === "reactivar") {
    // El arrendatario dice que no está crecido → reactivar
    await doc.ref.update({
      estado: "disponible",
      confirmadoPorArrendatario: false,
      tokenConfirmacion: null,
      ndviIgnorado: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return res.redirect("https://tu-app.com/terreno/reactivado");
  }

  res.status(400).send("Acción no reconocida");
});
```

---

## Email de confirmación (con SendGrid o Firebase Extensions)

```js
async function enviarEmailConfirmacion(terreno, terrenoId, ndvi, token) {
  const baseUrl = process.env.FUNCTIONS_BASE_URL; // URL de tus Cloud Functions

  const urlConfirmar = `${baseUrl}/confirmarEstadoTerreno?token=${token}&accion=confirmar`;
  const urlReactivar = `${baseUrl}/confirmarEstadoTerreno?token=${token}&accion=reactivar`;

  const html = `
    <h2>Alerta de vegetación en tu terreno</h2>
    <p>Nuestro sistema de monitoreo satelital detectó un índice de vegetación 
    elevado (NDVI: ${ndvi.toFixed(2)}) en tu terreno <strong>${terreno.nombre}</strong>.</p>
    <p>Esto puede indicar que el pasto está crecido. Por favor confirma:</p>
    <p>
      <a href="${urlConfirmar}" style="background:#f44336;color:white;padding:10px 20px;text-decoration:none;border-radius:4px;">
        Sí, el pasto está crecido
      </a>
      &nbsp;&nbsp;
      <a href="${urlReactivar}" style="background:#4CAF50;color:white;padding:10px 20px;text-decoration:none;border-radius:4px;">
        No, reactivar mi terreno
      </a>
    </p>
    <p><small>Este enlace expira en 72 horas.</small></p>
  `;

  // Usar Firebase Extension "Trigger Email" o SendGrid
  await db.collection("mail").add({
    to: terreno.arrendatarioEmail,
    message: {
      subject: `⚠️ Alerta satelital: ${terreno.nombre}`,
      html,
    },
  });
}
```

---

## Modelo de datos en Firestore

```
terrenos/{terrenoId}
  ├── estado: 'disponible' | 'reservado' | 'en_espera' | 'inactivo'
  ├── coordenadas: [[lng, lat], [lng, lat], ...]  ← polígono del terreno
  ├── razonEspera: 'ndvi_alto' | null
  ├── ndviDetectado: number | null
  ├── tokenConfirmacion: string | null
  ├── tokenExpira: Timestamp | null
  ├── confirmadoPorArrendatario: boolean | null
  └── ndviHistorial/ (subcolección)
      └── {autoId}
          ├── ndvi: number
          ├── fecha: string (ISO)
          └── evaluadoEn: Timestamp
```

---

## Limitaciones y consideraciones importantes

| Limitación          | Detalle                                                                                             |
| ------------------- | --------------------------------------------------------------------------------------------------- |
| Resolución temporal | Sentinel-2 pasa cada ~5 días. No es tiempo real.                                                    |
| Cobertura de nubes  | Con >30% de nubes no hay imagen útil. Manejar el error.                                             |
| Resolución espacial | Bandas B04/B08: 10m por píxel. Bueno para terrenos >0.1 ha.                                         |
| Cuota gratuita      | Sentinel Hub tiene un tier gratuito con Processing Units limitadas. Monitorear uso en el dashboard. |
| Latencia            | Las imágenes tienen un retraso de ~2 días desde la captura.                                         |

---

## Variables de entorno requeridas

```bash
SENTINEL_CLIENT_ID=tu_client_id
SENTINEL_CLIENT_SECRET=tu_client_secret
SENTINEL_BASE_URL=https://sh.dataspace.copernicus.eu
NDVI_UMBRAL_ALERTA=0.5
FUNCTIONS_BASE_URL=https://us-central1-tu-proyecto.cloudfunctions.net
```

---

## Paquetes Flutter para mostrar mapa con polígonos de terreno

```yaml
# pubspec.yaml
dependencies:
  flutter_map: ^6.1.0 # Mapas OSM sin API key
  latlong2: ^0.9.0 # Coordenadas lat/lng
  geolocator: ^11.0.0 # Ubicación del usuario
  permission_handler: ^11.0.0 # Permisos de ubicación
```

```dart
// Dibujar polígono de terreno en mapa
FlutterMap(
  options: MapOptions(center: LatLng(latCentro, lngCentro), zoom: 15),
  children: [
    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
    PolygonLayer(polygons: [
      Polygon(
        points: terreno.coordenadas
            .map((c) => LatLng(c[1], c[0]))
            .toList(),
        color: terreno.estado == 'en_espera'
            ? Colors.orange.withOpacity(0.4)
            : Colors.green.withOpacity(0.3),
        borderColor: terreno.estado == 'en_espera'
            ? Colors.orange
            : Colors.green,
        borderStrokeWidth: 2,
      )
    ]),
  ],
)
```

---

## Checklist de implementación

- [ ] Crear cuenta en dataspace.copernicus.eu
- [ ] Generar OAuth Client → guardar client_id y client_secret
- [ ] Implementar `sentinelAuth.js` con cache de token
- [ ] Implementar `ndviService.js` con Statistical API
- [ ] Crear Cron Job `monitoreoNDVI` con Pub/Sub en Cloud Functions
- [ ] Crear endpoint `confirmarEstadoTerreno` con tokens one-time
- [ ] Instalar Firebase Extension "Trigger Email" o configurar SendGrid
- [ ] Guardar polígono de coordenadas al crear terreno (desde Flutter)
- [ ] Dibujar polígono en mapa Flutter con `flutter_map`
- [ ] Definir umbral NDVI como variable de entorno (default: 0.5)
- [ ] Manejar caso de error por nubes (no cambiar estado del terreno)
- [ ] Monitorear Processing Units en Sentinel Hub Dashboard
