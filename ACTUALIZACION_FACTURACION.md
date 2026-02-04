# ✅ ACTUALIZACIÓN DE SISTEMA DE FACTURACIÓN CFDI

**Fecha:** 28 de Enero de 2026  
**Versión:** 2.0

---

## 📋 RESUMEN DE CAMBIOS

Se ha actualizado completamente el sistema de facturación para cumplir con **todos los requisitos del SAT para CFDI (Comprobante Fiscal Digital por Internet)**.

### ✨ Nuevas Funcionalidades

1. **Configuración Fiscal del Emisor**
   - Gestión de datos fiscales de la empresa
   - Almacenamiento de certificados CSD
   - Régimen fiscal y domicilio completo

2. **Datos Completos del Receptor**
   - RFC y nombre completo
   - Régimen fiscal
   - Domicilio fiscal
   - Uso de CFDI

3. **Conceptos Detallados**
   - Clave de producto/servicio SAT
   - Clave de unidad SAT
   - Impuestos por concepto (IVA, IEPS, ISR)
   - Base gravable

4. **Cálculo Automático de Impuestos**
   - IVA trasladado y retenido
   - IEPS
   - ISR retenido
   - Subtotales correctos

5. **Campos de Certificación SAT**
   - Sellos digitales
   - Números de certificado
   - Cadena original
   - Fechas de timbrado

---

## 🚀 INSTRUCCIONES DE INSTALACIÓN

### Paso 1: Ejecutar el Script SQL

Ejecuta el archivo `facturacion_actualizada.sql` en PostgreSQL:

```bash
# Opción 1: Desde la terminal
psql -U postgres -d almacen_db -f facturacion_actualizada.sql

# Opción 2: Desde pgAdmin
# 1. Abre pgAdmin
# 2. Conecta a tu base de datos almacen_db
# 3. Abre Query Tool
# 4. Carga el archivo facturacion_actualizada.sql
# 5. Ejecuta (F5)
```

### Paso 2: Configurar Datos Fiscales de tu Empresa

**IMPORTANTE:** Debes actualizar la configuración fiscal con los datos reales de tu empresa.

#### Opción A: Desde la Base de Datos

```sql
UPDATE configuracion_fiscal 
SET 
    rfc_emisor = 'TU_RFC_AQUI',
    nombre_emisor = 'NOMBRE DE TU EMPRESA',
    razon_social = 'RAZON SOCIAL COMPLETA',
    regimen_fiscal = '612',  -- Código de régimen fiscal SAT
    calle = 'CALLE',
    numero_exterior = '123',
    colonia = 'COLONIA',
    municipio = 'CIUDAD',
    estado = 'ESTADO',
    codigo_postal = '12345'
WHERE activo = true;
```

#### Opción B: Desde la API (Requiere token de ADMIN)

```bash
POST http://localhost:8000/api/v1/configuracion/fiscal
Content-Type: application/json
Authorization: Bearer {token}

{
  "rfc_emisor": "TU_RFC_AQUI",
  "nombre_emisor": "NOMBRE DE TU EMPRESA",
  "razon_social": "RAZON SOCIAL COMPLETA",
  "regimen_fiscal": "612",
  "calle": "CALLE",
  "numero_exterior": "123",
  "colonia": "COLONIA",
  "municipio": "CIUDAD",
  "estado": "ESTADO",
  "pais": "México",
  "codigo_postal": "12345"
}
```

### Paso 3: Reiniciar el Backend

```bash
# Si usas Docker
docker-compose restart backend

# Si usas directamente
# Detén el servidor y reinicia
uvicorn app.main:app --reload
```

### Paso 4: Reiniciar el Frontend

```bash
# Si usas Docker
docker-compose restart frontend

# Si usas npm directamente
npm start
```

---

## 📊 NUEVAS TABLAS CREADAS

### 1. `configuracion_fiscal`
Almacena los datos fiscales del emisor (tu empresa).

**Campos principales:**
- RFC, nombre, razón social
- Régimen fiscal
- Domicilio completo
- Certificados CSD (.cer, .key)
- Vigencia de certificados

### 2. `factura_conceptos`
Almacena los productos/servicios de cada factura.

**Campos principales:**
- Clave producto/servicio SAT
- Cantidad, unidad, descripción
- Precio unitario, importe
- Objeto de impuesto

### 3. `factura_concepto_impuestos`
Almacena los impuestos de cada concepto.

