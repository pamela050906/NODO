# ⚡ Comandos Rápidos - Cheat Sheet

## 🚀 Inicio Rápido

```bash
# 1. Levantar todo
docker-compose up -d

# 2. Inicializar DB
docker cp init_db.sql pos_db:/tmp/init_db.sql && \
docker-compose exec db psql -U postgres -d pos_db -f /tmp/init_db.sql

# 3. Verificar
curl http://localhost:8000/health
```

## 🔐 Autenticación

```bash
# Login y guardar token
TOKEN=$(curl -s -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123" | jq -r '.access_token')

# Ver usuario actual
curl -s "http://localhost:8000/api/v1/auth/me" \
  -H "Authorization: Bearer $TOKEN" | jq .
```

## 🛒 Flujo Completo de Venta

```bash
# 1. Login
TOKEN=$(curl -s -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123" | jq -r '.access_token')

# 2. Crear venta vacía
VENTA_ID=$(curl -s -X POST "http://localhost:8000/api/v1/sales" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "cliente_nombre": "Juan Pérez",
    "metodo_pago": "EFECTIVO",
    "descuento_general": 0,
    "detalles": []
  }' | jq -r '.id')

echo "Venta creada: $VENTA_ID"

# 3. Agregar Mouse (código: 7501234567891)
curl -s -X POST "http://localhost:8000/api/v1/sales/$VENTA_ID/item" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "codigo_barras": "7501234567891",
    "cantidad": 2,
    "descuento": 10.00
  }' | jq .

# 4. Agregar Teclado (código: 7501234567892)
curl -s -X POST "http://localhost:8000/api/v1/sales/$VENTA_ID/item" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "codigo_barras": "7501234567892",
    "cantidad": 1,
    "descuento": 0
  }' | jq .

# 5. Ver venta completa
curl -s "http://localhost:8000/api/v1/sales/$VENTA_ID" \
  -H "Authorization: Bearer $TOKEN" | jq .

# 6. Completar venta
curl -s -X POST "http://localhost:8000/api/v1/sales/$VENTA_ID/complete" \
  -H "Authorization: Bearer $TOKEN" | jq .
```

## 📊 Consultas

```bash
# Listar todas las ventas
curl -s "http://localhost:8000/api/v1/sales" \
  -H "Authorization: Bearer $TOKEN" | jq .

# Listar solo pendientes
curl -s "http://localhost:8000/api/v1/sales?estado=PENDIENTE" \
  -H "Authorization: Bearer $TOKEN" | jq .

# Listar con paginación
curl -s "http://localhost:8000/api/v1/sales?skip=0&limit=10" \
  -H "Authorization: Bearer $TOKEN" | jq .
```

## 🗄️ Base de Datos

```bash
# Conectar a PostgreSQL
docker-compose exec db psql -U postgres -d pos_db

# Ver tablas
docker-compose exec db psql -U postgres -d pos_db -c "\dt"

# Ver productos con stock
docker-compose exec db psql -U postgres -d pos_db -c "SELECT * FROM v_productos_stock;"

# Ver ventas de hoy
docker-compose exec db psql -U postgres -d pos_db -c "SELECT * FROM v_ventas_hoy;"

# Backup
docker-compose exec db pg_dump -U postgres pos_db > backup_$(date +%Y%m%d).sql

# Restore
docker-compose exec -T db psql -U postgres -d pos_db < backup.sql
```

## 🐳 Docker

```bash
# Ver servicios corriendo
docker-compose ps

# Ver logs del backend
docker-compose logs -f backend

# Ver logs de la base de datos
docker-compose logs -f db

# Reiniciar servicios
docker-compose restart

# Reconstruir imágenes
docker-compose up -d --build

# Parar todo
docker-compose down

# Parar y eliminar volúmenes (¡CUIDADO!)
docker-compose down -v
```

## 🧪 Testing

```bash
# Test automático completo
chmod +x test_api.sh
./test_api.sh

# Test con Python
python examples/test_client.py

# Test individual: Health check
curl http://localhost:8000/health | jq .

# Test individual: Login
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123" | jq .
```

## 📝 Datos de Prueba

### Usuarios
```
admin / admin123 (ADMIN)
cajero / cajero123 (CAJERO)
```

### Productos
```
7501234567890 - Laptop Dell Inspiron - $15,999 (stock: 10)
7501234567891 - Mouse Logitech M185 - $299 (stock: 50)
7501234567892 - Teclado Mecánico RGB - $1,899 (stock: 20)
```

## 🔍 Debugging

```bash
# Ver logs en tiempo real con filtro
docker-compose logs -f backend | grep ERROR

# Ver último error
docker-compose logs backend --tail 50 | grep -i error

# Ejecutar comando en contenedor
docker-compose exec backend bash

# Ver variables de entorno
docker-compose exec backend env

# Ver procesos
docker-compose exec backend ps aux
```

## 📊 SQL Útiles

