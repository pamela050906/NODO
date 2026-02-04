# Cotización formal — Opción ultra‑económica (Módulos 2.1, 2.2, 2.3)

**Proveedor:** ________________________________  
**RFC:** ________________________________  
**Contacto:** ________________________________  
**Correo/Teléfono:** ________________________________  

**Cliente:** ________________________________  
**Proyecto:** Implementación gradual de POS + Almacén + Reportes (alcances 2.1, 2.2, 2.3)  
**Fecha:** ____ / ____ / 2026  
**Vigencia:** 15 días naturales  
**Moneda:** MXN (pesos mexicanos) + IVA  

---

## 1) Objetivo de esta propuesta (ultra‑económica)
Cubrir **únicamente** las necesidades **explícitas** de los puntos **2.1, 2.2 y 2.3** con el **menor costo posible**, priorizando:

- Implementación rápida
- Funcionalidad estándar (sin desarrollos a medida)
- Reportes/exportables básicos

---

## 2) Enfoque y plataforma
Para mantener el costo ultra‑económico, el enfoque es:

- **Usar una plataforma SaaS** (software ya hecho) y
- Realizar solo **configuración/capacitación mínima** (sin desarrollo a medida).

### Plataforma considerada (referencia de mercado)
- **Bind ERP — Plan “Total” (pago anual)**: **$22,680 MXN + IVA / año** (equivalente a $1,890 MXN/mes pagando anual).  
  Fuente pública: `https://bind.com.mx/erp/pymes`

> Nota: el licenciamiento SaaS se paga directamente al proveedor (Bind), conforme a sus términos.

---

## 3) Checklist por módulo (qué cubre la solución)

### 3.1 Módulo 2.1 — Portal de ventas (POS mostrador)
- [x] **Conexión de lector RF / escáner (códigos de barra)**: escáner tipo “teclado” (USB/Bluetooth).
- [x] **Campo para entrada manual de cantidades**: captura de cantidad en POS.
- [x] **Conexión con impresora de tickets**: impresión vía navegador/driver (térmica).
- [x] **Facturación (SAT)**: emisión de CFDI usando la capacidad nativa del SaaS.
- [x] **Generación de QR para facturación**: incluido **si** la plataforma lo soporta; si no, se implementa un QR mínimo a URL/formulario acordado.
- [x] **Programa de cobranza**: cuentas por cobrar y registro de pagos (según funciones del plan).
- [x] **Lectura automática de precio menudeo/mayoreo (≥12)**: mediante reglas/listas de precio del SaaS **si** está disponible; si no, procedimiento operativo acordado.
- [x] **Conexión con caja/cajón**: ultra‑económica (sin desarrollo): operación manual (llave) o por configuración de driver (según hardware).

### 3.2 Módulo 2.2 — Programa de control de stock (almacén)
- [x] **Variantes de producto (talla/color)**: alta por catálogo (según soporte del SaaS).
- [x] **Carga de precios (menudeo/mayoreo)**: configuración en catálogo/listas de precio.
- [x] **Layout de carga de productos**: importación por plantilla CSV/Excel del SaaS.
- [x] **Disminución de stock post venta**: automático por operación estándar POS/ERP.
- [x] **Sistema centralizado de control de stock**: acceso web en nube.
- [x] **Entrada/registro manual de nuevos productos**: alta manual de productos/variantes.
- [x] **Generación de códigos de barra** (ultra‑bajo): uso de SKU/código interno + plantilla de etiquetas (sin generador avanzado).
- [x] **Reporte semanal y mensual + restock** (ultra‑bajo): reportes por periodo + control por stock mínimo (si se requiere recomendación avanzada, se cotiza aparte).

### 3.3 Módulo 2.3 — Programa de reporteo
- [x] **Reporte de ventas**: por periodo, con separación por método de pago (según reportes estándar del SaaS).
- [x] **Reporte de almacén**: existencias por categoría.
- [x] **Reporte de movimientos de inventario**: entradas/salidas/ajustes por periodo (según soporte del plan).
- [x] **Reporte general de ventas (mensual)**: ingresos mensuales y comparativos básicos.
- [x] **Exportables**: CSV/Excel estándar del SaaS.

---

## 4) Entregables de implementación (servicio mínimo)
La implementación mínima incluye:

