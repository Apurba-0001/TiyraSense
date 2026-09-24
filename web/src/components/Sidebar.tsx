import React from 'react';
import { NavLink } from 'react-router-dom';
import { useAuth } from '../state/AuthContext';
import {
  LayoutGrid,
  Route as RouteIcon,
  FileText,
  Bell,
  Users,
  Settings,
  LogOut,
  X,
} from 'lucide-react';

interface SidebarProps {
  isOpen?: boolean;
  onClose?: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ isOpen = false, onClose }) => {
  const { user, logout } = useAuth();
  const isAdmin = user?.role === 'ADMIN';

  const operationsLinks = [
    { to: '/dashboard', label: 'Dashboard', icon: <LayoutGrid size={18} /> },
    { to: '/corridors', label: 'Corridors', icon: <RouteIcon size={18} /> },
    { to: '/reports', label: 'Field Reports', icon: <FileText size={18} /> },
    { to: '/alerts', label: 'Alerts', icon: <Bell size={18} />, badge: '3' },
  ];

  const adminLinks = [
    { to: '/users', label: 'User Management', icon: <Users size={18} /> },
    { to: '/settings', label: 'System Health & Settings', icon: <Settings size={18} /> },
  ];

  return (
    <aside
      data-testid="side-panel"
      style={{
        width: 'min(280px, 85vw)',
        backgroundColor: 'var(--color-surface)',
        borderRight: '1px solid var(--color-border)',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        padding: '16px 14px',
        flexShrink: 0,
        height: 'calc(100vh - 60px)',
        position: 'fixed',
        top: '60px',
        left: 0,
        zIndex: 40,
        overflowY: 'auto',
        WebkitOverflowScrolling: 'touch',
        boxShadow: isOpen ? 'var(--modal-shadow)' : 'none',
        transform: isOpen ? 'translateX(0)' : 'translateX(-100%)',
        visibility: isOpen ? 'visible' : 'hidden',
        transition: 'transform 0.26s cubic-bezier(0.16, 1, 0.3, 1), visibility 0.26s, box-shadow 0.26s',
      }}
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {/* Header inside side panel with Close button */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            padding: '2px 6px 12px',
            borderBottom: '1px solid var(--color-border)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <div
              style={{
                width: '8px',
                height: '8px',
                borderRadius: '50%',
                backgroundColor: 'var(--color-primary)',
              }}
            />
            <span
              style={{
                fontSize: '12px',
                fontWeight: 700,
                color: 'var(--color-text-primary)',
                letterSpacing: '0.05em',
                textTransform: 'uppercase',
              }}
            >
              Command Panel
            </span>
          </div>
          {onClose && (
            <button
              type="button"
              data-testid="sidebar-close-btn"
              aria-label="Close side panel"
              title="Close panel"
              onClick={onClose}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: '28px',
                height: '28px',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--color-border)',
                backgroundColor: 'var(--color-container)',
                color: 'var(--color-text-secondary)',
                cursor: 'pointer',
                transition: 'all var(--transition-fast)',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.backgroundColor = 'var(--color-danger-bg)';
                e.currentTarget.style.color = 'var(--color-danger)';
                e.currentTarget.style.borderColor = 'var(--color-danger)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.backgroundColor = 'var(--color-container)';
                e.currentTarget.style.color = 'var(--color-text-secondary)';
                e.currentTarget.style.borderColor = 'var(--color-border)';
              }}
            >
              <X size={16} />
            </button>
          )}
        </div>
        {/* Operations Section */}
        <div>
          <div
            style={{
              padding: '0 12px 8px',
              fontSize: '11px',
              fontWeight: 700,
              color: 'var(--color-text-disabled)',
              textTransform: 'uppercase',
              letterSpacing: '0.06em',
            }}
          >
            OPERATIONS
          </div>

          <nav style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
            {operationsLinks.map((link) => (
              <NavLink
                key={link.to}
                to={link.to}
                onClick={onClose}
                style={({ isActive }) => ({
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  height: '40px',
                  padding: '0 12px',
                  borderRadius: 'var(--radius-sm)',
                  fontSize: '13px',
                  fontWeight: isActive ? 600 : 500,
                  color: isActive ? 'var(--color-primary)' : 'var(--color-text-secondary)',
                  backgroundColor: isActive ? 'var(--color-primary-bg)' : 'transparent',
                  borderLeft: isActive ? '3px solid var(--color-primary)' : '3px solid transparent',
                  transition: 'background-color var(--transition-fast)',
                })}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  {link.icon}
                  <span>{link.label}</span>
                </div>
                {link.badge && (
                  <span
                    style={{
                      backgroundColor: 'var(--color-primary-light)',
                      color: 'var(--color-primary)',
                      fontSize: '11px',
                      fontWeight: 700,
                      padding: '2px 7px',
                      borderRadius: '10px',
                    }}
                  >
                    {link.badge}
                  </span>
                )}
              </NavLink>
            ))}
          </nav>
        </div>

        {/* Administration Section (Admin only) */}
        {isAdmin && (
          <div>
            <div
              style={{
                padding: '0 12px 8px',
                fontSize: '11px',
                fontWeight: 700,
                color: 'var(--color-text-disabled)',
                textTransform: 'uppercase',
                letterSpacing: '0.06em',
              }}
            >
              ADMINISTRATION
            </div>

            <nav style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
              {adminLinks.map((link) => (
                <NavLink
                  key={link.to}
                  to={link.to}
                  onClick={onClose}
                  style={({ isActive }) => ({
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px',
                    height: '40px',
                    padding: '0 12px',
                    borderRadius: 'var(--radius-sm)',
                    fontSize: '13px',
                    fontWeight: isActive ? 600 : 500,
                    color: isActive ? 'var(--color-primary)' : 'var(--color-text-secondary)',
                    backgroundColor: isActive ? 'var(--color-primary-bg)' : 'transparent',
                    borderLeft: isActive ? '3px solid var(--color-primary)' : '3px solid transparent',
                    transition: 'background-color var(--transition-fast)',
                  })}
                >
                  {link.icon}
                  <span>{link.label}</span>
                </NavLink>
              ))}
            </nav>
          </div>
        )}
      </div>

      {/* Bottom Block */}
      <div>
        <div style={{ height: '1px', backgroundColor: 'var(--color-border)', marginBottom: '12px' }} />

        <button
          onClick={() => {
            onClose?.();
            logout();
          }}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            width: '100%',
            height: '40px',
            padding: '0 12px',
            borderRadius: 'var(--radius-sm)',
            fontSize: '13px',
            fontWeight: 500,
            color: 'var(--color-danger)',
            transition: 'background-color var(--transition-fast)',
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.backgroundColor = 'var(--color-danger-bg)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.backgroundColor = 'transparent';
          }}
        >
          <LogOut size={16} />
          <span>Sign Out</span>
        </button>

        <div
          style={{
            textAlign: 'center',
            fontSize: '11px',
            color: 'var(--color-text-disabled)',
            marginTop: '8px',
          }}
        >
          TiyraSense v1.0
        </div>
      </div>
    </aside>
  );
};
