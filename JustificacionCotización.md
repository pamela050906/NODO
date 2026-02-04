# Justificación de cotización por módulo (implementación gradual)

Este documento fija un **precio profesional y justo** para implementar el **módulo 2.1** de forma individual, incluyendo el porqué del costo (alcance, complejidad, riesgos y estado actual del sistema).

> **Moneda**: MXN (pesos mexicanos) + IVA  
> **Base técnica observada**: FastAPI (backend) + React (frontend) con endpoints ya existentes para POS/ventas/tickets, facturación y cobranza.

---

## Módulo 2.1 — Portal de ventas (POS mostrador)

### Alcance solicitado (según tus imágenes)
Funcionalidades del área de venta en mostrador:

- **Conexión con caja (cajón/caja registradora)** al momento de realizar una venta en efectivo.
- **Conexión de lector RF / escáner** para lectura de códigos de barra.
- **Conexión con impresora de tickets** para cierre de ventas y entrega de comprobante.
- **Facturación (conexión a plataforma SAT)** para emitir facturas en tienda respetando folios/series.
- **Generación de QR para facturación** impreso en el ticket.
- **Programa de cobranza** operando junto con caja/impresora/lector; opción de cobro en tarjeta o efectivo; generación de ticket.
- **Lectura automática de precio menudeo/mayoreo** (regla indicada: a partir de 12 productos).
- **Campo para entrada manual de cantidades** (cuando se compran muchas piezas con el mismo código).

---

## Estado actual en el sistema (qué ya está y qué falta)

### Lo que ya está implementado (base existente)
- **Escaneo/lectura por código de barras (POS)**: existe endpoint `GET /api/v1/pos/barcode/{codigo}` (backend) y uso desde `frontend/src/pages/POS.js`.
- **Flujo de ventas**: endpoints para crear venta, agregar ítems, cerrar/cancelar y listar (`/api/v1/ventas`).
- **Precio automático menudeo/mayoreo (regla ≥ 12)**: la base de datos incluye trigger `fn_precio_automatico()` que, al insertar en `venta_detalle`, asigna `precio_mayoreo` cuando `cantidad >= 12` (si no, `precio_menudeo`).
- **Descuento automático de stock post‑venta**: la base de datos incluye trigger `fn_descuento_inventario()` que descuenta inventario y registra `movimientos_inventario` tipo `SALIDA` con referencia a la venta.
- **Ticket**:
  - Generación de ticket **HTML + texto** y **QR base64** (`/api/v1/ventas/{venta_id}/ticket`).
  - En frontend se imprime con `window.print()` (funciona con impresoras configuradas en el SO/navegador).
- **Facturación**:
  - Endpoints y UI para crear borrador, timbrar, cancelar y factura global de tarjetas (`/api/v1/facturas`, `frontend/src/pages/Facturacion.js`).
- **Cobranza**:
  - Endpoints y UI para cuentas por cobrar y registrar pagos (`/api/v1/cobranza`, `frontend/src/pages/Cobranza.js`).
- **Entrada manual de cantidades**: el POS ya permite capturar cantidad en UI.

### Brechas detectadas (por las que *aún no está “listo”* el módulo 2.1)
- **Integración real con SAT/PAC**: el `PACAdapter` actual es un **stub** (simulación). Para operación real se requiere integración con un PAC (Finkok/Diverza/SW, etc.), certificados, manejo de errores SAT, resguardo de XML/PDF, etc.
- **Regla menudeo/mayoreo y “acumulado”**: aunque la BD ya aplica **≥12 por línea** vía trigger, falta confirmar/ajustar el comportamiento final de negocio (por ejemplo: acumulado por ticket, por producto, por variante, o parametrizable) y alinear backend/frontend/BD para que sea consistente y testeado.
- **Conexión “con caja/cajón”**: no hay integración directa con cajón de dinero (hardware). En web puro normalmente no se puede abrir cajón sin puente (driver/servicio local) o app de escritorio.
- **Cobranza integrada al flujo de caja**: existe como módulo separado; falta “amarrarlo” al flujo POS (por ejemplo: cerrar venta a crédito, imprimir ticket de crédito/abono, y registrar pagos desde caja).
- **Riesgos de calidad**: detecté al menos un error de implementación en router de ventas (parámetro/variable), lo que sugiere que falta pasada de QA integral del flujo POS.

