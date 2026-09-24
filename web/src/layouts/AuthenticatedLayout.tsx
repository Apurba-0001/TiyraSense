import React, { useState } from 'react';
import { Outlet } from 'react-router-dom';
import { Header } from '../components/Header';
import { Sidebar } from '../components/Sidebar';

export const AuthenticatedLayout: React.FC = () => {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  const toggleSidebar = () => {
    setIsSidebarOpen((prev) => !prev);
  };

  const closeSidebar = () => {
    setIsSidebarOpen(false);
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', backgroundColor: 'var(--color-canvas)' }}>
      <Header onToggleSidebar={toggleSidebar} isSidebarOpen={isSidebarOpen} />

      {/* Semi-transparent backdrop when side panel is open */}
      {isSidebarOpen && (
        <div
          data-testid="sidebar-backdrop"
          onClick={closeSidebar}
          style={{
            position: 'fixed',
            top: '60px',
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(15, 23, 42, 0.35)',
            backdropFilter: 'blur(2px)',
            zIndex: 35,
            transition: 'opacity 0.2s ease',
          }}
        />
      )}

      <div style={{ display: 'flex', flex: 1, position: 'relative' }}>
        <Sidebar isOpen={isSidebarOpen} onClose={closeSidebar} />
        <main
          className="responsive-main"
          style={{
            flex: 1,
            backgroundColor: 'var(--color-canvas)',
            overflowY: 'auto',
            width: '100%',
          }}
        >
          <Outlet />
        </main>
      </div>
    </div>
  );
};

