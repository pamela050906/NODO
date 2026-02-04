import { useState, useCallback } from 'react';

/**
 * Hook personalizado para manejar notificaciones Toast
 * @returns {Object} { toast, showToast, hideToast }
 */
function useToast() {
  const [toast, setToast] = useState({
    show: false,
    tipo: 'info',
    mensaje: ''
  });

  const showToast = useCallback((tipo, mensaje, duracion = 3000) => {
    setToast({
      show: true,
      tipo,
      mensaje,
      duracion
    });

    if (duracion > 0) {
      setTimeout(() => {
        setToast(prev => ({ ...prev, show: false }));
      }, duracion);
    }
  }, []);

  const hideToast = useCallback(() => {
    setToast(prev => ({ ...prev, show: false }));
  }, []);

  // Métodos de conveniencia
  const success = useCallback((mensaje, duracion) => {
    showToast('success', mensaje, duracion);
  }, [showToast]);

  const error = useCallback((mensaje, duracion) => {
    showToast('error', mensaje, duracion);
  }, [showToast]);

  const warning = useCallback((mensaje, duracion) => {
    showToast('warning', mensaje, duracion);
  }, [showToast]);

  const info = useCallback((mensaje, duracion) => {
    showToast('info', mensaje, duracion);
  }, [showToast]);

  return {
    toast,
    showToast,
    hideToast,
    success,
    error,
    warning,
    info
  };
}

export default useToast;
