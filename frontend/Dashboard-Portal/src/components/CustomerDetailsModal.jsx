import { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { X, User, MapPin, Phone, FileText, DollarSign, Eye, EyeOff, Printer, ShieldCheck, AlertCircle } from 'lucide-react';
import { formatCurrency, maskCpfCnpj, maskPhone, maskEmail } from '../utils/formatters';
import { logError } from '../utils/logger';
import { createApi } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import useFocusTrap from '../hooks/useFocusTrap';
import './CustomerDetailsModal.css';

const activeRequests = new Map();

export default function CustomerDetailsModal({ isOpen, onClose, customer }) {
  const modalRef = useFocusTrap(isOpen);
  const [debtValue, setDebtValue] = useState(null);
  const [loadingDebt, setLoadingDebt] = useState(false);
  const [debtError, setDebtError] = useState(null);
  const [showSensitive, setShowSensitive] = useState(false);

  const { userRole } = useAuth();
  const isFinancialAllowed = userRole === 'admin' || userRole === 'gerente';
  const customerId = customer?.codigo;

  useEffect(() => {
    if (!customerId) return;

    let isMounted = true;
    const fetchDebt = async () => {
      setLoadingDebt(true);
      setDebtError(null);
      try {
        let promise = activeRequests.get(customerId);
        if (!promise) {
          const api = createApi(true);
          promise = api.get(`/v1/clientes/${customerId}/valor-devedor`);
          activeRequests.set(customerId, promise);

          promise.finally(() => {
            activeRequests.delete(customerId);
          });
        }

        const res = await promise;
        if (isMounted) {
          const value = res.data?.vlr_devedor ?? 0;
          setDebtValue(Number(value));
        }
      } catch (err) {
        logError('Erro ao carregar valor devedor do cliente:', err);
        if (isMounted) {
          setDebtError('Erro ao carregar');
        }
      } finally {
        if (isMounted) {
          setLoadingDebt(false);
        }
      }
    };

    fetchDebt();

    return () => {
      isMounted = false;
    };
  }, [customerId]);

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

  if (!isOpen || !customer) return null;

  const code = customer.codigo ?? '-';
  const name = customer.nome ?? 'Cliente sem nome';
  const phone = customer.celular ?? customer.telefone ?? '-';
  const email = customer.email ?? '-';
  const city = customer.cidade ?? '-';
  const uf = customer.uf ?? '-';

  // Extra details
  const address = customer.endereco ?? customer.end ?? customer.logradouro ?? '-';
  const neighborhood = customer.bairro ?? '-';
  const zip = customer.cep ?? '-';
  const doc = customer.cnpj ?? customer.cpf_cnpj ?? customer.cnpj_cpf ?? customer.cpf ?? '-';
  const rgIe = customer.ie ?? customer.insc_estadual ?? customer.rg ?? '-';
  const creditLimit = customer.limite ?? customer.limite_credito ?? 0;

  const hasDebt = (debtValue || 0) > 0;

  return createPortal(
    <div className="customer-modal-overlay" onClick={onClose}>
      <div
        ref={modalRef}
        className="customer-modal glass"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="customer-modal-title"
      >
        {/* Header */}
        <div className="customer-modal-header">
          <div className="customer-modal-title-group">
            <div className="customer-modal-icon-badge">
              <User size={22} />
            </div>
            <div>
              <h3 id="customer-modal-title">Ficha do Cliente</h3>
              <span className="customer-modal-subtitle">Código #{code} • Cadastro e Informações</span>
            </div>
          </div>

          <div className="customer-modal-header-actions">
            <button
              type="button"
              onClick={() => setShowSensitive(!showSensitive)}
              className="customer-modal-toggle-sensitive"
              aria-label={showSensitive ? 'Ocultar dados sensíveis' : 'Revelar dados sensíveis'}
              title={showSensitive ? 'Ocultar dados sensíveis' : 'Revelar dados sensíveis'}
            >
              {showSensitive ? <EyeOff size={16} /> : <Eye size={16} />}
              <span>{showSensitive ? 'Ocultar Dados' : 'Exibir Dados'}</span>
            </button>
            <button className="customer-modal-close" onClick={onClose} aria-label="Fechar ficha do cliente">
              <X size={20} />
            </button>
          </div>
        </div>

        {/* Modal Body */}
        <div className="customer-modal-body">
          {/* Header Summary */}
          <div className="customer-profile-summary">
            <div className="avatar-placeholder">
              {name.charAt(0).toUpperCase()}
            </div>
            <div className="profile-info">
              <h4>{name}</h4>
              <div className="profile-badges">
                <span className="profile-code">Código #{code}</span>
                {uf && uf !== '-' && <span className="profile-uf-badge">{uf}</span>}
              </div>
            </div>
          </div>

          <div className="customer-details-grid">
            {/* Contact Card */}
            <div className="details-section-card glass">
              <h5><Phone size={16} className="section-icon" /> Contato</h5>
              <div className="details-field">
                <span className="field-label">Celular / Telefone</span>
                <span className="field-value">{showSensitive ? phone : maskPhone(phone)}</span>
              </div>
              <div className="details-field">
                <span className="field-label">E-mail</span>
                <span className="field-value email-value">{showSensitive ? email : maskEmail(email)}</span>
              </div>
            </div>

            {/* Location Card */}
            <div className="details-section-card glass">
              <h5><MapPin size={16} className="section-icon" /> Localização</h5>
              <div className="details-field">
                <span className="field-label">Cidade / UF</span>
                <span className="field-value">{city} - {uf}</span>
              </div>
              <div className="details-field">
                <span className="field-label">Endereço</span>
                <span className="field-value">{address}</span>
              </div>
              <div className="details-field">
                <span className="field-label">Bairro</span>
                <span className="field-value">{neighborhood}</span>
              </div>
              <div className="details-field">
                <span className="field-label">CEP</span>
                <span className="field-value">{zip}</span>
              </div>
            </div>

            {/* Document Card */}
            <div className="details-section-card glass">
              <h5><FileText size={16} className="section-icon" /> Documentos</h5>
              <div className="details-field">
                <span className="field-label">CPF / CNPJ</span>
                <span className="field-value">{showSensitive ? doc : maskCpfCnpj(doc)}</span>
              </div>
              <div className="details-field">
                <span className="field-label">RG / Inscrição Estadual</span>
                <span className="field-value">{showSensitive ? rgIe : maskCpfCnpj(rgIe)}</span>
              </div>
            </div>

            {/* Financial Card */}
            {isFinancialAllowed && (
              <div className={`details-section-card financial-card glass ${hasDebt ? 'has-debt-card' : 'no-debt-card'}`}>
                <div className="financial-card-header">
                  <h5><DollarSign size={16} className="section-icon" /> Situação Financeira</h5>
                  {!loadingDebt && !debtError && (
                    <span className={`status-pill ${hasDebt ? 'status-debt' : 'status-ok'}`}>
                      {hasDebt ? (
                        <>
                          <AlertCircle size={13} />
                          <span>Em Débito</span>
                        </>
                      ) : (
                        <>
                          <ShieldCheck size={13} />
                          <span>Adimplente</span>
                        </>
                      )}
                    </span>
                  )}
                </div>

                <div className="details-field">
                  <span className="field-label">Valor Devedor</span>
                  {loadingDebt ? (
                    <span className="loading-skeleton" aria-label="Carregando..." />
                  ) : debtError ? (
                    <span className="field-value devedor-amount error-text">
                      {debtError}
                    </span>
                  ) : (
                    <span className={`field-value devedor-amount ${hasDebt ? 'has-debt' : 'no-debt'}`}>
                      {formatCurrency(debtValue ?? 0)}
                    </span>
                  )}
                </div>

                {(customer.limite !== undefined || customer.limite_credito !== undefined) && (
                  <div className="details-field">
                    <span className="field-label">Limite de Crédito</span>
                    <span className="field-value">{formatCurrency(creditLimit)}</span>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>

        {/* Footer with Shortcuts and Actions */}
        <div className="customer-modal-footer">
          <div className="shortcut-hint">
            <kbd>ESC</kbd> <span>Fechar</span>
          </div>
          <div className="customer-modal-footer-actions">
            <button
              type="button"
              className="btn-secondary"
              onClick={() => window.print()}
              title="Imprimir Ficha do Cliente"
            >
              <Printer size={16} />
              <span>Imprimir</span>
            </button>
            <button
              type="button"
              className="btn-secondary"
              onClick={onClose}
            >
              Fechar
            </button>
          </div>
        </div>
      </div>
    </div>,
    document.body
  );
}
