# GUIA DE PROMPT OPERATIVO PARA SUPERVISION

## Objetivo

Este documento define la mejor forma de pedirle trabajo al agente para ejecutar el plan del proyecto CowBnB con bajo riesgo de fallos, máximo contexto y control de calidad.

Se usa junto con:

- IMPLEMENTATION_PLAN.md

---

## 1. Enfoque recomendado

Para minimizar errores, usar siempre 2 fases separadas:

1. Fase Plan
2. Fase Ejecucion

No mezclar ambas en un mismo mensaje largo.

Adicionalmente, para reducir alucinacion en tareas grandes:

- Usar un orquestador principal.
- Dividir trabajo en subagentes especializados.
- Consolidar resultados con verificacion cruzada antes de editar.

---

## 1.1 Patron Orquestador + Subagentes

Regla principal:

- Nunca depender de un solo agente para tareas de alcance amplio.

Rol del orquestador:

- Define alcance exacto.
- Lanza subagentes por objetivo.
- Compara salidas entre subagentes.
- Marca contradicciones y obliga revalidacion en repo.
- Solo entonces autoriza cambios o cierre.

Modelo recomendado:

- Pedir siempre el modelo mas actualizado disponible.
- En este entorno, referencia operativa: GPT-5.3-Codex.

Si el entorno solo expone un subagente generico (por ejemplo Explore), se usa varias veces con prompts diferentes, simulando especializaciones por rol.

Subagentes recomendados por rol:

1. Discovery Agent

- Objetivo: inventario real de archivos, rutas, contratos y estados.

2. Architecture Agent

- Objetivo: validar diseno tecnico contra IMPLEMENTATION_PLAN.md.

3. Security Agent

- Objetivo: revisar reglas, ownership, secretos, idempotencia, tokens.

4. Data Agent

- Objetivo: colecciones, indices, queries y consistencia transaccional.

5. QA Agent

- Objetivo: criterios de done, pruebas minimas y riesgos de regresion.

Salida minima exigida al orquestador:

- Hallazgos por subagente.
- Conflictos detectados entre subagentes.
- Decisiones finales con justificacion.
- Lista de acciones ejecutables (sin ambiguedad).

---

## 2. Que adjuntar en el chat

Adjuntos minimos para cada corrida:

- IMPLEMENTATION_PLAN.md
- Estructura de carpetas actualizada del repo
- Archivo de reglas si existe: firestore.rules
- Archivo de indices si existe: firestore.indexes.json
- Captura de errores actuales (si hay)

Adjuntos recomendados por modulo:

- Auth: paginas de registro/login y router
- Terrenos: create_listing_page, map_discovery_page, listing_details_page
- Pagos: checkout_page y cualquier servicio de reservas
- Satelital: archivos del job NDVI y funciones satelitales

Si no adjuntas algo clave, el agente puede asumir contexto incompleto.

---

## 3. Prompt maestro para Fase Plan

Copia y pega este bloque cuando quieras que el agente solo planifique una etapa concreta.

TITULO: FASE PLAN - SIN IMPLEMENTAR

CONTEXTO:

- Producto: CowBnB, plataforma de arriendo de terrenos para pastoreo de ganado.
- No es marketplace abierto.
- Fuente de verdad funcional: IMPLEMENTATION_PLAN.md.
- Modo de trabajo: orquestador + subagentes (no agente unico).
- Modelo: usar el mas actualizado disponible (referencia operativa: GPT-5.3-Codex).

OBJETIVO DE ESTA SESION:

- Planificar el modulo: [NOMBRE_MODULO].
- No escribir codigo.
- No crear ni modificar archivos de implementacion.

INSTRUCCIONES OBLIGATORIAS:

1. Lee primero IMPLEMENTATION_PLAN.md completo.
2. Lanza subagentes por rol: Discovery, Architecture, Security, Data, QA.
3. Explora el repo para confirmar estado actual real.
4. Si algo no existe, escribir exactamente: NO ENCONTRADO.
5. No inventar rutas, clases, endpoints ni campos.
6. Resolver contradicciones entre subagentes antes de responder.
7. Entregar salida en este formato:
   - Alcance del modulo
   - Dependencias previas
   - Archivos a crear/modificar
   - Contratos de entrada/salida
   - Riesgos y mitigaciones
   - Criterios de done
   - Checklist de supervision
   - Hallazgos por subagente y consolidacion final