**Conclusión de readiness**: el módulo 2.1 está **parcialmente implementado (base funcional)**, pero **no está listo para operación real** de mostrador “con hardware + SAT” hasta completar las brechas anteriores.

---

## Cotización propuesta (precio profesional y justo)

### Precio del módulo 2.1
**$360,000 MXN + IVA**

Este precio considera que ya existe una base importante, pero el salto a “producción de mostrador” implica trabajo especializado en: **timbrado real SAT (PAC)**, **reglas de precio mayoreo/menudeo**, **flujo de cobranza en caja**, **impresión robusta**, y (si aplica) **puente de hardware** para cajón/impresora.

---

## ¿Por qué este costo? (justificación técnica y de riesgo)

### Factores que más pesan (lo más caro/arriesgado)
- **SAT/PAC (timbrado real)**: no es solo “pegarle a una API”; implica cumplimiento CFDI, manejo de catálogos, folios/series, cancelaciones, reintentos, resguardo de evidencias (XML), y escenarios de error en producción. Es el principal driver de costo/tiempo.
- **Hardware (cajón/impresora)**: cada modelo/driver cambia el enfoque. En web suele requerir **servicio local** o **app de escritorio** (Electron/.NET) para ESC/POS o drivers. Esto agrega complejidad operativa.
- **Reglas comerciales de precio (menudeo/mayoreo)**: la regla “a partir de 12” debe definirse con precisión (por producto, por ticket, por variante, por acumulado del día, etc.) y debe quedar parametrizable y testeada.
- **Calidad/operación en caja**: un POS requiere estabilidad, baja fricción, atajos, manejo de concurrencia y stock, y pruebas tipo “caja real” (impresión, cortes, cierres).

---

## Desglose estimado de esfuerzo (para respaldar el precio)

> Tarifa de referencia: **$900 MXN/h** (perfil senior full‑stack + integración)  
> Incluye: análisis, desarrollo, QA, documentación y acompañamiento de salida.

| Componente | Entregable | Estimación |
|---|---|---:|
| POS caja (flujo robusto) | Correcciones, estabilidad, estados de venta, UX de caja | 60 h |
| Regla menudeo/mayoreo (≥12) | Motor de precios parametrizable + pruebas | 50 h |
| Ticket e impresión | Formato térmico, QR estable, compatibilidad impresión | 35 h |
| Cobranza integrada en caja | Venta crédito + pagos + ticket/abonos | 55 h |
| SAT/PAC real | Integración PAC, timbrado/cancelación, almacenamiento, validaciones | 130 h |
| “Conexión con caja/cajón” | Propuesta + implementación (puente local si aplica) | 45 h |
| QA integral + documentación | Casos de caja, guías operativas, smoke tests | 25 h |
| **Subtotal** |  | **400 h** |
| Ajuste por base existente + eficiencia (ya hay endpoints/UI) | descuento aplicado | **-40 h** |
| Contingencia (riesgo SAT/hardware) | ~10% | **+40 h** |
| **Total estimado** |  | **400 h** |

400 h × $900 MXN/h = **$360,000 MXN**

---

## Supuestos y exclusiones (para que el precio sea “justo”)

- **Incluye**:
  - Entregar el módulo 2.1 operable en ambiente de staging/producción con configuración documentada.
  - 1 flujo POS (escaneo, cantidades, cierre/cancelación), ticket con QR, cobranza operable, y facturación SAT timbrada con PAC.
- **No incluye** (se cotiza aparte si aplica):
  - **Costo del PAC**, certificados CSD, renovación, y cualquier comisión por timbre.
  - Compra/configuración física de hardware (cajón, impresoras, lectores) y visitas on‑site.
  - Integración con “terminal bancaria” (cobro real con adquirente); aquí se contempla **registro de método TARJETA** y conciliación básica, no procesamiento de pagos.
