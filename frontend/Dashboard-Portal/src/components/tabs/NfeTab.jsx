import { useState, useEffect } from 'react';
import { 
  FileText, Download, ShieldCheck, RefreshCw, 
  XCircle, Search, Eye, AlertTriangle, CheckCircle, Clock, X 
} from 'lucide-react';
import { createApi } from '../../services/api';
import { formatCurrency, formatDatehora } from '../../utils/formatters';
import SearchBar from '../SearchBar';
import './CadastrosTab.css';
import '../../pages/Dashboard.css';

export default function NfeTab() {
  const api = createApi(true); // CD_API_BASE (port 9000)
  const [loading, setLoading] = useState(false);
  const [notes, setNotes] = useState([]);
  const [statusFilter, setStatusFilter] = useState('todos');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedNote, setSelectedNote] = useState(null);
  const [showCancelModal, setShowCancelModal] = useState(false);
  const [cancelJustification, setCancelJustification] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    fetchNotes();
  }, []);

  // Atalho para fechar modal com ESC
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape' && showCancelModal) {
        setShowCancelModal(false);
        setCancelJustification('');
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [showCancelModal]);

  const fetchNotes = async () => {
    setLoading(true);
    try {
      const res = await api.get('/v1/nfe/listar');
      if (res.data && Array.isArray(res.data.data)) {
        setNotes(res.data.data);
      } else if (Array.isArray(res.data)) {
        setNotes(res.data);
      }
    } catch (err) {
      console.error('Erro ao buscar NF-es:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleDownloadDanfe = async (chave) => {
    try {
      const res = await api.get(`/v1/nfe/${chave}/danfe`);
      if (res.data?.pdf_base64) {
        const link = document.createElement('a');
        link.href = `data:application/pdf;base64,${res.data.pdf_base64}`;
        link.download = `DANFE_${chave}.pdf`;
        link.click();
      } else {
        alert('Conteúdo do DANFE em PDF obtido com sucesso!');
      }
    } catch (err) {
      console.error('Erro ao baixar DANFE:', err);
      alert('Erro ao obter o DANFE (PDF) para a chave informada.');
    }
  };

  const handleDownloadXml = async (chave) => {
    try {
      const res = await api.get(`/v1/nfe/${chave}/xml`);
      if (res.data?.xml) {
        const blob = new Blob([res.data.xml], { type: 'application/xml' });
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = `NFE_${chave}.xml`;
        link.click();
      } else {
        alert('XML da NF-e obtido com sucesso!');
      }
    } catch (err) {
      console.error('Erro ao baixar XML:', err);
      alert('Erro ao obter o XML para a chave informada.');
    }
  };

  const handleCancelNfe = async () => {
    if (!cancelJustification || cancelJustification.trim().length < 15) {
      alert('A justificativa de cancelamento deve ter pelo menos 15 caracteres.');
      return;
    }
    setActionLoading(true);
    try {
      await api.post(`/v1/nfe/${selectedNote.chave}/cancelar`, {
        protocolo: selectedNote.protocolo,
        justificativa: cancelJustification
      });
      alert(`NF-e #${selectedNote.numero} cancelada com sucesso!`);
      setShowCancelModal(false);
      setCancelJustification('');
      fetchNotes();
    } catch (err) {
      console.error('Erro ao cancelar NF-e:', err);
      alert('Falha ao cancelar NF-e. Verifique se o documento está dentro do prazo SEFAZ.');
    } finally {
      setActionLoading(false);
    }
  };

  const filteredNotes = notes.filter(n => {
    const matchesStatus = statusFilter === 'todos' || (n.status && n.status.toUpperCase() === statusFilter.toUpperCase());
    const term = searchTerm.toLowerCase().trim();
    const matchesSearch = !term || 
      (n.chave && n.chave.toLowerCase().includes(term)) ||
      (n.numero && String(n.numero).includes(term)) ||
      (n.protocolo && n.protocolo.toLowerCase().includes(term));
    return matchesStatus && matchesSearch;
  });

  const totalEmitidas = notes.length;
  const totalAutorizadas = notes.filter(n => n.status === 'AUTORIZADA').length;
  const totalCanceladas = notes.filter(n => n.status === 'CANCELADA').length;
  const totalRejeitadas = notes.filter(n => n.status === 'REJEITADA').length;

  return (
    <div className="crud-container">
      {/* Cabeçalho Superior */}
      <div className="crud-title-row">
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap' }}>
          <h2 style={{ fontSize: '1.4rem', fontWeight: 700, margin: 0, display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-primary)' }}>
            <FileText size={24} style={{ color: 'var(--accent)' }} /> 
            Painel de Notas Fiscais (NF-e Modelo 55)
          </h2>
          <span className="badge badge-success" style={{ letterSpacing: '0.5px' }}>
            SEFAZ ONLINE (NT 2025.002)
          </span>
        </div>
        <button 
          className="btn-secondary" 
          onClick={fetchNotes} 
          disabled={loading}
          style={{ height: '38px', padding: '0 1rem' }}
        >
          <RefreshCw size={16} className={loading ? 'spin' : ''} /> 
          Atualizar Lista
        </button>
      </div>

      {/* Grid de Cards de Métricas */}
      <div className="dashboard-grid" style={{ marginBottom: '1rem' }}>
        <div className="metric-card glass">
          <div className="metric-header">
            <span>Total Emitidas</span>
            <FileText className="metric-icon" size={20} />
          </div>
          <div className="metric-value">{totalEmitidas}</div>
        </div>

        <div className="metric-card glass credits-metric-card">
          <div className="metric-header">
            <span>Autorizadas</span>
            <CheckCircle className="metric-icon" size={20} />
          </div>
          <div className="metric-value">{totalAutorizadas}</div>
        </div>

        <div className="metric-card glass" style={{ borderColor: 'rgba(249, 115, 22, 0.3)' }}>
          <div className="metric-header">
            <span>Canceladas</span>
            <Clock className="metric-icon" size={20} />
          </div>
          <div className="metric-value" style={{ color: 'var(--accent)' }}>{totalCanceladas}</div>
        </div>

        <div className="metric-card glass debits-metric-card">
          <div className="metric-header">
            <span>Rejeitadas</span>
            <XCircle className="metric-icon" size={20} />
          </div>
          <div className="metric-value">{totalRejeitadas}</div>
        </div>
      </div>

      {/* Card Principal com Filtros em Pílula e Tabela */}
      <div className="list-card glass full-width">
        {/* Barra de Filtros em Pílula */}
        <div className="filter-bar" style={{ marginBottom: '1rem' }}>
          <button 
            type="button" 
            className={`filter-btn ${statusFilter === 'todos' ? 'active' : ''}`}
            onClick={() => setStatusFilter('todos')}
          >
            Todas ({totalEmitidas})
          </button>
          <button 
            type="button" 
            className={`filter-btn filter-pago ${statusFilter === 'AUTORIZADA' ? 'active' : ''}`}
            onClick={() => setStatusFilter('AUTORIZADA')}
          >
            Autorizadas ({totalAutorizadas})
          </button>
          <button 
            type="button" 
            className={`filter-btn filter-warning ${statusFilter === 'CANCELADA' ? 'active' : ''}`}
            onClick={() => setStatusFilter('CANCELADA')}
          >
            Canceladas ({totalCanceladas})
          </button>
          <button 
            type="button" 
            className={`filter-btn filter-aberto ${statusFilter === 'REJEITADA' ? 'active' : ''}`}
            onClick={() => setStatusFilter('REJEITADA')}
          >
            Rejeitadas ({totalRejeitadas})
          </button>
        </div>

        {/* Campo de Busca */}
        <SearchBar
          value={searchTerm}
          onChange={setSearchTerm}
          onSearch={() => {}}
          onClear={() => setSearchTerm('')}
          placeholder="Buscar por número da NF, chave de acesso de 44 dígitos ou protocolo..."
        />

        {/* Tabela Responsiva de NF-e */}
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th scope="col">Nº Nota / Série</th>
                <th scope="col">Transferência</th>
                <th scope="col">Chave de Acesso NF-e</th>
                <th scope="col">Data Emissão</th>
                <th scope="col">Valor Total</th>
                <th scope="col">Status SEFAZ</th>
                <th scope="col" style={{ textAlign: 'right' }}>Ações Fiscais</th>
              </tr>
            </thead>
            <tbody>
              {filteredNotes.map((n) => (
                <tr key={n.id || n.chave}>
                  <td data-label="Nº Nota / Série">
                    <span className="item-code">
                      NF-e #{n.numero || n.id} {n.serie ? `(Série ${n.serie})` : ''}
                    </span>
                  </td>
                  <td data-label="Transferência">
                    <span className="badge badge-info">
                      Lote #{n.transferencia_id || n.id}
                    </span>
                  </td>
                  <td data-label="Chave de Acesso NF-e">
                    <span className="item-code" title={n.chave} style={{ fontSize: '0.8rem' }}>
                      {n.chave ? `${n.chave.substring(0, 10)}...${n.chave.substring(34)}` : '-'}
                    </span>
                  </td>
                  <td data-label="Data Emissão">{formatDatehora(n.data_emissao)}</td>
                  <td data-label="Valor Total" style={{ fontWeight: 600 }}>
                    {formatCurrency(n.valor_total)}
                  </td>
                  <td data-label="Status SEFAZ">
                    <span className={`badge ${
                      n.status === 'AUTORIZADA' 
                        ? 'badge-success' 
                        : n.status === 'CANCELADA' 
                        ? 'badge-warning' 
                        : n.status === 'REJEITADA' 
                        ? 'badge-danger' 
                        : 'badge-info'
                    }`}>
                      {n.status === 'AUTORIZADA' ? 'Autorizada' : n.status === 'CANCELADA' ? 'Cancelada' : n.status === 'REJEITADA' ? 'Rejeitada' : (n.status || 'Pendente')}
                    </span>
                  </td>
                  <td data-label="Ações Fiscais" className="actions-cell" style={{ justifyContent: 'flex-end' }}>
                    <button 
                      className="action-btn" 
                      onClick={() => handleDownloadDanfe(n.chave)}
                      title="Baixar DANFE em PDF"
                      aria-label="Baixar DANFE em PDF"
                      style={{ gap: '5px', fontSize: '0.82rem', padding: '6px 12px' }}
                    >
                      <FileText size={15} /> DANFE (PDF)
                    </button>
                    <button 
                      className="action-btn" 
                      onClick={() => handleDownloadXml(n.chave)}
                      title="Baixar XML Autorizado"
                      aria-label="Baixar XML Autorizado"
                      style={{ gap: '5px', fontSize: '0.82rem', padding: '6px 12px' }}
                    >
                      <Download size={15} /> XML
                    </button>
                    {n.status === 'AUTORIZADA' && (
                      <button 
                        className="action-btn" 
                        onClick={() => { setSelectedNote(n); setShowCancelModal(true); }}
                        title="Cancelar NF-e na SEFAZ"
                        aria-label="Cancelar NF-e na SEFAZ"
                        style={{ 
                          gap: '5px', 
                          fontSize: '0.82rem', 
                          padding: '6px 12px',
                          color: '#ba1a1a', 
                          background: 'rgba(186, 26, 26, 0.08)' 
                        }}
                      >
                        <XCircle size={15} /> Cancelar
                      </button>
                    )}
                  </td>
                </tr>
              ))}
              {filteredNotes.length === 0 && (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '2.5rem', color: 'var(--text-secondary)' }}>
                    Nenhuma Nota Fiscal (NF-e) encontrada.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Institucional de Cancelamento com Glassmorphism */}
      {showCancelModal && selectedNote && (
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) { setShowCancelModal(false); setCancelJustification(''); } }}>
          <div className="modal-content glass" style={{ maxWidth: '520px' }}>
            <div className="modal-header">
              <h4 style={{ color: 'var(--danger, #ba1a1a)' }}>
                <AlertTriangle size={20} style={{ color: 'var(--danger, #ba1a1a)' }} /> 
                Cancelar NF-e #{selectedNote.numero}
              </h4>
              <button 
                className="btn-close" 
                onClick={() => { setShowCancelModal(false); setCancelJustification(''); }}
                aria-label="Fechar"
              >
                <X size={18} />
              </button>
            </div>
            
            <div className="modal-body" style={{ padding: '1rem 0' }}>
              <p style={{ margin: '0 0 1rem 0', fontSize: '0.9rem', color: 'var(--text-secondary)', lineHeight: 1.5 }}>
                Atenção: O cancelamento da Nota Fiscal será transmitido diretamente para a SEFAZ. Esta ação não poderá ser desfeita.
              </p>
              
              <div className="crud-input">
                <label style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                  <span>Justificativa do Cancelamento (Mínimo 15 caracteres) *</span>
                  <textarea 
                    value={cancelJustification}
                    onChange={(e) => setCancelJustification(e.target.value)}
                    placeholder="Ex: Erro no preenchimento dos valores da transferência..."
                    rows={4}
                    style={{ 
                      width: '100%',
                      padding: '0.75rem',
                      borderRadius: '0.65rem',
                      border: '1px solid rgba(0, 0, 0, 0.12)',
                      background: 'var(--bg-secondary, #ffffff)',
                      color: 'var(--text-primary)',
                      fontFamily: 'inherit',
                      fontSize: '0.9rem',
                      resize: 'vertical'
                    }}
                    required
                  />
                </label>
              </div>
            </div>

            <div className="modal-footer" style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end', borderTop: '1px solid rgba(0,0,0,0.08)', paddingTop: '1rem' }}>
              <button 
                type="button" 
                className="btn-secondary" 
                onClick={() => { setShowCancelModal(false); setCancelJustification(''); }}
              >
                Fechar <kbd style={{ marginLeft: '4px', fontSize: '0.75rem', padding: '1px 4px', borderRadius: '3px', background: 'rgba(0,0,0,0.08)' }}>ESC</kbd>
              </button>
              <button 
                type="button" 
                onClick={handleCancelNfe}
                disabled={actionLoading}
                className="btn-primary"
                style={{
                  background: 'linear-gradient(135deg, #ba1a1a 0%, #93000a 100%)',
                  boxShadow: '0 4px 12px rgba(186, 26, 26, 0.25)'
                }}
              >
                {actionLoading ? 'Transmitindo Cancelamento...' : 'Confirmar Cancelamento'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
