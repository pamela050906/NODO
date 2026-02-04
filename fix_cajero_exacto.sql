-- Script para replicar EXACTAMENTE la estructura del Admin para Cajero
-- Basado en el Admin que funciona: nombre='admin', rol_id=1, activo=true

-- 1. Ver estructura del Admin (que funciona)
SELECT 
    'Admin (funciona)' as referencia,
    id,
    nombre,
    email,
    rol_id,
    activo
FROM usuarios 
WHERE nombre = 'admin';

-- 2. Ver estructura actual del Cajero
SELECT 
    'Cajero (actual)' as referencia,
    id,
    nombre,
    email,
    rol_id,
    activo
FROM usuarios 
WHERE nombre = 'Cajero';

-- 3. ACTUALIZAR Cajero para que tenga EXACTAMENTE la misma estructura que Admin
-- Solo cambiamos: nombre='Cajero', email='cajero@local.com', rol_id=2
-- Hash para cajero123: $2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36BvQxW5wVaD8IfaKZ1.dCS

UPDATE usuarios 
SET 
    nombre = 'Cajero',
    email = 'cajero@local.com',
    password_hash = '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36BvQxW5wVaD8IfaKZ1.dCS',
    rol_id = 2,
    activo = true
WHERE id = 2;

-- 4. Verificar que quedó igual que Admin (solo cambia nombre, email y rol_id)
SELECT 
    id,
    nombre,
    email,
    rol_id,
    activo,
    CASE 
        WHEN nombre = 'admin' THEN '✅ Admin (funciona)'
        WHEN nombre = 'Cajero' AND rol_id = 2 AND activo = true THEN '✅ Cajero (debe funcionar igual)'
        ELSE '❌ Revisar'
    END as estado
FROM usuarios
WHERE nombre IN ('admin', 'Cajero')
ORDER BY id;

-- 5. Comparación lado a lado
SELECT 
    'admin' as usuario,
    nombre,
    email,
    rol_id,
    activo
FROM usuarios WHERE nombre = 'admin'
UNION ALL
SELECT 
    'Cajero' as usuario,
    nombre,
    email,
    rol_id,
    activo
FROM usuarios WHERE nombre = 'Cajero';
