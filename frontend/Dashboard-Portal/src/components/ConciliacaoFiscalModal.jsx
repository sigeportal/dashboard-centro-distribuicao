import React, { useState, useEffect } from 'react';
import { 
  FileCheck2, Search, Link2, Unlink, Printer, X, ChevronDown, ChevronRight, 
  AlertTriangle, CheckCircle, Package, ArrowRight, RefreshCw, Layers
} from 'lucide-react';
import { createApi } from '../services/api';
import { formatCurrency } from '../utils/formatters';
import './ConciliacaoFiscalModal.css';

export default function ConciliacaoFiscalModal({ onClose }) {
  const api = createApi(true);

  const [loading, setLoading] = useState(false);
  const [data, setData] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('todos'); // 'todos', 'divergentes', 'alinhados', 'sem_vinculo'
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
      alert(`Produto #${productCode} vinculado ao fiscal #${selectedMaster.codigoFiscal} com sucesso!`);
      setShowLinkModal(false);
      fetchComparativo();
    } catch (err) {
      console.error(err);
      alert('Erro ao vincular produto.');
    }
  };

  const handleUnlinkProduct = async (productCode) => {
    if (!window.confirm(`Deseja desvincular o produto #${productCode} do produto fiscal?`)) return;
    try {
      await api.post('/v1/conciliacao/desvincular', { codigo: Number(productCode) });
      alert('Produto desvinculado com sucesso!');
      fetchComparativo();
    } catch (err) {
      console.error(err);
      alert('Erro ao desvincular produto.');
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
    <div className="conciliacao-overlay">
      <div className="conciliacao-container conciliacao-print-area">
        
        {/* Header */}
        <div className="conciliacao-header no-print">
          <div className="conciliacao-header-title">
            <FileCheck2 size={24} color="#2563eb" />
            <div>
              <h3>Conciliação Fiscal de Produtos & Comparativo de Estoque</h3>
              <p>Mapeamento entre Produto Fiscal Mestre (PRO_COD_FISCAL) e Produtos Operacionais (Madenorte & PDV_NOVO)</p>
            </div>
          </div>
          
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <button className="btn-conciliacao print" onClick={() => window.print()} title="Imprimir Relatório A4">
              <Printer size={15} /> Imprimir A4
            </button>
            <button className="btn-conciliacao close" onClick={onClose} title="Fechar (ESC)">
              <X size={18} />
            </button>
          </div>
        </div>

        {/* Corpo do Relatório */}
        <div className="conciliacao-body">
          
          {/* Cards de Métricas / KPIs */}
          <div className="conciliacao-kpis no-print">
            <div className="conciliacao-kpi-card highlight">
              <label>Itens Fiscais Mestres</label>
              <div className="kpi-value">{totalFiscais}</div>
            </div>
            <div className="conciliacao-kpi-card">
              <label>Estoque Contábil (Fiscal)</label>
              <div className="kpi-value">{totalEstoqueContabil.toLocaleString('pt-BR')} un</div>
            </div>
            <div className="conciliacao-kpi-card">
              <label>Estoque Físico (Vinculados)</label>
              <div className="kpi-value">{totalEstoqueFisico.toLocaleString('pt-BR')} un</div>
            </div>
            <div className={`conciliacao-kpi-card ${totalDivergencias > 0 ? 'danger' : 'success'}`}>
              <label>Itens com Divergência</label>
              <div className="kpi-value">{totalDivergencias}</div>
            </div>
          </div>

          {/* Filtros e Busca */}
          <div className="conciliacao-filters no-print">
            <div className="conciliacao-search-box">
              <Search size={16} />
              <input 
                type="text" 
                placeholder="Buscar por código ou nome do produto fiscal..."
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
              />
            </div>

            <div style={{ display: 'flex', gap: '6px' }}>
              <button 
                type="button" 
                className={`btn-conciliacao ${statusFilter === 'todos' ? 'print' : 'close'}`}
                onClick={() => setStatusFilter('todos')}
              >
                Todos ({data.length})
              </button>
              <button 
                type="button" 
                className={`btn-conciliacao ${statusFilter === 'divergentes' ? 'print' : 'close'}`}
                onClick={() => setStatusFilter('divergentes')}
              >
                Divergentes ({totalDivergencias})
              </button>
              <button 
                type="button" 
                className={`btn-conciliacao ${statusFilter === 'alinhados' ? 'print' : 'close'}`}
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
                  <th style={{ width: '40px' }} className="no-print"></th>
                  <th style={{ width: '100px' }}>CÓD. FISCAL</th>
                  <th>DESCRIÇÃO DO PRODUTO FISCAL MESTRE</th>
                  <th style={{ width: '130px', textAlign: 'right' }}>ESTOQUE FISCAL</th>
                  <th style={{ width: '130px', textAlign: 'right' }}>ESTOQUE FÍSICO</th>
                  <th style={{ width: '120px', textAlign: 'right' }}>DIFERENÇA</th>
                  <th style={{ width: '100px', textAlign: 'center' }}>STATUS</th>
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
                            isExp ? <ChevronDown size={16} /> : <ChevronRight size={16} />
                          ) : '-'}
                        </td>
                        <td>
                          <span className="conciliacao-badge fiscal">#{group.codigoFiscal}</span>
                        </td>
                        <td>
                          <strong>{group.nomeFiscal || group.descFiscal}</strong>
                          <span style={{ fontSize: '0.72rem', color: '#64748b', marginLeft: '6px' }}>
                            ({linkedItems.length} {linkedItems.length === 1 ? 'item vinculado' : 'itens vinculados'})
                          </span>
                        </td>
                        <td style={{ textAlign: 'right', fontWeight: 800, color: '#1d4ed8' }}>
                          {(Number(group.estoqueContabil) || 0).toLocaleString('pt-BR')}
                        </td>
                        <td style={{ textAlign: 'right', fontWeight: 700 }}>
                          {(Number(group.totalEstoqueFisicoVinculados || group.estoqueFisicoTotal) || 0).toLocaleString('pt-BR')}
                        </td>
                        <td style={{ textAlign: 'right', fontWeight: 800, color: isZero ? '#15803d' : '#b91c1c' }}>
                          {diff > 0 ? `+${diff.toLocaleString('pt-BR')}` : diff.toLocaleString('pt-BR')}
                        </td>
                        <td style={{ textAlign: 'center' }}>
                          <span className={`conciliacao-badge ${isZero ? 'diff-zero' : 'diff-warn'}`}>
                            {isZero ? <><CheckCircle size={12} /> Alinhado</> : <><AlertTriangle size={12} /> Divergência</>}
                          </span>
                        </td>
                        <td style={{ textAlign: 'center' }} className="no-print">
                          <button 
                            type="button" 
                            className="btn-conciliacao link"
                            style={{ padding: '3px 8px', fontSize: '0.72rem' }}
                            onClick={() => handleOpenLinkModal(group)}
                            title="Vincular Produto Operacional a este Fiscal"
                          >
                            <Link2 size={12} /> Vincular
                          </button>
                        </td>
                      </tr>

                      {/* Linhas dos Itens Vinculados (Detalhe) */}
                      {isExp && linkedItems.map((item, idx) => (
                        <tr key={idx} className="linked-row">
                          <td className="no-print"></td>
                          <td style={{ paddingLeft: '1.5rem', color: '#64748b' }}>
                            ↳ #{item.codigo}
                          </td>
                          <td style={{ paddingLeft: '1.5rem' }}>
                            <span style={{ color: '#0f172a' }}>{item.nome}</span>
                            {item.codbarra && (
                              <span style={{ fontSize: '0.7rem', color: '#94a3b8', marginLeft: '6px', fontFamily: 'monospace' }}>
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
                              {item.fiscalGerar === 'S' ? '📄 Saída Fiscal' : '📦 Interno'}
                            </span>
                          </td>
                          <td style={{ textAlign: 'center' }} className="no-print">
                            {Number(item.codigo) !== Number(group.codigoFiscal) && (
                              <button 
                                type="button" 
                                style={{ background: 'transparent', border: 'none', color: '#ef4444', cursor: 'pointer' }}
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
                    <td colSpan="8" style={{ textAlign: 'center', padding: '2rem', color: '#64748b' }}>
                      Nenhum produto fiscal encontrado.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

        </div>

        {/* Rodapé */}
        <div className="conciliacao-footer no-print">
          <span style={{ fontSize: '0.8rem', color: '#64748b' }}>
            Total de {filteredData.length} grupos fiscais auditados
          </span>
          <button className="btn-conciliacao close" onClick={onClose}>
            Fechar
          </button>
        </div>

      </div>

      {/* MODAL DE VÍNCULO RÁPIDO */}
      {showLinkModal && selectedMaster && (
        <div className="conciliacao-overlay" style={{ zIndex: 1300 }}>
          <div className="conciliacao-container" style={{ maxWidth: '600px', maxHeight: '75vh' }}>
            <div className="conciliacao-header">
              <div className="conciliacao-header-title">
                <Link2 size={20} color="#059669" />
                <div>
                  <h4 style={{ margin: 0 }}>Vincular ao Produto Fiscal #{selectedMaster.codigoFiscal}</h4>
                  <p style={{ margin: 0, fontSize: '0.75rem', color: '#64748b' }}>{selectedMaster.nomeFiscal}</p>
                </div>
              </div>
              <button className="btn-conciliacao close" onClick={() => setShowLinkModal(false)}>
                <X size={16} />
              </button>
            </div>

            <div className="conciliacao-body">
              <div className="conciliacao-search-box">
                <Search size={16} />
                <input 
                  type="text" 
                  placeholder="Pesquisar produto operacional para vincular..."
                  value={linkSearchTerm}
                  onChange={e => setLinkSearchTerm(e.target.value)}
                />
              </div>

              <div style={{ maxHeight: '350px', overflowY: 'auto' }}>
                <table className="conciliacao-table">
                  <thead>
                    <tr>
                      <th>CÓD</th>
                      <th>PRODUTO OPERACIONAL</th>
                      <th style={{ textAlign: 'right' }}>ESTOQUE</th>
                      <th style={{ textAlign: 'center' }}>VINCULAR</th>
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
                        <tr key={prod.codigo}>
                          <td><strong>#{prod.codigo}</strong></td>
                          <td>{prod.nome}</td>
                          <td style={{ textAlign: 'right' }}>{prod.quantidade || 0}</td>
                          <td style={{ textAlign: 'center' }}>
                            <button 
                              type="button" 
                              className="btn-conciliacao link"
                              style={{ padding: '3px 8px', fontSize: '0.72rem' }}
                              onClick={() => handleLinkProduct(prod.codigo)}
                            >
                              + Vincular
                            </button>
                          </td>
                        </tr>
                      ))}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="conciliacao-footer">
              <button className="btn-conciliacao close" onClick={() => setShowLinkModal(false)}>
                Cancelar
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
