-- Migración 002: Mejorar lógica de precios por acumulado
-- Fecha: 2026-01-21
-- Propósito: Implementar precio mayoreo cuando cantidad ACUMULADA en venta >= 12

-- 1. Crear función mejorada que calcula precio por acumulado
CREATE OR REPLACE FUNCTION fn_precio_automatico_acumulado()
RETURNS TRIGGER AS $$
DECLARE
    v_precio_menudeo NUMERIC(10,2);
    v_precio_mayoreo NUMERIC(10,2);
    v_cantidad_total INTEGER;
    v_precio_aplicar NUMERIC(10,2);
BEGIN
    -- Obtener precios de la variante
    SELECT precio_menudeo, precio_mayoreo
    INTO v_precio_menudeo, v_precio_mayoreo
    FROM variantes_producto
    WHERE id = NEW.variante_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Variante % no encontrada', NEW.variante_id;
    END IF;

    -- Calcular cantidad total acumulada de esta variante en la venta
    SELECT COALESCE(SUM(cantidad), 0) + NEW.cantidad
    INTO v_cantidad_total
    FROM venta_detalle
    WHERE venta_id = NEW.venta_id
    AND variante_id = NEW.variante_id;

    -- Aplicar precio según cantidad acumulada
    IF v_cantidad_total >= 12 THEN
        v_precio_aplicar := v_precio_mayoreo;
        
        -- IMPORTANTE: Actualizar TODOS los detalles de esta variante en la venta
        -- para que tengan el precio de mayoreo
        UPDATE venta_detalle
        SET precio_unitario = v_precio_mayoreo,
            subtotal = cantidad * v_precio_mayoreo
        WHERE venta_id = NEW.venta_id
        AND variante_id = NEW.variante_id;
    ELSE
        v_precio_aplicar := v_precio_menudeo;
    END IF;

    -- Asignar precio al nuevo detalle
    NEW.precio_unitario := v_precio_aplicar;
    NEW.subtotal := NEW.cantidad * v_precio_aplicar;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Reemplazar trigger existente
DROP TRIGGER IF EXISTS trg_precio_automatico ON venta_detalle;

CREATE TRIGGER trg_precio_automatico_acumulado
    BEFORE INSERT ON venta_detalle
    FOR EACH ROW
    EXECUTE FUNCTION fn_precio_automatico_acumulado();

-- 3. Crear función para recalcular totales de venta automáticamente
CREATE OR REPLACE FUNCTION fn_recalcular_totales_venta()
RETURNS TRIGGER AS $$
DECLARE
    v_subtotal NUMERIC(12,2);
    v_total NUMERIC(12,2);
BEGIN
    -- Calcular subtotal sumando todos los detalles
    SELECT COALESCE(SUM(subtotal), 0)
    INTO v_subtotal
    FROM venta_detalle
    WHERE venta_id = COALESCE(NEW.venta_id, OLD.venta_id);

    -- Por ahora total = subtotal (sin descuentos ni impuestos)
    v_total := v_subtotal;

    -- Actualizar venta
    UPDATE ventas
    SET subtotal = v_subtotal,
        total = v_total
    WHERE id = COALESCE(NEW.venta_id, OLD.venta_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 4. Crear trigger para recalcular totales
DROP TRIGGER IF EXISTS trg_recalcular_totales ON venta_detalle;

CREATE TRIGGER trg_recalcular_totales
    AFTER INSERT OR UPDATE OR DELETE ON venta_detalle
    FOR EACH ROW
    EXECUTE FUNCTION fn_recalcular_totales_venta();

COMMENT ON FUNCTION fn_precio_automatico_acumulado() IS 'Aplica precio mayoreo cuando cantidad acumulada de un producto en la venta >= 12';
COMMENT ON FUNCTION fn_recalcular_totales_venta() IS 'Recalcula automáticamente subtotal y total de la venta';
