import React from 'react';
import { NavLink } from 'react-router-dom';
import { useAuth } from '../state/AuthContext';
import {
  LayoutDashboard,
  MapPin,
  AlertTriangle,
  Users,
  Sliders,
  Database,
  Activity,
} from 'lucide-react';

export const Sidebar: React.FC = () => {
  const { user } = useAuth();
  const isAdmin = user?.role === 'ADMIN';

  const officialLinks = [
    { to: '/dashboard', label: 'Operations Overview', icon: <LayoutDashboard size={18} /> },
    { to: '/dashboard#corridors', label: 'NER Corridors & GIS', icon: <MapPin size={18} /> },
    { to: '/dashboard#incidents', label: 'Incident Status', icon: <AlertTriangle size={18} /> },
    { to: '/dashboard#telemetry', label: 'System Health', icon: <Activity size={18} /> },
  ];

  const adminLinks = [
    { to: '/admin', label: 'System Overview', icon: <LayoutDashboard size={18} /> },
    { to: '/admin#users', label: 'Users & Roles', icon: <Users size={18} /> },
    { to: '/admin#config', label: 'Platform Settings', icon: <Sliders size={18} /> },
    { to: '/admin#database', label: 'PostGIS System Health', icon: <Database size={18} /> },
  ];

  const links = isAdmin ? adminLinks : officialLinks;

  return (
    <aside
      style={{
        width: '240px',
        backgroundColor: 'var(--surface)',
        borderRight: '1px solid var(--border)',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        padding: '1.25rem 0.75rem',
      }}
    >
      <div>
        <div style={{ padding: '0 0.75rem 1rem', fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
          {isAdmin ? 'Administration' : 'Disaster Management'}
        </div>

        <nav style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
          {links.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              style={({ isActive }) => ({
                display: 'flex',
                alignItems: 'center',
                gap: '0.75rem',
                padding: '0.65rem 0.85rem',
                borderRadius: 'var(--radius-md)',
                fontSize: '0.9rem',
                fontWeight: isActive ? 600 : 500,
                color: isActive ? 'var(--primary)' : 'var(--text-secondary)',
                backgroundColor: isActive ? 'var(--primary-light)' : 'transparent',
                transition: 'all var(--transition-fast)',
              })}
            >
              {link.icon}
              <span>{link.label}</span>
            </NavLink>
          ))}
        </nav>
      </div>

      <div
        style={{
          padding: '0.75rem',
          backgroundColor: 'var(--border-subtle)',
          borderRadius: 'var(--radius-md)',
          fontSize: '0.75rem',
          color: 'var(--text-muted)',
          display: 'flex',
          flexDirection: 'column',
          gap: '0.25rem',
        }}
      >
        <span style={{ fontWeight: 600, color: 'var(--text-secondary)' }}>Region 1: NER Domain</span>
        <span>Coverage: 8 NE States</span>
        <span style={{ color: 'var(--success)', fontWeight: 500 }}>● Engine: Active</span>
      </div>
    </aside>
  );
};
