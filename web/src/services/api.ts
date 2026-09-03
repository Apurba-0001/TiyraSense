import { TokenResponse, User } from '../types/auth';

const API_BASE = 'http://localhost:8000/api/v1';

export class ApiErrorResponse extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
    this.name = 'ApiErrorResponse';
  }
}

function getHeaders(includeAuth = true): HeadersInit {
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
  };
  if (includeAuth) {
    const token = localStorage.getItem('tiyrasense_token');
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
  }
  return headers;
}

export async function loginUser(email: string, password: string): Promise<TokenResponse> {
  const res = await fetch(`${API_BASE}/auth/login`, {
    method: 'POST',
    headers: getHeaders(false),
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    let errorDetail = 'Authentication failed. Please check your credentials.';
    try {
      const err = await res.json();
      if (err.detail) errorDetail = err.detail;
    } catch {
      // Fallback to generic message
    }
    throw new ApiErrorResponse(errorDetail, res.status);
  }

  return res.json();
}

export async function fetchCurrentUser(): Promise<User> {
  const res = await fetch(`${API_BASE}/auth/me`, {
    headers: getHeaders(true),
  });

  if (!res.ok) {
    throw new ApiErrorResponse('Session expired or invalid token', res.status);
  }

  return res.json();
}

export async function fetchHealthStatus(): Promise<{
  status: string;
  database: string;
  postgis_version: string;
  data_label: string;
}> {
  const res = await fetch(`${API_BASE}/health`, {
    headers: getHeaders(false),
  });

  if (!res.ok) {
    throw new ApiErrorResponse('Healthcheck failed', res.status);
  }

  return res.json();
}
