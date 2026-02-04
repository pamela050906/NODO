import React from 'react';
import { X } from 'lucide-react';

/**
 * Componente Input con Bootstrap 5
 */
export function Input({ 
  label, 
  error, 
  helperText,
  icon: Icon,
  clearable = false,
  onClear,
  fullWidth = true,
  className = '',
  ...props 
}) {
  const hasValue = props.value && props.value.length > 0;

  return (
    <div className={`mb-3 ${fullWidth ? 'w-100' : ''}`}>
      {label && (
        <label className="form-label">
          {label}
          {props.required && <span className="text-danger ms-1">*</span>}
        </label>
      )}
      
      <div className="position-relative">
        {Icon && (
          <div className="position-absolute top-50 start-0 translate-middle-y ms-3 text-muted">
            <Icon size={20} />
          </div>
        )}
        
        <input
          className={`form-control ${Icon ? 'ps-5' : ''} ${clearable && hasValue ? 'pe-5' : ''} ${error ? 'is-invalid' : ''} ${className}`}
          {...props}
        />
        
        {clearable && hasValue && !props.disabled && (
          <button
            type="button"
            onClick={onClear}
            className="btn btn-sm position-absolute top-50 end-0 translate-middle-y me-2 p-0 border-0"
            style={{background: 'none'}}
          >
            <X size={18} className="text-muted" />
          </button>
        )}
        
        {error && (
          <div className="invalid-feedback d-block">{error}</div>
        )}
      </div>
      
      {helperText && !error && (
        <div className="form-text">{helperText}</div>
      )}
    </div>
  );
}

export default Input;
