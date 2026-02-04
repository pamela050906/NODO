# 📋 Contrato de API - ERP/POS Sistema

## 📁 Archivo: `openapi.yaml`

Este es el **contrato oficial** del sistema. Define:
- ✅ Todos los endpoints disponibles
- ✅ Request/response schemas
- ✅ Códigos de error
- ✅ Autenticación y seguridad
- ✅ Ejemplos de uso

---

## 🎯 Filosofía del Contrato

### Principios CLAVE

1. **PostgreSQL = Lógica de negocio**
   - Los precios se calculan en la BD
   - El inventario se valida en la BD
   - Las reglas (mayoreo/menudeo) están en la BD

2. **FastAPI = Fachada segura**
   - Valida payloads
   - Autentica usuarios
   - Llama a funciones SQL
   - Devuelve respuestas

3. **Frontend = Interfaz**
   - Solo consume el API
   - No tiene lógica de precios ni inventario
   - Muestra información

---

## 🔗 Endpoints por Módulo

### 🔐 Autenticación

```
POST /api/v1/auth/login       → Obtener JWT
GET  /api/v1/auth/me          → Info del usuario actual
```

### 💰 POS (Flujo crítico)

```
GET  /api/v1/pos/barcode/{codigo}           → Escanear código de barras
POST /api/v1/ventas                         → Crear venta nueva
POST /api/v1/ventas/{id}/items              → Agregar producto
DELETE /api/v1/ventas/{id}/items/{detalle}  → Quitar producto
POST /api/v1/ventas/{id}/cerrar             → Cerrar venta
POST /api/v1/ventas/{id}/cancelar           → Cancelar venta
```

### 📦 Productos e Inventario

```
GET  /api/v1/productos                      → Listar productos
GET  /api/v1/productos/{id}                 → Detalle de producto
GET  /api/v1/inventario/stock               → Consultar stock
GET  /api/v1/inventario/stock/bajo          → Productos con stock bajo
POST /api/v1/inventario/movimientos         → Registrar entrada/salida
```

### 🧾 Facturación SAT

```
POST /api/v1/facturas                       → Crear factura (borrador)
POST /api/v1/facturas/{id}/timbrar          → Timbrar con PAC
POST /api/v1/facturas/global/tarjetas       → Factura global de tarjetas
GET  /api/v1/facturas/{id}                  → Detalle de factura
```

---

## 🔒 Seguridad

### Autenticación JWT

Todos los endpoints (excepto `/auth/login` y `/health`) requieren:

```http
Authorization: Bearer {token}
```

### Flujo de autenticación

1. **Login**: `POST /auth/login`
   ```json
   {
     "username": "admin",
     "password": "admin123"
   }
   ```

2. **Respuesta**:
   ```json
   {
     "access_token": "eyJhbG...",
     "token_type": "bearer",
     "user": {
       "id": 1,
       "username": "admin",
       "rol": "ADMIN"
     }
   }
   ```

3. **Usar token** en todas las peticiones:
   ```http
   GET /api/v1/productos
   Authorization: Bearer eyJhbG...
   ```

---

## ⚠️ Códigos de Error

El API usa códigos HTTP estándar + códigos de negocio:

### HTTP Status Codes

| Código | Significado | Cuándo |
|--------|-------------|--------|
| 200 | OK | Operación exitosa |
| 201 | Created | Recurso creado |
| 400 | Bad Request | Payload inválido |
| 401 | Unauthorized | Sin autenticación |
| 403 | Forbidden | Sin permisos |
| 404 | Not Found | Recurso no existe |
| 409 | Conflict | Conflicto de negocio |
| 500 | Internal Error | Error del servidor |

### Códigos de Negocio (en el body)

```json
{
  "code": "STOCK_INSUFFICIENT",
  "message": "Stock insuficiente. Disponible: 2, solicitado: 5",
  "details": {
    "variante_id": 3,
    "stock_disponible": 2,
    "cantidad_solicitada": 5
  }
}
```

**Códigos importantes:**

