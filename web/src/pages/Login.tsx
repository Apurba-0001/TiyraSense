import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../state/AuthContext';
import { Mail, Lock, Eye, EyeOff, AlertCircle } from 'lucide-react';
import appIcon from '../assets/app_icon.png';

/**
 * High-performance ambient particle canvas rendering randomly moving elements
 * across the blank space behind the brand logo and title.
 */
const ParticleCanvas: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || typeof canvas.getContext !== 'function') return;
    let ctx: CanvasRenderingContext2D | null = null;
    try {
      ctx = canvas.getContext('2d');
    } catch {
      return;
    }
    if (!ctx) return;

    let animationFrameId: number;
    let width = (canvas.width = canvas.parentElement?.clientWidth || 500);
    let height = (canvas.height = canvas.parentElement?.clientHeight || 800);

    const handleResize = () => {
      if (!canvas || !canvas.parentElement) return;
      width = canvas.width = canvas.parentElement.clientWidth;
      height = canvas.height = canvas.parentElement.clientHeight;
    };

    window.addEventListener('resize', handleResize);

    interface ParticleElement {
      x: number;
      y: number;
      vx: number;
      vy: number;
      size: number;
      color: string;
      alpha: number;
      type: 'circle' | 'ring' | 'diamond' | 'pulse';
      pulseSpeed: number;
      pulseAngle: number;
    }

    const colors = ['#0284C7', '#0EA5E9', '#38BDF8', '#7DD3FC', '#6366F1', '#059669'];
    const types: ('circle' | 'ring' | 'diamond' | 'pulse')[] = ['circle', 'ring', 'diamond', 'pulse'];

    // Generate 42 randomly moving elements with distinct velocities, sizes, and types
    const elements: ParticleElement[] = Array.from({ length: 42 }, () => ({
      x: Math.random() * width,
      y: Math.random() * height,
      vx: (Math.random() - 0.5) * 0.9,
      vy: (Math.random() - 0.5) * 0.9,
      size: Math.random() * 6 + 3,
      color: colors[Math.floor(Math.random() * colors.length)],
      alpha: Math.random() * 0.35 + 0.15,
      type: types[Math.floor(Math.random() * types.length)],
      pulseSpeed: Math.random() * 0.03 + 0.015,
      pulseAngle: Math.random() * Math.PI * 2,
    }));

    const render = () => {
      ctx.clearRect(0, 0, width, height);

      // Draw subtle dynamic constellation links between nearby moving elements
      for (let i = 0; i < elements.length; i++) {
        for (let j = i + 1; j < elements.length; j++) {
          const dx = elements[i].x - elements[j].x;
          const dy = elements[i].y - elements[j].y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist < 120) {
            ctx.beginPath();
            ctx.strokeStyle = `rgba(2, 132, 199, ${0.16 * (1 - dist / 120)})`;
            ctx.lineWidth = 0.8;
            ctx.moveTo(elements[i].x, elements[i].y);
            ctx.lineTo(elements[j].x, elements[j].y);
            ctx.stroke();
          }
        }
      }

      // Update positions and draw elements
      elements.forEach((el) => {
        el.x += el.vx;
        el.y += el.vy;
        el.pulseAngle += el.pulseSpeed;

        // Wrap around canvas edges
        if (el.x < -20) el.x = width + 20;
        if (el.x > width + 20) el.x = -20;
        if (el.y < -20) el.y = height + 20;
        if (el.y > height + 20) el.y = -20;

        const currentAlpha = el.alpha + Math.sin(el.pulseAngle) * 0.1;
        ctx.save();
        ctx.globalAlpha = Math.max(0.06, Math.min(0.75, currentAlpha));

        if (el.type === 'circle') {
          ctx.beginPath();
          ctx.arc(el.x, el.y, el.size, 0, Math.PI * 2);
          ctx.fillStyle = el.color;
          ctx.fill();
        } else if (el.type === 'ring') {
          ctx.beginPath();
          ctx.arc(el.x, el.y, el.size * 1.5, 0, Math.PI * 2);
          ctx.strokeStyle = el.color;
          ctx.lineWidth = 1.4;
          ctx.stroke();
        } else if (el.type === 'diamond') {
          ctx.save();
          ctx.translate(el.x, el.y);
          ctx.rotate(el.pulseAngle);
          ctx.beginPath();
          ctx.rect(-el.size / 2, -el.size / 2, el.size, el.size);
          ctx.fillStyle = el.color;
          ctx.fill();
          ctx.restore();
        } else if (el.type === 'pulse') {
          const pulseSize = el.size * (1 + 0.4 * Math.sin(el.pulseAngle));
          ctx.beginPath();
          ctx.arc(el.x, el.y, pulseSize, 0, Math.PI * 2);
          ctx.fillStyle = el.color;
          ctx.shadowColor = el.color;
          ctx.shadowBlur = 10;
          ctx.fill();
        }
        ctx.restore();
      });

      animationFrameId = requestAnimationFrame(render);
    };

    render();

    return () => {
      window.removeEventListener('resize', handleResize);
      cancelAnimationFrame(animationFrameId);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        pointerEvents: 'none',
      }}
    />
  );
};

