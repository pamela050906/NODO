import React from 'react';

/**
 * Card - Contenedor principal con Bootstrap 5
 */
export function Card({ children, className = '', hover = false }) {
  return (
    <div className={`card shadow ${hover ? 'card-hover' : ''} ${className}`}>
      {children}
    </div>
  );
}

/**
 * CardHeader - Cabecera del card
 */
export function CardHeader({ children, className = '', gradient = false, color = 'primary' }) {
  const bgColors = {
    primary: 'bg-primary text-white',
    success: 'bg-success text-white',
    warning: 'bg-warning text-dark',
    danger: 'bg-danger text-white',
    info: 'bg-info text-white'
  };

  return (
    <div className={`card-header ${gradient ? bgColors[color] : ''} ${className}`}>
      {children}
    </div>
  );
}

/**
 * CardContent - Contenido del card
 */
export function CardContent({ children, className = '', padding = true }) {
  return (
    <div className={`card-body ${!padding ? 'p-0' : ''} ${className}`}>
      {children}
    </div>
  );
}

/**
 * CardFooter - Pie del card
 */
export function CardFooter({ children, className = '' }) {
  return (
    <div className={`card-footer bg-light ${className}`}>
      {children}
    </div>
  );
}

/**
 * CardTitle - Título del card
 */
export function CardTitle({ children, className = '' }) {
  return (
    <h3 className={`card-title ${className}`}>
      {children}
    </h3>
  );
}

/**
 * CardDescription - Descripción del card
 */
export function CardDescription({ children, className = '' }) {
  return (
    <p className={`card-text text-muted ${className}`}>
      {children}
    </p>
  );
}

export default Card;
