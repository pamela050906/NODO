# Arquitectura del Backend POS

## 📐 Clean Architecture

Este proyecto sigue los principios de **Clean Architecture** para mantener el código mantenible, testeable y escalable.

```
┌─────────────────────────────────────────────────────┐
│                   API Layer                         │
│  (FastAPI Endpoints, Dependencies, Auth)            │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│                Service Layer                         │
│  (Lógica de negocio, Transacciones ACID)            │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│              Repository Layer                        │
│  (Acceso a datos, Queries SQL)                      │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│              Database Layer                          │
│  (PostgreSQL, Triggers, Constraints)                 │
└──────────────────────────────────────────────────────┘
```

## 🎯 Principios SOLID

### 1. Single Responsibility Principle (SRP)
Cada clase tiene una única responsabilidad:

- **Repositories**: Solo acceso a datos
- **Services**: Solo lógica de negocio
- **Endpoints**: Solo manejo de HTTP

### 2. Open/Closed Principle (OCP)
El sistema es abierto a extensión pero cerrado a modificación:

```python
# Fácil agregar nuevo repositorio sin modificar existentes
class ClienteRepository:
    def __init__(self, db: Session):
        self.db = db
```

### 3. Dependency Inversion Principle (DIP)
Las capas superiores no dependen de las inferiores:

```python
# El servicio recibe una sesión de DB, no una implementación específica
class VentaService:
    def __init__(self, db: Session):
        self.venta_repo = VentaRepository(db)
```

## 🔄 Flujo de Datos

### POST /sales/{id}/item

```
1. API Layer (ventas.py)
   ├─ Validar token JWT
   ├─ Validar request con Pydantic
   └─ Llamar a VentaService

2. Service Layer (venta_service.py)
   ├─ Iniciar transacción
   ├─ Validar venta existe y está PENDIENTE
   ├─ Llamar a ProductoRepository
   ├─ Llamar a InventarioRepository con FOR UPDATE
   ├─ Validar stock suficiente
   ├─ Llamar a VentaRepository para crear detalle
   ├─ Actualizar totales
   └─ Commit transacción

3. Repository Layer
   ├─ ProductoRepository.get_variante_by_codigo_barras()
   ├─ InventarioRepository.get_by_variante_id_with_lock()
   └─ VentaRepository.add_detalle()

4. Database Layer
   ├─ SELECT ... FOR UPDATE (lock)
   ├─ INSERT INTO venta_detalle
   ├─ UPDATE ventas
   └─ Trigger actualiza inventario
```

## 🔒 Manejo de Concurrencia

### SELECT FOR UPDATE

Cuando dos usuarios intentan vender el mismo producto simultáneamente:

```sql
-- Usuario A (en transacción)
BEGIN;
SELECT * FROM inventario WHERE variante_id = 1 FOR UPDATE;
-- 🔒 Registro bloqueado

-- Usuario B (debe esperar)
BEGIN;
SELECT * FROM inventario WHERE variante_id = 1 FOR UPDATE;
-- ⏳ Esperando a que A termine...

-- Usuario A termina
UPDATE inventario SET cantidad = cantidad - 5;
COMMIT;
-- 🔓 Registro desbloqueado

-- Usuario B continúa
-- Ahora ve el stock actualizado por A
```

### Niveles de Aislamiento

PostgreSQL usa **READ COMMITTED** por defecto, suficiente para este caso de uso.

Para operaciones más críticas, se puede usar:

```python
from sqlalchemy import create_engine

engine = create_engine(
    url,
    isolation_level="REPEATABLE READ"  # Mayor aislamiento
)
```

## 🏢 Capas en Detalle

### 1. Core Layer

**Responsabilidad**: Configuración global

```
app/core/
├── config.py       # Configuración de entorno
├── database.py     # Engine y sesiones
└── security.py     # JWT, hashing
```

### 2. Models Layer

**Responsabilidad**: Entidades de dominio (mapeo ORM)