- Configuración inicial de empresa, sucursal(es) y parámetros básicos.
- Alta de usuarios/roles (caja, almacén, administración) a nivel básico.
- Plantilla de carga (layout) validada y 1 carga inicial asistida (muestra).
- Pruebas rápidas de:
  - Venta con escáner + ticket
  - Actualización de inventario
  - Reportes básicos
- 1 sesión de capacitación remota (operación de caja, almacén y reportes).

---

## 5) Inversión (costos) — por módulo y paquete

### 5.1 Costos por módulo (licencia + implementación mínima)
> En SaaS, la licencia es transversal; se muestra “por módulo” solo para claridad comercial.

| Módulo | Licencia Bind Total (anual) | Implementación mínima (servicios) | Total 1er año |
|---|---:|---:|---:|
| **2.1 POS** | $22,680 + IVA | $10,000 + IVA | $32,680 + IVA |
| **2.2 Almacén** | $22,680 + IVA | $6,000 + IVA | $28,680 + IVA |
| **2.3 Reporteo** | $22,680 + IVA | $2,000 + IVA | $24,680 + IVA |

### 5.2 Paquete completo (2.1 + 2.2 + 2.3)
- **Licencia Bind Total (anual):** $22,680 MXN + IVA  
- **Implementación mínima total (servicios):** $18,000 MXN + IVA  
- **Total 1er año:** **$40,680 MXN + IVA** (+ hardware)

---

## 6) Tiempo estimado
- **Duración:** 1 a 2 semanas (remoto), dependiendo de:
  - disponibilidad de usuarios clave,
  - calidad/estructura del catálogo a cargar,
  - compras e instalación de hardware (si aplica).

---

## 7) Requisitos del cliente
- Confirmar número de usuarios y roles (caja/almacén/admin).
- Proveer catálogo inicial (o layout) y validar plantilla final.
- Contar con hardware (si aplica): impresora térmica, escáner y cajón; etiquetas.
- Definir reglas mínimas: mayoreo (≥12), stock mínimo, y políticas de cobro (contado/crédito).

---

## 8) Exclusiones (para mantener el costo ultra‑bajo)
- Integración a medida con **cajón** (apertura por comando) y hardware especializado.
- Desarrollo de **integraciones personalizadas** o funcionalidades no explícitas en 2.1–2.3.
- Implementación de BI avanzado (márgenes, dashboards a medida, modelos de rotación avanzados).
- Compra/configuración física de hardware y visitas en sitio (se cotiza aparte).

---

## 9) Condiciones comerciales
- **Servicios (implementación mínima):** 100% al inicio o 50% inicio / 50% al cierre (a convenir).
- **Licencia SaaS:** contratación y pago directo del cliente al proveedor (Bind ERP).
- **Soporte post‑implementación:** no incluido; disponible por bolsa mensual o por evento (cotización separada).

---

## 10) Aceptación
**Cliente**: ____________________________  **Firma**: ____________________  **Fecha**: ____/____/2026  
**Proveedor**: __________________________  **Firma**: ____________________  **Fecha**: ____/____/2026  

# Cotización ultra‑baja (por módulo) + checklist (estado real actual)

## Supuestos de la opción ultra‑baja (sin desarrollo a medida)
- **Modelo**: usar una plataforma SaaS (ej. **Bind ERP**) + **configuración/capacitación mínima**.
- **Plataforma de referencia (publicada)**: **Bind ERP “Total”** (anual) **$22,680 MXN + IVA / año** (equiv. $1,890 MXN/mes, pago anual).  
  Fuente: `https://bind.com.mx/erp/pymes`
- **Servicios mínimos (implementación remota)**: bolsa total sugerida **$18,000 MXN + IVA** (≈ 20 h) para “dejar operando” lo explícito (plantillas, catálogos, permisos, pruebas rápidas y capacitación express).
- **Hardware**: escáner, impresora térmica, cajón, etiquetas **no incluido** (se compra aparte). Para ultra‑bajo, el cajón puede operar **manual** (llave) o por configuración del driver de impresora (sin software).

> Nota importante: en SaaS, el **licenciamiento no se “divide” por módulo**; la división por módulo aplica a **servicios de implementación**.

---

## Resumen de costos ultra‑bajos (por módulo)

| Módulo | Costo plataforma (anual) | Implementación mínima (servicios) | Total 1er año (plataforma + impl.) |
|---|---:|---:|---:|
| 2.1 POS (ventas mostrador) | $22,680 + IVA | $10,000 + IVA | $32,680 + IVA |
| 2.2 Almacén (stock) | $22,680 + IVA | $6,000 + IVA | $28,680 + IVA |
| 2.3 Reporteo | $22,680 + IVA | $2,000 + IVA | $24,680 + IVA |