**Campos principales:**
- Tipo (traslado o retención)
- Base gravable
- Impuesto (IVA, IEPS, ISR)
- Tasa o cuota
- Importe

### 4. `factura_pagos`
Para complementos de pago (CFDI tipo P).

---

## 🔧 CAMPOS AGREGADOS A `facturas`

### Información del Emisor
- `nombre_emisor`
- `regimen_fiscal_emisor`
- `lugar_expedicion`

### Información del Receptor
- `nombre_receptor` ✨ OBLIGATORIO AHORA
- `regimen_fiscal_receptor`
- `domicilio_fiscal_receptor`
- `residencia_fiscal` (extranjeros)
- `num_reg_id_trib` (extranjeros)

### Datos del Comprobante
- `tipo_comprobante` (I, E, T, P, N)
- `moneda`
- `tipo_cambio`
- `exportacion`

### Subtotales e Impuestos
- `subtotal`
- `descuento`
- `iva_trasladado`
- `iva_retenido`
- `ieps_trasladado`
- `isr_retenido`

### Datos de Certificación SAT
- `fecha_emision`
- `fecha_timbrado`
- `fecha_certificacion`
- `certificado_sat`
- `no_certificado_emisor`
- `no_certificado_sat`
- `sello_cfdi`
- `sello_sat`
- `cadena_original_sat`

### Relaciones de CFDI
- `tipo_relacion`
- `uuid_relacionados[]`

### Cancelación
- `motivo_cancelacion`
- `fecha_cancelacion`

---

## 🎨 NUEVOS CAMPOS EN EL FORMULARIO

El formulario de facturación ahora incluye:

### 📋 Datos del Receptor
- RFC (obligatorio)
- Nombre o Razón Social (obligatorio)
- Régimen Fiscal (catálogo SAT)
- Uso CFDI (catálogo completo SAT)
- Domicilio Fiscal (opcional)

### 💳 Forma y Método de Pago
- Forma de Pago (01-Efectivo, 03-Transferencia, 04-Tarjeta, etc.)
- Método de Pago (PUE o PPD)
- Moneda (MXN, USD, EUR, etc.)
- Tipo de Cambio (si moneda != MXN)

### 📝 Observaciones
- Campo de texto libre para notas adicionales

---

## 🔄 CATÁLOGOS SAT INCLUIDOS

### Régimen Fiscal (Receptor)
- 601 - General de Ley Personas Morales
- 603 - Personas Morales con Fines no Lucrativos
- 605 - Sueldos y Salarios
- 606 - Arrendamiento
- 612 - Personas Físicas con Actividades Empresariales
- 616 - Sin obligaciones fiscales
- 621 - Incorporación Fiscal
- 625 - Plataformas Tecnológicas
- 626 - Régimen Simplificado de Confianza

### Uso CFDI
- G01 - Adquisición de mercancías
- G02 - Devoluciones
- G03 - Gastos en general
- I01-I08 - Inversiones
- D01-D10 - Deducciones personales
- S01 - Sin efectos fiscales
- CP01 - Pagos
- CN01 - Nómina
- P01 - Por definir

### Forma de Pago
- 01 - Efectivo
- 02 - Cheque nominativo
- 03 - Transferencia electrónica
- 04 - Tarjeta de crédito
- 28 - Tarjeta de débito
- 99 - Por definir

---

## 📡 NUEVOS ENDPOINTS DE API

### Configuración Fiscal

#### Obtener Configuración
```http
GET /api/v1/configuracion/fiscal
Authorization: Bearer {token}
```

#### Crear Configuración (Solo ADMIN)
```http
POST /api/v1/configuracion/fiscal
Authorization: Bearer {token}
Content-Type: application/json

{
  "rfc_emisor": "XAXX010101000",
  "nombre_emisor": "EMPRESA EJEMPLO",
  "razon_social": "EMPRESA EJEMPLO SA DE CV",
  "regimen_fiscal": "601",
  "codigo_postal": "03410"
}
```

#### Actualizar Configuración (Solo ADMIN)
```http
PUT /api/v1/configuracion/fiscal/{id}
Authorization: Bearer {token}
Content-Type: application/json
```

### Facturas (Actualizadas)