```sql
-- Conectar primero:
-- docker-compose exec db psql -U postgres -d pos_db

-- Ver stock bajo
SELECT * FROM v_productos_stock WHERE estado_stock = 'STOCK_BAJO';

-- Ver ventas del día
SELECT * FROM v_ventas_hoy;

-- Reporte de ventas
SELECT 
    DATE(created_at) as fecha,
    COUNT(*) as total_ventas,
    SUM(total) as monto_total
FROM ventas
WHERE estado = 'COMPLETADA'
GROUP BY DATE(created_at)
ORDER BY fecha DESC;

-- Productos más vendidos
SELECT 
    vd.producto_nombre,
    SUM(vd.cantidad) as total_vendido,
    SUM(vd.subtotal) as monto_total
FROM venta_detalle vd
JOIN ventas v ON vd.venta_id = v.id
WHERE v.estado = 'COMPLETADA'
GROUP BY vd.producto_nombre
ORDER BY total_vendido DESC
LIMIT 10;

-- Verificar inventario
SELECT 
    p.nombre,
    vp.codigo_barras,
    i.cantidad,
    i.stock_minimo,
    CASE 
        WHEN i.cantidad <= 0 THEN 'SIN_STOCK'
        WHEN i.cantidad <= i.stock_minimo THEN 'ALERTA'
        ELSE 'OK'
    END as estado
FROM productos p
JOIN variantes_producto vp ON p.id = vp.producto_id
JOIN inventario i ON vp.id = i.variante_producto_id;
```

## 🔧 Mantenimiento

```bash
# Ver uso de espacio
docker system df

# Limpiar contenedores parados
docker container prune

# Limpiar imágenes sin usar
docker image prune

# Limpiar volúmenes sin usar
docker volume prune

# Limpiar todo (¡CUIDADO!)
docker system prune -a
```

## 📡 URLs Importantes

```
http://localhost:8000          - API Base
http://localhost:8000/docs     - Swagger UI (Documentación interactiva)
http://localhost:8000/redoc    - ReDoc (Documentación alternativa)
http://localhost:8000/openapi.json - OpenAPI Spec
http://localhost:8000/health   - Health Check
```

## 💡 Tips Rápidos

```bash
# Alias útiles (agregar a .bashrc o .zshrc)
alias pos-up='docker-compose up -d'
alias pos-down='docker-compose down'
alias pos-logs='docker-compose logs -f backend'
alias pos-db='docker-compose exec db psql -U postgres -d pos_db'
alias pos-restart='docker-compose restart backend'

# Función para login rápido
pos-login() {
    curl -s -X POST "http://localhost:8000/api/v1/auth/login" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "username=$1&password=$2" | jq -r '.access_token'
}

# Uso: TOKEN=$(pos-login admin admin123)
```

## 🚨 Solución Rápida de Problemas

```bash
# Problema: Puerto 8000 ocupado
# Solución en Windows:
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Solución en Linux/Mac:
lsof -ti:8000 | xargs kill -9

# Problema: DB no responde
# Solución:
docker-compose restart db
# Esperar 10 segundos
docker-compose restart backend

# Problema: Error de conexión a DB
# Solución:
docker-compose down
docker-compose up -d
# Esperar a que DB esté ready
docker-compose logs db | grep "ready to accept"

# Problema: Cambios en código no se reflejan
# Solución:
docker-compose restart backend
# O reconstruir:
docker-compose up -d --build

# Problema: Olvidé el token
# Solución:
TOKEN=$(curl -s -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123" | jq -r '.access_token')
echo $TOKEN
```

## 📦 One-Liners Útiles

```bash
# Todo en uno: Login, crear venta, agregar ítem
TOKEN=$(curl -s -X POST "http://localhost:8000/api/v1/auth/login" -H "Content-Type: application/x-www-form-urlencoded" -d "username=admin&password=admin123" | jq -r '.access_token') && \
VENTA_ID=$(curl -s -X POST "http://localhost:8000/api/v1/sales" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"cliente_nombre":"Test","metodo_pago":"EFECTIVO","descuento_general":0,"detalles":[]}' | jq -r '.id') && \
curl -s -X POST "http://localhost:8000/api/v1/sales/$VENTA_ID/item" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"codigo_barras":"7501234567891","cantidad":1,"descuento":0}' | jq .

# Ver todas las ventas de hoy con detalles
curl -s "http://localhost:8000/api/v1/sales" -H "Authorization: Bearer $(curl -s -X POST "http://localhost:8000/api/v1/auth/login" -H "Content-Type: application/x-www-form-urlencoded" -d "username=admin&password=admin123" | jq -r '.access_token')" | jq '.[] | select(.created_at | startswith("'$(date +%Y-%m-%d)'"))'

# Reinicio completo
docker-compose down && docker-compose up -d && sleep 5 && curl http://localhost:8000/health
```

---

**Tip**: Guarda los comandos que más uses y crea aliases para trabajar más rápido.
