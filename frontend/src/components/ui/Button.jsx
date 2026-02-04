import React from 'react';

const variants = {
  primary: 'btn-primary',
  secondary: 'btn-secondary',
  danger: 'btn-danger',
  success: 'btn-success',
  warning: 'btn-warning',
  ghost: 'btn-outline-secondary',
  outline: 'btn-outline-primary',
  link: 'btn-link'
};

const sizes = {
  xs: 'btn-sm',
  sm: 'btn-sm',
  md: '',
  lg: 'btn-lg',
  xl: 'btn-lg px-5'
};

/**
 * Componente Button con Bootstrap 5
 */
export function Button({ 
  children, 
  variant = 'primary', 
  size = 'md',
  loading = false,
  icon: Icon,
  fullWidth = false,
  className = '',
  disabled = false,
  ...props 
}) {
  return (
    <button
      className={`btn ${variants[variant]} ${sizes[size]} ${fullWidth ? 'w-100' : ''} d-inline-flex align-items-center justify-content-center gap-2 ${className}`}
      disabled={loading || disabled}
      {...props}
    >
      {loading ? (
        <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
      ) : (
        Icon && <Icon size={16} />
      )}
      {children}
    </button>
  );
}

export default Button;
