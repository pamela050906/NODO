/**
 * Funciones de utilidad para la aplicación
 */

/**
 * Formatea un número como moneda (pesos mexicanos)
 * @param {number} valor - El valor a formatear
 * @param {number} decimales - Número de decimales (default: 2)
 * @returns {string} Valor formateado como "$1,234.56"
 */
export const formatearMoneda = (valor, decimales = 2) => {
  if (valor === null || valor === undefined || isNaN(valor)) {
    return '$0.00';
  }
  
  return new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: 'MXN',
    minimumFractionDigits: decimales,
    maximumFractionDigits: decimales
  }).format(valor);
};

/**
 * Formatea una fecha a formato legible
 * @param {string|Date} fecha - La fecha a formatear
 * @param {boolean} incluirHora - Si incluir la hora (default: false)
 * @returns {string} Fecha formateada
 */
export const formatearFecha = (fecha, incluirHora = false) => {
  if (!fecha) return '-';
  
  const date = new Date(fecha);
  if (isNaN(date.getTime())) return '-';
  
  const opciones = {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  };
  
  if (incluirHora) {
    opciones.hour = '2-digit';
    opciones.minute = '2-digit';
    opciones.second = '2-digit';
  }
  
  return date.toLocaleString('es-MX', opciones);
};

/**
 * Trunca un texto a una longitud máxima
 * @param {string} texto - El texto a truncar
 * @param {number} maxLength - Longitud máxima (default: 50)
 * @returns {string} Texto truncado con "..."
 */
export const truncarTexto = (texto, maxLength = 50) => {
  if (!texto) return '';
  if (texto.length <= maxLength) return texto;
  return texto.substring(0, maxLength) + '...';
};

/**
 * Valida si un email es válido
 * @param {string} email - Email a validar
 * @returns {boolean} true si es válido
 */
export const validarEmail = (email) => {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
};

/**
 * Valida si un RFC mexicano es válido (formato básico)
 * @param {string} rfc - RFC a validar
 * @returns {boolean} true si es válido
 */
export const validarRFC = (rfc) => {
  // Persona física: 13 caracteres
  // Persona moral: 12 caracteres
  const regex = /^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$/;
  return regex.test(rfc);
};

/**
 * Genera un código de barras aleatorio (para testing)
 * @returns {string} Código de barras de 13 dígitos
 */
export const generarCodigoBarras = () => {
  return Math.floor(Math.random() * 9000000000000 + 1000000000000).toString();
};

/**
 * Debounce function - retrasa la ejecución de una función
 * @param {function} func - Función a ejecutar
 * @param {number} wait - Tiempo de espera en ms
 * @returns {function} Función con debounce
 */
export const debounce = (func, wait = 300) => {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
};

/**
 * Capitaliza la primera letra de un texto
 * @param {string} texto - Texto a capitalizar
 * @returns {string} Texto capitalizado
 */
export const capitalizar = (texto) => {
  if (!texto) return '';
  return texto.charAt(0).toUpperCase() + texto.slice(1).toLowerCase();
};

/**
 * Calcula el porcentaje de descuento
 * @param {number} precioOriginal - Precio original
 * @param {number} precioFinal - Precio final
 * @returns {number} Porcentaje de descuento
 */
export const calcularDescuento = (precioOriginal, precioFinal) => {
  if (!precioOriginal || precioOriginal === 0) return 0;
  return ((precioOriginal - precioFinal) / precioOriginal) * 100;
};

/**
 * Formatea un número de teléfono (México)
 * @param {string} telefono - Número de teléfono
 * @returns {string} Teléfono formateado
 */
export const formatearTelefono = (telefono) => {
  if (!telefono) return '';
  
  // Eliminar caracteres no numéricos
  const numeros = telefono.replace(/\D/g, '');
  
  // Formato: (XXX) XXX-XXXX para 10 dígitos
  if (numeros.length === 10) {
    return `(${numeros.slice(0, 3)}) ${numeros.slice(3, 6)}-${numeros.slice(6)}`;
  }
  
  return telefono;
};

/**
 * Descarga un archivo blob
 * @param {Blob} blob - Blob a descargar
 * @param {string} nombreArchivo - Nombre del archivo
 */
export const descargarArchivo = (blob, nombreArchivo) => {
  const url = window.URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = nombreArchivo;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  window.URL.revokeObjectURL(url);
};

/**
 * Copia texto al portapapeles
 * @param {string} texto - Texto a copiar
 * @returns {Promise<boolean>} true si se copió correctamente
 */
export const copiarAlPortapapeles = async (texto) => {
  try {
    await navigator.clipboard.writeText(texto);
    return true;
  } catch (err) {
    console.error('Error al copiar al portapapeles:', err);
    return false;
  }
};

/**
 * Calcula el total de un array de items
 * @param {Array} items - Array de items con propiedad 'subtotal' o 'total'
 * @param {string} campo - Campo a sumar (default: 'subtotal')
 * @returns {number} Total calculado
 */
export const calcularTotal = (items, campo = 'subtotal') => {
  if (!items || !Array.isArray(items)) return 0;
  return items.reduce((sum, item) => sum + (parseFloat(item[campo]) || 0), 0);
};

/**
 * Verifica si una fecha está vencida
 * @param {string|Date} fecha - Fecha a verificar
 * @returns {boolean} true si está vencida
 */
export const estaVencida = (fecha) => {
  if (!fecha) return false;
  const fechaObj = new Date(fecha);
  const hoy = new Date();
  return fechaObj < hoy;
};

/**
 * Calcula días entre dos fechas
 * @param {string|Date} fechaInicio - Fecha inicial
 * @param {string|Date} fechaFin - Fecha final (default: hoy)
 * @returns {number} Días de diferencia
 */
export const diasEntre = (fechaInicio, fechaFin = new Date()) => {
  const inicio = new Date(fechaInicio);
  const fin = new Date(fechaFin);
  const diferencia = fin.getTime() - inicio.getTime();
  return Math.floor(diferencia / (1000 * 60 * 60 * 24));
};

/**
 * Obtiene el color según el estado
 * @param {string} estado - Estado a verificar
 * @returns {string} Clase CSS del color
 */
export const obtenerColorEstado = (estado) => {
  const colores = {
    'ABIERTA': 'warning',
    'CERRADA': 'success',
    'COMPLETADA': 'success',
    'CANCELADA': 'danger',
    'PENDIENTE': 'warning',
    'TIMBRADA': 'success',
    'BORRADOR': 'secondary',
    'PAGADA': 'success',
    'VENCIDA': 'danger'
  };
  
  return colores[estado] || 'secondary';
};

/**
 * Sleep/delay asíncrono
 * @param {number} ms - Milisegundos a esperar
 * @returns {Promise} Promise que se resuelve después del delay
 */
export const sleep = (ms) => {
  return new Promise(resolve => setTimeout(resolve, ms));
};

const helpers = {
  formatearMoneda,
  formatearFecha,
  truncarTexto,
  validarEmail,
  validarRFC,
  generarCodigoBarras,
  debounce,
  capitalizar,
  calcularDescuento,
  formatearTelefono,
  descargarArchivo,
  copiarAlPortapapeles,
  calcularTotal,
  estaVencida,
  diasEntre,
  obtenerColorEstado,
  sleep
};

export default helpers;