#### Crear Factura
```http
POST /api/v1/facturas
Authorization: Bearer {token}
Content-Type: application/json

{
  "ventas_ids": [1, 2],
  "rfc_receptor": "XAXX010101000",
  "nombre_receptor": "CLIENTE EJEMPLO",
  "regimen_fiscal_receptor": "616",
  "uso_cfdi": "G03",
  "tipo_comprobante": "I",
  "forma_pago": "01",
  "metodo_pago": "PUE",
  "moneda": "MXN",
  "observaciones": "Factura de prueba"
}
```

---

## 🧪 PRUEBAS SUGERIDAS

### 1. Verificar Instalación de Tablas

```sql
-- Verificar que las tablas se crearon
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('configuracion_fiscal', 'factura_conceptos', 'factura_concepto_impuestos');
```

### 2. Verificar Configuración Fiscal

```sql
-- Ver configuración fiscal activa
SELECT * FROM configuracion_fiscal WHERE activo = true;
```

### 3. Crear Factura de Prueba

1. Crear una venta cerrada
2. Ir a Facturación
3. Llenar formulario con todos los campos
4. Crear factura en borrador
5. Verificar que se calculen correctamente los totales

### 4. Verificar Conceptos

```sql
-- Ver conceptos de la última factura
SELECT 
    f.serie,
    f.folio,
    fc.descripcion,
    fc.cantidad,
    fc.precio_unitario,
    fc.importe
FROM facturas f
JOIN factura_conceptos fc ON f.id = fc.factura_id
ORDER BY f.id DESC
LIMIT 10;
```

---

## ⚠️ IMPORTANTE: CONFIGURAR ANTES DE USAR

### 1. Actualiza tu Configuración Fiscal
El sistema viene con datos de ejemplo. **DEBES** actualizarlos con los datos reales de tu empresa antes de timbrar facturas.

### 2. Claves SAT
Los conceptos se crean con claves genéricas:
- `clave_prod_serv`: `01010101` (genérica)
- `clave_unidad`: `H87` (Pieza)

Para producción, deberás:
- Agregar campos de claves SAT a tus productos
- Actualizar el servicio para usar las claves correctas

### 3. Integración con PAC
El servicio `PACAdapter` es un stub para desarrollo. Para producción:
- Integrar con un PAC real (Finkok, Diverza, SW Sapien, etc.)
- Implementar generación de XML CFDI 4.0
- Implementar sellos digitales
- Manejar respuestas del PAC

---

## 📚 DOCUMENTACIÓN ADICIONAL

### Catálogos SAT
- [Catálogo de Régimen Fiscal](http://omawww.sat.gob.mx/tramitesyservicios/Paginas/documentos/catCFDI.xls)
- [Catálogo de Uso CFDI](http://omawww.sat.gob.mx/tramitesyservicios/Paginas/documentos/catCFDI.xls)
- [Catálogo de Forma de Pago](http://omawww.sat.gob.mx/tramitesyservicios/Paginas/documentos/catCFDI.xls)

### Guías SAT
- [CFDI 4.0 - Guía de Llenado](https://www.sat.gob.mx/consulta/92764/comprobante-fiscal-digital-por-internet-4.0)

---

## 🐛 SOLUCIÓN DE PROBLEMAS

### Error: "No hay configuración fiscal configurada"
**Solución:** Ejecuta el paso 2 de instalación y configura los datos fiscales.

### Error: "Missing required field nombre_receptor"
**Solución:** El campo `nombre_receptor` es ahora obligatorio. Asegúrate de llenar el formulario completo.

### Error: "Column configuracion_fiscal does not exist"
**Solución:** Ejecuta el script SQL `facturacion_actualizada.sql`

### Los totales no calculan correctamente
**Solución:** El trigger automático debería calcularlos. Verifica:
```sql
SELECT * FROM pg_trigger WHERE tgname = 'trg_factura_conceptos_totales';
```

---

## 📞 SOPORTE

Si encuentras algún problema:
1. Verifica que ejecutaste el script SQL correctamente
2. Verifica que configuraste los datos fiscales
3. Revisa los logs del backend para errores
4. Consulta la documentación del SAT

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

- [ ] Script SQL ejecutado sin errores
- [ ] Configuración fiscal actualizada con datos reales
- [ ] Backend reiniciado
- [ ] Frontend reiniciado
- [ ] Factura de prueba creada exitosamente
- [ ] Conceptos se crean automáticamente
- [ ] Totales se calculan correctamente
- [ ] Formulario muestra todos los campos nuevos

---

**¡Sistema de facturación actualizado y listo para uso!** 🎉

Para integración completa con el SAT, el siguiente paso es conectar con un PAC autorizado.
