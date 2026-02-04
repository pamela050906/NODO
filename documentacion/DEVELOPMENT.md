# Guía de Desarrollo

## 🚀 Setup Inicial

### 1. Clonar y Preparar Entorno

```bash
cd ERP

# Copiar variables de entorno
cp .env.example .env

# Editar .env con tu configuración
# Especialmente si vas a correr sin Docker
```

### 2. Opción A: Con Docker (Recomendado)

```bash
# Levantar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f backend

# Verificar que funciona
curl http://localhost:8000/health
```

### 3. Opción B: Sin Docker

```bash
# Crear entorno virtual
python -m venv venv

# Activar entorno virtual
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt

# Asegurar que PostgreSQL está corriendo
# Editar .env con tu configuración de PostgreSQL local

# Ejecutar aplicación
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## 🗄️ Inicializar Base de Datos

### Con Docker

```bash
# Copiar script SQL al contenedor
docker cp init_db.sql pos_db:/tmp/init_db.sql

# Ejecutar script
docker-compose exec db psql -U postgres -d pos_db -f /tmp/init_db.sql
```

### Sin Docker

```bash
# Conectar a PostgreSQL y ejecutar
psql -U postgres -d pos_db -f init_db.sql
```

### Verificar

```bash
# Conectar a base de datos
docker-compose exec db psql -U postgres -d pos_db

# O sin Docker:
psql -U postgres -d pos_db

# Verificar tablas
\dt

# Ver usuarios creados
SELECT * FROM usuarios;

# Ver productos de ejemplo
SELECT * FROM productos;

# Ver inventario
SELECT * FROM v_productos_stock;
```

## 🧪 Testing

### 1. Test Manual con cURL

```bash
# Dar permisos al script (Linux/Mac)
chmod +x test_api.sh

# Ejecutar tests
./test_api.sh
```

### 2. Test con Cliente Python

```bash
# Instalar requests
pip install requests

# Ejecutar cliente de ejemplo
python examples/test_client.py
```

### 3. Test con Postman/Insomnia

1. Abrir Swagger UI: `http://localhost:8000/docs`
2. Usar el botón "Authorize" con el token de login
3. Probar endpoints interactivamente

### 4. Unit Tests (Próximamente)

```bash
# Instalar pytest
pip install pytest pytest-cov

# Crear tests
mkdir tests
touch tests/test_venta_service.py

# Ejecutar tests
pytest tests/ -v

# Con cobertura
pytest tests/ --cov=app --cov-report=html
```

## 🏗️ Estructura del Proyecto

```
ERP/
├── app/                        # Código de la aplicación
│   ├── core/                   # Configuración global
│   │   ├── config.py           # Settings
│   │   ├── database.py         # Engine y sesiones
│   │   └── security.py         # JWT y hashing
│   │
│   ├── models/                 # Modelos SQLAlchemy
│   │   ├── usuario.py
│   │   ├── producto.py
│   │   ├── inventario.py
│   │   └── venta.py
│   │
│   ├── schemas/                # Schemas Pydantic
│   │   ├── auth.py
│   │   ├── producto.py
│   │   └── venta.py
│   │
│   ├── repositories/           # Acceso a datos
│   │   ├── usuario_repository.py
│   │   ├── producto_repository.py
│   │   ├── inventario_repository.py
│   │   └── venta_repository.py
│   │
│   ├── services/               # Lógica de negocio
│   │   ├── auth_service.py
│   │   └── venta_service.py
│   │
│   ├── api/                    # Endpoints
│   │   ├── dependencies.py     # Auth dependencies
│   │   └── v1/
│   │       ├── auth.py
│   │       └── ventas.py
│   │
│   └── main.py                 # App FastAPI
│
├── examples/                   # Ejemplos de uso
│   └── test_client.py
│
├── tests/                      # Tests (crear)
│
├── requirements.txt            # Dependencias Python
├── Dockerfile                  # Imagen Docker
├── docker-compose.yml          # Orquestación
├── init_db.sql                 # Script de inicialización
├── test_api.sh                 # Tests automáticos
├── .env.example                # Template de variables
├── .gitignore
├── README.md                   # Documentación principal
├── ARCHITECTURE.md             # Documentación de arquitectura
└── DEVELOPMENT.md              # Esta guía
```

## 📝 Agregar Nuevas Funcionalidades

### Ejemplo: Agregar módulo de Clientes

#### 1. Crear Modelo

```python
# app/models/cliente.py
from sqlalchemy import Column, Integer, String
from app.core.database import Base

class Cliente(Base):
    __tablename__ = "clientes"
    
    id = Column(Integer, primary_key=True)
    nombre = Column(String(200), nullable=False)
    documento = Column(String(20), unique=True)
    # ... más campos
```

#### 2. Crear Schemas

```python
# app/schemas/cliente.py
from pydantic import BaseModel

class ClienteCreate(BaseModel):
    nombre: str
    documento: str

class ClienteResponse(BaseModel):
    id: int
    nombre: str
    documento: str
    
    class Config:
        from_attributes = True
```

#### 3. Crear Repository

```python
# app/repositories/cliente_repository.py
from sqlalchemy.orm import Session
from app.models.cliente import Cliente

class ClienteRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def create(self, cliente: Cliente) -> Cliente:
        self.db.add(cliente)
        self.db.flush()
        return cliente
    
    def get_by_documento(self, documento: str):
        return self.db.query(Cliente).filter(
            Cliente.documento == documento
        ).first()
```

#### 4. Crear Service

