# Diagrama de la base de datos del ERP

## 1. Cómo verificar cuál es nuestra base de datos

La aplicación usa **PostgreSQL**. La base de datos se identifica por nombre y conexión.

### 1.1 Dónde está definida

| Ubicación | Qué ver |
|-----------|---------|
| **Backend** | `backend/app/core/config.py`: `DATABASE_URL`, `DATABASE_NAME` |
| **Variables de entorno** | Archivo `.env` en la raíz o en `backend/` (si existe): `DATABASE_URL` |
| **Docker** | `docker-compose.yml`: servicio `db`, variable `POSTGRES_DB` |

Valores por defecto en el proyecto:

- **Motor:** PostgreSQL  
- **Nombre de la base de datos:** `almacen_db`  
- **Usuario:** `postgres`  
- **Puerto:** `5432`  
- **URL típica:** `postgresql://postgres:postgres@localhost:5432/almacen_db`  
- **Con Docker:** `postgresql://postgres:postgres@db:5432/almacen_db`

### 1.2 Verificación desde línea de comandos

**Opción A – Con `psql` (recomendado)**

```bash
# Conexión por defecto (usa variables PGHOST, PGUSER, etc. si están definidas)
psql -U postgres -d almacen_db -h localhost -p 5432

# Una vez conectado, ejecutar:
SELECT current_database();
SELECT version();
\dt
```

- `current_database()` confirma que estás en **almacen_db**.  
- `\dt` lista las tablas del esquema `public`.

**Opción B – Script de verificación incluido**

Desde la raíz del proyecto:

```bash
# Con Python (desde la raíz del repo, para que encuentre app)
cd c:\Users\Fernando Acuña\OneDrive\Escritorio\ERP
python scripts/verificar_bd.py
```

El script muestra: base de datos actual, versión de PostgreSQL, host, lista de tablas y cantidad de tablas.

### 1.3 Verificación desde el backend (código)

El backend usa **SQLAlchemy** y la URL se carga con **Pydantic** desde `config.py` (y opcionalmente desde `.env`). Para comprobar en tiempo de ejecución qué BD se usa, puedes inspeccionar:

```python
from app.core.config import settings
print(settings.DATABASE_NAME)   # almacen_db
print(settings.DATABASE_URL)   # URL completa (sin mostrar contraseña en logs)
```

---

## 2. Cómo hacer un diagrama visual completo y profesional

Tienes varias opciones, de la más rápida a la más elaborada.

### 2.1 Diagrama ya generado en el repositorio (Mermaid)

En este mismo proyecto hay un diagrama ER en **Mermaid** que refleja el esquema actual:

