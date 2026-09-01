import { useEffect } from 'react';
import { createPortal } from 'react-dom';
import { X, Mail, LifeBuoy, Clock, ExternalLink } from 'lucide-react';
import useFocusTrap from '../hooks/useFocusTrap';
import './SupportModal.css';

export default function SupportModal({ isOpen, onClose }) {
  const modalRef = useFocusTrap(isOpen);

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

  if (!isOpen) return null;

  const handleClose = () => {
    onClose();
  };

  const whatsappPhone = '556734673694';
  const whatsappMessage = 'Olá! Gostaria de tirar uma dúvida ou solicitar suporte referente ao Dashboard do Portal Gerencial.';
  const whatsappUrl = `https://wa.me/${whatsappPhone}?text=${encodeURIComponent(whatsappMessage)}`;

  return createPortal(
    <div className="support-modal-overlay" onClick={handleClose}>
      <div
        ref={modalRef}
        className="support-modal glass"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="support-modal-title"
        aria-describedby="support-modal-desc"
      >
        {/* Header */}
        <div className="support-modal-header">
          <div className="support-modal-title-group">
            <div className="support-modal-icon-badge">
              <LifeBuoy size={20} />
            </div>
            <div>
              <h3 id="support-modal-title">Central de Suporte</h3>
              <span className="support-modal-subtitle">Canais diretos de atendimento e suporte técnico</span>
            </div>
          </div>
          <button className="support-modal-close" onClick={handleClose} aria-label="Fechar suporte">
            <X size={20} />
          </button>
        </div>

        {/* Modal Body */}
        <div className="support-modal-body">
          <p id="support-modal-desc" className="support-modal-desc">
            Como podemos te ajudar? Escolha um de nossos canais oficiais de atendimento:
          </p>

          <div className="support-options">
            {/* WhatsApp Card */}
            <a
              href={whatsappUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="support-option-card whatsapp-card glass"
            >
              <div className="icon-wrapper">
                <svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor">
                  <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.039 2.879 1.188 3.077.149.2 2.038 3.113 4.939 4.363.69.298 1.229.476 1.64.6.696.222 1.329.19 1.83.114.558-.083 1.758-.718 2.007-1.409.249-.69.249-1.284.174-1.409-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L0 24l6.335-1.662c1.746.953 3.71 1.458 5.705 1.459h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                </svg>
              </div>
              <div className="option-details">
                <span className="option-label">WhatsApp Corporativo</span>
                <span className="option-value">(67) 3467-3694</span>
              </div>
              <div className="option-action-hint">
                <ExternalLink size={16} />
              </div>
            </a>

            {/* Email Card */}
            <a
              href="mailto:sigeportal@gmail.com"
              className="support-option-card email-card glass"
            >
              <div className="icon-wrapper">
                <Mail size={22} />
              </div>
              <div className="option-details">
                <span className="option-label">E-mail de Suporte</span>
                <span className="option-value">sigeportal@gmail.com</span>
              </div>
              <div className="option-action-hint">
                <ExternalLink size={16} />
              </div>
            </a>
          </div>

          {/* Info Card */}
          <div className="support-info-banner">
            <Clock size={16} className="info-icon" />
            <span>Horário de Atendimento: Segunda a Sexta • 07h30 às 17h30 (MS)</span>
          </div>
        </div>

        {/* Modal Footer */}
        <div className="support-modal-footer">
          <div className="shortcut-hint">
            <kbd>ESC</kbd> <span>Fechar</span>
          </div>
          <button type="button" className="btn-secondary" onClick={handleClose}>
            Fechar
          </button>
        </div>
      </div>
    </div>,
    document.body
  );
}

