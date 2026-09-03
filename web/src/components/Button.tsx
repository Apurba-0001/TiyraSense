import React from 'react';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
  leftIcon?: React.ReactNode;
}

export const Button: React.FC<ButtonProps> = ({
  children,
  variant = 'primary',
  size = 'md',
  isLoading = false,
  leftIcon,
  disabled,
  className = '',
  style,
  ...props
}) => {
  const getStyles = (): React.CSSProperties => {
    const base: React.CSSProperties = {
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: '0.5rem',
      fontWeight: 500,
      borderRadius: 'var(--radius-md)',
      transition: 'all var(--transition-fast)',
      cursor: disabled || isLoading ? 'not-allowed' : 'pointer',
      opacity: disabled || isLoading ? 0.65 : 1,
      outline: 'none',
      userSelect: 'none',
    };

    // Size variants
    if (size === 'sm') {
      Object.assign(base, { padding: '0.4rem 0.75rem', fontSize: '0.85rem' });
    } else if (size === 'lg') {
      Object.assign(base, { padding: '0.75rem 1.5rem', fontSize: '1.05rem' });
    } else {
      Object.assign(base, { padding: '0.6rem 1.15rem', fontSize: '0.95rem' });
    }

    // Color variants
    if (variant === 'primary') {
      Object.assign(base, {
        backgroundColor: 'var(--primary)',
        color: '#ffffff',
        boxShadow: 'var(--shadow-sm)',
      });
    } else if (variant === 'secondary') {
      Object.assign(base, {
        backgroundColor: '#e2e8f0',
        color: 'var(--text-primary)',
      });
    } else if (variant === 'outline') {
      Object.assign(base, {
        backgroundColor: 'transparent',
        border: '1px solid var(--border)',
        color: 'var(--text-primary)',
      });
    } else if (variant === 'ghost') {
      Object.assign(base, {
        backgroundColor: 'transparent',
        color: 'var(--text-secondary)',
      });
    } else if (variant === 'danger') {
      Object.assign(base, {
        backgroundColor: 'var(--critical)',
        color: '#ffffff',
      });
    }

    return { ...base, ...style };
  };

  return (
    <button
      style={getStyles()}
      disabled={disabled || isLoading}
      className={`tiyra-btn ${className}`}
      {...props}
    >
      {isLoading ? (
        <span
          style={{
            display: 'inline-block',
            width: '1rem',
            height: '1rem',
            border: '2px solid rgba(255,255,255,0.3)',
            borderTopColor: '#ffffff',
            borderRadius: '50%',
            animation: 'spin 0.6s linear infinite',
          }}
        />
      ) : (
        leftIcon
      )}
      {children}
    </button>
  );
};
