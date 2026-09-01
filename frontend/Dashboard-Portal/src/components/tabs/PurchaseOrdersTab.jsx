import React, { useState, useEffect, useRef } from 'react';
import { 
  FileSpreadsheet, Plus, Trash2, Edit2, Printer, 
  Search, RefreshCw, CheckCircle2, AlertCircle, Building2, 
  DollarSign, Package, X, Save, Share2, Layers, Calendar,
  CreditCard, Truck, FileText, Check, Hash
} from 'lucide-react';
import { createApi } from '../../services/api';
import SearchBar from '../SearchBar';
import Pagination from '../Pagination';
import LookupSelect from '../LookupSelect';
import { toast } from '../../contexts/ToastContext';
import { formatCurrency } from '../../utils/formatters';
import './PurchaseOrdersTab.css';

export default function PurchaseOrdersTab() {
  const api = createApi(true);
  const printRef = useRef(null);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  // Lista e Paginação
  const [pedidos, setPedidos] = useState([]);
  const [page, setPage] = useState(1);
  const [meta, setMeta] = useState({ page: 1, limit: 15, total: 0, pages: 1 });
  const [searchTerm, setSearchTerm] = useState('');

  // Dados Auxiliares
  const [fornecedores, setFornecedores] = useState([]);
  const [produtos, setProdutos] = useState([]);

  // Modais
  const [showOrderModal, setShowOrderModal] = useState(false);
  const [showPrintModal, setShowPrintModal] = useState(null);

  // Grade de Tamanhos Padrão (Colunas da Matriz: ex: 34 a 39 ou P, M, G, GG)
  const [colunasTamanhos, setColunasTamanhos] = useState(['34', '35', '36', '37', '38', '39']);

  // Formulário da Ordem de Compra
  const [orderForm, setOrderForm] = useState({
    id: 0,
    numero_ordem: '',
    fornecedor_id: '',
    fornecedor_nome: '',
    marca: 'MOONCITY',
    representante: 'ADEMIR',
    contato_representante: '67981353840',
    empresa_nome: 'GIGANTE ROUPAS E CALÇADOS',
    empresa_cnpj: '31.797.325.0003-32',
    local_pedido: 'DOURADINA',
    local_entrega: 'ITAPORÃ',
    data_pedido: new Date().toISOString().split('T')[0],
    data_entrega: 'ABRIL / 2026',
    prazo_pagamento: '60/90/120/150/180',
    desconto_perc: 0,
    desconto_valor: 0,
    imposto_icms: 0,
    total_pecas: 0,
    valor_total: 0,
    status: 'RASCUNHO',
    observacao: 'NOTA 70%',
    itens: []
  });

  // Estado de Inclusão de Linha na Matriz
  const [itemLinhaForm, setItemLinhaForm] = useState({
    produto_codigo: 0,
    produto_nome: '',
    cor: 'PRETA',
    referencia: '',
    valor_unitario: 0,
    valor_imposto: 0,
    valor_dinheiro: 0,
    valor_vista: 0,
    valor_prazo: 0,
    grade_tamanhos: {}
  });

  useEffect(() => {
    fetchPedidos(1);
    fetchAuxiliaryData();
  }, []);

  // Atalhos de teclado (F2 para Novo Pedido, ESC para fechar modais)
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'F2') {
        e.preventDefault();
        handleOpenCreateOrder();
      } else if (e.key === 'Escape') {
        if (showOrderModal) setShowOrderModal(false);
        if (showPrintModal) setShowPrintModal(null);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [showOrderModal, showPrintModal, fornecedores]);

  const fetchPedidos = async (targetPage = 1) => {
    setLoading(true);
    setError('');
    try {
      let url = `/v1/pedidos-compra?page=${targetPage}&limit=15`;
      if (searchTerm) url += `&busca=${encodeURIComponent(searchTerm)}`;
      
      const res = await api.get(url);
      let items = [];
      let metaData = { page: targetPage, limit: 15, total: 0, pages: 1 };

      if (res.data && Array.isArray(res.data.data)) {
        items = res.data.data;
        metaData = res.data.meta || { page: targetPage, limit: 15, total: items.length, pages: 1 };
      } else if (Array.isArray(res.data)) {
        items = res.data;
        metaData = { page: 1, limit: items.length || 15, total: items.length, pages: 1 };
      }

      setPedidos(items);
      setMeta(metaData);
      setPage(metaData.page || targetPage);
    } catch (err) {
      console.error(err);
      setPedidos([]);
      setError('Erro ao carregar lista de ordens de compra.');
    } finally {
      setLoading(false);
    }
  };

  const fetchAuxiliaryData = async () => {
    try {
      const [fRes, pRes] = await Promise.all([
        api.get('/v1/fornecedores?limit=500').catch(() => ({ data: [] })),
        api.get('/v1/produtos?limit=1000').catch(() => ({ data: [] }))
      ]);
      setFornecedores(Array.isArray(fRes.data) ? fRes.data : (fRes.data?.data || []));
      setProdutos(Array.isArray(pRes.data) ? pRes.data : (pRes.data?.data || []));
    } catch (err) {
      console.error(err);
    }
  };

  const handleOpenCreateOrder = () => {
    const nextNum = Math.floor(Math.random() * 900) + 100;
    const anoAtual = new Date().getFullYear();

    setOrderForm({
      id: 0,
      numero_ordem: `00${nextNum % 50 + 1}/${anoAtual}`,
      fornecedor_id: fornecedores[0]?.codigo || '',
      fornecedor_nome: fornecedores[0]?.nome || 'MOONCITY',
      marca: 'MOONCITY',
      representante: 'ADEMIR',
      contato_representante: '67981353840',
      empresa_nome: 'GIGANTE ROUPAS E CALÇADOS',
      empresa_cnpj: '31.797.325.0003-32',
      local_pedido: 'DOURADINA',
      local_entrega: 'ITAPORÃ',
      data_pedido: new Date().toISOString().split('T')[0],
      data_entrega: `MAIO / ${anoAtual}`,
      prazo_pagamento: '60/90/120/150/180',
      desconto_perc: 0,
      desconto_valor: 0,
      imposto_icms: 0,
      total_pecas: 0,
      valor_total: 0,
      status: 'RASCUNHO',
      observacao: 'NOTA 70%',
      itens: []
    });

    setItemLinhaForm({
      produto_codigo: 0,
      produto_nome: '',
      cor: 'PRETA',
      referencia: '',
      valor_unitario: 0,
      valor_imposto: 0,
      valor_dinheiro: 0,
      valor_vista: 0,
      valor_prazo: 0,
      grade_tamanhos: {}
    });

    setShowOrderModal(true);
  };

  const handleOpenEditOrder = async (order) => {
    setLoading(true);
    try {
      const res = await api.get(`/v1/pedidos-compra/${order.id}`);
      const dados = res.data;
      
      const parsedItens = (dados.itens || []).map(it => {
        let gradeObj = {};
        try {
          if (typeof it.grade_tamanhos === 'string') {
            gradeObj = JSON.parse(it.grade_tamanhos);
          } else if (typeof it.grade_tamanhos === 'object') {
            gradeObj = it.grade_tamanhos;
          }
        } catch (e) {
          gradeObj = {};
        }
        return {
          ...it,
          grade_tamanhos: gradeObj
        };
      });

      setOrderForm({
        ...dados,
        itens: parsedItens
      });
      setShowOrderModal(true);
    } catch (err) {
      console.error(err);
      toast.error('Erro ao carregar detalhes do pedido de compra.');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteOrder = async (orderId) => {
    if (!window.confirm('Tem certeza que deseja excluir esta Ordem de Compra?')) return;
    setLoading(true);
    try {
      await api.delete(`/v1/pedidos-compra/${orderId}`);
      setSuccessMsg('Ordem de compra excluída com sucesso.');
      fetchPedidos(page);
      setTimeout(() => setSuccessMsg(''), 4000);
    } catch (err) {
      console.error(err);
      toast.error('Erro ao excluir pedido de compra.');
    } finally {
      setLoading(false);
    }
  };

  // Alternar Colunas de Tamanho (Calçados: 34..39, Vestuário: P..GG, Numérico: 36..46)
  const handleSetTamanhosPreset = (preset) => {
    if (preset === 'calcados') {
      setColunasTamanhos(['34', '35', '36', '37', '38', '39']);
    } else if (preset === 'calcados_grandes') {
      setColunasTamanhos(['37', '38', '39', '40', '41', '42', '43', '44']);
    } else if (preset === 'roupas') {
      setColunasTamanhos(['P', 'M', 'G', 'GG', 'XG']);
    } else if (preset === 'numeros') {
      setColunasTamanhos(['36', '38', '40', '42', '44', '46']);
    }
  };

  // Inclusão de Linha na Matriz do Pedido
  const handleAddLinhaItem = () => {
    if (!itemLinhaForm.produto_nome.trim()) {
      toast.warning('Informe a descrição do produto.');
      return;
    }
    const vu = parseFloat(itemLinhaForm.valor_unitario) || 0;
    if (vu <= 0) {
      toast.warning('Informe o preço de custo unitário.');
      return;
    }

    // Calcula quantidade total da linha somando as colunas
    const grade = itemLinhaForm.grade_tamanhos || {};
    let totalPecasLinha = 0;
    colunasTamanhos.forEach(col => {
      totalPecasLinha += Number(grade[col] || 0);
    });

    if (totalPecasLinha <= 0) {
      toast.warning('Informe a quantidade para pelo menos um tamanho na grade.');
      return;
    }

    const vImposto = itemLinhaForm.valor_imposto > 0 ? Number(itemLinhaForm.valor_imposto) : (vu * 1.07);
    const vVista = itemLinhaForm.valor_vista > 0 ? Number(itemLinhaForm.valor_vista) : (vu * 2);
    const vDinheiro = itemLinhaForm.valor_dinheiro > 0 ? Number(itemLinhaForm.valor_dinheiro) : vVista;
    const vPrazo = itemLinhaForm.valor_prazo > 0 ? Number(itemLinhaForm.valor_prazo) : (vVista * 1.1);

    const totalLinha = totalPecasLinha * vu;

    const novaLinha = {
      ...itemLinhaForm,
      valor_unitario: vu,
      valor_imposto: vImposto,
      valor_vista: vVista,
      valor_dinheiro: vDinheiro,
      valor_prazo: vPrazo,
      total_pecas: totalPecasLinha,
      valor_total: totalLinha
    };

    setOrderForm(prev => ({
      ...prev,
      itens: [...prev.itens, novaLinha]
    }));

    // Reset Linha Form
    setItemLinhaForm({
      produto_codigo: 0,
      produto_nome: '',
      cor: 'PRETA',
      referencia: '',
      valor_unitario: 0,
      valor_imposto: 0,
      valor_dinheiro: 0,
      valor_vista: 0,
      valor_prazo: 0,
      grade_tamanhos: {}
    });
  };

  const handleUpdateLinhaGradeQtd = (linhaIndex, tamanhoCol, qtd) => {
    setOrderForm(prev => {
      const updatedItens = [...prev.itens];
      const it = { ...updatedItens[linhaIndex] };
      const grade = { ...it.grade_tamanhos, [tamanhoCol]: parseInt(qtd, 10) || 0 };
      
      let totPecas = 0;
      colunasTamanhos.forEach(c => { totPecas += Number(grade[c] || 0); });

      it.grade_tamanhos = grade;
      it.total_pecas = totPecas;
      it.valor_total = totPecas * Number(it.valor_unitario || 0);

      updatedItens[linhaIndex] = it;
      return { ...prev, itens: updatedItens };
    });
  };

  const handleRemoveLinha = (idx) => {
    setOrderForm(prev => ({
      ...prev,
      itens: prev.itens.filter((_, i) => i !== idx)
    }));
  };

  // Totais Gerais do Pedido
  const calcularTotaisPedido = () => {
    let totPecas = 0;
    let totValor = 0;
    const somasPorTamanho = {};
    colunasTamanhos.forEach(c => { somasPorTamanho[c] = 0; });

    orderForm.itens.forEach(it => {
      totPecas += Number(it.total_pecas || 0);
      totValor += Number(it.valor_total || 0);

      colunasTamanhos.forEach(c => {
        somasPorTamanho[c] += Number(it.grade_tamanhos?.[c] || 0);
      });
    });

    const desc = Number(orderForm.desconto_valor || 0);
    const imp = Number(orderForm.imposto_icms || 0);
    const valorLiquido = totValor - desc + imp;

    return {
      totalPecas: totPecas,
      totalValorBruto: totValor,
      valorLiquido: valorLiquido,
      somasPorTamanho: somasPorTamanho
    };
  };

  // Salvar Ordem de Compra
  const handleSaveOrder = async () => {
    if (!orderForm.marca.trim() && !orderForm.fornecedor_nome.trim()) {
      toast.warning('Informe a Marca ou Fornecedor do pedido.');
      return;
    }

    if (orderForm.itens.length === 0) {
      toast.warning('Adicione pelo menos um produto na matriz da ordem de compra.');
      return;
    }

    const totais = calcularTotaisPedido();
    setLoading(true);
    setError('');

    try {
      const payload = {
        ...orderForm,
        total_pecas: totais.totalPecas,
        valor_total: totais.valorLiquido,
        itens: orderForm.itens.map(it => ({
          ...it,
          grade_tamanhos: typeof it.grade_tamanhos === 'object' ? JSON.stringify(it.grade_tamanhos) : it.grade_tamanhos
        }))
      };

      await api.post('/v1/pedidos-compra', payload);
      toast.success('Ordem de Compra salva com sucesso!');
      setSuccessMsg('Ordem de Compra salva com sucesso!');
      setShowOrderModal(false);
      fetchPedidos(page);
      setTimeout(() => setSuccessMsg(''), 4000);
    } catch (err) {
      console.error(err);
      toast.error('Erro ao salvar Ordem de Compra.');
    } finally {
      setLoading(false);
    }
  };

  // Abrir Visualização / Impressão A4
  const handleOpenPrintPreview = (order) => {
    setShowPrintModal(order);
  };

  // Enviar Ordem via WhatsApp ao Representante
  const handleSendWhatsApp = (order) => {
    const repTel = (order.contato_representante || '').replace(/\D/g, '');
    if (!repTel) {
      toast.warning('Telefone do representante não informado.');
      return;
    }

    const textoMsg = `*ORDEM DE COMPRA Nº ${order.numero_ordem}*\n` +
      `*Marca:* ${order.marca}\n` +
      `*Empresa:* ${order.empresa_nome} (CNPJ: ${order.empresa_cnpj})\n` +
      `*Previsão de Entrega:* ${order.data_entrega}\n` +
      `*Condição de Pagamento:* ${order.prazo_pagamento}\n` +
      `*Total de Peças/Pares:* ${order.total_pecas}\n` +
      `*Valor Total:* ${formatCurrency(order.valor_total)}\n\n` +
      `_Pedido gerado pelo Sistema Centro de Distribuição._`;

    const url = `https://wa.me/55${repTel}?text=${encodeURIComponent(textoMsg)}`;
    window.open(url, '_blank');
  };

  const totaisGerais = calcularTotaisPedido();

  const formatOrderNumber = (ordem) => {
    if (!ordem) return '#ORD-000';
    if (ordem.startsWith('#ORD-') || ordem.startsWith('ORD-')) return ordem;
    if (ordem.startsWith('#')) return `#ORD-${ordem.substring(1)}`;
    return `#ORD-${ordem}`;
  };

  const getStatusBadge = (status) => {
    const st = (status || 'RASCUNHO').toUpperCase();
    if (st === 'ENVIADO' || st === 'APROVADO' || st === 'EMITIDO') {
      return <span className="badge badge-success">{st}</span>;
    }
    if (st === 'CANCELADO' || st === 'REJEITADO') {
      return <span className="badge badge-danger">{st}</span>;
    }
    return <span className="badge badge-warning">{st}</span>;
  };

  return (
    <div className="crud-container orders-container">
      
      {/* CABEÇALHO DA ABA ORDENS DE COMPRA */}
      <div className="orders-header glass">
        <div className="orders-header-info">
          <h2>Controle de Pedidos de Compras (Ordem de Compra)</h2>
          <p>Matriz de Grades por Tamanho & Cor • 3 Preços de Venda • Relatórios Timbrados para Fornecedores</p>
        </div>

        <div className="orders-header-actions">
          <button className="btn-secondary" onClick={() => fetchPedidos(page)}>
            <RefreshCw size={16} /> Atualizar
          </button>
          
          <button className="btn-primary" onClick={handleOpenCreateOrder}>
            <Plus size={16} /> Nova Ordem de Compra
          </button>
        </div>
      </div>

      {/* KPI METRIC CARDS */}
      <div className="orders-kpis">
        <div className="orders-kpi-card glass">
          <div className="orders-kpi-icon">
            <FileSpreadsheet size={22} />
          </div>
          <div className="orders-kpi-data">
            <span className="orders-kpi-label">Ordens de Compra</span>
            <span className="orders-kpi-value">{meta.total || pedidos.length}</span>
          </div>
        </div>

        <div className="orders-kpi-card glass">
          <div className="orders-kpi-icon">
            <Layers size={22} />
          </div>
          <div className="orders-kpi-data">
            <span className="orders-kpi-label">Total de Peças/Pares</span>
            <span className="orders-kpi-value">
              {pedidos.reduce((acc, p) => acc + (Number(p.total_pecas) || 0), 0)}
            </span>
          </div>
        </div>

        <div className="orders-kpi-card glass">
          <div className="orders-kpi-icon success">
            <DollarSign size={22} />
          </div>
          <div className="orders-kpi-data">
            <span className="orders-kpi-label">Valor Total Pedidos</span>
            <span className="orders-kpi-value" style={{ color: 'var(--success)' }}>
              {formatCurrency(pedidos.reduce((acc, p) => acc + (Number(p.valor_total) || 0), 0))}
            </span>
          </div>
        </div>

        <div className="orders-kpi-card glass">
          <div className="orders-kpi-icon">
            <Building2 size={22} />
          </div>
          <div className="orders-kpi-data">
            <span className="orders-kpi-label">Fornecedores / Marcas</span>
            <span className="orders-kpi-value">
              {new Set(pedidos.map(p => p.marca || p.fornecedor_nome).filter(Boolean)).size || fornecedores.length}
            </span>
          </div>
        </div>
      </div>

      {successMsg && <div className="feedback-banner success"><CheckCircle2 size={18} /> {successMsg}</div>}
      {error && <div className="feedback-banner error"><AlertCircle size={18} /> {error}</div>}

      {/* LISTAGEM DE ORDENS */}
      <div className="list-card glass">
        <div className="crud-table-header">
          <h3>Ordens de Compra Emitidas</h3>
          <SearchBar
            value={searchTerm}
            onChange={(val) => setSearchTerm(val)}
            onSearch={() => fetchPedidos(1)}
            onClear={() => { setSearchTerm(''); fetchPedidos(1); }}
            placeholder="Buscar por Nº Ordem, Marca, Fornecedor ou Representante..."
          />
        </div>

        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Nº Ordem</th>
                <th>Marca / Fornecedor</th>
                <th>Representante</th>
                <th>Filial / Comprador</th>
                <th>Previsão Entrega</th>
                <th style={{ textAlign: 'center' }}>Total Peças</th>
                <th style={{ textAlign: 'right' }}>Valor Total</th>
                <th>Status</th>
                <th style={{ textAlign: 'center' }}>Ações</th>
              </tr>
            </thead>
            <tbody>
              {pedidos.length === 0 ? (
                <tr>
                  <td colSpan="9" style={{ textAlign: 'center', padding: '2.5rem', color: 'var(--text-secondary)' }}>
                    Nenhuma ordem de compra registrada. Clique em "Nova Ordem de Compra" para criar.
                  </td>
                </tr>
              ) : (
                pedidos.map(p => (
                  <tr key={p.id}>
                    <td>
                      <span className="item-code">{formatOrderNumber(p.numero_ordem || p.id)}</span>
                    </td>
                    <td><span className="badge badge-info">{p.marca || p.fornecedor_nome}</span></td>
                    <td>
                      <div><strong>{p.representante || '-'}</strong></div>
                      {p.contato_representante && (
                        <small style={{ color: 'var(--text-secondary)' }}>{p.contato_representante}</small>
                      )}
                    </td>
                    <td>{p.empresa_nome || p.local_pedido}</td>
                    <td>{p.data_entrega || '-'}</td>
                    <td style={{ textAlign: 'center' }}><strong>{p.total_pecas}</strong></td>
                    <td style={{ textAlign: 'right', fontWeight: 800, color: 'var(--success)' }}>
                      {formatCurrency(p.valor_total)}
                    </td>
                    <td>{getStatusBadge(p.status)}</td>
                    <td style={{ textAlign: 'center' }}>
                      <div className="actions-cell" style={{ justifyContent: 'center' }}>
                        <button 
                          className="action-btn" 
                          onClick={() => handleOpenPrintPreview(p)} 
                          title="Visualizar / Imprimir Espelho do Pedido"
                        >
                          <Printer size={15} />
                        </button>
                        <button 
                          className="action-btn edit" 
                          onClick={() => handleOpenEditOrder(p)} 
                          title="Editar Ordem de Compra"
                        >
                          <Edit2 size={15} />
                        </button>
                        <button 
                          className="action-btn delete" 
                          onClick={() => handleDeleteOrder(p.id)} 
                          title="Excluir Ordem de Compra"
                        >
                          <Trash2 size={15} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <Pagination 
          page={page}
          pages={meta.pages}
          total={meta.total}
          limit={meta.limit}
          onPageChange={(p) => fetchPedidos(p)}
        />
      </div>

      {/* RODAPÉ COM ATALHOS DE TECLADO */}
      <div className="orders-footer-shortcuts">
        <div className="orders-shortcut-item">
          <kbd>F2</kbd> Nova Ordem de Compra
        </div>
        <div className="orders-shortcut-item">
          <kbd>F5</kbd> Atualizar Lista
        </div>
        <div className="orders-shortcut-item">
          <kbd>ESC</kbd> Fechar Modal
        </div>
      </div>

      {/* ========================================================================= */}
      {/* MODAL DE CRIAÇÃO / EDIÇÃO DA ORDEM DE COMPRA (PADRÃO MATRIZ EXCEL)       */}
      {/* ========================================================================= */}
      {showOrderModal && (
        <div className="product-form-modal-overlay modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setShowOrderModal(false); }}>
          <div className="product-form-modal-container modal-content glass" style={{ maxWidth: '1280px', maxHeight: '92vh' }}>
            
            {/* CABEÇALHO DO MODAL */}
            <div className="product-modal-header">
              <div className="product-modal-title-group">
                <div className="product-modal-icon-badge">
                  <FileSpreadsheet size={22} />
                </div>
                <div>
                  <h3>Ordem de Compra Nº {orderForm.numero_ordem || 'NOVA'}</h3>
                  <span className="product-modal-subtitle">Matriz de Grade por Produto & 3 Preços de Venda • Fornecedores</span>
                </div>
              </div>
              <button className="btn-close" onClick={() => setShowOrderModal(false)} title="Fechar (ESC)">
                <X size={20} />
              </button>
            </div>

            <div className="product-modal-body">
              
              {/* CABEÇALHO COMERCIAL DA ORDEM DE COMPRA */}
              <div className="list-card glass order-section-card">
                <div className="product-section-title">
                  <Building2 size={16} color="var(--accent)" /> Dados do Pedido & Condições Comerciais
                </div>

                <div className="product-grid-4">
                  <div className="form-group">
                    <label>Nº Ordem de Compra *</label>
                    <input 
                      type="text" 
                      value={orderForm.numero_ordem} 
                      onChange={(e) => setOrderForm({ ...orderForm, numero_ordem: e.target.value })} 
                      placeholder="Ex: 002/2026" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Marca / Fabricante *</label>
                    <LookupSelect
                      value={orderForm.fornecedor_id || orderForm.marca}
                      displayValue={orderForm.marca || (orderForm.fornecedor_id ? `#${orderForm.fornecedor_id} - ${orderForm.fornecedor_nome}` : '')}
                      placeholder="Buscar Fornecedor..."
                      title="Selecionar Marca / Fornecedor"
                      subtitle="Busca paginada por Razão Social, Fantasia ou Código"
                      icon={Building2}
                      searchPlaceholder="Digite o nome, marca, CNPJ ou código..."
                      fetchData={async (termo, targetPage, limit) => {
                        let url = `/v1/fornecedores?page=${targetPage}&limit=${limit}`;
                        if (termo) url += `&busca=${encodeURIComponent(termo)}`;
                        const res = await api.get(url);
                        return res.data;
                      }}
                      columns={[
                        { key: 'codigo', label: 'Código', width: '90px', render: (f) => <span className="item-code">#{f.codigo}</span> },
                        { key: 'nome', label: 'Razão Social / Nome', render: (f) => <strong>{f.nome || f.razao_social || '-'}</strong> },
                        { key: 'fantasia', label: 'Nome Fantasia' },
                        { key: 'cidade', label: 'Cidade / UF', render: (f) => `${f.cidade || ''} - ${f.uf || ''}` }
                      ]}
                      onSelect={(forn) => {
                        setOrderForm(prev => ({
                          ...prev,
                          fornecedor_id: forn.codigo,
                          fornecedor_nome: forn.nome || forn.razao_social,
                          marca: forn.fantasia || forn.nome || forn.razao_social
                        }));
                      }}
                      onClear={() => {
                        setOrderForm(prev => ({ ...prev, fornecedor_id: '', fornecedor_nome: '', marca: '' }));
                      }}
                    />
                  </div>

                  <div className="form-group">
                    <label>Representante *</label>
                    <input 
                      type="text" 
                      value={orderForm.representante} 
                      onChange={(e) => setOrderForm({ ...orderForm, representante: e.target.value })} 
                      placeholder="Ex: ADEMIR" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Contato / WhatsApp Rep.</label>
                    <input 
                      type="text" 
                      value={orderForm.contato_representante} 
                      onChange={(e) => setOrderForm({ ...orderForm, contato_representante: e.target.value })} 
                      placeholder="Ex: 67981353840" 
                    />
                  </div>

                  <div className="form-group" style={{ gridColumn: 'span 2' }}>
                    <label>Empresa Compradora / Filial *</label>
                    <input 
                      type="text" 
                      value={orderForm.empresa_nome} 
                      onChange={(e) => setOrderForm({ ...orderForm, empresa_nome: e.target.value })} 
                      placeholder="Ex: GIGANTE ROUPAS E CALÇADOS" 
                    />
                  </div>

                  <div className="form-group">
                    <label>CNPJ Comprador</label>
                    <input 
                      type="text" 
                      value={orderForm.empresa_cnpj} 
                      onChange={(e) => setOrderForm({ ...orderForm, empresa_cnpj: e.target.value })} 
                      placeholder="31.797.325.0003-32" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Local do Pedido</label>
                    <input 
                      type="text" 
                      value={orderForm.local_pedido} 
                      onChange={(e) => setOrderForm({ ...orderForm, local_pedido: e.target.value })} 
                      placeholder="Ex: DOURADINA" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Previsão de Entrega *</label>
                    <input 
                      type="text" 
                      value={orderForm.data_entrega} 
                      onChange={(e) => setOrderForm({ ...orderForm, data_entrega: e.target.value })} 
                      placeholder="Ex: ABRIL / 2026" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Local de Entrega</label>
                    <input 
                      type="text" 
                      value={orderForm.local_entrega} 
                      onChange={(e) => setOrderForm({ ...orderForm, local_entrega: e.target.value })} 
                      placeholder="Ex: ITAPORÃ" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Prazo de Pagamento *</label>
                    <input 
                      type="text" 
                      value={orderForm.prazo_pagamento} 
                      onChange={(e) => setOrderForm({ ...orderForm, prazo_pagamento: e.target.value })} 
                      placeholder="Ex: 60/90/120/150/180" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Nota / Faturamento Fiscal</label>
                    <input 
                      type="text" 
                      value={orderForm.observacao} 
                      onChange={(e) => setOrderForm({ ...orderForm, observacao: e.target.value })} 
                      placeholder="Ex: NOTA 70%" 
                    />
                  </div>
                </div>
              </div>

              {/* SELETOR DE PRESETS DE GRADE DE TAMANHOS */}
              <div className="list-card glass order-section-card" style={{ display: 'flex', flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.8rem' }}>
                <div className="grade-preset-group">
                  <span style={{ fontWeight: 700, fontSize: '0.88rem', color: 'var(--text-primary)' }}>Configuração de Grade da Matriz:</span>
                  <button type="button" className={`grade-preset-chip ${colunasTamanhos.join('') === '343536373839' ? 'active' : ''}`} onClick={() => handleSetTamanhosPreset('calcados')}>
                    Calçados (34 a 39)
                  </button>
                  <button type="button" className={`grade-preset-chip ${colunasTamanhos.join('') === '3738394041424344' ? 'active' : ''}`} onClick={() => handleSetTamanhosPreset('calcados_grandes')}>
                    Calçados Grandes (37 a 44)
                  </button>
                  <button type="button" className={`grade-preset-chip ${colunasTamanhos.join('') === 'PMGXXG' || colunasTamanhos.join('') === 'PMGGG' ? 'active' : ''}`} onClick={() => handleSetTamanhosPreset('roupas')}>
                    Vestuário (P a XG)
                  </button>
                  <button type="button" className={`grade-preset-chip ${colunasTamanhos.join('') === '363840424446' ? 'active' : ''}`} onClick={() => handleSetTamanhosPreset('numeros')}>
                    Calças (36 a 46)
                  </button>
                </div>
              </div>

              {/* FORMULÁRIO DE INCLUSÃO DE PRODUTO NA GRADE MATRIZ */}
              <div className="list-card glass order-section-card">
                <div className="product-section-title">
                  <Package size={16} color="var(--success)" /> Adicionar Produto / Referência na Matriz
                </div>

                <div className="orders-quick-add-grid">
                  <div className="form-group">
                    <label>Descrição do Produto *</label>
                    <LookupSelect
                      value={itemLinhaForm.produto_id || itemLinhaForm.produto_nome}
                      displayValue={itemLinhaForm.produto_nome}
                      placeholder="Buscar do catálogo ou digitar..."
                      title="Selecionar Produto do Catálogo"
                      subtitle="Busca paginada por Descrição, Código ou Referência"
                      icon={Package}
                      searchPlaceholder="Digite a descrição, código ou referência..."
                      fetchData={async (termo, targetPage, limit) => {
                        let url = `/v1/produtos?page=${targetPage}&limit=${limit}`;
                        if (termo) url += `&busca=${encodeURIComponent(termo)}&termo=${encodeURIComponent(termo)}`;
                        const res = await api.get(url);
                        return res.data;
                      }}
                      columns={[
                        { key: 'codigo', label: 'Código', width: '90px', render: (p) => <span className="item-code">#{p.codigo || p.PRO_CODIGO}</span> },
                        { key: 'nome', label: 'Descrição do Produto', render: (p) => <strong>{p.nome || p.PRO_NOME || p.descricao}</strong> },
                        { key: 'referencia', label: 'Referência', render: (p) => p.referencia || p.PRO_REFERENCIA || '-' },
                        { key: 'cor', label: 'Cor', render: (p) => p.cor || p.PRO_COR || '-' },
                        { key: 'custo', label: 'Custo', align: 'right', render: (p) => formatCurrency(p.custo || p.PRO_VALORC || 0) },
                        { key: 'valorv', label: 'Preço Venda', align: 'right', render: (p) => <strong style={{ color: 'var(--success)' }}>{formatCurrency(p.valorv || p.PRO_VALORV || 0)}</strong> }
                      ]}
                      onSelect={(prod) => {
                        const vu = Number(prod.custo || prod.PRO_VALORC || prod.valorc || 0);
                        const vv = Number(prod.valorv || prod.PRO_VALORV || (vu * 2));
                        const vd = Number(prod.pro_valor_dinheiro || prod.valor_dinheiro || vv);
                        const vp = Number(prod.pro_valorv_prazo || prod.valor_prazo || (vu * 2.2));

                        setItemLinhaForm(prev => ({
                          ...prev,
                          produto_id: prod.codigo || prod.PRO_CODIGO,
                          produto_nome: prod.nome || prod.PRO_NOME || prod.descricao,
                          cor: prod.cor || prod.PRO_COR || prev.cor || 'UNICA',
                          referencia: prod.referencia || prod.PRO_REFERENCIA || prev.referencia || '',
                          valor_unitario: vu,
                          valor_imposto: vu * 1.07,
                          valor_vista: vv,
                          valor_dinheiro: vd,
                          valor_prazo: vp
                        }));
                      }}
                      onClear={() => {
                        setItemLinhaForm(prev => ({ ...prev, produto_id: 0, produto_nome: '' }));
                      }}
                    />
                  </div>

                  <div className="form-group">
                    <label>Cor *</label>
                    <input 
                      type="text" 
                      value={itemLinhaForm.cor} 
                      onChange={(e) => setItemLinhaForm({ ...itemLinhaForm, cor: e.target.value })} 
                      placeholder="Ex: MARROM, PRETA" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Referência (REF)</label>
                    <input 
                      type="text" 
                      value={itemLinhaForm.referencia} 
                      onChange={(e) => setItemLinhaForm({ ...itemLinhaForm, referencia: e.target.value })} 
                      placeholder="Ex: 72110" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Preço Custo Unit. (R$) *</label>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={itemLinhaForm.valor_unitario} 
                      onChange={(e) => {
                        const vu = parseFloat(e.target.value) || 0;
                        setItemLinhaForm({
                          ...itemLinhaForm,
                          valor_unitario: vu,
                          valor_imposto: vu * 1.07,
                          valor_vista: vu * 2,
                          valor_dinheiro: vu * 2,
                          valor_prazo: vu * 2.2
                        });
                      }} 
                    />
                  </div>

                  <div className="form-group">
                    <label>Preço c/ Imposto (R$)</label>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={itemLinhaForm.valor_imposto} 
                      onChange={(e) => setItemLinhaForm({ ...itemLinhaForm, valor_imposto: parseFloat(e.target.value) || 0 })} 
                    />
                  </div>

                  <div>
                    <button type="button" className="btn-primary" onClick={handleAddLinhaItem} style={{ height: '38px', padding: '0 1.2rem', whiteSpace: 'nowrap' }}>
                      <Plus size={16} /> Incluir Linha
                    </button>
                  </div>
                </div>

                {/* MATRIZ DE GRADE POR PRODUTO (TABELA DINÂMICA COMPLETA) */}
                <div className="table-responsive" style={{ maxHeight: '350px', overflowY: 'auto' }}>
                  <table className="data-table" style={{ fontSize: '0.85rem' }}>
                    <thead>
                      <tr>
                        <th>Produto / Descrição</th>
                        <th>Cor</th>
                        <th>REF</th>
                        <th style={{ textAlign: 'right' }}>Preço Unit.</th>
                        <th style={{ textAlign: 'right' }}>P/ Imposto</th>
                        
                        {/* COLUNAS DE TAMANHOS DINÂMICAS */}
                        {colunasTamanhos.map(col => (
                          <th key={col} style={{ textAlign: 'center', minWidth: '48px', background: 'rgba(0, 0, 0, 0.03)' }}>
                            {col}
                          </th>
                        ))}

                        <th style={{ textAlign: 'center', background: 'rgba(249, 115, 22, 0.08)', fontWeight: 800, color: 'var(--accent)' }}>TOTAL</th>
                        <th style={{ textAlign: 'right', background: 'rgba(0, 108, 73, 0.08)', fontWeight: 800, color: 'var(--success)' }}>VALOR R$</th>
                        <th style={{ textAlign: 'center' }}>Ações</th>
                      </tr>
                    </thead>
                    <tbody>
                      {orderForm.itens.length === 0 ? (
                        <tr>
                          <td colSpan={colunasTamanhos.length + 8} style={{ textAlign: 'center', padding: '2.5rem', color: 'var(--text-secondary)' }}>
                            Nenhum produto adicionado na ordem de compra. Use o formulário acima para adicionar linhas.
                          </td>
                        </tr>
                      ) : (
                        orderForm.itens.map((it, idx) => (
                          <tr key={idx}>
                            <td><strong>{it.produto_nome}</strong></td>
                            <td><span className="sigla-tag">{it.cor || 'UNICA'}</span></td>
                            <td><code>{it.referencia || '-'}</code></td>
                            <td style={{ textAlign: 'right' }}>{formatCurrency(it.valor_unitario)}</td>
                            <td style={{ textAlign: 'right', color: 'var(--text-secondary)' }}>{formatCurrency(it.valor_imposto)}</td>

                            {/* CÉLULAS DA GRADE DE TAMANHOS */}
                            {colunasTamanhos.map(col => (
                              <td key={col} style={{ textAlign: 'center', padding: '4px' }}>
                                <input 
                                  type="number" 
                                  min="0"
                                  className="matrix-input-cell"
                                  value={it.grade_tamanhos?.[col] || 0} 
                                  onChange={(e) => handleUpdateLinhaGradeQtd(idx, col, e.target.value)} 
                                />
                              </td>
                            ))}

                            <td style={{ textAlign: 'center', fontWeight: 800, background: 'rgba(249, 115, 22, 0.04)' }}>
                              {it.total_pecas}
                            </td>
                            <td style={{ textAlign: 'right', fontWeight: 800, color: 'var(--success)', background: 'rgba(0, 108, 73, 0.04)' }}>
                              {formatCurrency(it.valor_total)}
                            </td>
                            <td style={{ textAlign: 'center' }}>
                              <button className="action-btn delete" onClick={() => handleRemoveLinha(idx)} title="Remover Linha">
                                <Trash2 size={14} />
                              </button>
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>

                    {/* RODAPÉ COM TOTALIZADORES POR COLUNA */}
                    {orderForm.itens.length > 0 && (
                      <tfoot>
                        <tr className="matrix-total-row">
                          <td colSpan="5" style={{ textAlign: 'right' }}>TOTAL DE PEÇAS / TAMANHO:</td>
                          {colunasTamanhos.map(col => (
                            <td key={col} style={{ textAlign: 'center', color: 'var(--text-primary)', fontWeight: 800 }}>
                              {totaisGerais.somasPorTamanho[col]}
                            </td>
                          ))}
                          <td style={{ textAlign: 'center', color: 'var(--accent)', fontSize: '1rem', fontWeight: 800 }}>
                            {totaisGerais.totalPecas}
                          </td>
                          <td style={{ textAlign: 'right', color: 'var(--success)', fontSize: '1.05rem', fontWeight: 800 }}>
                            {formatCurrency(totaisGerais.totalValorBruto)}
                          </td>
                          <td></td>
                        </tr>
                      </tfoot>
                    )}
                  </table>
                </div>

              </div>

            </div>

            {/* RODAPÉ DO MODAL */}
            <div className="product-modal-footer">
              <div style={{ display: 'flex', gap: '2rem', alignItems: 'center', flexWrap: 'wrap' }}>
                <div>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', display: 'block', fontWeight: 600 }}>TOTAL DE PEÇAS:</span>
                  <strong style={{ fontSize: '1.25rem', color: 'var(--accent)' }}>{totaisGerais.totalPecas} pares/peças</strong>
                </div>

                <div>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', display: 'block', fontWeight: 600 }}>VALOR TOTAL DA ORDEM:</span>
                  <strong style={{ fontSize: '1.35rem', color: 'var(--success)' }}>{formatCurrency(totaisGerais.valorLiquido)}</strong>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '0.8rem', alignItems: 'center' }}>
                <button type="button" className="btn-secondary" onClick={() => setShowOrderModal(false)}>Cancelar</button>
                <button type="button" className="btn-primary" onClick={handleSaveOrder} disabled={loading} style={{ minWidth: '190px' }}>
                  {loading ? <RefreshCw size={18} className="spinner" /> : <Save size={18} />} Salvar Ordem de Compra
                </button>
              </div>
            </div>

          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL DE IMPRESSÃO / RELATÓRIO TIMBRADO A4 (PARA FORNECEDOR)             */}
      {/* ========================================================================= */}
      {showPrintModal && (
        <div className="product-form-modal-overlay modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setShowPrintModal(null); }}>
          <div className="product-form-modal-container modal-content glass" style={{ maxWidth: '980px', background: '#ffffff', borderRadius: '1.5rem' }}>
            
            <div className="product-modal-header">
              <div className="product-modal-title-group">
                <div className="product-modal-icon-badge">
                  <Printer size={22} />
                </div>
                <div>
                  <h3>Relatório Timbrado da Ordem de Compra</h3>
                  <span className="product-modal-subtitle">Pronto para Impressão A4 ou Envio via WhatsApp ao Representante</span>
                </div>
              </div>
              <button className="btn-close" onClick={() => setShowPrintModal(null)} title="Fechar (ESC)">
                <X size={20} />
              </button>
            </div>

            {/* ÁREA DE IMPRESSÃO A4 */}
            <div className="product-modal-body" style={{ background: '#ffffff', padding: '2rem' }}>
              <div ref={printRef} className="orders-print-sheet">
                
                {/* CABEÇALHO TIMBRADO */}
                <div className="orders-print-header">
                  <div>
                    <h2 className="orders-print-title">ORDEM DE COMPRA: {showPrintModal.numero_ordem || `#${showPrintModal.id}`}</h2>
                    <div className="orders-print-subtitle">
                      <strong>Marca:</strong> {showPrintModal.marca} | <strong>Representante:</strong> {showPrintModal.representante} ({showPrintModal.contato_representante})
                    </div>
                  </div>

                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontWeight: 800, fontSize: '1.1rem', color: '#0f172a' }}>{showPrintModal.empresa_nome}</div>
                    <div style={{ fontSize: '0.8rem', color: '#64748b' }}>CNPJ: {showPrintModal.empresa_cnpj}</div>
                    <div style={{ fontSize: '0.8rem', color: '#64748b' }}>Data: {new Date(showPrintModal.data_pedido || Date.now()).toLocaleDateString('pt-BR')}</div>
                  </div>
                </div>

                {/* CONDIÇÕES COMERCIAIS */}
                <div className="orders-print-conditions">
                  <div><strong>Local do Pedido:</strong> {showPrintModal.local_pedido}</div>
                  <div><strong>Previsão de Entrega:</strong> {showPrintModal.data_entrega}</div>
                  <div><strong>Local de Entrega:</strong> {showPrintModal.local_entrega}</div>
                  <div><strong>Prazo Pagamento:</strong> {showPrintModal.prazo_pagamento}</div>
                  <div><strong>Faturamento:</strong> {showPrintModal.observacao}</div>
                  <div><strong>Status:</strong> {showPrintModal.status}</div>
                </div>

                {/* TABELA DA MATRIZ DE ITENS */}
                <table className="orders-print-table">
                  <thead>
                    <tr>
                      <th style={{ textAlign: 'left' }}>Produto</th>
                      <th style={{ textAlign: 'left' }}>Cor</th>
                      <th style={{ textAlign: 'left' }}>REF</th>
                      <th style={{ textAlign: 'right' }}>Preço</th>
                      {colunasTamanhos.map(col => (
                        <th key={col} style={{ textAlign: 'center' }}>{col}</th>
                      ))}
                      <th style={{ textAlign: 'center' }}>Total</th>
                      <th style={{ textAlign: 'right' }}>Valor R$</th>
                    </tr>
                  </thead>
                  <tbody>
                    {(showPrintModal.itens || []).map((it, idx) => {
                      let grade = {};
                      try {
                        grade = typeof it.grade_tamanhos === 'string' ? JSON.parse(it.grade_tamanhos) : (it.grade_tamanhos || {});
                      } catch (e) { grade = {}; }

                      return (
                        <tr key={idx}>
                          <td><strong>{it.produto_nome}</strong></td>
                          <td>{it.cor}</td>
                          <td>{it.referencia}</td>
                          <td style={{ textAlign: 'right' }}>{formatCurrency(it.valor_unitario)}</td>
                          {colunasTamanhos.map(col => (
                            <td key={col} style={{ textAlign: 'center' }}>
                              {grade[col] || 0}
                            </td>
                          ))}
                          <td style={{ textAlign: 'center', fontWeight: 800 }}>{it.total_pecas}</td>
                          <td style={{ textAlign: 'right', fontWeight: 800 }}>{formatCurrency(it.valor_total)}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                  <tfoot>
                    <tr style={{ background: '#e2e8f0', fontWeight: 800 }}>
                      <td colSpan="4" style={{ textAlign: 'right' }}>TOTAIS:</td>
                      {colunasTamanhos.map(col => {
                        let som = 0;
                        (showPrintModal.itens || []).forEach(it => {
                          try {
                            const g = typeof it.grade_tamanhos === 'string' ? JSON.parse(it.grade_tamanhos) : (it.grade_tamanhos || {});
                            som += Number(g[col] || 0);
                          } catch (e) {}
                        });
                        return <td key={col} style={{ textAlign: 'center' }}>{som}</td>;
                      })}
                      <td style={{ textAlign: 'center', fontSize: '0.9rem' }}>{showPrintModal.total_pecas}</td>
                      <td style={{ textAlign: 'right', fontSize: '0.95rem', color: '#16a34a' }}>{formatCurrency(showPrintModal.valor_total)}</td>
                    </tr>
                  </tfoot>
                </table>

                {/* ASSINATURAS */}
                <div className="orders-print-signatures">
                  <div>
                    <strong>{showPrintModal.empresa_nome}</strong>
                    <div>Comprador Responsável</div>
                  </div>
                  <div>
                    <strong>{showPrintModal.representante} ({showPrintModal.marca})</strong>
                    <div>Representante Comercial</div>
                  </div>
                </div>

              </div>
            </div>

            {/* RODAPÉ DO MODAL DE IMPRESSÃO */}
            <div className="product-modal-footer">
              <button type="button" className="btn-secondary" onClick={() => setShowPrintModal(null)}>
                Fechar
              </button>

              <div style={{ display: 'flex', gap: '0.8rem', alignItems: 'center' }}>
                <button 
                  type="button" 
                  className="btn-secondary btn-whatsapp" 
                  onClick={() => handleSendWhatsApp(showPrintModal)}
                >
                  <Share2 size={16} /> Enviar via WhatsApp
                </button>
                <button 
                  type="button" 
                  className="btn-secondary btn-print-primary" 
                  onClick={() => window.print()}
                >
                  <Printer size={16} /> Imprimir Espelho (A4)
                </button>
              </div>
            </div>

          </div>
        </div>
      )}

    </div>
  );
}
