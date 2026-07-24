import { useCallback, useEffect, useState } from 'react';
import axios from 'axios';
import { ArrowRight, Building2, Link2, LoaderCircle, LogOut, Plus, PlugZap, RefreshCw, X } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { AUTH_API_BASE, normalizeBaseUrl, createApi } from '../services/api';
import { getAccessToken, setBaseUrl, setCnpj } from '../services/auth';
import { useAuth } from '../contexts/AuthContext';
import { logError } from '../utils/logger';
import logo from '/portal_gerencial_logo.svg';
import './CompanySelect.css';

const formatCnpj = (value = '') => {
  return value
    .replace(/\D/g, '')
    .slice(0, 14)
    .replace(/(\d{2})(\d)/, '$1.$2')
    .replace(/(\d{3})(\d)/, '$1.$2')
    .replace(/(\d{3})(\d{1,4})/, '$1/$2')
    .replace(/(\d{4})(\d{1,2})/, '$1-$2');
};

const isAllowedBaseUrl = (value) => {
  try {
    const url = new URL(value);
    const isLocalHttp = url.protocol === 'http:' && ['localhost', '127.0.0.1'].includes(url.hostname);
    return url.protocol === 'https:' || isLocalHttp;
  } catch {
    return false;
  }
};

const getCompanyKey = (company) => company.id || company.cnpj || company.url;

