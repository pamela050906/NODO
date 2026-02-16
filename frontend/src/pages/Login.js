import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Monitor, User, Lock, LogIn } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import './Login.css';

function Login() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const { login, isAuthenticated } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (isAuthenticated) {
      navigate('/dashboard');
    }
  }, [isAuthenticated, navigate]);

  /* Evitar scroll en la página de login */
  useEffect(() => {
    document.documentElement.classList.add('login-page-active');
    document.body.classList.add('login-page-active');
    return () => {
      document.documentElement.classList.remove('login-page-active');
      document.body.classList.remove('login-page-active');
    };
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const result = await login(username, password);

      if (result.success) {
        navigate('/dashboard');
      } else {
        setError(result.error || 'Error al iniciar sesión');
      }
    } catch (err) {
      setError('Error de conexión con el servidor');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-page">
      <div className="login-container">
        {/* Tarjeta glass */}
        <div className="login-card">
          <header className="login-card-header">
            <Monitor className="login-logo-icon" size={32} strokeWidth={1.8} />
            <h1 className="login-brand">Sistema ERP</h1>
          </header>

          <div className="login-card-form-wrap">
            <div className="login-form-waves" aria-hidden="true" />
            <div className="login-card-body">
              {error && (
                <div className="alert alert-danger login-alert d-flex align-items-start gap-2" role="alert">
                  <span className="flex-grow-1">{error}</span>
                </div>
              )}

              <p className="login-welcome">Bienvenido de nuevo</p>

              <form onSubmit={handleSubmit}>
                <div className="login-input-wrap">
                  <label htmlFor="username" className="form-label">
                    Usuario
                  </label>
                  <div className="position-relative">
                    <User className="input-icon" size={20} strokeWidth={2} />
                    <input
                      type="text"
                      id="username"
                      className="form-control"
                      value={username}
                      onChange={(e) => setUsername(e.target.value)}
                      placeholder="Ingresa tu usuario"
                      required
                      disabled={loading}
                      autoComplete="username"
                    />
                  </div>
                </div>

                <div className="login-input-wrap">
                  <label htmlFor="password" className="form-label">
                    Contraseña
                  </label>
                  <div className="position-relative">
                    <Lock className="input-icon" size={20} strokeWidth={2} />
                    <input
                      type="password"
                      id="password"
                      className="form-control"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="Ingresa tu contraseña"
                      required
                      disabled={loading}
                      autoComplete="current-password"
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  className="login-btn-primary"
                  disabled={loading}
                >
                  {loading ? (
                    <span className="d-flex align-items-center justify-content-center gap-2">
                      <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true" />
                      Iniciando sesión...
                    </span>
                  ) : (
                    <>
                      <LogIn size={18} className="me-2" style={{ verticalAlign: 'middle' }} />
                      Iniciar sesión
                    </>
                  )}
                </button>
              </form>

              <p className="login-divider">o</p>
              <button
                type="button"
                className="login-btn-outline"
                onClick={() => {}}
                aria-label="Registrarse (próximamente)"
              >
                Registrarse
              </button>

              <div className="login-demo-block">
                <strong>Usuarios de prueba:</strong><br />
                <span style={{ color: 'var(--erp-primary)' }}>Admin / admin123</span> (ADMIN) ·{' '}
                <span style={{ color: 'var(--erp-secondary)' }}>Cajero / cajero123</span> (CAJERO)
              </div>
            </div>
          </div>
        </div>

        {/* Ilustración: persona en escritorio con computadora */}
        <div className="login-illustration" aria-hidden="true">
          <svg
            viewBox="0 0 400 320"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            role="img"
            aria-label=""
          >
            <defs>
              <linearGradient id="erp-illus-primary" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" stopColor="#2f4156" />
                <stop offset="100%" stopColor="#3d5266" />
              </linearGradient>
            </defs>
            {/* Ventana / marco */}
            <rect x="120" y="40" width="200" height="140" rx="8" stroke="currentColor" strokeWidth="2" fill="none" style={{ color: 'var(--erp-highlight)' }} />
            <line x1="220" y1="40" x2="220" y2="180" stroke="currentColor" strokeWidth="1.5" style={{ color: 'var(--erp-highlight)' }} />
            <line x1="120" y1="100" x2="320" y2="100" stroke="currentColor" strokeWidth="1.5" style={{ color: 'var(--erp-highlight)' }} />
            {/* Escritorio */}
            <path d="M60 200 L340 200 L320 260 L80 260 Z" fill="url(#erp-illus-primary)" />
            <rect x="80" y="180" width="240" height="12" rx="2" fill="var(--erp-secondary)" opacity="0.8" />
            {/* Monitor */}
            <rect x="140" y="120" width="160" height="95" rx="6" fill="var(--erp-primary)" />
            <rect x="152" y="132" width="136" height="72" rx="2" fill="var(--erp-highlight)" opacity="0.4" />
            <rect x="218" y="212" width="4" height="25" fill="var(--erp-primary)" />
            <ellipse cx="220" cy="248" rx="35" ry="6" fill="var(--erp-primary)" />
            {/* Persona: camisa */}
            <path d="M200 165 L240 165 L245 220 L195 220 Z" fill="var(--erp-primary)" />
            {/* Cabeza */}
            <circle cx="220" cy="145" r="28" fill="#e8d5c4" />
            {/* Pantalones */}
            <path d="M198 220 L205 268 L220 268 L222 220 Z" fill="var(--erp-secondary)" />
            <path d="M222 220 L235 268 L250 268 L242 220 Z" fill="var(--erp-secondary)" />
            {/* Teclado */}
            <rect x="195" y="192" width="50" height="22" rx="3" fill="var(--erp-primary)" opacity="0.9" />
          </svg>
        </div>
      </div>
    </div>
  );
}

export default Login;