**Paquete (2.1 + 2.2 + 2.3)**  
- Plataforma (anual): **$22,680 + IVA**  
- Implementación total: **$18,000 + IVA**  
- **Total 1er año**: **$40,680 + IVA** (+ hardware)

---

## Módulo 2.1 — Portal de ventas (POS mostrador)

### Checklist de necesidades (capturas 2.1) vs **respuesta real actual (su sistema)**
- [x] **Conexión de lector RF / escáner (códigos de barra)**  
  - **Estado actual**: ✅ Ya hay endpoint de búsqueda por código (`/api/v1/pos/barcode/{codigo}`) y pantalla POS que captura el código.
- [x] **Campo para entrada manual de cantidades**  
  - **Estado actual**: ✅ UI de POS permite cantidad.
- [x] **Lectura automática menudeo/mayoreo (≥12)**  
  - **Estado actual**: ✅ En BD existe trigger `fn_precio_automatico()` que aplica mayoreo cuando `cantidad >= 12`.  
  - **Pendiente**: ⚠️ Alinear/confirmar regla final (por línea vs acumulado) y pruebas end‑to‑end.
- [x] **Disminución de stock post venta**  
  - **Estado actual**: ✅ Trigger `fn_descuento_inventario()` descuenta stock y registra movimiento.
- [x] **Conexión con impresora de tickets**  
  - **Estado actual**: ⚠️ Se genera ticket (HTML/texto) y se imprime vía `window.print()`; falta robustecer para operación real (layout térmico consistente, pruebas con impresoras reales).
- [x] **Generación de QR para facturación**  
  - **Estado actual**: ✅ Se genera QR base64 y se incrusta en ticket.
- [ ] **Facturación (conexión a SAT/PAC real)**  
  - **Estado actual**: ⚠️ Hay módulo de facturas y “timbrado”, pero el adaptador PAC está como **stub** (simulación). Falta PAC real.
- [ ] **Conexión con caja/cajón**  
  - **Estado actual**: ❌ No hay integración directa con hardware de cajón.
- [x] **Programa de cobranza operando junto con caja/POS**  
  - **Estado actual**: ⚠️ Existe módulo de cobranza, pero falta integrarlo al flujo POS (crédito/abonos/ticket/recibos en caja).

### Checklist vs **opción ultra‑baja (SaaS + configuración)**
- [x] **Escáner**: ✅ (escáner tipo teclado)
- [x] **Cantidad manual**: ✅
- [x] **Menudeo/mayoreo ≥12**: ⚠️ depende de reglas/listas de precio del SaaS (si no, procedimiento operativo)
- [x] **Baja de inventario post venta**: ✅ estándar en POS/ERP
- [x] **Ticket**: ✅ impresión por navegador/driver (sin desarrollo)
- [x] **QR en ticket para facturar**: ⚠️ si el SaaS lo soporta; si no, QR a URL/formulario mínimo
- [x] **CFDI/SAT**: ✅ usando facturación del SaaS (sin desarrollar PAC)
- [x] **Caja/cajón**: ⚠️ manual o por driver (sin software a medida)
- [x] **Cobranza**: ✅ cuentas por cobrar/pagos (según funciones del plan)

### Costo ultra‑bajo del módulo 2.1
- **Plataforma (Bind Total anual)**: **$22,680 MXN + IVA / año**
- **Implementación mínima 2.1 (servicios)**: **$10,000 MXN + IVA**
- **Total 1er año (2.1)**: **$32,680 MXN + IVA** (+ hardware)

---

## Módulo 2.2 — Programa de control de stock (almacén)

### Checklist de necesidades (capturas 2.2) vs **respuesta real actual (su sistema)**
- [x] **Variantes (talla/color) por producto**  
  - **Estado actual**: ✅ Backend soporta variantes con talla/color y precios.
- [x] **Carga de precios (menudeo/mayoreo)**  
  - **Estado actual**: ✅ Campos de precio por variante existen.
- [x] **Layout de carga de productos**  
  - **Estado actual**: ✅ Carga masiva por **CSV** existe (`/api/v1/productos/carga-masiva`).  
  - **Pendiente**: ⚠️ Si “layout” significa Excel/XLSX, falta importador y validación de plantilla.
