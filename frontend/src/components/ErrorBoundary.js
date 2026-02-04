import React from 'react';
import { AlertTriangle, RefreshCw, Home } from 'lucide-react';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true };
  }

  componentDidCatch(error, errorInfo) {
    console.error('Error capturado por ErrorBoundary:', error, errorInfo);
    this.setState({
      error: error,
      errorInfo: errorInfo
    });
  }

  handleReload = () => {
    window.location.reload();
  };

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-vh-100 d-flex align-items-center justify-content-center p-4" style={{background: 'var(--erp-bg-soft)'}}>
          <div className="card shadow-lg border-0" style={{maxWidth: '800px', width: '100%'}}>
            <div className="card-body p-5 text-center">
              <div className="mb-4 d-flex justify-content-center">
                <AlertTriangle size={64} className="text-warning" />
              </div>
              <h1 className="h2 fw-bold mb-3">Algo salió mal</h1>
              <p className="text-muted mb-4">Ha ocurrido un error inesperado en la aplicación.</p>
              
              {process.env.NODE_ENV === 'development' && this.state.error && (
                <details className="mb-4 p-3 rounded text-start" style={{background: 'var(--erp-bg-soft)', border: '1px solid var(--erp-border)'}}>
                  <summary className="fw-medium mb-2" style={{cursor: 'pointer', color: 'var(--erp-primary)'}}>
                    Detalles del error (solo en desarrollo)
                  </summary>
                  <pre className="small text-danger mb-2 overflow-auto">{this.state.error.toString()}</pre>
                  {this.state.errorInfo && (
                    <pre className="small text-muted overflow-auto">{this.state.errorInfo.componentStack}</pre>
                  )}
                </details>
              )}

              <div className="d-flex gap-3 justify-content-center flex-wrap">
                <button 
                  className="btn btn-primary d-inline-flex align-items-center gap-2"
                  onClick={this.handleReload}
                >
                  <RefreshCw size={18} />
                  Recargar Página
                </button>
                <a href="/" className="btn btn-secondary d-inline-flex align-items-center gap-2">
                  <Home size={18} />
                  Ir al Inicio
                </a>
              </div>
            </div>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
