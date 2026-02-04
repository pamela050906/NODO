import React from 'react';
import { AlertTriangle, HelpCircle, Info, CheckCircle } from 'lucide-react';

/**
 * Componente ConfirmDialog con Bootstrap 5
 */
function ConfirmDialog({
  title = '¿Estás seguro?',
  message,
  onConfirm,
  onCancel,
  confirmText = 'Confirmar',
  cancelText = 'Cancelar',
  tipo = 'warning'
}) {
  const iconosConfig = {
    danger: { Icon: AlertTriangle, btnClass: 'btn-danger' },
    warning: { Icon: HelpCircle, btnClass: 'btn-warning' },
    info: { Icon: Info, btnClass: 'btn-primary' },
    success: { Icon: CheckCircle, btnClass: 'btn-success' }
  };

  const config = iconosConfig[tipo];
  const IconComponent = config.Icon;

  return (
    <div 
      className="modal d-block" 
      style={{backgroundColor: 'rgba(47, 65, 86, 0.5)', backdropFilter: 'blur(4px)'}}
      onClick={onCancel}
    >
      <div className="modal-dialog modal-dialog-centered">
        <div className="modal-content" onClick={(e) => e.stopPropagation()}>
          <div className="modal-body text-center p-4">
            <div className="mb-3 d-flex justify-content-center">
              <IconComponent size={48} style={{ color: 'var(--erp-secondary)' }} />
            </div>
            <h5 className="modal-title fw-bold mb-2">{title}</h5>
            {message && <p className="text-muted mb-4">{message}</p>}
          </div>
          <div className="modal-footer justify-content-center border-0 pt-0">
            <button className="btn btn-secondary" onClick={onCancel}>
              {cancelText}
            </button>
            <button className={`btn ${config.btnClass}`} onClick={onConfirm}>
              {confirmText}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default ConfirmDialog;
