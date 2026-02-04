# Cotización formal — Opción B (continuar con sistema actual) — Módulos 2.1, 2.2, 2.3

**Proveedor:** ________________________________  
**RFC:** ________________________________  
**Contacto:** ________________________________  
**Correo/Teléfono:** ________________________________  

**Cliente:** ________________________________  
**Proyecto:** Implementación gradual sobre sistema ERP/POS actual (alcances 2.1, 2.2, 2.3)  
**Fecha:** ____ / ____ / 2026  
**Vigencia:** 15 días naturales  
**Moneda:** MXN (pesos mexicanos) + IVA  

---

## 1) Objetivo de esta propuesta (Opción B)
Completar **únicamente** las necesidades **explícitas** descritas en los puntos **2.1, 2.2 y 2.3**, **sobre el sistema actual del cliente** (backend + frontend + base de datos), priorizando:

- Reusar lo ya construido (menor costo vs “construir de cero”)
- Cierre funcional “operable” para una empresa pequeña
- Estabilidad, pruebas y entrega gradual por módulo

---

## 2) Base técnica (existente)
Esta propuesta parte de una base ya implementada por el cliente:

- Backend API (FastAPI)
- Frontend web (React)
- Base de datos PostgreSQL con triggers de inventario y precio
- Pantallas y endpoints ya presentes para POS, almacén, cobranza, facturación y reportes

> Nota: Esta propuesta **no** sustituye el sistema actual por un SaaS externo. Se trabaja **sobre el sistema del cliente**.

---

## 3) Alcance por módulo (checklist de lo explícito)

### 3.1 Módulo 2.1 — Portal de ventas (POS mostrador)
**Alcances explícitos y entregables:**
- [x] **Conexión con caja (venta en efectivo)**  
  - Entregable (acotado): flujo de venta en efectivo operable; apertura de cajón **sin integración a medida** (manual/por driver si aplica).
- [x] **Conexión de lector RF / escáner**  
  - Entregable: soporte operativo con escáner tipo teclado (USB/Bluetooth), input enfocado, validaciones y manejo de errores.
- [x] **Conexión con impresora de tickets**  
  - Entregable: ticket imprimible estable (térmico) vía navegador/driver, con formato final de tienda.
- [x] **Facturación (conexión a plataforma SAT)**  
  - Entregable: timbrado real (CFDI) vía **PAC** seleccionado por el cliente, con folios/series, cancelación y resguardo de evidencias (XML/PDF o enlaces).
- [x] **Generación de QR para facturación**  
  - Entregable: QR en ticket con URL configurable para facturación/consulta.
- [x] **Programa de cobranza**  
  - Entregable (mínimo): venta a crédito y registro de abonos/pagos con recibo/ticket y trazabilidad básica.
- [x] **Lectura automática menudeo/mayoreo (≥12)**  
  - Entregable: confirmación/ajuste de regla (por línea vs acumulado) y pruebas; alineación frontend/backend/BD.
- [x] **Campo para entrada manual de cantidades**  
  - Entregable: captura y operación rápida (incluye atajos y validaciones).

**Fuera de alcance (para mantener costo bajo):**
- Integración bancaria/terminal (cobro real con adquirente).
- Integración a medida para apertura de cajón por comando ESC/POS (se cotiza aparte si se requiere).

---

### 3.2 Módulo 2.2 — Programa de control de stock (almacén)
**Alcances explícitos y entregables:**
- [x] **Variantes de producto (talla/color)**  
  - Entregable: flujo completo de alta/edición/consulta de variantes en UI (operativo para almacén).
- [x] **Carga de precios (menudeo/mayoreo)**  
  - Entregable: mantenimiento de precios por variante y validaciones.
- [x] **Layout de carga de productos**  
  - Entregable (mínimo): carga masiva por plantilla **CSV** robusta (validación por línea + reporte de errores).  
  - Opcional: importador **Excel/XLSX** (si el cliente lo exige; ver “Opcionales”).
- [x] **Disminución de stock post venta**  
  - Entregable: verificación end‑to‑end del descuento automático + bitácora de movimientos.
- [x] **Sistema centralizado de control de stock**  
  - Entregable: consulta de stock (incluye stock bajo) y movimientos con filtros básicos.
- [x] **Entrada y registro manual de nuevos productos**  
  - Entregable: alta manual en UI con permisos por rol.
- [x] **Generación de códigos de barra por producto/variante**  
  - Entregable (mínimo): generador de **código interno** (no EAN/UPC) + plantilla de etiquetas imprimible desde navegador.
- [x] **Reporte semanal y mensual (más vendidos + restock)**  
  - Entregable: reportes por periodo y listado de stock bajo; “restock” por umbral configurable (mínimo).

---

### 3.3 Módulo 2.3 — Programa de reporteo
**Alcances explícitos y entregables:**
- [x] **Reporte de ventas** (separado por método de pago, con fecha y estado de facturación si se requiere)  
  - Entregable: filtros por rango de fechas, método de pago, facturado/no facturado; export CSV.
- [x] **Reporte de almacén** (vista general de stock por categoría)  
  - Entregable: filtros por categoría/stock bajo; export CSV.
- [x] **Reporte de movimientos de inventario**  
  - Entregable: entradas/salidas/ajustes por periodo; export (CSV).
- [x] **Reporte general mensual (admin)**  
  - Entregable: ingresos mensuales + comparativos básicos + top productos; exportable.

**Fuera de alcance (para mantener costo bajo):**
- BI avanzado (márgenes, tableros ejecutivos personalizados, predicciones).

---

