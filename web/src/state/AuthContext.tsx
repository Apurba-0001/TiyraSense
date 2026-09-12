import React, { createContext, useContext, useState, useEffect } from 'react';
import { User, TokenResponse } from '../types/auth';
import { loginUser, fetchCurrentUser, updateCurrentUserProfile } from '../services/api';

export interface UserUpdatePayload extends Partial<User> {
  current_password?: string;
  new_password?: string;
}

interface AuthContextType {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<TokenResponse>;
  logout: () => void;
  updateUserProfile: (data: UserUpdatePayload) => Promise<User | null>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(() => localStorage.getItem('tiyrasense_token'));
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    async function restoreSession() {
      const storedToken = localStorage.getItem('tiyrasense_token');
      const storedUserStr = localStorage.getItem('tiyrasense_user');
      if (storedToken) {
        if (storedUserStr) {
          try {
            setUser(JSON.parse(storedUserStr));
          } catch {
            // ignore parse error
          }
        }
        setToken(storedToken);
        try {
          const profile = await fetchCurrentUser();
          setUser(profile);
          localStorage.setItem('tiyrasense_user', JSON.stringify(profile));
        } catch {
          // Retain cached session across network errors & browser restarts
          // Only explicit logout destroys session
        }
      }
      setIsLoading(false);
    }
    restoreSession();
  }, []);

  const login = async (email: string, password: string): Promise<TokenResponse> => {
    setIsLoading(true);
    try {
      const response = await loginUser(email, password);
      localStorage.setItem('tiyrasense_token', response.access_token);
      localStorage.setItem('tiyrasense_user', JSON.stringify(response.user));
      setToken(response.access_token);
      setUser(response.user);
      return response;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    localStorage.removeItem('tiyrasense_token');
    localStorage.removeItem('tiyrasense_user');
    setToken(null);
    setUser(null);
  };

  const updateUserProfile = async (data: UserUpdatePayload): Promise<User | null> => {
    // 1. Optimistic update to local state and localStorage
    setUser((prev) => {
      if (!prev) return null;
      const updated = {
        ...prev,
        full_name: data.full_name !== undefined ? data.full_name : prev.full_name,
        phone_number: data.phone_number !== undefined ? data.phone_number : prev.phone_number,
        organization: data.organization !== undefined ? data.organization : prev.organization,
      };
      localStorage.setItem('tiyrasense_user', JSON.stringify(updated));
      return updated;
    });

    // 2. Persist to backend database (PostgreSQL + Supabase)
    try {
      const updated = await updateCurrentUserProfile({
        full_name: data.full_name ?? undefined,
        phone_number: (data.phone_number !== null ? data.phone_number : undefined),
        organization: (data.organization !== null ? data.organization : undefined),
        current_password: data.current_password,
        new_password: data.new_password,
      });

      setUser(updated);
      localStorage.setItem('tiyrasense_user', JSON.stringify(updated));
      return updated;
    } catch (err) {
      console.warn('Backend database profile sync encountered an issue, kept local update:', err);
      return user;
    }
  };

  return (
    <AuthContext.Provider value={{ user, token, isLoading, login, logout, updateUserProfile }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