- **Dependencias del cliente**:
  - Definir PAC a usar, proveer credenciales/certificados, datos fiscales del emisor, y reglas exactas de mayoreo/menudeo (interpretación final).

---

## Resultado esperado del módulo 2.1 (criterios de “listo”)
- POS permite venta rápida con escáner, cantidades, cierre/cancelación, y ticket imprimible estable.
- QR en ticket dirige a URL configurable de facturación.
- Facturación: crear borrador, timbrar y cancelar con PAC real; control de folios/series; PDF/XML accesibles.
- Cobranza: cuentas por cobrar y pagos desde caja con trazabilidad.
- Regla menudeo/mayoreo aplicada automáticamente conforme a la regla acordada.
- Documentación operativa y técnica mínima para soporte.

---

## Siguiente paso
Abajo agrego el **módulo 2.2**. Cuando me compartas el **módulo 2.3**, lo incorporo y al final cierro una **cotización total** adecuada para una empresa pequeña en México (2026).

---

## Módulo 2.2 — Programa de control de stock (almacén)

### Alcance solicitado (según tus imágenes)
- **Carga por “layout”** de productos que entran a tienda, actualizando cantidades y reflejando salidas por ventas.
- **Reporte semanal y mensual** de productos que salen (más vendidos) y necesidades de **restock**.
- **Variantes de producto** (talla, color) para catálogo.
- **Carga de precios** (menudeo y mayoreo) por producto/variante.
- **Disminución automática de stock post venta**.
- **Sistema centralizado** para control de stock (acceso desde tienda y dispositivos de administradores).
- **Entrada/registro manual de nuevos productos**.
- **Generación de códigos de barra** por producto/variante.

---

## Estado actual en el sistema (qué ya está y qué falta)

### Lo que ya está implementado (base existente)
- **Catálogo con variantes**:
  - Endpoints para **crear producto** y **crear variante** con `talla`, `color`, `precio_menudeo`, `precio_mayoreo`, `codigo_barras` (`/api/v1/productos`, `/api/v1/productos/variantes`).
  - UI base en `frontend/src/pages/Almacen.js` (sección Productos) y en pantallas de productos.
- **Carga masiva tipo “layout”**:
  - Endpoint `POST /api/v1/productos/carga-masiva` que recibe **CSV** con columnas esperadas (nombre, categoría, SKU, código de barras, precios, stock inicial, etc.).
  - UI para subir archivo desde `Almacen` (input `.csv`).
- **Control de stock centralizado**:
  - Endpoint `GET /api/v1/inventario/stock` y UI “Stock” en `Almacen`.
  - Endpoint `GET /api/v1/inventario/stock/bajo` (umbral 10) para identificar faltantes.
- **Disminución automática post venta**:
  - Trigger `fn_descuento_inventario()` descuenta stock y registra movimiento `SALIDA` al insertarse `venta_detalle`.
- **Reportes**:
  - Reporte de almacén (`GET /api/v1/reportes/almacen`) y exportación CSV.
  - Reporte de movimientos (`GET /api/v1/reportes/movimientos`).
  - Reporte mensual general (`GET /api/v1/reportes/general/{mes}/{anio}`) con **Top 10** productos por cantidad.

### Brechas detectadas (por las que *aún no está “listo”* el módulo 2.2)
- **“Layout” en Excel/XLSX**: actualmente la carga masiva está diseñada para **CSV**; si el negocio requiere Excel (muy común), faltaría importador XLSX, validación de plantilla y reporte de errores amigable.
- **UI/flujo incompleto en almacén**:
  - `Almacen.js` muestra tabs y botones, pero la pantalla no expone completamente (en UI) la captura de variantes/movimientos y su consulta de forma operativa (requiere cierre de UX y QA).
- **Reporte semanal y “restock” accionable**:
  - Hoy se puede hacer “semanal” por **rango de fechas** (reportes de ventas/movimientos) y “mensual” existe.
  - Falta un reporte específico orientado a compras: sugerencias de reposición (por umbral, promedio de venta, lead time) y/o exportación dedicada por proveedor/categoría si se requiere.
