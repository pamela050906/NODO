import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

function Login() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  
  const { login, isAuthenticated } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    // Si ya está autenticado, redirigir al dashboard
    if (isAuthenticated) {
      navigate('/dashboard');
    }
  }, [isAuthenticated, navigate]);

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
    <div className="min-vh-100 d-flex align-items-center justify-content-center p-4" style={{background: 'linear-gradient(135deg, var(--erp-primary) 0%, var(--erp-secondary) 100%)'}}>
      <div className="card shadow-lg border-0" style={{maxWidth: '450px', width: '100%'}}>
        <div className="card-header text-white text-center py-4 border-0" style={{background: 'var(--erp-primary)'}}>
          <h1 className="h3 fw-bold mb-2">Sistema ERP</h1>
          <p className="mb-0 opacity-75">Inicia sesión para continuar</p>
        </div>

        <div className="card-body p-4">
          {error && (
            <div className="alert alert-danger d-flex align-items-start gap-2" role="alert">
              <span className="flex-grow-1">{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="mb-3">
              <label htmlFor="username" className="form-label fw-medium">
                Usuario
              </label>
              <input
                type="text"
                id="username"
                className="form-control form-control-lg"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="Ingresa tu usuario"
                required
                disabled={loading}
              />
            </div>

            <div className="mb-3">
              <label htmlFor="password" className="form-label fw-medium">
                Contraseña
              </label>
              <input
                type="password"
                id="password"
                className="form-control form-control-lg"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Ingresa tu contraseña"
                required
                disabled={loading}
              />
            </div>

            <button 
              type="submit" 
              className="btn btn-primary btn-lg w-100 fw-semibold"
              disabled={loading}
            >
              {loading ? (
                <span className="d-flex align-items-center justify-content-center gap-2">
                  <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
                  Iniciando sesión...
                </span>
              ) : (
                'Iniciar Sesión'
              )}
            </button>
          </form>

          <div className="mt-4 p-3 rounded border" style={{background: 'var(--erp-bg-soft)', borderColor: 'var(--erp-border)'}}>
            <p className="small text-center mb-0">
              <strong>Usuarios de prueba:</strong><br />
              <span className="text-primary font-monospace">Admin / admin123</span> (ADMIN)<br />
              <span className="text-success font-monospace">Cajero / cajero123</span> (CAJERO)
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Login;