export default function CompanySelect() {
  const navigate = useNavigate();
  const { logout } = useAuth();
  const [companies, setCompanies] = useState([]);
  const [companiesLoading, setCompaniesLoading] = useState(true);
  const [companiesError, setCompaniesError] = useState('');
  const [statusRefreshing, setStatusRefreshing] = useState(false);
  const [cnpj, setCompanyCnpj] = useState('');
  const [claim, setClaim] = useState('');
  const [statusMsg, setStatusMsg] = useState({ text: '', type: '' });
  const [linkLoading, setLinkLoading] = useState(false);
  const [isLinkModalOpen, setIsLinkModalOpen] = useState(false);
  const [pendingTransfers, setPendingTransfers] = useState({});

  const fetchPendingTransfers = async () => {
    try {
      const api = createApi(true);
      const res = await api.get('/v1/transferencias');
      if (Array.isArray(res.data)) {
        const counts = {};
        res.data.forEach(t => {
          if (t.status === 'Em Trânsito') {
            counts[t.destino] = (counts[t.destino] || 0) + 1;
          }
        });
        setPendingTransfers(counts);
      }
    } catch (e) {
      console.warn('Erro ao buscar transferências pendentes para notificação', e);
    }
  };

  const getAuthHeaders = useCallback(() => {
    const token = getAccessToken();
    if (!token) {
      throw new Error('Token de acesso ausente.');
    }
    return {
      Authorization: `Bearer ${token}`,
      'ngrok-skip-browser-warning': 'true'
    };
  }, []);

  const checkCompanyStatus = useCallback(async (company) => {
    const baseUrl = normalizeBaseUrl(company.url);
    if (!baseUrl || !isAllowedBaseUrl(baseUrl)) {
      return { ...company, baseUrl, connectivity: 'offline' };
    }

    try {
      await axios.get(`${baseUrl}/v1/ping`, {
        headers: getAuthHeaders(),
        timeout: 4000,
        validateStatus: () => true
      });
      return { ...company, baseUrl, connectivity: 'online' };
    } catch {
      return { ...company, baseUrl, connectivity: 'offline' };
    }
  }, [getAuthHeaders]);

  const fetchLinkedCompanies = useCallback(async () => {
    setCompaniesLoading(true);
    setCompaniesError('');

    try {
      const response = await axios.get(`${AUTH_API_BASE}/v1/companies/linked`, {
        headers: getAuthHeaders()
      });
      const linkedCompanies = Array.isArray(response.data?.companies)
        ? response.data.companies
        : [];
      const companiesWithStatus = await Promise.all(linkedCompanies.map(checkCompanyStatus));
      setCompanies(companiesWithStatus);
      fetchPendingTransfers();
    } catch (error) {
      logError('Erro ao buscar empresas vinculadas', error);
      const apiMessage = error.response?.data?.error || error.response?.data?.message;
      setCompaniesError(apiMessage || 'Não foi possível carregar as empresas vinculadas.');
      setCompanies([]);
    } finally {
      setCompaniesLoading(false);
    }
  }, [checkCompanyStatus, getAuthHeaders]);

  const refreshCompanyStatuses = async () => {
    if (companies.length === 0) return;

    setStatusRefreshing(true);
    setCompaniesError('');

    try {
      const companiesWithStatus = await Promise.all(companies.map(checkCompanyStatus));
      setCompanies(companiesWithStatus);
      fetchPendingTransfers();
    } catch (error) {
      logError('Erro ao atualizar status das empresas', error);
      setCompaniesError('Não foi possível atualizar o status das empresas.');
    } finally {
      setStatusRefreshing(false);
    }
  };

  useEffect(() => {
    const timer = setTimeout(() => {
      fetchLinkedCompanies();
    }, 0);

    return () => clearTimeout(timer);
  }, [fetchLinkedCompanies]);

  const handleSelectCompany = (company) => {
    const baseUrl = normalizeBaseUrl(company.url || company.baseUrl);
    if (!isAllowedBaseUrl(baseUrl)) {
      setCompaniesError('A URL desta empresa é inválida. Aguarde a API Local atualizar o endereço.');
      return;
    }

    setCnpj(company.cnpj);
    setBaseUrl(baseUrl);
    localStorage.setItem('selected_company_id', company.id);
    navigate('/dashboard', { replace: true });
  };

  const handleLogout = () => {
    logout();
    navigate('/login', { replace: true });
  };

  const handleOpenLinkModal = () => {
    setStatusMsg({ text: '', type: '' });
    setIsLinkModalOpen(true);
  };

  const handleCloseLinkModal = () => {
    if (linkLoading) return;
    setStatusMsg({ text: '', type: '' });
    setIsLinkModalOpen(false);
  };

  const handleLinkCompany = async (event) => {
    event.preventDefault();
    setStatusMsg({ text: '', type: '' });
    setLinkLoading(true);

    try {
      await axios.post(
        `${AUTH_API_BASE}/v1/companies/link`,
        { cnpj, claim },
        { headers: getAuthHeaders() }
      );

      setClaim('');
      setStatusMsg({ text: '', type: '' });
      setIsLinkModalOpen(false);
      await fetchLinkedCompanies();
    } catch (error) {
      logError('Erro ao vincular empresa', error);
      const apiMessage = error.response?.data?.error || error.response?.data?.message;
      setStatusMsg({ text: apiMessage || 'Não foi possível vincular a empresa.', type: 'error' });
    } finally {
      setLinkLoading(false);
    }
  };

  const companyCountLabel = companies.length === 1 ? '1 empresa' : `${companies.length} empresas`;

  return (
    <main className="company-select-page">
      <header className="company-select-topbar">
        <img src={logo} alt="Portal Gerencial" className="company-select-logo" />
        <button type="button" className="company-select-logout" onClick={handleLogout}>
          <LogOut size={18} aria-hidden="true" />
          <span>Sair</span>
        </button>
      </header>

      <section className="company-select-shell" aria-labelledby="company-select-title">
        <div className="company-select-hero">
          <div className="hero-left">
            <p className="company-select-eyebrow">Empresas vinculadas</p>
            <h1 id="company-select-title">
              Escolha uma empresa
              <span className="company-count-badge">{companiesLoading ? 'Carregando' : companyCountLabel}</span>
            </h1>
            <p className="company-select-subtitle">
              O Dashboard verifica a disponibilidade da API Local de cada empresa antes do acesso.
            </p>
          </div>

          <div className="hero-right">
            <button
              type="button"
              className="btn-refresh-companies"
              onClick={refreshCompanyStatuses}
              disabled={companiesLoading || statusRefreshing || companies.length === 0}
            >
              <RefreshCw size={18} aria-hidden="true" className={statusRefreshing ? 'spinning' : ''} />
              <span>{statusRefreshing ? 'Atualizando' : 'Atualizar'}</span>
            </button>
            <button type="button" className="btn-add-company" onClick={handleOpenLinkModal}>
              <Plus size={18} aria-hidden="true" />
              <span>Adicionar Empresa</span>
            </button>
          </div>
        </div>

        {companiesError && (
          <div className="company-status-message error company-page-message">
            {companiesError}
          </div>
        )}

        {companiesLoading ? (
          <div className="company-empty-state">
            <LoaderCircle size={22} aria-hidden="true" className="company-loading-icon" />
            <span>Buscando empresas vinculadas...</span>
          </div>
        ) : companies.length === 0 ? (
          <div className="company-empty-state">
            <Building2 size={24} aria-hidden="true" />
            <span>Nenhuma empresa vinculada ao seu acesso.</span>
          </div>
        ) : (
          <div className="company-grid">
            {companies.map((company) => (
              <button
                key={getCompanyKey(company)}
                type="button"
                className={`company-card company-card--${company.connectivity}`}
                onClick={() => handleSelectCompany(company)}
              >
                <span className="company-card-icon">
                  <Building2 size={24} aria-hidden="true" />
                </span>
                <span className="company-card-content">
                  <span className="company-card-header">
                    <span>
                      <span className="company-name">{company.nome || 'Empresa vinculada'}</span>
                      <span className="company-document">{formatCnpj(company.cnpj)}</span>
                    </span>
                    <span className={`company-status company-status--${company.connectivity}`}>
                      <span className="status-dot"></span>
                      {company.connectivity === 'online' ? 'Online' : 'Offline'}
                    </span>
                  </span>
                </span>
                <span className="company-card-action" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  {pendingTransfers[company.id] > 0 && (
                    <span className="notification-badge" style={{ backgroundColor: 'var(--brand-primary)', color: 'white', padding: '2px 8px', borderRadius: '12px', fontSize: '0.75rem', fontWeight: '600' }}>
                      {pendingTransfers[company.id]} pendente
                    </span>
                  )}
                  <ArrowRight size={20} aria-hidden="true" />
                </span>
              </button>
            ))}
          </div>
        )}
      </section>

      {isLinkModalOpen && (
        <div className="company-modal-overlay" onClick={handleCloseLinkModal}>
          <div
            className="company-link-modal"
            role="dialog"
            aria-modal="true"
            aria-labelledby="company-link-modal-title"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="company-modal-header">
              <div className="company-form-title">
                <span className="company-card-icon">
                  <Link2 size={22} aria-hidden="true" />
                </span>
                <div>
                  <h2 id="company-link-modal-title">Vincular empresa ao cliente</h2>
                  <p>Informe os dados da empresa para concluir o vínculo.</p>
                </div>
              </div>
              <button
                type="button"
                className="company-modal-close"
                onClick={handleCloseLinkModal}
                aria-label="Fechar vínculo de empresa"
                disabled={linkLoading}
              >
                <X size={20} aria-hidden="true" />
              </button>
            </div>

            <form className="company-link-form" onSubmit={handleLinkCompany}>
              {statusMsg.text && (
                <div className={`company-status-message ${statusMsg.type}`}>
                  {statusMsg.text}
                </div>
              )}

              <label className="company-field" htmlFor="company-cnpj">
                <span>CNPJ da Empresa</span>
                <input
                  id="company-cnpj"
                  type="text"
                  value={cnpj}
                  onChange={(event) => {
                    setCompanyCnpj(formatCnpj(event.target.value));
                    if (statusMsg.text) setStatusMsg({ text: '', type: '' });
                  }}
                  placeholder="00.000.000/0000-00"
                  required
                  autoFocus
                />
              </label>

              <label className="company-field" htmlFor="company-claim">
                <span>Claim da Empresa</span>
                <input
                  id="company-claim"
                  type="text"
                  value={claim}
                  onChange={(event) => {
                    setClaim(event.target.value);
                    if (statusMsg.text) setStatusMsg({ text: '', type: '' });
                  }}
                  placeholder="Claim exibido pela API Local"
                  required
                />
              </label>

              <button type="submit" className="company-submit-btn" disabled={linkLoading}>
                <PlugZap size={18} aria-hidden="true" />
                <span>{linkLoading ? 'Vinculando...' : 'Vincular Empresa'}</span>
              </button>
            </form>
          </div>
        </div>
      )}
    </main>
  );
}