- **Archivo:** `docs/diagrama_er_bd.mmd` (en la raíz del repo: `ERP/docs/diagrama_er_bd.mmd`)  
- **Renderizado:** Puedes abrirlo en:
  - [Mermaid Live Editor](https://mermaid.live)
  - VS Code / Cursor con extensión "Mermaid"
  - GitHub/GitLab (se renderiza en `.md` con bloque ```mermaid)

Desde ahí puedes exportar a PNG/SVG para documentación o presentaciones.

### 2.2 Conectar una herramienta a PostgreSQL y generar el diagrama

Estas herramientas se conectan a tu PostgreSQL y generan el diagrama a partir del esquema real (incluyendo migraciones y `facturacion_actualizada.sql` si ya están aplicadas).

#### A) DBeaver (gratuito, muy usado)

1. Descargar e instalar [DBeaver](https://dbeaver.io/).
2. Crear conexión: PostgreSQL, host `localhost`, puerto `5432`, base de datos `almacen_db`, usuario `postgres`.
3. En el árbol: base de datos **almacen_db** → esquema **public** → clic derecho → **View Diagram** (o **ER Diagram**).
4. Se genera el diagrama a partir de las tablas actuales. Puedes reorganizar y exportar a imagen (PNG/SVG) o PDF.

Muy profesional y siempre alineado con lo que hay en la BD.

#### B) pgAdmin

1. Abrir pgAdmin y conectar al servidor PostgreSQL.
2. Navegar: **almacen_db** → **Schemas** → **public** → **Tables**.
3. En el menú **Tools** → **Query Tool** puedes usar extensiones o herramientas de diagrama si las tienes instaladas; en versiones recientes también hay opciones de “Diagram” desde el árbol (depende de la versión).

#### C) dbdiagram.io (web, muy visual)

dbdiagram.io acepta **SQL DDL de PostgreSQL** directamente (convierte a DBML al importar). Pasos:

**1. Exportar solo el esquema con pg_dump**

**Si tienes PostgreSQL instalado en Windows** (y `pg_dump` en el PATH):

```powershell
cd "C:\Users\Fernando Acuña\OneDrive\Escritorio\ERP"
pg_dump -U postgres -d almacen_db -s --no-owner --no-privileges -f docs\esquema_para_dbdiagram.sql
```

**Si `pg_dump` no se reconoce** (no está instalado o no está en el PATH), usa el contenedor Docker. Con la base de datos levantada (`docker compose up -d` o ya corriendo), en PowerShell desde la raíz del proyecto:

```powershell
cd "C:\Users\Fernando Acuña\OneDrive\Escritorio\ERP"
docker compose exec db pg_dump -U postgres -d almacen_db -s --no-owner --no-privileges | Out-File -FilePath docs\esquema_para_dbdiagram.sql -Encoding utf8
```

- El `pg_dump` se ejecuta **dentro** del contenedor `db`.
- `Out-File -Encoding utf8` evita que PowerShell guarde en UTF-16 (que puede dar problemas al importar).
- No hace falta tener PostgreSQL instalado en Windows.

En ambos casos: `-s` = solo esquema (sin datos); el archivo queda en `docs\esquema_para_dbdiagram.sql`. Luego ejecuta el script de limpieza (paso 2).

**2. (Recomendado) Generar DDL limpio para dbdiagram.io**

El dump crudo incluye `SET`, `CREATE FUNCTION`, etc., que dbdiagram.io no entiende y puede dar error "undefined". Usa el script que deja solo tablas y restricciones:

```powershell
python scripts/limpiar_esquema_para_dbdiagram.py
```

Eso genera **`docs/esquema_para_dbdiagram_limpio.sql`** en UTF-8, solo con `CREATE TABLE`, `ALTER TABLE ADD CONSTRAINT` y `CREATE INDEX`. Usa **ese archivo** para importar en dbdiagram.io.

**3. Importar en dbdiagram.io**

1. Entra en [dbdiagram.io](https://dbdiagram.io) e inicia sesión si quieres guardar el diagrama.  
2. En el menú del editor: **File** → **Import** → **Import from SQL**.  
3. Pega el contenido de **`docs\esquema_para_dbdiagram_limpio.sql`** (o súbelo). **No uses** el `.sql` crudo del dump.  
4. Elige **PostgreSQL** como tipo de base de datos.  
5. Confirma la importación: se generará el diagrama sin errores "undefined".

**Opcional – Convertir a DBML con la CLI**

Si prefieres generar DBML antes:

```bash
npx sql2dbml docs/esquema_para_dbdiagram.sql --postgres -o docs/esquema.dbml
```

Luego en dbdiagram.io: **File** → **Import** → pega o sube el contenido de `esquema.dbml`.

Resultado: diagrama muy limpio y fácil de compartir.

#### D) SchemaSpy (documentación HTML + diagramas)

Genera un sitio HTML con diagramas y documentación de tablas/relaciones:

1. Descargar [SchemaSpy](https://schemaspy.org/) y el driver JDBC de PostgreSQL.
2. Ejecutar algo como:

   ```bash
   java -jar schemaspy.jar -t pgsql -host localhost -port 5432 -db almacen_db -u postgres -p postgres -o output_bd
   ```

3. Abrir `output_bd/index.html` y usar los diagramas generados.

Útil para documentación técnica y auditorías.

### 2.3 Exportar solo el esquema (sin datos) para cualquier herramienta

Para tener un “dump” limpio del esquema actual (tablas, PKs, FKs, índices) y usarlo en cualquier herramienta o para comparar:

```bash
pg_dump -U postgres -d almacen_db -s --no-owner --no-privileges -f esquema_actual.sql
```

- `-s`: solo esquema (estructura).  
- `-f esquema_actual.sql`: nombre del archivo de salida.

Ese archivo es la “foto” de tu base de datos actual y sirve como referencia para diagramas o documentación.

---

## 3. Resumen de la base de datos actual

- **Motor:** PostgreSQL.  
- **Nombre:** `almacen_db`.  
- **Configuración:** `backend/app/core/config.py` y opcionalmente `.env`.  
- **Esquema base:** definido en `docs/almacen_db.sql`.  
- **Cambios posteriores:** migraciones en `migrations/` (001 a 004) y `facturacion_actualizada.sql`.  

Para un diagrama rápido y versionado en el repo: usa **docs/diagrama_er_bd.mmd** (Mermaid).  
Para un diagrama siempre alineado con la BD real y muy profesional: conecta **DBeaver** a `almacen_db` y genera el ER desde el esquema **public**.
