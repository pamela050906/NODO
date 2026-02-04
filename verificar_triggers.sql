-- Script para verificar que los triggers se crearon correctamente
-- Ejecutar en psql: \i verificar_triggers.sql

-- Verificar triggers en venta_detalle
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'venta_detalle'
ORDER BY trigger_name;

-- Verificar funciones creadas
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    'fn_precio_automatico_acumulado',
    'fn_recalcular_totales_venta'
)
ORDER BY routine_name;

-- Resultado esperado:
-- Deberías ver:
-- 1. trg_precio_automatico_acumulado (BEFORE INSERT)
-- 2. trg_recalcular_totales (AFTER INSERT OR UPDATE OR DELETE)
-- 3. Las dos funciones listadas arriba
