import React from 'react';
import { Link } from 'react-router-dom';
import { Search, Home } from 'lucide-react';

function NotFound() {
  return (
    <div className="min-vh-100 d-flex align-items-center justify-content-center p-4" style={{background: 'var(--erp-bg-soft)'}}>
      <div className="text-center">
        <div className="mb-4 d-flex justify-content-center">
          <Search size={80} className="text-secondary" style={{color: 'var(--erp-secondary)'}} />
        </div>
        <h1 className="display-1 fw-black mb-4" style={{color: 'var(--erp-primary)'}}>404</h1>
        <h2 className="h2 fw-bold mb-3" style={{color: 'var(--erp-primary)'}}>Página no encontrada</h2>
        <p className="text-muted fs-5 mb-5" style={{maxWidth: '500px', margin: '0 auto'}}>
          La página que estás buscando no existe o ha sido movida.
        </p>
        <Link to="/dashboard" className="btn btn-primary btn-lg shadow d-inline-flex align-items-center gap-2">
          <Home size={20} />
          Volver al Dashboard
        </Link>
      </div>
    </div>
  );
}

export default NotFound;