## 4) Entregables transversales (incluidos)
- Endpoints y UI operativos por módulo.
- Roles/permisos básicos (caja / almacén / admin).
- Documentación corta (guía de operación + checklist de despliegue).
- Pruebas rápidas (“smoke test”) y validación de flujos críticos.

---

## 5) Inversión (costos) — por módulo y paquete

### 5.1 Tarifas y criterio de costeo
Para mantener la opción **baja pero justa**, esta cotización está calculada como **“cierre de brechas”** (no re‑hacer módulos completos), reusando lo ya existente (endpoints, pantallas, triggers y reportes).

Se considera una tarifa promedio reducida para PYME, que incluye análisis, desarrollo, QA y documentación:
- **$650 MXN/h**

> Los costos de licencias externas (PAC, certificados, timbres, etc.) se pagan por separado por el cliente.

### 5.2 Costos por módulo (implementación sobre sistema actual)
| Módulo | Estimación | Inversión |
|---|---:|---:|
| **2.1 POS + ticket + QR + cobranza mínima + SAT/PAC real (alcance acotado)** | ~120 h | **$80,000 MXN + IVA** |
| **2.2 Almacén + layout CSV robusto + etiquetas + restock por umbral** | ~70 h | **$45,000 MXN + IVA** |
| **2.3 Reportes (ventas/almacén/movimientos/mensual) + exportables** | ~40 h | **$25,000 MXN + IVA** |
| **Total por módulos** | **~230 h** | **$150,000 MXN + IVA** |

### 5.3 Paquete completo (2.1 + 2.2 + 2.3)
**Total paquete (Opción B): $150,000 MXN + IVA**

---

## 5.4 Justificación de precios (por qué es “bajo pero justo”)

### a) Por qué esta Opción B cuesta más que un SaaS (Opción A)
Aquí no se paga una suscripción mensual para “software ya hecho”. Se paga por:
- **Cerrar brechas reales** del sistema actual (lo que falta para operar con los puntos 2.1–2.3).
- **Riesgo y responsabilidad técnica** (pruebas, estabilidad y soporte de salida).
- Integración **SAT/PAC** (aunque sea acotada) que no es solo configuración.

### b) Por qué aun así es significativamente más barata que un “desarrollo completo”
Porque el sistema del cliente ya trae base funcional:
- POS, ventas y ticket (incluyendo QR) ya existen en UI/API.
- Inventario y precio ya tienen triggers en BD.
- Reportes base y exportables ya existen.

Por eso la estimación es de **~230 horas**, enfocada en:
- **PAC real** (reemplazar stub), flujo mínimo de timbrado/cancelación y resguardo de evidencias.
- Hardening de impresión/ticket y reglas operativas.
- Completar UX operativa de almacén (altas/cargas/etiquetas mínimas).
- Alinear reportes a lo explícito (ventas/almacén/movimientos/mensual) y exportables.

### c) Comparativo de referencia (mercado)
Como referencia, Odoo publica “Success Packs” para implementación con consultor dedicado de **50h / 100h / 200h** (además de licencias).  
Fuentes: `https://www.odoo.com/pricing-packs` y `https://www.odoo.com/pricing`

Nuestra propuesta de **~230 horas** se mantiene en rango razonable para llevar un sistema propio a operación, pero con una tarifa reducida PYME (\(650 MXN/h\)) y alcance acotado para bajar el costo total.

### d) Qué se entiende por “SAT/PAC real” en esta opción (alcance acotado)
Para mantener precio bajo, se considera:
- 1 PAC elegido por el cliente
- 1 flujo de timbrado (factura ingreso) + cancelación básica
- Resguardo de XML/PDF (o enlaces, según PAC)
- Sin escenarios avanzados (complementos, nómina, comercio exterior, etc.)

---

## 6) Tiempo estimado y plan de trabajo
- **Duración total estimada:** 6 a 10 semanas (según disponibilidad de usuarios clave y PAC).
- **Entrega gradual:** por módulo (2.1 → 2.2 → 2.3) o según prioridad del cliente.

---

## 7) Dependencias del cliente (necesarias)
- Definir **PAC** a utilizar y proporcionar credenciales/certificados y datos fiscales del emisor.
- Confirmar regla de mayoreo (≥12): por línea vs acumulado (definición final).
- Proveer plantilla de carga de productos y 1 ejemplo real (catálogo).
- Hardware (si aplica): impresora térmica, escáner, cajón (operación manual/driver).

---

## 8) Exclusiones (para evitar malentendidos)
- Costos de PAC, timbres, certificados CSD, renovaciones, comisiones: **no incluidos**.
- Integración bancaria/terminal (procesamiento de pagos con adquirente): **no incluido**.
- Integración a medida con cajón por comando ESC/POS: **no incluido** (se cotiza opcional).
- Migraciones masivas complejas (limpieza de datos, deduplicación avanzada): **no incluido** salvo acuerdo.

---

## 9) Opcionales (si el cliente los solicita)
- Importación **Excel/XLSX** para “layout” (además de CSV): **+$18,000 MXN + IVA**
- Apertura de cajón por comando (si hardware compatible + servicio local): **+$25,000 MXN + IVA**
- Soporte post‑salida (bolsa mensual): **a cotizar** según cobertura

---

## 10) Condiciones comerciales
- **Forma de pago sugerida:** 50% al inicio / 50% contra entrega del módulo (por fases) o 100% al inicio por módulo.
- **Soporte posterior:** no incluido; opcional por bolsa mensual o por evento.

---

## 11) Aceptación
**Cliente**: ____________________________  **Firma**: ____________________  **Fecha**: ____/____/2026  
**Proveedor**: __________________________  **Firma**: ____________________  **Fecha**: ____/____/2026  

