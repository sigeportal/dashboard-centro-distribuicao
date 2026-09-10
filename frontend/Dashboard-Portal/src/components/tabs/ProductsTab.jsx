import { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { 
  Package, X, Building2, History, Edit, Plus, MoreHorizontal, 
  Grid, Trash2, FileCheck2, Settings2, Users, Folder, Tag, ChevronDown, MapPin 
} from 'lucide-react';
import SearchBar from '../SearchBar';
import Pagination from '../Pagination';
import ProductFormModal from '../ProductFormModal';
import ConciliacaoFiscalModal from '../ConciliacaoFiscalModal';
import FornecedoresModal from '../FornecedoresModal';
import GruposSubgruposModal from '../GruposSubgruposModal';
import ModelosModal from '../ModelosModal';
import GradesModal from '../GradesModal';
import { formatCurrency } from '../../utils/formatters';
import { createApi } from '../../services/api';
import { toast } from '../../contexts/ToastContext';
import './ProductsTab.css';

export default function ProductsTab({ 
  data, 
  pages, 
  searchTerms, 
  setSearchTerms, 
  prodFilter, 
  setProdFilter, 
  getFilteredData, 
  handleSearchClick, 
  handleClearSearch, 
  fetchPage 
}) {
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [unitStocks, setUnitStocks] = useState([]);
  const [loadingStocks, setLoadingStocks] = useState(false);

  // Histórico de Movimentações (HIS_PRO)
  const [selectedHistoryProduct, setSelectedHistoryProduct] = useState(null);
  const [historyData, setHistoryData] = useState([]);
  const [loadingHistory, setLoadingHistory] = useState(false);

  // Modal de Cadastro/Edição de Produto
  const [showProductModal, setShowProductModal] = useState(false);
  const [productToEditModal, setProductToEditModal] = useState(null);

  // Modais de Cadastros Auxiliares e Conciliação Fiscal
  const [showConciliacaoModal, setShowConciliacaoModal] = useState(false);
  const [showAuxiliaresMenu, setShowAuxiliaresMenu] = useState(false);
  const [showFornecedoresModal, setShowFornecedoresModal] = useState(false);
  const [showGruposSubgruposModal, setShowGruposSubgruposModal] = useState(false);
  const [showModelosModal, setShowModelosModal] = useState(false);

  // Modal de Grades do Produto Selecionado
  const [showGradesModal, setShowGradesModal] = useState(false);
  const [productForGrades, setProductForGrades] = useState(null);

  // Menu Dropdown de Ações da Linha (...)
  const [activeActionMenuId, setActiveActionMenuId] = useState(null);
  const auxiliaresMenuRef = useRef(null);

  // Saldo de Estoque Consolidado (Soma de Todas as Filiais)
  const [consolidatedStocks, setConsolidatedStocks] = useState({});
  const [, setActiveUnitStocks] = useState({});
  const activeUnitId = Number(localStorage.getItem('selected_company_id')) || 1;

  const api = createApi(true);

  // Fechar menus ao clicar fora
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (auxiliaresMenuRef.current && !auxiliaresMenuRef.current.contains(e.target)) {
        setShowAuxiliaresMenu(false);
      }
      setActiveActionMenuId(null);
    };
    document.addEventListener('click', handleClickOutside);
    return () => document.removeEventListener('click', handleClickOutside);
  }, []);

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

  const handleDeleteProduct = async (prodId) => {
    if (!window.confirm(`Tem certeza que deseja excluir o produto #${prodId}?`)) return;
    try {
      await api.delete(`/v1/produtos/${prodId}`);
      toast.success('Produto excluído com sucesso!');
      fetchPage('produtos', pages.produtos);
    } catch (err) {
      console.error(err);
      toast.error('Erro ao excluir produto: ' + (err.response?.data?.error || err.message));
    }
  };

  return (
    <div className="list-card glass full-width">
      
      {/* Top Header com Botões de Ações e Cadastros Auxiliares */}
      <div className="products-header-row">
        <h3 style={{ margin: 0, display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Package size={22} style={{ color: '#f97316' }} /> Catálogo de Produtos
        </h3>

        <div className="products-header-actions">
          {/* Botão Conciliação Fiscal */}
          <button 
            className="btn-secondary" 
            onClick={() => setShowConciliacaoModal(true)}
            title="Abrir Relatório Comparativo de Estoque Fiscal vs Físico"
          >
            <FileCheck2 size={16} /> Conciliação Fiscal
          </button>

          {/* Menu Dropdown Cadastros Auxiliares */}
          <div className="auxiliares-menu-container" ref={auxiliaresMenuRef}>
            <button 
              className={`btn-secondary ${showAuxiliaresMenu ? 'active' : ''}`}
              onClick={(e) => {
                e.stopPropagation();
                setShowAuxiliaresMenu(!showAuxiliaresMenu);
              }}
              title="Acessar tabelas de apoio"
            >
              <Settings2 size={16} /> Cadastros Auxiliares <ChevronDown size={14} />
            </button>

            {showAuxiliaresMenu && (
              <div className="cadastros-dropdown-menu" onClick={(e) => e.stopPropagation()}>
                <div className="cadastros-dropdown-header">Tabelas de Apoio</div>
                <button 
                  className="cadastros-dropdown-item" 
                  onClick={() => { setShowAuxiliaresMenu(false); setShowFornecedoresModal(true); }}
                >
                  <Users size={16} /> Fornecedores
                </button>
                <button 
                  className="cadastros-dropdown-item" 
                  onClick={() => { setShowAuxiliaresMenu(false); setShowGruposSubgruposModal(true); }}
                >
                  <Folder size={16} /> Grupos & Subgrupos
                </button>
                <button 
                  className="cadastros-dropdown-item" 
                  onClick={() => { setShowAuxiliaresMenu(false); setShowModelosModal(true); }}
                >
                  <Tag size={16} /> Modelos / Linhas
                </button>
              </div>
            )}
          </div>

          {/* Botão Novo Produto */}
          <button 
            className="btn-primary" 
            onClick={() => { setProductToEditModal(null); setShowProductModal(true); }}
            title="Cadastrar Novo Produto"
          >
            <Plus size={16} /> Novo Produto
          </button>
        </div>
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

      {/* Tabela de Produtos com Preços e Ações Dropdown */}
      <div className="table-responsive" style={{ overflow: 'visible' }}>
        <table className="data-table">
          <thead>
            <tr>
              <th scope="col" style={{ width: '80px' }}>Código</th>
              <th scope="col" style={{ minWidth: '220px' }}>Nome do Produto</th>
              <th scope="col" style={{ width: '130px' }}>Fabricante/Marca</th>
              <th scope="col" style={{ width: '125px' }}>Cód. Barras</th>
              <th scope="col" style={{ width: '100px', textAlign: 'center' }} title="Estoque Total Consolidado (Soma de Todas as Filiais)">Estoque Total</th>
              <th scope="col" style={{ width: '170px' }}>Preços (Vista / Din. / Prazo)</th>
              <th scope="col" style={{ width: '65px', textAlign: 'center' }}>Ações</th>
            </tr>
          </thead>
          <tbody>
            {getFilteredData('produtos').map((item, idx) => {
              const stockTotal = getProductConsolidatedStock(item);
              const isMenuOpen = activeActionMenuId === (item.codigo || idx);

              return (
                <tr key={item.codigo || idx} className={prodFilter === 'sem_estoque' ? 'row-danger' : prodFilter === 'acabando' ? 'row-warning' : ''}>
                  <td data-label="Código">
                    {item.codigo ? <span className="item-code">#{item.codigo}</span> : '-'}
                  </td>
                  <td data-label="Nome">
                    <strong>{item.nome}</strong>
                  </td>
                  <td data-label="Fabricante">{item.fabricante || item.marca || '-'}</td>
                  <td data-label="Cód. Barras" className="codbarra-cell">
                    {item.codbarra || '-'}
                  </td>
                  <td data-label="Estoque" style={{ textAlign: 'center' }}>
                    <strong style={{ color: stockTotal > 0 ? '#10b981' : '#ef4444' }}>
                      {stockTotal}
                    </strong>
                  </td>
                  <td data-label="Preços" className="prices-cell">
                    <div className="price-badge-container">
                      <div className="price-primary" title="Preço À Vista (Débito / PIX)">
                        <span className="price-label">Vista:</span> {formatCurrency(item.valorv || 0)}
                      </div>
                      <div className="price-secondary-row">
                        <span className="price-tag" title="Valor Dinheiro">Din: {formatCurrency(item.pro_valor_dinheiro ?? item.valorv ?? 0)}</span>
                        <span className="price-tag" title="Preço a Prazo">Prazo: {formatCurrency(item.pro_valorv_prazo ?? item.valorv ?? 0)}</span>
                      </div>
                    </div>
                  </td>
                  <td data-label="Ações" className="actions-cell-relative">
                    <button 
                      className={`action-dots-btn ${isMenuOpen ? 'active' : ''}`}
                      onClick={(e) => {
                        e.stopPropagation();
                        setActiveActionMenuId(isMenuOpen ? null : (item.codigo || idx));
                      }}
                      title="Opções do Produto"
                    >
                      <MoreHorizontal size={18} />
                    </button>

                    {isMenuOpen && (
                      <div className="action-menu-dropdown" onClick={(e) => e.stopPropagation()}>
                        <button 
                          className="action-menu-item"
                          onClick={() => {
                            setActiveActionMenuId(null);
                            handleOpenStockModal(item);
                          }}
                        >
                          <Building2 size={15} style={{ color: '#ea580c' }} /> Filiais
                        </button>

                        <button 
                          className="action-menu-item"
                          onClick={() => {
                            setActiveActionMenuId(null);
                            setProductForGrades(item);
                            setShowGradesModal(true);
                          }}
                        >
                          <Grid size={15} style={{ color: '#8b5cf6' }} /> Grades
                        </button>

                        <button 
                          className="action-menu-item"
                          onClick={() => {
                            setActiveActionMenuId(null);
                            handleOpenHistoryModal(item);
                          }}
                        >
                          <History size={15} style={{ color: '#059669' }} /> Histórico
                        </button>

                        <button 
                          className="action-menu-item"
                          onClick={() => {
                            setActiveActionMenuId(null);
                            setProductToEditModal(item);
                            setShowProductModal(true);
                          }}
                        >
                          <Edit size={15} style={{ color: '#0284c7' }} /> Editar
                        </button>

                        <div className="action-menu-divider" />

                        <button 
                          className="action-menu-item delete"
                          onClick={() => {
                            setActiveActionMenuId(null);
                            handleDeleteProduct(item.codigo);
                          }}
                        >
                          <Trash2 size={15} /> Excluir
                        </button>
                      </div>
                    )}
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

      {/* Modal de Conciliação Fiscal */}
      {showConciliacaoModal && (
        <ConciliacaoFiscalModal onClose={() => setShowConciliacaoModal(false)} />
      )}

      {/* Modal de Gestão de Fornecedores */}
      <FornecedoresModal 
        isOpen={showFornecedoresModal} 
        onClose={() => setShowFornecedoresModal(false)} 
      />

      {/* Modal de Grupos e Subgrupos */}
      <GruposSubgruposModal 
        isOpen={showGruposSubgruposModal} 
        onClose={() => setShowGruposSubgruposModal(false)} 
      />

      {/* Modal de Modelos / Linhas */}
      <ModelosModal 
        isOpen={showModelosModal} 
        onClose={() => setShowModelosModal(false)} 
      />

      {/* Modal de Grades do Produto */}
      <GradesModal 
        isOpen={showGradesModal} 
        product={productForGrades}
        onClose={() => {
          setShowGradesModal(false);
          setProductForGrades(null);
        }}
        onGradesUpdated={() => fetchPage('produtos', pages.produtos)}
      />

      {/* Modal de Cadastro / Edição de Produto Completo */}
      <ProductFormModal
        isOpen={showProductModal}
        productToEdit={productToEditModal}
        onClose={() => setShowProductModal(false)}
        onSaveSuccess={() => fetchPage('produtos', pages.produtos)}
      />

      {/* Modal de Posição de Estoque por Filial */}
      {selectedProduct && createPortal(
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setSelectedProduct(null); }}>
          <div className="modal-content glass" style={{ maxWidth: '720px', width: '95vw', borderRadius: '16px' }}>
            <div className="modal-header" style={{ borderBottom: '1px solid rgba(0,0,0,0.08)', paddingBottom: '1rem' }}>
              <div>
                <h4 style={{ display: 'flex', alignItems: 'center', gap: '8px', margin: 0, fontSize: '1.15rem' }}>
                  <Building2 size={20} style={{ color: '#ea580c' }} /> 
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
                  <div style={{ 
                    display: 'flex', 
                    justifyContent: 'space-between', 
                    alignItems: 'center', 
                    background: 'linear-gradient(135deg, rgba(249, 115, 22, 0.08) 0%, rgba(234, 88, 12, 0.04) 100%)', 
                    border: '1px solid rgba(249, 115, 22, 0.2)', 
                    borderRadius: '10px', 
                    padding: '0.8rem 1.2rem', 
                    marginBottom: '1rem' 
                  }}>
                    <span style={{ fontSize: '0.88rem', color: 'var(--text-primary)', fontWeight: 600 }}>
                      Estoque Total Consolidado (Todas as Unidades):
                    </span>
                    <span style={{ 
                      background: 'linear-gradient(135deg, #f97316 0%, #ea580c 100%)', 
                      color: '#ffffff', 
                      fontSize: '0.95rem', 
                      fontWeight: 700, 
                      padding: '0.35rem 0.8rem',
                      borderRadius: '0.5rem',
                      boxShadow: '0 2px 8px rgba(234, 88, 12, 0.25)'
                    }}>
                      {unitStocks.reduce((acc, curr) => acc + (Number(curr.quantidade) || 0), 0)} UN
                    </span>
                  </div>

                  <div className="table-responsive" style={{ maxHeight: '380px', overflowY: 'auto' }}>
                    <table className="data-table" style={{ width: '100%' }}>
                      <thead>
                        <tr>
                          <th style={{ textAlign: 'left' }}>Filial / Unidade</th>
                          <th style={{ textAlign: 'center', width: '85px' }}>Cód. Item</th>
                          <th style={{ textAlign: 'center', width: '120px' }}>Estoque Atual</th>
                          <th style={{ textAlign: 'center', width: '135px' }}>Sincronização</th>
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
                                <div style={{ display: 'flex', flexDirection: 'column', gap: '3px' }}>
                                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                    <strong style={{ fontSize: '0.92rem', color: 'var(--text-primary)' }}>
                                      {empName}
                                    </strong>
                                    {isCd && (
                                      <span style={{ 
                                        fontSize: '0.65rem', 
                                        background: 'rgba(234, 88, 12, 0.12)', 
                                        color: '#ea580c', 
                                        padding: '1px 5px', 
                                        borderRadius: '4px', 
                                        fontWeight: 700,
                                        letterSpacing: '0.5px'
                                      }}>
                                        CD MATRIZ
                                      </span>
                                    )}
                                  </div>
                                  {city && (
                                    <span style={{ 
                                      fontSize: '0.78rem', 
                                      color: 'var(--text-secondary, #64748b)', 
                                      fontWeight: 500,
                                      display: 'flex',
                                      alignItems: 'center',
                                      gap: '4px'
                                    }}>
                                      <MapPin size={12} style={{ color: '#ea580c' }} /> {city}{uf ? ` - ${uf}` : ''}
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

      {/* Modal de Histórico de Movimentações (HIS_PRO) */}
      {selectedHistoryProduct && createPortal(
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setSelectedHistoryProduct(null); }}>
          <div className="modal-content glass" style={{ maxWidth: '900px', width: '95vw', borderRadius: '16px' }}>
            <div className="modal-header" style={{ borderBottom: '1px solid rgba(0,0,0,0.08)', paddingBottom: '1rem' }}>
              <div>
                <h4 style={{ display: 'flex', alignItems: 'center', gap: '8px', margin: 0, fontSize: '1.15rem' }}>
                  <History size={20} style={{ color: '#ea580c' }} /> 
                  Histórico de Movimentações de Estoque
                </h4>
                <p style={{ margin: '4px 0 0 0', fontSize: '0.9rem', color: 'var(--text-muted)', fontWeight: 500 }}>
                  Mercadoria: <strong>#{selectedHistoryProduct.codigo} - {selectedHistoryProduct.nome}</strong>
                </p>
              </div>
              <button className="btn-close" onClick={() => setSelectedHistoryProduct(null)}><X size={18} /></button>
            </div>

            <div className="modal-body" style={{ padding: '1rem 0 0.5rem 0' }}>
              {loadingHistory ? (
                <div style={{ textAlign: 'center', padding: '2.5rem' }}>
                  <div className="spinner" style={{ margin: '0 auto 0.8rem auto' }}></div>
                  Carregando movimentações do produto...
                </div>
              ) : historyData.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                  Nenhum registro de movimentação encontrado para esta mercadoria.
                </div>
              ) : (
                <div className="table-responsive" style={{ maxHeight: '420px', overflowY: 'auto' }}>
                  <table className="data-table" style={{ width: '100%', minWidth: '700px' }}>
                    <thead>
                      <tr>
                        <th style={{ textAlign: 'left', width: '140px' }}>Data / Hora</th>
                        <th style={{ textAlign: 'center', width: '90px' }}>Tipo</th>
                        <th style={{ textAlign: 'center', width: '90px' }}>Qtd</th>
                        <th style={{ textAlign: 'right', width: '110px' }}>Unitário</th>
                        <th style={{ textAlign: 'left' }}>Documento / Histórico</th>
                      </tr>
                    </thead>
                    <tbody>
                      {historyData.map((item, i) => {
                        const tipo = (item.tipo || item.his_tipo || '').toUpperCase();
                        const isEntrada = tipo === 'E' || tipo === 'COMPRA' || tipo === 'ENTRADA';
                        return (
                          <tr key={item.codigo || item.his_codigo || i}>
                            <td style={{ fontSize: '0.85rem' }}>{formatDatePtBr(item.data || item.his_data)}</td>
                            <td style={{ textAlign: 'center' }}>
                              <span className={`badge ${isEntrada ? 'badge-success' : 'badge-danger'}`} style={{ fontSize: '0.78rem' }}>
                                {isEntrada ? 'ENTRADA' : 'SAÍDA'}
                              </span>
                            </td>
                            <td style={{ textAlign: 'center', fontWeight: 700 }}>
                              {item.quantidade || item.his_quantidade || 0}
                            </td>
                            <td style={{ textAlign: 'right' }}>
                              {formatCurrency(item.valor || item.his_valor || 0)}
                            </td>
                            <td style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                              {item.documento || item.his_documento || item.historico || item.his_historico || '-'}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
            <div className="modal-footer" style={{ textAlign: 'right', marginTop: '0.8rem', borderTop: '1px solid rgba(0,0,0,0.08)', paddingTop: '0.8rem' }}>
              <button className="btn-secondary" onClick={() => setSelectedHistoryProduct(null)}>Fechar</button>
            </div>
          </div>
        </div>,
        document.body
      )}

    </div>
  );
}
