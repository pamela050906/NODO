# 📚 Guía de Desarrollo - Frontend ERP

Esta guía proporciona las mejores prácticas y convenciones para el desarrollo del frontend.

## 📋 Índice

1. [Estructura de Archivos](#estructura-de-archivos)
2. [Convenciones de Código](#convenciones-de-código)
3. [Componentes](#componentes)
4. [Estilos CSS](#estilos-css)
5. [Gestión de Estado](#gestión-de-estado)
6. [Integración con API](#integración-con-api)
7. [Testing](#testing)
8. [Buenas Prácticas](#buenas-prácticas)

## 📁 Estructura de Archivos

```
src/
├── components/          # Componentes reutilizables
│   ├── Layout.js
│   ├── Navbar.js
│   ├── Loading.js
│   ├── ErrorBoundary.js
│   ├── Toast.js
│   └── ConfirmDialog.js
├── context/            # Context API
│   └── AuthContext.js
├── hooks/              # Custom hooks
│   └── useToast.js
├── pages/              # Páginas/Vistas
│   ├── Login.js
│   ├── Dashboard.js
│   ├── POS.js
│   └── ...
├── services/           # Servicios de API
│   └── apiService.js
├── styles/             # Estilos globales
│   └── global.css
├── utils/              # Utilidades
│   ├── constants.js
│   └── helpers.js
├── App.js
└── index.js
```

### Convenciones de Nombres

- **Componentes**: PascalCase (ej: `UserProfile.js`)
- **Utilidades**: camelCase (ej: `formatearMoneda`)
- **Constantes**: UPPER_SNAKE_CASE (ej: `API_BASE_URL`)
- **Archivos CSS**: mismo nombre del componente (ej: `Login.css` para `Login.js`)

## 🎨 Estilos CSS

### Sistema de Diseño

#### Colores Primarios

```css
/* Gradientes principales */
--primary-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
--success-gradient: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
--danger-gradient: linear-gradient(135deg, #ee0979 0%, #ff6a00 100%);
--warning-gradient: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
--info-gradient: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
```

#### Espaciado

Usar múltiplos de 0.5rem:
- `0.5rem` (8px) - Extra pequeño
- `1rem` (16px) - Pequeño
- `1.5rem` (24px) - Mediano
- `2rem` (32px) - Grande
- `3rem` (48px) - Extra grande

#### Tipografía

```css
/* Tamaños de fuente */
--font-xs: 0.75rem;    /* 12px */
--font-sm: 0.875rem;   /* 14px */
--font-base: 1rem;     /* 16px */
--font-lg: 1.125rem;   /* 18px */
--font-xl: 1.5rem;     /* 24px */
--font-2xl: 2rem;      /* 32px */
```

### Clases Utilitarias

Usar clases de `global.css`:

```css
.card              /* Tarjeta estándar */
.btn               /* Botón base */
.btn-primary       /* Botón primario */
.badge             /* Badge/etiqueta */
.form-control      /* Input/select */
.text-center       /* Texto centrado */
.mt-2              /* Margin top */
```

### Guía de Estilo

1. **Usar variables CSS** cuando sea posible
2. **Evitar !important** a menos que sea absolutamente necesario
3. **Mobile-first**: escribir estilos base para móvil, luego media queries para desktop
4. **BEM naming** para componentes complejos (opcional)

## ⚛️ Componentes

### Estructura de un Componente

```javascript
import React, { useState, useEffect } from 'react';
import Layout from '../components/Layout';
import { servicioAPI } from '../services/apiService';
import './MiComponente.css';

/**
 * Descripción del componente
 * @param {Object} props - Props del componente
 */
function MiComponente({ prop1, prop2 }) {
  // 1. State
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);

  // 2. Effects
  useEffect(() => {
    cargarDatos();
  }, []);

  // 3. Handlers
  const cargarDatos = async () => {
    try {
      setLoading(true);
      const resultado = await servicioAPI.getData();
      setData(resultado);
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };

  // 4. Render
  if (loading) {
    return <Loading />;
  }

  return (
    <Layout>
      <div className="mi-componente">
        {/* Contenido */}
      </div>
    </Layout>
  );
}

export default MiComponente;
```

### Componentes Reutilizables Disponibles

#### Layout
```javascript
import Layout from '../components/Layout';

<Layout>
  {/* Contenido de la página */}
</Layout>
```

#### Loading
```javascript
import Loading from '../components/Loading';

<Loading message="Cargando datos..." />
```

#### Toast (Notificaciones)
```javascript
import useToast from '../hooks/useToast';

const { success, error, warning, info } = useToast();

// Usar
success('Operación exitosa');
error('Error al guardar');
warning('Atención requerida');
info('Información adicional');
```

#### ConfirmDialog
```javascript
import ConfirmDialog from '../components/ConfirmDialog';

const [showConfirm, setShowConfirm] = useState(false);

<ConfirmDialog
  title="¿Eliminar producto?"
  message="Esta acción no se puede deshacer"
  tipo="danger"
  onConfirm={handleEliminar}
  onCancel={() => setShowConfirm(false)}
/>
```

## 🔌 Integración con API

### Usar servicios en `apiService.js`

```javascript
import { productService, salesService } from '../services/apiService';

// Obtener productos
const productos = await productService.getAll({ activo: true });

// Crear venta
const venta = await salesService.create({
  punto_venta_id: 1,
  metodo_pago: 'EFECTIVO',
  detalles: []
});
```

### Manejo de Errores

```javascript
try {
  const data = await apiService.operation();
  // Éxito
  showToast('success', 'Operación exitosa');
} catch (error) {
  // Error
  const mensaje = error.response?.data?.detail || 'Error desconocido';
  showToast('error', mensaje);
  console.error('Error detallado:', error);
}
```

## 📊 Gestión de Estado

### Context API (Auth)

```javascript
import { useAuth } from '../context/AuthContext';

function MiComponente() {
  const { user, token, login, logout, isAuthenticated } = useAuth();

  // Verificar rol
  if (user?.rol !== 'ADMIN') {
    return <p>No autorizado</p>;
  }

  return <div>Contenido para admin</div>;
}
```

### Local State (useState)

Para estado local del componente:

```javascript
const [formData, setFormData] = useState({
  nombre: '',
  email: ''
});

const handleChange = (e) => {
  setFormData({
    ...formData,
    [e.target.name]: e.target.value
  });
};
```

## 🧪 Testing

### Estructura de Tests

```javascript
import { render, screen } from '@testing-library/react';
import MiComponente from './MiComponente';

describe('MiComponente', () => {
  test('renderiza correctamente', () => {
    render(<MiComponente />);
    expect(screen.getByText('Título')).toBeInTheDocument();
  });

  test('maneja click en botón', async () => {
    render(<MiComponente />);
    const boton = screen.getByRole('button');
    fireEvent.click(boton);
    // Assertions...
  });
});
```

## ✅ Buenas Prácticas

### 1. Separación de Responsabilidades

- **Componentes**: Solo renderizado y lógica de UI
- **Services**: Comunicación con API
- **Utils**: Funciones auxiliares reutilizables
- **Context**: Estado global compartido

### 2. Nomenclatura Clara

```javascript
// ❌ Mal
const d = new Date();
const f = () => {};

// ✅ Bien
const fechaActual = new Date();
const calcularTotal = () => {};
```

### 3. Manejo de Loading States

```javascript
const [loading, setLoading] = useState(false);

const fetchData = async () => {
  try {
    setLoading(true);
    const data = await api.getData();
    setData(data);
  } catch (error) {
    handleError(error);
  } finally {
    setLoading(false); // Siempre en finally
  }
};
```

### 4. Validación de Datos

```javascript
import { validarEmail, validarRFC } from '../utils/helpers';

const handleSubmit = (e) => {
  e.preventDefault();
  
  if (!validarEmail(email)) {
    showToast('error', 'Email inválido');
    return;
  }
  
  // Continuar...
};
```

### 5. Optimización de Renders

```javascript
// Usar React.memo para componentes que no cambian seguido
const MiComponente = React.memo(({ data }) => {
  return <div>{data}</div>;
});

// useCallback para funciones pasadas como props
const handleClick = useCallback(() => {
  // Lógica
}, [dependencias]);
```

### 6. Accesibilidad

```javascript
// Siempre usar labels para inputs
<label htmlFor="email">Email</label>
<input id="email" type="email" />

// Atributos aria cuando sea necesario
<button aria-label="Cerrar modal">✕</button>

// Alt text en imágenes
<img src="logo.png" alt="Logo de la empresa" />
```

### 7. Seguridad

```javascript
// Nunca guardar datos sensibles en localStorage sin encriptar
localStorage.setItem('token', token); // OK para tokens JWT

// Sanitizar inputs de usuario
const sanitizeInput = (input) => {
  return input.trim().replace(/[<>]/g, '');
};
```

## 🎯 Utilidades Disponibles

### Constants (`utils/constants.js`)

```javascript
import { ROLES, ESTADOS_VENTA, METODOS_PAGO } from '../utils/constants';

// Verificar rol
if (user.rol === ROLES.ADMIN) {
  // ...
}

// Estado de venta
if (venta.estado === ESTADOS_VENTA.CERRADA) {
  // ...
}
```

### Helpers (`utils/helpers.js`)

```javascript
import {
  formatearMoneda,
  formatearFecha,
  calcularTotal,
  obtenerColorEstado
} from '../utils/helpers';

// Formatear moneda
const precio = formatearMoneda(1234.56); // "$1,234.56"

// Formatear fecha
const fecha = formatearFecha(new Date(), true); // "22/01/2026 14:30:45"

// Calcular total
const total = calcularTotal(items); // Suma todos los subtotales

// Obtener color de badge
const color = obtenerColorEstado('COMPLETADA'); // 'success'
```

## 🚀 Flujo de Desarrollo

1. **Crear feature branch**
   ```bash
   git checkout -b feature/nueva-funcionalidad
   ```

2. **Desarrollar**
   - Escribir componente
   - Agregar estilos
   - Integrar con API
   - Probar manualmente

3. **Testing**
   ```bash
   npm test
   ```

4. **Lint y formato**
   ```bash
   npm run lint
   ```

5. **Commit**
   ```bash
   git add .
   git commit -m "feat: agregar nueva funcionalidad"
   ```

6. **Push y PR**
   ```bash
   git push origin feature/nueva-funcionalidad
   ```

## 📝 Convenciones de Commits

Usar [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` Nueva funcionalidad
- `fix:` Corrección de bug
- `docs:` Cambios en documentación
- `style:` Cambios de formato/estilo
- `refactor:` Refactorización de código
- `test:` Agregar o modificar tests
- `chore:` Tareas de mantenimiento

Ejemplos:
```
feat: agregar módulo de reportes
fix: corregir cálculo de totales en POS
docs: actualizar README con instrucciones
style: mejorar estilos del dashboard
refactor: extraer lógica de validación a helpers
```

## 🔍 Debugging

### React DevTools

Instalar extensión de navegador: React Developer Tools

### Console Logs

```javascript
// Desarrollo
if (process.env.NODE_ENV === 'development') {
  console.log('Debug info:', data);
}

// Errores siempre
console.error('Error crítico:', error);
```

### Network Inspector

Usar la pestaña Network del navegador para depurar llamadas API.

## 📖 Recursos Adicionales

- [React Docs](https://react.dev/)
- [MDN Web Docs](https://developer.mozilla.org/)
- [CSS Tricks](https://css-tricks.com/)
- [JavaScript Info](https://javascript.info/)

---

**¡Feliz desarrollo! 🚀**
