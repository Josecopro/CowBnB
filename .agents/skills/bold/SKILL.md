# SKILL: Bold Pagos Colombia

> Fuente oficial: https://developers.bold.co  
> Última verificación: Abril 2026  
> Stack objetivo: Node.js (Cloud Functions) + Flutter (WebView / deeplink)

---

## ¿Qué es Bold?

Bold es una pasarela de pagos colombiana que acepta tarjetas crédito/débito,
PSE, Nequi y botón Bancolombia. Opera en COP y USD. No requiere certificación
PCI para la integración con Botón de Pagos (la captura la hace Bold).

---

## Modos de integración disponibles

| Modo                    | Cuándo usarlo                             | Requiere PCI |
| ----------------------- | ----------------------------------------- | ------------ |
| **Botón de Pagos** (JS) | Web o WebView en Flutter                  | No           |
| **API Link de Pagos**   | Generar link desde backend y abrirlo      | No           |
| **API Integrations**    | Datáfonos físicos conectados a app        | No           |
| **API Pagos en Línea**  | Captura propia (requiere aprobación Bold) | Sí           |

> ⚠️ Para este proyecto usar **API Link de Pagos** desde Node.js.  
> El link generado se abre en Flutter con `url_launcher` o `WebView`.

---

## Autenticación

### Llaves necesarias

- **Llave de identidad** (API key): pública, se envía en headers. Identifica el comercio.
- **Llave secreta**: privada, se usa SOLO en servidor para generar el hash SHA256. Nunca exponerla en Flutter.

### Dónde obtenerlas

Panel Bold → Integraciones → Llaves de integración → Botón de pagos → Activar llaves.

Existen dos pares: **pruebas** y **producción**. Nunca mezclar llaves de ambientes distintos.

### Header de autenticación

```http
Authorization: x-api-key <llave_de_identidad>
Content-Type: application/json
```

---

## Flujo principal: API Link de Pagos

```
Flutter                Node.js (CF)             Bold API
  |                        |                       |
  |-- POST /crearPago ----->|                       |
  |                        |-- POST /online/link/v1 ->|
  |                        |<-- { url, payment_link } |
  |<-- { boldUrl } --------|                       |
  |                        |                       |
  |-- abre boldUrl (WebView/url_launcher)           |
  |                        |                       |
  |   [usuario paga]        |                       |
  |                        |<-- Webhook POST -------|
  |                        | (estado transacción)  |
  |                        |-- actualiza Firestore  |
  |<-- FCM notificación ----|                       |
```

---

## Endpoint: Crear Link de Pago

```
POST https://integrations.api.bold.co/online/link/v1
Authorization: x-api-key <llave_de_identidad>
```

### Body (monto fijo / CLOSE)

```json
{
  "amount_type": "CLOSE",
  "amount": {
    "currency": "COP",
    "total_amount": 150000,
    "tip_amount": 0,
    "taxes": []
  },
  "description": "Arriendo terreno - Ref TERR-001",
  "reference": "TERR-001-1712345678",
  "expiration_date": 1712432078000000000,
  "callback_url": "https://tu-app.com/pago/resultado"
}
```

> `reference`: alfanumérico, guiones permitidos, máx 60 chars.  
> Añadir timestamp en nanosegundos al reference para evitar duplicados.  
> `expiration_date`: nanosegundos desde epoch Unix.

### Body (monto abierto / OPEN)

```json
{
  "amount_type": "OPEN",
  "description": "Arriendo terreno",
  "reference": "TERR-001-1712345678"
}
```

### Respuesta exitosa (HTTP 201)

```json
{
  "payload": {
    "payment_link": "LNK_H7S4xxx",
    "url": "https://checkout.bold.co/LNK_H7S4xxx"
  },
  "errors": []
}
```

---

## Endpoint: Consultar estado del Link

```
GET https://integrations.api.bold.co/online/link/v1/{payment_link}
Authorization: x-api-key <llave_de_identidad>
```

Campos relevantes en respuesta:

- `payment_status`: estado actual (puede no ser definitivo justo después del pago)
- `amount_type`: OPEN o CLOSE
- `is_sandbox`: boolean

---

## Hash de Integridad (Botón de Pagos manual)

> Solo necesario si usas el Botón JS con monto fijo. Para API Link no aplica.

```js
// SOLO ejecutar en servidor (Node.js), nunca en cliente
const crypto = require("crypto");

function generarHashIntegridad(orderId, amount, currency, secretKey) {
  const cadena = `${orderId}${amount}${currency}${secretKey}`;
  return crypto.createHash("sha256").update(cadena).digest("hex");
}
```

---

## Webhook: Recibir notificaciones de pago

### Configuración

Panel Bold → Integraciones → Webhook → agregar URL del endpoint.  
El endpoint debe aceptar `POST` con body JSON.

### Cloud Function receptor (Node.js)

