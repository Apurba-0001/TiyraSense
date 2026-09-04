import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../state/AuthContext';
import { Input } from '../components/Input';
import { Button } from '../components/Button';
import { StatusBadge } from '../components/StatusBadge';
import { ShieldCheck, AlertCircle, Compass, Truck, Users, Activity, Lock } from 'lucide-react';
import logo from '../assets/logo.png';

export const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errors, setErrors] = useState<{ email?: string; password?: string; general?: string }>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const { login } = useAuth();
  const navigate = useNavigate();

  const validate = (): boolean => {
    const errs: { email?: string; password?: string } = {};
    if (!email.trim()) {
      errs.email = 'Email address is required';
    } else if (!/\S+@\S+\.\S+/.test(email)) {
      errs.email = 'Please enter a valid email address';
    }

    if (!password) {
      errs.password = 'Password is required';
    } else if (password.length < 6) {
      errs.password = 'Password must be at least 6 characters';
    }

    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    setIsSubmitting(true);
    setErrors({});

    try {
      const res = await login(email.trim(), password);
      if (res.user.role === 'ADMIN') {
        navigate('/admin');
      } else if (res.user.role === 'OFFICIAL') {
        navigate('/dashboard');
      } else {
        navigate('/dashboard');
      }
    } catch (err: any) {
      setErrors({
        general: err.message || 'Invalid email or password. Please verify credentials.',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleQuickFill = (testEmail: string, testPass: string) => {
    setEmail(testEmail);
    setPassword(testPass);
    setErrors({});
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '2rem 1.5rem',
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      {/* Tactical Topographic Ambient Grid */}
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundImage:
            'radial-gradient(circle at 50% 20%, rgba(2, 132, 199, 0.08) 0%, transparent 60%), linear-gradient(rgba(226, 232, 240, 0.4) 1px, transparent 1px), linear-gradient(90deg, rgba(226, 232, 240, 0.4) 1px, transparent 1px)',
          backgroundSize: '100% 100%, 32px 32px, 32px 32px',
          opacity: 0.7,
          pointerEvents: 'none',
        }}
      />

      {/* Main Glassmorphic Authentication Card */}
      <div
        className="glass-panel"
        style={{
          width: '100%',
          maxWidth: '460px',
          borderRadius: 'var(--radius-xl)',
          padding: '2.5rem',
          boxShadow: 'var(--shadow-lg)',
          position: 'relative',
          zIndex: 1,
        }}
      >
        {/* Top Header Branding */}
        <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
          <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '1.25rem' }}>
            <img src={logo} alt="TiyraSense" style={{ height: '44px', width: 'auto', objectFit: 'contain' }} />
          </div>

          <div
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '0.5rem',
              backgroundColor: 'var(--primary-light)',
              border: '1px solid #bae6fd',
              borderRadius: 'var(--radius-full)',
              padding: '0.35rem 0.85rem',
              marginBottom: '1rem',
            }}
          >
            <Compass size={14} color="var(--primary)" />
            <span
              style={{
                fontSize: '0.72rem',
                fontWeight: 700,
                color: 'var(--primary)',
                letterSpacing: '0.06em',
                textTransform: 'uppercase',
              }}
            >
              NER Transport Intelligence
            </span>
          </div>

          <h1
            style={{
              fontSize: '2rem',
              fontWeight: 800,
              letterSpacing: '-0.03em',
              color: 'var(--text-primary)',
              lineHeight: 1.15,
            }}
          >
            TiyraSense
          </h1>
          <p
            style={{
              fontSize: '0.88rem',
              color: 'var(--text-secondary)',
              marginTop: '0.35rem',
            }}
          >
            Risk-Aware Logistics & Accessibility Decision Platform
          </p>
        </div>

        {/* Error Alert Banner */}
        {errors.general && (
          <div
            role="alert"
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.75rem',
              padding: '0.85rem 1rem',
              borderRadius: 'var(--radius-md)',
              backgroundColor: 'var(--critical-bg)',
              border: '1px solid var(--critical-border)',
              color: 'var(--critical)',
              fontSize: '0.85rem',
              fontWeight: 500,
              marginBottom: '1.5rem',
            }}
          >
            <AlertCircle size={18} style={{ flexShrink: 0 }} />
            <span>{errors.general}</span>
          </div>
        )}

        {/* Credentials Form */}
        <form onSubmit={handleSubmit} noValidate style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <Input
            id="email"
            label="Official / Work Email"
            type="email"
            placeholder="officer@asdma.gov.in"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            error={errors.email}
            required
            autoComplete="username"
          />

          <Input
            id="password"
            label="Password"
            type="password"
            placeholder="••••••••••••"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            error={errors.password}
            required
            autoComplete="current-password"
          />

          <Button
            type="submit"
            variant="primary"
            size="lg"
            isLoading={isSubmitting}
            style={{
              width: '100%',
              marginTop: '0.5rem',
              boxShadow: 'var(--shadow-glow)',
              fontWeight: 700,
            }}
          >
            <Lock size={16} style={{ marginRight: '0.5rem' }} />
            Sign In to Console
          </Button>
        </form>

        {/* Quick-Fill Demonstration Panel */}
        <div
          style={{
            marginTop: '2rem',
            paddingTop: '1.5rem',
            borderTop: '1px solid var(--border-subtle)',
          }}
        >
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              marginBottom: '0.85rem',
            }}
          >
            <span
              style={{
                fontSize: '0.75rem',
                fontWeight: 700,
                color: 'var(--text-muted)',
                textTransform: 'uppercase',
                letterSpacing: '0.05em',
              }}
            >
              Demo Profile Presets
            </span>
            <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>1-Click Autofill</span>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.5rem' }}>
            <button
              type="button"
              onClick={() => handleQuickFill('official@tiyrasense.in', 'OfficialPass2026!')}
              style={{
                padding: '0.65rem 0.75rem',
                borderRadius: 'var(--radius-md)',
                border: '1px solid var(--border)',
                backgroundColor: 'var(--surface)',
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                textAlign: 'left',
                fontSize: '0.78rem',
                fontWeight: 600,
                color: 'var(--text-primary)',
                transition: 'all var(--transition-snappy)',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.borderColor = 'var(--primary)')}
              onMouseLeave={(e) => (e.currentTarget.style.borderColor = 'var(--border)')}
            >
              <Activity size={14} color="var(--primary)" />
              <div>
                <div>Official (ASDMA)</div>
                <div style={{ fontSize: '0.65rem', color: 'var(--text-muted)', fontWeight: 400 }}>
                  Dashboard Console
                </div>
              </div>
            </button>

            <button
              type="button"
              onClick={() => handleQuickFill('admin@tiyrasense.in', 'AdminPass2026!')}
              style={{
                padding: '0.65rem 0.75rem',
                borderRadius: 'var(--radius-md)',
                border: '1px solid var(--border)',
                backgroundColor: 'var(--surface)',
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                textAlign: 'left',
                fontSize: '0.78rem',
                fontWeight: 600,
                color: 'var(--text-primary)',
                transition: 'all var(--transition-snappy)',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.borderColor = '#7c3aed')}
              onMouseLeave={(e) => (e.currentTarget.style.borderColor = 'var(--border)')}
            >
              <ShieldCheck size={14} color="#7c3aed" />
              <div>
                <div>Admin (NEC)</div>
                <div style={{ fontSize: '0.65rem', color: 'var(--text-muted)', fontWeight: 400 }}>
                  Governance Matrix
                </div>
              </div>
            </button>

            <button
              type="button"
              onClick={() => handleQuickFill('driver@tiyrasense.in', 'DriverPass2026!')}
              style={{
                padding: '0.65rem 0.75rem',
                borderRadius: 'var(--radius-md)',
                border: '1px solid var(--border)',
                backgroundColor: 'var(--surface)',
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                textAlign: 'left',
                fontSize: '0.78rem',
                fontWeight: 600,
                color: 'var(--text-primary)',
                transition: 'all var(--transition-snappy)',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.borderColor = 'var(--info)')}
              onMouseLeave={(e) => (e.currentTarget.style.borderColor = 'var(--border)')}
            >
              <Truck size={14} color="var(--info)" />
              <div>
                <div>Driver (Mobile)</div>
                <div style={{ fontSize: '0.65rem', color: 'var(--text-muted)', fontWeight: 400 }}>
                  Mobile Guidance
                </div>
              </div>
            </button>

            <button
              type="button"
              onClick={() => handleQuickFill('worker@tiyrasense.in', 'WorkerPass2026!')}
              style={{
                padding: '0.65rem 0.75rem',
                borderRadius: 'var(--radius-md)',
                border: '1px solid var(--border)',
                backgroundColor: 'var(--surface)',
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                textAlign: 'left',
                fontSize: '0.78rem',
                fontWeight: 600,
                color: 'var(--text-primary)',
                transition: 'all var(--transition-snappy)',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.borderColor = 'var(--warning)')}
              onMouseLeave={(e) => (e.currentTarget.style.borderColor = 'var(--border)')}
            >
              <Users size={14} color="var(--warning)" />
              <div>
                <div>Field Worker</div>
                <div style={{ fontSize: '0.65rem', color: 'var(--text-muted)', fontWeight: 400 }}>
                  Reporting Console
                </div>
              </div>
            </button>
          </div>
        </div>

        {/* Provenance Footer */}
        <div
          style={{
            marginTop: '1.5rem',
            textAlign: 'center',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '0.5rem',
          }}
        >
          <StatusBadge label="LIVE POSTGIS ACTIVE" variant="LIVE" size="sm" />
          <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>
            SIH 2026 PS-26002
          </span>
        </div>
      </div>
    </div>
  );
};