- `STOCK_INSUFFICIENT` - No hay inventario
- `SALE_CLOSED` - Venta ya cerrada
- `SALE_ALREADY_INVOICED` - Venta ya facturada
- `INVALID_BARCODE` - Código de barras no existe
- `CONCURRENT_MODIFICATION` - Conflicto de concurrencia
- `INSUFFICIENT_PERMISSIONS` - Usuario sin permisos

---

## 🎬 Flujos de Uso

### Flujo 1: Venta en POS

```
1. Login
   POST /auth/login

2. Crear venta
   POST /ventas
   → venta_id = 101

3. Escanear producto
   GET /pos/barcode/7501234567890
   → variante_id = 3, precio_menudeo = 600

4. Agregar a venta
   POST /ventas/101/items
   body: { variante_id: 3, cantidad: 5 }
   → subtotal = 3000, stock_restante = 37

5. Repetir pasos 3-4 para más productos

6. Cerrar venta
   POST /ventas/101/cerrar
   → estado = CERRADA, total = 3000
```

### Flujo 2: Aplicación automática de precio mayoreo

```
1. Crear venta
   POST /ventas → venta_id = 102

2. Agregar 5 piezas (menudeo)
   POST /ventas/102/items
   body: { variante_id: 3, cantidad: 5 }
   → precio_unitario = 600 (MENUDEO)
   → subtotal = 3000

3. Agregar 8 piezas más (activa mayoreo)
   POST /ventas/102/items
   body: { variante_id: 3, cantidad: 8 }
   → cantidad_total = 13 (>=12, umbral mayoreo)
   → LA BASE DE DATOS RECALCULA TODO
   → precio_unitario = 520 (MAYOREO)
   → subtotal_total = 6760 (13 × 520)
```

**Nota:** El frontend NO calcula esto, la BD lo hace automáticamente.

### Flujo 3: Facturación de ventas con tarjeta

```
1. Al final del día, obtener ventas con tarjeta
   GET /ventas?metodo_pago=TARJETA&fecha=2026-01-14

2. Generar factura global
   POST /facturas/global/tarjetas
   body: {
     fecha_desde: "2026-01-14",
     fecha_hasta: "2026-01-14"
   }
   → factura_id = 50, estado = BORRADOR

3. Timbrar con PAC
   POST /facturas/50/timbrar
   → uuid = "ABC123...", xml_url, pdf_url
```

---

## 📊 Ejemplos de Responses

### Éxito: Agregar producto a venta

```json
{
  "detalle_id": 1,
  "variante_id": 3,
  "cantidad": 5,
  "precio_unitario_aplicado": 600.00,
  "regla_precio": "MENUDEO",
  "subtotal": 3000.00,
  "stock_restante": 37,
  "cantidad_total_producto_en_venta": 5
}
```

### Error: Stock insuficiente

```json
{
  "code": "STOCK_INSUFFICIENT",
  "message": "Stock insuficiente. Disponible: 2, solicitado: 5",
  "details": {
    "variante_id": 3,
    "stock_disponible": 2,
    "cantidad_solicitada": 5
  }
}
```

### Error: Venta ya cerrada

```json
{
  "code": "SALE_CLOSED",
  "message": "No se pueden agregar productos a una venta cerrada",
  "details": {
    "venta_id": 101,
    "estado": "CERRADA"
  }
}
```

---

## 🧪 Testing del Contrato

### Opción 1: Swagger UI (Recomendado)

FastAPI genera automáticamente Swagger UI:

```
http://localhost:8000/docs
```

Desde ahí puedes:
- Ver todos los endpoints
- Probar las peticiones
- Ver ejemplos
- Autenticarte con JWT

### Opción 2: Postman

1. Importar el archivo `openapi.yaml` en Postman
2. Configurar variables:
   - `base_url`: http://localhost:8000/api/v1
   - `token`: (obtener de /auth/login)

### Opción 3: curl

