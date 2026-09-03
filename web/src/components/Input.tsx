import React, { useState } from 'react';
import { Eye, EyeOff } from 'lucide-react';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label: string;
  error?: string;
  hint?: string;
  showPasswordToggle?: boolean;
}

export const Input: React.FC<InputProps> = ({
  label,
  error,
  hint,
  type = 'text',
  id,
  showPasswordToggle = false,
  className = '',
  style,
  ...props
}) => {
  const [showPassword, setShowPassword] = useState(false);
  const inputId = id || `input-${label.toLowerCase().replace(/\s+/g, '-')}`;
  const effectiveType = showPasswordToggle ? (showPassword ? 'text' : 'password') : type;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem', width: '100%' }}>
      <label
        htmlFor={inputId}
        style={{
          fontSize: '0.875rem',
          fontWeight: 500,
          color: error ? 'var(--critical)' : 'var(--text-primary)',
        }}
      >
        {label}
      </label>

      <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
        <input
          id={inputId}
          type={effectiveType}
          aria-invalid={Boolean(error)}
          aria-describedby={error ? `${inputId}-error` : hint ? `${inputId}-hint` : undefined}
          style={{
            width: '100%',
            padding: '0.65rem 0.85rem',
            paddingRight: showPasswordToggle ? '2.5rem' : '0.85rem',
            borderRadius: 'var(--radius-md)',
            border: `1px solid ${error ? 'var(--critical)' : 'var(--border)'}`,
            backgroundColor: '#ffffff',
            color: 'var(--text-primary)',
            fontSize: '0.95rem',
            outline: 'none',
            transition: 'border-color var(--transition-fast), box-shadow var(--transition-fast)',
            ...style,
          }}
          onFocus={(e) => {
            e.currentTarget.style.borderColor = error ? 'var(--critical)' : 'var(--primary)';
            e.currentTarget.style.boxShadow = `0 0 0 3px ${
              error ? 'rgba(220, 38, 38, 0.15)' : 'var(--primary-ring)'
            }`;
          }}
          onBlur={(e) => {
            e.currentTarget.style.borderColor = error ? 'var(--critical)' : 'var(--border)';
            e.currentTarget.style.boxShadow = 'none';
          }}
          {...props}
        />

        {showPasswordToggle && (
          <button
            type="button"
            onClick={() => setShowPassword(!showPassword)}
            aria-label={showPassword ? 'Hide password' : 'Show password'}
            style={{
              position: 'absolute',
              right: '0.75rem',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'var(--text-muted)',
              padding: '0.25rem',
              borderRadius: 'var(--radius-sm)',
            }}
          >
            {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
          </button>
        )}
      </div>

      {error ? (
        <span
          id={`${inputId}-error`}
          role="alert"
          style={{ fontSize: '0.8rem', color: 'var(--critical)', fontWeight: 500 }}
        >
          {error}
        </span>
      ) : hint ? (
        <span id={`${inputId}-hint`} style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
          {hint}
        </span>
      ) : null}
    </div>
  );
};
