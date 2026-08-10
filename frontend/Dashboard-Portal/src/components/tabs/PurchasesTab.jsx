import { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { 
  ShoppingCart, Upload, Plus, Eye, FileText, UserPlus, PackagePlus, 
  X, Save, AlertCircle, Building2, CheckCircle2, DollarSign, Calendar,
  TrendingUp, Search, Filter, AlertTriangle, RefreshCw, Trash2, ArrowRight, Package
} from 'lucide-react';
import { createApi } from '../../services/api';
import Pagination from '../Pagination';
import SearchBar from '../SearchBar';
import { formatCurrency } from '../../utils/formatters';
import './CadastrosTab.css';

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
  const [filterType, setFilterType] = useState('todas'); // 'todas', 'xml', 'manual'

  // Listas auxiliares
  const [fornecedores, setFornecedores] = useState([]);
  const [produtos, setProdutos] = useState([]);

  // Modais de Visualização e Compra
  const [showPurchaseForm, setShowPurchaseForm] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(null);
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
    itens: []
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
    valor_outros: 0
  });

  // Quick form states
  const [quickVendorForm, setQuickVendorForm] = useState({ nome: '', fantasia: '', cnpj: '', telefone: '', uf: 'PR' });
  const [quickProductForm, setQuickProductForm] = useState({ nome: '', codbarra: '', valorv: 0, ncm: '6109.10.00', um: 'UN' });

  useEffect(() => {
    fetchCompras('last');
    fetchAuxiliaryData();
  }, []);

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
        api.get('/v1/produtos?limit=500').catch(() => ({ data: [] }))
      ]);

      setFornecedores(Array.isArray(fRes.data) ? fRes.data : fRes.data?.data || []);
      setProdutos(Array.isArray(pRes.data) ? pRes.data : pRes.data?.data || []);
    } catch (err) {
      console.error('Erro ao carregar listas auxiliares:', err);
    }
  };

  const handleOpenNewPurchase = () => {
    setPurchaseForm({
      id: 0,
      fornecedor_id: fornecedores[0]?.codigo || '',
      fornecedor_nome: fornecedores[0]?.nome || '',
      numero_nf: '',
      chave_nfe: '',
      data_entrada: new Date().toISOString().split('T')[0],
      valor_frete: 0,
      valor_outros: 0,
      observacao: 'Lançamento Manual de Compra',
      itens: []
    });
    setItemForm({
      produto_codigo: '',
      produto_nome: '',
      quantidade: 1,
      valor_unitario: 0,
      valor_frete: 0,
      valor_ipi: 0,
      valor_st: 0,
      valor_outros: 0
    });
    setShowPurchaseForm(true);
  };

  const handleAddItemToPurchase = () => {
    if (!itemForm.produto_codigo) {
      alert('Selecione um produto.');
      return;
    }
    const selectedProd = produtos.find(p => p.codigo === Number(itemForm.produto_codigo));
    const newItem = {
      ...itemForm,
      produto_codigo: Number(itemForm.produto_codigo),
      produto_nome: selectedProd ? selectedProd.nome : (itemForm.produto_nome || `Produto #${itemForm.produto_codigo}`),
      quantidade: Number(itemForm.quantidade) || 1,
      valor_unitario: Number(itemForm.valor_unitario) || 0,
      valor_frete: Number(itemForm.valor_frete) || 0,
      valor_ipi: Number(itemForm.valor_ipi) || 0,
      valor_st: Number(itemForm.valor_st) || 0,
      valor_outros: Number(itemForm.valor_outros) || 0,
      matched: true
    };

    setPurchaseForm(prev => ({
      ...prev,
      itens: [...prev.itens, newItem]
    }));

    setItemForm({
      produto_codigo: '',
      produto_nome: '',
      quantidade: 1,
      valor_unitario: 0,
      valor_frete: 0,
      valor_ipi: 0,
      valor_st: 0,
      valor_outros: 0
    });
  };

  const handleRemoveItem = (index) => {
    setPurchaseForm(prev => ({
      ...prev,
      itens: prev.itens.filter((_, i) => i !== index)
    }));
  };

  const calcularTotalForm = () => {
    const subtotal = purchaseForm.itens.reduce((acc, item) => acc + (item.quantidade * item.valor_unitario), 0);
    const frete = Number(purchaseForm.valor_frete) || 0;
    const outros = Number(purchaseForm.valor_outros) || 0;
    return subtotal + frete + outros;
  };

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
      const payload = {
        ...purchaseForm,
        fornecedor_id: Number(purchaseForm.fornecedor_id) || 0,
        fornecedor_nome: selectedForn ? (selectedForn.nome || selectedForn.razao_social) : purchaseForm.fornecedor_nome,
        numero_nf: purchaseForm.numero_nf || 'MANUAL',
        chave_nfe: purchaseForm.chave_nfe || '', // Opcional sem validação de 44 dígitos
        valor_total: calcularTotalForm(),
        valor_frete: Number(purchaseForm.valor_frete) || 0,
        valor_outros: Number(purchaseForm.valor_outros) || 0
      };

      await api.post('/v1/compras', payload);
      alert('Compra lançada com sucesso! Os custos e estoques dos produtos foram atualizados no banco de dados.');
      setSuccessMsg('Compra lançada com sucesso! Os custos e estoques foram atualizados.');
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

  // Helper de leitura seguro de XML
  const getXmlText = (parent, tagName) => {
    if (!parent) return '';
    const el = parent.getElementsByTagName(tagName)[0] || parent.getElementsByTagNameNS('*', tagName)[0];
    return el ? (el.textContent || '').trim() : '';
  };

  // Parser de XML NF-e Client-Side
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

        // Emitente (Fornecedor)
        const emitNode = xmlDoc.getElementsByTagName('emit')[0] || xmlDoc.getElementsByTagNameNS('*', 'emit')[0];
        const emitNome = getXmlText(emitNode, 'xNome');
        const emitFantasia = getXmlText(emitNode, 'xFant') || emitNome;
        const emitCnpj = getXmlText(emitNode, 'CNPJ') || getXmlText(emitNode, 'CPF');

        const cleanCnpj = emitCnpj.replace(/\D/g, '');
        const matchedForn = fornecedores.find(f => {
          const fCnpj = (f.cnpj_cpf || f.cnpj || '').replace(/\D/g, '');
          return fCnpj && cleanCnpj && fCnpj === cleanCnpj;
        });

        // Itens (det)
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
          itens: parsedItens
        });

        setShowPurchaseForm(true);
        setSuccessMsg(`XML NFe #${nNF} de ${emitNome} importado com ${parsedItens.length} itens!`);
        setTimeout(() => setSuccessMsg(''), 5000);
      } catch (err) {
        console.error('Erro ao ler XML NFe:', err);
        alert('Erro ao processar arquivo XML NFe.');
      }
    };
    reader.readAsText(file);
    event.target.value = '';
  };

  const handleOpenDetailModal = async (compraId) => {
    setLoading(true);
    try {
      const res = await api.get(`/v1/compras/${compraId}`);
      setShowDetailModal(res.data);
    } catch (err) {
      alert('Erro ao carregar detalhes da compra.');
    } finally {
      setLoading(false);
    }
  };

  // Quick Vendor Save
  const handleSaveQuickVendor = async (e) => {
    e.preventDefault();
    if (!quickVendorForm.nome.trim()) return;
    setLoading(true);
    try {
      const newCode = Math.floor(Math.random() * 9000) + 1000;
      await api.post('/v1/fornecedores', {
        codigo: newCode,
        nome: quickVendorForm.nome,
        razao_social: quickVendorForm.nome,
        fantasia: quickVendorForm.fantasia || quickVendorForm.nome,
        cnpj: quickVendorForm.cnpj,
        telefone: quickVendorForm.telefone,
        uf: quickVendorForm.uf || 'PR'
      });
      alert(`Fornecedor "${quickVendorForm.nome}" cadastrado com sucesso!`);
      setShowQuickVendorModal(false);
      setPurchaseForm(prev => ({ ...prev, fornecedor_id: newCode, fornecedor_nome: quickVendorForm.nome }));
      setQuickVendorForm({ nome: '', fantasia: '', cnpj: '', telefone: '', uf: 'PR' });
      fetchAuxiliaryData();
    } catch (err) {
      alert('Erro ao cadastrar fornecedor.');
    } finally {
      setLoading(false);
    }
  };

  // Quick Product Save
  const handleSaveQuickProduct = async (e) => {
    e.preventDefault();
    if (!quickProductForm.nome.trim()) return;
    setLoading(true);
    try {
      const newCode = Math.floor(Math.random() * 90000) + 10000;
      await api.post('/v1/produtos', {
        codigo: newCode,
        nome: quickProductForm.nome,
        codbarra: quickProductForm.codbarra,
        valorv: Number(quickProductForm.valorv) || 0,
        ncm: quickProductForm.ncm || '6109.10.00',
        um: quickProductForm.um || 'UN',
        embalagem: quickProductForm.um || 'UN',
        cadastrar: 'S'
      });
      alert(`Produto "${quickProductForm.nome}" (#${newCode}) cadastrado com sucesso!`);
      if (quickProductTargetIndex !== null && quickProductTargetIndex !== undefined) {
        setPurchaseForm(prev => {
          const updated = [...prev.itens];
          updated[quickProductTargetIndex] = {
            ...updated[quickProductTargetIndex],
            produto_codigo: newCode,
            matched: true
          };
          return { ...prev, itens: updated };
        });
      } else {
        setItemForm(prev => ({ ...prev, produto_codigo: newCode, produto_nome: quickProductForm.nome }));
      }
      setShowQuickProductModal(false);
      setQuickProductForm({ nome: '', codbarra: '', valorv: 0, ncm: '6109.10.00', um: 'UN' });
      setQuickProductTargetIndex(null);
      fetchAuxiliaryData();
    } catch (err) {
      alert('Erro ao cadastrar produto.');
    } finally {
      setLoading(false);
    }
  };

  // Métricas
  const comprasList = Array.isArray(compras) ? compras : [];

  // Filtro
  const getFilteredCompras = () => {
    return comprasList.filter(c => {
      if (!c) return false;
      const matchesSearch = !searchTerm || (
        (c.numero_nf && String(c.numero_nf).toLowerCase().includes(searchTerm.toLowerCase())) ||
        (c.fornecedor_nome && String(c.fornecedor_nome).toLowerCase().includes(searchTerm.toLowerCase())) ||
        (c.chave_nfe && String(c.chave_nfe).toLowerCase().includes(searchTerm.toLowerCase()))
      );
      const matchesType = filterType === 'todas' ? true :
        filterType === 'xml' ? (c.chave_nfe && c.chave_nfe.length > 0) :
        (!c.chave_nfe || c.chave_nfe.length === 0);

      return matchesSearch && matchesType;
    });
  };

  return (
    <div className="crud-container full-width">

      {successMsg && (
        <div className="glass" style={{ padding: '0.8rem 1.2rem', backgroundColor: 'rgba(34, 197, 94, 0.12)', borderColor: '#22c55e', color: '#15803d', borderRadius: '0.75rem', display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '1rem' }}>
          <CheckCircle2 size={18} /> {successMsg}
        </div>
      )}
      {error && <div className="crud-error-bar"><AlertCircle size={20} /> {error}</div>}

      {/* FORMULÁRIO DE COMPRA OU LISTAGEM (GERENCIAMENTO DE COMPRAS) */}
      {showPurchaseForm ? (
        <div className="glass" style={{ padding: '1.5rem', borderRadius: '1.25rem', display: 'flex', flexDirection: 'column', gap: '1.2rem' }}>
          
          {/* Header do Form */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--border-color)', paddingBottom: '1rem' }}>
            <h4 style={{ margin: 0, display: 'flex', alignItems: 'center', gap: '8px', fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              <FileText size={22} style={{ color: 'var(--accent-primary)' }} /> Entrada de Nota Fiscal / Compra Manual
            </h4>
            <button className="btn-close" onClick={() => setShowPurchaseForm(false)} title="Fechar"><X size={18} /></button>
          </div>

          {/* DADOS DO DOCUMENTO */}
          <div style={{ background: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '0.85rem', padding: '1.25rem' }}>
            <div style={{ fontSize: '0.85rem', fontWeight: 700, color: '#475569', textTransform: 'uppercase', marginBottom: '0.75rem', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Building2 size={16} /> Dados do Documento de Entrada
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem' }}>
              
              {/* Fornecedor */}
              <div className="form-group" style={{ gridColumn: 'span 2' }}>
                <label style={{ fontWeight: 700 }}>Fornecedor *</label>
                <div style={{ display: 'flex', gap: '6px' }}>
                  <select 
                    value={purchaseForm.fornecedor_id} 
                    onChange={(e) => {
                      const id = e.target.value;
                      const f = fornecedores.find(item => item.codigo === Number(id));
                      setPurchaseForm(prev => ({ ...prev, fornecedor_id: id, fornecedor_nome: f ? f.nome : prev.fornecedor_nome }));
                    }}
                    style={{ flex: 1, height: '40px', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }}
                  >
                    <option value="">Selecione um Fornecedor...</option>
                    {fornecedores.map(f => (
                      <option key={f.codigo} value={f.codigo}>#{f.codigo} - {f.nome || f.razao_social || f.fantasia}</option>
                    ))}
                  </select>
                  <button 
                    type="button" 
                    className="btn-secondary" 
                    onClick={() => setShowQuickVendorModal(true)} 
                    title="Cadastrar Novo Fornecedor"
                    style={{ height: '40px', display: 'flex', alignItems: 'center', gap: '4px', padding: '0 12px' }}
                  >
                    <UserPlus size={16} />
                  </button>
                </div>
              </div>

              {/* Número NF */}
              <div className="form-group">
                <label style={{ fontWeight: 700 }}>Número da NF / Doc</label>
                <input 
                  type="text" 
                  value={purchaseForm.numero_nf} 
                  onChange={(e) => setPurchaseForm(prev => ({ ...prev, numero_nf: e.target.value }))} 
                  placeholder="Ex: 001234 ou Recibo"
                  style={{ height: '40px', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }}
                />
              </div>

              {/* Data Entrada */}
              <div className="form-group">
                <label style={{ fontWeight: 700 }}>Data de Entrada</label>
                <input 
                  type="date" 
                  value={purchaseForm.data_entrada} 
                  onChange={(e) => setPurchaseForm(prev => ({ ...prev, data_entrada: e.target.value }))} 
                  style={{ height: '40px', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }}
                />
              </div>

              {/* Chave NFe (Opcional) */}
              <div className="form-group" style={{ gridColumn: 'span 2' }}>
                <label style={{ fontWeight: 700 }}>
                  Chave NFe <span style={{ fontWeight: 400, color: '#64748b', fontSize: '0.78rem' }}>(Opcional para compras manuais)</span>
                </label>
                <input 
                  type="text" 
                  value={purchaseForm.chave_nfe} 
                  onChange={(e) => setPurchaseForm(prev => ({ ...prev, chave_nfe: e.target.value }))} 
                  placeholder="Opcional - Chave de 44 dígitos da NF-e" 
                  style={{ height: '40px', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }}
                />
              </div>

              {/* Frete */}
              <div className="form-group">
                <label style={{ fontWeight: 700 }}>Rateio Frete Total (R$)</label>
                <input 
                  type="number" 
                  step="0.01" 
                  value={purchaseForm.valor_frete} 
                  onChange={(e) => setPurchaseForm(prev => ({ ...prev, valor_frete: parseFloat(e.target.value) || 0 }))} 
                  style={{ height: '40px', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }}
                />
              </div>

              {/* Outras Despesas */}
              <div className="form-group">
                <label style={{ fontWeight: 700 }}>Outras Despesas (R$)</label>
                <input 
                  type="number" 
                  step="0.01" 
                  value={purchaseForm.valor_outros} 
                  onChange={(e) => setPurchaseForm(prev => ({ ...prev, valor_outros: parseFloat(e.target.value) || 0 }))} 
                  style={{ height: '40px', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }}
                />
              </div>

            </div>
          </div>

          {/* BOX DE INCLUSÃO DE ITENS */}
          <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '0.85rem', padding: '1.25rem', boxShadow: '0 2px 8px rgba(0,0,0,0.02)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
              <h5 style={{ margin: 0, fontSize: '0.95rem', fontWeight: 800, color: '#1e293b', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Package size={18} color="#2563eb" /> Adicionar Item à Nota
              </h5>
              <button 
                type="button" 
                className="btn-link" 
                onClick={() => {
                  setQuickProductTargetIndex(null);
                  setShowQuickProductModal(true);
                }} 
                style={{ fontSize: '0.82rem', color: '#2563eb', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '4px' }}
              >
                <Plus size={14} /> Novo Produto em Modal
              </button>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(130px, 1fr))', gap: '0.8rem', alignItems: 'end' }}>
              
              <div className="form-group" style={{ gridColumn: 'span 2', minWidth: '220px' }}>
                <label style={{ fontSize: '0.8rem', fontWeight: 700 }}>Produto</label>
                <select 
                  value={itemForm.produto_codigo} 
                  onChange={(e) => {
                    const cod = e.target.value;
                    const p = produtos.find(item => item.codigo === Number(cod));
                    setItemForm(prev => ({
                      ...prev,
                      produto_codigo: cod,
                      produto_nome: p ? p.nome : '',
                      valor_unitario: p ? (Number(p.valorf || p.valorc) || 0) : prev.valor_unitario
                    }));
                  }}
                  style={{ height: '38px', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }}
                >
                  <option value="">Selecione o Produto...</option>
                  {produtos.map(p => (
                    <option key={p.codigo} value={p.codigo}>#{p.codigo} - {p.nome} (Venda: R$ {p.valorv})</option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label style={{ fontSize: '0.8rem', fontWeight: 700 }}>Quantidade</label>
                <input 
                  type="number" 
                  step="1" 
                  min="1" 
                  value={itemForm.quantidade} 
                  onChange={(e) => setItemForm(prev => ({ ...prev, quantidade: parseFloat(e.target.value) || 0 }))} 
                  style={{ height: '38px', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }}
                />
              </div>

              <div className="form-group">
                <label style={{ fontSize: '0.8rem', fontWeight: 700 }}>Custo Unitário (R$)</label>
                <input 
                  type="number" 
                  step="0.01" 
                  value={itemForm.valor_unitario} 
                  onChange={(e) => setItemForm(prev => ({ ...prev, valor_unitario: parseFloat(e.target.value) || 0 }))} 
                  style={{ height: '38px', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }}
                />
              </div>

              <div className="form-group">
                <label style={{ fontSize: '0.8rem', fontWeight: 700 }}>IPI (Item)</label>
                <input 
                  type="number" 
                  step="0.01" 
                  value={itemForm.valor_ipi} 
                  onChange={(e) => setItemForm(prev => ({ ...prev, valor_ipi: parseFloat(e.target.value) || 0 }))} 
                  style={{ height: '38px', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }}
                />
              </div>

              <div className="form-group">
                <label style={{ fontSize: '0.8rem', fontWeight: 700 }}>ST (Item)</label>
                <input 
                  type="number" 
                  step="0.01" 
                  value={itemForm.valor_st} 
                  onChange={(e) => setItemForm(prev => ({ ...prev, valor_st: parseFloat(e.target.value) || 0 }))} 
                  style={{ height: '38px', borderRadius: '0.5rem', border: '1px solid #cbd5e1' }}
                />
              </div>

              <div>
                <button 
                  type="button" 
                  className="btn-primary" 
                  onClick={handleAddItemToPurchase} 
                  style={{ width: '100%', height: '38px', borderRadius: '0.5rem', fontWeight: 700, fontSize: '0.85rem' }}
                >
                  + Incluir Item
                </button>
              </div>

            </div>
          </div>

          {/* TABELA DE ITENS DA COMPRA */}
          <div className="table-responsive" style={{ border: '1px solid #e2e8f0', borderRadius: '0.75rem', overflow: 'hidden' }}>
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: '80px' }}>Cód</th>
                  <th>Produto</th>
                  <th style={{ textAlign: 'center', width: '90px' }}>Qtd</th>
                  <th style={{ textAlign: 'right' }}>Custo Unit.</th>
                  <th style={{ textAlign: 'right' }}>Custo Mercadoria (Rateado)</th>
                  <th style={{ textAlign: 'right' }}>Custo Operacional (+10%)</th>
                  <th style={{ textAlign: 'right' }}>Total Item</th>
                  <th style={{ textAlign: 'center', width: '70px' }}>Ações</th>
                </tr>
              </thead>
              <tbody>
                {purchaseForm.itens.length === 0 ? (
                  <tr>
                    <td colSpan="8" style={{ textAlign: 'center', padding: '2rem', color: '#64748b' }}>
                      Nenhum item adicionado à compra ainda.
                    </td>
                  </tr>
                ) : (
                  purchaseForm.itens.map((item, idx) => {
                    const rateio = item.quantidade > 0 ? (item.valor_frete + item.valor_ipi + item.valor_st + item.valor_outros) / item.quantidade : 0;
                    const custoMercadoria = item.valor_unitario + rateio;
                    const custoOperacional = custoMercadoria * 1.10;
                    const totalItem = item.quantidade * item.valor_unitario;

                    return (
                      <tr key={idx} className={item.matched === false ? 'row-warning' : ''}>
                        <td>
                          {item.produto_codigo ? (
                            <span className="item-code">#{item.produto_codigo}</span>
                          ) : (
                            <span className="badge badge-warning" style={{ fontSize: '0.75rem' }}>Pendente</span>
                          )}
                        </td>
                        <td>
                          <strong>{item.produto_nome}</strong>
                          {!item.produto_codigo && (
                            <div style={{ marginTop: '4px' }}>
                              <button 
                                type="button" 
                                className="btn-link" 
                                onClick={() => {
                                  setQuickProductForm({
                                    nome: item.produto_nome,
                                    codbarra: item.codbarra || '',
                                    valorv: item.valor_unitario * 1.5,
                                    ncm: '6109.10.00',
                                    um: 'UN'
                                  });
                                  setQuickProductTargetIndex(idx);
                                  setShowQuickProductModal(true);
                                }}
                                style={{ fontSize: '0.8rem', color: '#f59e0b', display: 'inline-flex', alignItems: 'center', gap: '4px' }}
                              >
                                <Plus size={12} /> Cadastrar produto no Modal
                              </button>
                            </div>
                          )}
                        </td>
                        <td style={{ textAlign: 'center' }}><strong>{item.quantidade}</strong></td>
                        <td style={{ textAlign: 'right' }}>{formatCurrency(item.valor_unitario)}</td>
                        <td style={{ textAlign: 'right' }}><span className="badge badge-info">{formatCurrency(custoMercadoria)}</span></td>
                        <td style={{ textAlign: 'right' }}>{formatCurrency(custoOperacional)}</td>
                        <td style={{ textAlign: 'right' }}><strong>{formatCurrency(totalItem)}</strong></td>
                        <td style={{ textAlign: 'center' }}>
                          <button className="crud-row-btn delete" onClick={() => handleRemoveItem(idx)} title="Remover Item"><Trash2 size={14} /></button>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>

          {/* RODAPÉ DO FORMULÁRIO */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid #e2e8f0', paddingTop: '1.25rem', flexWrap: 'wrap', gap: '1rem' }}>
            <div>
              <span style={{ fontSize: '0.85rem', color: '#64748b', fontWeight: 600 }}>Total Geral da Compra:</span>
              <h2 style={{ margin: 0, color: '#2563eb', fontWeight: 800 }}>{formatCurrency(calcularTotalForm())}</h2>
            </div>

            <div style={{ display: 'flex', gap: '0.8rem' }}>
              <button className="btn-secondary" onClick={() => setShowPurchaseForm(false)}>Cancelar</button>
              <button className="btn-primary" onClick={handleSavePurchase} disabled={loading} style={{ padding: '0.75rem 1.75rem', fontWeight: 700 }}>
                <Save size={18} /> Salvar & Dar Entrada no Estoque
              </button>
            </div>
          </div>

        </div>
      ) : (
        /* GERENCIAMENTO DE COMPRAS (SCREENSHOT 1) */
        <div className="glass" style={{ padding: '1.5rem', borderRadius: '1.25rem', display: 'flex', flexDirection: 'column', gap: '1.2rem' }}>
          
          <div className="crud-title-row">
            <h3 style={{ margin: 0, fontSize: '1.3rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              Gerenciamento de COMPRAS
            </h3>

            <div style={{ display: 'flex', gap: '0.6rem', flexWrap: 'wrap', alignItems: 'center' }}>
              <button className="crud-tab-btn" onClick={() => fetchCompras(1)} style={{ border: '1px solid rgba(0,0,0,0.1)', background: '#fff', gap: '6px' }}>
                <RefreshCw size={16} /> Atualizar
              </button>

              <label className="crud-tab-btn" style={{ cursor: 'pointer', border: '1px solid rgba(0,0,0,0.1)', background: '#fff', margin: 0, gap: '6px' }}>
                <Upload size={16} /> Importar XML (NFe)
                <input type="file" ref={fileInputRef} accept=".xml" onChange={handleFileUpload} style={{ display: 'none' }} />
              </label>

              <button className="crud-add-btn" onClick={handleOpenNewPurchase} style={{ gap: '6px' }}>
                <Plus size={16} /> Adicionar Novo
              </button>
            </div>
          </div>

          <SearchBar
            value={searchTerm}
            onChange={(val) => setSearchTerm(val)}
            onSearch={() => fetchCompras(1)}
            onClear={() => setSearchTerm('')}
            placeholder="Buscar por fornecedor, número NF ou chave NFe..."
          />

          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: '110px' }}>Código Compra</th>
                  <th style={{ width: '120px' }}>NF-e</th>
                  <th>Fornecedor</th>
                  <th style={{ width: '130px' }}>Data Entrada</th>
                  <th style={{ width: '130px', textAlign: 'right' }}>Valor Total</th>
                  <th style={{ textAlign: 'center', width: '80px' }}>Ações</th>
                </tr>
              </thead>
              <tbody>
                {getFilteredCompras().length === 0 ? (
                  <tr>
                    <td colSpan="6" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                      Nenhuma compra encontrada.
                    </td>
                  </tr>
                ) : (
                  getFilteredCompras().map((compra) => (
                    <tr key={compra.id}>
                      <td><span className="item-code">#{compra.id}</span></td>
                      <td><strong>{compra.numero_nf ? `NF #${compra.numero_nf}` : 'Manual'}</strong></td>
                      <td>{compra.fornecedor_nome || `Fornecedor #${compra.fornecedor_id}`}</td>
                      <td>{compra.data_entrada || '-'}</td>
                      <td style={{ textAlign: 'right' }}><strong style={{ color: 'var(--accent-primary)' }}>{formatCurrency(compra.valor_total)}</strong></td>
                      <td className="actions-cell">
                        <button className="crud-row-btn edit" onClick={() => handleOpenDetailModal(compra.id)} title="Ver Detalhes">
                          <Eye size={16} />
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          <Pagination
            currentPage={meta.page || page}
            totalPages={meta.pages || 1}
            onPageChange={(p) => fetchCompras(p)}
          />
        </div>
      )}

      {/* MODAL POPUP DE DETALHES DA COMPRA */}
      {showDetailModal && createPortal(
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setShowDetailModal(null); }}>
          <div className="modal-content glass" style={{ maxWidth: '850px' }}>
            <div className="modal-header">
              <h4><FileText size={20} style={{ color: 'var(--accent-primary)' }} /> Detalhes da Compra #{showDetailModal.id}</h4>
              <button className="btn-close" onClick={() => setShowDetailModal(null)}><X size={18} /></button>
            </div>

            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '1rem', padding: '1rem 0' }}>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '0.8rem', background: '#f8fafc', padding: '1rem', borderRadius: '0.75rem', border: '1px solid #e2e8f0' }}>
                <div>
                  <span style={{ fontSize: '0.75rem', color: '#64748b', fontWeight: 700 }}>FORNECEDOR:</span>
                  <div><strong>{showDetailModal.fornecedor_nome || `Cód: #${showDetailModal.fornecedor_id}`}</strong></div>
                </div>
                <div>
                  <span style={{ fontSize: '0.75rem', color: '#64748b', fontWeight: 700 }}>NÚMERO DA NOTA:</span>
                  <div><strong>{showDetailModal.numero_nf || 'Sem Número'}</strong></div>
                </div>
                <div>
                  <span style={{ fontSize: '0.75rem', color: '#64748b', fontWeight: 700 }}>DATA DE ENTRADA:</span>
                  <div>{showDetailModal.data_entrada || '-'}</div>
                </div>
                <div>
                  <span style={{ fontSize: '0.75rem', color: '#64748b', fontWeight: 700 }}>VALOR TOTAL:</span>
                  <div style={{ color: '#16a34a', fontWeight: 800 }}>{formatCurrency(showDetailModal.valor_total)}</div>
                </div>
                {showDetailModal.chave_nfe && (
                  <div style={{ gridColumn: '1 / -1' }}>
                    <span style={{ fontSize: '0.75rem', color: '#64748b', fontWeight: 700 }}>CHAVE DA NFE:</span>
                    <div style={{ fontFamily: 'monospace', fontSize: '0.8rem', wordBreak: 'break-all' }}>{showDetailModal.chave_nfe}</div>
                  </div>
                )}
              </div>

              <h5 style={{ margin: '0.5rem 0 0 0', fontWeight: 800 }}>Itens da Compra ({showDetailModal.itens?.length || 0})</h5>
              <div className="table-responsive" style={{ maxHeight: '300px', overflowY: 'auto' }}>
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Cód</th>
                      <th>Produto</th>
                      <th style={{ textAlign: 'center' }}>Qtd</th>
                      <th style={{ textAlign: 'right' }}>Custo Entrada</th>
                      <th style={{ textAlign: 'right' }}>Custo Mercadoria</th>
                      <th style={{ textAlign: 'right' }}>Custo Operacional</th>
                      <th style={{ textAlign: 'right' }}>Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    {(showDetailModal.itens || []).map((it, idx) => (
                      <tr key={idx}>
                        <td><span className="item-code">#{it.produto_codigo}</span></td>
                        <td><strong>{it.produto_nome}</strong></td>
                        <td style={{ textAlign: 'center' }}>{it.quantidade}</td>
                        <td style={{ textAlign: 'right' }}>{formatCurrency(it.valor_unitario)}</td>
                        <td style={{ textAlign: 'right' }}>{formatCurrency(it.custo_mercadoria || it.valor_unitario)}</td>
                        <td style={{ textAlign: 'right' }}>{formatCurrency(it.custo_operacional || (it.valor_unitario * 1.1))}</td>
                        <td style={{ textAlign: 'right' }}><strong>{formatCurrency(it.quantidade * it.valor_unitario)}</strong></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '1rem' }}>
              <button type="button" className="btn-secondary" onClick={() => setShowDetailModal(null)}>Fechar</button>
            </div>
          </div>
        </div>,
        document.body
      )}

      {/* QUICK VENDOR MODAL */}
      {showQuickVendorModal && createPortal(
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setShowQuickVendorModal(false); }}>
          <div className="modal-content glass" style={{ maxWidth: '480px' }}>
            <div className="modal-header">
              <h4><UserPlus size={20} color="#2563eb" /> Cadastrar Fornecedor Rápido</h4>
              <button className="btn-close" onClick={() => setShowQuickVendorModal(false)}><X size={18} /></button>
            </div>
            <form onSubmit={handleSaveQuickVendor}>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem', padding: '1rem 0' }}>
                <div className="form-group">
                  <label>Razão Social / Nome *</label>
                  <input type="text" required value={quickVendorForm.nome} onChange={(e) => setQuickVendorForm({ ...quickVendorForm, nome: e.target.value })} placeholder="Ex: DISTRIBUIDORA BRASIL" />
                </div>
                <div className="form-group">
                  <label>Nome Fantasia</label>
                  <input type="text" value={quickVendorForm.fantasia} onChange={(e) => setQuickVendorForm({ ...quickVendorForm, fantasia: e.target.value })} placeholder="Ex: TECIDOS BR" />
                </div>
                <div className="form-group">
                  <label>CNPJ / CPF</label>
                  <input type="text" value={quickVendorForm.cnpj} onChange={(e) => setQuickVendorForm({ ...quickVendorForm, cnpj: e.target.value })} placeholder="00.000.000/0001-00" />
                </div>
                <div className="form-group">
                  <label>Telefone / WhatsApp</label>
                  <input type="text" value={quickVendorForm.telefone} onChange={(e) => setQuickVendorForm({ ...quickVendorForm, telefone: e.target.value })} placeholder="(00) 00000-0000" />
                </div>
              </div>
              <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.6rem' }}>
                <button type="button" className="btn-secondary" onClick={() => setShowQuickVendorModal(false)}>Cancelar</button>
                <button type="submit" className="btn-primary" disabled={loading}>Salvar Fornecedor</button>
              </div>
            </form>
          </div>
        </div>,
        document.body
      )}

      {/* QUICK PRODUCT MODAL */}
      {showQuickProductModal && createPortal(
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setShowQuickProductModal(false); }}>
          <div className="modal-content glass" style={{ maxWidth: '480px' }}>
            <div className="modal-header">
              <h4><PackagePlus size={20} color="#059669" /> Cadastrar Produto Rápido</h4>
              <button className="btn-close" onClick={() => setShowQuickProductModal(false)}><X size={18} /></button>
            </div>
            <form onSubmit={handleSaveQuickProduct}>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem', padding: '1rem 0' }}>
                <div className="form-group">
                  <label>Nome do Produto *</label>
                  <input type="text" required value={quickProductForm.nome} onChange={(e) => setQuickProductForm({ ...quickProductForm, nome: e.target.value })} placeholder="Ex: CAMISETA POLO AZUL M" />
                </div>
                <div className="form-group">
                  <label>Código de Barras (EAN)</label>
                  <input type="text" value={quickProductForm.codbarra} onChange={(e) => setQuickProductForm({ ...quickProductForm, codbarra: e.target.value })} placeholder="789..." />
                </div>
                <div className="form-group">
                  <label>Preço de Venda Sugerido (R$)</label>
                  <input type="number" step="0.01" value={quickProductForm.valorv} onChange={(e) => setQuickProductForm({ ...quickProductForm, valorv: parseFloat(e.target.value) || 0 })} placeholder="59.90" />
                </div>
              </div>
              <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.6rem' }}>
                <button type="button" className="btn-secondary" onClick={() => setShowQuickProductModal(false)}>Cancelar</button>
                <button type="submit" className="btn-primary" disabled={loading}>Salvar Produto</button>
              </div>
            </form>
          </div>
        </div>,
        document.body
      )}

    </div>
  );
}