```python
class Venta(Base):
    __tablename__ = "ventas"
    
    id = Column(Integer, primary_key=True)
    total = Column(Numeric(10, 2))
    estado = Column(Enum(EstadoVentaEnum))
    
    # Relaciones ORM
    detalles = relationship("VentaDetalle", back_populates="venta")
```

**Características**:
- Mapeo directo a tablas PostgreSQL
- Relaciones ORM configuradas
- Constraints a nivel de columna

### 3. Schemas Layer

**Responsabilidad**: DTOs y validación

```python
class AddItemToSaleRequest(BaseModel):
    codigo_barras: str = Field(..., min_length=1)
    cantidad: int = Field(..., gt=0)
    descuento: Decimal = Field(default=Decimal("0"), ge=0)
    
    @validator('descuento')
    def round_descuento(cls, v):
        return round(v, 2)
```

**Características**:
- Validación automática con Pydantic
- Conversión de tipos
- Documentación automática para OpenAPI

### 4. Repository Layer

**Responsabilidad**: Acceso a datos (queries)

```python
class VentaRepository:
    def get_by_id_with_lock(self, venta_id: int) -> Optional[Venta]:
        return self.db.query(Venta).filter(
            Venta.id == venta_id
        ).with_for_update().first()
```

**Características**:
- Encapsula queries SQL complejas
- Usa QueryBuilder de SQLAlchemy
- Proporciona métodos con y sin locks

### 5. Service Layer

**Responsabilidad**: Lógica de negocio y transacciones

```python
class VentaService:
    def add_item_to_sale(self, venta_id: int, item: AddItemToSaleRequest):
        try:
            # Lógica de negocio compleja
            # Múltiples repositorios
            # Validaciones
            self.db.commit()
        except Exception as e:
            self.db.rollback()
            raise
```

**Características**:
- Orquesta llamadas a múltiples repositorios
- Maneja transacciones ACID
- Implementa reglas de negocio
- Manejo centralizado de errores

### 6. API Layer

**Responsabilidad**: Endpoints HTTP

```python
@router.post("/{sale_id}/item", response_model=VentaResponse)
def add_item_to_sale(
    sale_id: int,
    item_data: AddItemToSaleRequest,
    current_user: Annotated[Usuario, Depends(require_cajero_or_admin)],
    db: Session = Depends(get_db)
):
    service = VentaService(db)
    return service.add_item_to_sale(sale_id, item_data)
```

**Características**:
- Validación de autenticación/autorización
- Conversión HTTP request → DTO
- Conversión respuesta → JSON
- Documentación automática

## 🔐 Autenticación y Autorización

### JWT Flow

```
1. Login
   POST /auth/login
   ├─ Verificar password
   └─ Generar JWT con claims: {sub: username, rol: ADMIN}

2. Request a endpoint protegido
   GET /sales/1
   ├─ Extraer token del header Authorization
   ├─ Decodificar JWT
   ├─ Verificar firma y expiración
   ├─ Obtener usuario desde DB
   └─ Validar rol requerido

3. Acceso concedido
   └─ Ejecutar endpoint
```

### Dependencies

```python
# Cadena de dependencies
get_current_user
  → decode_access_token()
  → AuthService.get_current_user()

get_current_active_user
  → get_current_user
  → Validar usuario.activo == 1

require_cajero_or_admin
  → get_current_active_user
  → Validar rol in [CAJERO, ADMIN]
```

## 📊 Modelo de Datos

### Relaciones

```
Usuario ─┐
         │
         ├─→ Venta ─┐
         │          │
Cliente ─┘          ├─→ VentaDetalle ──→ VarianteProducto ──→ Producto
                    │                             │
                    └─────────────────────────────┴──→ Inventario
```

### Reglas de Negocio en Base de Datos

```sql
-- Constraint: cantidad no negativa
ALTER TABLE inventario 
ADD CONSTRAINT check_cantidad_no_negativa 
CHECK (cantidad >= 0);

-- Trigger: actualizar inventario automáticamente
CREATE TRIGGER trigger_actualizar_inventario
AFTER INSERT ON venta_detalle
FOR EACH ROW
EXECUTE FUNCTION actualizar_inventario_venta();
```

