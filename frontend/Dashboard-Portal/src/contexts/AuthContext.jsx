import { createContext, useContext, useState, useCallback, useEffect } from 'react';
import axios from 'axios';
import {
  setAccessToken, setRefreshToken, setCpf,
  clearAuth, clearLegacyStorage, hasSession, getUserRole,
  getRefreshToken, getAccessToken
} from '../services/auth';
import { AUTH_API_BASE } from '../services/api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [isAuthenticated, setIsAuthenticated] = useState(hasSession);
  const [userRole, setUserRole] = useState(getUserRole);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    clearLegacyStorage();

    const initializeAuth = async () => {
      const refreshToken = getRefreshToken();
      const accessToken = getAccessToken();

      if (refreshToken && !accessToken) {
        try {
          const res = await axios.post(`${AUTH_API_BASE}/v1/refresh-token`, {
            refresh_token: refreshToken
          });
          const newAccessToken = res.data.access_token;
          if (newAccessToken) {
            setAccessToken(newAccessToken);
            setIsAuthenticated(true);
            setUserRole(getUserRole());
          } else {
            throw new Error('Sem access_token retornado');
          }
        } catch {
          clearAuth();
          setIsAuthenticated(false);
          setUserRole(null);
        }
      }
      setLoading(false);
    };

    initializeAuth();
  }, []);

  const login = useCallback(({ access_token, refresh_token, cpf }) => {
    setAccessToken(access_token);
    setRefreshToken(refresh_token);
    setCpf(cpf);
    setIsAuthenticated(true);
    setUserRole(getUserRole());
  }, []);

  const logout = useCallback(() => {
    clearAuth();
    setIsAuthenticated(false);
    setUserRole(null);
  }, []);

  if (loading) {
    return <div className="loading-state">Carregando sessão...</div>;
  }

  return (
    <AuthContext.Provider value={{ isAuthenticated, userRole, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth deve ser usado dentro de <AuthProvider>');
  return ctx;
}
