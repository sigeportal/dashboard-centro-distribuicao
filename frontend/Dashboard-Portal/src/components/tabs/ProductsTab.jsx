import { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Package, Eye, X, Building2, History } from 'lucide-react';
import SearchBar from '../SearchBar';
import Pagination from '../Pagination';
import { formatCurrency } from '../../utils/formatters';
import { createApi } from '../../services/api';

export default function ProductsTab({ data, pages, searchTerms, setSearchTerms, prodFilter, setProdFilter, getFilteredData, handleSearchClick, handleClearSearch, fetchPage }) {
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [unitStocks, setUnitStocks] = useState([]);
  const [loadingStocks, setLoadingStocks] = useState(false);

  // Histórico de Movimentações (HIS_PRO)
  const [selectedHistoryProduct, setSelectedHistoryProduct] = useState(null);
  const [historyData, setHistoryData] = useState([]);
  const [loadingHistory, setLoadingHistory] = useState(false);

  // Saldo de Estoque Específico da Unidade Logada
  const [activeUnitStocks, setActiveUnitStocks] = useState({});
  const activeUnitId = Number(localStorage.getItem('selected_company_id')) || 1;
  const activeUnitName = localStorage.getItem('selected_company_name') || (activeUnitId === 1 ? 'CD DOURADINA' : `Unidade #${activeUnitId}`);
  const isMatriz = activeUnitId === 1 || activeUnitName.toUpperCase().includes('CD') || activeUnitName.toUpperCase().includes('DOURADINA');

  const api = createApi(true);

  useEffect(() => {
    fetchActiveUnitStocks();
  }, [activeUnitId]);

  const fetchActiveUnitStocks = async () => {
    try {
      const res = await api.get('/v1/estoque/posicao');
      let dataArr = [];
      if (Array.isArray(res.data)) dataArr = res.data;
      else if (res.data?.data && Array.isArray(res.data.data)) dataArr = res.data.data;

      const map = {};
      dataArr.forEach(st => {
        if (Number(st.empresa_id) === activeUnitId) {
          map[st.pro_codigo] = Number(st.quantidade) || 0;
        }
      });
      setActiveUnitStocks(map);
    } catch (err) {
      console.warn('Erro ao buscar saldos de estoque da unidade ativa:', err);
    }
  };

  const getProductStockForActiveUnit = (item) => {
    const prodId = item.codigo || item.id || item.pro_codigo;
    if (activeUnitStocks[prodId] !== undefined) {
      return activeUnitStocks[prodId];
    }
    if (isMatriz) {
      return Number(item.quantidade) || 0;
    }
    return 0;
  };

  // Formata datas para pt-BR e fuso horário UTC-4 (Mato Grosso do Sul / Campo Grande)
  const formatDatePtBr = (dateStr) => {
    if (!dateStr || dateStr === 'Recentemente' || dateStr === 'Atualizado') return dateStr;
    try {
      const regex = /^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2}):(\d{2}))?/;
      const match = String(dateStr).match(regex);
      if (match) {
        const [_, year, month, day, hours, minutes, seconds] = match;
        if (hours && minutes && seconds) {
          return `${day}/${month}/${year} ${hours}:${minutes}:${seconds}`;
        }
        return `${day}/${month}/${year}`;
      }
      const d = new Date(dateStr);
      if (!isNaN(d.getTime())) {
        return d.toLocaleString('pt-BR', {
          timeZone: 'America/Campo_Grande',
          day: '2-digit',
          month: '2-digit',
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit'
        });
      }
      return dateStr;
    } catch (err) {
      return dateStr;
    }
  };

  const handleOpenStockModal = async (product) => {
    setSelectedProduct(product);
    setLoadingStocks(true);
    const prodId = product.codigo || product.id || product.pro_codigo || product.PRO_CODIGO;
    try {
      const res = await api.get(`/v1/estoque/posicao?pro_codigo=${prodId}`);
      let stocks = [];
      if (Array.isArray(res.data)) {
        stocks = res.data;
      } else if (res.data?.data && Array.isArray(res.data.data)) {
        stocks = res.data.data;
      } else if (res.data && typeof res.data === 'object') {
        stocks = Object.values(res.data).filter(item => typeof item === 'object');
      }

      // Deduplica rigorosamente por nome normalizado da unidade (evita duplicações em tela)
      const uniqueMap = new Map();
      stocks.forEach(st => {
        const rawName = st.empresa_nome || `Unidade #${st.empresa_id}`;
        const key = rawName.trim().toUpperCase();
        if (key && !uniqueMap.has(key)) {
          uniqueMap.set(key, st);
        } else if (key && uniqueMap.has(key)) {
          const existing = uniqueMap.get(key);
          if ((Number(st.quantidade) > Number(existing.quantidade)) ||
              (!existing.data_atualizacao && st.data_atualizacao) || 
              (st.data_atualizacao && st.data_atualizacao > existing.data_atualizacao)) {
            uniqueMap.set(key, st);
          }
        }
      });

      setUnitStocks(Array.from(uniqueMap.values()));
    } catch (err) {
      console.error('Erro ao buscar posições de estoque:', err);
      setUnitStocks([]);
    } finally {
      setLoadingStocks(false);
    }
  };

  const handleOpenHistoryModal = async (product) => {
    setSelectedHistoryProduct(product);
    setLoadingHistory(true);
    try {
      const res = await api.get(`/v1/historico-estoque?pro_codigo=${product.codigo}`);
      if (res.data && Array.isArray(res.data.data)) {
        setHistoryData(res.data.data);
      } else if (Array.isArray(res.data)) {
        setHistoryData(res.data);
      } else {
        setHistoryData([]);
      }
    } catch (err) {
      console.error('Erro ao buscar histórico de estoque:', err);
      setHistoryData([]);
    } finally {
      setLoadingHistory(false);
    }
  };

  return (
    <div className="list-card glass full-width">
      <h3><Package size={20} /> Tabela de Produtos</h3>
      <SearchBar
        value={searchTerms.produtos}
        onChange={(val) => setSearchTerms(prev => ({ ...prev, produtos: val }))}
        onSearch={() => handleSearchClick('produtos')}
        onClear={() => handleClearSearch('produtos')}
        placeholder="Buscar por nome, fabricante, código de barras..."
      />

      {/* Filtros rápidos de Produtos */}
      <div className="filter-bar">
        <button className={`filter-btn ${prodFilter === 'todos' ? 'active' : ''}`} onClick={() => setProdFilter('todos')}>Todos</button>
        <button className={`filter-btn filter-warning ${prodFilter === 'acabando' ? 'active' : ''}`} onClick={() => setProdFilter('acabando')}>Quase Acabando</button>
        <button className={`filter-btn filter-aberto ${prodFilter === 'sem_estoque' ? 'active' : ''}`} onClick={() => setProdFilter('sem_estoque')}>Sem Estoque</button>
      </div>
      <div className="table-responsive">
        <table className="data-table">
          <thead>
            <tr>
              <th scope="col">Código</th>
              <th scope="col">Nome</th>
              <th scope="col">Fabricante</th>
              <th scope="col">Cód. Barras</th>
              <th scope="col">Estoque ({activeUnitName})</th>
              <th scope="col">Valor (Venda)</th>
              <th scope="col">Ações & Histórico</th>
            </tr>
          </thead>
          <tbody>
            {getFilteredData('produtos').map((item, idx) => (
              <tr key={item.codigo || idx} className={prodFilter === 'sem_estoque' ? 'row-danger' : prodFilter === 'acabando' ? 'row-warning' : ''}>
                <td data-label="Código">{item.codigo ? <span className="item-code">#{item.codigo}</span> : '-'}</td>
                <td data-label="Nome">{item.nome}</td>
                <td data-label="Fabricante">{item.fabricante}</td>
                <td data-label="Cód. Barras">{item.codbarra}</td>
                <td data-label={`Estoque (${activeUnitName})`}>
                  <strong style={{ color: getProductStockForActiveUnit(item) > 0 ? '#10b981' : '#ef4444' }}>
                    {getProductStockForActiveUnit(item)}
                  </strong>
                </td>
                <td data-label="Valor (Venda)">{formatCurrency(item.valorv)}</td>
                <td data-label="Ações & Histórico">
                  <div style={{ display: 'inline-flex', gap: '6px', flexWrap: 'wrap' }}>
                    <button 
                      className="action-btn action-view" 
                      onClick={() => handleOpenStockModal(item)}
                      title="Ver posição por Filial"
                      style={{ padding: '6px 10px', fontSize: '0.82rem', display: 'inline-flex', alignItems: 'center', gap: '4px' }}
                    >
                      <Building2 size={14} /> Filiais
                    </button>
                    <button 
                      className="action-btn" 
                      onClick={() => handleOpenHistoryModal(item)}
                      title="Ver Histórico de Movimentações (HIS_PRO)"
                      style={{
                        padding: '6px 10px',
                        fontSize: '0.82rem',
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '4px',
                        background: 'rgba(99, 102, 241, 0.12)',
                        color: '#6366f1',
                        border: '1px solid rgba(99, 102, 241, 0.3)',
                        borderRadius: '6px',
                        cursor: 'pointer',
                        fontWeight: 600
                      }}
                    >
                      <History size={14} /> Histórico
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pagination
        currentPage={pages.produtos}
        totalPages={data.produtos.meta?.pages || 1}
        onPageChange={(page) => fetchPage('produtos', page)}
      />

      {/* Modal de Posição de Estoque por Unidade */}
      {selectedProduct && createPortal(
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setSelectedProduct(null); }}>
          <div className="modal-content glass" style={{ maxWidth: '640px', borderRadius: '16px' }}>
            <div className="modal-header" style={{ borderBottom: '1px solid rgba(0,0,0,0.08)', paddingBottom: '1rem' }}>
              <div>
                <h4 style={{ display: 'flex', alignItems: 'center', gap: '8px', margin: 0, fontSize: '1.15rem' }}>
                  <Building2 size={20} style={{ color: '#3b82f6' }} /> 
                  Posição de Estoque por Filial
                </h4>
                <p style={{ margin: '4px 0 0 0', fontSize: '0.9rem', color: 'var(--text-muted)', fontWeight: 500 }}>
                  Produto: <strong>#{selectedProduct.codigo} - {selectedProduct.nome}</strong>
                </p>
              </div>
              <button className="btn-close" onClick={() => setSelectedProduct(null)}><X size={18} /></button>
            </div>

            <div className="modal-body" style={{ padding: '1rem 0 0.5rem 0' }}>
              {loadingStocks ? (
                <div style={{ textAlign: 'center', padding: '2.5rem' }}>
                  <div className="spinner" style={{ margin: '0 auto 0.8rem auto' }}></div>
                  Carregando saldos sincronizados das filiais...
                </div>
              ) : unitStocks.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                  Nenhum saldo sincronizado encontrado para esta mercadoria nas filiais.
                </div>
              ) : (
                <>
                  {/* Resumo Consolidado */}
                  <div style={{ 
                    display: 'flex', 
                    justifyContent: 'space-between', 
                    alignItems: 'center', 
                    background: 'linear-gradient(135deg, rgba(59, 130, 246, 0.08) 0%, rgba(99, 102, 241, 0.08) 100%)', 
                    border: '1px solid rgba(59, 130, 246, 0.2)', 
                    borderRadius: '10px', 
                    padding: '0.8rem 1.2rem', 
                    marginBottom: '1rem' 
                  }}>
                    <span style={{ fontSize: '0.88rem', color: 'var(--text-primary)', fontWeight: 600 }}>
                      Estoque Total Consolidado (Todas as Unidades):
                    </span>
                    <span className="badge badge-info" style={{ fontSize: '1rem', fontWeight: 700, padding: '0.35rem 0.8rem' }}>
                      {unitStocks.reduce((acc, curr) => acc + (Number(curr.quantidade) || 0), 0)} UN
                    </span>
                  </div>

                  <div className="table-responsive" style={{ maxHeight: '360px', overflowY: 'auto' }}>
                    <table className="data-table">
                      <thead>
                        <tr>
                          <th>Unidade / Filial</th>
                          <th style={{ textAlign: 'center' }}>Cód. Item</th>
                          <th style={{ textAlign: 'center' }}>Estoque Atual</th>
                          <th>Status Sincronização</th>
                        </tr>
                      </thead>
                      <tbody>
                        {unitStocks.map((stock, i) => {
                          const empName = stock.empresa_nome || `Unidade #${stock.empresa_id}`;
                          const isCd = empName.toUpperCase().includes('CD') || stock.empresa_id === 1 || stock.empresa_id === 5;
                          const mainCdQty = Number(selectedProduct.quantidade || selectedProduct.pro_quantidade || selectedProduct.PRO_QUANTIDADE || 0);
                          let qty = Number(stock.quantidade) || 0;
                          if (isCd && qty === 0 && mainCdQty > 0) {
                            qty = mainCdQty;
                          }

                          return (
                            <tr key={stock.empresa_id || i}>
                              <td>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                  <strong style={{ fontSize: '0.92rem' }}>{empName}</strong>
                                  {isCd && (
                                    <span style={{ 
                                      fontSize: '0.72rem', 
                                      background: 'rgba(234, 88, 12, 0.12)', 
                                      color: '#ea580c', 
                                      padding: '2px 6px', 
                                      borderRadius: '4px', 
                                      fontWeight: 700 
                                    }}>
                                      CD MATRIZ
                                    </span>
                                  )}
                                </div>
                              </td>
                              <td style={{ textAlign: 'center', color: 'var(--text-muted)' }}>#{stock.pro_codigo || selectedProduct.codigo}</td>
                              <td style={{ textAlign: 'center' }}>
                                {qty > 0 ? (
                                  <span className="badge badge-success" style={{ fontSize: '0.9rem', fontWeight: 700, minWidth: '60px' }}>
                                    {qty} UN
                                  </span>
                                ) : (
                                  <span className="badge badge-secondary" style={{ fontSize: '0.88rem', opacity: 0.65, minWidth: '60px' }}>
                                    0 UN
                                  </span>
                                )}
                              </td>
                              <td style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
                                <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                                  <span style={{ width: '7px', height: '7px', borderRadius: '50%', background: '#22c55e', display: 'inline-block' }}></span>
                                  {formatDatePtBr(stock.data_atualizacao) || 'Atualizado'}
                                </span>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </>
              )}
            </div>
            <div className="modal-footer" style={{ textAlign: 'right', marginTop: '0.8rem', borderTop: '1px solid rgba(0,0,0,0.08)', paddingTop: '0.8rem' }}>
              <button className="btn-secondary" onClick={() => setSelectedProduct(null)}>Fechar</button>
            </div>
          </div>
        </div>,
        document.body
      )}

      {/* Modal de Histórico de Movimentação de Estoque (HIS_PRO) */}
      {selectedHistoryProduct && createPortal(
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setSelectedHistoryProduct(null); }}>
          <div className="modal-content glass" style={{ maxWidth: '900px', width: '92vw' }}>
            <div className="modal-header">
              <h4><History size={20} style={{ color: 'var(--accent-primary)' }} /> Histórico de Movimentações (HIS_PRO): #{selectedHistoryProduct.codigo} - {selectedHistoryProduct.nome}</h4>
              <button className="btn-close" onClick={() => setSelectedHistoryProduct(null)}><X size={18} /></button>
            </div>
            <div className="modal-body" style={{ padding: '1rem 0' }}>
              {loadingHistory ? (
                <div style={{ textAlign: 'center', padding: '2rem' }}>Carregando histórico de movimentação...</div>
              ) : historyData.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>Nenhuma movimentação de estoque registrada para este produto.</div>
              ) : (
                <div className="table-responsive" style={{ maxHeight: '420px', overflowY: 'auto' }}>
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Data</th>
                        <th>Origem / Operação</th>
                        <th>Doc. / Ref</th>
                        <th>Tipo</th>
                        <th>Qtd Movimentada</th>
                        <th>Qtd Anterior</th>
                        <th>Custo Entrada</th>
                        <th>Custo Médio</th>
                        <th>Valor Venda</th>
                      </tr>
                    </thead>
                    <tbody>
                      {historyData.map((h, idx) => (
                        <tr key={h.hp_codigo || idx}>
                          <td>{h.hp_data}</td>
                          <td><strong>{h.hp_origem || '-'}</strong></td>
                          <td>{h.hp_doc || '-'}</td>
                          <td>
                            <span className={`badge ${h.hp_tipo === 'E' ? 'badge-success' : h.hp_tipo === 'S' ? 'badge-danger' : 'badge-info'}`}>
                              {h.hp_tipo === 'E' ? 'Entrada' : h.hp_tipo === 'S' ? 'Saída' : h.hp_tipo || 'Movimento'}
                            </span>
                          </td>
                          <td><strong>{h.hp_quantidade}</strong></td>
                          <td>{h.hp_quantidadea || 0}</td>
                          <td>{formatCurrency(h.hp_valorc || 0)}</td>
                          <td>{formatCurrency(h.hp_valorcm || 0)}</td>
                          <td>{formatCurrency(h.hp_valorv || 0)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
            <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '1rem' }}>
              <button className="btn-secondary" onClick={() => setSelectedHistoryProduct(null)}>Fechar</button>
            </div>
          </div>
        </div>,
        document.body
      )}
    </div>
  );
}
