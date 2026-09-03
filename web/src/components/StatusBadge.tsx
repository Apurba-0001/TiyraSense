import React from 'react';

export type BadgeVariant =
  | 'LIVE'
  | 'SIMULATED'
  | 'HISTORICAL'
  | 'DRIVER'
  | 'FIELD_WORKER'
  | 'OFFICIAL'
  | 'ADMIN'
  | 'healthy'
  | 'warning'
  | 'critical';

interface StatusBadgeProps {
  label: string;
  variant?: BadgeVariant | string;
  size?: 'sm' | 'md';
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({
  label,
  variant = 'info',
  size = 'md',
}) => {
  const isPulsing = variant === 'LIVE' || variant === 'healthy' || variant === 'critical';

  const getBadgeColors = () => {
    switch (variant) {
      case 'LIVE':
      case 'healthy':
        return {
          bg: 'var(--success-bg)',
          color: 'var(--success)',
          border: 'var(--success-border)',
          dot: 'var(--success)',
        };
      case 'warning':
      case 'FIELD_WORKER':
        return {
          bg: 'var(--warning-bg)',
          color: 'var(--warning)',
          border: 'var(--warning-border)',
          dot: 'var(--warning)',
        };
      case 'critical':
        return {
          bg: 'var(--critical-bg)',
          color: 'var(--critical)',
          border: 'var(--critical-border)',
          dot: 'var(--critical)',
        };
      case 'OFFICIAL':
      case 'ADMIN':
        return {
          bg: '#ede9fe',
          color: '#6d28d9',
          border: '#ddd6fe',
          dot: '#7c3aed',
        };
      case 'DRIVER':
        return {
          bg: 'var(--primary-light)',
          color: 'var(--primary)',
          border: '#bae6fd',
          dot: 'var(--primary)',
        };
      case 'SIMULATED':
        return {
          bg: '#f1f5f9',
          color: '#64748b',
          border: '#e2e8f0',
          dot: '#94a3b8',
        };
      default:
        return {
          bg: 'var(--info-bg)',
          color: 'var(--info)',
          border: 'var(--info-border)',
          dot: 'var(--info)',
        };
    }
  };

  const colors = getBadgeColors();

  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: '0.4rem',
        fontWeight: 600,
        textTransform: 'uppercase',
        letterSpacing: '0.05em',
        borderRadius: 'var(--radius-full)',
        fontSize: size === 'sm' ? '0.68rem' : '0.74rem',
        padding: size === 'sm' ? '0.2rem 0.55rem' : '0.3rem 0.75rem',
        backgroundColor: colors.bg,
        color: colors.color,
        border: `1px solid ${colors.border}`,
        boxShadow: isPulsing ? '0 1px 2px rgba(0,0,0,0.03)' : 'none',
      }}
    >
      <span
        style={{
          width: size === 'sm' ? '5px' : '6px',
          height: size === 'sm' ? '5px' : '6px',
          borderRadius: '50%',
          backgroundColor: colors.dot,
          display: 'inline-block',
        }}
        className={isPulsing ? 'pulse-beacon' : ''}
      />
      {label}
    </span>
  );
};
