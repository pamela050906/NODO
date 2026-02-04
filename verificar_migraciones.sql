-- Script de verificación rápida de migraciones
-- Ejecutar en psql: \i verificar_migraciones.sql

-- ============================================
-- VERIFICACIÓN MIGRACIÓN 001
-- ============================================
SELECT 'MIGRACIÓN 001 - Campos en ventas' as verificacion;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'ventas'
AND column_name IN ('subtotal', 'descuento', 'impuesto', 'estado', 'completed_at')
ORDER BY column_name;

-- ============================================
-- VERIFICACIÓN MIGRACIÓN 002
-- ============================================
SELECT 'MIGRACIÓN 002 - Triggers y funciones' as verificacion;

-- Verificar funciones
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    'fn_precio_automatico_acumulado',
    'fn_recalcular_totales_venta'
);

-- Verificar triggers en venta_detalle
SELECT trigger_name, action_timing, event_manipulation
FROM information_schema.triggers
WHERE event_object_table = 'venta_detalle'
AND trigger_name IN (
    'trg_precio_automatico_acumulado',
    'trg_recalcular_totales'
);

-- ============================================
-- VERIFICACIÓN MIGRACIÓN 003
-- ============================================
SELECT 'MIGRACIÓN 003 - Tablas de cobranza' as verificacion;

-- Verificar tablas creadas
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
    'clientes',
    'cuentas_por_cobrar',
    'pagos_cuenta'
)
ORDER BY table_name;

-- Verificar trigger de cobranza
SELECT trigger_name, action_timing, event_manipulation
FROM information_schema.triggers
WHERE event_object_table = 'pagos_cuenta'
AND trigger_name = 'trg_actualizar_cuenta_pago';

-- Verificar función de cobranza
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name = 'fn_actualizar_cuenta_pago';

-- Verificar campo cliente_id en ventas
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'ventas'
AND column_name = 'cliente_id';

-- ============================================
-- RESUMEN
-- ============================================
SELECT '✅ Si ves todas las tablas, triggers y funciones arriba, las migraciones están OK' as resultado;
