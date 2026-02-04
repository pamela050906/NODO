-- ============================================
-- ACTUALIZACIÓN DE SISTEMA DE FACTURACIÓN CFDI
-- Versión: 2.0
-- Fecha: 2026-01-28
-- ============================================

-- ============================================
-- 1. CONFIGURACIÓN FISCAL DEL EMISOR
-- ============================================

CREATE TABLE IF NOT EXISTS configuracion_fiscal (
    id SERIAL PRIMARY KEY,
    rfc_emisor VARCHAR(13) NOT NULL UNIQUE,
    nombre_emisor VARCHAR(255) NOT NULL,
    razon_social VARCHAR(255) NOT NULL,
    regimen_fiscal VARCHAR(10) NOT NULL,
    
    -- Domicilio fiscal
    calle VARCHAR(100),
    numero_exterior VARCHAR(20),
    numero_interior VARCHAR(20),
    colonia VARCHAR(100),
    localidad VARCHAR(100),
    municipio VARCHAR(100),
    estado VARCHAR(100),
    pais VARCHAR(100) DEFAULT 'México',
    codigo_postal VARCHAR(5) NOT NULL,
    
    -- Certificados SAT (archivos CSD)
    certificado_cer BYTEA,
    certificado_key BYTEA,
    certificado_password VARCHAR(255),
    no_certificado VARCHAR(50),
    vigencia_desde DATE,
    vigencia_hasta DATE,
    
    -- Control
    activo BOOLEAN DEFAULT TRUE,
    creado_en TIMESTAMP DEFAULT NOW(),
    actualizado_en TIMESTAMP DEFAULT NOW()
);

-- Agregar constraints a configuracion_fiscal
DO $$ 
BEGIN
    ALTER TABLE configuracion_fiscal DROP CONSTRAINT IF EXISTS check_codigo_postal;
    
    ALTER TABLE configuracion_fiscal ADD CONSTRAINT check_codigo_postal 
        CHECK (codigo_postal ~ '^\d{5}$');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error al crear constraints en configuracion_fiscal: %', SQLERRM;
END $$;

COMMENT ON TABLE configuracion_fiscal IS 'Configuración fiscal de la empresa emisora de facturas';
COMMENT ON COLUMN configuracion_fiscal.regimen_fiscal IS 'Código SAT del régimen fiscal (601, 603, 612, 621, 625, 626)';
COMMENT ON COLUMN configuracion_fiscal.certificado_cer IS 'Certificado .cer del SAT (archivo binario)';
COMMENT ON COLUMN configuracion_fiscal.certificado_key IS 'Llave privada .key del SAT (archivo binario)';

-- ============================================
-- 2. AMPLIAR TABLA FACTURAS CON CAMPOS CFDI
-- ============================================

-- Agregar campos del emisor
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS nombre_emisor VARCHAR(255);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS regimen_fiscal_emisor VARCHAR(10);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS lugar_expedicion VARCHAR(5);

-- Agregar campos del receptor
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS nombre_receptor VARCHAR(255);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS regimen_fiscal_receptor VARCHAR(10);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS domicilio_fiscal_receptor VARCHAR(500);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS residencia_fiscal VARCHAR(3);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS num_reg_id_trib VARCHAR(40);

-- Agregar campos del comprobante
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS tipo_comprobante VARCHAR(1) DEFAULT 'I';
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS moneda VARCHAR(3) DEFAULT 'MXN';
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS tipo_cambio NUMERIC(10,6);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS exportacion VARCHAR(3) DEFAULT '01';

-- Agregar subtotales e impuestos
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS subtotal NUMERIC(16,2);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS descuento NUMERIC(16,2) DEFAULT 0;
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS iva_trasladado NUMERIC(16,2) DEFAULT 0;
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS iva_retenido NUMERIC(16,2) DEFAULT 0;
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS ieps_trasladado NUMERIC(16,2) DEFAULT 0;
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS isr_retenido NUMERIC(16,2) DEFAULT 0;

-- Agregar campos de certificación SAT
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS fecha_emision TIMESTAMP;
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS fecha_timbrado TIMESTAMP;
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS fecha_certificacion TIMESTAMP;
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS certificado_sat VARCHAR(50);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS sello_cfdi TEXT;
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS sello_sat TEXT;
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS cadena_original_sat TEXT;
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS no_certificado_emisor VARCHAR(50);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS no_certificado_sat VARCHAR(50);

