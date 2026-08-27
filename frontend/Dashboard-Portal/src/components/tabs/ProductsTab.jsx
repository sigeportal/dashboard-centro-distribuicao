import { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Package, Eye, X, Building2, History, Edit, Plus } from 'lucide-react';
import SearchBar from '../SearchBar';
import Pagination from '../Pagination';
import ProductFormModal from '../ProductFormModal';
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

  // Modal de Cadastro/Edição de Produto Legado (Pop-up)
  const [showProductModal, setShowProductModal] = useState(false);
  const [productToEditModal, setProductToEditModal] = useState(null);

  // Saldo de Estoque Consolidado (Soma de Todas as Filiais)
  const [consolidatedStocks, setConsolidatedStocks] = useState({});
  const [activeUnitStocks, setActiveUnitStocks] = useState({});
  const activeUnitId = Number(localStorage.getItem('selected_company_id')) || 1;
  const activeUnitName = localStorage.getItem('selected_company_name') || (activeUnitId === 1 ? 'CD DOURADINA' : `Unidade #${activeUnitId}`);
  const isMatriz = activeUnitId === 1 || activeUnitName.toUpperCase().includes('CD') || activeUnitName.toUpperCase().includes('DOURADINA');

  const api = createApi(true);

  const fetchStocks = async () => {
    try {
      const res = await api.get('/v1/estoque/posicao');
      let dataArr = [];
      if (Array.isArray(res.data)) dataArr = res.data;
      else if (res.data?.data && Array.isArray(res.data.data)) dataArr = res.data.data;

      const consMap = {};
      const unitMap = {};
      const seenUnitsPerProduct = {};

      dataArr.forEach(st => {
        const prodId = Number(st.pro_codigo || st.codigo || st.pro);
        const qty = Number(st.quantidade) || 0;
        const empId = Number(st.empresa_id);
        const empName = (st.empresa_nome || '').toUpperCase();
        let unitKey = String(empId);
        if (unitKey === '1' || unitKey === '5' || empName.includes('DOURADINA') || empName.includes('CD')) {
          unitKey = 'CD_DOURADINA';
        }

        if (prodId) {
          if (!seenUnitsPerProduct[prodId]) seenUnitsPerProduct[prodId] = new Set();
          if (!seenUnitsPerProduct[prodId].has(unitKey)) {
            seenUnitsPerProduct[prodId].add(unitKey);
            consMap[prodId] = (consMap[prodId] || 0) + qty;
          }
          if (empId === activeUnitId || (activeUnitId === 5 && (empId === 1 || empId === 5))) {
            unitMap[prodId] = qty;
          }
        }
      });
      setConsolidatedStocks(consMap);
      setActiveUnitStocks(unitMap);
    } catch (err) {
      console.warn('Erro ao buscar saldos de estoque consolidados:', err);
    }
  };

  useEffect(() => {
    fetchStocks();
  }, [activeUnitId]);

  const getProductConsolidatedStock = (item) => {
    const prodId = Number(item.codigo || item.id || item.pro_codigo || item.PRO_CODIGO);
    if (prodId && consolidatedStocks[prodId] !== undefined) {
      return consolidatedStocks[prodId];
    }
    return Number(item.quantidade || item.pro_quantidade || item.PRO_QUANTIDADE) || 0;
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

      // Deduplica rigorosamente por chave de unidade real (evita duplicar CD Douradina)
      const uniqueMap = new Map();
      stocks.forEach(st => {
        const rawName = st.empresa_nome || `Unidade #${st.empresa_id}`;
        let key = rawName.trim().toUpperCase();
        if (key.includes('DOURADINA') || key.includes('CD') || st.empresa_id === 5 || st.empresa_id === 1) {
          key = 'CD_DOURADINA';
        }
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
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
        <h3 style={{ margin: 0 }}><Package size={20} /> Tabela de Produtos</h3>
        <button 
          className="btn-primary" 
          onClick={() => { setProductToEditModal(null); setShowProductModal(true); }}
          style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '0.55rem 1.1rem', fontWeight: 600 }}
        >
          <Plus size={16} /> Novo Produto (Pop-up)
        </button>
      </div>

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
              <th scope="col" style={{ width: '80px' }}>Código</th>
              <th scope="col">Nome</th>
              <th scope="col" style={{ width: '130px' }}>Fabricante</th>
              <th scope="col" style={{ width: '130px' }}>Cód. Barras</th>
              <th scope="col" style={{ width: '110px', textAlign: 'center' }} title="Estoque Total Consolidado (Soma de Todas as Filiais)">Estoque</th>
              <th scope="col" style={{ width: '100px', textAlign: 'right' }}>Valor</th>
              <th scope="col" style={{ width: '220px', textAlign: 'center' }}>Ações</th>
            </tr>
          </thead>
          <tbody>
            {getFilteredData('produtos').map((item, idx) => {
              const stockTotal = getProductConsolidatedStock(item);
              return (
                <tr key={item.codigo || idx} className={prodFilter === 'sem_estoque' ? 'row-danger' : prodFilter === 'acabando' ? 'row-warning' : ''}>
                  <td data-label="Código">{item.codigo ? <span className="item-code">#{item.codigo}</span> : '-'}</td>
                  <td data-label="Nome">{item.nome}</td>
                  <td data-label="Fabricante">{item.fabricante}</td>
                  <td data-label="Cód. Barras">{item.codbarra}</td>
                  <td data-label="Estoque" style={{ textAlign: 'center' }}>
                    <strong style={{ color: stockTotal > 0 ? '#10b981' : '#ef4444' }}>
                      {stockTotal}
                    </strong>
                  </td>
                  <td data-label="Valor" style={{ textAlign: 'right' }}>{formatCurrency(item.valorv)}</td>
                  <td data-label="Ações" style={{ textAlign: 'center' }}>
                    <div style={{ display: 'inline-flex', gap: '4px', justifyContent: 'center' }}>
                      <button 
                        className="action-btn action-view" 
                        onClick={() => handleOpenStockModal(item)}
                        title="Ver posição por Filial"
                        style={{ padding: '4px 8px', fontSize: '0.78rem', display: 'inline-flex', alignItems: 'center', gap: '3px' }}
                      >
                        <Building2 size={13} /> Filiais
                      </button>

                      <button 
                        className="action-btn" 
                        onClick={() => { setProductToEditModal(item); setShowProductModal(true); }}
                        title="Editar Produto (Pop-up)"
                        style={{
                          padding: '4px 8px',
                          fontSize: '0.78rem',
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: '3px',
                          background: 'rgba(37, 99, 235, 0.12)',
                          color: '#2563eb',
                          border: '1px solid rgba(37, 99, 235, 0.3)',
                          borderRadius: '6px',
                          cursor: 'pointer',
                          fontWeight: 600
                        }}
                      >
                        <Edit size={13} /> Editar
                      </button>

                      <button 
                        className="action-btn" 
                        onClick={() => handleOpenHistoryModal(item)}
                        title="Ver Histórico (HIS_PRO)"
                        style={{
                          padding: '4px 8px',
                          fontSize: '0.78rem',
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: '3px',
                          background: 'rgba(99, 102, 241, 0.12)',
                          color: '#6366f1',
                          border: '1px solid rgba(99, 102, 241, 0.3)',
                          borderRadius: '6px',
                          cursor: 'pointer',
                          fontWeight: 600
                        }}
                      >
                        <History size={13} /> Histórico
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
            {getFilteredData('produtos').length === 0 && (
              <tr>
                <td colSpan="7" style={{ textAlign: 'center', padding: '2.5rem', color: '#64748b' }}>
                  Nenhum produto cadastrado no catálogo. Clique em <strong>"+ Novo Produto"</strong> para cadastrar.
                </td>
              </tr>
            )}
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
          <div className="modal-content glass" style={{ maxWidth: '820px', width: '95vw', borderRadius: '16px' }}>
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

                  <div className="table-responsive" style={{ maxHeight: '380px', overflowY: 'auto' }}>
                    <table className="data-table" style={{ width: '100%', minWidth: '680px' }}>
                      <thead>
                        <tr>
                          <th style={{ textAlign: 'left', minWidth: '280px' }}>Unidade / Filial</th>
                          <th style={{ textAlign: 'center', width: '85px' }}>Cód. Item</th>
                          <th style={{ textAlign: 'center', width: '130px' }}>Estoque Atual</th>
                          <th style={{ textAlign: 'center', minWidth: '170px' }}>Status Sincronização</th>
                        </tr>
                      </thead>
                      <tbody>
                        {unitStocks.map((stock, i) => {
                          const fallbackCities = {
                            5: 'DOURADINA',
                            1: 'DOURADINA',
                            6: 'RIO BRILHANTE',
                            7: 'ITAPORÃ',
                            4: 'NOVA ALVORADA DO SUL',
                            8: 'MARACAJU'
                          };
                          const empName = stock.empresa_fantasia || stock.empresa_nome || `Unidade #${stock.empresa_id}`;
                          const city = stock.empresa_municipio || stock.municipio || stock.cidade || fallbackCities[stock.empresa_id] || '';
                          const uf = stock.empresa_uf || stock.uf || (city ? 'MS' : '');
                          const isCd = empName.toUpperCase().includes('CD') || empName.toUpperCase().includes('MATRIZ') || stock.empresa_id === 1 || stock.empresa_id === 5;
                          const mainCdQty = Number(selectedProduct.quantidade || selectedProduct.pro_quantidade || selectedProduct.PRO_QUANTIDADE || 0);
                          let qty = Number(stock.quantidade) || 0;
                          if (isCd && qty === 0 && mainCdQty > 0) {
                            qty = mainCdQty;
                          }

                          return (
                            <tr key={stock.empresa_id || i}>
                              <td>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'nowrap' }}>
                                  <strong style={{ fontSize: '0.92rem', color: 'var(--text-primary)', whiteSpace: 'nowrap' }}>
                                    {empName}
                                  </strong>
                                  {city && (
                                    <span style={{ 
                                      fontSize: '0.78rem', 
                                      background: 'rgba(37, 99, 235, 0.08)', 
                                      color: '#2563eb', 
                                      padding: '2px 8px', 
                                      borderRadius: '6px', 
                                      fontWeight: 600,
                                      border: '1px solid rgba(37, 99, 235, 0.18)',
                                      whiteSpace: 'nowrap'
                                    }}>
                                      {city}{uf ? ` - ${uf}` : ''}
                                    </span>
                                  )}
                                  {isCd && (
                                    <span style={{ 
                                      fontSize: '0.68rem', 
                                      background: 'rgba(234, 88, 12, 0.12)', 
                                      color: '#ea580c', 
                                      padding: '2px 6px', 
                                      borderRadius: '4px', 
                                      fontWeight: 700,
                                      whiteSpace: 'nowrap',
                                      letterSpacing: '0.5px'
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
                              <td style={{ textAlign: 'center', fontSize: '0.82rem', color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>
                                <span style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
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
                          <td>
                            {h.unidade_origem || h.unidade_destino ? (
                              <span className="badge badge-info" style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', padding: '4px 8px', fontWeight: 600 }}>
                                🏢 {h.hp_origem}
                              </span>
                            ) : h.hp_origem && h.hp_origem.toUpperCase().includes('TRANSF') ? (
                              <span className="badge badge-info" style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', padding: '4px 8px', fontWeight: 600 }}>
                                🔄 {h.hp_origem}
                              </span>
                            ) : (
                              <strong>{h.hp_origem || '-'}</strong>
                            )}
                          </td>
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
      {/* Modal de Cadastro/Edição em Pop-up */}
      {showProductModal && (
        <ProductFormModal
          isOpen={showProductModal}
          onClose={() => setShowProductModal(false)}
          productToEdit={productToEditModal}
          onSaveSuccess={() => {
            setShowProductModal(false);
            fetchPage('produtos', pages.produtos || 1);
          }}
        />
      )}

    </div>
  );
}
