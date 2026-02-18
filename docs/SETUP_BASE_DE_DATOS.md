# Configuración de la base de datos (PostgreSQL)

Si el **login no funciona** al usar Docker (por ejemplo en el equipo de un compañero), suele deberse a que la base de datos está vacía o no tiene usuarios creados.

## Qué hace el proyecto al levantar Docker

1. **Primera vez** que se ejecuta `docker compose up`:
   - PostgreSQL crea la base `almacen_db`.
   - Se ejecuta el script `docs/almacen_db.sql` en `/docker-entrypoint-initdb.d/`:
     - Se crean todas las tablas (roles, usuarios, productos, ventas, etc.).
     - Se insertan los **roles** (ADMIN, CAJERO, ALMACEN) y datos de ejemplo (productos, puntos de venta, inventario).
     - La tabla **usuarios** queda vacía a propósito (las contraseñas deben ser hashes bcrypt válidos).

2. Por tanto, **hay que crear al menos un usuario** después de la primera puesta en marcha.

## Pasos para que el login funcione (para tu compañera u otro equipo)

### 1. Levantar los contenedores

```bash
docker compose up -d
```

Esperar a que `pos_db` y `pos_backend` estén en marcha.

### 2. Crear usuarios por defecto

Desde la **raíz del proyecto**, con la base de datos accesible en `localhost:5432`:

```bash
# Opción A: si tienes Python y dependencias del backend en tu máquina
set DATABASE_URL=postgresql://postgres:postgres@localhost:5432/almacen_db
python scripts/crear_usuario.py --crear-defaults
```

En PowerShell:

```powershell
$env:DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/almacen_db"
python scripts/crear_usuario.py --crear-defaults
```

**Opción B:** Si no tienes Python en tu máquina o prefieres ejecutarlo dentro del contenedor:

**En PowerShell (Windows) - RECOMENDADO:**
```powershell
# Usar el script de PowerShell incluido (más fácil)
.\scripts\crear_usuarios_docker.ps1
```

O ejecutar el comando Python directamente:
```powershell
docker exec -it pos_backend python -c "from app.core.database import SessionLocal; from app.models.usuario import Usuario; from app.core.security import get_password_hash; db = SessionLocal(); usuarios = [('Admin', 'admin@local.com', 'admin123', 1), ('Cajero', 'cajero@local.com', 'cajero123', 2)]; [db.add(Usuario(nombre=n, email=e, password_hash=get_password_hash(p), rol_id=r, activo=True)) for n, e, p, r in usuarios if not db.query(Usuario).filter(Usuario.nombre == n).first()]; db.commit(); print('Usuarios creados.'); db.close()"
```

**En Bash/Linux/Mac:**
```bash
docker exec -it pos_backend python -c "
from app.core.database import SessionLocal
from app.models.usuario import Usuario
from app.core.security import get_password_hash

db = SessionLocal()
for name, email, pwd, rol_id in [
    ('Admin', 'admin@local.com', 'admin123', 1),
    ('Cajero', 'cajero@local.com', 'cajero123', 2)
]:
    if db.query(Usuario).filter(Usuario.nombre == name).first():
        print(f'Usuario {name} ya existe')
        continue
    u = Usuario(nombre=name, email=email, password_hash=get_password_hash(pwd), rol_id=rol_id, activo=True)
    db.add(u)
    print(f'Creado: {name}')
db.commit()
db.close()
print('Listo.')
"
```

### 3. Credenciales por defecto

Después de crear los usuarios:

| Usuario | Contraseña | Rol   |
|--------|------------|--------|
| Admin  | admin123   | ADMIN  |
| Cajero | cajero123  | CAJERO |

### 4. Si la base ya existía (volumen antiguo)

Los scripts en `docker-entrypoint-initdb.d/` **solo se ejecutan cuando el volumen de PostgreSQL está vacío** (primera vez). Si alguien ya había levantado los contenedores antes sin init:

- **Opción 1:** Borrar el volumen y volver a levantar (se pierde todo lo que haya en la BD):

  ```bash
  docker compose down -v
  docker compose up -d
  ```

  Luego repetir el paso 2 (crear usuarios).

- **Opción 2:** Mantener datos y solo crear usuarios ejecutando el script del paso 2 (desde el host o con `docker exec` como en Opción B).

## Resumen para tu compañera

### Pasos rápidos (PowerShell):

1. **Levantar contenedores:**
   ```powershell
   docker compose up -d
   ```
   Espera unos segundos a que `pos_db` y `pos_backend` estén corriendo.

2. **Crear usuarios (una sola vez):**
   
   **Opción más fácil (recomendada):**
   ```powershell
   .\scripts\crear_usuarios_docker.ps1
   ```
   
   **O si tienes Python instalado:**
   ```powershell
   $env:DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/almacen_db"
   python scripts/crear_usuario.py --crear-defaults
   ```

3. **Abrir el frontend:**
   - Ve a `http://localhost:3000`
   - Inicia sesión con:
     - Usuario: `Admin`
     - Contraseña: `admin123`

### Nota importante

- El SQL (`docs/almacen_db.sql`) se ejecuta **automáticamente** la primera vez que levantas Docker (no necesitas ejecutarlo manualmente).
- Solo necesitas crear usuarios **una vez** después de la primera puesta en marcha.
- Si en tu máquina el login ya funciona, es porque tu PostgreSQL ya tenía el esquema y los usuarios. En el equipo de tu compañera, la base se inicializa desde cero con el script y sin usuarios; por eso debe ejecutar una sola vez el paso de crear usuarios.
