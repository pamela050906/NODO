# 🏪 Sistema ERP - Frontend

Frontend moderno desarrollado con React para el sistema de gestión empresarial (ERP) con módulos de POS, Almacén, Reportes, Facturación y Cobranza.

## Tabla de Contenidos

- [Características](#características)
- [Tecnologías](#tecnologías)
- [Requisitos Previos](#requisitos-previos)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Uso](#uso)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Módulos](#módulos)
- [Atajos de Teclado](#atajos-de-teclado)

## Características

### Módulos Implementados

- **Dashboard**: Vista general con estadísticas y resúmenes
- **POS (Punto de Venta)**: Sistema de ventas con lector de códigos de barras
- **Almacén**: Gestión de productos, variantes y control de inventario
- **Reportes**: Reportes de ventas, almacén y movimientos con exportación
- **Facturación**: Creación y timbrado de facturas SAT
- **Cobranza**: Gestión de cuentas por cobrar y pagos

### Características Generales

- ✅ Autenticación JWT con roles (ADMIN, CAJERO, ALMACEN)
- ✅ Rutas protegidas
- ✅ Diseño responsive
- ✅ Interfaz moderna con gradientes y animaciones
- ✅ Manejo de errores con ErrorBoundary
- ✅ Estados de carga
- ✅ Mensajes de feedback al usuario
- ✅ Atajos de teclado para operaciones rápidas

## Tecnologías

- **React** 19.2.3
- **React Router DOM** 7.12.0
- **Axios** 1.13.2
- **CSS3** (con variables y gradientes)

## Requisitos Previos

- Node.js >= 14.x
- npm >= 6.x
- Backend del ERP corriendo en `http://localhost:8000`

## Instalación

1. **Clonar el repositorio** (si aún no lo has hecho)

```bash
git clone <url-del-repositorio>
cd ERP/frontend
```

2. **Instalar dependencias**

```bash
npm install
```

## Configuración

### Variables de Entorno

Crea un archivo `.env` en la raíz del frontend:

```env
REACT_APP_API_URL=http://localhost:8000
```

### Proxy (Opcional)

El `package.json` ya incluye un proxy configurado para desarrollo:

```json
"proxy": "http://localhost:8000"
```

## Uso

### Desarrollo

Iniciar el servidor de desarrollo:

```bash
npm start
```

La aplicación se abrirá en `http://localhost:3000`

### Producción

Construir para producción:

```bash
npm run build
```

Los archivos optimizados estarán en la carpeta `build/`

### Testing

Ejecutar tests:

```bash
npm test
```

## Estructura del Proyecto

```
frontend/
├── public/
│   ├── index.html
│   └── ...
├── src/
│   ├── components/          # Componentes reutilizables
│   │   ├── Layout.js
│   │   ├── Navbar.js
│   │   ├── Loading.js
│   │   └── ErrorBoundary.js
│   ├── context/            # Context API
│   │   └── AuthContext.js
│   ├── pages/              # Páginas de la aplicación
│   │   ├── Login.js
│   │   ├── Dashboard.js
│   │   ├── POS.js
│   │   ├── Almacen.js
│   │   ├── Reportes.js
│   │   ├── Facturacion.js
│   │   ├── Cobranza.js
│   │   └── NotFound.js
│   ├── services/           # Servicios de API
│   │   └── apiService.js
│   ├── styles/             # Estilos globales
│   │   └── global.css
│   ├── App.js
│   ├── App.css
│   ├── index.js
│   └── index.css
├── package.json
└── README.md
```

## Módulos

### 1. Login

**Ruta**: `/login`

**Credenciales de prueba**:
- Admin: `admin` / `admin123` (Rol: ADMIN)
- Cajero: `cajero` / `cajero123` (Rol: CAJERO)

### 2. Dashboard

**Ruta**: `/dashboard`

**Características**:
- Resumen de ventas del día
- Total de ventas
- Productos con stock bajo
- Ventas recientes

### 3. POS (Punto de Venta)

**Ruta**: `/pos`

**Características**:
- Escaneo de código de barras
- Entrada manual de códigos
- Gestión de cantidad
- Vista en tiempo real del carrito
- Cálculo automático de totales
- Generación e impresión de tickets
- Atajos de teclado

**Flujo de trabajo**:
1. Presiona F1 o haz clic en "Nueva Venta"
2. Escanea o ingresa el código de barras
3. Ajusta la cantidad si es necesario
4. Presiona Enter para agregar el producto
5. Repite para más productos
6. Presiona F2 para cerrar y generar ticket
7. F3 para cancelar si es necesario

### 4. Almacén

**Ruta**: `/almacen`

**Tabs disponibles**:
- **Productos**: Catálogo completo
- **Stock**: Control de inventario
- **Movimientos**: Historial de entradas/salidas

**Operaciones**:
- Crear producto
- Crear variante (talla/color)
- Registrar movimiento
- Carga masiva CSV

### 5. Reportes

**Ruta**: `/reportes`

**Tipos de reportes**:
- **Ventas**: Con filtros por fecha, método de pago, facturado
- **Almacén**: Existencias por categoría
- **Movimientos**: Historial de inventario
- **General Mensual**: Comparativa con mes anterior

**Funciones**:
- Filtros avanzados
- Visualización de datos
- Exportación a CSV
- Resúmenes calculados

### 6. Facturación

**Ruta**: `/facturacion`

**Funciones**:
- Crear factura (selección múltiple de ventas)
- Factura global de tarjetas
- Timbrar con PAC
- Ver facturas emitidas
- Descargar XML/PDF
- Estados: BORRADOR / TIMBRADA / CANCELADA

### 7. Cobranza

**Ruta**: `/cobranza`

**Funciones**:
- Listar cuentas por cobrar
- Filtros (todas/vencidas/pagadas)
- Registrar pagos/abonos
- Métodos de pago múltiples
- Estado de cuenta por cliente
- Alertas de vencimiento

## ⌨Atajos de Teclado

### POS (Punto de Venta)

| Atajo | Acción |
|-------|--------|
| `F1` | Nueva Venta |
| `F2` | Cerrar Venta |
| `F3` | Cancelar Venta |
| `Enter` | Agregar Producto |

## Temas y Estilos

El frontend utiliza un sistema de diseño moderno con:

- **Colores primarios**: Gradientes púrpura-azul (#667eea - #764ba2)
- **Tipografía**: System fonts para mejor rendimiento
- **Animaciones**: Transiciones suaves y efectos hover
- **Responsive**: Diseño adaptable a móviles y tablets
- **Componentes**: Cards, badges, botones, modales consistentes

## Autenticación y Roles

El sistema implementa control de acceso basado en roles (RBAC):

### Permisos por Rol

**ADMIN**: Acceso completo a todos los módulos

**CAJERO**:
- ✅ Dashboard
- ✅ POS (ventas)
- ✅ Reportes (solo consulta)
- ✅ Facturación
- ✅ Cobranza

**ALMACEN**:
- ✅ Dashboard
- ✅ Almacén (productos, inventario)
- ✅ Reportes de almacén

## 🐛 Debugging

### Modo Desarrollo

```bash
npm start
```

Características de desarrollo:
- Hot reload automático
- Source maps para debugging
- ErrorBoundary muestra detalles del error
- Console logs de errores de API

### Variables de Entorno

```env
NODE_ENV=development
REACT_APP_API_URL=http://localhost:8000
```

## Responsive Design

El frontend está optimizado para:

- **Desktop**: 1400px+ (experiencia completa)
- **Tablet**: 768px - 1399px (adaptación de layouts)
- **Mobile**: < 768px (columna única, navegación simplificada)

## Despliegue

### Build de Producción

```bash
npm run build
```

### Servir archivos estáticos

```bash
npm install -g serve
serve -s build -l 3000
```

### Con Docker

Ver `Dockerfile` en la raíz del proyecto frontend.

## 🔧 Solución de Problemas

### Error de conexión con el backend

Verifica que:
1. El backend esté corriendo en `http://localhost:8000`
2. La variable `REACT_APP_API_URL` esté configurada correctamente
3. No haya problemas de CORS

### Errores de autenticación

1. Limpia localStorage: `localStorage.clear()`
2. Recarga la página
3. Intenta iniciar sesión nuevamente

### Problemas de dependencias

```bash
rm -rf node_modules package-lock.json
npm install
```

## API Integration

El frontend se comunica con el backend a través de `apiService.js`:

```javascript
import { authService, salesService, productService, ... } from './services/apiService';
```

Todos los servicios están documentados en el archivo `apiService.js`

## Contribuciones

Para contribuir:

1. Haz fork del proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto es parte de un sistema ERP privado.

## 👥 Soporte

Para reportar bugs o solicitar features, crea un issue en el repositorio.

---