```bash
# Login
TOKEN=$(curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' \
  | jq -r '.access_token')

# Crear venta
VENTA_ID=$(curl -X POST http://localhost:8000/api/v1/ventas \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"punto_venta_id":1,"metodo_pago":"EFECTIVO"}' \
  | jq -r '.venta_id')

# Agregar producto
curl -X POST http://localhost:8000/api/v1/ventas/$VENTA_ID/items \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"variante_id":3,"cantidad":5}'
```

---

## 📐 Validaciones

### En el Frontend (básicas)

- Formato de campos (email, números positivos)
- Campos requeridos
- Longitudes máximas

### En FastAPI (esquema)

- Validación con Pydantic
- Tipos de datos
- Rangos numéricos
- Enums

### En PostgreSQL (negocio)

- **Stock suficiente** (antes de vender)
- **Precios correctos** (mayoreo/menudeo)
- **Concurrencia** (bloqueos de fila)
- **Integridad referencial** (FK)
- **Estados válidos** (no cerrar venta cancelada)

---

## 🔄 Versionado

El API usa versionado en la URL:

- **Actual**: `/api/v1/...`
- **Futuro**: `/api/v2/...` (si hay breaking changes)

### Cambios compatibles (no requieren nueva versión):

- ✅ Agregar endpoints nuevos
- ✅ Agregar campos opcionales a responses
- ✅ Agregar valores a enums

### Cambios incompatibles (requieren v2):

- ❌ Eliminar endpoints
- ❌ Cambiar tipos de datos
- ❌ Hacer campos opcionales → requeridos
- ❌ Cambiar formato de respuestas

---

## 🚀 Implementación

### Backend (FastAPI)

Los endpoints deben implementarse siguiendo este patrón:

```python
# routers/ventas.py

@router.post("/ventas/{venta_id}/items", response_model=VentaItemAddResponse)
def agregar_item_venta(
    venta_id: int,
    item: VentaItemAddRequest,
    db: Session = Depends(get_db),
    current_user: Usuario = Depends(get_current_user)
):
    """
    Agregar producto a venta.
    La lógica de precio y validación está en PostgreSQL.
    """
    try:
        # Llamar función SQL
        result = db.execute(
            text("SELECT * FROM fn_agregar_item_venta(:venta, :variante, :cantidad, :usuario)"),
            {
                "venta": venta_id,
                "variante": item.variante_id,
                "cantidad": item.cantidad,
                "usuario": current_user.id
            }
        ).fetchone()
        
        return result
        
    except IntegrityError as e:
        if "stock_insuficiente" in str(e):
            raise HTTPException(
                status_code=409,
                detail={
                    "code": "STOCK_INSUFFICIENT",
                    "message": "Stock insuficiente"
                }
            )
        raise
```

### Frontend (React)

Consumir el API con el servicio ya creado:

```typescript
// services/apiService.ts

export const salesService = {
  async createSale(data: VentaCreateRequest) {
    const response = await apiClient.post('/ventas', data);
    return response.data;
  },
  
  async addItem(ventaId: number, item: VentaItemAddRequest) {
    const response = await apiClient.post(`/ventas/${ventaId}/items`, item);
    return response.data;
  },
  
  async closeSale(ventaId: number) {
    const response = await apiClient.post(`/ventas/${ventaId}/cerrar`);
    return response.data;
  }
};
```

---

## 📝 Próximos Pasos

1. ✅ **Contrato definido** (este archivo)
2. ⏭️ **Implementar endpoints en FastAPI** (Paso 2)
3. ⏭️ **Crear funciones SQL** en PostgreSQL
4. ⏭️ **Probar con Postman/Swagger** (Paso 3)
5. ⏭️ **Actualizar frontend** para usar endpoints finales (Paso 4)
6. ⏭️ **Integración SAT/PAC** (Paso 5)

---

## 📚 Recursos

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI Spec**: `openapi.yaml`
- **Este documento**: `API_CONTRACT.md`

---

**✅ Contrato congelado - Versión 1.0.0**  
**Fecha**: Enero 2026  
**Estado**: LISTO PARA IMPLEMENTACIÓN
