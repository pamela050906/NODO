# 🚀 Inicio Rápido - Frontend ERP

Guía rápida para poner en marcha el frontend en menos de 5 minutos.

## ⚡ Pasos Rápidos

### 1. Requisitos Previos

Asegúrate de tener instalado:
- ✅ Node.js 14+ (`node --version`)
- ✅ npm 6+ (`npm --version`)
- ✅ Backend corriendo en `http://localhost:8000`

### 2. Instalación

```bash
# Navegar al directorio frontend
cd frontend

# Instalar dependencias
npm install
```

### 3. Configuración

Crear archivo `.env` en la raíz de frontend:

```env
REACT_APP_API_URL=http://localhost:8000
```

### 4. Ejecutar

```bash
# Modo desarrollo
npm start
```

La aplicación se abrirá automáticamente en `http://localhost:3000`

## 👤 Login de Prueba

### Credenciales

**Administrador**:
- Usuario: `admin`
- Contraseña: `admin123`

**Cajero**:
- Usuario: `cajero`
- Contraseña: `cajero123`

## 📋 Verificación Rápida

### ✅ Checklist Post-Instalación

- [ ] La aplicación abre en `http://localhost:3000`
- [ ] Puedes ver la pantalla de login
- [ ] Puedes iniciar sesión con las credenciales de prueba
- [ ] El dashboard carga correctamente
- [ ] Puedes navegar entre módulos (POS, Almacén, etc.)

### ❌ Problemas Comunes

#### Error: "Cannot GET /"
**Solución**: Asegúrate de estar en el directorio `frontend`

#### Error de conexión con el backend
**Solución**: Verifica que el backend esté corriendo
```bash
curl http://localhost:8000/health
```

#### Página en blanco
**Solución**: Revisa la consola del navegador (F12)

#### "Module not found"
**Solución**: Reinstala dependencias
```bash
rm -rf node_modules package-lock.json
npm install
```

## 🎯 Prueba Rápida de Funcionalidades

### 1. POS (Punto de Venta)

1. Navega a **POS** (`/pos`)
2. Presiona **F1** para nueva venta
3. Ingresa código de barras: `7501234567890`
4. Cantidad: `5`
5. Presiona **Enter**
6. Presiona **F2** para cerrar venta
7. ✅ Verifica que se genere el ticket

### 2. Almacén

1. Navega a **Almacén** (`/almacen`)
2. Click en **➕ Nuevo Producto**
3. Completa el formulario
4. Click en **Crear Producto**
5. ✅ Verifica que aparezca en la tabla

### 3. Reportes

1. Navega a **Reportes** (`/reportes`)
2. Selecciona **Reporte de Ventas**
3. Configura fechas
4. Click en **Generar Reporte**
5. ✅ Verifica que se muestren datos

## 🛠️ Comandos Útiles

```bash
# Iniciar desarrollo
npm start

# Ejecutar tests
npm test

# Build para producción
npm run build

# Linter (si está configurado)
npm run lint

# Limpiar caché
npm cache clean --force
```

## 📦 Estructura Rápida

```
frontend/
├── src/
│   ├── pages/          # Páginas principales
│   ├── components/     # Componentes reutilizables
│   ├── services/       # API calls
│   ├── context/        # Estado global
│   ├── utils/          # Utilidades
│   └── styles/         # Estilos globales
└── public/             # Archivos estáticos
```

## 🎨 Páginas Disponibles

| Ruta | Descripción | Acceso |
|------|-------------|---------|
| `/login` | Inicio de sesión | Público |
| `/dashboard` | Panel principal | Autenticado |
| `/pos` | Punto de venta | ADMIN, CAJERO |
| `/almacen` | Gestión de inventario | ADMIN, ALMACEN |
| `/reportes` | Reportes y análisis | ADMIN, CAJERO |
| `/facturacion` | Facturación SAT | ADMIN, CAJERO |
| `/cobranza` | Cuentas por cobrar | ADMIN, CAJERO |

## ⌨️ Atajos de Teclado (POS)

| Atajo | Acción |
|-------|--------|
| `F1` | Nueva Venta |
| `F2` | Cerrar Venta |
| `F3` | Cancelar Venta |
| `Enter` | Agregar Producto |

## 🔧 Configuración Adicional

### Cambiar Puerto

Por defecto usa el puerto 3000. Para cambiarlo:

**Windows**:
```bash
set PORT=3001 && npm start
```

**Linux/Mac**:
```bash
PORT=3001 npm start
```

### Variables de Entorno

Crear `.env` con:
```env
REACT_APP_API_URL=http://localhost:8000
NODE_ENV=development
```

## 📱 Responsive

El frontend está optimizado para:
- 💻 Desktop (1400px+)
- 📱 Tablet (768px - 1399px)
- 📱 Mobile (< 768px)

## 🐛 Debug

### Modo Desarrollo

Las herramientas de desarrollo están habilitadas:
- React DevTools (extensión del navegador)
- Console logs detallados
- ErrorBoundary con detalles

### Ver Errores de Red

1. Abre DevTools (F12)
2. Ve a la pestaña **Network**
3. Filtra por **Fetch/XHR**
4. Revisa las llamadas a la API

## 📚 Siguientes Pasos

1. ✅ **Explorar la aplicación**: Navega por todos los módulos
2. ✅ **Leer la documentación**: Revisa `README.md` y `GUIA_DESARROLLO.md`
3. ✅ **Personalizar**: Ajusta estilos y configuraciones según necesites
4. ✅ **Integrar con backend real**: Conecta con tu API de producción

## 🆘 Ayuda

¿Necesitas ayuda? Revisa:
- 📖 `README.md` - Documentación completa
- 📚 `GUIA_DESARROLLO.md` - Guía para desarrolladores
- 🐛 Issues del repositorio
- 💬 Contacta al equipo de desarrollo

## 🎉 ¡Listo!

Ahora tienes el frontend corriendo. ¡Comienza a explorar!

```
🏠 Dashboard → Ver estadísticas
🛒 POS → Realizar ventas
📦 Almacén → Gestionar productos
📊 Reportes → Analizar datos
🧾 Facturación → Emitir facturas
💰 Cobranza → Gestionar cobros
```

---

**¡Desarrolla con confianza! 💪**
