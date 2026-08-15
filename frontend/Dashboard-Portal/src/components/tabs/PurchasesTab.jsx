import { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { 
  ShoppingCart, Upload, Plus, Eye, FileText, UserPlus, PackagePlus, 
  X, Save, AlertCircle, Building2, CheckCircle2, DollarSign, Calendar,
  TrendingUp, Search, Filter, AlertTriangle, RefreshCw, Trash2, ArrowRight, 
  Package, Calculator, CreditCard, Sparkles, Check, ChevronRight
} from 'lucide-react';
import { createApi } from '../../services/api';
import Pagination from '../Pagination';
import SearchBar from '../SearchBar';
import LookupSelect from '../LookupSelect';
import { formatCurrency } from '../../utils/formatters';
import './PurchasesTab.css';

export default function PurchasesTab() {
  const api = createApi(true); // Conecta na CD_API_BASE (port 9000)
  const fileInputRef = useRef(null);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  // Lista e Paginação de Compras
  const [compras, setCompras] = useState([]);
  const [page, setPage] = useState(1);
  const [meta, setMeta] = useState({ page: 1, limit: 10, total: 0, pages: 1 });
  const [searchTerm, setSearchTerm] = useState('');

  // Listas auxiliares
  const [fornecedores, setFornecedores] = useState([]);
  const [produtos, setProdutos] = useState([]);

  // Modais de Controle
  const [showPurchaseForm, setShowPurchaseForm] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(null);
  const [showCostAnalysisModal, setShowCostAnalysisModal] = useState(false);
  const [showBillingModal, setShowBillingModal] = useState(false);
  const [showQuickVendorModal, setShowQuickVendorModal] = useState(false);
  const [showQuickProductModal, setShowQuickProductModal] = useState(false);
  const [quickProductTargetIndex, setQuickProductTargetIndex] = useState(null);

  // Estado do Formulário de Compra
  const [purchaseForm, setPurchaseForm] = useState({
    id: 0,
    fornecedor_id: '',
    fornecedor_nome: '',
    numero_nf: '',
    chave_nfe: '',
    data_entrada: new Date().toISOString().split('T')[0],
    valor_frete: 0,
    valor_outros: 0,
    observacao: '',
    itens: [],
    parcelas: []
  });

  // Estado de Item de Compra Atual no Form Manual
  const [itemForm, setItemForm] = useState({
    produto_codigo: '',
    produto_nome: '',
    quantidade: 1,
    valor_unitario: 0,
    valor_frete: 0,
    valor_ipi: 0,
    valor_st: 0,
    valor_outros: 0,
    // Custos e Preços para F5
    margem_lucro: 100,
    valor_dinheiro: 0,
    valor_vista: 0,
    valor_prazo: 0,
    atualizar_precos: true
  });

  // Estado da Análise de Custos F5
  const [analiseItens, setAnaliseItens] = useState([]);
  const [custoOperacionalPerc, setCustoOperacionalPerc] = useState(10); // 10% padrão

  // Estado do Faturamento / Contas a Pagar
  const [condicaoPagamento, setCondicaoPagamento] = useState('30_60_90'); // 'a_vista', '30d', '30_60', '30_60_90', '60_90_120_150_180', 'custom'
  const [customNumParcelas, setCustomNumParcelas] = useState(3);
  const [customIntervaloDias, setCustomIntervaloDias] = useState(30);
  const [dataPrimeiroVencimento, setDataPrimeiroVencimento] = useState(
    new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
  );
  const [formaPagamentoPadrao, setFormaPagamentoPadrao] = useState('BOLETO');

  // Quick form states
  const [quickVendorForm, setQuickVendorForm] = useState({ nome: '', fantasia: '', cnpj: '', telefone: '', uf: 'PR' });
  const [quickProductForm, setQuickProductForm] = useState({ nome: '', codbarra: '', valorv: 0, ncm: '6109.10.00', um: 'UN' });

  useEffect(() => {
    fetchCompras('last');
    fetchAuxiliaryData();
  }, []);

  // Atalho de Teclado F5 para abrir Análise de Custos
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'F5' && showPurchaseForm) {
        e.preventDefault();
        handleOpenCostAnalysis();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [showPurchaseForm, purchaseForm]);

  const fetchCompras = async (targetPage = 'last') => {
    setLoading(true);
    setError('');
    try {
      let pageToFetch = targetPage === 'last' ? 1 : targetPage;
      let res = await api.get(`/v1/compras?page=${pageToFetch}&limit=10`);
      
      let items = [];
      let metaData = { page: pageToFetch, limit: 10, total: 0, pages: 1 };

      if (res.data && Array.isArray(res.data.data)) {
        items = res.data.data;
        metaData = res.data.meta || { page: pageToFetch, limit: 10, total: items.length, pages: 1 };
      } else if (Array.isArray(res.data)) {
        items = res.data;
        metaData = { page: 1, limit: items.length || 10, total: items.length, pages: 1 };
      }

      if (targetPage === 'last' && metaData.pages > 1) {
        pageToFetch = metaData.pages;
        res = await api.get(`/v1/compras?page=${pageToFetch}&limit=10`);
        if (res.data && Array.isArray(res.data.data)) {
          items = res.data.data;
          metaData = res.data.meta || { page: pageToFetch, limit: 10, total: items.length, pages: 1 };
        } else if (Array.isArray(res.data)) {
          items = res.data;
          metaData = { page: 1, limit: items.length || 10, total: items.length, pages: 1 };
        }
      }

      setCompras(items);
      setMeta(metaData);
      setPage(metaData.page || pageToFetch);
    } catch (err) {
      console.error(err);
      setCompras([]);
      setError('Erro ao carregar histórico de compras.');
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

      const fData = Array.isArray(fRes.data) ? fRes.data : (fRes.data?.data || []);
      const pData = Array.isArray(pRes.data) ? pRes.data : (pRes.data?.data || []);

      setFornecedores(fData);
      setProdutos(pData);
    } catch (err) {
      console.error('Erro ao buscar dados auxiliares:', err);
    }
  };

  const handleOpenCreatePurchase = () => {
    setPurchaseForm({
      id: 0,
      fornecedor_id: fornecedores[0]?.codigo || '',
      fornecedor_nome: fornecedores[0]?.nome || '',
      numero_nf: '',
      chave_nfe: '',
      data_entrada: new Date().toISOString().split('T')[0],
      valor_frete: 0,
      valor_outros: 0,
      observacao: '',
      itens: [],
      parcelas: []
    });
    setItemForm({
      produto_codigo: '',
      produto_nome: '',
      quantidade: 1,
      valor_unitario: 0,
      valor_frete: 0,
      valor_ipi: 0,
      valor_st: 0,
      valor_outros: 0,
      margem_lucro: 100,
      valor_dinheiro: 0,
      valor_vista: 0,
      valor_prazo: 0,
      atualizar_precos: true
    });
    setShowPurchaseForm(true);
  };

  // Cálculo do Total da Compra
  const calcularTotalItens = () => {
    return purchaseForm.itens.reduce((acc, item) => acc + (Number(item.quantidade) * Number(item.valor_unitario)), 0);
  };

  const calcularTotalForm = () => {
    const subtotal = calcularTotalItens();
    const frete = Number(purchaseForm.valor_frete) || 0;
    const outros = Number(purchaseForm.valor_outros) || 0;
    return subtotal + frete + outros;
  };

  // Inclusão de Item no Formulário de Compra
  const handleAddItemToPurchase = () => {
    if (!itemForm.produto_codigo) {
      alert('Por favor, selecione um produto.');
      return;
    }
    const q = parseFloat(itemForm.quantidade) || 0;
    const vu = parseFloat(itemForm.valor_unitario) || 0;
    if (q <= 0 || vu <= 0) {
      alert('Quantidade e Valor Unitário devem ser maiores que zero.');
      return;
    }

    const matchedProd = produtos.find(p => Number(p.codigo) === Number(itemForm.produto_codigo));
    const prodNome = matchedProd ? matchedProd.nome : itemForm.produto_nome;
    const precoAtualVista = matchedProd ? Number(matchedProd.valorv || matchedProd.valor || 0) : 0;

    // Rateio inicial
    const rateioUnit = (Number(itemForm.valor_frete || 0) + Number(itemForm.valor_ipi || 0) + Number(itemForm.valor_st || 0) + Number(itemForm.valor_outros || 0)) / (q || 1);
    const custoMerc = vu + rateioUnit;
    const custoOp = custoMerc * (1 + (custoOperacionalPerc / 100));
    const margem = Number(itemForm.margem_lucro) || 100;
    const vVistaSugerido = custoOp * (1 + (margem / 100));

    const newItem = {
      ...itemForm,
      produto_nome: prodNome,
      preco_atual_vista: precoAtualVista,
      custo_mercadoria: custoMerc,
      custo_operacional: custoOp,
      valor_vista: itemForm.valor_vista > 0 ? Number(itemForm.valor_vista) : vVistaSugerido,
      valor_dinheiro: itemForm.valor_dinheiro > 0 ? Number(itemForm.valor_dinheiro) : vVistaSugerido,
      valor_prazo: itemForm.valor_prazo > 0 ? Number(itemForm.valor_prazo) : (vVistaSugerido * 1.1)
    };

    setPurchaseForm(prev => ({
      ...prev,
      itens: [...prev.itens, newItem]
    }));

    // Reset Item Form
    setItemForm({
      produto_codigo: '',
      produto_nome: '',
      quantidade: 1,
      valor_unitario: 0,
      valor_frete: 0,
      valor_ipi: 0,
      valor_st: 0,
      valor_outros: 0,
      margem_lucro: 100,
      valor_dinheiro: 0,
      valor_vista: 0,
      valor_prazo: 0,
      atualizar_precos: true
    });
  };

  const handleRemoveItem = (index) => {
    setPurchaseForm(prev => ({
      ...prev,
      itens: prev.itens.filter((_, i) => i !== index)
    }));
  };

  // =========================================================================
  // F5 - ANÁLISE DE CUSTOS (INSPIRADO EM UnitCompra.pas E UnitAnaliseCustos)
  // =========================================================================
  const handleOpenCostAnalysis = () => {
    if (purchaseForm.itens.length === 0) {
      alert('Adicione itens à compra antes de abrir a Análise de Custos.');
      return;
    }

    const totalQtdCompra = purchaseForm.itens.reduce((acc, it) => acc + Number(it.quantidade || 0), 0) || 1;
    const freteTotal = Number(purchaseForm.valor_frete) || 0;
    const outrosTotal = Number(purchaseForm.valor_outros) || 0;

    const itensCalculados = purchaseForm.itens.map((it, idx) => {
      const q = Number(it.quantidade) || 1;
      const vu = Number(it.valor_unitario) || 0;

      // Rateio proporcional do frete e outras despesas da nota
      const freteRateadoItem = freteTotal > 0 ? (freteTotal * (q / totalQtdCompra)) : (Number(it.valor_frete) || 0);
      const outrosRateadoItem = outrosTotal > 0 ? (outrosTotal * (q / totalQtdCompra)) : (Number(it.valor_outros) || 0);
      const ipi = Number(it.valor_ipi) || 0;
      const st = Number(it.valor_st) || 0;

      const rateioTotalItem = (freteRateadoItem + outrosRateadoItem + ipi + st) / q;
      const custoMercadoria = vu + rateioTotalItem; // Custo Final de Entrada da Mercadoria
      const custoOperacional = custoMercadoria * (1 + (custoOperacionalPerc / 100)); // +10% custo operacional

      const matchedProd = produtos.find(p => Number(p.codigo) === Number(it.produto_codigo));
      const precoAtual = matchedProd ? Number(matchedProd.valorv || matchedProd.valor || 0) : 0;
      const precoAtualDin = matchedProd ? Number(matchedProd.pro_valor_dinheiro || matchedProd.valor_dinheiro || precoAtual) : 0;
      const precoAtualPrazo = matchedProd ? Number(matchedProd.pro_valorv_prazo || matchedProd.valorv_prazo || precoAtual) : 0;

      const margem = Number(it.margem_lucro) || 100;
      const vVistaSugerido = custoOperacional * (1 + (margem / 100));
      const vDinheiroSugerido = vVistaSugerido;
      const vPrazoSugerido = vVistaSugerido * 1.10; // +10% a prazo

      return {
        ...it,
        index: idx,
        custo_entrada: vu,
        rateio_unit: rateioTotalItem,
        custo_mercadoria: custoMercadoria,
        custo_operacional: custoOperacional,
        preco_atual_vista: precoAtual,
        preco_atual_din: precoAtualDin,
        preco_atual_prazo: precoAtualPrazo,
        margem_lucro: margem,
        valor_vista: it.valor_vista > 0 ? it.valor_vista : vVistaSugerido,
        valor_dinheiro: it.valor_dinheiro > 0 ? it.valor_dinheiro : vDinheiroSugerido,
        valor_prazo: it.valor_prazo > 0 ? it.valor_prazo : vPrazoSugerido,
        atualizar_precos: it.atualizar_precos !== false
      };
    });

    setAnaliseItens(itensCalculados);
    setShowCostAnalysisModal(true);
  };

  const handleUpdateAnaliseItem = (idx, field, val) => {
    setAnaliseItens(prev => {
      const updated = [...prev];
      const it = { ...updated[idx], [field]: val };

      if (field === 'margem_lucro') {
        const m = parseFloat(val) || 0;
        const vVista = it.custo_operacional * (1 + (m / 100));
        it.valor_vista = vVista;
        it.valor_dinheiro = vVista;
        it.valor_prazo = vVista * 1.10;
      } else if (field === 'valor_vista') {
        const v = parseFloat(val) || 0;
        if (it.custo_operacional > 0) {
          it.margem_lucro = ((v - it.custo_operacional) / it.custo_operacional) * 100;
        }
      }

      updated[idx] = it;
      return updated;
    });
  };

  const handleApplyMarginToAll = (margem) => {
    setAnaliseItens(prev => prev.map(it => {
      const vVista = it.custo_operacional * (1 + (margem / 100));
      return {
        ...it,
        margem_lucro: margem,
        valor_vista: vVista,
        valor_dinheiro: vVista,
        valor_prazo: vVista * 1.10
      };
    }));
  };

  const handleConfirmCostAnalysis = () => {
    // Atualiza itens do purchaseForm com os dados refinados da Análise de Custos
    const updatedItens = purchaseForm.itens.map((it, idx) => {
      const matchAnalise = analiseItens.find(a => a.index === idx);
      if (matchAnalise) {
        return {
          ...it,
          custo_mercadoria: matchAnalise.custo_mercadoria,
          custo_operacional: matchAnalise.custo_operacional,
          margem_lucro: matchAnalise.margem_lucro,
          valor_vista: matchAnalise.valor_vista,
          valor_dinheiro: matchAnalise.valor_dinheiro,
          valor_prazo: matchAnalise.valor_prazo,
          atualizar_precos: matchAnalise.atualizar_precos
        };
      }
      return it;
    });

    setPurchaseForm(prev => ({ ...prev, itens: updatedItens }));
    setShowCostAnalysisModal(false);
    setSuccessMsg('Análise de Custos (F5) aplicada aos itens da compra!');
    setTimeout(() => setSuccessMsg(''), 4000);
  };

  // =========================================================================
  // FATURAMENTO & CONTAS A PAGAR (INSPIRADO EM UnitLancamentoEntradas.pas)
  // =========================================================================
  const handleOpenBilling = () => {
    const total = calcularTotalForm();
    if (total <= 0) {
      alert('O valor total da compra deve ser maior que zero para gerar o faturamento.');
      return;
    }
    if (purchaseForm.parcelas.length === 0) {
      gerarGradeParcelas(condicaoPagamento);
    }
    setShowBillingModal(true);
  };

  const gerarGradeParcelas = (tipoCondicao) => {
    const totalCompra = calcularTotalForm();
    let prazos = [];

    if (tipoCondicao === 'a_vista') prazos = [0];
    else if (tipoCondicao === '30d') prazos = [30];
    else if (tipoCondicao === '30_60') prazos = [30, 60];
    else if (tipoCondicao === '30_60_90') prazos = [30, 60, 90];
    else if (tipoCondicao === '60_90_120_150_180') prazos = [60, 90, 120, 150, 180];
    else if (tipoCondicao === 'custom') {
      prazos = Array.from({ length: customNumParcelas }, (_, i) => (i + 1) * customIntervaloDias);
    }

    const numParc = prazos.length;
    const vlrParcBase = Math.floor((totalCompra / numParc) * 100) / 100;
    const centavosRestantes = Math.round((totalCompra - (vlrParcBase * numParc)) * 100) / 100;

    const baseDate = new Date(dataPrimeiroVencimento || Date.now());

    const novasParcelas = prazos.map((dias, idx) => {
      const vDate = new Date(baseDate);
      if (idx > 0) vDate.setDate(vDate.getDate() + (dias - prazos[0]));
      
      const vlrParcFinal = idx === 0 ? (vlrParcBase + centavosRestantes) : vlrParcBase;

      return {
        parcela: `${idx + 1}/${numParc}`,
        data_vencimento: vDate.toISOString().split('T')[0],
        valor_parcela: Number(vlrParcFinal.toFixed(2)),
        forma_pagamento: formaPagamentoPadrao,
        status: 'ABERTO'
      };
    });

    setPurchaseForm(prev => ({ ...prev, parcelas: novasParcelas }));
  };

  const handleUpdateParcela = (idx, field, val) => {
    setPurchaseForm(prev => {
      const updated = [...prev.parcelas];
      updated[idx] = { ...updated[idx], [field]: val };
      return { ...prev, parcelas: updated };
    });
  };

  // =========================================================================
  // SALVAR COMPRA FINALIZADA (COMPRAS + ITENS + CUSTOS + CONTAS_PAGAR)
  // =========================================================================
  const handleSavePurchase = async () => {
    if (!purchaseForm.fornecedor_id && !purchaseForm.fornecedor_nome) {
      alert('Por favor, selecione ou cadastre um Fornecedor antes de finalizar a compra.');
      return;
    }

    if (purchaseForm.itens.length === 0) {
      alert('Adicione pelo menos um item à compra antes de finalizar.');
      return;
    }

    const unmatched = purchaseForm.itens.find(it => !it.produto_codigo || Number(it.produto_codigo) <= 0);
    if (unmatched) {
      alert(`O produto "${unmatched.produto_nome}" ainda não possui vínculo de código. Cadastre-o ou vincule-o antes de finalizar.`);
      return;
    }

    setLoading(true);
    setError('');
    try {
      const selectedForn = fornecedores.find(f => f.codigo === Number(purchaseForm.fornecedor_id));
      const totalCompra = calcularTotalForm();

      const payload = {
        ...purchaseForm,
        fornecedor_id: Number(purchaseForm.fornecedor_id) || 0,
        fornecedor_nome: selectedForn ? (selectedForn.nome || selectedForn.razao_social) : purchaseForm.fornecedor_nome,
        numero_nf: purchaseForm.numero_nf || 'MANUAL',
        chave_nfe: purchaseForm.chave_nfe || '',
        valor_total: totalCompra,
        valor_frete: Number(purchaseForm.valor_frete) || 0,
        valor_outros: Number(purchaseForm.valor_outros) || 0,
        itens: purchaseForm.itens.map(it => ({
          produto_codigo: Number(it.produto_codigo),
          produto_nome: it.produto_nome,
          quantidade: Number(it.quantidade),
          valor_unitario: Number(it.valor_unitario),
          valor_frete: Number(it.valor_frete || 0),
          valor_ipi: Number(it.valor_ipi || 0),
          valor_st: Number(it.valor_st || 0),
          valor_outros: Number(it.valor_outros || 0),
          // 3 Preços de Venda Atualizados
          valor_dinheiro: Number(it.valor_dinheiro || it.valor_vista || 0),
          valor_vista: Number(it.valor_vista || 0),
          valor_prazo: Number(it.valor_prazo || it.valor_vista || 0)
        })),
        parcelas: purchaseForm.parcelas
      };

      await api.post('/v1/compras', payload);
      alert('Compra lançada com sucesso! Os custos, estoques, preços e parcelas do Contas a Pagar foram gravados.');
      setSuccessMsg('Compra lançada com sucesso!');
      setShowPurchaseForm(false);
      fetchCompras(1);
      fetchAuxiliaryData();
      setTimeout(() => setSuccessMsg(''), 5000);
    } catch (err) {
      console.error('Erro ao salvar compra:', err);
      const errMsg = err.response?.data?.error || err.message || 'Erro ao salvar lançamento de compra.';
      alert(`Atenção: Não foi possível salvar a compra.\nMotivo: ${errMsg}`);
      setError(`Erro ao salvar lançamento de compra: ${errMsg}`);
    } finally {
      setLoading(false);
    }
  };

  // Helper de leitura de XML NF-e
  const getXmlText = (parent, tagName) => {
    if (!parent) return '';
    const el = parent.getElementsByTagName(tagName)[0] || parent.getElementsByTagNameNS('*', tagName)[0];
    return el ? (el.textContent || '').trim() : '';
  };

  const handleFileUpload = (event) => {
    const file = event.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const xmlText = e.target.result;
        const parser = new DOMParser();
        const xmlDoc = parser.parseFromString(xmlText, 'text/xml');

        const nNF = getXmlText(xmlDoc, 'nNF');
        const infNFe = xmlDoc.getElementsByTagName('infNFe')[0] || xmlDoc.getElementsByTagNameNS('*', 'infNFe')[0];
        const chNFe = getXmlText(xmlDoc, 'chNFe') || (infNFe ? infNFe.getAttribute('Id')?.replace('NFe', '') : '');

        const emitNode = xmlDoc.getElementsByTagName('emit')[0] || xmlDoc.getElementsByTagNameNS('*', 'emit')[0];
        const emitNome = getXmlText(emitNode, 'xNome');
        const emitCnpj = getXmlText(emitNode, 'CNPJ') || getXmlText(emitNode, 'CPF');

        const cleanCnpj = emitCnpj.replace(/\D/g, '');
        const matchedForn = fornecedores.find(f => {
          const fCnpj = (f.cnpj_cpf || f.cnpj || '').replace(/\D/g, '');
          return fCnpj && cleanCnpj && fCnpj === cleanCnpj;
        });

        const detNodes = Array.from(xmlDoc.getElementsByTagName('det')).concat(Array.from(xmlDoc.getElementsByTagNameNS('*', 'det')));
        const uniqueDets = detNodes.filter((v, i, a) => a.indexOf(v) === i);

        const parsedItens = [];

        for (let i = 0; i < uniqueDets.length; i++) {
          const det = uniqueDets[i];
          const prodNode = det.getElementsByTagName('prod')[0] || det.getElementsByTagNameNS('*', 'prod')[0];
          if (!prodNode) continue;

          const cProd = getXmlText(prodNode, 'cProd');
          const xProd = getXmlText(prodNode, 'xProd');
          const cEAN = getXmlText(prodNode, 'cEAN');
          const qCom = parseFloat(getXmlText(prodNode, 'qCom')) || 0;
          const vUnCom = parseFloat(getXmlText(prodNode, 'vUnCom')) || 0;
          const vFrete = parseFloat(getXmlText(prodNode, 'vFrete')) || 0;
          const vOutro = parseFloat(getXmlText(prodNode, 'vOutro')) || 0;

          const impostoNode = det.getElementsByTagName('imposto')[0] || det.getElementsByTagNameNS('*', 'imposto')[0];
          const vIPI = parseFloat(getXmlText(impostoNode, 'vIPI')) || 0;
          const vICMSST = parseFloat(getXmlText(impostoNode, 'vST')) || 0;

          const matchedProd = produtos.find(p => 
            (cEAN && cEAN !== 'SEM GTIN' && p.codbarra === cEAN) ||
            (cProd && String(p.codigo) === String(cProd)) ||
            (p.nome && p.nome.toLowerCase() === xProd.toLowerCase())
          );

          parsedItens.push({
            produto_codigo: matchedProd ? matchedProd.codigo : '',
            produto_nome: xProd,
            codbarra: cEAN !== 'SEM GTIN' ? cEAN : '',
            quantidade: qCom,
            valor_unitario: vUnCom,
            valor_frete: vFrete,
            valor_ipi: vIPI,
            valor_st: vICMSST,
            valor_outros: vOutro,
            margem_lucro: 100,
            valor_vista: 0,
            valor_dinheiro: 0,
            valor_prazo: 0,
            atualizar_precos: true,
            matched: !!matchedProd
          });
        }

        setPurchaseForm({
          id: 0,
          fornecedor_id: matchedForn ? matchedForn.codigo : '',
          fornecedor_nome: emitNome,
          numero_nf: nNF,
          chave_nfe: chNFe,
          data_entrada: new Date().toISOString().split('T')[0],
          valor_frete: parsedItens.reduce((a, b) => a + b.valor_frete, 0),
          valor_outros: parsedItens.reduce((a, b) => a + b.valor_outros, 0),
          observacao: `Importado de XML NFe #${nNF}`,
          itens: parsedItens,
          parcelas: []
        });

        setShowPurchaseForm(true);
        setSuccessMsg(`XML NFe #${nNF} de ${emitNome} importado com ${parsedItens.length} itens!`);
        setTimeout(() => setSuccessMsg(''), 5000);
      } catch (err) {
        console.error('Erro ao processar XML:', err);
        alert('Erro ao interpretar o arquivo XML da NF-e.');
      }
    };
    reader.readAsText(file);
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  const handleOpenDetailModal = async (compra) => {
    setLoading(true);
    try {
      const res = await api.get(`/v1/compras/${compra.id}`);
      setShowDetailModal(res.data);
    } catch (err) {
      console.error(err);
      setShowDetailModal(compra);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="tab-container">
      
      {/* CABEÇALHO DA ABA COMPRAS */}
      <div className="purchases-header glass">
        <div className="purchases-header-info">
          <h2>Entrada de Compras & Gestão de Fornecedores</h2>
          <p>Lançamento de NF-e, Análise de Custos (F5), Rateio de Despesas e Faturamento Contas a Pagar</p>
        </div>

        <div className="purchases-header-actions">
          <button className="btn-secondary" onClick={() => fetchCompras(page)}>
            <RefreshCw size={16} /> Atualizar
          </button>
          
          <input 
            type="file" 
            ref={fileInputRef} 
            onChange={handleFileUpload} 
            accept=".xml" 
            style={{ display: 'none' }} 
          />
          <button className="btn-secondary" onClick={() => fileInputRef.current?.click()}>
            <Upload size={16} color="var(--info)" /> Importar XML (NF-e)
          </button>

          <button className="btn-primary" onClick={handleOpenCreatePurchase}>
            <Plus size={16} /> + Lançar Compra Manual
          </button>
        </div>
      </div>

      {/* KPI METRIC CARDS */}
      <div className="purchases-kpis">
        <div className="purchases-kpi-card glass">
          <div className="purchases-kpi-icon">
            <ShoppingCart size={24} />
          </div>
          <div className="purchases-kpi-data">
            <span className="purchases-kpi-label">Total de Compras</span>
            <span className="purchases-kpi-value">{meta.total || compras.length}</span>
          </div>
        </div>

        <div className="purchases-kpi-card glass">
          <div className="purchases-kpi-icon success">
            <DollarSign size={24} />
          </div>
          <div className="purchases-kpi-data">
            <span className="purchases-kpi-label">Volume de Compras</span>
            <span className="purchases-kpi-value" style={{ color: 'var(--success)' }}>
              {formatCurrency(compras.reduce((acc, c) => acc + (Number(c.valor_total) || 0), 0))}
            </span>
          </div>
        </div>

        <div className="purchases-kpi-card glass">
          <div className="purchases-kpi-icon info">
            <Building2 size={24} />
          </div>
          <div className="purchases-kpi-data">
            <span className="purchases-kpi-label">Fornecedores Cadastrados</span>
            <span className="purchases-kpi-value">{fornecedores.length}</span>
          </div>
        </div>

        <div className="purchases-kpi-card glass">
          <div className="purchases-kpi-icon">
            <Package size={24} />
          </div>
          <div className="purchases-kpi-data">
            <span className="purchases-kpi-label">Catálogo de Produtos</span>
            <span className="purchases-kpi-value">{produtos.length}</span>
          </div>
        </div>
      </div>

      {successMsg && <div className="feedback-banner success"><CheckCircle2 size={18} /> {successMsg}</div>}
      {error && <div className="feedback-banner error"><AlertCircle size={18} /> {error}</div>}

      {/* LISTAGEM DE COMPRAS */}
      <div className="list-card glass">
        <div className="crud-table-header">
          <h3>Histórico de Compras Realizadas</h3>
          <SearchBar
            value={searchTerm}
            onChange={(val) => setSearchTerm(val)}
            onSearch={() => fetchCompras(1)}
            onClear={() => { setSearchTerm(''); fetchCompras(1); }}
            placeholder="Buscar por NF, Fornecedor ou Chave..."
          />
        </div>

        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Fornecedor</th>
                <th>Nº Documento / NF</th>
                <th>Data Entrada</th>
                <th style={{ textAlign: 'right' }}>Total Frete</th>
                <th style={{ textAlign: 'right' }}>Valor Total Compra</th>
                <th style={{ textAlign: 'center' }}>Ações</th>
              </tr>
            </thead>
            <tbody>
              {compras.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '2rem', color: '#94a3b8' }}>
                    Nenhuma compra registrada. Clique em "+ Lançar Compra Manual" ou "Importar XML".
                  </td>
                </tr>
              ) : (
                compras.map(c => (
                  <tr key={c.id}>
                    <td><span className="item-code">#{c.id}</span></td>
                    <td><strong>{c.fornecedor_nome || `Fornecedor #${c.fornecedor_id}`}</strong></td>
                    <td>{c.numero_nf || 'MANUAL'}</td>
                    <td>{c.data_entrada ? new Date(c.data_entrada).toLocaleDateString('pt-BR') : '-'}</td>
                    <td style={{ textAlign: 'right' }}>{formatCurrency(c.valor_frete || 0)}</td>
                    <td style={{ textAlign: 'right', fontWeight: 800, color: '#16a34a' }}>{formatCurrency(c.valor_total || 0)}</td>
                    <td style={{ textAlign: 'center' }}>
                      <button className="crud-row-btn" onClick={() => handleOpenDetailModal(c)} title="Ver Detalhes / Custos">
                        <Eye size={14} /> Detalhes
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
          onPageChange={(p) => fetchCompras(p)}
        />
      </div>

      {/* ========================================================================= */}
      {/* MODAL DE LANÇAMENTO / EDIÇÃO DE COMPRA                                   */}
      {/* ========================================================================= */}
      {showPurchaseForm && (
        <div className="product-form-modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setShowPurchaseForm(false); }}>
          <div className="product-form-modal-container glass" style={{ maxWidth: '1150px' }}>
            
            <div className="product-modal-header">
              <div className="product-modal-title-group">
                <div className="product-modal-icon-badge" style={{ background: 'linear-gradient(135deg, #2563eb, #1d4ed8)' }}>
                  <ShoppingCart size={22} color="#ffffff" />
                </div>
                <div>
                  <h3>Lançamento de Entrada de Mercadorias (Compra)</h3>
                  <span className="product-modal-subtitle">Rateio de Custos • Análise F5 • Estoque & Contas a Pagar</span>
                </div>
              </div>
              <button className="btn-close" onClick={() => setShowPurchaseForm(false)}><X size={20} /></button>
            </div>

            <div className="product-modal-body">
              
              {/* DADOS DO CABEÇALHO */}
              <div className="product-section-card">
                <div className="product-section-title">
                  <Building2 size={16} color="#2563eb" /> Dados da Nota / Fornecedor
                </div>

                <div className="product-grid-4">
                  <div className="form-group" style={{ gridColumn: 'span 2' }}>
                    <label>Fornecedor *</label>
                    <LookupSelect
                      value={purchaseForm.fornecedor_id}
                      displayValue={
                        purchaseForm.fornecedor_id 
                          ? `#${purchaseForm.fornecedor_id} - ${purchaseForm.fornecedor_nome || fornecedores.find(f => Number(f.codigo) === Number(purchaseForm.fornecedor_id))?.nome || 'Fornecedor'}`
                          : ''
                      }
                      placeholder="Buscar Fornecedor..."
                      title="Selecionar Fornecedor"
                      subtitle="Busca paginada por Razão Social, Fantasia, CNPJ ou Código"
                      icon={Building2}
                      searchPlaceholder="Digite o nome, razão social, CNPJ ou código..."
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
                        { key: 'cnpj', label: 'CNPJ / CPF', render: (f) => <code>{f.cnpj || f.cpf || '-'}</code> },
                        { key: 'cidade', label: 'Cidade / UF', render: (f) => `${f.cidade || ''} - ${f.uf || ''}` }
                      ]}
                      onSelect={(forn) => {
                        setPurchaseForm(prev => ({
                          ...prev,
                          fornecedor_id: forn.codigo,
                          fornecedor_nome: forn.nome || forn.razao_social || forn.fantasia
                        }));
                      }}
                      onClear={() => {
                        setPurchaseForm(prev => ({ ...prev, fornecedor_id: '', fornecedor_nome: '' }));
                      }}
                    />
                  </div>

                  <div className="form-group">
                    <label>Nº Nota Fiscal / Doc *</label>
                    <input 
                      type="text" 
                      value={purchaseForm.numero_nf} 
                      onChange={(e) => setPurchaseForm({ ...purchaseForm, numero_nf: e.target.value })} 
                      placeholder="Ex: 12450" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Data de Entrada</label>
                    <input 
                      type="date" 
                      value={purchaseForm.data_entrada} 
                      onChange={(e) => setPurchaseForm({ ...purchaseForm, data_entrada: e.target.value })} 
                    />
                  </div>

                  <div className="form-group" style={{ gridColumn: 'span 2' }}>
                    <label>Chave de Acesso NF-e (Opcional)</label>
                    <input 
                      type="text" 
                      value={purchaseForm.chave_nfe} 
                      onChange={(e) => setPurchaseForm({ ...purchaseForm, chave_nfe: e.target.value })} 
                      placeholder="44 dígitos (opcional)" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Valor Frete Total (R$)</label>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={purchaseForm.valor_frete} 
                      onChange={(e) => setPurchaseForm({ ...purchaseForm, valor_frete: parseFloat(e.target.value) || 0 })} 
                    />
                  </div>

                  <div className="form-group">
                    <label>Outras Despesas (R$)</label>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={purchaseForm.valor_outros} 
                      onChange={(e) => setPurchaseForm({ ...purchaseForm, valor_outros: parseFloat(e.target.value) || 0 })} 
                    />
                  </div>
                </div>
              </div>

              {/* INCLUSÃO RÁPIDA DE ITENS */}
              <div className="product-section-card">
                <div className="product-section-title">
                  <PackagePlus size={16} color="#059669" /> Inclusão de Itens da Compra
                </div>

                <div className="grade-quick-form" style={{ gridTemplateColumns: '2fr 1fr 1fr 1fr 1fr auto' }}>
                  <div className="form-group">
                    <label>Produto *</label>
                    <LookupSelect
                      value={itemForm.produto_codigo}
                      displayValue={
                        itemForm.produto_codigo
                          ? `#${itemForm.produto_codigo} - ${itemForm.produto_nome || produtos.find(p => Number(p.codigo) === Number(itemForm.produto_codigo))?.nome || 'Produto'}`
                          : ''
                      }
                      placeholder="Buscar Produto..."
                      title="Selecionar Produto"
                      subtitle="Busca paginada por Descrição, Código, Referência ou Código de Barras"
                      icon={Package}
                      searchPlaceholder="Digite o nome, código, referência ou código de barras..."
                      fetchData={async (termo, targetPage, limit) => {
                        let url = `/v1/produtos?page=${targetPage}&limit=${limit}`;
                        if (termo) url += `&busca=${encodeURIComponent(termo)}&termo=${encodeURIComponent(termo)}`;
                        const res = await api.get(url);
                        return res.data;
                      }}
                      columns={[
                        { key: 'codigo', label: 'Código', width: '90px', render: (p) => <span className="item-code">#{p.codigo || p.PRO_CODIGO}</span> },
                        { key: 'nome', label: 'Descrição do Produto', render: (p) => <strong>{p.nome || p.PRO_NOME || p.descricao}</strong> },
                        { key: 'codbarra', label: 'Cód. Barras', render: (p) => <code>{p.codbarra || p.PRO_CODBARRA || '-'}</code> },
                        { key: 'um', label: 'UM', width: '60px', align: 'center', render: (p) => p.um || p.PRO_UM || 'UN' },
                        { key: 'custo', label: 'Custo Atual', align: 'right', render: (p) => formatCurrency(p.custo || p.PRO_VALORC || p.valorc || 0) },
                        { key: 'valorv', label: 'Preço Venda', align: 'right', render: (p) => <strong style={{ color: 'var(--success)' }}>{formatCurrency(p.valorv || p.PRO_VALORV || 0)}</strong> }
                      ]}
                      onSelect={(prod) => {
                        const pId = prod.codigo || prod.PRO_CODIGO;
                        const pNome = prod.nome || prod.PRO_NOME || prod.descricao;
                        const pCusto = Number(prod.custo || prod.PRO_VALORC || prod.valorc || 0);
                        setItemForm(prev => ({
                          ...prev,
                          produto_codigo: pId,
                          produto_nome: pNome,
                          valor_unitario: pCusto
                        }));
                      }}
                      onClear={() => {
                        setItemForm(prev => ({ ...prev, produto_codigo: '', produto_nome: '', valor_unitario: 0 }));
                      }}
                    />
                  </div>

                  <div className="form-group">
                    <label>Quantidade *</label>
                    <input 
                      type="number" 
                      step="1" 
                      value={itemForm.quantidade} 
                      onChange={(e) => setItemForm({ ...itemForm, quantidade: parseFloat(e.target.value) || 0 })} 
                    />
                  </div>

                  <div className="form-group">
                    <label>Valor Unit. (R$) *</label>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={itemForm.valor_unitario} 
                      onChange={(e) => setItemForm({ ...itemForm, valor_unitario: parseFloat(e.target.value) || 0 })} 
                    />
                  </div>

                  <div className="form-group">
                    <label>Frete Item (R$)</label>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={itemForm.valor_frete} 
                      onChange={(e) => setItemForm({ ...itemForm, valor_frete: parseFloat(e.target.value) || 0 })} 
                    />
                  </div>

                  <div className="form-group">
                    <label>IPI / ST (R$)</label>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={itemForm.valor_ipi} 
                      onChange={(e) => setItemForm({ ...itemForm, valor_ipi: parseFloat(e.target.value) || 0 })} 
                    />
                  </div>

                  <div>
                    <button type="button" className="btn-primary" onClick={handleAddItemToPurchase} style={{ height: '38px', padding: '0 1rem' }}>
                      + Adicionar Item
                    </button>
                  </div>
                </div>

                {/* TABELA DE ITENS DA COMPRA */}
                <div className="table-responsive" style={{ maxHeight: '240px', overflowY: 'auto' }}>
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Código</th>
                        <th>Descrição do Produto</th>
                        <th style={{ textAlign: 'center' }}>Qtd</th>
                        <th style={{ textAlign: 'right' }}>Vlr Unitário</th>
                        <th style={{ textAlign: 'right' }}>Subtotal</th>
                        <th style={{ textAlign: 'center' }}>Ações</th>
                      </tr>
                    </thead>
                    <tbody>
                      {purchaseForm.itens.length === 0 ? (
                        <tr>
                          <td colSpan="6" style={{ textAlign: 'center', padding: '1.5rem', color: '#94a3b8' }}>
                            Nenhum item adicionado à compra ainda.
                          </td>
                        </tr>
                      ) : (
                        purchaseForm.itens.map((it, idx) => (
                          <tr key={idx}>
                            <td><span className="item-code">#{it.produto_codigo || 'NOVO'}</span></td>
                            <td><strong>{it.produto_nome}</strong></td>
                            <td style={{ textAlign: 'center' }}>{it.quantidade}</td>
                            <td style={{ textAlign: 'right' }}>{formatCurrency(it.valor_unitario)}</td>
                            <td style={{ textAlign: 'right', fontWeight: 700 }}>{formatCurrency(it.quantidade * it.valor_unitario)}</td>
                            <td style={{ textAlign: 'center' }}>
                              <button className="crud-row-btn delete" onClick={() => handleRemoveItem(idx)} title="Remover Item">
                                <Trash2 size={14} />
                              </button>
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>

              </div>

            </div>

            {/* RODAPÉ DO FORMULÁRIO DE COMPRA COM OS BOTÕES F5 E FATURAMENTO */}
            <div className="product-modal-footer">
              <div style={{ display: 'flex', gap: '0.8rem', alignItems: 'center', flexWrap: 'wrap' }}>
                <button 
                  type="button" 
                  className="btn-secondary" 
                  onClick={handleOpenCostAnalysis}
                  style={{ background: '#fff7ed', borderColor: '#fed7aa', color: '#ea580c', fontWeight: 700 }}
                  title="Atalho F5: Analisar Custos, Margens e Preços de Venda"
                >
                  <Calculator size={16} /> 🔍 F5 - Análise de Custos
                </button>

                <button 
                  type="button" 
                  className="btn-secondary" 
                  onClick={handleOpenBilling}
                  style={{ background: '#eff6ff', borderColor: '#bfdbfe', color: '#2563eb', fontWeight: 700 }}
                  title="Gerar Parcelas do Contas a Pagar"
                >
                  <CreditCard size={16} /> 💳 Faturamento ({purchaseForm.parcelas.length}x Parcelas)
                </button>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem' }}>
                <div style={{ textAlign: 'right' }}>
                  <span style={{ fontSize: '0.75rem', color: '#64748b', display: 'block' }}>TOTAL DA COMPRA:</span>
                  <strong style={{ fontSize: '1.3rem', color: '#16a34a' }}>{formatCurrency(calcularTotalForm())}</strong>
                </div>

                <button type="button" className="btn-primary" onClick={handleSavePurchase} disabled={loading} style={{ minWidth: '160px' }}>
                  {loading ? <RefreshCw size={18} className="spinner" /> : <Save size={18} />} Finalizar Compra
                </button>
              </div>
            </div>

          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL F5 - ANÁLISE DE CUSTOS & PREÇOS DE VENDA                           */}
      {/* ========================================================================= */}
      {showCostAnalysisModal && (
        <div className="product-form-modal-overlay" style={{ zIndex: 1000000 }}>
          <div className="product-form-modal-container glass" style={{ maxWidth: '1200px', maxHeight: '90vh' }}>
            
            <div className="product-modal-header">
              <div className="product-modal-title-group">
                <div className="product-modal-icon-badge">
                  <Calculator size={22} />
                </div>
                <div>
                  <h3>F5 - Painel de Análise de Custos & Preços de Venda</h3>
                  <span className="product-modal-subtitle">Rateio Automático • Margens de Lucro • Formação dos 3 Preços de Venda</span>
                </div>
              </div>
              <button className="btn-close" onClick={() => setShowCostAnalysisModal(false)}><X size={20} /></button>
            </div>

            <div className="product-modal-body">
              
              {/* FERRAMENTAS DE MARGEM RÁPIDA */}
              <div className="product-section-card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.8rem' }}>
                  <span style={{ fontWeight: 700, fontSize: '0.9rem' }}>Custo Operacional Adicional (%):</span>
                  <input 
                    type="number" 
                    value={custoOperacionalPerc} 
                    onChange={(e) => setCustoOperacionalPerc(parseFloat(e.target.value) || 0)} 
                    style={{ width: '80px', textAlign: 'center', fontWeight: 800 }} 
                  />
                  <small style={{ color: '#64748b' }}>(Padrão: +10% sobre o custo da mercadoria)</small>
                </div>

                <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                  <span style={{ fontSize: '0.85rem', color: '#64748b' }}>Aplicar Margem a Todos:</span>
                  <button type="button" className="btn-secondary small" onClick={() => handleApplyMarginToAll(80)}>80%</button>
                  <button type="button" className="btn-secondary small" onClick={() => handleApplyMarginToAll(100)}>100%</button>
                  <button type="button" className="btn-secondary small" onClick={() => handleApplyMarginToAll(120)}>120%</button>
                  <button type="button" className="btn-secondary small" onClick={() => handleApplyMarginToAll(150)}>150%</button>
                </div>
              </div>

              {/* TABELA DETALHADA DE FORMAÇÃO DE CUSTO */}
              <div className="table-responsive" style={{ maxHeight: '420px', overflowY: 'auto' }}>
                <table className="data-table" style={{ fontSize: '0.85rem' }}>
                  <thead>
                    <tr>
                      <th>Produto</th>
                      <th style={{ textAlign: 'right' }}>Custo Entrada</th>
                      <th style={{ textAlign: 'right' }}>Rateio Desp.</th>
                      <th style={{ textAlign: 'right' }}>Custo Merc.</th>
                      <th style={{ textAlign: 'right' }}>Custo Oper.</th>
                      <th style={{ width: '90px', textAlign: 'center' }}>Margem %</th>
                      <th style={{ textAlign: 'right', color: '#16a34a' }}>Vlr Dinheiro</th>
                      <th style={{ textAlign: 'right', color: '#ea580c' }}>Vlr Vista (Pad)</th>
                      <th style={{ textAlign: 'right', color: '#2563eb' }}>Vlr Prazo</th>
                      <th style={{ textAlign: 'right' }}>Preço Atual</th>
                      <th style={{ textAlign: 'center' }}>Atualizar?</th>
                    </tr>
                  </thead>
                  <tbody>
                    {analiseItens.map((it, idx) => (
                      <tr key={idx}>
                        <td>
                          <strong>{it.produto_nome}</strong>
                          <span style={{ display: 'block', fontSize: '0.72rem', color: '#64748b' }}>Cód: #{it.produto_codigo}</span>
                        </td>
                        <td style={{ textAlign: 'right' }}>{formatCurrency(it.custo_entrada)}</td>
                        <td style={{ textAlign: 'right', color: '#64748b' }}>+{formatCurrency(it.rateio_unit)}</td>
                        <td style={{ textAlign: 'right', fontWeight: 700 }}>{formatCurrency(it.custo_mercadoria)}</td>
                        <td style={{ textAlign: 'right', color: '#b45309' }}>{formatCurrency(it.custo_operacional)}</td>
                        
                        <td style={{ textAlign: 'center' }}>
                          <input 
                            type="number" 
                            value={Math.round(it.margem_lucro)} 
                            onChange={(e) => handleUpdateAnaliseItem(idx, 'margem_lucro', e.target.value)} 
                            style={{ width: '65px', textAlign: 'center', padding: '2px', fontWeight: 700 }}
                          />%
                        </td>

                        <td style={{ textAlign: 'right' }}>
                          <input 
                            type="number" 
                            step="0.01" 
                            value={Number(it.valor_dinheiro).toFixed(2)} 
                            onChange={(e) => handleUpdateAnaliseItem(idx, 'valor_dinheiro', e.target.value)} 
                            style={{ width: '80px', textAlign: 'right', padding: '2px', color: '#16a34a', fontWeight: 700 }}
                          />
                        </td>

                        <td style={{ textAlign: 'right' }}>
                          <input 
                            type="number" 
                            step="0.01" 
                            value={Number(it.valor_vista).toFixed(2)} 
                            onChange={(e) => handleUpdateAnaliseItem(idx, 'valor_vista', e.target.value)} 
                            style={{ width: '80px', textAlign: 'right', padding: '2px', color: '#ea580c', fontWeight: 800 }}
                          />
                        </td>

                        <td style={{ textAlign: 'right' }}>
                          <input 
                            type="number" 
                            step="0.01" 
                            value={Number(it.valor_prazo).toFixed(2)} 
                            onChange={(e) => handleUpdateAnaliseItem(idx, 'valor_prazo', e.target.value)} 
                            style={{ width: '80px', textAlign: 'right', padding: '2px', color: '#2563eb', fontWeight: 700 }}
                          />
                        </td>

                        <td style={{ textAlign: 'right', color: '#94a3b8' }}>
                          {formatCurrency(it.preco_atual_vista)}
                        </td>

                        <td style={{ textAlign: 'center' }}>
                          <input 
                            type="checkbox" 
                            checked={it.atualizar_precos} 
                            onChange={(e) => handleUpdateAnaliseItem(idx, 'atualizar_precos', e.target.checked)} 
                          />
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

            </div>

            <div className="product-modal-footer">
              <span style={{ fontSize: '0.8rem', color: '#64748b' }}>
                Os valores aprovados aqui serão salvos diretamente como os 3 preços de venda dos produtos no banco.
              </span>

              <div style={{ display: 'flex', gap: '0.8rem' }}>
                <button type="button" className="btn-secondary" onClick={() => setShowCostAnalysisModal(false)}>Cancelar</button>
                <button type="button" className="btn-primary" onClick={handleConfirmCostAnalysis}>
                  <Check size={18} /> Confirmar Preços de Venda
                </button>
              </div>
            </div>

          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL DE FATURAMENTO & CONTAS A PAGAR                                    */}
      {/* ========================================================================= */}
      {showBillingModal && (
        <div className="product-form-modal-overlay" style={{ zIndex: 1000000 }}>
          <div className="product-form-modal-container glass" style={{ maxWidth: '900px' }}>
            
            <div className="product-modal-header">
              <div className="product-modal-title-group">
                <div className="product-modal-icon-badge">
                  <CreditCard size={22} />
                </div>
                <div>
                  <h3>Faturamento da Compra & Contas a Pagar</h3>
                  <span className="product-modal-subtitle">Geração de Grade de Parcelas e Vencimentos Financeiros</span>
                </div>
              </div>
              <button className="btn-close" onClick={() => setShowBillingModal(false)}><X size={20} /></button>
            </div>

            <div className="product-modal-body">
              
              {/* CONFIGURAÇÃO DE PARCELAMENTO */}
              <div className="product-section-card">
                <div className="product-section-title">
                  <Calendar size={16} color="#2563eb" /> Condição de Pagamento
                </div>

                <div className="product-grid-3">
                  <div className="form-group">
                    <label>Condição de Pagamento *</label>
                    <select 
                      value={condicaoPagamento}
                      onChange={(e) => {
                        setCondicaoPagamento(e.target.value);
                        gerarGradeParcelas(e.target.value);
                      }}
                    >
                      <option value="a_vista">À Vista (Vencimento Hoje)</option>
                      <option value="30d">30 Dias (1 Parcela)</option>
                      <option value="30_60">30 / 60 Dias (2 Parcelas)</option>
                      <option value="30_60_90">30 / 60 / 90 Dias (3 Parcelas)</option>
                      <option value="60_90_120_150_180">60 / 90 / 120 / 150 / 180 Dias (5 Parcelas)</option>
                      <option value="custom">Personalizado (Livre)</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>1º Vencimento</label>
                    <input 
                      type="date" 
                      value={dataPrimeiroVencimento} 
                      onChange={(e) => {
                        setDataPrimeiroVencimento(e.target.value);
                        setTimeout(() => gerarGradeParcelas(condicaoPagamento), 100);
                      }} 
                    />
                  </div>

                  <div className="form-group">
                    <label>Forma de Pagamento</label>
                    <select 
                      value={formaPagamentoPadrao}
                      onChange={(e) => {
                        setFormaPagamentoPadrao(e.target.value);
                        setTimeout(() => gerarGradeParcelas(condicaoPagamento), 100);
                      }}
                    >
                      <option value="BOLETO">Boleto Bancário</option>
                      <option value="PIX">PIX / Transferência</option>
                      <option value="DUPLICATA">Duplicata Mercantil</option>
                      <option value="CHEQUE">Cheque Pré-datado</option>
                    </select>
                  </div>
                </div>
              </div>

              {/* TABELA DE PARCELAS GERADAS */}
              <div className="product-section-card">
                <div className="product-section-title">
                  <DollarSign size={16} color="#16a34a" /> Grade de Vencimentos do Contas a Pagar
                </div>

                <div className="table-responsive" style={{ maxHeight: '250px', overflowY: 'auto' }}>
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Parcela</th>
                        <th>Data de Vencimento</th>
                        <th>Forma de Pagamento</th>
                        <th style={{ textAlign: 'right' }}>Valor Parcela (R$)</th>
                      </tr>
                    </thead>
                    <tbody>
                      {purchaseForm.parcelas.map((p, idx) => (
                        <tr key={idx}>
                          <td><strong>{p.parcela}</strong></td>
                          <td>
                            <input 
                              type="date" 
                              value={p.data_vencimento} 
                              onChange={(e) => handleUpdateParcela(idx, 'data_vencimento', e.target.value)} 
                              style={{ width: '150px' }}
                            />
                          </td>
                          <td>
                            <select 
                              value={p.forma_pagamento}
                              onChange={(e) => handleUpdateParcela(idx, 'forma_pagamento', e.target.value)}
                            >
                              <option value="BOLETO">Boleto Bancário</option>
                              <option value="PIX">PIX</option>
                              <option value="DUPLICATA">Duplicata</option>
                              <option value="CHEQUE">Cheque</option>
                            </select>
                          </td>
                          <td style={{ textAlign: 'right' }}>
                            <input 
                              type="number" 
                              step="0.01" 
                              value={p.valor_parcela} 
                              onChange={(e) => handleUpdateParcela(idx, 'valor_parcela', parseFloat(e.target.value) || 0)} 
                              style={{ width: '120px', textAlign: 'right', fontWeight: 700 }}
                            />
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                {/* VALIDAÇÃO DE SOMA */}
                <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '1.5rem', marginTop: '1rem', alignItems: 'center' }}>
                  <div>
                    <span style={{ fontSize: '0.8rem', color: '#64748b' }}>Soma das Parcelas: </span>
                    <strong>{formatCurrency(purchaseForm.parcelas.reduce((a, b) => a + Number(b.valor_parcela || 0), 0))}</strong>
                  </div>
                  <div>
                    <span style={{ fontSize: '0.8rem', color: '#64748b' }}>Total da Compra: </span>
                    <strong style={{ color: '#16a34a' }}>{formatCurrency(calcularTotalForm())}</strong>
                  </div>
                </div>

              </div>

            </div>

            <div className="product-modal-footer">
              <button type="button" className="btn-secondary" onClick={() => setShowBillingModal(false)}>Fechar</button>
              <button type="button" className="btn-primary" onClick={() => setShowBillingModal(false)}>
                <Check size={18} /> Confirmar Faturamento
              </button>
            </div>

          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL DE DETALHES DA COMPRA REALIZADA                                     */}
      {/* ========================================================================= */}
      {showDetailModal && (
        <div className="product-form-modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setShowDetailModal(null); }}>
          <div className="product-form-modal-container glass" style={{ maxWidth: '900px' }}>
            
            <div className="product-modal-header">
              <div className="product-modal-title-group">
                <div className="product-modal-icon-badge" style={{ background: 'linear-gradient(135deg, #10b981, #059669)' }}>
                  <FileText size={22} color="#ffffff" />
                </div>
                <div>
                  <h3>Detalhes da Compra #{showDetailModal.id}</h3>
                  <span className="product-modal-subtitle">{showDetailModal.fornecedor_nome} • NF {showDetailModal.numero_nf || 'MANUAL'}</span>
                </div>
              </div>
              <button className="btn-close" onClick={() => setShowDetailModal(null)}><X size={20} /></button>
            </div>

            <div className="product-modal-body">
              
              <div className="product-section-card">
                <div className="product-grid-4">
                  <div>
                    <span style={{ fontSize: '0.75rem', color: '#64748b' }}>Data de Entrada</span>
                    <div style={{ fontWeight: 700 }}>{showDetailModal.data_entrada ? new Date(showDetailModal.data_entrada).toLocaleDateString('pt-BR') : '-'}</div>
                  </div>
                  <div>
                    <span style={{ fontSize: '0.75rem', color: '#64748b' }}>Valor Frete</span>
                    <div style={{ fontWeight: 700 }}>{formatCurrency(showDetailModal.valor_frete || 0)}</div>
                  </div>
                  <div>
                    <span style={{ fontSize: '0.75rem', color: '#64748b' }}>Outras Despesas</span>
                    <div style={{ fontWeight: 700 }}>{formatCurrency(showDetailModal.valor_outros || 0)}</div>
                  </div>
                  <div>
                    <span style={{ fontSize: '0.75rem', color: '#64748b' }}>Valor Total</span>
                    <div style={{ fontWeight: 800, color: '#16a34a', fontSize: '1.1rem' }}>{formatCurrency(showDetailModal.valor_total || 0)}</div>
                  </div>
                </div>
              </div>

              {/* ITENS */}
              <div className="product-section-card">
                <div className="product-section-title"><Package size={16} /> Itens da Compra</div>
                <div className="table-responsive">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Produto</th>
                        <th style={{ textAlign: 'center' }}>Qtd</th>
                        <th style={{ textAlign: 'right' }}>Vlr Unitário</th>
                        <th style={{ textAlign: 'right' }}>Custo Merc.</th>
                        <th style={{ textAlign: 'right' }}>Custo Oper.</th>
                        <th style={{ textAlign: 'right' }}>Subtotal</th>
                      </tr>
                    </thead>
                    <tbody>
                      {(showDetailModal.itens || []).map((it, idx) => (
                        <tr key={idx}>
                          <td><strong>{it.produto_nome}</strong> (Cód: #{it.produto_codigo})</td>
                          <td style={{ textAlign: 'center' }}>{it.quantidade}</td>
                          <td style={{ textAlign: 'right' }}>{formatCurrency(it.valor_unitario)}</td>
                          <td style={{ textAlign: 'right', fontWeight: 600 }}>{formatCurrency(it.custo_mercadoria)}</td>
                          <td style={{ textAlign: 'right', color: '#b45309' }}>{formatCurrency(it.custo_operacional)}</td>
                          <td style={{ textAlign: 'right', fontWeight: 700 }}>{formatCurrency(it.quantidade * it.valor_unitario)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* PARCELAS */}
              {showDetailModal.parcelas && showDetailModal.parcelas.length > 0 && (
                <div className="product-section-card">
                  <div className="product-section-title"><CreditCard size={16} /> Contas a Pagar (Parcelas)</div>
                  <div className="table-responsive">
                    <table className="data-table">
                      <thead>
                        <tr>
                          <th>Parcela</th>
                          <th>Vencimento</th>
                          <th>Forma de Pagamento</th>
                          <th>Status</th>
                          <th style={{ textAlign: 'right' }}>Valor Parcela</th>
                        </tr>
                      </thead>
                      <tbody>
                        {showDetailModal.parcelas.map((p, idx) => (
                          <tr key={idx}>
                            <td><strong>{p.parcela}</strong></td>
                            <td>{new Date(p.data_vencimento).toLocaleDateString('pt-BR')}</td>
                            <td>{p.forma_pagamento}</td>
                            <td><span className="badge badge-info">{p.status}</span></td>
                            <td style={{ textAlign: 'right', fontWeight: 700 }}>{formatCurrency(p.valor_parcela)}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

            </div>

            <div className="product-modal-footer">
              <button type="button" className="btn-secondary" onClick={() => setShowDetailModal(null)}>Fechar</button>
            </div>

          </div>
        </div>
      )}

    </div>
  );
}