- [x] **Sistema centralizado de control de stock (acceso remoto)**  
  - **Estado actual**: ✅ Web + API con autenticación.
- [x] **Entrada/registro manual de nuevos productos**  
  - **Estado actual**: ⚠️ Backend lo permite; UI de almacén está parcial (requiere cierre operativo/UX).
- [x] **Disminución automática post venta**  
  - **Estado actual**: ✅ Trigger en BD.
- [x] **Reportes semanal/mensual (más vendidos y restock)**  
  - **Estado actual**: ⚠️ Hay reportes por rango de fechas + mensual general + stock bajo; “restock” como recomendación accionable no está formalizado.
- [ ] **Generación de códigos de barra por producto/variante**  
  - **Estado actual**: ❌ Hoy se captura `codigo_barras`; no hay generador/etiquetas.

### Checklist vs **opción ultra‑baja (SaaS + configuración)**
- [x] **Variantes**: ✅ (según soporte del SaaS)
- [x] **Precios menudeo/mayoreo**: ✅ (listas de precio/reglas)
- [x] **Layout**: ✅ importación CSV/Excel del SaaS (plantilla)
- [x] **Centralizado**: ✅ nube
- [x] **Altas manuales**: ✅
- [x] **Baja post venta**: ✅
- [x] **Reportes semanal/mensual + restock**: ⚠️ reportes sí; “restock” como recomendación avanzada depende del SaaS/plan (si no, se resuelve con stock mínimo)
- [x] **Códigos de barra**: ⚠️ mínimo ultra‑bajo: usar SKU/código interno + imprimir etiquetas con plantilla; generador formal depende del SaaS

### Costo ultra‑bajo del módulo 2.2
- **Plataforma (Bind Total anual)**: **$22,680 MXN + IVA / año**
- **Implementación mínima 2.2 (servicios)**: **$6,000 MXN + IVA**
- **Total 1er año (2.2)**: **$28,680 MXN + IVA**

---

## Módulo 2.3 — Programa de reporteo

### Checklist de necesidades (capturas 2.3) vs **respuesta real actual (su sistema)**
- [x] **Reporte de ventas (por método de pago, fecha, facturación y crédito si aplica)**  
  - **Estado actual**: ✅ método de pago + rango fechas + facturado existe; ⚠️ “crédito” como dimensión consolidada depende de normalización con cobranza.
- [x] **Reporte de almacén (vista general de stock, por categorías)**  
  - **Estado actual**: ✅ existe reporte de almacén + export.
- [x] **Reporte de movimientos de inventario (entradas/salidas/ajustes por periodo)**  
  - **Estado actual**: ✅ existe.
- [x] **Reporte general mensual (admin) con ingresos/comparativos**  
  - **Estado actual**: ✅ existe mensual con comparativa básica y top productos.
- [x] **Modularidad (lapso configurable) y exportables**  
  - **Estado actual**: ✅ filtros por fecha y export CSV en ventas/almacén; ⚠️ falta estandarizar “formatos de negocio” si se requiere.

### Checklist vs **opción ultra‑baja (SaaS + configuración)**
- [x] **Ventas por periodo y método**: ✅
- [x] **Almacén por categoría / existencias**: ✅
- [x] **Movimientos/kardex**: ✅ (según plan)
- [x] **Mensual admin**: ✅ (comparativos básicos)
- [x] **Export CSV/Excel**: ✅

### Costo ultra‑bajo del módulo 2.3
- **Plataforma (Bind Total anual)**: **$22,680 MXN + IVA / año**
- **Implementación mínima 2.3 (servicios)**: **$2,000 MXN + IVA**
- **Total 1er año (2.3)**: **$24,680 MXN + IVA**

---

## Paquete completo ultra‑bajo (2.1 + 2.2 + 2.3)
- **Plataforma (Bind Total anual)**: **$22,680 MXN + IVA / año**
- **Implementación mínima total (servicios)**: **$18,000 MXN + IVA**
- **Total 1er año**: **$40,680 MXN + IVA** (+ hardware)

### Qué NO cubre esta opción ultra‑baja (para evitar malentendidos)
- Integración a medida con **cajón** (comando de apertura) y hardware especializado.
- Desarrollo de **PAC propio** o integraciones especiales; se usa lo que el SaaS ya trae.
- Reportes BI avanzados (márgenes por categoría, rotación avanzada, etc.) más allá de lo estándar del SaaS.
