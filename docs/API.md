## API ERP/POS – Visión General

Esta API implementa el backend de un sistema **ERP/POS** para punto de venta y gestión de almacén.  
Está pensada para tiendas con múltiples cajas y usuarios, con inventario centralizado y facturación SAT preparada.

Backend: **FastAPI + SQLAlchemy + PostgreSQL**  
Frontend: **React** (consume esta API)  
Base de datos: **PostgreSQL** (lógica de negocio apoyada en triggers y funciones PL/pgSQL).

---

## Arquitectura

- **Framework**: `FastAPI` (`app/main.py`).
- **Routers**: `app.api.v1` expone los módulos:
  - `auth`, `pos`, `ventas`, `productos`, `inventario`, `reportes`, `cobranza`, `facturas`.
- **Capa de configuración**: `app.core.config` (variables como `DATABASE_URL`, `SECRET_KEY`, `API_V1_PREFIX`).
- **Capa de base de datos**: `app.core.database`
  - Crea el `engine` de SQLAlchemy contra PostgreSQL.
  - Define `SessionLocal` y la base declarativa `Base`.
  - Expone la dependencia `get_db()` para inyectar sesiones en los endpoints.
- **Capa de seguridad**: `app.core.security`
  - Hash de contraseñas con `passlib` (bcrypt).
  - Creación y decodificación de tokens **JWT** con `python-jose`.
- **Capa de modelos**: `app.models.*`
  - Modelos ORM que representan tablas de la BD (`Venta`, `VentaDetalle`, `Inventario`, `Producto`, `Usuario`, etc.).
- **Capa de repositorios**: `app.repositories.*`
  - Encapsulan el acceso a datos y las consultas SQL/ORM (incluyendo `SELECT FOR UPDATE` para concurrencia).
- **Capa de servicios**: `app.services.*`
  - Contiene la **lógica de negocio** (ventas, inventario, facturación, tickets, reportes, etc.).
  - Orquesta transacciones, validaciones de dominio y coordinación entre repositorios.
- **Capa de esquemas**: `app.schemas.*`
  - Modelos Pydantic para requests/responses alineados con `openapi.yaml`.

El archivo `app/main.py` registra todos los routers con el prefijo `settings.API_V1_PREFIX` (por ejemplo `/api/v1`) y configura CORS para permitir las peticiones desde el frontend.

---

## Seguridad y Autenticación

- **Esquema de seguridad**: `BearerAuth` (JWT) definido en `openapi.yaml`.
- **Flujo de login**:
  - `POST /api/v1/auth/login`
    - Recibe `username` y `password`.
    - Valida las credenciales, genera un **JWT** con:
      - `id`, `username`, `email`, `rol`, `punto_venta_id`, etc.
    - Devuelve:
      - `access_token` (JWT),
      - `token_type` (`bearer`),
      - `expires_in`,
      - `user` (objeto `UserInfo`).
- **Usuario actual**:
  - `GET /api/v1/auth/me`
    - Requiere `Authorization: Bearer {token}`.
    - Devuelve la información del usuario asociado al token.
- **Roles**:
  - Los esquemas contemplan roles como `ADMIN`, `CAJERO`, etc.
  - El código de negocio utiliza estos roles para restringir operaciones sensibles (por ejemplo, descuentos manuales, administración de usuarios, facturación).

---

## Módulos Funcionales y Endpoints Principales

La especificación detallada de endpoints está en `openapi.yaml`. A continuación se resumen los módulos más importantes.

### 1. Autenticación (`Autenticación`)

- **Login**  
  - `POST /api/v1/auth/login`  
  - **Función**: autenticar usuarios y emitir tokens JWT.  
- **Usuario actual**  
  - `GET /api/v1/auth/me`  
  - **Función**: devolver información del usuario autenticado.

### 2. POS / Punto de Venta (`POS`)

- **Búsqueda por código de barras**  
  - `GET /api/v1/pos/barcode/{codigo}`  
  - **Función**:
    - Escanear un código de barras.
    - Devolver información lista para el POS:
      - `variante_id`, `producto_id`,
      - `nombre_producto`, `nombre_variante`,
      - `codigo_barras`, `sku`,
      - `precio_menudeo`, `precio_mayoreo`, `umbral_mayoreo`,
      - `stock_actual`, `activo`.
  - **Uso típico**: el cajero escanea el código y el frontend agrega la línea al ticket con estos datos.

### 3. Ventas (`Ventas`)

#### Crear y listar ventas

- **Crear venta**  
  - `POST /api/v1/ventas`  
  - **Entrada**: `VentaCreateRequest` (punto_venta_id, metodo_pago, datos opcionales de cliente).  
  - **Salida**: `VentaCreateResponse` (id de venta, folio, estado inicial `ABIERTA`).  
  - **Comportamiento**:
    - Crea una venta en estado `ABIERTA`.
    - Esta operación inicia el flujo POS.