## 🚀 Escalabilidad

### Horizontal

- **API**: Múltiples instancias detrás de load balancer
- **DB**: Connection pooling configurado en SQLAlchemy

```python
engine = create_engine(
    url,
    pool_size=10,        # Conexiones persistentes
    max_overflow=20,     # Conexiones adicionales temporales
    pool_pre_ping=True   # Verificar conexión antes de usar
)
```

### Vertical

- **Índices**: En campos de búsqueda frecuente
- **Particionado**: Ventas por fecha si crece mucho
- **Materialized Views**: Para reportes pesados

### Caching (Futuro)

```python
# Ejemplo de Redis cache
@cache(ttl=60)
def get_producto_by_barcode(codigo_barras: str):
    # Cachear productos más vendidos
    pass
```

## 🧪 Testing Strategy

### Unit Tests

```python
# Test de repository
def test_get_variante_by_codigo_barras():
    repo = ProductoRepository(db)
    variante = repo.get_variante_by_codigo_barras("7501234567890")
    assert variante is not None
    assert variante.codigo_barras == "7501234567890"
```

### Integration Tests

```python
# Test de service con transacción
def test_add_item_to_sale_with_insufficient_stock():
    service = VentaService(db)
    
    with pytest.raises(HTTPException) as exc:
        service.add_item_to_sale(1, AddItemToSaleRequest(
            codigo_barras="7501234567890",
            cantidad=9999
        ))
    
    assert "Stock insuficiente" in str(exc.value.detail)
```

### E2E Tests

```python
# Test del endpoint completo
def test_endpoint_add_item(client, auth_headers):
    response = client.post(
        "/api/v1/sales/1/item",
        json={"codigo_barras": "7501234567890", "cantidad": 1},
        headers=auth_headers
    )
    assert response.status_code == 200
```

## 📈 Monitoreo y Observabilidad

### Logging

```python
import logging

logger = logging.getLogger(__name__)

# En el servicio
logger.info(f"Agregando ítem a venta {venta_id}")
logger.error(f"Stock insuficiente para variante {variante_id}")
```

### Métricas (Futuro)

- Requests por segundo
- Latencia P95, P99
- Error rate
- Stock bajo (alertas)

### APM (Futuro)

- Integración con Datadog/New Relic
- Tracing de transacciones
- Profiling de queries lentas

## 🔄 CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
on: [push]

jobs:
  test:
    - Run unit tests
    - Run integration tests
    - Check linting
  
  build:
    - Build Docker image
    - Push to registry
  
  deploy:
    - Deploy to staging
    - Run smoke tests
    - Deploy to production
```

## 📚 Patrones de Diseño Utilizados

1. **Repository Pattern**: Abstracción de acceso a datos
2. **Dependency Injection**: Via FastAPI Depends
3. **DTO Pattern**: Schemas de Pydantic
4. **Factory Pattern**: SessionLocal para crear sesiones
5. **Strategy Pattern**: Diferentes métodos de pago (extensible)

## 🎓 Mejores Prácticas

✅ **DO**:
- Usar transacciones para operaciones críticas
- Validar datos en múltiples capas
- Usar SELECT FOR UPDATE para concurrencia
- Separar responsabilidades por capa
- Documentar endpoints con docstrings

❌ **DON'T**:
- Mezclar lógica de negocio en endpoints
- Hacer queries directas en servicios
- Hardcodear valores de configuración
- Ignorar manejo de errores
- Commitear credenciales

## 🔮 Futuras Mejoras

1. **Async/Await**: Migrar a SQLAlchemy async
2. **GraphQL**: API alternativa con Strawberry
3. **WebSockets**: Notificaciones en tiempo real
4. **Microservicios**: Separar módulos grandes
5. **Event Sourcing**: Para auditoría completa
6. **CQRS**: Separar lectura de escritura para reportes

---

**Última actualización**: Enero 2026
