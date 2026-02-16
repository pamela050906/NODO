## Seguridad del sistema y autenticación

Este documento describe cómo se maneja la **seguridad** en el backend ERP/POS, con especial foco en:

- Autenticación de usuarios (login).
- Emisión y validación de tokens **JWT**.
- Gestión de credenciales y contraseñas.
- Control de acceso a endpoints protegidos y roles.
- Configuración sensible (secretos, expiraciones).

---

## Componentes principales de seguridad

- **Configuración (`app/core/config.py`)**
  - `SECRET_KEY`: clave secreta usada para firmar tokens JWT.  
  - `ALGORITHM`: algoritmo de firma (por defecto `HS256`).  
  - `ACCESS_TOKEN_EXPIRE_MINUTES`: minutos de validez del token.  
  - Variables de conexión a base de datos y modo `DEBUG`.

- **Seguridad/JWT (`app/core/security.py`)**
  - Hash y verificación de contraseñas con `passlib` (bcrypt).
  - Creación y decodificación de tokens JWT con `python-jose`.

- **Modelo de usuario (`app/models/usuario.py`)**
  - Tabla `usuarios` con:
    - `id`
    - `nombre`
    - `email` (único)
    - `password_hash` (contraseña hasheada)
    - `rol_id` (FK a tabla `roles`)
    - `activo` (booleano)
    - `creado_en` (timestamp)

- **Esquemas de autenticación (`app/schemas/auth.py`)**
  - `Login`: payload del login (username/password).
  - `Token`: respuesta estándar de login (`access_token`, `token_type`).
  - `TokenData`: datos decodificados del token.
  - `UsuarioResponse`: datos del usuario devueltos por `/auth/me`.

- **Servicio de autenticación (`app/services/auth_service.py`)**
  - Encapsula la lógica de:
    - Validar credenciales.
    - Emitir el token JWT.
    - Resolver el usuario actual a partir del token.

- **Router de autenticación (`app/api/v1/auth.py`)**
  - Define los endpoints HTTP:
    - `POST /api/v1/auth/login`
    - `GET /api/v1/auth/me`

---

## Gestión de contraseñas

Las contraseñas **nunca se guardan en texto plano**.

- En la base de datos (`usuarios.password_hash`) se almacena únicamente el **hash** generado con bcrypt.
- El módulo `app/core/security.py` provee:
  - `get_password_hash(password: str) -> str`  
    - Recibe la contraseña en texto plano y devuelve el hash bcrypt.
  - `verify_password(plain_password: str, hashed_password: str) -> bool`  
    - Compara la contraseña ingresada con el hash almacenado usando bcrypt.

Flujo típico de alta/cambio de contraseña:

1. El usuario define o cambia su contraseña.
2. El backend llama a `get_password_hash` y almacena el resultado en `usuarios.password_hash`.
3. En el login, se recupera `password_hash` de la BD y se llama a `verify_password` para validar.

---

## Tokens JWT: creación y validación

### Creación de tokens

La creación de tokens se realiza en `app/core/security.py` mediante:

- `create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str`

Proceso:

1. Se recibe un diccionario `data` con la información que se quiere incluir en el token (por ejemplo, `sub` y `rol_id`).
2. Se calcula la fecha de expiración:
   - Por defecto, ahora + `ACCESS_TOKEN_EXPIRE_MINUTES` (configurable en `Settings`).
3. Se añade la clave `exp` al payload (momento de expiración).
4. Se firma el token con:
   - `SECRET_KEY`
   - `ALGORITHM` (ej. `HS256`)
5. Se devuelve el **token JWT** como string.

Ejemplo de payload típico:

```json
{
  "sub": "nombre_de_usuario",
  "rol_id": 1,
  "exp": 1738166400
}
```

### Validación/decodificación de tokens

La validación se hace con:

- `decode_access_token(token: str) -> Optional[dict]`

Proceso:

1. Se intenta decodificar el token con `jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])`.
2. Si la firma es válida y no está expirado, devuelve el **payload** (diccionario).
3. Si hay cualquier error (firma incorrecta, token manipulado, expirado, etc.), devuelve `None`.

Este mecanismo se usa en las dependencias de FastAPI para extraer el usuario y su rol a partir del token recibido en el header `Authorization`.

---

## Flujo de login y emisión de token

### Endpoint de login

- **Ruta**: `POST /api/v1/auth/login`  
- **Router**: `app/api/v1/auth.py`  
- **Payload**:
  - Usa el esquema estándar `OAuth2PasswordRequestForm` de FastAPI:
    - `username`
    - `password`
  - Se envía como `application/x-www-form-urlencoded`.

### Lógica interna del login (`AuthService.login`)

1. El router crea una instancia de `AuthService` con la sesión de BD:
   - `auth_service = AuthService(db)`
2. Llama a `auth_service.login(form_data.username, form_data.password)`.

Dentro de `AuthService.login`:

1. **Autenticación de credenciales**  
   - Llama a `authenticate_user(username, password)`:
     - Busca al usuario en la BD por nombre de usuario (`UsuarioRepository.get_by_username`).
     - Si no existe, devuelve `None`.
     - Si existe, valida la contraseña:
       - Llama `verify_password(password, usuario.password_hash)`.
       - Si el hash no coincide, devuelve `None`.
   - Si el resultado es `None`, lanza:
     - `HTTPException(status_code=401, detail="Usuario o contraseña incorrectos", headers={"WWW-Authenticate": "Bearer"})`
