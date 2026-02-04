-- Migración 003: Módulo de Cobranza
-- Fecha: 2026-01-21
-- Propósito: Implementar ventas a crédito y cuentas por cobrar

-- 1. Crear tabla de clientes (si no existe)
CREATE TABLE IF NOT EXISTS clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    rfc VARCHAR(13),
    telefono VARCHAR(15),
    email VARCHAR(150),
    direccion TEXT,
    limite_credito NUMERIC(12,2) DEFAULT 0,
    activo BOOLEAN DEFAULT true,
    creado_en TIMESTAMP DEFAULT NOW()
);

-- 2. Crear tabla de cuentas por cobrar
CREATE TABLE IF NOT EXISTS cuentas_por_cobrar (
    id SERIAL PRIMARY KEY,
    venta_id INTEGER NOT NULL REFERENCES ventas(id),
    cliente_id INTEGER NOT NULL REFERENCES clientes(id),
    monto_total NUMERIC(12,2) NOT NULL,
    monto_pagado NUMERIC(12,2) DEFAULT 0,
    saldo_pendiente NUMERIC(12,2) NOT NULL,
    fecha_vencimiento DATE,
    estado VARCHAR(20) DEFAULT 'PENDIENTE',
    creada_en TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT cuentas_saldo_check CHECK (saldo_pendiente >= 0),
    CONSTRAINT cuentas_estado_check CHECK (estado IN ('PENDIENTE', 'PAGADA', 'VENCIDA'))
);

-- 3. Crear tabla de pagos/abonos
CREATE TABLE IF NOT EXISTS pagos_cuenta (
    id SERIAL PRIMARY KEY,
    cuenta_id INTEGER NOT NULL REFERENCES cuentas_por_cobrar(id),
    monto NUMERIC(12,2) NOT NULL,
    metodo_pago VARCHAR(20) NOT NULL,
    referencia VARCHAR(100),
    notas TEXT,
    usuario_id INTEGER REFERENCES usuarios(id),
    creado_en TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT pagos_monto_check CHECK (monto > 0),
    CONSTRAINT pagos_metodo_check CHECK (metodo_pago IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'CHEQUE'))
);

-- 4. Agregar campo cliente_id a ventas (si no existe)
ALTER TABLE ventas ADD COLUMN IF NOT EXISTS cliente_id INTEGER REFERENCES clientes(id);

-- 5. Agregar campo tipo_venta para distinguir contado/crédito
ALTER TABLE ventas ADD COLUMN IF NOT EXISTS tipo_venta VARCHAR(20) DEFAULT 'CONTADO';

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ventas_tipo_venta_check') THEN
        ALTER TABLE ventas ADD CONSTRAINT ventas_tipo_venta_check 
        CHECK (tipo_venta IN ('CONTADO', 'CREDITO'));
    END IF;
END $$;

-- 6. Crear función trigger para actualizar cuenta al registrar pago
CREATE OR REPLACE FUNCTION fn_actualizar_cuenta_pago()
RETURNS TRIGGER AS $$
DECLARE
    v_saldo_nuevo NUMERIC(12,2);
BEGIN
    -- Actualizar monto pagado y saldo
    UPDATE cuentas_por_cobrar
    SET monto_pagado = monto_pagado + NEW.monto,
        saldo_pendiente = saldo_pendiente - NEW.monto
    WHERE id = NEW.cuenta_id;
    
    -- Obtener nuevo saldo
    SELECT saldo_pendiente INTO v_saldo_nuevo
    FROM cuentas_por_cobrar
    WHERE id = NEW.cuenta_id;
    
    -- Actualizar estado si está pagada completamente
    IF v_saldo_nuevo <= 0 THEN
        UPDATE cuentas_por_cobrar
        SET estado = 'PAGADA',
            saldo_pendiente = 0
        WHERE id = NEW.cuenta_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_actualizar_cuenta_pago ON pagos_cuenta;

CREATE TRIGGER trg_actualizar_cuenta_pago
    AFTER INSERT ON pagos_cuenta
    FOR EACH ROW
    EXECUTE FUNCTION fn_actualizar_cuenta_pago();

-- 7. Crear índices para performance
CREATE INDEX IF NOT EXISTS idx_cuentas_cliente ON cuentas_por_cobrar(cliente_id);
CREATE INDEX IF NOT EXISTS idx_cuentas_estado ON cuentas_por_cobrar(estado);
CREATE INDEX IF NOT EXISTS idx_cuentas_vencimiento ON cuentas_por_cobrar(fecha_vencimiento);
CREATE INDEX IF NOT EXISTS idx_pagos_cuenta ON pagos_cuenta(cuenta_id);
CREATE INDEX IF NOT EXISTS idx_ventas_cliente ON ventas(cliente_id);

-- 8. Insertar cliente genérico para ventas sin cliente
INSERT INTO clientes (nombre, rfc, activo) 
VALUES ('PÚBLICO EN GENERAL', 'XAXX010101000', true)
ON CONFLICT DO NOTHING;

COMMENT ON TABLE cuentas_por_cobrar IS 'Cuentas por cobrar de ventas a crédito';
COMMENT ON TABLE pagos_cuenta IS 'Pagos/abonos a cuentas por cobrar';
COMMENT ON COLUMN ventas.tipo_venta IS 'CONTADO (pago inmediato) o CREDITO (pago diferido)';
