-- Script para replicar exactamente la estructura del Admin pero para Cajero
-- Basado en cómo funciona el Admin (nombre='admin', minúscula)

-- 1. Verificar cómo está el Admin (que funciona)
SELECT 
    id, 
    nombre, 
    email, 
    rol_id, 
    activo,
    LEFT(password_hash, 30) as hash_preview
FROM usuarios 
WHERE nombre = 'admin';

-- 2. Verificar cómo está el Cajero actual
SELECT 
    id, 
    nombre, 
    email, 
    rol_id, 
    activo,
    LEFT(password_hash, 30) as hash_preview
FROM usuarios 
WHERE nombre ILIKE '%cajero%';

-- 3. ACTUALIZAR el usuario Cajero para que sea EXACTAMENTE como Admin pero con datos de Cajero
-- Hash para cajero123: $2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36BvQxW5wVaD8IfaKZ1.dCS

-- Opción A: Si el usuario Cajero existe, actualizarlo
UPDATE usuarios 
SET 
    nombre = 'Cajero',  -- Mantener mayúscula C como está en la BD
    email = 'cajero@local.com',
    password_hash = '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36BvQxW5wVaD8IfaKZ1.dCS',
    rol_id = 2,
    activo = true
WHERE id = 2 OR email = 'cajero@local.com';

-- Opción B: Si no existe, insertarlo (pero ya existe según la consulta anterior)
INSERT INTO usuarios (nombre, email, password_hash, rol_id, activo)
VALUES ('Cajero', 'cajero@local.com', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36BvQxW5wVaD8IfaKZ1.dCS', 2, true)
ON CONFLICT (email) DO UPDATE 
SET 
    nombre = 'Cajero',
    password_hash = '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36BvQxW5wVaD8IfaKZ1.dCS',
    rol_id = 2,
    activo = true;

-- 4. Verificar resultado final - comparar Admin vs Cajero
SELECT 
    id,
    nombre,
    email,
    rol_id,
    activo,
    CASE 
        WHEN nombre = 'admin' THEN '✅ Admin (funciona)'
        WHEN nombre = 'Cajero' THEN '✅ Cajero (debe funcionar igual)'
        ELSE '❓ Otro usuario'
    END as estado
FROM usuarios
WHERE nombre IN ('admin', 'Cajero')
ORDER BY id;

-- 5. Verificar que ambos tienen la misma estructura
SELECT 
    'admin' as usuario_esperado,
    nombre as nombre_real,
    email,
    rol_id,
    activo,
    CASE 
        WHEN nombre = 'admin' AND rol_id = 1 AND activo = true THEN '✅ Correcto'
        ELSE '❌ Revisar'
    END as validacion
FROM usuarios WHERE nombre = 'admin'
UNION ALL
SELECT 
    'Cajero' as usuario_esperado,
    nombre as nombre_real,
    email,
    rol_id,
    activo,
    CASE 
        WHEN nombre = 'Cajero' AND rol_id = 2 AND activo = true THEN '✅ Correcto'
        ELSE '❌ Revisar'
    END as validacion
FROM usuarios WHERE nombre = 'Cajero';
