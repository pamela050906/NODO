import React from 'react';

function Loading({ message = 'Cargando...' }) {
  return (
    <div className="position-fixed top-0 start-0 w-100 h-100 d-flex align-items-center justify-content-center" style={{backgroundColor: 'rgba(47, 65, 86, 0.5)', zIndex: 9999, backdropFilter: 'blur(4px)'}}>
      <div className="rounded shadow-lg p-5 text-center" style={{ background: 'var(--erp-bg-main)', border: '1px solid var(--erp-border)' }}>
        <div className="spinner-border text-primary mb-3" role="status" style={{width: '4rem', height: '4rem'}}>
          <span className="visually-hidden">Loading...</span>
        </div>
        <p className="h5 mb-0" style={{ color: 'var(--erp-primary)' }}>{message}</p>
      </div>
    </div>
  );
}

export default Loading;