- **Listar ventas**  
  - `GET /api/v1/ventas`  
  - **Filtros**: `estado`, `punto_venta_id`, `fecha_desde`, `fecha_hasta`, `limit`, `offset`.  
  - **Salida**: lista de `VentaDetalle` (resumen de ventas).

- **Detalle de venta**  
  - `GET /api/v1/ventas/{venta_id}`  
  - Devuelve un `VentaDetalle` completo con:
    - Datos de la venta.
    - Items (producto, variante, cantidad, precio unitario, subtotal).

#### Manejo de items en una venta

- **Agregar producto a venta**  
  - `POST /api/v1/ventas/{venta_id}/items`  
  - **Entrada**: `VentaItemAddRequest`  
    - `variante_id` o datos equivalentes (según implementación de router),
    - `cantidad`,
    - `descuento_manual` (opcional, sujeto a permisos).  
  - **Salida**: `VentaItemAddResponse`.  
  - **Lógica de negocio (base de datos + servicios)**:
    - Validación de stock.
    - Cálculo de precio automático (menudeo vs mayoreo) según cantidad y umbral.
    - Bloqueo de inventario.
    - Cálculo de subtotales.
    - El precio **no lo envía el frontend**, se calcula en PostgreSQL y/o en la capa de servicios.

- **Eliminar producto de venta**  
  - `DELETE /api/v1/ventas/{venta_id}/items/{detalle_id}`  
  - Borra un detalle de venta si la venta está abierta.

#### Cierre y cancelación de ventas

- **Cerrar venta**  
  - `POST /api/v1/ventas/{venta_id}/cerrar`  
  - **Efectos**:
    - Descuenta inventario definitivamente (confirmando los bloqueos previos).
    - Genera ticket asociado.
    - Marca la venta como facturable.
    - Cambia el estado a `CERRADA`.
  - Una vez cerrada, **no se puede modificar**.

- **Cancelar venta**  
  - `POST /api/v1/ventas/{venta_id}/cancelar`  
  - **Efectos**:
    - Cancela una venta `ABIERTA`.
    - Libera el inventario bloqueado.

### 4. Productos (`Productos`)

- **Listar productos**  
  - `GET /api/v1/productos`  
  - Filtros:
    - `categoria`,
    - `buscar` (nombre o SKU),
    - `activo`.  
  - Devuelve una lista de `ProductoDetalle` con sus variantes.

- **Detalle de producto**  
  - `GET /api/v1/productos/{producto_id}`  
  - Devuelve `ProductoDetalle` con todas sus variantes (`VarianteBarcodeResponse`).

### 5. Inventario (`Inventario`)

- **Registrar movimiento de inventario**  
  - `POST /api/v1/inventario/movimientos`  
  - **Entrada**: `MovimientoInventarioRequest`  
    - `variante_id`,
    - `tipo` (`ENTRADA`, `SALIDA`, `AJUSTE`),
    - `cantidad`,
    - `motivo`,
    - `referencia` (opcional).  
  - **Comportamiento** (servicio `MovimientoInventario`):
    - Obtiene el registro de `Inventario` con `SELECT FOR UPDATE`.
    - Si no existe, crea un registro con stock 0.
    - Calcula nuevo stock:
      - `ENTRADA`: suma.
      - `SALIDA`: resta (valida que no quede negativo).
      - `AJUSTE`: fija el stock a la cantidad indicada.
    - Actualiza el stock en la tabla `inventario`.
    - Inserta un registro en `movimientos_inventario` (historial auditable).

- **Consultar stock de variantes**  
  - `GET /api/v1/inventario/stock`  
  - Filtros:
    - `estado` (`OK`, `BAJO`, `CRITICO`).  
  - Devuelve una lista de `StockVariante` con:
    - `variante_id`, `producto_nombre`, `sku`,
    - `stock_actual`, `stock_minimo`, `estado_stock`.

- **Productos con stock bajo**  
  - `GET /api/v1/inventario/stock/bajo`  
  - Devuelve variantes con stock <= stock mínimo configurado.

### 6. Facturación (`Facturación`)

- **Crear factura (borrador)**  
  - `POST /api/v1/facturas`  
  - **Entrada**: `FacturaCreateRequest`  
    - `ventas_ids` (una o varias ventas),
    - `rfc_receptor`,
    - `uso_cfdi`,
    - `nombre_receptor`,
    - `tipo_factura` (`INDIVIDUAL`, `GLOBAL`).  
  - **Salida**: `FacturaResponse` en estado `BORRADOR`.

- **Detalle de factura**  
  - `GET /api/v1/facturas/{factura_id}`  
  - Devuelve `FacturaResponse` con información de UUID, folio, serie, total, URLs de XML/PDF, etc.

- **Timbrar factura con PAC**  
  - `POST /api/v1/facturas/{factura_id}/timbrar`  
  - **Función**:
    - Envía la factura al PAC.
    - Actualiza `uuid`, `xml_url`, `pdf_url` y estado (`TIMBRADA`).
  - Maneja errores de PAC y reintentos según la lógica de negocio.

