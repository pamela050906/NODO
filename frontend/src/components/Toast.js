import React, { useState, useEffect } from 'react';
import { CheckCircle, XCircle, AlertTriangle, Info } from 'lucide-react';

/**
 * Componente Toast con Bootstrap 5
 */
function Toast({ tipo = 'info', mensaje, duracion = 3000, onClose }) {
  const [visible, setVisible] = useState(true);

  useEffect(() => {
    if (duracion > 0) {
      const timer = setTimeout(() => {
        handleClose();
      }, duracion);

      return () => clearTimeout(timer);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [duracion]);

  const handleClose = () => {
    setVisible(false);
    setTimeout(() => {
      if (onClose) onClose();
    }, 300);
  };

  const alertTypes = {
    success: 'alert-success',
    error: 'alert-danger',
    warning: 'alert-warning',
    info: 'alert-info'
  };

  const IconComponent = { success: CheckCircle, error: XCircle, warning: AlertTriangle, info: Info }[tipo] || Info;

  if (!mensaje) return null;

  return (
    <div 
      className={`alert ${alertTypes[tipo]} alert-dismissible position-fixed top-0 end-0 m-3 shadow-lg ${visible ? 'show' : 'hide'}`}
      role="alert"
      style={{maxWidth: '400px', zIndex: 9999, transition: 'all 0.3s ease'}}
    >
      <div className="d-flex align-items-center gap-2">
        <IconComponent size={22} className="flex-shrink-0" />
        <div className="flex-grow-1 fw-medium">{mensaje}</div>
        <button 
          type="button" 
          className="btn-close" 
          onClick={handleClose}
          aria-label="Close"
        ></button>
      </div>
    </div>
  );
}

export default Toast;
