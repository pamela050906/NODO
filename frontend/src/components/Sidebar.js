import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Store,
  LayoutDashboard,
  ShoppingCart,
  Package,
  Receipt,
  Wallet,
  LogOut,
  ChevronLeft,
  ChevronRight,
  X,
  TrendingUp
} from 'lucide-react';

const navItems = [
  { path: '/dashboard',   label: 'Dashboard',      icon: LayoutDashboard, section: 'principal'  },
  { path: '/pos',         label: 'Punto de Venta',  icon: ShoppingCart,    section: 'principal'  },
  { path: '/almacen',     label: 'Almacén',         icon: Package,         section: 'inventario' },
  { path: '/reportes',    label: 'Reportes',        icon: TrendingUp,      section: 'analítica'  },
  { path: '/facturacion', label: 'Facturación',     icon: Receipt,         section: 'finanzas'   },
  { path: '/cobranza',    label: 'Cobranza',        icon: Wallet,          section: 'finanzas'   },
];

const sectionLabels = {
  principal:  'Principal',
  inventario: 'Inventario',
  'analítica':'Analítica',
  finanzas:   'Finanzas',
};

function Sidebar({ collapsed, setCollapsed, mobileOpen, setMobileOpen }) {
  const { user, logout } = useAuth();
  const location = useLocation();
  const [hoveredItem, setHoveredItem] = useState(null);

  const isActive = (path) => location.pathname === path;

  const groupedNav = navItems.reduce((acc, item) => {
    if (!acc[item.section]) acc[item.section] = [];
    acc[item.section].push(item);
    return acc;
  }, {});

  const userInitials = user?.username
    ? user.username.slice(0, 2).toUpperCase()
    : 'US';

  // Variantes de texto (label/sección) — fade lateral
  const labelVariants = {
    visible: { opacity: 1, x: 0 },
    hidden:  { opacity: 0, x: -6 },
  };

  return (
    <>
      {/* Overlay en mobile */}
      <AnimatePresence>
        {mobileOpen && (
          <motion.div
            className="erp-sidebar-overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setMobileOpen(false)}
          />
        )}
      </AnimatePresence>

      {/* Sidebar */}
      <motion.aside
        className={`erp-sidebar${collapsed ? ' erp-sidebar--collapsed' : ''}${mobileOpen ? ' erp-sidebar--mobile-open' : ''}`}
        animate={{ width: collapsed ? 78 : 260 }}
        transition={{ duration: 0.28, ease: [0.4, 0, 0.2, 1] }}
      >
        <div className="erp-sidebar__inner">

          {/* ── Header / Logo ── */}
          <div className="erp-sidebar__header">
            <Link to="/dashboard" className="erp-sidebar__logo" tabIndex={-1}>
              <div className="erp-sidebar__logo-icon">
                <Store size={20} strokeWidth={2.2} />
              </div>
              <AnimatePresence>
                {!collapsed && (
                  <motion.div
                    className="erp-sidebar__logo-text"
                    variants={labelVariants}
                    initial="hidden"
                    animate="visible"
                    exit="hidden"
                    transition={{ duration: 0.2 }}
                  >
                    <span className="erp-sidebar__brand">ERP</span>
                    <span className="erp-sidebar__brand-sub">Sistema POS</span>
                  </motion.div>
                )}
              </AnimatePresence>
            </Link>

            {/* Botón colapsar (desktop) */}
            <button
              className="erp-sidebar__collapse-btn d-none d-md-flex"
              onClick={() => setCollapsed(!collapsed)}
              aria-label={collapsed ? 'Expandir menú' : 'Colapsar menú'}
            >
              {collapsed ? <ChevronRight size={15} /> : <ChevronLeft size={15} />}
            </button>

            {/* Botón cerrar (mobile) */}
            <button
              className="erp-sidebar__collapse-btn d-flex d-md-none"
              onClick={() => setMobileOpen(false)}
              aria-label="Cerrar menú"
            >
              <X size={15} />
            </button>
          </div>

          {/* ── Navegación ── */}
          <nav className="erp-sidebar__nav">
            {Object.entries(groupedNav).map(([section, items]) => (
              <div key={section} className="erp-sidebar__section">
                <AnimatePresence>
                  {!collapsed && (
                    <motion.span
                      className="erp-sidebar__section-label"
                      variants={labelVariants}
                      initial="hidden"
                      animate="visible"
                      exit="hidden"
                      transition={{ duration: 0.15 }}
                    >
                      {sectionLabels[section]}
                    </motion.span>
                  )}
                </AnimatePresence>

                {items.map((item) => {
                  const Icon = item.icon;
                  const active = isActive(item.path);
                  return (
                    <div
                      key={item.path}
                      className="erp-sidebar__link-wrapper"
                      onMouseEnter={() => setHoveredItem(item.path)}
                      onMouseLeave={() => setHoveredItem(null)}
                    >
                      <Link
                        to={item.path}
                        className={`erp-sidebar__link${active ? ' erp-sidebar__link--active' : ''}`}
                      >
                        {active && (
                          <motion.div
                            className="erp-sidebar__active-indicator"
                            layoutId="activeIndicator"
                            transition={{ type: 'spring', stiffness: 380, damping: 32 }}
                          />
                        )}
                        <span className="erp-sidebar__link-icon">
                          <Icon size={19} strokeWidth={active ? 2.2 : 1.8} />
                        </span>
                        <AnimatePresence>
                          {!collapsed && (
                            <motion.span
                              className="erp-sidebar__link-label"
                              variants={labelVariants}
                              initial="hidden"
                              animate="visible"
                              exit="hidden"
                              transition={{ duration: 0.15 }}
                            >
                              {item.label}
                            </motion.span>
                          )}
                        </AnimatePresence>
                      </Link>

                      {/* Tooltip sólo en modo colapsado */}
                      <AnimatePresence>
                        {collapsed && hoveredItem === item.path && (
                          <motion.div
                            className="erp-sidebar__tooltip"
                            initial={{ opacity: 0, x: -6 }}
                            animate={{ opacity: 1, x: 0 }}
                            exit={{ opacity: 0, x: -6 }}
                            transition={{ duration: 0.15 }}
                          >
                            {item.label}
                          </motion.div>
                        )}
                      </AnimatePresence>
                    </div>
                  );
                })}
              </div>
            ))}
          </nav>

          {/* ── Footer / Usuario ── */}
          <div className="erp-sidebar__footer">
            <div className="erp-sidebar__user">
              <div className="erp-sidebar__avatar">{userInitials}</div>
              <AnimatePresence>
                {!collapsed && (
                  <motion.div
                    className="erp-sidebar__user-info"
                    variants={labelVariants}
                    initial="hidden"
                    animate="visible"
                    exit="hidden"
                    transition={{ duration: 0.15 }}
                  >
                    <span className="erp-sidebar__username">{user?.username || 'Usuario'}</span>
                    <span className="erp-sidebar__role">{user?.rol || 'N/A'}</span>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>

            <button
              className="erp-sidebar__logout"
              onClick={() => { logout(); }}
              title="Cerrar sesión"
            >
              <LogOut size={17} />
              <AnimatePresence>
                {!collapsed && (
                  <motion.span
                    variants={labelVariants}
                    initial="hidden"
                    animate="visible"
                    exit="hidden"
                    transition={{ duration: 0.15 }}
                  >
                    Salir
                  </motion.span>
                )}
              </AnimatePresence>
            </button>
          </div>
        </div>
      </motion.aside>
    </>
  );
}

export default Sidebar;