- **Factura global de ventas con tarjeta**  
  - `POST /api/v1/facturas/global/tarjetas`  
  - **Entrada**:
    - `fecha_desde`, `fecha_hasta`,
    - `punto_venta_id` (opcional).  
  - **Función**:
    - Agrupar todas las ventas con método de pago `TARJETA` en el rango dado.
    - Generar una factura global (típicamente por día).

### 7. Usuarios (`Usuarios`)

- **Listar usuarios**  
  - `GET /api/v1/usuarios`  
  - Devuelve un arreglo de `UserInfo` con los usuarios y sus roles.

### 8. Sistema / Health Check

- **Health check**  
  - `GET /health` (sin prefijo) y `GET /api/v1/health` (según router).  
  - Devuelve:
    - `status: "healthy"`,
    - `timestamp` (en el caso del endpoint descrito en `openapi.yaml`).

- **Raíz del backend**  
  - `GET /`  
  - Devuelve información básica:
    - Mensaje identificando la API,
    - Versión,
    - Rutas a `/docs` y `/health`.

---

## Lógica de Negocio Interna (resumen)

### Transacciones y concurrencia

- Las operaciones críticas (ventas, inventario) se implementan como **transacciones ACID**:
  - Se utilizan sesiones SQLAlchemy (`SessionLocal`) con `autocommit=False`.
  - Los servicios (`VentaService`, `MovimientoInventario`, etc.) hacen:
    - `db.commit()` al final si todo sale bien.
    - `db.rollback()` y lanzan `HTTPException` si hay errores.
- Para evitar problemas de concurrencia (dos cajas vendiendo el mismo stock):
  - Se usan consultas con **`SELECT FOR UPDATE`** en los repositorios para bloquear filas de inventario o venta mientras se actualizan.

### Uso de la base de datos como “motor de reglas”

- Parte de la lógica se delega a **triggers y funciones en PostgreSQL** (por ejemplo, descuento de inventario en `docs/almacen_db.sql`):
  - Al insertar un `venta_detalle`, un trigger puede:
    - Descontar stock automáticamente.
    - Registrar movimientos de inventario.
  - Esto asegura integridad incluso si hay cambios en otros clientes o procesos.

### Flujo típico de venta POS

1. **Cajero inicia sesión** (`POST /api/v1/auth/login`) y obtiene un JWT.
2. **Crea una venta** (`POST /api/v1/ventas`) para un punto de venta y método de pago.
3. **Escanea productos**:
   - Frontend llama `GET /api/v1/pos/barcode/{codigo}` para obtener info del producto.
   - Agrega productos a la venta con `POST /api/v1/ventas/{venta_id}/items`.
4. **Cierra la venta** (`POST /api/v1/ventas/{venta_id}/cerrar`):
   - Se descuenta inventario definitivamente.
   - Se genera ticket.
   - La venta queda lista para facturación.
5. **Facturación** (opcional, según requerimientos fiscales):
   - `POST /api/v1/facturas` para crear factura individual/global.
   - `POST /api/v1/facturas/{factura_id}/timbrar` para obtener CFDI timbrado.

---

## Entorno de Ejecución (Docker)

El archivo `docker-compose.yml` define tres servicios principales:

- **db** (`postgres:15-alpine`)
  - Variables:
    - `POSTGRES_USER=postgres`
    - `POSTGRES_PASSWORD=postgres`
    - `POSTGRES_DB=almacen_db`
  - Expone el puerto `5432`.
  - Usa un volumen `postgres_data` para persistir los datos.
  - Healthcheck con `pg_isready`.

- **backend**
  - `build: .` (usa el `Dockerfile` del proyecto).
  - Expone el puerto `8000`.
  - Variable:
    - `DATABASE_URL=postgresql://postgres:postgres@db:5432/almacen_db`
  - Monta el código de `./backend/app` dentro del contenedor para desarrollo.
  - Comando:
    - `uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload`.

- **frontend**
  - `build` desde `./frontend` con `Dockerfile.dev`.
  - Expone el puerto `3000`.
  - Variables:
    - `REACT_APP_API_URL=http://localhost:8000`
    - `CHOKIDAR_USEPOLLING=true` (para hot reload en entornos Docker/Windows).
  - Monta `./frontend/src` y `./frontend/public` para desarrollo.
  - Depende del `backend`.

Con `docker-compose up` se levanta toda la pila (BD + API + frontend) para desarrollo local.

---

## Referencias

- Especificación completa de la API: `openapi.yaml`.
- Script de estructura de BD: `docs/almacen_db.sql`.
- Servicios de negocio principales:
  - `app/services/venta_service.py`
  - `app/services/inventario_service.py`
  - `app/services/facturacion_service.py`
  - `app/services/ticket_service.py`

