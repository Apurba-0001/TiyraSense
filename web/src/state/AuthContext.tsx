import React, { createContext, useContext, useState, useEffect } from 'react';
import { User, TokenResponse } from '../types/auth';
import { loginUser, fetchCurrentUser } from '../services/api';

interface AuthContextType {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<TokenResponse>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(() => localStorage.getItem('tiyrasense_token'));
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    async function restoreSession() {
      const storedToken = localStorage.getItem('tiyrasense_token');
      if (storedToken) {
        try {
          const profile = await fetchCurrentUser();
          setUser(profile);
          setToken(storedToken);
        } catch {
          localStorage.removeItem('tiyrasense_token');
          setUser(null);
          setToken(null);
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
      setToken(response.access_token);
      setUser(response.user);
      return response;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    localStorage.removeItem('tiyrasense_token');
    setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, token, isLoading, login, logout }}>
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
