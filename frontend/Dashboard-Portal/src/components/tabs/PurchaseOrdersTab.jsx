import React, { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { 
  FileSpreadsheet, Plus, Trash2, Edit2, Eye, Printer, Send, 
  Search, RefreshCw, CheckCircle2, AlertCircle, Building2, 
  Calendar, DollarSign, Package, Sparkles, X, Save, Share2, 
  ArrowRight, Layers, FileText
} from 'lucide-react';
import { createApi } from '../../services/api';
import SearchBar from '../SearchBar';
import Pagination from '../Pagination';
import { formatCurrency } from '../../utils/formatters';
import './CadastrosTab.css';

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
      alert('Erro ao carregar detalhes do pedido de compra.');
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
      alert('Erro ao excluir pedido de compra.');
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
      alert('Informe a descrição do produto.');
      return;
    }
    const vu = parseFloat(itemLinhaForm.valor_unitario) || 0;
    if (vu <= 0) {
      alert('Informe o preço de custo unitário.');
      return;
    }

    // Calcula quantidade total da linha somando as colunas
    const grade = itemLinhaForm.grade_tamanhos || {};
    let totalPecasLinha = 0;
    colunasTamanhos.forEach(col => {
      totalPecasLinha += Number(grade[col] || 0);
    });

    if (totalPecasLinha <= 0) {
      alert('Informe a quantidade para pelo menos um tamanho na grade.');
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
      alert('Informe a Marca ou Fornecedor do pedido.');
      return;
    }

    if (orderForm.itens.length === 0) {
      alert('Adicione pelo menos um produto na matriz da ordem de compra.');
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
      setSuccessMsg('Ordem de Compra salva com sucesso!');
      setShowOrderModal(false);
      fetchPedidos(page);
      setTimeout(() => setSuccessMsg(''), 4000);
    } catch (err) {
      console.error(err);
      alert('Erro ao salvar Ordem de Compra.');
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
      alert('Telefone do representante não informado.');
      return;
    }

    const totais = calcularTotaisPedido();
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

  return (
    <div className="tab-container">
      
      {/* CABEÇALHO DA ABA */}
      <div className="tab-header glass">
        <div>
          <h2>Controle de Pedidos de Compras (Ordem de Compra)</h2>
          <p className="tab-subtitle">Matriz de Grades por Tamanho & Cor • 3 Preços de Venda • Relatórios Timbrados para Fornecedores</p>
        </div>

        <div className="tab-header-actions" style={{ display: 'flex', gap: '0.6rem' }}>
          <button className="btn-secondary" onClick={() => fetchPedidos(page)}>
            <RefreshCw size={16} /> Atualizar
          </button>
          
          <button className="btn-primary" onClick={handleOpenCreateOrder} style={{ background: 'linear-gradient(135deg, #7c3aed, #6d28d9)' }}>
            <Plus size={16} /> + Nova Ordem de Compra
          </button>
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
                  <td colSpan="9" style={{ textAlign: 'center', padding: '2rem', color: '#94a3b8' }}>
                    Nenhuma ordem de compra registrada. Clique em "+ Nova Ordem de Compra" para criar.
                  </td>
                </tr>
              ) : (
                pedidos.map(p => (
                  <tr key={p.id}>
                    <td><strong>{p.numero_ordem || `#${p.id}`}</strong></td>
                    <td><span className="badge badge-info">{p.marca || p.fornecedor_nome}</span></td>
                    <td>
                      <div>{p.representante || '-'}</div>
                      <small style={{ color: '#64748b' }}>{p.contato_representante}</small>
                    </td>
                    <td>{p.empresa_nome || p.local_pedido}</td>
                    <td>{p.data_entrega || '-'}</td>
                    <td style={{ textAlign: 'center' }}><strong>{p.total_pecas}</strong></td>
                    <td style={{ textAlign: 'right', fontWeight: 800, color: '#16a34a' }}>{formatCurrency(p.valor_total)}</td>
                    <td><span className={`badge ${p.status === 'ENVIADO' ? 'badge-success' : 'badge-warning'}`}>{p.status}</span></td>
                    <td style={{ textAlign: 'center' }}>
                      <button className="crud-row-btn" onClick={() => handleOpenPrintPreview(p)} title="Imprimir / Relatório Timbrado A4" style={{ color: '#2563eb' }}>
                        <Printer size={14} />
                      </button>
                      <button className="crud-row-btn edit" onClick={() => handleOpenEditOrder(p)} title="Editar Ordem">
                        <Edit2 size={14} />
                      </button>
                      <button className="crud-row-btn delete" onClick={() => handleDeleteOrder(p.id)} title="Excluir Ordem">
                        <Trash2 size={14} />
                      </button>
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

      {/* ========================================================================= */}
      {/* MODAL DE CRIAÇÃO / EDIÇÃO DA ORDEM DE COMPRA (PADRÃO MOONCITY EXCEL)     */}
      {/* ========================================================================= */}
      {showOrderModal && (
        <div className="product-form-modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setShowOrderModal(false); }}>
          <div className="product-form-modal-container glass" style={{ maxWidth: '1250px', maxHeight: '92vh' }}>
            
            {/* CABEÇALHO */}
            <div className="product-modal-header" style={{ background: 'linear-gradient(135deg, #7c3aed, #6d28d9)', color: '#ffffff' }}>
              <div className="product-modal-title-group">
                <div className="product-modal-icon-badge" style={{ background: 'rgba(255, 255, 255, 0.2)' }}>
                  <FileSpreadsheet size={22} color="#ffffff" />
                </div>
                <div>
                  <h3 style={{ color: '#ffffff' }}>Ordem de Compra Nº {orderForm.numero_ordem}</h3>
                  <span className="product-modal-subtitle" style={{ color: '#ddd6fe' }}>Modelo Oficial MOONCITY • Matriz de Grade por Produto & 3 Preços de Venda</span>
                </div>
              </div>
              <button className="btn-close" onClick={() => setShowOrderModal(false)} style={{ color: '#ffffff' }}><X size={20} /></button>
            </div>

            <div className="product-modal-body">
              
              {/* CABEÇALHO COMERCIAL DA ORDEM DE COMPRA */}
              <div className="product-section-card">
                <div className="product-section-title">
                  <Building2 size={16} color="#7c3aed" /> Dados do Pedido & Condições Comerciais
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
                    <input 
                      type="text" 
                      value={orderForm.marca} 
                      onChange={(e) => setOrderForm({ ...orderForm, marca: e.target.value })} 
                      placeholder="Ex: MOONCITY" 
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
              <div className="product-section-card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.8rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
                  <span style={{ fontWeight: 700, fontSize: '0.88rem' }}>Configuração de Grade da Matriz:</span>
                  <button type="button" className="btn-secondary small" onClick={() => handleSetTamanhosPreset('calcados')}>
                    👟 Calçados (34 a 39)
                  </button>
                  <button type="button" className="btn-secondary small" onClick={() => handleSetTamanhosPreset('calcados_grandes')}>
                    👟 Calçados Grandes (37 a 44)
                  </button>
                  <button type="button" className="btn-secondary small" onClick={() => handleSetTamanhosPreset('roupas')}>
                    👕 Vestuário (P a XG)
                  </button>
                  <button type="button" className="btn-secondary small" onClick={() => handleSetTamanhosPreset('numeros')}>
                    👖 Calças (36 a 46)
                  </button>
                </div>
              </div>

              {/* FORMULÁRIO DE INCLUSÃO DE PRODUTO NA GRADE MATRIZ */}
              <div className="product-section-card">
                <div className="product-section-title">
                  <Package size={16} color="#059669" /> Adicionar Produto / Referência na Matriz
                </div>

                <div className="grade-quick-form" style={{ gridTemplateColumns: '2fr 1fr 1fr 1fr 1fr auto' }}>
                  <div className="form-group">
                    <label>Descrição do Produto *</label>
                    <input 
                      type="text" 
                      value={itemLinhaForm.produto_nome} 
                      onChange={(e) => setItemLinhaForm({ ...itemLinhaForm, produto_nome: e.target.value })} 
                      placeholder="Ex: BOTA CANO ALTO" 
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
                      + Incluir Linha
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
                          <th key={col} style={{ textAlign: 'center', minWidth: '45px', background: '#f1f5f9' }}>
                            {col}
                          </th>
                        ))}

                        <th style={{ textAlign: 'center', background: '#e2e8f0', fontWeight: 800 }}>TOTAL</th>
                        <th style={{ textAlign: 'right', background: '#e2e8f0', fontWeight: 800 }}>VALOR R$</th>
                        <th style={{ textAlign: 'center' }}>Ações</th>
                      </tr>
                    </thead>
                    <tbody>
                      {orderForm.itens.length === 0 ? (
                        <tr>
                          <td colSpan={colunasTamanhos.length + 8} style={{ textAlign: 'center', padding: '2rem', color: '#94a3b8' }}>
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
                            <td style={{ textAlign: 'right', color: '#64748b' }}>{formatCurrency(it.valor_imposto)}</td>

                            {/* CÉLULAS DA GRADE DE TAMANHOS */}
                            {colunasTamanhos.map(col => (
                              <td key={col} style={{ textAlign: 'center', padding: '2px' }}>
                                <input 
                                  type="number" 
                                  min="0"
                                  value={it.grade_tamanhos?.[col] || 0} 
                                  onChange={(e) => handleUpdateLinhaGradeQtd(idx, col, e.target.value)} 
                                  style={{ width: '45px', textAlign: 'center', padding: '2px', fontWeight: 700 }}
                                />
                              </td>
                            ))}

                            <td style={{ textAlign: 'center', fontWeight: 800, background: '#f8fafc' }}>
                              {it.total_pecas}
                            </td>
                            <td style={{ textAlign: 'right', fontWeight: 800, color: '#16a34a', background: '#f8fafc' }}>
                              {formatCurrency(it.valor_total)}
                            </td>
                            <td style={{ textAlign: 'center' }}>
                              <button className="crud-row-btn delete" onClick={() => handleRemoveLinha(idx)} title="Remover Linha">
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
                        <tr style={{ background: '#f1f5f9', fontWeight: 800 }}>
                          <td colSpan="5" style={{ textAlign: 'right' }}>TOTAL DE PEÇAS / TAMANHO:</td>
                          {colunasTamanhos.map(col => (
                            <td key={col} style={{ textAlign: 'center', color: '#2563eb' }}>
                              {totaisGerais.somasPorTamanho[col]}
                            </td>
                          ))}
                          <td style={{ textAlign: 'center', color: '#7c3aed', fontSize: '1rem' }}>
                            {totaisGerais.totalPecas}
                          </td>
                          <td style={{ textAlign: 'right', color: '#16a34a', fontSize: '1.1rem' }}>
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
              <div style={{ display: 'flex', gap: '1.5rem', alignItems: 'center' }}>
                <div>
                  <span style={{ fontSize: '0.75rem', color: '#64748b', display: 'block' }}>TOTAL DE PEÇAS:</span>
                  <strong style={{ fontSize: '1.2rem', color: '#7c3aed' }}>{totaisGerais.totalPecas} pares/peças</strong>
                </div>

                <div>
                  <span style={{ fontSize: '0.75rem', color: '#64748b', display: 'block' }}>VALOR TOTAL DA ORDEM:</span>
                  <strong style={{ fontSize: '1.3rem', color: '#16a34a' }}>{formatCurrency(totaisGerais.valorLiquido)}</strong>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '0.8rem' }}>
                <button type="button" className="btn-secondary" onClick={() => setShowOrderModal(false)}>Cancelar</button>
                <button type="button" className="btn-primary" onClick={handleSaveOrder} disabled={loading} style={{ background: 'linear-gradient(135deg, #7c3aed, #6d28d9)', minWidth: '180px' }}>
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
        <div className="product-form-modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setShowPrintModal(null); }}>
          <div className="product-form-modal-container glass" style={{ maxWidth: '950px', background: '#ffffff' }}>
            
            <div className="product-modal-header" style={{ background: '#1e293b', color: '#ffffff' }}>
              <div className="product-modal-title-group">
                <div className="product-modal-icon-badge" style={{ background: '#334155' }}>
                  <Printer size={22} color="#ffffff" />
                </div>
                <div>
                  <h3 style={{ color: '#ffffff' }}>Relatório Timbrado da Ordem de Compra</h3>
                  <span className="product-modal-subtitle" style={{ color: '#94a3b8' }}>Pronto para Impressão A4 ou Envio via WhatsApp ao Representante</span>
                </div>
              </div>
              <button className="btn-close" onClick={() => setShowPrintModal(null)} style={{ color: '#ffffff' }}><X size={20} /></button>
            </div>

            {/* ÁREA DE IMPRESSÃO A4 */}
            <div className="product-modal-body" style={{ background: '#ffffff', padding: '2rem' }}>
              <div ref={printRef} style={{ border: '2px solid #0f172a', padding: '1.5rem', fontFamily: 'Arial, sans-serif' }}>
                
                {/* CABEÇALHO TIMBRADO */}
                <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '2px solid #0f172a', paddingBottom: '1rem', marginBottom: '1rem' }}>
                  <div>
                    <h2 style={{ margin: 0, fontSize: '1.4rem', color: '#0f172a' }}>ORDEM DE COMPRA: {showPrintModal.numero_ordem || `#${showPrintModal.id}`}</h2>
                    <div style={{ fontSize: '0.9rem', color: '#475569', marginTop: '4px' }}>
                      <strong>Marca:</strong> {showPrintModal.marca} | <strong>Representante:</strong> {showPrintModal.representante} ({showPrintModal.contato_representante})
                    </div>
                  </div>

                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontWeight: 800, fontSize: '1.1rem' }}>{showPrintModal.empresa_nome}</div>
                    <div style={{ fontSize: '0.8rem', color: '#64748b' }}>CNPJ: {showPrintModal.empresa_cnpj}</div>
                    <div style={{ fontSize: '0.8rem', color: '#64748b' }}>Data: {new Date(showPrintModal.data_pedido || Date.now()).toLocaleDateString('pt-BR')}</div>
                  </div>
                </div>

                {/* CONDIÇÕES COMERCIAIS */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '1rem', background: '#f8fafc', padding: '0.75rem', borderRadius: '0.5rem', marginBottom: '1.5rem', fontSize: '0.85rem' }}>
                  <div><strong>Local do Pedido:</strong> {showPrintModal.local_pedido}</div>
                  <div><strong>Previsão de Entrega:</strong> {showPrintModal.data_entrega}</div>
                  <div><strong>Local de Entrega:</strong> {showPrintModal.local_entrega}</div>
                  <div><strong>Prazo Pagamento:</strong> {showPrintModal.prazo_pagamento}</div>
                  <div><strong>Faturamento:</strong> {showPrintModal.observacao}</div>
                  <div><strong>Status:</strong> {showPrintModal.status}</div>
                </div>

                {/* TABELA DA MATRIZ DE ITENS */}
                <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.8rem', marginBottom: '1.5rem' }}>
                  <thead>
                    <tr style={{ background: '#0f172a', color: '#ffffff' }}>
                      <th style={{ padding: '6px', border: '1px solid #0f172a', textAlign: 'left' }}>Produto</th>
                      <th style={{ padding: '6px', border: '1px solid #0f172a', textAlign: 'left' }}>Cor</th>
                      <th style={{ padding: '6px', border: '1px solid #0f172a', textAlign: 'left' }}>REF</th>
                      <th style={{ padding: '6px', border: '1px solid #0f172a', textAlign: 'right' }}>Preço</th>
                      {colunasTamanhos.map(col => (
                        <th key={col} style={{ padding: '6px', border: '1px solid #0f172a', textAlign: 'center' }}>{col}</th>
                      ))}
                      <th style={{ padding: '6px', border: '1px solid #0f172a', textAlign: 'center' }}>Total</th>
                      <th style={{ padding: '6px', border: '1px solid #0f172a', textAlign: 'right' }}>Valor R$</th>
                    </tr>
                  </thead>
                  <tbody>
                    {(showPrintModal.itens || []).map((it, idx) => {
                      let grade = {};
                      try {
                        grade = typeof it.grade_tamanhos === 'string' ? JSON.parse(it.grade_tamanhos) : (it.grade_tamanhos || {});
                      } catch (e) { grade = {}; }

                      return (
                        <tr key={idx} style={{ background: idx % 2 === 0 ? '#ffffff' : '#f8fafc' }}>
                          <td style={{ padding: '6px', border: '1px solid #cbd5e1' }}><strong>{it.produto_nome}</strong></td>
                          <td style={{ padding: '6px', border: '1px solid #cbd5e1' }}>{it.cor}</td>
                          <td style={{ padding: '6px', border: '1px solid #cbd5e1' }}>{it.referencia}</td>
                          <td style={{ padding: '6px', border: '1px solid #cbd5e1', textAlign: 'right' }}>{formatCurrency(it.valor_unitario)}</td>
                          {colunasTamanhos.map(col => (
                            <td key={col} style={{ padding: '6px', border: '1px solid #cbd5e1', textAlign: 'center' }}>
                              {grade[col] || 0}
                            </td>
                          ))}
                          <td style={{ padding: '6px', border: '1px solid #cbd5e1', textAlign: 'center', fontWeight: 800 }}>{it.total_pecas}</td>
                          <td style={{ padding: '6px', border: '1px solid #cbd5e1', textAlign: 'right', fontWeight: 800 }}>{formatCurrency(it.valor_total)}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                  <tfoot>
                    <tr style={{ background: '#e2e8f0', fontWeight: 800 }}>
                      <td colSpan="4" style={{ padding: '6px', border: '1px solid #cbd5e1', textAlign: 'right' }}>TOTAIS:</td>
                      {colunasTamanhos.map(col => {
                        let som = 0;
                        (showPrintModal.itens || []).forEach(it => {
                          try {
                            const g = typeof it.grade_tamanhos === 'string' ? JSON.parse(it.grade_tamanhos) : (it.grade_tamanhos || {});
                            som += Number(g[col] || 0);
                          } catch (e) {}
                        });
                        return <td key={col} style={{ padding: '6px', border: '1px solid #cbd5e1', textAlign: 'center' }}>{som}</td>;
                      })}
                      <td style={{ padding: '6px', border: '1px solid #cbd5e1', textAlign: 'center', fontSize: '0.9rem' }}>{showPrintModal.total_pecas}</td>
                      <td style={{ padding: '6px', border: '1px solid #cbd5e1', textAlign: 'right', fontSize: '0.95rem', color: '#16a34a' }}>{formatCurrency(showPrintModal.valor_total)}</td>
                    </tr>
                  </tfoot>
                </table>

                {/* ASSINATURAS */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '3rem', marginTop: '3rem', textAlign: 'center', fontSize: '0.85rem' }}>
                  <div style={{ borderTop: '1px solid #0f172a', paddingTop: '0.5rem' }}>
                    <strong>{showPrintModal.empresa_nome}</strong>
                    <div>Comprador Responsável</div>
                  </div>
                  <div style={{ borderTop: '1px solid #0f172a', paddingTop: '0.5rem' }}>
                    <strong>{showPrintModal.representante} ({showPrintModal.marca})</strong>
                    <div>Representante Comercial</div>
                  </div>
                </div>

              </div>
            </div>

            {/* RODAPÉ DO MODAL DE IMPRESSÃO */}
            <div className="product-modal-footer">
              <button type="button" className="btn-secondary" onClick={() => setShowPrintModal(null)}>Fechar</button>

              <div style={{ display: 'flex', gap: '0.8rem' }}>
                <button type="button" className="btn-secondary" onClick={() => handleSendWhatsApp(showPrintModal)} style={{ color: '#16a34a', borderColor: '#86efac', background: '#dcfce7' }}>
                  <Share2 size={16} /> Enviar via WhatsApp
                </button>
                <button type="button" className="btn-primary" onClick={() => window.print()}>
                  <Printer size={16} /> Imprimir / PDF
                </button>
              </div>
            </div>

          </div>
        </div>
      )}

    </div>
  );
}