- **Generación de códigos de barra**:
  - El sistema **requiere** `codigo_barras` al crear variante; no existe un generador (secuencial o bajo estándar) ni módulo de impresión de etiquetas.
- **Gobernanza de datos de catálogo**:
  - Falta definir reglas de unicidad/estándar de SKU y código de barras (y si habrá “códigos internos” vs EAN/UPC), para evitar duplicados y problemas en caja.

**Conclusión de readiness**: el módulo 2.2 está **parcialmente implementado** (catálogo, variantes, stock, movimientos, carga CSV y reportes base), pero **no está listo como “almacén operativo completo”** hasta cerrar UI, reportes de reposición y el flujo de generación/etiquetado de códigos.

---

## Cotización propuesta (precio profesional y justo)

### Precio del módulo 2.2
**$225,000 MXN + IVA**

Este precio es menor que el 2.1 porque ya existe buena parte del backend (endpoints, triggers y reportes). El costo se justifica por cerrar “operación real de almacén”: **importación por layout robusta**, **UX completa**, **reportes de restock**, **códigos de barra/etiquetas** y pruebas con datos reales.

---

## Desglose estimado de esfuerzo (para respaldar el precio)

> Tarifa de referencia: **$900 MXN/h** (perfil senior full‑stack)  
> Incluye: análisis, desarrollo, QA, documentación y acompañamiento de salida.

| Componente | Entregable | Estimación |
|---|---|---:|
| Carga por layout robusta | Validaciones, errores por línea, opcional XLSX, reintentos | 55 h |
| Flujo de almacén (UI/UX) | Variantes, movimientos, consulta y filtros, permisos | 65 h |
| Reportes semanal/mensual orientados a compras | Top salidas por periodo + restock (umbrales/insights) + export | 55 h |
| Códigos de barra y etiquetas | Generador + pantalla/plantilla de impresión de etiquetas | 35 h |
| QA + hardening | Pruebas con archivo real, datos sucios, performance básico | 40 h |
| **Total estimado** |  | **250 h** |

250 h × $900 MXN/h = **$225,000 MXN**

---

## Supuestos y exclusiones (para que el precio sea “justo”)
- **Incluye**:
  - Operación diaria de almacén con carga masiva, captura manual, consulta de stock, movimientos y reportes exportables.
  - Generación de código (interno) y flujo de etiquetas (impresión vía navegador / plantilla).
- **No incluye** (se cotiza aparte si aplica):
  - Integración específica con impresora de etiquetas industrial (Zebra, etc.) vía driver/servicio local.
  - Integración con proveedores/órdenes de compra (si se desea un módulo de compras completo).
- **Dependencias del cliente**:
  - Definir si el “layout” será CSV o Excel, y proporcionar plantilla final + 1 ejemplo real.
  - Definir estándar de códigos: EAN/UPC vs interno, y reglas de SKU.

---

## Módulo 2.3 — Programa de reporteo

### Alcance solicitado (según tus imágenes)
El programa debe permitir **desplegar reportes** (ventas, entradas y salidas de mercancía) para trazabilidad de productos vendidos y cantidades que se ingresan al sistema.

Requerimientos clave:
- Reportes **modulares** (seleccionar lapso, filtros, etc.).
- Reportes **semanales y mensuales** en formato que habilite **comparativos y métricas** posteriores.

Reportes requeridos:
- **Reporte de ventas (Área: Ventas)**: ventas vendidas separadas por método de pago, con fecha y estado de facturación (y “a crédito” si aplica).
- **Reporte de almacén (Área: Almacén)**: vista general del stock, con filtros por modo/categoría (ej. playeras, gorras, bolsas, etc.).
- **Reporte de movimientos de inventario (Área: Almacén)**: entradas/salidas/ajustes por periodo y cantidades.
- **Reporte general de ventas (Área: Admin)**: ingresos mensuales, comparativa con otros reportes y visión de rentabilidad/gastos (para prevención y control).

