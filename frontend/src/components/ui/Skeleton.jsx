import React from 'react';

/**
 * Skeleton con Bootstrap 5
 */
export function Skeleton({ className = '', ...props }) {
  return (
    <div className={`placeholder-glow ${className}`} {...props}>
      <span className="placeholder col-12 bg-secondary"></span>
    </div>
  );
}

/**
 * CardSkeleton - Skeleton para cards
 */
export function CardSkeleton({ lines = 3 }) {
  return (
    <div className="card shadow">
      <div className="card-body placeholder-glow">
        <div className="placeholder col-6 bg-secondary mb-3" style={{height: '24px'}}></div>
        {[...Array(lines)].map((_, i) => (
          <div 
            key={i} 
            className={`placeholder ${i === lines - 1 ? 'col-8' : 'col-12'} bg-secondary mb-2`}
            style={{height: '16px'}}
          ></div>
        ))}
      </div>
    </div>
  );
}

/**
 * TableSkeleton - Skeleton para tablas
 */
export function TableSkeleton({ rows = 5 }) {
  return (
    <div className="placeholder-glow">
      {[...Array(rows)].map((_, i) => (
        <div key={i} className="d-flex align-items-center gap-3 mb-3">
          <div className="placeholder rounded-circle bg-secondary" style={{width: '48px', height: '48px'}}></div>
          <div className="flex-grow-1">
            <div className="placeholder col-9 bg-secondary mb-2" style={{height: '16px'}}></div>
            <div className="placeholder col-6 bg-secondary" style={{height: '12px'}}></div>
          </div>
        </div>
      ))}
    </div>
  );
}

/**
 * StatCardSkeleton - Skeleton para tarjetas de estadísticas
 */
export function StatCardSkeleton() {
  return (
    <div className="card shadow">
      <div className="card-body placeholder-glow">
        <div className="d-flex align-items-center gap-3">
          <div className="placeholder rounded bg-secondary" style={{width: '48px', height: '48px'}}></div>
          <div className="flex-grow-1">
            <div className="placeholder col-8 bg-secondary mb-2" style={{height: '16px'}}></div>
            <div className="placeholder col-5 bg-secondary" style={{height: '32px'}}></div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Skeleton;
