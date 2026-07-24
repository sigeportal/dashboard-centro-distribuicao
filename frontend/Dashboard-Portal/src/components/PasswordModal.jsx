import { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { KeyRound, X, Eye, EyeOff } from 'lucide-react';
import axios from 'axios';
import { AUTH_API_BASE } from '../services/api';
import { getAccessToken } from '../services/auth';
import useFocusTrap from '../hooks/useFocusTrap';
import './PasswordModal.css';

export default function PasswordModal({ isOpen, onClose }) {
  const modalRef = useFocusTrap(isOpen);
  const [passwordForm, setPasswordForm] = useState({
    oldPassword: '',
    newPassword: '',
    confirmPassword: ''
  });
  const [passwordMsg, setPasswordMsg] = useState({ text: '', type: '' });
  const [passwordLoading, setPasswordLoading] = useState(false);
  const [showOldPassword, setShowOldPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [onClose]);

  const handleClose = () => {
    setPasswordMsg({ text: '', type: '' });
    onClose();
  };

  const handlePasswordChange = async (e) => {
    e.preventDefault();
    setPasswordMsg({ text: '', type: '' });

    const { oldPassword, newPassword, confirmPassword } = passwordForm;

    if (!oldPassword.trim()) {
      setPasswordMsg({ text: 'A senha atual não pode ser vazia.', type: 'error' });
      return;
    }

    if (!newPassword || !newPassword.trim()) {
      setPasswordMsg({ text: 'A nova senha não pode ser vazia ou conter apenas espaços em branco.', type: 'error' });
      return;
    }

    if (/\s{2,}/.test(newPassword)) {
      setPasswordMsg({ text: 'A nova senha não pode conter vários espaços em branco consecutivos.', type: 'error' });
      return;
    }

    if (newPassword !== confirmPassword) {
      setPasswordMsg({ text: 'A nova senha e a confirmação não coincidem.', type: 'error' });
      return;
    }

    const accessToken = getAccessToken();
    if (!accessToken) {
      setPasswordMsg({ text: 'Sessão expirada. Faça login novamente.', type: 'error' });
      return;
    }

    setPasswordLoading(true);

    try {
      const response = await axios.post(`${AUTH_API_BASE}/v1/update-password`, {
        old_password: oldPassword,
        new_password: newPassword
      }, {
        headers: {
          Authorization: `Bearer ${accessToken}`
        }
      });

      if (response.status === 200) {
        setPasswordMsg({ text: response.data?.status || 'Senha alterada com sucesso!', type: 'success' });
        setPasswordForm({ oldPassword: '', newPassword: '', confirmPassword: '' });
      }
    } catch (error) {
      if (error.response) {
        const status = error.response.status;
        const errorMsg = error.response.data?.error || '';

        if (status === 401) {
          setPasswordMsg({ text: errorMsg || 'Credenciais inválidas! Verifique sua senha atual.', type: 'error' });
        } else if (status === 400) {
          setPasswordMsg({ text: errorMsg || 'Requisição inválida. Verifique os dados informados.', type: 'error' });
        } else if (status === 500) {
          setPasswordMsg({ text: errorMsg || 'Erro interno do servidor. Tente novamente mais tarde.', type: 'error' });
        } else {
          setPasswordMsg({ text: errorMsg || 'Ocorreu um erro inesperado.', type: 'error' });
        }
      } else {
        setPasswordMsg({ text: 'Erro de conexão. Verifique sua internet e tente novamente.', type: 'error' });
      }
    } finally {
      setPasswordLoading(false);
    }
  };

  if (!isOpen) return null;

  return createPortal(
    <div className="password-modal-overlay" onClick={handleClose}>
      <div
        ref={modalRef}
        className="password-modal glass"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="password-modal-title"
      >
        <div className="password-modal-header">
          <h3 id="password-modal-title"><KeyRound size={22} /> Alterar Senha</h3>
          <button className="password-modal-close" onClick={handleClose} aria-label="Fechar alterar senha">
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handlePasswordChange} className="password-modal-form">
          <div className="form-group">
            <label htmlFor="old-password">Senha Atual</label>
            <div className="password-input-wrapper">
              <input
                id="old-password"
                type={showOldPassword ? 'text' : 'password'}
                value={passwordForm.oldPassword}
                onChange={(e) => setPasswordForm(prev => ({ ...prev, oldPassword: e.target.value }))}
                placeholder="Digite sua senha atual"
                required
                autoComplete="current-password"
              />
              <button
                type="button"
                className="password-toggle-btn"
                onClick={() => setShowOldPassword(!showOldPassword)}
                aria-label={showOldPassword ? 'Ocultar senha atual' : 'Mostrar senha atual'}
                aria-pressed={showOldPassword}
              >
                {showOldPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>

          <div className="form-group">
            <label htmlFor="new-password">Nova Senha</label>
            <div className="password-input-wrapper">
              <input
                id="new-password"
                type={showNewPassword ? 'text' : 'password'}
                value={passwordForm.newPassword}
                onChange={(e) => setPasswordForm(prev => ({ ...prev, newPassword: e.target.value }))}
                placeholder="Digite sua nova senha"
                required
                autoComplete="new-password"
              />
              <button
                type="button"
                className="password-toggle-btn"
                onClick={() => setShowNewPassword(!showNewPassword)}
                aria-label={showNewPassword ? 'Ocultar nova senha' : 'Mostrar nova senha'}
                aria-pressed={showNewPassword}
              >
                {showNewPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>

          <div className="form-group">
            <label htmlFor="confirm-password">Confirmar Nova Senha</label>
            <div className="password-input-wrapper">
              <input
                id="confirm-password"
                type={showConfirmPassword ? 'text' : 'password'}
                value={passwordForm.confirmPassword}
                onChange={(e) => setPasswordForm(prev => ({ ...prev, confirmPassword: e.target.value }))}
                placeholder="Confirme sua nova senha"
                required
                autoComplete="new-password"
              />
              <button
                type="button"
                className="password-toggle-btn"
                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                aria-label={showConfirmPassword ? 'Ocultar confirmação da nova senha' : 'Mostrar confirmação da nova senha'}
                aria-pressed={showConfirmPassword}
              >
                {showConfirmPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>

          {passwordMsg.text && (
            <div className={`password-msg ${passwordMsg.type}`}>
              {passwordMsg.text}
            </div>
          )}

          <button
            type="submit"
            className="password-submit-btn"
            disabled={passwordLoading}
          >
            {passwordLoading ? 'Alterando...' : 'Alterar Senha'}
          </button>
        </form>
      </div>
    </div>,
    document.body
  );
}
