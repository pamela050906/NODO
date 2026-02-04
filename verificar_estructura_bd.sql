-- Script para verificar la estructura real de la tabla usuarios
-- Ejecuta esto en pgAdmin para ver qué columnas tiene realmente tu tabla

-- Ver todas las columnas de la tabla usuarios
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'usuarios'
ORDER BY ordinal_position;

-- Ver los datos actuales
SELECT * FROM usuarios LIMIT 5;

-- Ver qué base de datos estás usando
SELECT current_database();
