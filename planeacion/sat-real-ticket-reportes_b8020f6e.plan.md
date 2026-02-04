---
name: SAT-real-ticket-reportes
overview: Plan para completar primero Facturación SAT real, después impresión física de tickets y finalmente reforzar reportes, alineado al documento YOMYOM y a la implementación actual (FastAPI + PostgreSQL + React).
todos:
  - id: sat-01-elegir-pac
    content: Definir PAC/CFDI objetivo y modalidad (API, sandbox/prod).
    status: pending
  - id: sat-02-credenciales
    content: Reunir certificados CSD/credenciales y configurar variables/secretos.
    status: pending
  - id: sat-03-adaptador-pac
    content: Implementar adaptador PAC real en `facturacion_service.py` con manejo de errores y almacenamiento XML/PDF.
    status: pending
  - id: sat-04-uat
    content: Ejecutar UAT de timbrado/cancelación (ventas cerradas) y documentar evidencias.
    status: pending
  - id: ticket-01-hardware
    content: Definir impresora y canal (USB/LAN/Bluetooth) + requerimientos de corte/caja.
    status: pending
  - id: ticket-02-impresion
    content: Implementar impresión física (ESC/POS o puente) usando ticket texto/HTML.
    status: pending
  - id: ticket-03-uat
    content: "UAT impresión: ticket normal + ticket con mayoreo + ticket con QR."
    status: pending
  - id: rep-01-salidas-venta
    content: Asegurar salidas por venta en reporte de movimientos (registrar o derivar de `venta_detalle`).
    status: pending
  - id: rep-02-mermas
    content: Separar ventas vs mermas/ajustes en reportes de movimientos.
    status: pending
  - id: rep-03-mensual-egresos
    content: Si se requiere, implementar egresos/costos y reporte mensual ingreso vs egreso.
    status: pending
---

## Objetivo
Dejar el sistema en cumplimiento operativo del documento, priorizando: **SAT real** → **ticket físico** → **reportes**, con criterios de aceptación y pruebas UAT.

## Supuestos actuales (bloqueantes)
- PAC: **aún no definido**.
- Certificados/credenciales: **aún no disponibles**.
- Impresora: **aún no definida**.

## Fase 1 — Facturación SAT real (prioridad 1)
- **1. Selección de PAC y modalidad**
  - Elegir PAC (Finkok/SW/Diverza/otro) y si será timbrado por API REST/SOAP.
  - Definir CFDI objetivo (típicamente 4.0), catálogos mínimos y reglas de cancelación.
- **2. Gestión de certificados y accesos**
  - Recolectar CSD (archivos .cer/.key), contraseña, RFC emisor, régimen fiscal, serie/folio.
  - Obtener credenciales de PAC (sandbox y/o productivo).
- **3. Definir modelo mínimo de datos SAT y mapping**
  - Confirmar campos faltantes a persistir (ej. receptor: nombre/CP/uso_cfdi/regimen; emisor: regimen; forma/metodo pago; moneda; exportación; etc.).
  - Alinear con tablas actuales (`facturas`, `factura_ventas`, `folios_sat`) + migración adicional si faltan campos obligatorios.
- **4. Implementar adaptador real de PAC**
  - Reemplazar/expandir el stub actual en `backend/app/services/facturacion_service.py` (`PACAdapter`) por un adaptador por proveedor.
  - Manejar:
    - **Timbrado**: request/response, UUID, XML timbrado, PDF (si aplica) y almacenamiento.
    - **Cancelación**: motivo SAT, acuse, transición de estado.
    - **Errores**: códigos PAC/SAT, reintentos, estados intermedios.
- **5. Endpoints y flujo UAT**
  - Validar flujo completo con `/api/v1/facturas`:
    - crear borrador → timbrar → obtener → cancelar.

### Criterios de aceptación (SAT real)
- Se timbra una factura con PAC y se obtiene **UUID real**.
- Se guarda **XML timbrado** (y PDF si el PAC lo entrega) y se pueden recuperar por API.
- La cancelación genera acuse y cambia el estado.

### Pruebas UAT (SAT real)
- Caso 1: Venta cerrada → factura individual → timbrar OK.
- Caso 2: Cancelación con motivo 02 → estado CANCELADA + acuse.
- Caso 3: Error PAC (credencial/cert) → API responde error entendible sin 500.

## Fase 2 — Ticket físico (prioridad 2)
- **1. Definir hardware y canal**
  - Elegir impresora (USB Windows vs LAN ESC/POS vs Bluetooth) y modelo.
- **2. Implementación de impresión**
  - Mantener `TicketService` (HTML/Texto) y agregar un camino de impresión “1 clic” según hardware:
    - **USB Windows**: imprimir desde navegador (CSS print) o app puente (si se requiere corte/apertura caja).
    - **LAN/Bluetooth ESC/POS**: servicio de impresión (backend o agente local) enviando comandos ESC/POS.
- **3. Funciones mínimas**
  - Selección de impresora (si aplica), corte, reintentos/cola básica.
  - Impresión de ticket con totales y QR (si el flujo de facturación lo requiere).

### Criterios de aceptación (ticket físico)
- Al cerrar una venta, el usuario puede imprimir ticket físico con formato 80mm.
- Si es ESC/POS: corte automático.

### Pruebas UAT (ticket físico)
- Venta con 1–3 ítems → imprimir ticket → verificar totales, fecha, método pago.
- Venta con >=12 piezas misma variante → verificar precio mayoreo reflejado.

## Fase 3 — Reportes (prioridad 3)
- **1. Reporte de movimientos: “salidas por venta”**
  - Asegurar que el reporte de movimientos incluya salidas por venta (ya sea registrando movimientos al vender o derivando desde `venta_detalle`).
- **2. Reporte de mermas/ajustes vs ventas**
  - Separar SALIDA por venta vs SALIDA por merma/ajuste.
- **3. Reporte general mensual (si el documento exige egresos/costos)**
  - Si el cliente requiere egresos: modelar y capturar egresos + comparativa ingresos vs egresos.

### Criterios de aceptación (reportes)
- Reporte de movimientos muestra salidas por venta y salidas manuales diferenciadas.
- Reporte mensual cuadra con ventas del periodo y (si aplica) egresos.

## Archivos clave a tocar (referencia)
- Backend:
  - `backend/app/services/facturacion_service.py` (reemplazar stub PAC).
  - `backend/app/api/v1/facturas.py` (flujo y validaciones).
  - `backend/app/services/ticket_service.py` (formato + puente de impresión según hardware).
  - `backend/app/services/reporte_service.py` (movimientos/ventas/mensual).
  - `migrations/` (nueva migración si SAT exige campos extra).
- Frontend:
  - `frontend/src/services/apiService.js` y páginas de Facturación/POS para UX de timbrado e impresión.

## Entregables
- SAT real funcional (sandbox y luego prod).
- Impresión física operativa en caja.
- Reportes con trazabilidad completa de salidas.