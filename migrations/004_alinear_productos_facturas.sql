-- Migración 004: Alinear productos y facturas con backend
-- Fecha: 2026-01-21
-- Propósito: Evitar errores por columnas faltantes

-- 1) Productos: agregar columnas faltantes
ALTER TABLE productos ADD COLUMN IF NOT EXISTS categoria VARCHAR(100);
ALTER TABLE productos ADD COLUMN IF NOT EXISTS marca VARCHAR(100);
ALTER TABLE productos ADD COLUMN IF NOT EXISTS actualizado_en TIMESTAMP;

ALTER TABLE productos
    ALTER COLUMN actualizado_en SET DEFAULT NOW();

-- 2) Facturas: agregar columnas faltantes
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS serie VARCHAR(10);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS folio INTEGER;
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS uso_cfdi VARCHAR(10);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS forma_pago VARCHAR(10);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS metodo_pago VARCHAR(10);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS estado VARCHAR(20) DEFAULT 'BORRADOR';
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS xml_content TEXT;
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS xml_url VARCHAR(500);
ALTER TABLE facturas ADD COLUMN IF NOT EXISTS pdf_url VARCHAR(500);

ALTER TABLE facturas
    ALTER COLUMN estado SET DEFAULT 'BORRADOR';

-- 3) Índices útiles
CREATE UNIQUE INDEX IF NOT EXISTS idx_facturas_uuid_sat ON facturas(uuid_sat);
CREATE INDEX IF NOT EXISTS idx_facturas_estado ON facturas(estado);
CREATE INDEX IF NOT EXISTS idx_facturas_fecha ON facturas(fecha);