---

## Estado actual en el sistema (qué ya está y qué falta)

### Lo que ya está implementado (base existente)
- **Reportes disponibles en API**:
  - Ventas con filtros de fechas/método de pago y export a CSV (`GET /api/v1/reportes/ventas` y `/ventas/export`).
  - Almacén (existencias + valor inventario) y export a CSV (`GET /api/v1/reportes/almacen` y `/almacen/export`).
  - Movimientos de inventario por periodo (`GET /api/v1/reportes/movimientos`).
  - General mensual con comparativa (mes vs mes anterior) y **Top 10** productos (`GET /api/v1/reportes/general/{mes}/{anio}`).
- **UI de reportes**:
  - Pantalla `frontend/src/pages/Reportes.js` con selector de tipo, filtros por rango de fechas, método de pago y exportación CSV.

### Brechas detectadas (por las que *aún no está “listo”* el módulo 2.3)
- **Modularidad y “biblioteca de métricas”**:
  - Hoy existen reportes, pero falta estandarizar un set de KPIs para que el reporte sea “módulo” (por ejemplo: margen estimado, rotación, contribución por categoría, ticket promedio por punto de venta, etc.) y que sea consistente entre pantallas/export.
- **Comparativos avanzados y trazabilidad**:
  - Ya hay comparativa mensual básica; falta profundizar comparativos (periodo vs periodo, semana a semana, YoY si aplica) y trazabilidad por producto/variante/categoría con drill‑down.
- **Separación “venta a crédito / cobranza” y estado de facturación**:
  - El reporte de ventas ya incluye “facturado” y método de pago; falta incorporar/normalizar “crédito vs contado” como dimensión de análisis y conciliación con cobranza (si se requiere en el reporte 2.3).
- **Calidad de exportables**:
  - CSV existe; falta definir formatos “de negocio” (plantillas) para contabilidad/administración y, si se solicita, PDF/Excel con layout fijo.
- **Gobernanza y roles**:
  - Reforzar permisos y visibilidad por rol (ventas vs almacén vs admin) y bitácora básica de consultas/exportaciones si la empresa lo requiere.

**Conclusión de readiness**: el módulo 2.3 está **mayormente implementado en su base técnica** (API + UI), pero requiere **mejoras para que sea un programa de reporteo empresarial**: KPIs, comparativos, dimensiones (crédito/facturación), formatos de salida y control por rol.

---

## Cotización propuesta (precio profesional y justo)

### Precio del módulo 2.3
**$165,000 MXN + IVA**

El precio se justifica por el trabajo de “pasar de reportes técnicos a reportes de negocio”: definición de KPIs, comparativos, trazabilidad por dimensiones y formatos de exportación listos para administración.

---

## Desglose estimado de esfuerzo (para respaldar el precio)

> Tarifa de referencia: **$900 MXN/h**  
> Incluye: análisis, desarrollo, QA, documentación y acompañamiento de salida.

| Componente | Entregable | Estimación |
|---|---|---:|
| Normalización de KPIs | Definición + endpoints/UI consistentes | 45 h |
| Comparativos y drill‑down | Periodo vs periodo, tendencias, top/bottom, filtros avanzados | 55 h |
| Dimensiones de negocio | Facturación/crédito/cobranza (si aplica), categorías/variantes | 35 h |
| Exportables “de negocio” | CSV mejorado + opcional Excel/PDF (plantilla) | 25 h |
| QA + documentación | Casos de prueba y guía de uso para admin | 20 h |
| **Total estimado** |  | **180 h** |

180 h × $900 MXN/h = **$162,000 MXN** (redondeado a **$165,000 MXN**)

---

## Cotización completa (2.1 + 2.2 + 2.3) — Empresa pequeña (México 2026)

### Resumen de precios por módulo
- **Módulo 2.1 (POS + ticket/QR + facturación SAT/PAC + cobranza en caja)**: **$360,000 MXN + IVA**
- **Módulo 2.2 (Almacén/stock + layout + restock + barcodes/etiquetas)**: **$225,000 MXN + IVA**
- **Módulo 2.3 (Programa de reporteo modular + comparativos + KPIs)**: **$165,000 MXN + IVA**