-- Agregar campos de relación CFDI
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS tipo_relacion VARCHAR(2);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS uuid_relacionados TEXT[];

-- Agregar campos de control
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS observaciones TEXT;
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS motivo_cancelacion VARCHAR(2);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS fecha_cancelacion TIMESTAMP;

-- Agregar constraints (primero eliminar si existen)
DO $$ 
BEGIN
    -- Drop constraints si existen
    ALTER TABLE facturas DROP CONSTRAINT IF EXISTS check_tipo_comprobante;
    ALTER TABLE facturas DROP CONSTRAINT IF EXISTS check_estado;
    ALTER TABLE facturas DROP CONSTRAINT IF EXISTS check_moneda;
    
    -- Crear constraints
    ALTER TABLE facturas ADD CONSTRAINT check_tipo_comprobante 
        CHECK (tipo_comprobante IN ('I', 'E', 'T', 'P', 'N'));
    
    ALTER TABLE facturas ADD CONSTRAINT check_estado 
        CHECK (estado IN ('BORRADOR', 'TIMBRADA', 'CANCELADA'));
    
    ALTER TABLE facturas ADD CONSTRAINT check_moneda 
        CHECK (moneda IN ('MXN', 'USD', 'EUR', 'CAD', 'GBP', 'JPY'));
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error al crear constraints: %', SQLERRM;
END $$;

-- ============================================
-- 3. CREAR TABLA DE CONCEPTOS (PRODUCTOS DE LA FACTURA)
-- ============================================

