# Guía para actualizar el proyecto (pull de cambios recientes)

Esta guía es para quienes ya tenían el repositorio clonado y van a **traer los últimos cambios** (refactor de carpetas, Docker, etc.) a su máquina.

---

## 1. Guardar tu trabajo local (si tienes cambios sin commitear)

Si tienes archivos modificados que **no** quieres perder:

```bash
# Opción A: Hacer commit de tus cambios en otra rama
git stash
# O crear una rama y commitear ahí:
# git checkout -b mi-rama
# git add .
# git commit -m "Mis cambios antes de actualizar"
```

Si **no** tienes cambios importantes o ya hiciste commit, puedes seguir al paso 2.

---

## 2. Traer los cambios del repositorio (pull)

Abre terminal en la carpeta del proyecto (donde está el `.git`) y ejecuta:

```bash
cd ruta/donde/está/ERP   # Ejemplo: cd ~/OneDrive/Escritorio/ERP

git pull origin main
```

Si te pide usuario/contraseña o token, ingrésalos. Cuando termine, verás algo como *"Already up to date"* o *"Successfully updated"* con la lista de archivos actualizados.

---

## 3. Qué cambió en el proyecto (resumen)

- **Carpeta `docker/`**  
  Todo lo de Docker está ahí. Para levantar servicios ya no se usa `docker-compose` en la raíz, sino:
  ```bash
  docker compose -f docker/docker-compose.yml up -d
  ```

- **Archivos `.env`**  
  - Backend: el ejemplo está en `backend/.env.example`. Copia a `backend/.env` si no lo tienes.
  - Frontend: el ejemplo está en `frontend/.env.example`. Copia a `frontend/.env` si no lo tienes.

- **Páginas del frontend**  
  Cada módulo está en su propia carpeta con su `.js` y `.css`, por ejemplo:
  - `frontend/src/pages/Login/Login.js` y `Login.css`
  - `frontend/src/pages/Dashboard/Dashboard.js`
  - etc.

- **Documentación**  
  - `CHANGELOG.md` y `SOLUCION_LOGIN.md` están ahora en `docs/`.
  - La especificación de la API está en `backend/openapi.yaml`.

- **Dependencias del backend**  
  Solo en `backend/requirements.txt` (ya no hay `requirements.txt` en la raíz).

---

## 4. Después del pull: qué hacer en tu máquina

### Si usas backend con Python local (sin Docker)

```bash
pip install -r backend/requirements.txt
cp backend/.env.example backend/.env
# Edita backend/.env si necesitas (base de datos, etc.)
```

### Si usas frontend con Node local

```bash
cd frontend
npm install
cp .env.example .env
# .env ya trae REACT_APP_API_URL=http://localhost:8000 por defecto
cd ..
```

### Si usas todo con Docker

```bash
docker compose -f docker/docker-compose.yml up -d
```

Para ver logs, detener o reiniciar:

```bash
docker compose -f docker/docker-compose.yml logs -f backend
docker compose -f docker/docker-compose.yml down
docker compose -f docker/docker-compose.yml up -d
```

---

## 5. Si el pull da error o conflictos

**Mensaje tipo: "You have divergent branches" o "Cannot merge"**

No hagas `git pull` a la fuerza. Avísale a quien subió los cambios o al responsable del repo. Si te indican que puedes descartar tus cambios locales:

```bash
git fetch origin
git reset --hard origin/main
```

⚠️ Esto borra los cambios que tengas en tu carpeta y deja todo igual que `origin/main`. Solo hazlo si te confirmaron que está bien.

**Mensaje tipo: "Merge conflict"**

Git marcará los archivos en conflicto. Abre esos archivos, busca las marcas `<<<<<<<`, `=======`, `>>>>>>>` y edita dejando la versión correcta. Luego:

```bash
git add .
git commit -m "Resuelvo conflictos tras pull"
```

---

## 6. Comprobar que todo quedó bien

- Backend: `http://localhost:8000/health` debe responder.
- Frontend: `http://localhost:3000` debe abrir la app.
- Login de prueba: usuario `Admin`, contraseña `admin123` (si la BD tiene los datos de ejemplo).

Si algo no funciona, revisa:
- [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- [docs/SOLUCION_LOGIN.md](SOLUCION_LOGIN.md) (si el problema es solo el login).

---

**Resumen en una línea:**  
Hacer `git pull origin main`, luego `cp backend/.env.example backend/.env` y `cp frontend/.env.example frontend/.env` si no tienes `.env`, y usar `docker compose -f docker/docker-compose.yml up -d` si trabajas con Docker.
