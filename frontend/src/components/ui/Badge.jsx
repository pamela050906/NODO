import React from 'react';

const variants = {
  success: 'bg-success',
  danger: 'bg-danger',
  warning: 'bg-warning text-dark',
  info: 'bg-info',
  default: 'bg-secondary',
  primary: 'bg-primary'
};

/**
 * Componente Badge con Bootstrap 5
 */
export function Badge({ 
  children, 
  variant = 'default', 
  icon: Icon,
  dot = false,
  className = '',
  pill = true
}) {
  return (
    <span className={`badge ${pill ? 'rounded-pill' : ''} ${variants[variant]} d-inline-flex align-items-center gap-1 ${className}`}>
      {dot && <span style={{width: '6px', height: '6px', borderRadius: '50%', backgroundColor: 'currentColor', opacity: 0.8}} />}
      {Icon && <Icon size={12} />}
      {children}
    </span>
  );
}

export default Badge;
