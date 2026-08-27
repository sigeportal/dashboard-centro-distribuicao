import axios from 'axios';
import { getAccessToken, setAccessToken, getRefreshToken, getBaseUrl } from './auth';

export const AUTH_API_BASE = import.meta.env.VITE_AUTH_API_BASE || 'https://servidor-auth-dash-fboxwqyjfq-rj.a.run.app';
export const CD_API_BASE = import.meta.env.VITE_CD_API_BASE || 'http://127.0.0.1:8080';

const normalizeBaseUrl = (baseUrl) => {
  if (!baseUrl) return '';
  const normalized = baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl;
  return normalized.endsWith('/v1') ? normalized.slice(0, -3) : normalized;
};

let refreshPromise = null;

export const isUnauthorizedError = (error) => error.response?.status === 401 || error.isAuthRefreshFailure;

export function createApi() {
  const baseUrl = normalizeBaseUrl(CD_API_BASE);
  const token = getAccessToken();

  const headers = {
    'ngrok-skip-browser-warning': 'true'
  };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  const selectedCompanyId = localStorage.getItem('selected_company_id');
  if (selectedCompanyId) {
    headers['X-Empresa-Id'] = selectedCompanyId;
  }

  const api = axios.create({
    baseURL: baseUrl,
    headers
  });

  api.interceptors.request.use((config) => {
    const empId = localStorage.getItem('selected_company_id') || 
                  localStorage.getItem('empresa_id') || 
                  localStorage.getItem('emp_id') || '1';
    const empCc = localStorage.getItem('emp_cc') || empId;

    config.headers['X-Empresa-Id'] = empId;
    config.headers['X-Empresa-CC'] = empCc;

    config.params = {
      emp_id: empId,
      emp_cc: empCc,
      ...config.params
    };
    return config;
  });

  api.interceptors.response.use(
    (response) => response,
    async (error) => {
      const originalRequest = error.config;
      if (error.response?.status === 401 && !originalRequest._retry) {
        originalRequest._retry = true;
        try {
          const refreshToken = getRefreshToken();
          if (!refreshToken) {
            throw new Error('Refresh token ausente.');
          }

          refreshPromise ??= axios
            .post(`${AUTH_API_BASE}/v1/refresh-token`, { refresh_token: refreshToken })
            .finally(() => {
              refreshPromise = null;
            });

          const res = await refreshPromise;

          const newAccessToken = res.data.access_token;
          if (newAccessToken) {
            setAccessToken(newAccessToken);
            
            // Garantir que a instância atual use o novo token no retry
            api.defaults.headers.common['Authorization'] = `Bearer ${newAccessToken}`;
            if (api.defaults.headers.Authorization) {
              api.defaults.headers.Authorization = `Bearer ${newAccessToken}`;
            }
            
            // Garantir que a requisição original que falhou seja atualizada
            if (originalRequest.headers.set) {
              originalRequest.headers.set('Authorization', `Bearer ${newAccessToken}`);
            } else {
              originalRequest.headers['Authorization'] = `Bearer ${newAccessToken}`;
            }
            
            return api(originalRequest);
          }
          throw new Error('Refresh sem access_token.');
        } catch (refreshError) {
          refreshError.isAuthRefreshFailure = true;
          return Promise.reject(refreshError);
        }
      }
      return Promise.reject(error);
    }
  );
  return api;
}

export { normalizeBaseUrl };