REGLAS:

- No implementar.
- No resumir en abstracto.
- Ser especifico con archivos y decisiones tecnicas.

ENTRADA ADJUNTA:

- IMPLEMENTATION_PLAN.md
- [LISTA_DE_ARCHIVOS_ADICIONALES]

---

## 4. Prompt maestro para Fase Ejecucion

Copia y pega este bloque cuando quieras que el agente implemente un alcance ya aprobado.

TITULO: FASE EJECUCION - IMPLEMENTAR SOLO ALCANCE APROBADO

CONTEXTO:

- Producto: CowBnB, plataforma de arriendo de terrenos para pastoreo.
- No es marketplace abierto.
- Fuente de verdad: IMPLEMENTATION_PLAN.md.
- Alcance aprobado: [PEGAR_SCOPE_APROBADO].
- Modo: orquestador + subagentes por dominio.
- Modelo: usar el mas actualizado disponible (referencia operativa: GPT-5.3-Codex).

MODO DE TRABAJO:

1. Primero relee IMPLEMENTATION_PLAN.md.
2. Lanza subagentes: Discovery (estado actual), Security (riesgos), Data (indices/queries), QA (pruebas).
3. Verifica archivos existentes antes de editar.
4. Implementa en pasos pequenos y verificables.
5. Despues de cada bloque, corre validaciones o pruebas relevantes.
6. Si falta informacion, decide de forma conservadora y documenta la decision.
7. Si hay conflicto entre subagentes, detener bloque, resolver con evidencia del repo y continuar.

INSTRUCCIONES TECNICAS:

- Mantener compatibilidad con rutas actuales del frontend.
- No romper flujo owner/renter.
- Usar estados canonicos de terreno: disponible, reservado, en_espera, inactivo.
- No exponer secretos ni tokens en logs.
- Webhook de pagos debe ser idempotente.
- Tokens de accion deben ser one-time y almacenados en hash.

FORMATO DE ENTREGA EN CADA RESPUESTA:

- Cambios realizados
- Archivos tocados
- Validaciones ejecutadas
- Riesgos abiertos
- Siguiente paso inmediato

CONDICION DE PARADA:

- Detenerse solo cuando se cumpla el criterio de done del alcance aprobado.
- No cerrar sin checklist de subagentes y consolidacion del orquestador.

ENTRADA ADJUNTA:

- IMPLEMENTATION_PLAN.md
- [ARCHIVOS_DEL_MODULO]

---

## 5. Prompt para modo Auditoria (supervision de tercero)

Usa este prompt cuando otra persona implemento y tu quieres auditar calidad.

TITULO: AUDITORIA TECNICA CONTRA PLAN

CONTEXTO:

- Revisa la implementacion realizada por tercero.
- Compara contra IMPLEMENTATION_PLAN.md.

TAREA:

1. Detectar incumplimientos funcionales.
2. Detectar riesgos de seguridad y regresiones.
3. Validar indices y reglas Firestore requeridas.
4. Validar criterios de done por modulo.

FORMATO DE SALIDA OBLIGATORIO:

- Hallazgos criticos
- Hallazgos altos
- Hallazgos medios
- Hallazgos bajos
- Lista de bloqueantes para aprobar
- Lista de mejoras no bloqueantes

REGLAS:

- Citar archivo exacto por hallazgo.
- No proponer reescritura completa si hay arreglo puntual.
- Si no hay hallazgos, decir explicitamente: Sin hallazgos bloqueantes.

---

## 6. Guia de permisos para Modo Agente

Cuando abras sesion para ejecucion real, define de entrada:

- Permiso de lectura completo del repo.
- Permiso para editar archivos del modulo objetivo.
- Permiso para correr comandos de validacion.
- Permiso para crear archivos nuevos necesarios del alcance.
- Permiso para lanzar subagentes de exploracion y auditoria tecnica.