```js
exports.boldWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") return res.status(405).end();

  const evento = req.body;
  // Estructura del evento varía según método de pago
  // Campos comunes: transaction_id, payment_status, reference, amount

  const { reference, payment_status, transaction_id } = evento;

  // Buscar reserva por reference en Firestore
  const snap = await db
    .collection("reservas")
    .where("boldReference", "==", reference)
    .limit(1)
    .get();

  if (!snap.empty) {
    const doc = snap.docs[0];
    await doc.ref.update({
      estadoPago: payment_status, // APPROVED | REJECTED | FAILED
      boldTransactionId: transaction_id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (payment_status === "APPROVED") {
      // Cambiar estado del terreno a 'reservado'
      await db.collection("terrenos").doc(doc.data().terrenoId).update({
        estado: "reservado",
      });
      // Enviar FCM al arrendador
    }
  }

  res.status(200).json({ received: true });
});
```

### Estados de pago posibles

| Estado     | Significado            |
| ---------- | ---------------------- |
| `APPROVED` | Pago exitoso           |
| `REJECTED` | Rechazado por banco    |
| `FAILED`   | Error técnico          |
| `PENDING`  | En proceso (PSE/Nequi) |

---

## Consultar notificación de webhook por referencia

```
GET https://integrations.api.bold.co/payments/webhook/notifications/{reference}?is_external_reference=true
Authorization: x-api-key <llave_de_identidad>
```

Útil para reconciliación o si el webhook no llegó.

---

## Implementación en Flutter

Bold NO tiene SDK oficial para Flutter. Estrategia recomendada:

### Opción A: url_launcher (más simple)

```dart
// pubspec.yaml
// url_launcher: ^6.2.0

import 'package:url_launcher/url_launcher.dart';

Future<void> abrirPasarelaBold(String boldUrl) async {
  final uri = Uri.parse(boldUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
```

### Opción B: WebView embebido (mejor UX)

```dart
// pubspec.yaml
// webview_flutter: ^4.4.0

import 'package:webview_flutter/webview_flutter.dart';

class PasarelaBoldScreen extends StatefulWidget {
  final String boldUrl;
  const PasarelaBoldScreen({required this.boldUrl});

  @override
  State<PasarelaBoldScreen> createState() => _PasarelaBoldScreenState();
}

class _PasarelaBoldScreenState extends State<PasarelaBoldScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          // Detectar redirect de callback_url para saber que terminó
          if (request.url.contains('/pago/resultado')) {
            Navigator.pop(context);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.boldUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago seguro')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
```

---

## Ambiente de pruebas

- Usar llaves de **pruebas** (par distinto al de producción).
- Las transacciones en modo prueba NO envían webhooks automáticamente.
- Para probar webhook: finalizar compra → botón "Probar el webhook" en la pasarela.
- Referencias de prueba se eliminan a las 12 horas.
- Datos de tarjeta de prueba: ver https://developers.bold.co/pagos-en-linea/boton-de-pagos/ambiente-pruebas

---

## Variables de entorno requeridas (Cloud Functions)

```bash
# .env o Firebase Functions Config
BOLD_API_KEY=tu_llave_de_identidad
BOLD_SECRET_KEY=tu_llave_secreta          # Nunca en cliente
BOLD_ENV=sandbox                           # sandbox | production
BOLD_BASE_URL=https://integrations.api.bold.co
```

```js
// functions/config/bold.js
module.exports = {
  apiKey: process.env.BOLD_API_KEY,
  secretKey: process.env.BOLD_SECRET_KEY,
  baseUrl: process.env.BOLD_BASE_URL || "https://integrations.api.bold.co",
  isSandbox: process.env.BOLD_ENV === "sandbox",
};
```

---

## Errores comunes y solución

| Error                                | Causa                                                | Solución                                                  |
| ------------------------------------ | ---------------------------------------------------- | --------------------------------------------------------- |
| `Integrity key doesn't match`        | Hash SHA256 incorrecto                               | Verificar orden: orderId+amount+currency+secretKey        |
| `The reference has been used before` | Reference duplicada                                  | Añadir timestamp al reference                             |
| `401 Unauthorized`                   | API key incorrecta o de ambiente distinto            | Verificar que pruebas usa llaves de pruebas               |
| Webhook no llega                     | En sandbox los webhooks no se envían automáticamente | Usar botón "Probar webhook" al finalizar compra de prueba |

---

## Checklist de implementación

- [ ] Obtener llaves de prueba desde panel Bold
- [ ] Crear Cloud Function `crearLinkPago` que llama a `/online/link/v1`
- [ ] Crear Cloud Function `boldWebhook` como endpoint POST
- [ ] Registrar URL del webhook en panel Bold → Integraciones
- [ ] Implementar lógica de actualización de Firestore al recibir `APPROVED`
- [ ] Implementar pantalla WebView en Flutter para abrir el link
- [ ] Detectar `callback_url` en WebView para cerrar la pantalla al terminar
- [ ] Probar flujo completo en sandbox antes de solicitar llaves de producción
- [ ] Solicitar activación de llaves de producción a Bold (requiere revisión del equipo Bold)
