-- Script para verificar y corregir el usuario Cajero
-- Ejecutar en pgAdmin o desde psql conectado a la BD almacen_db

-- 1. Verificar si el usuario existe
SELECT id, nombre, email, rol_id, activo, password_hash
FROM usuarios
WHERE nombre ILIKE '%cajero%' OR email ILIKE '%cajero%';

-- 2. Verificar los roles disponibles
SELECT id, nombre FROM roles ORDER BY id;

-- 3. Insertar o actualizar usuario Cajero
-- Hash para cajero123: $2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36BvQxW5wVaD8IfaKZ1.dCS

-- Opción A: Si el usuario NO existe, insertarlo
INSERT INTO usuarios (nombre, email, password_hash, rol_id, activo)
VALUES ('Cajero', 'cajero@local.com', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36BvQxW5wVaD8IfaKZ1.dCS', 2, true)
ON CONFLICT (email) DO NOTHING;

-- Opción B: Si el usuario existe pero tiene problemas, actualizarlo
UPDATE usuarios 
SET 
    nombre = 'Cajero',
    password_hash = '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36BvQxW5wVaD8IfaKZ1.dCS',
    rol_id = 2,
    activo = true
WHERE email = 'cajero@local.com' OR nombre ILIKE '%cajero%';

-- 4. Verificar el resultado final
SELECT 
    id, 
    nombre, 
    email, 
    rol_id, 
    (SELECT nombre FROM roles WHERE id = usuarios.rol_id) as rol_nombre,
    activo
FROM usuarios
WHERE nombre = 'Cajero' OR email = 'cajero@local.com';

-- 5. Verificar todos los usuarios activos
SELECT 
    u.id,
    u.nombre,
    u.email,
    r.nombre as rol,
    u.activo
FROM usuarios u
JOIN roles r ON u.rol_id = r.id
WHERE u.activo = true
ORDER BY u.id;
