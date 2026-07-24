// ---------- access_token: memória apenas ----------
let accessToken = null;

export function getAccessToken() {
  return accessToken;
}

export function setAccessToken(token) {
  accessToken = token;
}

// ---------- sessionStorage ----------
export function getRefreshToken() {
  return sessionStorage.getItem('refresh_token');
}

export function setRefreshToken(token) {
  if (token) {
    sessionStorage.setItem('refresh_token', token);
  } else {
    sessionStorage.removeItem('refresh_token');
  }
}

export function getCpf() {
  return sessionStorage.getItem('cpf');
}

export function setCpf(value) {
  if (value) {
    sessionStorage.setItem('cpf', value);
  } else {
    sessionStorage.removeItem('cpf');
  }
}

export function getCnpj() {
  return sessionStorage.getItem('cnpj');
}

export function setCnpj(value) {
  if (value) {
    sessionStorage.setItem('cnpj', value);
  } else {
    sessionStorage.removeItem('cnpj');
  }
}

export function getBaseUrl() {
  return sessionStorage.getItem('base_url');
}

export function setBaseUrl(value) {
  if (!value) {
    sessionStorage.removeItem('base_url');
    return true;
  }
  try {
    const url = new URL(value);
    const isLocalHttp = url.protocol === 'http:' && ['localhost', '127.0.0.1'].includes(url.hostname);
    if (url.protocol !== 'https:' && !isLocalHttp) {
      return false;
    }
  } catch {
    return false;
  }
  sessionStorage.setItem('base_url', value);
  return true;
}

// ---------- limpeza ----------
export function clearAuth() {
  accessToken = null;
  sessionStorage.removeItem('refresh_token');
  sessionStorage.removeItem('cpf');
  sessionStorage.removeItem('cnpj');
  sessionStorage.removeItem('base_url');
}

/**
 * Remove dados legados que estavam em localStorage (migração).
 * Chamado uma vez na inicialização do app.
 */
export function clearLegacyStorage() {
  localStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');
  localStorage.removeItem('cpf');
  localStorage.removeItem('cnpj');
  localStorage.removeItem('base_url');
  sessionStorage.removeItem('cnpj');
}

// ---------- JWT helpers ----------
function decodeJwtPayload(token) {
  try {
    const base64 = token.split('.')[1];
    const json = atob(base64.replace(/-/g, '+').replace(/_/g, '/'));
    return JSON.parse(json);
  } catch {
    return null;
  }
}

/**
 * Verifica se o token JWT está expirado.
 * Retorna true se expirado ou se não tem campo `exp`.
 */
export function isTokenExpired(token) {
  if (!token) return true;
  const payload = decodeJwtPayload(token);
  if (!payload?.exp) return true;
  // Margem de 30s para evitar rejeição por clock skew
  return Date.now() >= (payload.exp * 1000) - 30000;
}

/**
 * Retorna true se há sessão ativa.
 * - access_token em memória e não expirado → true
 * - refresh_token em sessionStorage → true (tentará refresh automático)
 */
export function hasSession() {
  if (accessToken && !isTokenExpired(accessToken)) return true;
  return !!getRefreshToken();
}

/**
 * Retorna o papel (role) do usuário a partir do token JWT.
 * Procura por claims comuns como 'role', 'roles', 'type', ou 'permission'.
 * Retorna 'admin' por padrão se não for encontrado (seguro contra quebras).
 */
export function getUserRole() {
  const token = accessToken || getRefreshToken();
  if (!token) return null;
  const payload = decodeJwtPayload(token);
  if (!payload) return 'admin';
  
  // Mapeia possíveis chaves de roles do payload do backend
  const role = payload.role || payload.roles?.[0] || payload.type || payload.permission;
  return role ? String(role).toLowerCase() : 'admin';
}

