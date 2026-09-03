import React, { useState, useEffect } from 'react';
import { StatusBadge } from '../components/StatusBadge';
import { fetchHealthStatus } from '../services/api';
import { Users, Shield, Database, Lock, Server, CheckCircle2 } from 'lucide-react';

export const Admin: React.FC = () => {
  const [health, setHealth] = useState<{
    status: string;
    database: string;
    postgis_version: string;
    environment: string;
  } | null>(null);

  useEffect(() => {
    async function load() {
      try {
        const res = await fetchHealthStatus();
        setHealth({ ...res, environment: 'development' });
      } catch {
        setHealth({ status: 'offline', database: 'disconnected', postgis_version: 'unknown', environment: 'dev' });
      }
    }
    load();
  }, []);

  const rolesList = [
    { role: 'DRIVER', desc: 'Commercial drivers running mobile navigation and live alerts', count: 1, color: 'var(--primary)' },
    { role: 'FIELD_WORKER', desc: 'Disaster management field inspectors with offline reporting', count: 1, color: 'var(--warning)' },
    { role: 'OFFICIAL', desc: 'State disaster authority (ASDMA) operations dispatchers', count: 1, color: '#7c3aed' },
    { role: 'ADMIN', desc: 'System governance, database administrators, and security ops', count: 1, color: '#0f172a' },
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
      {/* Admin Header */}
      <div
        className="glass-panel"
        style={{
          padding: '1.5rem 2rem',
          borderRadius: 'var(--radius-xl)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '1rem',
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
            <Server size={14} color="var(--primary)" />
            <span style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--primary)', letterSpacing: '0.06em', textTransform: 'uppercase' }}>
              North Eastern Council (NEC) Systems Governance
            </span>
          </div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800, letterSpacing: '-0.025em' }}>
            Security & RBAC Enforcement Matrix
          </h1>
          <p style={{ fontSize: '0.88rem', color: 'var(--text-secondary)', marginTop: '0.2rem' }}>
            Multi-tenant role boundaries, PostGIS database telemetry, and cryptographic JWT configuration.
          </p>
        </div>

        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <StatusBadge label="GOVERNANCE ACTIVE" variant="healthy" />
          <StatusBadge label="ISO 27001 ALIGNED" variant="info" />
        </div>
      </div>

      {/* System Status Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '1.25rem' }}>
        <div className="glass-panel" style={{ padding: '1.5rem', borderRadius: 'var(--radius-lg)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.82rem', fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase' }}>Database Engine</span>
            <Database size={20} color="var(--primary)" />
          </div>
          <div style={{ fontSize: '1.5rem', fontWeight: 800, marginTop: '0.75rem' }}>PostgreSQL 16</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.78rem', color: 'var(--success)', fontWeight: 600, marginTop: '0.35rem' }}>
            <CheckCircle2 size={14} />
            <span>Extension: {health?.postgis_version || 'PostGIS 3.4'}</span>
          </div>
        </div>

        <div className="glass-panel" style={{ padding: '1.5rem', borderRadius: 'var(--radius-lg)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.82rem', fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase' }}>Authentication</span>
            <Shield size={20} color="var(--success)" />
          </div>
          <div style={{ fontSize: '1.5rem', fontWeight: 800, marginTop: '0.75rem' }}>JWT (HS256)</div>
          <div style={{ fontSize: '0.78rem', color: 'var(--text-secondary)', marginTop: '0.35rem' }}>
            Direct Bcrypt Hashing • 72-byte safe
          </div>
        </div>

        <div className="glass-panel" style={{ padding: '1.5rem', borderRadius: 'var(--radius-lg)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.82rem', fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase' }}>Data Provenance</span>
            <Lock size={20} color="#7c3aed" />
          </div>
          <div style={{ fontSize: '1.5rem', fontWeight: 800, marginTop: '0.75rem' }}>Strict Boundary</div>
          <div style={{ fontSize: '0.78rem', color: 'var(--text-secondary)', marginTop: '0.35rem' }}>
            X-TiyraSense-Data-Label: LIVE enforced
          </div>
        </div>
      </div>

      {/* Role Management Matrix */}
      <div className="glass-panel" style={{ borderRadius: 'var(--radius-xl)', padding: '1.75rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem' }}>
          <div>
            <h3 style={{ fontSize: '1.1rem', fontWeight: 700, letterSpacing: '-0.01em' }}>
              Role-Based Access Control (RBAC) Hierarchy
            </h3>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              Strict client/server authorization enforced at API gateway level.
            </p>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
            <Users size={16} />
            <span>4 Configured Personas</span>
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          {rolesList.map((r) => (
            <div
              key={r.role}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: '1rem 1.25rem',
                borderRadius: 'var(--radius-md)',
                border: '1px solid var(--border)',
                backgroundColor: 'var(--surface)',
                transition: 'border-color var(--transition-snappy)',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <StatusBadge label={r.role} variant={r.role} />
                <span style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>{r.desc}</span>
              </div>
              <span style={{ fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-primary)' }}>
                {r.count} Active User
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