2. **Construcción del token**  
   - Calcula la expiración:
     - `access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)`
   - Llama a `create_access_token` con el payload:
     - `data={"sub": usuario.nombre, "rol_id": usuario.rol_id}`
   - Esto genera un JWT que incluye:
     - `sub`: nombre del usuario (identificador lógico).
     - `rol_id`: rol numérico asociado (para control de permisos).
     - `exp`: fecha/hora de expiración.
3. **Respuesta al cliente**  
   - Devuelve un objeto `Token`:
     - `access_token`: token JWT
     - `token_type`: `"bearer"`

El cliente (frontend, otra API, etc.) debe guardar este token y enviarlo en cada petición protegida usando:

```http
Authorization: Bearer <access_token>
```

---

## Resolución del usuario actual

### Servicio `AuthService.get_current_user`

Aunque el decode del token se hace típicamente en dependencias comunes (por ejemplo, en `app/api/dependencies.py`), el servicio de auth ofrece:

- `get_current_user(username: str) -> Usuario`

Proceso:

1. Recibe el `username` extraído previamente del token (campo `sub` del payload JWT).
2. Busca el usuario en la tabla `usuarios` (`get_by_username`).
3. Si no existe, lanza `HTTPException` con `401 Unauthorized`.
4. Si existe, devuelve el modelo `Usuario`.

Este patrón permite:

- Asegurar que el usuario sigue existiendo.
- Verificar que sigue activo (`activo=True`) si la lógica de negocio lo requiere.

### Endpoint `/auth/me`

- **Ruta**: `GET /api/v1/auth/me`  
- **Router**: `app/api/v1/auth.py`  
- **Dependencia**:
  - Usa `get_current_active_user` (en `app.api.dependencies`) para:
    - Decodificar el token JWT.
    - Obtener el usuario desde la BD.
    - Verificar que está activo.
- **Respuesta**:
  - Devuelve un `UsuarioResponse` con:
    - `id`, `nombre`, `email`, `rol_id`, `activo`, `creado_en`.

Este endpoint permite al frontend reconstruir la sesión y saber los permisos del usuario logueado.

---

## Protección de endpoints y autorización

### Autorización por token (nivel básico)

La mayoría de endpoints de negocio (ventas, inventario, facturación, etc.) están marcados en `openapi.yaml` con:

```yaml
security:
  - BearerAuth: []
```

En el código, esto se traduce en dependencias del tipo:

- `Depends(get_current_user)` o `Depends(get_current_active_user)`.

Lo que implica:

1. El cliente debe enviar el header `Authorization: Bearer <token>`.
2. FastAPI ejecuta la dependencia:
   - Decodifica el token.
   - Valida firma y expiración.
   - Obtiene el usuario desde la BD.
3. Si algo falla:
   - Se devuelve `401 Unauthorized` o `403 Forbidden` según el caso.

### Autorización por rol (nivel de negocio)

Aunque los detalles de la tabla `roles` y la lógica fina de permisos están fuera del fragmento mostrado, el diseño prevé:

- Campo `rol_id` en el modelo `Usuario`.
- Inclusión de `rol_id` en el payload del token.

Esto permite en los servicios y routers:

- Restringir ciertas operaciones sólo a roles específicos, por ejemplo:
  - `ADMIN` puede:
    - Crear usuarios.
    - Ejecutar ciertas tareas de facturación o configuración.
  - `CAJERO` puede:
    - Crear ventas.
    - Agregar productos al ticket.
    - Cerrar ventas.
  - `ALMACEN` puede:
    - Registrar movimientos de inventario.
    - Consultar stock, etc.

La comprobación puede hacerse:

- En dependencias que validen el rol antes de entrar al endpoint.
- O directamente en los servicios, lanzando `HTTPException(403)` cuando el rol no es suficiente.

---

## Protección de datos sensibles y configuración

- **SECRET_KEY**
  - Por defecto en `Settings` tiene un valor de ejemplo:
    - `"tu-clave-secreta-super-segura-cambiar-en-produccion"`.
  - En entornos reales, debe sobreescribirse mediante variables de entorno (`.env`) con una clave larga y aleatoria.

- **DEBUG**
  - `DEBUG` está a `True` por defecto.
  - En producción se recomienda ponerlo en `False` para:
    - Evitar trazas de error con detalles internos.
    - Desactivar logs demasiado verbosos.

- **Datos de BD**
  - `DATABASE_URL` y credenciales se leen desde entorno (`.env`) mediante `pydantic_settings`.
  - Es importante no commitear contraseñas reales al repositorio.

---

## Resumen del flujo de seguridad en el login

1. **El usuario envía sus credenciales** a `POST /api/v1/auth/login` (username/password).
2. El backend:
   - Busca el usuario por nombre.
   - Verifica la contraseña con bcrypt (`verify_password`).
3. Si las credenciales son correctas:
   - Construye el payload con:
     - `sub` = nombre de usuario.
     - `rol_id` = rol numérico del usuario.
   - Llama a `create_access_token` con expiración configurada.
   - Devuelve `access_token` + `token_type="bearer"`.
4. **El cliente guarda el token** y lo envía en cada petición protegida en el header `Authorization`.
5. En cada endpoint protegido:
   - Se decodifica el token.
   - Se valida firma y expiración.
   - Se carga el usuario desde la BD.
   - (Opcional) Se verifica rol y estado (`activo`).
6. Si algo falla (token inválido, expirado, usuario inexistente/inactivo, rol insuficiente), la API responde con los códigos adecuados (`401` o `403`) sin exponer información sensible.