**Subtotal por módulos**: **$750,000 MXN + IVA**

### Descuento por contratación completa (implementación integral)
Para una empresa pequeña, al contratar los 3 módulos como paquete se elimina retrabajo de coordinación/QA y se comparten entregables (catálogo, permisos, reportes, pruebas).

- **Descuento paquete**: **-$51,000 MXN**
- **Total paquete**: **$699,000 MXN + IVA**

---

## Qué ofrecemos (respuesta directa a cada necesidad)

### 2.1 Portal de ventas (POS)
- **Conexión con caja / cajón**
  - Ofrecemos: diseño e implementación de “puente” de hardware (según cajón/impresora), y disparo automático en ventas en efectivo (cuando aplique).
- **Conexión lector RF / escáner**
  - Ofrecemos: flujo POS optimizado para escaneo (input enfocado, atajos) + endpoint POS ya existente; pruebas con escáner tipo teclado.
- **Impresora de tickets**
  - Ofrecemos: ticket HTML + texto + QR; hardening de impresión y compatibilidad (térmica) y layout final.
- **Facturación SAT**
  - Ofrecemos: integrar PAC real (timbrar/cancelar), control de folios/series, almacenamiento de XML/PDF y manejo de errores.
- **QR para facturación**
  - Ofrecemos: QR en ticket con URL configurable (ya existe base) + validaciones.
- **Programa de cobranza**
  - Ofrecemos: integrar cobranza al flujo de caja (venta a crédito, abonos, tickets/recibos) y conciliación básica.
- **Precio menudeo/mayoreo y cantidades**
  - Ofrecemos: respetar regla ≥12 (ya existe en BD) y parametrizar/confirmar si aplica por línea vs acumulado; UI para cantidades ya disponible, se robustece.

### 2.2 Control de stock (almacén)
- **Subir layout de entradas**
  - Ofrecemos: carga masiva robusta (CSV y/o Excel), validación por línea, reporte de errores y reintentos.
- **Actualizar cantidades / salidas por venta**
  - Ofrecemos: inventario se descuenta automáticamente por trigger post‑venta; se valida consistencia y se complementa con movimientos manuales.
- **Reporte semanal/mensual + restock**
  - Ofrecemos: reportes por periodo + sugerencias de reposición (umbral/rotación) y exportables listos para compras.
- **Variantes / precios**
  - Ofrecemos: variantes (talla/color) y precios menudeo/mayoreo ya soportados; se completa UX operativa.
- **Sistema centralizado**
  - Ofrecemos: acceso web con autenticación/roles; controles por perfil.
- **Registro manual de productos**
  - Ofrecemos: alta manual de productos/variantes con validaciones.
- **Generación de códigos de barra**
  - Ofrecemos: generador (interno o estándar acordado) + flujo de impresión de etiquetas.

### 2.3 Programa de reporteo
- **Reporte de ventas (método de pago + facturación + crédito si aplica)**
  - Ofrecemos: reportes con filtros, exportables, y dimensión crédito/facturado; comparativos periodo‑periodo.
- **Reporte de almacén (stock por categoría)**
  - Ofrecemos: vista de existencias/valor + filtros; exportables “de negocio”.
- **Reporte de movimientos**
  - Ofrecemos: entradas/salidas/ajustes por periodo, con trazabilidad por producto/variante.
- **Reporte general mensual (admin)**
  - Ofrecemos: KPIs, tendencias, comparativas y top productos; base ya existe y se profundiza para administración.

---

## Notas de implementación (prácticas para empresa pequeña)
- **Entrega gradual por módulo**: se puede poner en producción por fases (minimizando paro operativo).
- **Capacitación**: se incluye acompañamiento de salida por módulo (guía + sesión remota).
- **Soporte post‑salida (opcional)**: bolsa mensual de horas o soporte por evento (se cotiza según cobertura).

