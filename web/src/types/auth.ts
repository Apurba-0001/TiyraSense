export type UserRole = 'DRIVER' | 'FIELD_WORKER' | 'OFFICIAL' | 'ADMIN';

export interface User {
  id: string;
  email: string;
  full_name: string;
  role: UserRole;
  phone_number?: string | null;
  organization?: string | null;
}

export interface TokenResponse {
  access_token: string;
  token_type: string;
  expires_in_seconds: number;
  user: User;
}

export interface ApiError {
  detail: string;
}
