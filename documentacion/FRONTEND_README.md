# ERP Frontend - Sistema Point of Sale

Frontend de React para el sistema ERP de punto de venta, conectado con backend FastAPI.

## 🚀 Inicio Rápido

### Prerrequisitos

- Node.js 16+ instalado
- Backend corriendo en `http://localhost:8000`

### Instalación

```bash
# Instalar dependencias
npm install

# Iniciar en modo desarrollo
npm start
```

La aplicación estará disponible en `http://localhost:3000`

## 📁 Estructura del Proyecto

```
frontend/
├── public/              # Archivos estáticos
├── src/
│   ├── components/      # Componentes reutilizables
│   │   ├── Layout.js
│   │   └── Navbar.js
│   ├── context/         # Contextos de React (Auth, etc.)
│   │   └── AuthContext.js
│   ├── pages/           # Páginas principales
│   │   ├── Dashboard.js
│   │   ├── Login.js
│   │   ├── Products.js
│   │   └── Sales.js
│   ├── services/        # Servicios API
│   │   └── apiService.js
│   ├── App.js           # Componente principal
│   └── index.js         # Punto de entrada
├── .env                 # Variables de entorno
└── package.json         # Dependencias
```

## 🎯 Características

### ✅ Implementadas

- **🔐 Autenticación**
  - Login con JWT
  - Protección de rutas
  - Manejo de sesión

- **📊 Dashboard**
  - Estadísticas en tiempo real
  - Ventas recientes
  - Alertas de stock bajo

- **💰 Módulo de Ventas (POS)**
  - Escaneo de productos por código de barras
  - Carrito de compra en tiempo real
  - Descuentos por producto
  - Múltiples métodos de pago
  - Completar/Cancelar ventas

- **📦 Gestión de Productos**
  - Lista de productos
  - Búsqueda y filtrado
  - CRUD completo (Crear, Leer, Actualizar, Eliminar)
  - Visualización de stock
  - Alertas de stock bajo

## 🔗 Integración con Backend

El frontend se conecta automáticamente con el backend FastAPI a través de:

- **Proxy**: Configurado en `package.json` para desarrollo
- **API Service**: Centralizado en `src/services/apiService.js`
- **Interceptores**: Manejo automático de tokens JWT

### Endpoints Utilizados

```javascript
// Autenticación
POST /api/v1/auth/login
GET  /api/v1/auth/me

// Productos
GET    /api/v1/products
GET    /api/v1/products/:id
GET    /api/v1/products/barcode/:barcode
POST   /api/v1/products
PUT    /api/v1/products/:id
DELETE /api/v1/products/:id

// Ventas
GET    /api/v1/sales
GET    /api/v1/sales/:id
POST   /api/v1/sales
POST   /api/v1/sales/:id/item
DELETE /api/v1/sales/:id/item/:productId
POST   /api/v1/sales/:id/complete
POST   /api/v1/sales/:id/cancel

// Inventario
GET  /api/v1/inventory
GET  /api/v1/inventory/low-stock
POST /api/v1/inventory/:id/adjust
```

## 🔑 Usuarios de Prueba

```
Admin:
  Usuario: admin
  Contraseña: admin123

Cajero:
  Usuario: cajero
  Contraseña: cajero123
```

## 🛠️ Scripts Disponibles

```bash
# Desarrollo
npm start              # Inicia el servidor de desarrollo

# Producción
npm run build         # Construye la app para producción
npm test              # Ejecuta los tests

# Otros
npm run eject         # Eyecta configuración (NO REVERSIBLE)
```

## 🐳 Docker (Opcional)

Para ejecutar con Docker:

```bash
# Construir imagen
docker build -t erp-frontend .

# Ejecutar contenedor
docker run -p 3000:3000 erp-frontend
```

## 🌐 Variables de Entorno

Crear archivo `.env` en la raíz:

```env
REACT_APP_API_URL=http://localhost:8000
PORT=3000
```

## 📝 Notas de Desarrollo

### Estructura de Rutas

- `/login` - Página de inicio de sesión
- `/dashboard` - Dashboard principal (protegida)
- `/sales` - Módulo de ventas (protegida)
- `/products` - Gestión de productos (protegida)

### Componentes Principales

1. **AuthContext**: Manejo global de autenticación
2. **Layout**: Wrapper con navbar para páginas protegidas
3. **PrivateRoute**: HOC para protección de rutas

### Estilo

- CSS puro (sin frameworks)
- Diseño responsivo
- Gradientes modernos
- Animaciones suaves

## 🔧 Solución de Problemas

### Error de conexión con backend

```bash
# Verificar que el backend esté corriendo
curl http://localhost:8000/health
```

### Error de CORS

El proxy en `package.json` debería manejar esto automáticamente. Si persiste:

1. Verifica la configuración de CORS en el backend
2. Asegúrate de que `"proxy": "http://localhost:8000"` esté en package.json

### Problemas con dependencias

```bash
# Limpiar e reinstalar
rm -rf node_modules package-lock.json
npm install
```

## 📚 Recursos

- [React Documentation](https://react.dev/)
- [React Router](https://reactrouter.com/)
- [Axios](https://axios-http.com/)

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto es privado y de uso interno.

---

**Desarrollado con ❤️ para el Sistema ERP POS**
