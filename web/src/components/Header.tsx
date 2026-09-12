import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../state/AuthContext';
import { ChevronDown, Menu } from 'lucide-react';
import appIcon from '../assets/app_icon.png';
import { AccountDetailsModal } from './AccountDetailsModal';

interface HeaderProps {
  onToggleSidebar?: () => void;
  isSidebarOpen?: boolean;
}

export const Header: React.FC<HeaderProps> = ({ onToggleSidebar, isSidebarOpen = false }) => {
  const { user } = useAuth();
  const [isAccountModalOpen, setIsAccountModalOpen] = useState(false);

  const getInitials = (name?: string) => {
    if (!name) return 'TS';
    const parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.slice(0, 2).toUpperCase();
  };

  return (
    <>
      <header
        style={{
          height: '60px',
          backgroundColor: 'var(--color-surface)',
          borderBottom: '1px solid var(--color-border)',
          boxShadow: 'var(--topbar-shadow)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '0 24px',
          position: 'sticky',
          top: 0,
          zIndex: 30,
          width: '100%',
        }}
      >
        {/* Left zone: 3-lines hamburger button + App icon + TiyraSense branding */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
          }}
        >
          {/* 3 lines button to toggle side panel */}
          <button
            type="button"
            data-testid="sidebar-toggle-btn"
            aria-label={isSidebarOpen ? 'Hide navigation panel' : 'Open navigation panel'}
            title={isSidebarOpen ? 'Hide side panel' : 'Open side panel (3 lines)'}
            onClick={onToggleSidebar}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: '38px',
              height: '38px',
              borderRadius: 'var(--radius-md)',
              border: '1px solid var(--color-border)',
              backgroundColor: isSidebarOpen ? 'var(--color-primary-bg)' : 'var(--color-surface)',
              color: isSidebarOpen ? 'var(--color-primary)' : 'var(--color-text-primary)',
              cursor: 'pointer',
              transition: 'all var(--transition-fast)',
              flexShrink: 0,
              padding: 0,
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.backgroundColor = 'var(--color-primary-bg)';
              e.currentTarget.style.borderColor = 'var(--color-primary-light)';
              e.currentTarget.style.color = 'var(--color-primary)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.backgroundColor = isSidebarOpen ? 'var(--color-primary-bg)' : 'var(--color-surface)';
              e.currentTarget.style.borderColor = 'var(--color-border)';
              e.currentTarget.style.color = isSidebarOpen ? 'var(--color-primary)' : 'var(--color-text-primary)';
            }}
          >
            <Menu size={22} strokeWidth={2.2} />
          </button>

          <Link
            to="/dashboard"
            data-testid="navbar-logo-link"
            aria-label="TiyraSense - Navigate to Dashboard"
            title="Navigate to Dashboard"
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              textDecoration: 'none',
              cursor: 'pointer',
              borderRadius: 'var(--radius-md)',
              padding: '4px 6px',
              margin: '-4px -6px',
              transition: 'opacity var(--transition-fast)',
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.opacity = '0.85';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.opacity = '1';
            }}
          >
            <div
              style={{
                width: '32px',
                height: '32px',
                borderRadius: '8px',
                backgroundColor: '#FFFFFF',
                border: '1px solid var(--color-border)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                overflow: 'hidden',
                flexShrink: 0,
              }}
            >
              <img
                src={appIcon}
                alt="TiyraSense Icon"
                style={{
                  width: '26px',
                  height: '26px',
                  objectFit: 'contain',
                }}
              />
            </div>
            <div style={{ display: 'flex', flexDirection: 'column' }}>
              <span
                style={{
                  fontSize: '15px',
                  fontWeight: 800,
                  color: 'var(--color-text-primary)',
                  letterSpacing: '-0.02em',
                  lineHeight: 1.1,
                }}
              >
                TiyraSense
              </span>
              <span
                style={{
                  fontSize: '10px',
                  fontWeight: 700,
                  color: 'var(--color-primary)',
                  letterSpacing: '0.04em',
                }}
              >
                NER INTELLIGENCE
              </span>
            </div>
          </Link>
        </div>

        {/* Center zone: Horizontal inline status strip */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
          }}
        >
          <div
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
              backgroundColor: 'var(--color-success-bg)',
              color: 'var(--color-success)',
              padding: '4px 10px',
              borderRadius: 'var(--radius-pill)',
              fontSize: '11px',
              fontWeight: 700,
              letterSpacing: '0.04em',
            }}
          >
            <span
              className="pulse-beacon"
              style={{
                width: '6px',
                height: '6px',
                borderRadius: '50%',
                backgroundColor: 'var(--color-success)',
                display: 'inline-block',
              }}
            />
            <span>LIVE FEED</span>
          </div>

          <div style={{ width: '1px', height: '18px', backgroundColor: 'var(--color-border)' }} />

          <span
            style={{
              fontSize: '13px',
              color: 'var(--color-text-secondary)',
              fontWeight: 500,
            }}
          >
            Coverage: NER 8 Corridors
          </span>

          <div style={{ width: '1px', height: '18px', backgroundColor: 'var(--color-border)' }} />

          <span
            className="mono"
            style={{
              fontSize: '12px',
              color: 'var(--color-text-muted)',
              fontWeight: 500,
            }}
          >
            Updated 2m ago
          </span>
        </div>

        {/* Right zone */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          {/* User profile (clickable to open account details modal) */}
          {user && (
            <div
              role="button"
              tabIndex={0}
              onClick={() => setIsAccountModalOpen(true)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                  setIsAccountModalOpen(true);
                }
              }}
              title="Click to view & update account details"
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
                padding: '4px 8px',
                borderRadius: 'var(--radius-md)',
                cursor: 'pointer',
                transition: 'background-color var(--transition-fast)',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.backgroundColor = 'var(--color-canvas)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.backgroundColor = 'transparent';
              }}
            >
              <div
                style={{
                  width: '34px',
                  height: '34px',
                  borderRadius: '50%',
                  backgroundColor: 'var(--color-primary)',
                  color: '#FFFFFF',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: '13px',
                  fontWeight: 700,
                  flexShrink: 0,
                  boxShadow: 'var(--card-shadow)',
                }}
              >
                {getInitials(user.full_name)}
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', textAlign: 'left' }}>
                <span
                  style={{
                    fontSize: '13px',
                    fontWeight: 600,
                    color: 'var(--color-text-primary)',
                    lineHeight: 1.2,
                  }}
                >
                  {user.full_name || 'Official'}
                </span>
                <span
                  style={{
                    fontSize: '11px',
                    fontWeight: 500,
                    color: 'var(--color-text-muted)',
                  }}
                >
                  {user.role}
                </span>
              </div>

              <ChevronDown size={14} color="var(--color-text-disabled)" />
            </div>
          )}
        </div>
      </header>

      {/* Account Details Modal */}
      <AccountDetailsModal
        isOpen={isAccountModalOpen}
        onClose={() => setIsAccountModalOpen(false)}
      />
    </>
  );
};