Evitar permisos excesivos si no son necesarios para la etapa.

Permisos minimos recomendados para modo orquestador:

- Lectura total del repo.
- Escritura solo en paths del modulo activo.
- Ejecucion de pruebas/lint solo del modulo activo.
- Permiso de subagentes en modo read-only para discovery/auditoria.

---

## 7. Orden recomendado por modulo

Para reducir fallos por dependencias, seguir este orden:

1. Fundacion backend y convenciones compartidas
2. Auth
3. Terrenos CRUD + estados canonicos
4. Imagenes
5. Reservas y pagos
6. Mensajeria
7. Satelital NDVI
8. Reviews
9. Recomendaciones
10. Endurecimiento final de reglas e indices

No saltar pagos antes de tener Terrenos y Reservas base.

---

## 8. Plantilla de mensaje corto para abrir cada sesion

Sesion: [PLAN o EJECUCION o AUDITORIA]
Modulo: [NOMBRE]
Objetivo puntual: [1 frase]
Restricciones: no inventar, no romper rutas actuales, seguir IMPLEMENTATION_PLAN.md
Modo: ORQUESTADOR
Subagentes a lanzar:

- Discovery Agent
- Architecture Agent
- Security Agent
- Data Agent
- QA Agent
  Modelo solicitado: mas actualizado disponible (referencia: GPT-5.3-Codex)
  Adjuntos:
- IMPLEMENTATION_PLAN.md
- [archivo 1]
- [archivo 2]
  Done esperado:
- [criterio 1]
- [criterio 2]

---

## 9. Checklist de calidad antes de cerrar una tarea

Checklist funcional:

- Se cumple el alcance exacto pedido.
- No se implementaron extras no solicitados.
- Se mantuvo el modelo de plataforma de arriendo (no marketplace abierto).

Checklist tecnico:

- Sin secretos en codigo ni logs.
- Sin hardcodes sensibles.
- Estados canonicos consistentes.
- Validaciones y errores claros.

Checklist de datos:

- Reglas Firestore coherentes con ownership.
- Indices necesarios declarados.
- Operaciones criticas en transaccion cuando aplica.

Checklist de supervision:

- Cambios listados con claridad.
- Pruebas o validaciones reportadas.
- Riesgos abiertos documentados.

---

## 10. Anti-fallos: reglas de oro

- Una sesion, un objetivo.
- Siempre adjuntar IMPLEMENTATION_PLAN.md.
- Primero pedir plan, luego ejecutar.
- Siempre usar orquestador con subagentes; evitar agente unico en tareas grandes.
- No mezclar multiples modulos grandes en una sola corrida.
- Si aparece ambiguedad, forzar decision conservadora y documentarla.
- Si algo no existe en repo, marcar NO ENCONTRADO.

---

## 11. Ejemplo rapido de uso real

Paso 1: Plan de modulo pagos

- Abrir chat nuevo.
- Adjuntar IMPLEMENTATION_PLAN.md y checkout_page.
- Usar prompt de Fase Plan con modulo RESERVAS/PAGOS.
- Revisar y aprobar alcance.

Paso 2: Ejecucion de modulo pagos

- Abrir chat nuevo.
- Adjuntar IMPLEMENTATION_PLAN.md y archivos backend pagos.
- Usar prompt de Fase Ejecucion con el alcance aprobado.
- Exigir reporte por bloques con validaciones.

Paso 3: Auditoria

- Abrir chat nuevo.
- Adjuntar diff o archivos cambiados + plan.
- Usar prompt de Auditoria.
- Aprobar solo si no hay hallazgos bloqueantes.

---

## 12. Nota para supervision

Si tu objetivo es delegar al 100 por ciento, usa siempre este flujo:

1. Plan (obligatorio)
2. Ejecucion controlada por alcance
3. Auditoria contra plan

Ese ciclo reduce alucinaciones, evita cambios fuera de scope y mejora trazabilidad de decisiones.