export const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
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
      await login(email.trim(), password);
      navigate('/dashboard');
    } catch (err: any) {
      setErrors({
        general: err.message || 'Invalid email or password. Please verify credentials.',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div
      className="login-split-container"
      style={{
        minHeight: '100vh',
        width: '100%',
        display: 'flex',
        flexDirection: 'row',
        backgroundColor: 'var(--color-canvas)',
      }}
    >
      {/* LEFT COLUMN: Clean canvas with randomly moving elements and larger Logo + Name */}
      <div
        className="login-brand-column"
        style={{
          flex: '0 0 45%',
          backgroundColor: '#F1F5F9',
          position: 'relative',
          overflow: 'hidden',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          borderRight: '1px solid var(--color-border)',
          padding: '24px',
          boxSizing: 'border-box',
        }}
      >
        {/* Dynamic moving elements animation */}
        <ParticleCanvas />

        {/* Focused Brand Identity: Logo and Name placed side-by-side */}
        <div
          style={{
            position: 'relative',
            zIndex: 10,
            display: 'flex',
            flexDirection: 'row',
            alignItems: 'center',
            gap: '16px',
            userSelect: 'none',
          }}
        >
          <div
            className="login-logo-box"
            style={{
              width: '84px',
              height: '84px',
              borderRadius: '22px',
              backgroundColor: '#FFFFFF',
              boxShadow: '0 16px 36px rgba(2, 132, 199, 0.16), 0 4px 12px rgba(0, 0, 0, 0.06)',
              border: '1px solid rgba(2, 132, 199, 0.16)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              flexShrink: 0,
              transition: 'transform var(--transition-normal)',
            }}
          >
            <img
              className="login-logo-img"
              src={appIcon}
              alt="TiyraSense Emblem"
              style={{
                width: '64px',
                height: '64px',
                objectFit: 'contain',
              }}
            />
          </div>

          <h1
            className="login-brand-title"
            style={{
              fontSize: '44px',
              fontWeight: 800,
              color: 'var(--color-text-primary)',
              lineHeight: 1,
              letterSpacing: '-0.03em',
              margin: 0,
            }}
          >
            TiyraSense
          </h1>
        </div>
      </div>

      {/* RIGHT COLUMN: Dedicated Console Sign In (No Autofill) */}
      <div
        className="login-form-column"
        style={{
          flex: '0 0 55%',
          backgroundColor: '#FFFFFF',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          padding: 'clamp(24px, 5vw, 64px)',
          boxSizing: 'border-box',
        }}
      >
        <div style={{ maxWidth: '420px', margin: '0 auto', width: '100%' }}>
          <h2
            style={{
              fontSize: '22px',
              fontWeight: 800,
              color: 'var(--color-text-primary)',
              lineHeight: 1.3,
              marginBottom: '4px',
            }}
          >
            Operations Console Access
          </h2>
          <p
            style={{
              fontSize: '13px',
              color: 'var(--color-text-muted)',
              marginBottom: '28px',
            }}
          >
            Authorized access for disaster management officials and administrators
          </p>

          {errors.general && (
            <div
              role="alert"
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '12px 14px',
                backgroundColor: 'var(--color-danger-bg)',
                border: '1px solid var(--color-danger)',
                borderRadius: 'var(--radius-sm)',
                color: 'var(--color-danger)',
                fontSize: '13px',
                marginBottom: '20px',
              }}
            >
              <AlertCircle size={16} style={{ flexShrink: 0 }} />
              <span>{errors.general}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} noValidate>
            {/* Email Field (Clean, no preset value) */}
            <div style={{ marginBottom: '16px' }}>
              <label
                htmlFor="official-email"
                style={{
                  display: 'block',
                  fontSize: '12px',
                  fontWeight: 600,
                  color: 'var(--color-text-primary)',
                  marginBottom: '6px',
                }}
              >
                Official / Work Email
              </label>
              <div
                style={{
                  position: 'relative',
                  display: 'flex',
                  alignItems: 'center',
                }}
              >
                <Mail
                  size={16}
                  color="var(--color-text-muted)"
                  style={{ position: 'absolute', left: '12px', pointerEvents: 'none' }}
                />
                <input
                  id="official-email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="name@organization.gov.in"
                  autoComplete="email"
                  style={{
                    width: '100%',
                    height: '44px',
                    paddingLeft: '38px',
                    paddingRight: '12px',
                    borderRadius: 'var(--radius-sm)',
                    border: errors.email ? '1px solid var(--color-danger)' : '1px solid var(--color-border)',
                    backgroundColor: '#FFFFFF',
                    color: 'var(--color-text-primary)',
                    fontSize: '13px',
                    outline: 'none',
                    transition: 'border-color var(--transition-fast)',
                  }}
                  onFocus={(e) => {
                    e.currentTarget.style.borderColor = 'var(--color-primary)';
                  }}
                  onBlur={(e) => {
                    e.currentTarget.style.borderColor = errors.email ? 'var(--color-danger)' : 'var(--color-border)';
                  }}
                />
              </div>
              {errors.email && (
                <span style={{ fontSize: '11px', color: 'var(--color-danger)', marginTop: '4px', display: 'block' }}>
                  {errors.email}
                </span>
              )}
            </div>

            {/* Password Field */}
            <div style={{ marginBottom: '24px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <label
                  htmlFor="official-password"
                  style={{
                    fontSize: '12px',
                    fontWeight: 600,
                    color: 'var(--color-text-primary)',
                  }}
                >
                  Password
                </label>
                <a
                  href="#forgot"
                  onClick={(e) => e.preventDefault()}
                  style={{
                    fontSize: '12px',
                    color: 'var(--color-primary)',
                    fontWeight: 500,
                  }}
                >
                  Forgot password?
                </a>
              </div>
              <div
                style={{
                  position: 'relative',
                  display: 'flex',
                  alignItems: 'center',
                }}
              >
                <Lock
                  size={16}
                  color="var(--color-text-muted)"
                  style={{ position: 'absolute', left: '12px', pointerEvents: 'none' }}
                />
                <input
                  id="official-password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  autoComplete="current-password"
                  style={{
                    width: '100%',
                    height: '44px',
                    paddingLeft: '38px',
                    paddingRight: '38px',
                    borderRadius: 'var(--radius-sm)',
                    border: errors.password ? '1px solid var(--color-danger)' : '1px solid var(--color-border)',
                    backgroundColor: '#FFFFFF',
                    color: 'var(--color-text-primary)',
                    fontSize: '13px',
                    outline: 'none',
                    transition: 'border-color var(--transition-fast)',
                  }}
                  onFocus={(e) => {
                    e.currentTarget.style.borderColor = 'var(--color-primary)';
                  }}
                  onBlur={(e) => {
                    e.currentTarget.style.borderColor = errors.password ? 'var(--color-danger)' : 'var(--color-border)';
                  }}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  style={{
                    position: 'absolute',
                    right: '12px',
                    color: 'var(--color-text-muted)',
                    display: 'flex',
                    alignItems: 'center',
                  }}
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
              {errors.password && (
                <span style={{ fontSize: '11px', color: 'var(--color-danger)', marginTop: '4px', display: 'block' }}>
                  {errors.password}
                </span>
              )}
            </div>

            {/* Submit button */}
            <button
              type="submit"
              disabled={isSubmitting}
              style={{
                width: '100%',
                height: '44px',
                borderRadius: 'var(--radius-sm)',
                backgroundColor: 'var(--color-primary)',
                color: '#FFFFFF',
                fontSize: '13px',
                fontWeight: 700,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: isSubmitting ? 'not-allowed' : 'pointer',
                opacity: isSubmitting ? 0.7 : 1,
                transition: 'background-color var(--transition-fast)',
              }}
              onMouseEnter={(e) => {
                if (!isSubmitting) e.currentTarget.style.backgroundColor = 'var(--color-primary-hover)';
              }}
              onMouseLeave={(e) => {
                if (!isSubmitting) e.currentTarget.style.backgroundColor = 'var(--color-primary)';
              }}
            >
              {isSubmitting ? 'Authenticating...' : 'Sign In to Console'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