```python
# app/services/cliente_service.py
from sqlalchemy.orm import Session
from app.repositories.cliente_repository import ClienteRepository
from app.schemas.cliente import ClienteCreate, ClienteResponse

class ClienteService:
    def __init__(self, db: Session):
        self.db = db
        self.cliente_repo = ClienteRepository(db)
    
    def crear_cliente(self, data: ClienteCreate) -> ClienteResponse:
        # Validar duplicados
        existing = self.cliente_repo.get_by_documento(data.documento)
        if existing:
            raise ValueError("Cliente ya existe")
        
        # Crear
        cliente = Cliente(**data.dict())
        cliente = self.cliente_repo.create(cliente)
        
        self.db.commit()
        return ClienteResponse.model_validate(cliente)
```

#### 5. Crear Endpoints

```python
# app/api/v1/clientes.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.cliente import ClienteCreate, ClienteResponse
from app.services.cliente_service import ClienteService

router = APIRouter(prefix="/clientes", tags=["Clientes"])

@router.post("", response_model=ClienteResponse)
def crear_cliente(
    data: ClienteCreate,
    db: Session = Depends(get_db)
):
    service = ClienteService(db)
    return service.crear_cliente(data)
```

#### 6. Registrar Router

```python
# app/main.py
from app.api.v1 import clientes

app.include_router(clientes.router, prefix=settings.API_V1_PREFIX)
```

## 🔧 Comandos Útiles

### Docker

```bash
# Ver logs en tiempo real
docker-compose logs -f backend

# Reiniciar servicios
docker-compose restart

# Reconstruir imágenes
docker-compose up -d --build

# Parar servicios
docker-compose down

# Limpiar todo (¡cuidado con los datos!)
docker-compose down -v
```

### Base de Datos

```bash
# Conectar a PostgreSQL
docker-compose exec db psql -U postgres -d pos_db

# Backup
docker-compose exec db pg_dump -U postgres pos_db > backup.sql

# Restore
docker-compose exec -T db psql -U postgres -d pos_db < backup.sql

# Ver tablas
docker-compose exec db psql -U postgres -d pos_db -c "\dt"
```

### Python

```bash
# Formatear código
pip install black
black app/

# Linting
pip install flake8
flake8 app/

# Type checking
pip install mypy
mypy app/

# Ordenar imports
pip install isort
isort app/
```

## 🐛 Debugging

### 1. Ver Logs de la Aplicación

```bash
# Con Docker
docker-compose logs -f backend

# Sin Docker
# Los logs aparecen directamente en consola con --reload
```

### 2. Debug con VS Code

Crear `.vscode/launch.json`:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: FastAPI",
            "type": "python",
            "request": "launch",
            "module": "uvicorn",
            "args": [
                "app.main:app",
                "--reload",
                "--host", "0.0.0.0",
                "--port", "8000"
            ],
            "jinja": true,
            "justMyCode": true
        }
    ]
}
```

### 3. SQL Logging

En `.env`:

```env
DEBUG=True  # Habilita echo de SQL en consola
```

O en código:

```python
engine = create_engine(url, echo=True)  # Ver todas las queries
```

### 4. Breakpoints en Python

```python
# Agregar breakpoint
import pdb; pdb.set_trace()

# O con ipdb (mejor interfaz)
import ipdb; ipdb.set_trace()
```

## 📚 Recursos Adicionales

### Documentación

- **FastAPI**: https://fastapi.tiangolo.com/
- **SQLAlchemy 2.0**: https://docs.sqlalchemy.org/
- **Pydantic**: https://docs.pydantic.dev/
- **PostgreSQL**: https://www.postgresql.org/docs/

### Herramientas Recomendadas

- **Postman**: Testing de APIs
- **DBeaver**: Cliente de base de datos
- **VS Code**: Editor con extensiones Python
- **Docker Desktop**: Gestión de contenedores

### Extensiones VS Code

```json
{
    "recommendations": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-azuretools.vscode-docker",
        "mtxr.sqltools",
        "mtxr.sqltools-driver-pg"
    ]
}
```

## 🚨 Troubleshooting

### Error: "port 8000 already in use"

```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:8000 | xargs kill -9
```

### Error: "database does not exist"

```bash
# Crear base de datos
docker-compose exec db createdb -U postgres pos_db

# O manualmente
docker-compose exec db psql -U postgres -c "CREATE DATABASE pos_db;"
```

### Error: "no password supplied"

Verificar que `.env` tiene las credenciales correctas:

```env
DATABASE_PASSWORD=postgres
```

### Error: "Module not found"

```bash
# Reinstalar dependencias
pip install -r requirements.txt

# O con Docker
docker-compose up -d --build
```

## 🎯 Próximos Pasos

1. ✅ Setup básico completado
2. ✅ Endpoints principales implementados
3. ⏳ Agregar tests unitarios
4. ⏳ Agregar más módulos (clientes, reportes)
5. ⏳ Implementar CI/CD
6. ⏳ Optimizar queries pesadas
7. ⏳ Agregar cache (Redis)
8. ⏳ Migrar a async/await

## 💡 Tips

- Usa el modo `--reload` en desarrollo
- Revisa `/docs` para documentación interactiva
- Usa transacciones para operaciones críticas
- Siempre valida datos de entrada
- Documenta tus endpoints con docstrings
- Escribe tests para lógica crítica
- Usa logging en lugar de prints

---

¿Dudas? Revisa:
- `README.md` para información general
- `ARCHITECTURE.md` para detalles de arquitectura
- `/docs` para documentación de endpoints
