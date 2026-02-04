import React from 'react';
import Navbar from './Navbar';

function Layout({ children }) {
  return (
    <div className="min-vh-100" style={{ background: 'var(--erp-bg-soft)' }}>
      <Navbar />
      <main className="container-fluid py-3 py-md-4 px-2 px-md-3 px-lg-4" style={{maxWidth: '1400px', margin: '0 auto'}}>
        {children}
      </main>
    </div>
  );
}

export default Layout;
