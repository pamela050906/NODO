import React from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { 
  Store, 
  LayoutDashboard, 
  ShoppingCart, 
  Package, 
  FileText, 
  Receipt, 
  Wallet, 
  LogOut,
  User
} from 'lucide-react';
import { Button } from './ui';

function Navbar() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const isActive = (path) => location.pathname === path;

  const linkClass = (path) => `
    nav-link d-flex align-items-center gap-2 px-3 py-2 rounded
    ${isActive(path) ? 'active' : ''}
  `;

  return (
    <nav className="navbar navbar-expand-lg navbar-dark navbar-erp shadow-sm sticky-top">
      <div className="container-fluid">
        {/* Logo */}
        <Link to="/dashboard" className="navbar-brand d-flex align-items-center gap-2 text-white">
          <div className="p-2 rounded shadow-sm" style={{ background: 'rgba(255,255,255,0.2)' }}>
            <Store className="text-white" size={24} />
          </div>
          <span className="fw-bold d-none d-sm-inline text-white">ERP Sistema POS</span>
        </Link>

        {/* Toggler para mobile */}
        <button className="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
          <span className="navbar-toggler-icon"></span>
        </button>

        {/* Navigation Links */}
        <div className="collapse navbar-collapse" id="navbarNav">
          <ul className="navbar-nav mx-auto">
            <li className="nav-item">
              <Link to="/dashboard" className={linkClass('/dashboard')}>
                <LayoutDashboard size={18} />
                Dashboard
              </Link>
            </li>
            <li className="nav-item">
              <Link to="/pos" className={linkClass('/pos')}>
                <ShoppingCart size={18} />
                POS
              </Link>
            </li>
            <li className="nav-item">
              <Link to="/almacen" className={linkClass('/almacen')}>
                <Package size={18} />
                Almacén
              </Link>
            </li>
            <li className="nav-item">
              <Link to="/reportes" className={linkClass('/reportes')}>
                <FileText size={18} />
                Reportes
              </Link>
            </li>
            <li className="nav-item">
              <Link to="/facturacion" className={linkClass('/facturacion')}>
                <Receipt size={18} />
                Facturación
              </Link>
            </li>
            <li className="nav-item">
              <Link to="/cobranza" className={linkClass('/cobranza')}>
                <Wallet size={18} />
                Cobranza
              </Link>
            </li>
          </ul>

          {/* User Menu */}
          <div className="d-flex align-items-center gap-3">
            <div className="d-none d-sm-flex align-items-center gap-2 px-3 py-2 rounded text-white" style={{ background: 'rgba(255,255,255,0.15)' }}>
              <User size={18} />
              <div className="d-flex flex-column">
                <small className="fw-semibold">{user?.username || 'Usuario'}</small>
                <small className="opacity-75">{user?.rol || 'N/A'}</small>
              </div>
            </div>
            
            <Button 
              variant="danger" 
              size="sm"
              icon={LogOut}
              onClick={handleLogout}
            >
              Salir
            </Button>
          </div>
        </div>
      </div>
    </nav>
  );
}

export default Navbar;
