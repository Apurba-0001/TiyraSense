import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../state/AuthContext';
import { UserRole } from '../types/auth';
import { Smartphone, ShieldAlert } from 'lucide-react';
import { Button } from '../components/Button';

interface RoleGuardProps {
  children: React.ReactNode;
  allowedRoles?: UserRole[];
}

export const RoleGuard: React.FC<RoleGuardProps> = ({ children, allowedRoles }) => {
  const { user, isLoading, logout } = useAuth();

  if (isLoading) {
    return (
      <div
        style={{
          minHeight: '100vh',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: '1rem',
          backgroundColor: 'var(--bg)',
        }}
      >
        <div
          style={{
            width: '2.5rem',
            height: '2.5rem',
            border: '3px solid var(--border)',
            borderTopColor: 'var(--primary)',
            borderRadius: '50%',
            animation: 'spin 0.8s linear infinite',
          }}
        />
        <span style={{ fontSize: '0.9rem', color: 'var(--text-secondary)' }}>
          Verifying security credentials...
        </span>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  // Driver or Field Worker accessing web dashboard
  if (user.role === 'DRIVER' || user.role === 'FIELD_WORKER') {
    return (
      <div
        style={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: 'var(--bg)',
          padding: '1.5rem',
        }}
      >
        <div
          style={{
            maxWidth: '480px',
            backgroundColor: 'var(--surface)',
            borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--border)',
            padding: '2.5rem',
            textAlign: 'center',
            boxShadow: 'var(--shadow-md)',
          }}
        >
          <div
            style={{
              width: '56px',
              height: '56px',
              borderRadius: 'var(--radius-full)',
              backgroundColor: 'var(--primary-light)',
              color: 'var(--primary)',
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: '1.25rem',
            }}
          >
            <Smartphone size={28} />
          </div>

          <h2 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '0.75rem' }}>
            Mobile Application Required
          </h2>

          <p
            style={{
              fontSize: '0.925rem',
              color: 'var(--text-secondary)',
              lineHeight: 1.6,
              marginBottom: '1.5rem',
            }}
          >
            You are signed in as <strong>{user.full_name}</strong> ({user.role}). Field reporting, offline sync, and real-time corridor navigation are delivered through the <strong>TiyraSense Mobile App</strong>.
          </p>

          <div
            style={{
              padding: '0.75rem 1rem',
              backgroundColor: 'var(--border-subtle)',
              borderRadius: 'var(--radius-md)',
              fontSize: '0.85rem',
              color: 'var(--text-muted)',
              marginBottom: '1.5rem',
            }}
          >
            Web dashboard access is reserved for ASDMA/NE Disaster Management Officials and Administrators.
          </div>

          <Button variant="outline" onClick={logout} style={{ width: '100%' }}>
            Sign Out
          </Button>
        </div>
      </div>
    );
  }

  // Role restriction (e.g. Official trying to enter Admin page)
  if (allowedRoles && !allowedRoles.includes(user.role)) {
    return (
      <div
        style={{
          minHeight: '80vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '2rem',
        }}
      >
        <div
          style={{
            maxWidth: '460px',
            backgroundColor: 'var(--surface)',
            borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--critical)',
            padding: '2rem',
            textAlign: 'center',
          }}
        >
          <div
            style={{
              width: '52px',
              height: '52px',
              borderRadius: 'var(--radius-full)',
              backgroundColor: 'var(--critical-bg)',
              color: 'var(--critical)',
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              marginBottom: '1rem',
            }}
          >
            <ShieldAlert size={26} />
          </div>

          <h2 style={{ fontSize: '1.2rem', fontWeight: 700, marginBottom: '0.5rem' }}>
            Access Restricted (403 Forbidden)
          </h2>

          <p style={{ fontSize: '0.9rem', color: 'var(--text-secondary)', marginBottom: '1.5rem' }}>
            Your account role (<strong>{user.role}</strong>) does not have administrative privileges to access this console.
          </p>

          <Button variant="primary" onClick={() => window.location.href = '/dashboard'}>
            Return to Operations Dashboard
          </Button>
        </div>
      </div>
    );
  }

  return <>{children}</>;
};