CREATE TABLE IF NOT EXISTS factura_conceptos (
    id SERIAL PRIMARY KEY,
    factura_id INTEGER NOT NULL REFERENCES facturas(id) ON DELETE CASCADE,
    
    -- Identificación del concepto
    clave_prod_serv VARCHAR(10) NOT NULL,
    no_identificacion VARCHAR(100),
    cantidad NUMERIC(16,6) NOT NULL,
    clave_unidad VARCHAR(10) NOT NULL,
    unidad VARCHAR(50),
    descripcion TEXT NOT NULL,
    
    -- Valores monetarios
    precio_unitario NUMERIC(16,6) NOT NULL,
    importe NUMERIC(16,2) NOT NULL,
    descuento NUMERIC(16,2) DEFAULT 0,
    
    -- Impuestos
    objeto_impuesto VARCHAR(2) NOT NULL DEFAULT '02',
    
    -- Orden
    numero_linea INTEGER NOT NULL,
    
    -- Control
    creado_en TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_factura_conceptos_factura ON factura_conceptos(factura_id);

-- Agregar constraints a factura_conceptos
DO $$ 
BEGIN
    ALTER TABLE factura_conceptos DROP CONSTRAINT IF EXISTS check_cantidad_positiva;
    ALTER TABLE factura_conceptos DROP CONSTRAINT IF EXISTS check_precio_positivo;
    ALTER TABLE factura_conceptos DROP CONSTRAINT IF EXISTS check_objeto_impuesto;
    
    ALTER TABLE factura_conceptos ADD CONSTRAINT check_cantidad_positiva 
        CHECK (cantidad > 0);
    ALTER TABLE factura_conceptos ADD CONSTRAINT check_precio_positivo 
        CHECK (precio_unitario >= 0);
    ALTER TABLE factura_conceptos ADD CONSTRAINT check_objeto_impuesto 
        CHECK (objeto_impuesto IN ('01', '02', '03', '04'));
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error al crear constraints en factura_conceptos: %', SQLERRM;
END $$;

COMMENT ON TABLE factura_conceptos IS 'Conceptos (productos/servicios) de cada factura';
COMMENT ON COLUMN factura_conceptos.clave_prod_serv IS 'Clave del catálogo de productos y servicios del SAT';
COMMENT ON COLUMN factura_conceptos.clave_unidad IS 'Clave de unidad de medida del SAT (H87=Pieza, E48=Servicio, etc)';
COMMENT ON COLUMN factura_conceptos.objeto_impuesto IS '01=No objeto, 02=Sí objeto, 03=Sí objeto pero no obligado, 04=Sí objeto no obligado devuelto';

-- ============================================
-- 4. CREAR TABLA DE IMPUESTOS DE CONCEPTOS
-- ============================================

CREATE TABLE IF NOT EXISTS factura_concepto_impuestos (
    id SERIAL PRIMARY KEY,
    concepto_id INTEGER NOT NULL REFERENCES factura_conceptos(id) ON DELETE CASCADE,
    
    -- Tipo de impuesto (traslado o retención)
    tipo_movimiento VARCHAR(10) NOT NULL,
    
    -- Datos del impuesto
    base NUMERIC(16,2) NOT NULL,
    impuesto VARCHAR(10) NOT NULL,
    tipo_factor VARCHAR(10) NOT NULL,
    tasa_o_cuota NUMERIC(8,6) NOT NULL,
    importe NUMERIC(16,2) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_concepto_impuestos_concepto ON factura_concepto_impuestos(concepto_id);

-- Agregar constraints a factura_concepto_impuestos
DO $$ 
BEGIN
    ALTER TABLE factura_concepto_impuestos DROP CONSTRAINT IF EXISTS check_tipo_movimiento;
    ALTER TABLE factura_concepto_impuestos DROP CONSTRAINT IF EXISTS check_impuesto;
    ALTER TABLE factura_concepto_impuestos DROP CONSTRAINT IF EXISTS check_tipo_factor;
    
    ALTER TABLE factura_concepto_impuestos ADD CONSTRAINT check_tipo_movimiento 
        CHECK (tipo_movimiento IN ('TRASLADO', 'RETENCION'));
    ALTER TABLE factura_concepto_impuestos ADD CONSTRAINT check_impuesto 
        CHECK (impuesto IN ('001', '002', '003'));
    ALTER TABLE factura_concepto_impuestos ADD CONSTRAINT check_tipo_factor 
        CHECK (tipo_factor IN ('Tasa', 'Cuota', 'Exento'));
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error al crear constraints en factura_concepto_impuestos: %', SQLERRM;
END $$;

COMMENT ON TABLE factura_concepto_impuestos IS 'Impuestos trasladados y retenidos por concepto';
COMMENT ON COLUMN factura_concepto_impuestos.impuesto IS '001=ISR, 002=IVA, 003=IEPS';
COMMENT ON COLUMN factura_concepto_impuestos.tipo_factor IS 'Tasa (porcentaje), Cuota (cantidad fija), Exento';

-- ============================================
-- 5. CREAR TABLA DE COMPLEMENTOS DE PAGO
-- ============================================

CREATE TABLE IF NOT EXISTS factura_pagos (
    id SERIAL PRIMARY KEY,
    factura_id INTEGER NOT NULL REFERENCES facturas(id) ON DELETE CASCADE,
    
    -- Datos del pago
    fecha_pago TIMESTAMP NOT NULL,
    forma_pago VARCHAR(10) NOT NULL,
    moneda VARCHAR(3) NOT NULL DEFAULT 'MXN',
    tipo_cambio NUMERIC(10,6),
    monto NUMERIC(16,2) NOT NULL,
    
    -- Datos de la operación
    num_operacion VARCHAR(100),
    rfc_emisor_cta_ord VARCHAR(13),
    nom_banco_ord VARCHAR(100),
    cta_ordenante VARCHAR(50),
    rfc_emisor_cta_ben VARCHAR(13),
    cta_beneficiario VARCHAR(50),
    
    -- Control
    creado_en TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_factura_pagos_factura ON factura_pagos(factura_id);

-- Agregar constraints a factura_pagos
DO $$ 
BEGIN
    ALTER TABLE factura_pagos DROP CONSTRAINT IF EXISTS check_monto_positivo;
    
    ALTER TABLE factura_pagos ADD CONSTRAINT check_monto_positivo 
        CHECK (monto > 0);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error al crear constraints en factura_pagos: %', SQLERRM;
END $$;

COMMENT ON TABLE factura_pagos IS 'Complemento de pagos para CFDI tipo P (Pago)';

-- ============================================
-- 6. VALORES PREDETERMINADOS Y DATOS INICIALES
-- ============================================

-- Insertar configuración fiscal por defecto (ACTUALIZAR CON TUS DATOS REALES)
INSERT INTO configuracion_fiscal (
    rfc_emisor,
    nombre_emisor,
    razon_social,
    regimen_fiscal,
    calle,
    numero_exterior,
    colonia,
    municipio,
    estado,
    pais,
    codigo_postal,
    activo
) VALUES (
    'XAXX010101000',
    'EMPRESA EJEMPLO SA DE CV',
    'EMPRESA EJEMPLO SA DE CV',
    '601',
    'CALLE EJEMPLO',
    '123',
    'COLONIA EJEMPLO',
    'CIUDAD DE MÉXICO',
    'CIUDAD DE MÉXICO',
    'México',
    '03410',
    true
) ON CONFLICT (rfc_emisor) DO NOTHING;

-- ============================================
-- 7. ACTUALIZAR FACTURAS EXISTENTES
-- ============================================

-- Actualizar facturas existentes con valores por defecto
UPDATE facturas 
SET 
    tipo_comprobante = 'I',
    moneda = 'MXN',
    fecha_emision = COALESCE(fecha, creada_en),
    subtotal = total,
    lugar_expedicion = '03410'
WHERE tipo_comprobante IS NULL;

-- Actualizar emisor en facturas existentes desde la configuración
UPDATE facturas f
SET 
    nombre_emisor = cf.nombre_emisor,
    regimen_fiscal_emisor = cf.regimen_fiscal
FROM configuracion_fiscal cf
WHERE f.rfc_emisor = cf.rfc_emisor 
AND f.nombre_emisor IS NULL;

-- ============================================
-- 8. VISTAS ÚTILES
-- ============================================

-- Vista completa de factura con conceptos
CREATE OR REPLACE VIEW v_facturas_completas AS
SELECT 
    f.id,
    f.serie,
    f.folio,
    f.uuid_sat,
    f.tipo_comprobante,
    f.fecha_emision,
    f.fecha_timbrado,
    
    -- Emisor
    f.rfc_emisor,
    f.nombre_emisor,
    f.regimen_fiscal_emisor,
    f.lugar_expedicion,
    
    -- Receptor
    f.rfc_receptor,
    f.nombre_receptor,
    f.regimen_fiscal_receptor,
    f.uso_cfdi,
    
    -- Totales
    f.moneda,
    f.tipo_cambio,
    f.subtotal,
    f.descuento,
    f.iva_trasladado,
    f.iva_retenido,
    f.ieps_trasladado,
    f.isr_retenido,
    f.total,
    
    -- Estado
    f.estado,
    f.forma_pago,
    f.metodo_pago,
    
    -- URLs
    f.xml_url,
    f.pdf_url,
    
    -- Conteos
    COUNT(fc.id) as total_conceptos,
    COUNT(DISTINCT fv.venta_id) as total_ventas,
    
    f.creada_en
FROM facturas f
LEFT JOIN factura_conceptos fc ON f.id = fc.factura_id
LEFT JOIN factura_ventas fv ON f.id = fv.factura_id
GROUP BY f.id;

COMMENT ON VIEW v_facturas_completas IS 'Vista completa de facturas con totales y conteos';

-- Vista de conceptos con impuestos
CREATE OR REPLACE VIEW v_conceptos_con_impuestos AS
SELECT 
    fc.id,
    fc.factura_id,
    fc.numero_linea,
    fc.clave_prod_serv,
    fc.no_identificacion,
    fc.cantidad,
    fc.clave_unidad,
    fc.unidad,
    fc.descripcion,
    fc.precio_unitario,
    fc.importe,
    fc.descuento,
    fc.objeto_impuesto,
    
    -- Impuestos trasladados
    SUM(CASE WHEN fci.tipo_movimiento = 'TRASLADO' THEN fci.importe ELSE 0 END) as impuestos_trasladados,
    
    -- Impuestos retenidos
    SUM(CASE WHEN fci.tipo_movimiento = 'RETENCION' THEN fci.importe ELSE 0 END) as impuestos_retenidos,
    
    -- Total del concepto
    fc.importe - fc.descuento + 
    SUM(CASE WHEN fci.tipo_movimiento = 'TRASLADO' THEN fci.importe ELSE 0 END) -
    SUM(CASE WHEN fci.tipo_movimiento = 'RETENCION' THEN fci.importe ELSE 0 END) as total_concepto
    
FROM factura_conceptos fc
LEFT JOIN factura_concepto_impuestos fci ON fc.id = fci.concepto_id
GROUP BY fc.id;

COMMENT ON VIEW v_conceptos_con_impuestos IS 'Vista de conceptos con cálculo de impuestos';

-- ============================================
-- 9. FUNCIONES AUXILIARES
-- ============================================

-- Función para calcular totales de factura
CREATE OR REPLACE FUNCTION fn_calcular_totales_factura(p_factura_id INTEGER)
RETURNS void AS $$
DECLARE
    v_subtotal NUMERIC(16,2);
    v_descuento NUMERIC(16,2);
    v_iva_trasladado NUMERIC(16,2);
    v_iva_retenido NUMERIC(16,2);
    v_ieps_trasladado NUMERIC(16,2);
    v_isr_retenido NUMERIC(16,2);
    v_total NUMERIC(16,2);
BEGIN
    -- Calcular subtotal
    SELECT COALESCE(SUM(importe), 0)
    INTO v_subtotal
    FROM factura_conceptos
    WHERE factura_id = p_factura_id;
    
    -- Calcular descuento total
    SELECT COALESCE(SUM(descuento), 0)
    INTO v_descuento
    FROM factura_conceptos
    WHERE factura_id = p_factura_id;
    
    -- Calcular IVA trasladado
    SELECT COALESCE(SUM(fci.importe), 0)
    INTO v_iva_trasladado
    FROM factura_conceptos fc
    JOIN factura_concepto_impuestos fci ON fc.id = fci.concepto_id
    WHERE fc.factura_id = p_factura_id
    AND fci.tipo_movimiento = 'TRASLADO'
    AND fci.impuesto = '002';
    
    -- Calcular IVA retenido
    SELECT COALESCE(SUM(fci.importe), 0)
    INTO v_iva_retenido
    FROM factura_conceptos fc
    JOIN factura_concepto_impuestos fci ON fc.id = fci.concepto_id
    WHERE fc.factura_id = p_factura_id
    AND fci.tipo_movimiento = 'RETENCION'
    AND fci.impuesto = '002';
    
    -- Calcular IEPS trasladado
    SELECT COALESCE(SUM(fci.importe), 0)
    INTO v_ieps_trasladado
    FROM factura_conceptos fc
    JOIN factura_concepto_impuestos fci ON fc.id = fci.concepto_id
    WHERE fc.factura_id = p_factura_id
    AND fci.tipo_movimiento = 'TRASLADO'
    AND fci.impuesto = '003';
    
    -- Calcular ISR retenido
    SELECT COALESCE(SUM(fci.importe), 0)
    INTO v_isr_retenido
    FROM factura_conceptos fc
    JOIN factura_concepto_impuestos fci ON fc.id = fci.concepto_id
    WHERE fc.factura_id = p_factura_id
    AND fci.tipo_movimiento = 'RETENCION'
    AND fci.impuesto = '001';
    
    -- Calcular total
    v_total := v_subtotal - v_descuento + v_iva_trasladado - v_iva_retenido + v_ieps_trasladado - v_isr_retenido;
    
    -- Actualizar factura
    UPDATE facturas
    SET 
        subtotal = v_subtotal,
        descuento = v_descuento,
        iva_trasladado = v_iva_trasladado,
        iva_retenido = v_iva_retenido,
        ieps_trasladado = v_ieps_trasladado,
        isr_retenido = v_isr_retenido,
        total = v_total
    WHERE id = p_factura_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION fn_calcular_totales_factura IS 'Recalcula todos los totales e impuestos de una factura';

-- ============================================
-- 10. TRIGGERS
-- ============================================

-- Trigger para recalcular totales al insertar/actualizar conceptos
CREATE OR REPLACE FUNCTION trg_recalcular_totales_factura()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM fn_calcular_totales_factura(
        CASE 
            WHEN TG_OP = 'DELETE' THEN OLD.factura_id
            ELSE NEW.factura_id
        END
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_factura_conceptos_totales ON factura_conceptos;
CREATE TRIGGER trg_factura_conceptos_totales
    AFTER INSERT OR UPDATE OR DELETE ON factura_conceptos
    FOR EACH ROW
    EXECUTE FUNCTION trg_recalcular_totales_factura();

-- ============================================
-- 11. ÍNDICES PARA OPTIMIZACIÓN
-- ============================================

CREATE INDEX IF NOT EXISTS idx_facturas_uuid ON facturas(uuid_sat);
CREATE INDEX IF NOT EXISTS idx_facturas_fecha_emision ON facturas(fecha_emision);
CREATE INDEX IF NOT EXISTS idx_facturas_estado ON facturas(estado);
CREATE INDEX IF NOT EXISTS idx_facturas_rfc_receptor ON facturas(rfc_receptor);
CREATE INDEX IF NOT EXISTS idx_facturas_serie_folio ON facturas(serie, folio);

-- ============================================
-- SCRIPT COMPLETADO
-- ============================================

SELECT 'Actualización de facturación completada exitosamente' as mensaje;
SELECT 'IMPORTANTE: Actualizar configuracion_fiscal con los datos reales de tu empresa' as nota;
