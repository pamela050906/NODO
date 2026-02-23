import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import ErrorBoundary from './components/ErrorBoundary';
import Login from './pages/Login/Login';
import Dashboard from './pages/Dashboard/Dashboard';
import POS from './pages/POS/POS';
import Almacen from './pages/Almacen/Almacen';
import Reportes from './pages/Reportes/Reportes';
import Facturacion from './pages/Facturacion/Facturacion';
import Cobranza from './pages/Cobranza/Cobranza';
import NotFound from './pages/NotFound/NotFound';
import './App.css';

// Componente para rutas protegidas
function PrivateRoute({ children }) {
  const { token, loading } = useAuth();
  
  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Cargando...</p>
      </div>
    );
  }
  
  return token ? children : <Navigate to="/login" />;
}

function AppRoutes() {
  const { token } = useAuth();

  return (
    <Routes>
      <Route 
        path="/login" 
        element={token ? <Navigate to="/dashboard" /> : <Login />} 
      />
      <Route
        path="/dashboard"
        element={
          <PrivateRoute>
            <Dashboard />
          </PrivateRoute>
        }
      />
      <Route
        path="/pos"
        element={
          <PrivateRoute>
            <POS />
          </PrivateRoute>
        }
      />
      <Route
        path="/almacen"
        element={
          <PrivateRoute>
            <Almacen />
          </PrivateRoute>
        }
      />
      <Route
        path="/reportes"
        element={
          <PrivateRoute>
            <Reportes />
          </PrivateRoute>
        }
      />
      <Route
        path="/facturacion"
        element={
          <PrivateRoute>
            <Facturacion />
          </PrivateRoute>
        }
      />
      <Route
        path="/cobranza"
        element={
          <PrivateRoute>
            <Cobranza />
          </PrivateRoute>
        }
      />
      <Route path="/" element={<Navigate to="/dashboard" />} />
      <Route path="*" element={<NotFound />} />
    </Routes>
  );
}

function App() {
  return (
    <ErrorBoundary>
      <AuthProvider>
        <Router>
          <div className="App">
            <AppRoutes />
          </div>
        </Router>
      </AuthProvider>
    </ErrorBoundary>
  );
}

export default App;
