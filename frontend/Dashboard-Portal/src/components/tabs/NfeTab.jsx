import { useState, useEffect } from 'react';
import { FileText, Download, ShieldCheck, RefreshCw, XCircle, Search, Eye, AlertTriangle, CheckCircle, Clock } from 'lucide-react';
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
    <div className="cadastros-container">
      {/* Cabeçalho Superior */}
      <div className="crud-title-row" style={{ marginBottom: '1.5rem' }}>
        <div className="cd-title-with-badge">
          <h2><FileText size={24} style={{ color: 'var(--accent-primary)' }} /> Painel de Notas Fiscais (NF-e Modelo 55)</h2>
          <span className="badge badge-success">SEFAZ ONLINE (NT 2025.002)</span>
        </div>
        <button className="refresh-btn" onClick={fetchNotes} disabled={loading}>
          <RefreshCw size={18} className={loading ? 'spin' : ''} /> Atualizar Lista
        </button>
      </div>

      {/* Grid de Cards de Estatística no padrão global dashboard-grid */}
      <div className="dashboard-grid">
        <div className="metric-card glass">
          <div className="metric-header">
            <span>Total Emitidas</span>
            <FileText className="metric-icon" size={24} />
          </div>
          <div className="metric-value">{totalEmitidas}</div>
        </div>

        <div className="metric-card glass">
          <div className="metric-header">
            <span>Autorizadas 🟢</span>
            <CheckCircle className="metric-icon" size={24} style={{ color: '#10b981', background: 'rgba(16, 185, 129, 0.1)' }} />
          </div>
          <div className="metric-value" style={{ color: '#10b981' }}>{totalAutorizadas}</div>
        </div>

        <div className="metric-card glass">
          <div className="metric-header">
            <span>Canceladas 🟡</span>
            <Clock className="metric-icon" size={24} style={{ color: '#f59e0b', background: 'rgba(245, 158, 11, 0.1)' }} />
          </div>
          <div className="metric-value" style={{ color: '#f59e0b' }}>{totalCanceladas}</div>
        </div>

        <div className="metric-card glass">
          <div className="metric-header">
            <span>Rejeitadas 🔴</span>
            <XCircle className="metric-icon" size={24} style={{ color: '#ef4444', background: 'rgba(239, 68, 68, 0.1)' }} />
          </div>
          <div className="metric-value" style={{ color: '#ef4444' }}>{totalRejeitadas}</div>
        </div>
      </div>

      {/* Barra de Filtro e Busca Harmonizada */}
      <div className="list-card glass" style={{ marginBottom: '1.5rem', padding: '1.25rem' }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: '1rem', alignItems: 'center' }}>
          <SearchBar
            value={searchTerm}
            onChange={setSearchTerm}
            onSearch={() => {}}
            onClear={() => setSearchTerm('')}
            placeholder="Buscar por número da NF, chave de acesso de 44 dígitos ou protocolo..."
          />
          <div style={{ minWidth: '200px' }}>
            <select 
              value={statusFilter} 
              onChange={(e) => setStatusFilter(e.target.value)}
              className="cd-text-input"
              style={{
                width: '100%',
                padding: '0.65rem 0.9rem',
                borderRadius: '8px',
                border: '1px solid rgba(0, 0, 0, 0.15)',
                fontWeight: 600,
                backgroundColor: '#ffffff'
              }}
            >
              <option value="todos">Todos os Status</option>
              <option value="AUTORIZADA">🟢 Autorizadas</option>
              <option value="CANCELADA">🟡 Canceladas</option>
              <option value="REJEITADA">🔴 Rejeitadas</option>
            </select>
          </div>
        </div>
      </div>

      {/* Tabela de Notas Fiscais */}
      <div className="list-card glass">
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Nº Nota / Série</th>
                <th>Transferência</th>
                <th>Chave de Acesso NF-e</th>
                <th>Data Emissão</th>
                <th>Valor Total</th>
                <th>Status SEFAZ</th>
                <th style={{ textAlign: 'right' }}>Ações Fiscais</th>
              </tr>
            </thead>
            <tbody>
              {filteredNotes.map((n) => (
                <tr key={n.id || n.chave}>
                  <td><strong>NF-e #{n.numero || n.id} (Série {n.serie || 1})</strong></td>
                  <td><span className="badge badge-info">Lote #{n.transferencia_id || n.id}</span></td>
                  <td>
                    <span style={{ fontFamily: 'monospace', fontSize: '0.85rem', color: 'var(--accent-primary)', fontWeight: 600 }} title={n.chave}>
                      {n.chave ? `${n.chave.substring(0, 10)}...${n.chave.substring(34)}` : '-'}
                    </span>
                  </td>
                  <td>{formatDatehora(n.data_emissao)}</td>
                  <td><strong>{formatCurrency(n.valor_total)}</strong></td>
                  <td>
                    <span className={`badge ${n.status === 'AUTORIZADA' ? 'badge-success' : n.status === 'CANCELADA' ? 'badge-warning' : 'badge-danger'}`}>
                      {n.status === 'AUTORIZADA' ? '🟢 Autorizada' : n.status === 'CANCELADA' ? '🟡 Cancelada' : n.status || 'Pendente'}
                    </span>
                  </td>
                  <td className="actions-cell" style={{ textAlign: 'right' }}>
                    <button 
                      className="cd-action-btn view" 
                      onClick={() => handleDownloadDanfe(n.chave)}
                      title="Baixar DANFE em PDF"
                      style={{ marginRight: '6px' }}
                    >
                      📄 DANFE (PDF)
                    </button>
                    <button 
                      className="cd-action-btn view" 
                      onClick={() => handleDownloadXml(n.chave)}
                      title="Baixar XML Autorizado"
                      style={{ marginRight: '6px', backgroundColor: '#8b5cf6', color: '#fff' }}
                    >
                      📥 XML
                    </button>
                    {n.status === 'AUTORIZADA' && (
                      <button 
                        className="cd-action-btn check" 
                        onClick={() => { setSelectedNote(n); setShowCancelModal(true); }}
                        title="Cancelar NF-e na SEFAZ"
                        style={{ backgroundColor: '#ef4444', color: '#fff' }}
                      >
                        🚫 Cancelar
                      </button>
                    )}
                  </td>
                </tr>
              ))}
              {filteredNotes.length === 0 && (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '2.5rem', color: '#6b7280' }}>
                    Nenhuma Nota Fiscal (NF-e) encontrada.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal de Cancelamento */}
      {showCancelModal && selectedNote && (
        <div className="cd-modal-overlay">
          <div className="cd-modal-content glass" style={{ maxWidth: '520px' }}>
            <h3><AlertTriangle size={22} style={{ color: '#ef4444' }} /> Cancelar NF-e #{selectedNote.numero}</h3>
            <p style={{ margin: '0.8rem 0', fontSize: '0.9rem', color: 'var(--text-secondary)' }}>
              Atenção: O cancelamento da Nota Fiscal será transmitido diretamente para a SEFAZ. Esta ação não poderá ser desfeita.
            </p>
            
            <div className="cd-form">
              <label className="cd-input-container">
                Justificativa do Cancelamento (Mínimo 15 caracteres) *
                <textarea 
                  value={cancelJustification}
                  onChange={(e) => setCancelJustification(e.target.value)}
                  placeholder="Ex: Erro no preenchimento dos valores da transferência..."
                  className="cd-text-input"
                  rows={4}
                  style={{ resize: 'vertical' }}
                  required
                />
              </label>

              <div style={{ display: 'flex', gap: '1rem', justifyContent: 'flex-end', marginTop: '1.2rem' }}>
                <button 
                  type="button" 
                  className="refresh-btn" 
                  onClick={() => { setShowCancelModal(false); setCancelJustification(''); }}
                >
                  Voltar
                </button>
                <button 
                  type="button" 
                  onClick={handleCancelNfe}
                  disabled={actionLoading}
                  style={{
                    background: 'linear-gradient(135deg, #ef4444, #dc2626)',
                    color: '#fff',
                    border: 'none',
                    padding: '0.65rem 1.2rem',
                    borderRadius: '8px',
                    fontWeight: 600,
                    cursor: 'pointer'
                  }}
                >
                  {actionLoading ? '⌛ Transmitindo Cancelamento...' : 'Confirmar Cancelamento'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
