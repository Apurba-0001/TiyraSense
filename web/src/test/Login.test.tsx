import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { BrowserRouter } from 'react-router-dom';
import { AuthProvider } from '../state/AuthContext';
import { Login } from '../pages/Login';
import * as api from '../services/api';

vi.mock('../services/api');

describe('Web Login & Authentication Suite', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
  });

  it('renders login screen with TiyraSense identity and accessible inputs', () => {
    render(
      <AuthProvider>
        <BrowserRouter>
          <Login />
        </BrowserRouter>
      </AuthProvider>
    );

    expect(screen.getByText('TiyraSense')).toBeInTheDocument();
    expect(screen.getByLabelText(/Official \/ Work Email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/^Password$/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Sign In to Console/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Official \(ASDMA\)/i })).toBeInTheDocument();
  });

  it('shows client-side validation errors for empty inputs', async () => {
    render(
      <AuthProvider>
        <BrowserRouter>
          <Login />
        </BrowserRouter>
      </AuthProvider>
    );

    const submitBtn = screen.getByRole('button', { name: /Sign In to Console/i });
    fireEvent.click(submitBtn);

    await waitFor(() => {
      expect(screen.getByText(/Email address is required/i)).toBeInTheDocument();
      expect(screen.getByText(/Password is required/i)).toBeInTheDocument();
    });
  });

  it('autofills official credentials when quick-fill button is clicked', () => {
    render(
      <AuthProvider>
        <BrowserRouter>
          <Login />
        </BrowserRouter>
      </AuthProvider>
    );

    const quickFillBtn = screen.getByRole('button', { name: /Official \(ASDMA\)/i });
    fireEvent.click(quickFillBtn);

    const emailInput = screen.getByLabelText(/Official \/ Work Email/i) as HTMLInputElement;
    expect(emailInput.value).toBe('official@tiyrasense.in');
  });

  it('handles successful login and stores JWT token in localStorage', async () => {
    const mockResponse = {
      access_token: 'fake-jwt-token-official',
      token_type: 'bearer',
      expires_in_seconds: 3600,
      user: {
        id: '11111111-1111-1111-1111-111111111111',
        email: 'official@tiyrasense.in',
        full_name: 'Dr. Anamika Barua',
        role: 'OFFICIAL' as const,
      },
    };

    vi.spyOn(api, 'loginUser').mockResolvedValue(mockResponse);

    render(
      <AuthProvider>
        <BrowserRouter>
          <Login />
        </BrowserRouter>
      </AuthProvider>
    );

    fireEvent.change(screen.getByLabelText(/Official \/ Work Email/i), {
      target: { value: 'official@tiyrasense.in' },
    });
    fireEvent.change(screen.getByLabelText(/^Password$/i), {
      target: { value: 'OfficialPass2026!' },
    });

    fireEvent.click(screen.getByRole('button', { name: /Sign In to Console/i }));

    await waitFor(() => {
      expect(api.loginUser).toHaveBeenCalledWith('official@tiyrasense.in', 'OfficialPass2026!');
      expect(localStorage.getItem('tiyrasense_token')).toBe('fake-jwt-token-official');
    });
  });

  it('displays error banner when backend returns authentication error', async () => {
    vi.spyOn(api, 'loginUser').mockRejectedValue(
      new api.ApiErrorResponse('Invalid email or password', 401)
    );

    render(
      <AuthProvider>
        <BrowserRouter>
          <Login />
        </BrowserRouter>
      </AuthProvider>
    );

    fireEvent.change(screen.getByLabelText(/Official \/ Work Email/i), {
      target: { value: 'official@tiyrasense.in' },
    });
    fireEvent.change(screen.getByLabelText(/^Password$/i), {
      target: { value: 'WrongPassword!' },
    });

    fireEvent.click(screen.getByRole('button', { name: /Sign In to Console/i }));

    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent(/Invalid email or password/i);
    });
  });
});
