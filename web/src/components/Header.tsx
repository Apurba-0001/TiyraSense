import React from 'react';
import { useAuth } from '../state/AuthContext';
import { StatusBadge } from './StatusBadge';
import { LogOut, Radio, User as UserIcon } from 'lucide-react';
import logo from '../assets/logo.png';

export const Header: React.FC = () => {
  const { user, logout } = useAuth();

  return (
    <header
      style={{
        height: '68px',
        backgroundColor: 'rgba(255, 255, 255, 0.85)',
        backdropFilter: 'blur(16px)',
        WebkitBackdropFilter: 'blur(16px)',
        borderBottom: '1px solid var(--border)',
        boxShadow: 'var(--shadow-xs)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '0 2rem',
        position: 'sticky',
        top: 0,
        zIndex: 20,
      }}
    >
      {/* Brand & Provenance */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.85rem' }}>
          <img
            src={logo}
            alt="TiyraSense"
            style={{
              height: '32px',
              width: 'auto',
              display: 'block',
              objectFit: 'contain',
            }}
          />
          <div style={{ borderLeft: '1px solid var(--border)', paddingLeft: '0.85rem', display: 'flex', flexDirection: 'column' }}>
            <span style={{ fontSize: '0.70rem', fontWeight: 600, color: 'var(--text-muted)', letterSpacing: '0.04em', textTransform: 'uppercase' }}>
              NER Logistics Intelligence
            </span>
          </div>
        </div>

        {/* Live Data Badge */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', marginLeft: '0.25rem' }}>
          <Radio size={14} color="var(--success)" style={{ animation: 'pulse 2s infinite' }} />
          <StatusBadge label="LIVE DATA" variant="LIVE" size="sm" />
        </div>
      </div>

      {/* User Information & Controls */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem' }}>
        {user && (
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <div
              style={{
                width: '36px',
                height: '36px',
                borderRadius: 'var(--radius-full)',
                backgroundColor: '#f1f5f9',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'var(--text-secondary)',
              }}
            >
              <UserIcon size={18} />
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', justifyContent: 'flex-end' }}>
                <span style={{ fontSize: '0.875rem', fontWeight: 600 }}>{user.full_name}</span>
                <StatusBadge label={user.role} variant={user.role} size="sm" />
              </div>
              <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                {user.organization || user.email}
              </span>
            </div>
          </div>
        )}

        <button
          onClick={logout}
          aria-label="Logout"
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '0.4rem',
            padding: '0.5rem 0.85rem',
            borderRadius: 'var(--radius-md)',
            border: '1px solid var(--border)',
            fontSize: '0.85rem',
            fontWeight: 500,
            color: 'var(--text-secondary)',
            backgroundColor: '#ffffff',
            transition: 'all var(--transition-fast)',
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.backgroundColor = 'var(--critical-bg)';
            e.currentTarget.style.color = 'var(--critical)';
            e.currentTarget.style.borderColor = 'var(--critical)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.backgroundColor = '#ffffff';
            e.currentTarget.style.color = 'var(--text-secondary)';
            e.currentTarget.style.borderColor = 'var(--border)';
          }}
        >
          <LogOut size={16} />
          <span>Exit</span>
        </button>
      </div>
    </header>
  );
};
