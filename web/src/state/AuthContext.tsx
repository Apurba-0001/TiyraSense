import React, { createContext, useContext, useState, useEffect } from 'react';
import { User, TokenResponse } from '../types/auth';
import { loginUser, fetchCurrentUser } from '../services/api';

interface AuthContextType {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<TokenResponse>;
  logout: () => void;
  updateUserProfile: (data: Partial<User>) => void;
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

  const updateUserProfile = (data: Partial<User>) => {
    setUser((prev) => (prev ? { ...prev, ...data } : null));
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
