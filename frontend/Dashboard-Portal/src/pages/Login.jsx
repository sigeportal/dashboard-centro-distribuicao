import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { AUTH_API_BASE } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import { logError } from '../utils/logger';
import logo from '/portal_gerencial_logo.svg';
import './Login.css';

export default function Login() {
  const navigate = useNavigate();
  const { login } = useAuth();
  const [mode, setMode] = useState('login');
  const [cpf, setCpf] = useState('');
  const [nome, setNome] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const isRegisterMode = mode === 'register';
  const authJsonConfig = {
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json; charset=utf-8'
    }
  };

  const onlyDigits = (value) => value.replace(/\D/g, '');

  const formatCpf = (value) => {
    return value
      .replace(/\D/g, '')
      .slice(0, 11)
      .replace(/(\d{3})(\d)/, '$1.$2')
      .replace(/(\d{3})(\d)/, '$1.$2')
      .replace(/(\d{3})(\d{1,2})$/, '$1-$2');
  };

  const clearMessages = () => {
    if (errorMsg) setErrorMsg('');
  };

  const handleModeChange = (nextMode) => {
    setMode(nextMode);
    setErrorMsg('');
    setNome('');
    setPassword('');
    setConfirmPassword('');
  };

  const authenticate = async ({ cpf: cpfValue = cpf, password: passwordValue = password } = {}) => {
    const normalizedCpf = onlyDigits(cpfValue);

    const response = await axios.post(
      `${AUTH_API_BASE}/v1/login`,
      JSON.stringify({
        cpf: normalizedCpf,
        password: passwordValue
      }),
      authJsonConfig
    );

    const { access_token, refresh_token } = response.data;
    if (!access_token || !refresh_token) {
      throw new Error('Resposta de login sem tokens.');
    }

    login({ access_token, refresh_token, cpf: normalizedCpf });
    // Ao logar, abre diretamente o ambiente do Centro de Distribuição (CD)
    localStorage.setItem('selected_company_id', '5');
    navigate('/dashboard', { replace: true });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setErrorMsg('');
    setIsSubmitting(true);

    try {
      const formData = new FormData(e.currentTarget);
      const submittedCpf = String(formData.get('cpf') || cpf);
      const submittedPassword = String(formData.get('password') || password);
      const normalizedCpf = onlyDigits(submittedCpf);

      if (isRegisterMode) {
        const submittedName = String(formData.get('nome') || nome);
        const submittedConfirmPassword = String(formData.get('confirmPassword') || confirmPassword);
        const normalizedName = submittedName.trim();

        if (!normalizedName) {
          setErrorMsg('Informe seu nome para criar a conta.');
          return;
        }

        if (submittedPassword !== submittedConfirmPassword) {
          setErrorMsg('As senhas informadas não coincidem.');
          return;
        }

        await axios.post(
          `${AUTH_API_BASE}/v1/register`,
          JSON.stringify({
            name: normalizedName,
            cpf: normalizedCpf,
            password: submittedPassword
          }),
          authJsonConfig
        );
      }

      await authenticate({ cpf: normalizedCpf, password: submittedPassword });
    } catch (error) {
      logError(isRegisterMode ? 'Erro no cadastro' : 'Erro no login', error);
      const apiMessage = error.response?.data?.error || error.response?.data?.message;
      setErrorMsg(apiMessage || (isRegisterMode
        ? 'Falha ao criar conta. Verifique os dados informados.'
        : 'Falha ao efetuar login. Verifique as credenciais.'));
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="login-container">
      <form onSubmit={handleSubmit} className="login-form">
        <img src={logo} alt="Logo Portal Gerencial" className="login-logo" />
        <div className="auth-heading">
          <h2>{isRegisterMode ? 'Criar conta' : 'Login Dashboard'}</h2>
          <p>{isRegisterMode ? 'Cadastre seu acesso para gerenciar suas empresas.' : 'Acesse com seu CPF para escolher uma empresa.'}</p>
        </div>

        <div className="auth-mode-switch" role="tablist" aria-label="Opções de autenticação">
          <button
            type="button"
            className={mode === 'login' ? 'active' : ''}
            onClick={() => handleModeChange('login')}
            role="tab"
            aria-selected={mode === 'login'}
          >
            Entrar
          </button>
          <button
            type="button"
            className={mode === 'register' ? 'active' : ''}
            onClick={() => handleModeChange('register')}
            role="tab"
            aria-selected={mode === 'register'}
          >
            Registrar
          </button>
        </div>

        <div key={mode} className="auth-fields">
          {errorMsg && <div className="login-error-message">{errorMsg}</div>}

          {isRegisterMode && (
            <div className="form-group">
              <label htmlFor="nome">Nome</label>
              <input
                id="nome"
                name="nome"
                type="text"
                value={nome}
                onChange={(e) => {
                  setNome(e.target.value);
                  clearMessages();
                }}
                placeholder="Seu nome completo"
                autoComplete="name"
                required
              />
            </div>
          )}

          <div className="form-group">
            <label htmlFor="cpf">CPF</label>
            <input
              id="cpf"
              name="cpf"
              type="text"
              value={cpf}
              onChange={(e) => {
                setCpf(formatCpf(e.target.value));
                clearMessages();
              }}
              placeholder="000.000.000-00"
              inputMode="numeric"
              autoComplete="username"
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="password">Senha</label>
            <input
              id="password"
              name="password"
              type="password"
              value={password}
              onChange={(e) => {
                setPassword(e.target.value);
                clearMessages();
              }}
              placeholder="Sua senha"
              autoComplete={isRegisterMode ? 'new-password' : 'current-password'}
              required
            />
          </div>

          {isRegisterMode && (
            <div className="form-group">
              <label htmlFor="confirm-password">Confirmar senha</label>
              <input
                id="confirm-password"
                name="confirmPassword"
                type="password"
                value={confirmPassword}
                onChange={(e) => {
                  setConfirmPassword(e.target.value);
                  clearMessages();
                }}
                placeholder="Confirme sua senha"
                autoComplete="new-password"
                required
              />
            </div>
          )}
        </div>

        <button type="submit" className="auth-submit-btn" disabled={isSubmitting}>
          {isSubmitting ? 'Aguarde...' : isRegisterMode ? 'Criar conta e entrar' : 'Entrar'}
        </button>
      </form>
    </div>
  );
}
