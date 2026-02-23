# Solución para Problemas de Login en Docker

## Problema
El frontend se abre pero el login no funciona cuando se ingresan los datos.

## Posibles Causas y Soluciones

### 1. Variables de Entorno no Configuradas Correctamente

**Problema**: React necesita que las variables `REACT_APP_*` estén disponibles cuando se ejecuta `npm start`.

**Solución**: 
- Se ha actualizado el `Dockerfile.dev` (en `frontend/`) para crear automáticamente un archivo `.env` con las variables de entorno
- Se ha agregado un script `docker-entrypoint.sh` que configura las variables antes de iniciar React

**Pasos**:
```bash
# Reconstruir el contenedor del frontend (desde la raíz del proyecto)
docker compose -f docker/docker-compose.yml build frontend

# Reiniciar los contenedores
docker compose -f docker/docker-compose.yml down
docker compose -f docker/docker-compose.yml up -d
```

### 2. No Hay Usuarios en la Base de Datos

**Problema**: Si la base de datos está vacía, no habrá usuarios para hacer login.

**Solución**: Crear usuarios usando el script proporcionado:

```bash
# Crear usuarios por defecto (Admin y Cajero)
python scripts/crear_usuario.py --crear-defaults

# O crear un usuario específico
python scripts/crear_usuario.py --nombre Admin --password admin123 --rol 1 --email admin@local.com
```

**Usuarios por defecto**:
- **Admin**: nombre=`Admin`, password=`admin123`, rol=ADMIN (ID: 1)
- **Cajero**: nombre=`Cajero`, password=`cajero123`, rol=CAJERO (ID: 2)

### 3. Backend No Está Respondiendo

**Problema**: El backend puede no estar corriendo o no estar accesible.

**Solución**: Verificar que el backend esté corriendo:

```bash
# Verificar contenedores
docker ps

# Ver logs del backend
docker logs pos_backend

# Verificar que el backend responde
curl http://localhost:8000/health
```

### 4. Problemas de CORS

**Problema**: El backend puede estar rechazando peticiones del frontend.

**Solución**: El backend está configurado con CORS permitiendo todos los orígenes (`*`) en desarrollo. Si hay problemas, verifica la configuración en `backend/app/core/config.py`.

### 5. URL del API Incorrecta

**Problema**: El frontend puede estar intentando conectarse a una URL incorrecta.

**Solución**: 
- Desde el navegador del host, `http://localhost:8000` es correcto porque el puerto 8000 está mapeado al host
- Verifica que `REACT_APP_API_URL=http://localhost:8000` esté configurado en `docker/docker-compose.yml`

## Script de Diagnóstico

Se ha creado un script de diagnóstico para identificar problemas:

```bash
# Ejecutar diagnóstico completo
python scripts/diagnostico_login.py
```

Este script verifica:
1. Conexión al backend
2. Estado del endpoint de login
3. Usuarios en la base de datos
4. Configuración de CORS
5. Variables de entorno del frontend

## Pasos Recomendados para Solucionar

1. **Ejecutar el diagnóstico**:
   ```bash
   python scripts/diagnostico_login.py
   ```

2. **Verificar que todos los contenedores estén corriendo**:
   ```bash
   docker ps
   ```
   Deberías ver: `pos_db`, `pos_backend`, `pos_frontend`

3. **Verificar logs si hay errores**:
   ```bash
   docker logs pos_backend
   docker logs pos_frontend
   ```

4. **Crear usuarios si no existen**:
   ```bash
   python scripts/crear_usuario.py --crear-defaults
   ```

5. **Reconstruir contenedores si es necesario**:
   ```bash
   docker compose -f docker/docker-compose.yml down
   docker compose -f docker/docker-compose.yml build
   docker compose -f docker/docker-compose.yml up -d
   ```

6. **Abrir la consola del navegador (F12)** y verificar:
   - Errores en la consola
   - Peticiones de red en la pestaña "Network"
   - Verificar que las peticiones a `/api/v1/auth/login` se están haciendo correctamente

## Verificación Final

1. Abre el navegador en `http://localhost:3000`
2. Abre la consola del desarrollador (F12)
3. Intenta hacer login con:
   - Usuario: `Admin`
   - Password: `admin123`
4. Revisa la consola y la pestaña Network para ver si hay errores

## Contacto

Si el problema persiste después de seguir estos pasos, proporciona:
- Salida del script de diagnóstico
- Logs del backend (`docker logs pos_backend`)
- Logs del frontend (`docker logs pos_frontend`)
- Capturas de pantalla de la consola del navegador
