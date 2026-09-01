import React, { useState, useEffect } from 'react';
import { 
  FileCheck2, Search, Link2, Unlink, Printer, X, ChevronDown, ChevronRight, 
  AlertTriangle, CheckCircle, Package, ArrowRight, RefreshCw, Layers
} from 'lucide-react';
import { createApi } from '../services/api';
import { toast } from '../contexts/ToastContext';
import { formatCurrency } from '../utils/formatters';
import './ConciliacaoFiscalModal.css';

export default function ConciliacaoFiscalModal({ onClose }) {
  const api = createApi(true);

  const [loading, setLoading] = useState(false);
  const [data, setData] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('todos'); // 'todos', 'divergentes', 'alinhados'
  const [expandedKeys, setExpandedKeys] = useState({});

  // Modal para vincular produto rápido
  const [showLinkModal, setShowLinkModal] = useState(false);
  const [selectedMaster, setSelectedMaster] = useState(null);
  const [unlinkedProducts, setUnlinkedProducts] = useState([]);
  const [linkSearchTerm, setLinkSearchTerm] = useState('');
  const [linkingLoading, setLinkingLoading] = useState(false);

  useEffect(() => {
    fetchComparativo();
  }, []);

  // Atalho ESC
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape') {
        if (showLinkModal) {
          setShowLinkModal(false);
        } else if (onClose) {
          onClose();
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [showLinkModal, onClose]);

  const fetchComparativo = async () => {
    setLoading(true);
    try {
      const res = await api.get('/v1/conciliacao/comparativo');
      let items = [];
      if (Array.isArray(res.data)) items = res.data;
      else if (res.data?.data && Array.isArray(res.data.data)) items = res.data.data;
      setData(items);

      // Expande todos por padrão
      const exp = {};
      items.forEach(it => { exp[it.codigoFiscal] = true; });
      setExpandedKeys(exp);
    } catch (err) {
      console.error('Erro ao buscar comparativo fiscal:', err);
    } finally {
      setLoading(false);
    }
  };

  const toggleExpand = (masterCode) => {
    setExpandedKeys(prev => ({
      ...prev,
      [masterCode]: !prev[masterCode]
    }));
  };

  const handleOpenLinkModal = async (masterGroup) => {
    setSelectedMaster(masterGroup);
    setShowLinkModal(true);
    setLinkingLoading(true);
    try {
      // Busca produtos ativos
      const res = await api.get('/v1/produtos?limit=500');
      let prods = [];
      if (Array.isArray(res.data)) prods = res.data;
      else if (res.data?.data) prods = res.data.data;

      // Filtra produtos que ainda não possuem PRO_COD_FISCAL ou estão soltos
      setUnlinkedProducts(prods.filter(p => Number(p.codigo) !== Number(masterGroup.codigoFiscal)));
    } catch (err) {
      console.warn('Erro ao carregar produtos para vinculo:', err);
    } finally {
      setLinkingLoading(false);
    }
  };

  const handleLinkProduct = async (productCode) => {
    if (!selectedMaster) return;
    try {
      await api.post('/v1/conciliacao/vincular', {
        codigo: Number(productCode),
        codFiscal: Number(selectedMaster.codigoFiscal)
      });
      toast.success(`Produto #${productCode} vinculado ao fiscal #${selectedMaster.codigoFiscal} com sucesso!`);
      setShowLinkModal(false);
      fetchComparativo();
    } catch (err) {
      console.error(err);
      toast.error('Erro ao vincular produto.');
    }
  };

  const handleUnlinkProduct = async (productCode) => {
    if (!window.confirm(`Deseja desvincular o produto #${productCode} do produto fiscal?`)) return;
    try {
      await api.post('/v1/conciliacao/desvincular', { codigo: Number(productCode) });
      toast.success('Produto desvinculado com sucesso!');
      fetchComparativo();
    } catch (err) {
      console.error(err);
      toast.error('Erro ao desvincular produto.');
    }
  };

  // KPIs
  const totalFiscais = data.length;
  const totalEstoqueContabil = data.reduce((acc, it) => acc + (Number(it.estoqueContabil) || 0), 0);
  const totalEstoqueFisico = data.reduce((acc, it) => acc + (Number(it.totalEstoqueFisicoVinculados || it.estoqueFisicoTotal) || 0), 0);
  const totalDivergencias = data.filter(it => Math.abs(Number(it.diferencaEstoque || it.diferencaTotal) || 0) > 0.001).length;

  // Filtragem
  const filteredData = data.filter(it => {
    const term = searchTerm.toLowerCase();
    const matchesSearch = String(it.codigoFiscal).includes(term) || (it.nomeFiscal && it.nomeFiscal.toLowerCase().includes(term));
    
    const diff = Number(it.diferencaEstoque || it.diferencaTotal) || 0;
    const isDivergente = Math.abs(diff) > 0.001;

    if (!matchesSearch) return false;
    if (statusFilter === 'divergentes') return isDivergente;
    if (statusFilter === 'alinhados') return !isDivergente;
    return true;
  });

  return (
    <div className="conciliacao-overlay" onClick={(e) => { if (e.target === e.currentTarget && onClose) onClose(); }}>
      <div className="conciliacao-container glass conciliacao-print-area">
        
        {/* Header Padronizado */}
        <div className="conciliacao-header no-print">
          <div className="conciliacao-header-title">
            <div className="conciliacao-icon-badge">
              <FileCheck2 size={20} />
            </div>
            <div>
              <h3>Conciliação Fiscal de Produtos & Comparativo de Estoque</h3>
              <p>Mapeamento entre Produto Fiscal Mestre e Produtos Operacionais</p>
            </div>
          </div>
          
          <div className="conciliacao-header-actions">
            <button className="btn-secondary btn-print" onClick={() => window.print()} title="Imprimir Relatório A4">
              <Printer size={16} /> Imprimir A4
            </button>
            <button className="conciliacao-btn-close" onClick={onClose} title="Fechar (ESC)">
              <X size={20} />
            </button>
          </div>
        </div>

        {/* Corpo do Relatório */}
        <div className="conciliacao-body">
          
          {/* Cards de Métricas / KPIs */}
          <div className="conciliacao-kpis no-print">
            <div className="conciliacao-kpi-card highlight">
              <span className="kpi-label">Itens Fiscais Mestres</span>
              <div className="kpi-value">{totalFiscais}</div>
              <span className="kpi-sub">Cadastros centralizados</span>
            </div>
            <div className="conciliacao-kpi-card">
              <span className="kpi-label">Estoque Contábil (Fiscal)</span>
              <div className="kpi-value">{totalEstoqueContabil.toLocaleString('pt-BR')} <span className="kpi-unit">UN</span></div>
              <span className="kpi-sub">Saldo oficial tributário</span>
            </div>
            <div className="conciliacao-kpi-card">
              <span className="kpi-label">Estoque Físico (Vinculados)</span>
              <div className="kpi-value">{totalEstoqueFisico.toLocaleString('pt-BR')} <span className="kpi-unit">UN</span></div>
              <span className="kpi-sub">Soma das filiais e operacionais</span>
            </div>
            <div className={`conciliacao-kpi-card ${totalDivergencias > 0 ? 'danger' : 'success'}`}>
              <span className="kpi-label">Itens com Divergência</span>
              <div className="kpi-value">{totalDivergencias}</div>
              <span className="kpi-sub">{totalDivergencias > 0 ? 'Requer conferência física' : 'Auditoria 100% alinhada'}</span>
            </div>
          </div>

          {/* Filtros em Pílula e Busca */}
          <div className="conciliacao-filters-row no-print">
            <div className="conciliacao-search-box">
              <Search size={15} className="conciliacao-search-icon" />
              <input 
                type="text" 
                placeholder="Buscar por código ou descrição do produto fiscal..."
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
              />
              {searchTerm && (
                <button className="conciliacao-search-clear" onClick={() => setSearchTerm('')} title="Limpar">
                  <X size={14} />
                </button>
              )}
            </div>

            {/* Pílulas de Status */}
            <div className="conciliacao-filter-bar">
              <button 
                type="button" 
                className={`conciliacao-filter-btn ${statusFilter === 'todos' ? 'active todos' : ''}`}
                onClick={() => setStatusFilter('todos')}
              >
                Todos ({data.length})
              </button>
              <button 
                type="button" 
                className={`conciliacao-filter-btn ${statusFilter === 'divergentes' ? 'active divergentes' : ''}`}
                onClick={() => setStatusFilter('divergentes')}
              >
                Divergentes ({totalDivergencias})
              </button>
              <button 
                type="button" 
                className={`conciliacao-filter-btn ${statusFilter === 'alinhados' ? 'active alinhados' : ''}`}
                onClick={() => setStatusFilter('alinhados')}
              >
                Alinhados ({data.length - totalDivergencias})
              </button>
            </div>
          </div>

          {/* Tabela Comparativa Hierárquica */}
          <div className="conciliacao-table-wrapper">
            <table className="conciliacao-table">
              <thead>
                <tr>
                  <th style={{ width: '38px' }} className="no-print"></th>
                  <th style={{ width: '100px' }}>CÓD. FISCAL</th>
                  <th>DESCRIÇÃO DO PRODUTO FISCAL MESTRE</th>
                  <th style={{ width: '130px', textAlign: 'right' }}>ESTOQUE FISCAL</th>
                  <th style={{ width: '130px', textAlign: 'right' }}>ESTOQUE FÍSICO</th>
                  <th style={{ width: '120px', textAlign: 'right' }}>DIFERENÇA</th>
                  <th style={{ width: '120px', textAlign: 'center' }}>STATUS</th>
                  <th style={{ width: '110px', textAlign: 'center' }} className="no-print">AÇÕES</th>
                </tr>
              </thead>
              <tbody>
                {filteredData.map(group => {
                  const diff = Number(group.diferencaEstoque || group.diferencaTotal) || 0;
                  const isZero = Math.abs(diff) <= 0.001;
                  const isExp = expandedKeys[group.codigoFiscal];
                  const linkedItems = group.vinculados || group.itens || [];

                  return (
                    <React.Fragment key={group.codigoFiscal}>
                      {/* Linha Mestre */}
                      <tr className="master-row">
                        <td className="no-print" style={{ textAlign: 'center', cursor: 'pointer' }} onClick={() => toggleExpand(group.codigoFiscal)}>
                          {linkedItems.length > 0 ? (
                            <button className="conciliacao-expand-btn" type="button">
                              {isExp ? <ChevronDown size={15} /> : <ChevronRight size={15} />}
                            </button>
                          ) : (
                            <span style={{ color: '#cbd5e1' }}>•</span>
                          )}
                        </td>
                        <td>
                          <span className="conciliacao-badge fiscal">#{group.codigoFiscal}</span>
                        </td>
                        <td>
                          <span className="master-prod-name">{group.nomeFiscal || group.descFiscal}</span>
                          <span className="master-count-tag">
                            ({linkedItems.length} {linkedItems.length === 1 ? 'vinculado' : 'vinculados'})
                          </span>
                        </td>
                        <td style={{ textAlign: 'right', fontWeight: 800, color: 'var(--text-primary, #0b1c30)' }}>
                          {(Number(group.estoqueContabil) || 0).toLocaleString('pt-BR')}
                        </td>
                        <td style={{ textAlign: 'right', fontWeight: 700 }}>
                          {(Number(group.totalEstoqueFisicoVinculados || group.estoqueFisicoTotal) || 0).toLocaleString('pt-BR')}
                        </td>
                        <td style={{ textAlign: 'right', fontWeight: 800, color: isZero ? '#15803d' : '#b91c1c' }}>
                          {diff > 0 ? `+${diff.toLocaleString('pt-BR')}` : diff.toLocaleString('pt-BR')}
                        </td>
                        <td style={{ textAlign: 'center' }}>
                          <span className={`conciliacao-status-badge ${isZero ? 'alinhado' : 'divergente'}`}>
                            {isZero ? <><CheckCircle size={12} /> Alinhado</> : <><AlertTriangle size={12} /> Divergência</>}
                          </span>
                        </td>
                        <td style={{ textAlign: 'center' }} className="no-print">
                          <button 
                            type="button" 
                            className="btn-vincular-fiscal"
                            onClick={() => handleOpenLinkModal(group)}
                            title="Vincular Produto Operacional a este Fiscal"
                          >
                            <Link2 size={13} /> Vincular
                          </button>
                        </td>
                      </tr>

                      {/* Linhas dos Itens Vinculados (Detalhe) */}
                      {isExp && linkedItems.map((item, idx) => (
                        <tr key={idx} className="linked-row">
                          <td className="no-print"></td>
                          <td className="linked-code-cell">
                            <span className="linked-branch-icon">↳</span> #{item.codigo}
                          </td>
                          <td className="linked-name-cell">
                            <span className="linked-name">{item.nome}</span>
                            {item.codbarra && (
                              <span className="linked-ean-badge">
                                EAN: {item.codbarra}
                              </span>
                            )}
                          </td>
                          <td style={{ textAlign: 'right', color: '#94a3b8' }}>-</td>
                          <td style={{ textAlign: 'right', color: '#334155', fontWeight: 600 }}>
                            {(Number(item.estoqueFisico) || 0).toLocaleString('pt-BR')}
                          </td>
                          <td style={{ textAlign: 'right', color: '#94a3b8' }}>-</td>
                          <td style={{ textAlign: 'center' }}>
                            <span className="conciliacao-badge non-fiscal">
                              {item.fiscalGerar === 'S' ? 'Saída Fiscal' : 'Interno'}
                            </span>
                          </td>
                          <td style={{ textAlign: 'center' }} className="no-print">
                            {Number(item.codigo) !== Number(group.codigoFiscal) && (
                              <button 
                                type="button" 
                                className="btn-conciliacao-unlink"
                                onClick={() => handleUnlinkProduct(item.codigo)}
                                title="Desvincular deste Produto Fiscal"
                              >
                                <Unlink size={13} />
                              </button>
                            )}
                          </td>
                        </tr>
                      ))}
                    </React.Fragment>
                  );
                })}

                {filteredData.length === 0 && (
                  <tr>
                    <td colSpan="8" className="conciliacao-empty-state">
                      {loading ? 'Carregando comparativo fiscal...' : 'Nenhum produto fiscal encontrado.'}
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

        </div>

        {/* Rodapé */}
        <div className="conciliacao-footer no-print">
          <div className="conciliacao-shortcuts">
            <span className="conciliacao-shortcut-item"><kbd>ESC</kbd> Fechar</span>
            <span className="conciliacao-count-summary">
              Total de {filteredData.length} grupos fiscais auditados
            </span>
          </div>
          <button className="btn-conciliacao-close" onClick={onClose}>
            Fechar
          </button>
        </div>

      </div>

      {/* MODAL DE VÍNCULO RÁPIDO */}
      {showLinkModal && selectedMaster && (
        <div className="conciliacao-overlay quick-link-overlay" onClick={(e) => { if (e.target === e.currentTarget) setShowLinkModal(false); }}>
          <div className="conciliacao-container quick-link-container glass">
            <div className="conciliacao-header">
              <div className="conciliacao-header-title">
                <div className="conciliacao-icon-badge">
                  <Link2 size={20} />
                </div>
                <div>
                  <h3>Vincular Produto Operacional</h3>
                  <p>Mestre Fiscal: #{selectedMaster.codigoFiscal} - {selectedMaster.nomeFiscal}</p>
                </div>
              </div>
              <button className="conciliacao-btn-close" onClick={() => setShowLinkModal(false)} title="Fechar">
                <X size={18} />
              </button>
            </div>

            <div className="conciliacao-body quick-link-body">
              <div className="conciliacao-search-box">
                <Search size={15} className="conciliacao-search-icon" />
                <input 
                  type="text" 
                  placeholder="Pesquisar produto operacional por código ou nome..."
                  value={linkSearchTerm}
                  onChange={e => setLinkSearchTerm(e.target.value)}
                  autoFocus
                />
                {linkSearchTerm && (
                  <button className="conciliacao-search-clear" onClick={() => setLinkSearchTerm('')} title="Limpar">
                    <X size={14} />
                  </button>
                )}
              </div>

              <div className="quick-link-table-wrap">
                <table className="conciliacao-table">
                  <thead>
                    <tr>
                      <th style={{ width: '80px' }}>CÓD</th>
                      <th>DESCRIÇÃO DO PRODUTO</th>
                      <th style={{ width: '100px', textAlign: 'right' }}>ESTOQUE</th>
                      <th style={{ width: '110px', textAlign: 'center' }}>AÇÃO</th>
                    </tr>
                  </thead>
                  <tbody>
                    {unlinkedProducts
                      .filter(p => {
                        const term = linkSearchTerm.toLowerCase();
                        return String(p.codigo).includes(term) || (p.nome && p.nome.toLowerCase().includes(term));
                      })
                      .slice(0, 50)
                      .map(prod => (
                        <tr key={prod.codigo} className="quick-link-row">
                          <td><span className="conciliacao-badge fiscal">#{prod.codigo}</span></td>
                          <td style={{ fontWeight: 500 }}>{prod.nome}</td>
                          <td style={{ textAlign: 'right', fontWeight: 700 }}>{prod.quantidade || 0}</td>
                          <td style={{ textAlign: 'center' }}>
                            <button 
                              type="button" 
                              className="btn-primary btn-quick-link"
                              onClick={() => handleLinkProduct(prod.codigo)}
                            >
                              + Vincular
                            </button>
                          </td>
                        </tr>
                      ))}
                    {unlinkedProducts.length === 0 && (
                      <tr>
                        <td colSpan="4" className="conciliacao-empty-state">
                          {linkingLoading ? 'Carregando produtos...' : 'Nenhum produto disponível para vínculo.'}
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="conciliacao-footer">
              <span style={{ fontSize: '0.78rem', color: '#64748b' }}>
                Exibindo até 50 itens compatíveis
              </span>
              <button className="btn-conciliacao-close" onClick={() => setShowLinkModal(false)}>
                Cancelar
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
