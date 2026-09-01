import { useCallback, useEffect, useState } from 'react';
import axios from 'axios';
import {
  ArrowRight,
  ArrowRightLeft,
  Building2,
  Link2,
  LoaderCircle,
  LogOut,
  Plus,
  PlugZap,
  RefreshCw,
  X
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { AUTH_API_BASE, createApi } from '../services/api';
import { getAccessToken, setCnpj } from '../services/auth';
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

  const fetchPendingTransfers = useCallback(async () => {
    try {
      const api = createApi(true);
      const res = await api.get('/v1/transferencias');
      if (Array.isArray(res.data)) {
        const counts = {};
        res.data.forEach((t) => {
          if (t.status === 'Em Trânsito') {
            const dest = String(t.destino || '');
            counts[dest] = (counts[dest] || 0) + 1;
          }
        });
        setPendingTransfers(counts);
      }
    } catch (e) {
      console.warn('Erro ao buscar transferências pendentes para notificação', e);
    }
  }, []);

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
    return { ...company, connectivity: 'online' };
  }, []);

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
  }, [checkCompanyStatus, fetchPendingTransfers, getAuthHeaders]);

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
    setCnpj(company.cnpj);
    // Limpa URL local legada para garantir que todo o tráfego utilize o CD Cloud Central
    sessionStorage.removeItem('base_url');

    // Mapeamento preciso do Código da Empresa
    let compId = Number(company.codigo || company.id) || 5;
    const compName = (company.nome || company.razao_social || company.fantasia || '').toUpperCase();

    if (compName.includes('MARACAJU')) compId = 8;
    else if (compName.includes('RIO BRILHANTE')) compId = 6;
    else if (compName.includes('ITAPORA') || compName.includes('ITAPORÃ')) compId = 7;
    else if (compName.includes('NOVA ALVORADA')) compId = 4;
    else if (compName.includes('DOURADINA') || compName.includes('CD')) compId = 5;

    const fallbackCities = {
      5: 'DOURADINA',
      1: 'DOURADINA',
      6: 'RIO BRILHANTE',
      7: 'ITAPORÃ',
      4: 'NOVA ALVORADA DO SUL',
      8: 'MARACAJU'
    };
    const city = company.municipio || company.cidade || company.emp_municipio || fallbackCities[compId] || '';
    const uf = company.uf || company.emp_uf || (city ? 'MS' : '');

    localStorage.setItem('selected_company_id', String(compId));
    localStorage.setItem('selected_company_name', company.nome || compName);
    if (city) localStorage.setItem('selected_company_city', city);
    if (uf) localStorage.setItem('selected_company_uf', uf);
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

  const handleCloseLinkModal = useCallback(() => {
    if (linkLoading) return;
    setStatusMsg({ text: '', type: '' });
    setIsLinkModalOpen(false);
  }, [linkLoading]);

  // Suporte ao atalho ESC no Modal
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape' && isLinkModalOpen && !linkLoading) {
        handleCloseLinkModal();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isLinkModalOpen, linkLoading, handleCloseLinkModal]);

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
        <button type="button" className="company-select-logout" onClick={handleLogout} title="Encerrar sessão">
          <LogOut size={16} aria-hidden="true" />
          <span>Sair</span>
        </button>
      </header>

      <section className="company-select-shell" aria-labelledby="company-select-title">
        <div className="company-select-hero">
          <div className="hero-left">
            <p className="company-select-eyebrow">Centro de Distribuição &amp; Filiais</p>
            <h1 id="company-select-title">
              Escolha uma empresa
              <span className="company-count-badge">{companiesLoading ? 'Carregando' : companyCountLabel}</span>
            </h1>
            <p className="company-select-subtitle">
              Selecione uma filial ou centro de distribuição para acessar o painel de gestão integrada.
            </p>
          </div>

          <div className="hero-right">
            <button
              type="button"
              className="btn-secondary"
              onClick={refreshCompanyStatuses}
              disabled={companiesLoading || statusRefreshing || companies.length === 0}
              title="Atualizar disponibilidade das filiais"
            >
              <RefreshCw size={16} aria-hidden="true" className={statusRefreshing ? 'spinning' : ''} />
              <span>{statusRefreshing ? 'Atualizando...' : 'Atualizar'}</span>
            </button>
            <button type="button" className="btn-primary" onClick={handleOpenLinkModal}>
              <Plus size={16} aria-hidden="true" />
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
            <LoaderCircle size={24} aria-hidden="true" className="company-loading-icon" />
            <span>Buscando empresas vinculadas...</span>
          </div>
        ) : companies.length === 0 ? (
          <div className="company-empty-state">
            <Building2 size={24} aria-hidden="true" />
            <span>Nenhuma empresa vinculada ao seu acesso.</span>
          </div>
        ) : (
          <div className="company-grid">
            {companies.map((company) => {
              const fallbackCities = {
                5: 'DOURADINA',
                1: 'DOURADINA',
                6: 'RIO BRILHANTE',
                7: 'ITAPORÃ',
                4: 'NOVA ALVORADA DO SUL',
                8: 'MARACAJU'
              };
              const rawName = company.nome || company.razao_social || company.fantasia || 'Empresa vinculada';
              let compId = Number(company.codigo || company.id) || 5;
              const upperName = rawName.toUpperCase();
              if (upperName.includes('MARACAJU')) compId = 8;
              else if (upperName.includes('RIO BRILHANTE')) compId = 6;
              else if (upperName.includes('ITAPORA') || upperName.includes('ITAPORÃ')) compId = 7;
              else if (upperName.includes('NOVA ALVORADA')) compId = 4;
              else if (upperName.includes('DOURADINA') || upperName.includes('CD')) compId = 5;

              const city = company.municipio || company.cidade || company.emp_municipio || fallbackCities[compId] || '';
              const uf = company.uf || company.emp_uf || (city ? 'MS' : '');
              const isMatriz =
                compId === 5 ||
                compId === 1 ||
                upperName.includes('MATRIZ') ||
                upperName.includes('CENTRO DE DISTRIBUICAO') ||
                upperName.includes('CD ') ||
                upperName.startsWith('CD');

              const pendingCount =
                pendingTransfers[company.id] ||
                pendingTransfers[compId] ||
                pendingTransfers[String(compId)] ||
                0;

              return (
                <button
                  key={getCompanyKey(company)}
                  type="button"
                  className={`company-card glass company-card--${company.connectivity || 'online'}`}
                  onClick={() => handleSelectCompany(company)}
                >
                  <div className="company-card-left">
                    <div className="company-card-icon">
                      <Building2 size={22} aria-hidden="true" />
                    </div>
                    <div className="company-card-info">
                      <div className="company-card-title-row">
                        <span className="company-name">{rawName}</span>
                        <span className={`company-type-badge ${isMatriz ? 'matriz' : 'filial'}`}>
                          {isMatriz ? 'MATRIZ' : 'FILIAL'}
                        </span>
                        {city && (
                          <span className="company-city-badge">
                            {city}{uf ? ` - ${uf}` : ''}
                          </span>
                        )}
                      </div>
                      <div className="company-card-sub-row">
                        <span className="company-document">{formatCnpj(company.cnpj)}</span>
                        <span className={`company-status company-status--${company.connectivity || 'online'}`}>
                          <span className="status-dot"></span>
                          {company.connectivity === 'offline' ? 'Offline' : 'Online'}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="company-card-right">
                    {pendingCount > 0 && (
                      <span className="company-transfer-badge" title="Transferências em trânsito com destino a esta empresa">
                        <ArrowRightLeft size={12} aria-hidden="true" />
                        <span>{pendingCount} {pendingCount === 1 ? 'pendente' : 'pendentes'}</span>
                      </span>
                    )}
                    <div className="company-card-arrow">
                      <ArrowRight size={20} aria-hidden="true" />
                    </div>
                  </div>
                </button>
              );
            })}
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
              <div className="company-modal-header-left">
                <div className="company-modal-icon-badge">
                  <Link2 size={20} aria-hidden="true" />
                </div>
                <div>
                  <h2 id="company-link-modal-title">Vincular empresa ao cliente</h2>
                  <p className="company-modal-subtitle">Informe os dados da empresa para concluir o vínculo.</p>
                </div>
              </div>
              <button
                type="button"
                className="company-modal-close"
                onClick={handleCloseLinkModal}
                aria-label="Fechar vínculo de empresa"
                disabled={linkLoading}
              >
                <X size={18} aria-hidden="true" />
              </button>
            </div>

            <form className="company-link-form" onSubmit={handleLinkCompany}>
              {statusMsg.text && (
                <div className={`company-status-message ${statusMsg.type}`}>
                  {statusMsg.text}
                </div>
              )}

              <div className="company-form-group">
                <label htmlFor="company-cnpj">CNPJ da Empresa</label>
                <input
                  id="company-cnpj"
                  type="text"
                  className="company-input"
                  value={cnpj}
                  onChange={(event) => {
                    setCompanyCnpj(formatCnpj(event.target.value));
                    if (statusMsg.text) setStatusMsg({ text: '', type: '' });
                  }}
                  placeholder="00.000.000/0000-00"
                  required
                  autoFocus
                />
              </div>

              <div className="company-form-group">
                <label htmlFor="company-claim">Claim da Empresa</label>
                <input
                  id="company-claim"
                  type="text"
                  className="company-input"
                  value={claim}
                  onChange={(event) => {
                    setClaim(event.target.value);
                    if (statusMsg.text) setStatusMsg({ text: '', type: '' });
                  }}
                  placeholder="Claim exibido pela API Local"
                  required
                />
              </div>

              <div className="company-modal-footer">
                <div className="company-modal-shortcuts">
                  <span className="company-shortcut-item">
                    <kbd>ESC</kbd> Fechar
                  </span>
                </div>

                <button type="submit" className="btn-primary company-submit-btn" disabled={linkLoading}>
                  <PlugZap size={16} aria-hidden="true" />
                  <span>{linkLoading ? 'Vinculando...' : 'Vincular Empresa'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </main>
  );
}
