import { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { 
  ShoppingCart, Upload, Plus, Eye, FileText, UserPlus, PackagePlus, 
  X, Save, AlertCircle, Building2, CheckCircle2, DollarSign, Calendar,
  TrendingUp, Search, Filter, AlertTriangle, FolderPlus, Layers, Grid, Ruler,
  ArrowRight, RefreshCw, Trash2
} from 'lucide-react';
import { createApi } from '../../services/api';
import Pagination from '../Pagination';
import SearchBar from '../SearchBar';
import { formatCurrency } from '../../utils/formatters';
import './CadastrosTab.css';

export default function PurchasesTab() {
  const api = createApi(true); // Conecta na CD_API_BASE (port 9000)
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  // Lista e Paginação de Compras
  const [compras, setCompras] = useState([]);
  const [page, setPage] = useState(1);
  const [meta, setMeta] = useState({ page: 1, limit: 10, total: 0, pages: 1 });
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState('todas'); // 'todas', 'xml', 'manual'

  // Listas auxiliares para selects
  const [fornecedores, setFornecedores] = useState([]);
  const [produtos, setProdutos] = useState([]);
  const [grupos, setGrupos] = useState([]);
  const [subgrupos, setSubgrupos] = useState([]);
  const [tamanhos, setTamanhos] = useState([]);

  // Modais de Visualização e Compra
  const [showPurchaseForm, setShowPurchaseForm] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(null);

  // Modais de Cadastros Rápidos (Todos os Cadastros em Modais)
  const [activeModal, setActiveModal] = useState(null); // 'produto', 'fornecedor', 'grupo', 'subgrupo', 'grade', 'tamanho'

  // Estado do Formulário de Compra
  const [purchaseForm, setPurchaseForm] = useState({
    id: 0,
    fornecedor_id: '',
    fornecedor_nome: '',
    numero_nf: '',
    chave_nfe: '',
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

  // Estados dos Formulários de Cadastro em Modais
  const [prodForm, setProdForm] = useState({ nome: '', fabricante: '', codbarra: '', valorv: 0, targetItemIndex: null });
  const [fornForm, setFornForm] = useState({ nome: '', fantasia: '', cnpj: '', endereco: '', bairro: '', uf: 'SP' });
  const [grupoForm, setGrupoForm] = useState({ nome: '' });
  const [subgrupoForm, setSubgrupoForm] = useState({ nome: '', g1: '' });
  const [gradeForm, setGradeForm] = useState({ pro: '', tam: '', cor: '', codbarra: '', quantidade: 1, valor: 0 });
  const [tamanhoForm, setTamanhoForm] = useState({ tamanho: '', sigla: '', valor: 0, pro: '' });

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
      const [fRes, pRes, gRes, sgRes, tRes] = await Promise.all([
        api.get('/v1/fornecedores?limit=500'),
        api.get('/v1/produtos?limit=500'),
        api.get('/v1/grupos?limit=200'),
        api.get('/v1/subgrupos?limit=200'),
        api.get('/v1/tamanhos?limit=200')
      ]);

      setFornecedores(Array.isArray(fRes.data) ? fRes.data : fRes.data?.data || []);
      setProdutos(Array.isArray(pRes.data) ? pRes.data : pRes.data?.data || []);
      setGrupos(Array.isArray(gRes.data) ? gRes.data : gRes.data?.data || []);
      setSubgrupos(Array.isArray(sgRes.data) ? sgRes.data : sgRes.data?.data || []);
      setTamanhos(Array.isArray(tRes.data) ? tRes.data : tRes.data?.data || []);
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
      valor_frete: 0,
      valor_outros: 0,
      observacao: 'Lançamento Manual de Compra',
      itens: []
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
      alert(`O produto "${unmatched.produto_nome}" ainda não possui vínculo de código. Clique em "+ Novo Produto no Modal" ao lado do item para vinculá-lo antes de finalizar.`);
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
        valor_total: calcularTotalForm(),
        valor_frete: Number(purchaseForm.valor_frete) || 0,
        valor_outros: Number(purchaseForm.valor_outros) || 0
      };

      const res = await api.post('/v1/compras', payload);
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

  // Helper de leitura seguro de XML sem diferenciar namespace
  const getXmlText = (parent, tagName) => {
    if (!parent) return '';
    const el = parent.getElementsByTagName(tagName)[0] || parent.getElementsByTagNameNS('*', tagName)[0];
    return el ? (el.textContent || '').trim() : '';
  };

  // Parser de XML NF-e Client-Side Robusto
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

        // Tenta encontrar fornecedor existente pelo CNPJ normalizado
        const cleanCnpj = emitCnpj.replace(/\D/g, '');
        const matchedForn = fornecedores.find(f => {
          const fCnpj = (f.cnpj_cpf || f.cnpj || '').replace(/\D/g, '');
          return fCnpj && cleanCnpj && fCnpj === cleanCnpj;
        });

        if (!matchedForn && emitNome) {
          setFornForm({
            nome: emitNome,
            fantasia: emitFantasia,
            cnpj: emitCnpj,
            endereco: '',
            bairro: '',
            uf: 'SP'
          });
        }

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

  // --- HANDLERS PARA SALVAR OS 6 CADASTROS EM MODAIS ---

  const handleSaveProductModal = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const newCode = Math.floor(Math.random() * 90000) + 10000;
      const payload = {
        codigo: newCode,
        nome: prodForm.nome,
        fabricante: prodForm.fabricante,
        codbarra: prodForm.codbarra,
        quantidade: 0,
        valorv: Number(prodForm.valorv) || 0,
        codTotalizador: Number(prodForm.codTotalizador) || 1,
        ncm: prodForm.ncm || '6109.10.00',
        um: prodForm.um || 'UN',
        embalagem: prodForm.um || 'UN',
        cadastrar: 'S',
        url_Imagem: ''
      };
      await api.post('/v1/produtos', payload);

      // Distribuição automática do produto novo para todas as unidades/filiais
      try {
        const empRes = await api.get('/v1/empresa');
        if (Array.isArray(empRes.data)) {
          const activeUnitId = Number(localStorage.getItem('selected_company_id')) || 1;
          const otherUnits = empRes.data.filter(u => u.codigo !== activeUnitId);
          for (const unit of otherUnits) {
            const transferId = Math.floor(Math.random() * 90000) + 10000;
            const transferData = {
              id: transferId,
              origem: activeUnitId,
              destino: unit.codigo,
              data: new Date().toISOString().split('T')[0],
              status: 'Em Trânsito',
              obs: 'Distribuição automática de novo produto cadastrado',
              usuarioRecebimento: '',
              dataRecebimento: '1899-12-30'
            };
            await api.post('/v1/transferencias', transferData);
            const itemData = {
              id: Math.floor(Math.random() * 900000) + 100000,
              transferenciaId: transferId,
              produtoId: newCode,
              quantidade: 0,
              valor: payload.valorv,
              quantidadeConferida: 0
            };
            await api.post('/v1/transferenciaItens/emLote', { itens: [itemData] });
          }
        }
      } catch (distErr) {
        console.error('Erro ao agendar distribuição de novo produto:', distErr);
      }

      alert(`Produto "${prodForm.nome}" (#${newCode}) cadastrado e distribuído para as filiais!`);

      if (prodForm.targetItemIndex !== null && prodForm.targetItemIndex !== undefined) {
        setPurchaseForm(prev => {
          const updated = [...prev.itens];
          updated[prodForm.targetItemIndex] = {
            ...updated[prodForm.targetItemIndex],
            produto_codigo: newCode,
            matched: true
          };
          return { ...prev, itens: updated };
        });
      }
      setActiveModal(null);
      setProdForm({ nome: '', fabricante: '', codbarra: '', valorv: 0, targetItemIndex: null });
      fetchAuxiliaryData();
    } catch (err) {
      alert('Erro ao cadastrar produto.');
    } finally {
      setLoading(false);
    }
  };

  const handleSaveFornecedorModal = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const newCode = Math.floor(Math.random() * 9000) + 1000;
      const payload = {
        codigo: newCode,
        nome: fornForm.nome,
        razao_social: fornForm.nome,
        fantasia: fornForm.fantasia || fornForm.nome,
        cnpj_cpf: fornForm.cnpj,
        endereco: fornForm.endereco,
        bairro: fornForm.bairro,
        uf: fornForm.uf || 'SP'
      };
      await api.post('/v1/fornecedores', payload);
      alert(`Fornecedor "${fornForm.nome}" (#${newCode}) cadastrado com sucesso!`);

      setPurchaseForm(prev => ({
        ...prev,
        fornecedor_id: newCode,
        fornecedor_nome: fornForm.nome
      }));

      setActiveModal(null);
      setFornForm({ nome: '', fantasia: '', cnpj: '', endereco: '', bairro: '', uf: 'SP' });
      fetchAuxiliaryData();
    } catch (err) {
      alert('Erro ao cadastrar fornecedor.');
    } finally {
      setLoading(false);
    }
  };

  const handleSaveGrupoModal = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const newCode = Math.floor(Math.random() * 9000) + 1000;
      await api.post('/v1/grupos', { codigo: newCode, nome: grupoForm.nome });
      alert(`Grupo "${grupoForm.nome}" (#${newCode}) cadastrado com sucesso!`);
      setActiveModal(null);
      setGrupoForm({ nome: '' });
      fetchAuxiliaryData();
    } catch (err) {
      alert('Erro ao cadastrar grupo.');
    } finally {
      setLoading(false);
    }
  };

  const handleSaveSubgrupoModal = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const newCode = Math.floor(Math.random() * 9000) + 1000;
      await api.post('/v1/subgrupos', { codigo: newCode, nome: subgrupoForm.nome, g1: Number(subgrupoForm.g1) || 1 });
      alert(`Subgrupo "${subgrupoForm.nome}" (#${newCode}) cadastrado com sucesso!`);
      setActiveModal(null);
      setSubgrupoForm({ nome: '', g1: '' });
      fetchAuxiliaryData();
    } catch (err) {
      alert('Erro ao cadastrar subgrupo.');
    } finally {
      setLoading(false);
    }
  };

  const handleSaveGradeModal = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const newCode = Math.floor(Math.random() * 90000) + 10000;
      await api.post('/v1/grades', {
        codigo: newCode,
        pro: Number(gradeForm.pro),
        tam: Number(gradeForm.tam),
        cor: gradeForm.cor,
        codbarra: gradeForm.codbarra,
        quantidade: Number(gradeForm.quantidade) || 0,
        valor: Number(gradeForm.valor) || 0
      });
      alert(`Grade cadastrada com sucesso!`);
      setActiveModal(null);
      setGradeForm({ pro: '', tam: '', cor: '', codbarra: '', quantidade: 1, valor: 0 });
      fetchAuxiliaryData();
    } catch (err) {
      alert('Erro ao cadastrar grade.');
    } finally {
      setLoading(false);
    }
  };

  const handleSaveTamanhoModal = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const newCode = Math.floor(Math.random() * 9000) + 1000;
      await api.post('/v1/tamanhos', {
        codigo: newCode,
        tamanho: tamanhoForm.tamanho,
        sigla: tamanhoForm.sigla,
        valor: Number(tamanhoForm.valor) || 0,
        pro: Number(tamanhoForm.pro) || 0
      });
      alert(`Tamanho "${tamanhoForm.tamanho}" (#${newCode}) cadastrado com sucesso!`);
      setActiveModal(null);
      setTamanhoForm({ tamanho: '', sigla: '', valor: 0, pro: '' });
      fetchAuxiliaryData();
    } catch (err) {
      alert('Erro ao cadastrar tamanho.');
    } finally {
      setLoading(false);
    }
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

  // Métricas
  const comprasList = Array.isArray(compras) ? compras : [];
  const totalComprasCount = meta?.total || comprasList.length;
  const valorTotalAcumulado = comprasList.reduce((acc, curr) => acc + (Number(curr?.valor_total) || 0), 0);
  const mediaPorCompra = totalComprasCount > 0 ? valorTotalAcumulado / totalComprasCount : 0;
  const ultimaCompraData = comprasList[0]?.data_entrada || '-';

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

      {/* SUB MENU DE CADASTROS (IGUAL AO ANEXO CADASTROS CENTRALIZADOS) */}
      <div className="crud-header-tabs glass">
        <button className="crud-tab-btn active">
          <ShoppingCart size={18} /> Compras
        </button>
        <button className="crud-tab-btn" onClick={() => setActiveModal('grupo')}>
          <FolderPlus size={18} /> Grupos
        </button>
        <button className="crud-tab-btn" onClick={() => setActiveModal('subgrupo')}>
          <Layers size={18} /> Subgrupos
        </button>
        <button className="crud-tab-btn" onClick={() => setActiveModal('grade')}>
          <Grid size={18} /> Grades
        </button>
        <button className="crud-tab-btn" onClick={() => setActiveModal('tamanho')}>
          <Ruler size={18} /> Tamanhos
        </button>
        <button className="crud-tab-btn" onClick={() => setActiveModal('produto')}>
          <PackagePlus size={18} /> Produtos
        </button>
        <button className="crud-tab-btn" onClick={() => setActiveModal('fornecedor')}>
          <UserPlus size={18} /> Fornecedores
        </button>
      </div>

      {successMsg && (
        <div className="glass" style={{ padding: '0.8rem 1.2rem', backgroundColor: 'rgba(34, 197, 94, 0.12)', borderColor: '#22c55e', color: '#15803d', borderRadius: '0.75rem', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <CheckCircle2 size={18} /> {successMsg}
        </div>
      )}
      {error && <div className="crud-error-bar"><AlertCircle size={20} /> {error}</div>}

      {/* FORMULÁRIO DE COMPRA OU LISTAGEM (GERENCIAMENTO DE COMPRAS) */}
      {showPurchaseForm ? (
        <div className="glass" style={{ padding: '1.5rem', borderRadius: '1.25rem', display: 'flex', flexDirection: 'column', gap: '1.2rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--border-color)', paddingBottom: '1rem', marginBottom: '0.5rem' }}>
            <h4 style={{ margin: 0, display: 'flex', alignItems: 'center', gap: '8px', fontSize: '1.2rem', fontWeight: 700 }}>
              <FileText size={20} style={{ color: 'var(--accent-primary)' }} /> Entrada de Nota Fiscal / Compra Manual
            </h4>
            <button className="btn-close" onClick={() => setShowPurchaseForm(false)}><X size={18} /></button>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem', marginBottom: '1rem' }}>
            <div className="form-group">
              <label>Fornecedor *</label>
              <div style={{ display: 'flex', gap: '6px' }}>
                <select 
                  value={purchaseForm.fornecedor_id} 
                  onChange={(e) => {
                    const id = e.target.value;
                    const f = fornecedores.find(item => item.codigo === Number(id));
                    setPurchaseForm(prev => ({ ...prev, fornecedor_id: id, fornecedor_nome: f ? f.nome : prev.fornecedor_nome }));
                  }}
                  style={{ flex: 1 }}
                >
                  <option value="">Selecione um Fornecedor...</option>
                  {fornecedores.map(f => (
                    <option key={f.codigo} value={f.codigo}>#{f.codigo} - {f.nome || f.razao_social}</option>
                  ))}
                </select>
                <button type="button" className="btn-secondary" onClick={() => setActiveModal('fornecedor')} title="Novo Fornecedor em Modal"><UserPlus size={16} /></button>
              </div>
              {!purchaseForm.fornecedor_id && purchaseForm.fornecedor_nome && (
                <div style={{ marginTop: '4px' }}>
                  <button type="button" className="btn-link" onClick={() => setActiveModal('fornecedor')} style={{ color: '#f59e0b', fontSize: '0.8rem', display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <AlertTriangle size={14} /> Fornecedor "{purchaseForm.fornecedor_nome}" não cadastrado. Cadastre no Modal!
                  </button>
                </div>
              )}
            </div>

            <div className="form-group">
              <label>Número da NF</label>
              <input type="text" value={purchaseForm.numero_nf} onChange={(e) => setPurchaseForm(prev => ({ ...prev, numero_nf: e.target.value }))} placeholder="Ex: 001234" />
            </div>

            <div className="form-group">
              <label>Chave NFe (44 dígitos)</label>
              <input type="text" value={purchaseForm.chave_nfe} onChange={(e) => setPurchaseForm(prev => ({ ...prev, chave_nfe: e.target.value }))} placeholder="Chave da Nota Fiscal" />
            </div>

            <div className="form-group">
              <label>Rateio Frete Total (R$)</label>
              <input type="number" step="0.01" value={purchaseForm.valor_frete} onChange={(e) => setPurchaseForm(prev => ({ ...prev, valor_frete: parseFloat(e.target.value) || 0 }))} />
            </div>

            <div className="form-group">
              <label>Outras Despesas (R$)</label>
              <input type="number" step="0.01" value={purchaseForm.valor_outros} onChange={(e) => setPurchaseForm(prev => ({ ...prev, valor_outros: parseFloat(e.target.value) || 0 }))} />
            </div>
          </div>

          {/* BOX DE INCLUSÃO DE ITENS */}
          <div className="glass" style={{ padding: '1.2rem', borderRadius: '12px', marginBottom: '1rem', backgroundColor: 'rgba(0,0,0,0.02)', border: '1px solid rgba(0,0,0,0.06)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
              <h5 style={{ margin: 0, fontSize: '1rem', fontWeight: 600 }}>Adicionar Item à Nota</h5>
              <button type="button" className="btn-link" onClick={() => setActiveModal('produto')} style={{ fontSize: '0.85rem', color: 'var(--accent-primary)' }}>+ Novo Produto em Modal</button>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(130px, 1fr))', gap: '0.8rem', alignItems: 'end' }}>
              <div className="form-group" style={{ gridColumn: 'span 2' }}>
                <label>Produto</label>
                <select value={itemForm.produto_codigo} onChange={(e) => setItemForm(prev => ({ ...prev, produto_codigo: e.target.value }))}>
                  <option value="">Selecione o Produto...</option>
                  {produtos.map(p => (
                    <option key={p.codigo} value={p.codigo}>#{p.codigo} - {p.nome} (Atual: R$ {p.valorv})</option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label>Quantidade</label>
                <input type="number" step="1" min="1" value={itemForm.quantidade} onChange={(e) => setItemForm(prev => ({ ...prev, quantidade: parseFloat(e.target.value) || 0 }))} />
              </div>

              <div className="form-group">
                <label>Custo Unitário (R$)</label>
                <input type="number" step="0.01" value={itemForm.valor_unitario} onChange={(e) => setItemForm(prev => ({ ...prev, valor_unitario: parseFloat(e.target.value) || 0 }))} />
              </div>

              <div className="form-group">
                <label>IPI (Item)</label>
                <input type="number" step="0.01" value={itemForm.valor_ipi} onChange={(e) => setItemForm(prev => ({ ...prev, valor_ipi: parseFloat(e.target.value) || 0 }))} />
              </div>

              <div className="form-group">
                <label>ST (Item)</label>
                <input type="number" step="0.01" value={itemForm.valor_st} onChange={(e) => setItemForm(prev => ({ ...prev, valor_st: parseFloat(e.target.value) || 0 }))} />
              </div>

              <div>
                <button type="button" className="btn-primary" onClick={handleAddItemToPurchase} style={{ width: '100%', height: '42px', borderRadius: '8px' }}>+ Incluir Item</button>
              </div>
            </div>
          </div>

          {/* TABELA DE ITENS DA COMPRA */}
          <div className="table-responsive" style={{ marginBottom: '1.5rem' }}>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Cód</th>
                  <th>Produto</th>
                  <th>Qtd</th>
                  <th>Custo Entrada (Unit)</th>
                  <th>Custo Mercadoria (Fiscal)</th>
                  <th>Custo Operacional</th>
                  <th>Total Item</th>
                  <th>Ações</th>
                </tr>
              </thead>
              <tbody>
                {purchaseForm.itens.length === 0 ? (
                  <tr>
                    <td colSpan="8" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
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
                                  setProdForm({
                                    nome: item.produto_nome,
                                    fabricante: '',
                                    codbarra: item.codbarra || '',
                                    valorv: item.valor_unitario * 1.5,
                                    targetItemIndex: idx
                                  });
                                  setActiveModal('produto');
                                }}
                                style={{ fontSize: '0.8rem', color: '#f59e0b', display: 'inline-flex', alignItems: 'center', gap: '4px' }}
                              >
                                <Plus size={12} /> Cadastrar produto no Modal
                              </button>
                            </div>
                          )}
                        </td>
                        <td><strong>{item.quantidade}</strong></td>
                        <td>{formatCurrency(item.valor_unitario)}</td>
                        <td><span className="badge badge-info">{formatCurrency(custoMercadoria)}</span></td>
                        <td>{formatCurrency(custoOperacional)}</td>
                        <td><strong>{formatCurrency(totalItem)}</strong></td>
                        <td>
                          <button className="crud-row-btn delete" onClick={() => handleRemoveItem(idx)}><Trash2 size={14} /></button>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>

          {/* RODAPÉ DO FORMULÁRIO */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid var(--border-color)', paddingTop: '1rem', flexWrap: 'wrap', gap: '1rem' }}>
            <div>
              <span style={{ fontSize: '0.9rem', color: 'var(--text-muted)' }}>Total da Nota / Compra:</span>
              <h2 style={{ margin: 0, color: 'var(--accent-primary)', fontWeight: 800 }}>{formatCurrency(calcularTotalForm())}</h2>
            </div>

            <div style={{ display: 'flex', gap: '0.8rem' }}>
              <button className="btn-secondary" onClick={() => setShowPurchaseForm(false)}>Cancelar</button>
              <button className="btn-primary" onClick={handleSavePurchase} disabled={loading} style={{ padding: '0.7rem 1.5rem', fontWeight: 600 }}>
                <Save size={16} /> Finalizar & Atualizar Custos
              </button>
            </div>
          </div>
        </div>
      ) : (
        /* GERENCIAMENTO DE COMPRAS (IGUAL AO SCREENSHOT 1 "Gerenciamento de GRUPOS") */
        <div className="glass" style={{ padding: '1.5rem', borderRadius: '1.25rem', display: 'flex', flexDirection: 'column', gap: '1.2rem' }}>
          <div className="crud-title-row">
            <h3 style={{ margin: 0, fontSize: '1.3rem', fontWeight: 700, color: 'var(--text-primary)' }}>
              Gerenciamento de COMPRAS
            </h3>

            <div style={{ display: 'flex', gap: '0.6rem', flexWrap: 'wrap', alignItems: 'center' }}>
              <button className="crud-tab-btn" onClick={() => fetchCompras(1)} style={{ border: '1px solid rgba(0,0,0,0.1)', background: '#fff' }}>
                <RefreshCw size={16} /> Atualizar
              </button>

              <label className="crud-tab-btn" style={{ cursor: 'pointer', border: '1px solid rgba(0,0,0,0.1)', background: '#fff', margin: 0 }}>
                <Upload size={16} /> Importar XML (NFe)
                <input type="file" accept=".xml" onChange={handleFileUpload} style={{ display: 'none' }} />
              </label>

              <button className="crud-add-btn" onClick={handleOpenNewPurchase}>
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
                  <th>Código Compra</th>
                  <th>NF-e</th>
                  <th>Fornecedor</th>
                  <th>Data Entrada</th>
                  <th>Valor Total</th>
                  <th>Ações</th>
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
                      <td><strong style={{ color: 'var(--accent-primary)' }}>{formatCurrency(compra.valor_total)}</strong></td>
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

      {/* --- OS 6 MODAIS POPUP DE CADASTRO --- */}

      {/* 1. MODAL CADASTRO PRODUTO */}
      {activeModal === 'produto' && createPortal(
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setActiveModal(null); }}>
          <div className="modal-content glass" style={{ maxWidth: '520px' }}>
            <div className="modal-header">
              <h4><PackagePlus size={20} style={{ color: '#34d399' }} /> Popup Cadastro de Produto</h4>
              <button className="btn-close" onClick={() => setActiveModal(null)}><X size={18} /></button>
            </div>
            <form onSubmit={handleSaveProductModal}>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem', padding: '1rem 0' }}>
                <div className="form-group">
                  <label>Nome do Produto *</label>
                  <input type="text" required value={prodForm.nome} onChange={(e) => setProdForm(prev => ({ ...prev, nome: e.target.value }))} placeholder="Ex: Camiseta Algodão" />
                </div>
                <div className="form-group">
                  <label>Fabricante / Marca</label>
                  <input type="text" value={prodForm.fabricante} onChange={(e) => setProdForm(prev => ({ ...prev, fabricante: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>Código de Barras (EAN)</label>
                  <input type="text" value={prodForm.codbarra} onChange={(e) => setProdForm(prev => ({ ...prev, codbarra: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>NCM (Classificação Fiscal) *</label>
                  <input type="text" required value={prodForm.ncm || '6109.10.00'} onChange={(e) => setProdForm(prev => ({ ...prev, ncm: e.target.value }))} placeholder="Ex: 6109.10.00" />
                </div>
                <div className="form-group">
                  <label>Unidade de Medida (UM) *</label>
                  <select value={prodForm.um || 'UN'} onChange={(e) => setProdForm(prev => ({ ...prev, um: e.target.value }))}>
                    <option value="UN">UN - Unidade</option>
                    <option value="PC">PC - Peça</option>
                    <option value="KG">KG - Quilograma</option>
                    <option value="PAR">PAR - Par</option>
                    <option value="CX">CX - Caixa</option>
                    <option value="MT">MT - Metro</option>
                    <option value="L">L - Litro</option>
                  </select>
                </div>
                <div className="form-group">
                  <label>Totalizador Fiscal (ICMS/ISS) *</label>
                  <select value={prodForm.codTotalizador || 1} onChange={(e) => setProdForm(prev => ({ ...prev, codTotalizador: Number(e.target.value) }))}>
                    <option value={1}>#1 - 01T1700 (Tributado ICMS 17%)</option>
                    <option value={2}>#2 - 02T1200 (Tributado ICMS 12%)</option>
                    <option value={3}>#3 - 03T2500 (Tributado ICMS 25%)</option>
                    <option value={4}>#4 - F1 (Substituição Tributária)</option>
                    <option value={5}>#5 - I1 (Isento / Não Tributado)</option>
                    <option value={6}>#6 - N1 (Não Incidência)</option>
                  </select>
                </div>
                <div className="form-group">
                  <label>Preço Venda Sugerido (R$)</label>
                  <input type="number" step="0.01" value={prodForm.valorv} onChange={(e) => setProdForm(prev => ({ ...prev, valorv: parseFloat(e.target.value) || 0 }))} />
                </div>
              </div>
              <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.6rem', marginTop: '1rem' }}>
                <button type="button" className="btn-secondary" onClick={() => setActiveModal(null)}>Cancelar</button>
                <button type="submit" className="btn-primary" disabled={loading}>Salvar Produto</button>
              </div>
            </form>
          </div>
        </div>,
        document.body
      )}

      {/* 2. MODAL CADASTRO FORNECEDOR */}
      {activeModal === 'fornecedor' && createPortal(
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setActiveModal(null); }}>
          <div className="modal-content glass" style={{ maxWidth: '520px' }}>
            <div className="modal-header">
              <h4><UserPlus size={20} style={{ color: '#38bdf8' }} /> Popup Cadastro de Fornecedor</h4>
              <button className="btn-close" onClick={() => setActiveModal(null)}><X size={18} /></button>
            </div>
            <form onSubmit={handleSaveFornecedorModal}>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem', padding: '1rem 0' }}>
                <div className="form-group">
                  <label>Razão Social / Nome *</label>
                  <input type="text" required value={fornForm.nome} onChange={(e) => setFornForm(prev => ({ ...prev, nome: e.target.value }))} placeholder="Ex: Tecidos Indústria S.A." />
                </div>
                <div className="form-group">
                  <label>Nome Fantasia</label>
                  <input type="text" value={fornForm.fantasia} onChange={(e) => setFornForm(prev => ({ ...prev, fantasia: e.target.value }))} />
                </div>
                <div className="form-group">
                  <label>CNPJ / CPF</label>
                  <input type="text" value={fornForm.cnpj} onChange={(e) => setFornForm(prev => ({ ...prev, cnpj: e.target.value }))} placeholder="00.000.000/0001-00" />
                </div>
                <div className="form-group">
                  <label>Endereço</label>
                  <input type="text" value={fornForm.endereco} onChange={(e) => setFornForm(prev => ({ ...prev, endereco: e.target.value }))} />
                </div>
              </div>
              <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.6rem', marginTop: '1rem' }}>
                <button type="button" className="btn-secondary" onClick={() => setActiveModal(null)}>Cancelar</button>
                <button type="submit" className="btn-primary" disabled={loading}>Salvar Fornecedor</button>
              </div>
            </form>
          </div>
        </div>,
        document.body
      )}

      {/* 3. MODAL CADASTRO GRUPO */}
      {activeModal === 'grupo' && createPortal(
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setActiveModal(null); }}>
          <div className="modal-content glass" style={{ maxWidth: '450px' }}>
            <div className="modal-header">
              <h4><FolderPlus size={20} style={{ color: '#60a5fa' }} /> Popup Cadastro de Grupo</h4>
              <button className="btn-close" onClick={() => setActiveModal(null)}><X size={18} /></button>
            </div>
            <form onSubmit={handleSaveGrupoModal}>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem', padding: '1rem 0' }}>
                <div className="form-group">
                  <label>Nome do Grupo *</label>
                  <input type="text" required value={grupoForm.nome} onChange={(e) => setGrupoForm({ nome: e.target.value })} placeholder="Ex: Vestuário Masculino" />
                </div>
              </div>
              <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.6rem', marginTop: '1rem' }}>
                <button type="button" className="btn-secondary" onClick={() => setActiveModal(null)}>Cancelar</button>
                <button type="submit" className="btn-primary" disabled={loading}>Salvar Grupo</button>
              </div>
            </form>
          </div>
        </div>,
        document.body
      )}

      {/* 4. MODAL CADASTRO SUBGRUPO */}
      {activeModal === 'subgrupo' && createPortal(
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setActiveModal(null); }}>
          <div className="modal-content glass" style={{ maxWidth: '480px' }}>
            <div className="modal-header">
              <h4><Layers size={20} style={{ color: '#c084fc' }} /> Popup Cadastro de Subgrupo</h4>
              <button className="btn-close" onClick={() => setActiveModal(null)}><X size={18} /></button>
            </div>
            <form onSubmit={handleSaveSubgrupoModal}>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem', padding: '1rem 0' }}>
                <div className="form-group">
                  <label>Nome do Subgrupo *</label>
                  <input type="text" required value={subgrupoForm.nome} onChange={(e) => setSubgrupoForm(prev => ({ ...prev, nome: e.target.value }))} placeholder="Ex: Camisetas" />
                </div>
                <div className="form-group">
                  <label>Grupo Relacionado</label>
                  <select value={subgrupoForm.g1} onChange={(e) => setSubgrupoForm(prev => ({ ...prev, g1: e.target.value }))}>
                    <option value="">Selecione o Grupo Pai...</option>
                    {grupos.map(g => (
                      <option key={g.codigo} value={g.codigo}>#{g.codigo} - {g.nome}</option>
                    ))}
                  </select>
                </div>
              </div>
              <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.6rem', marginTop: '1rem' }}>
                <button type="button" className="btn-secondary" onClick={() => setActiveModal(null)}>Cancelar</button>
                <button type="submit" className="btn-primary" disabled={loading}>Salvar Subgrupo</button>
              </div>
            </form>
          </div>
        </div>,
        document.body
      )}

      {/* 5. MODAL CADASTRO GRADE */}
      {activeModal === 'grade' && createPortal(
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setActiveModal(null); }}>
          <div className="modal-content glass" style={{ maxWidth: '500px' }}>
            <div className="modal-header">
              <h4><Grid size={20} style={{ color: '#f472b6' }} /> Popup Cadastro de Grade</h4>
              <button className="btn-close" onClick={() => setActiveModal(null)}><X size={18} /></button>
            </div>
            <form onSubmit={handleSaveGradeModal}>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem', padding: '1rem 0' }}>
                <div className="form-group">
                  <label>Produto *</label>
                  <select required value={gradeForm.pro} onChange={(e) => setGradeForm(prev => ({ ...prev, pro: e.target.value }))}>
                    <option value="">Selecione o Produto...</option>
                    {produtos.map(p => (
                      <option key={p.codigo} value={p.codigo}>#{p.codigo} - {p.nome}</option>
                    ))}
                  </select>
                </div>
                <div className="form-group">
                  <label>Tamanho *</label>
                  <select required value={gradeForm.tam} onChange={(e) => setGradeForm(prev => ({ ...prev, tam: e.target.value }))}>
                    <option value="">Selecione o Tamanho...</option>
                    {tamanhos.map(t => (
                      <option key={t.codigo} value={t.codigo}>#{t.codigo} - {t.tamanho} ({t.sigla})</option>
                    ))}
                  </select>
                </div>
                <div className="form-group">
                  <label>Cor</label>
                  <input type="text" value={gradeForm.cor} onChange={(e) => setGradeForm(prev => ({ ...prev, cor: e.target.value }))} placeholder="Ex: Azul Marinho" />
                </div>
                <div className="form-group">
                  <label>Código de Barras EAN</label>
                  <input type="text" value={gradeForm.codbarra} onChange={(e) => setGradeForm(prev => ({ ...prev, codbarra: e.target.value }))} />
                </div>
              </div>
              <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.6rem', marginTop: '1rem' }}>
                <button type="button" className="btn-secondary" onClick={() => setActiveModal(null)}>Cancelar</button>
                <button type="submit" className="btn-primary" disabled={loading}>Salvar Grade</button>
              </div>
            </form>
          </div>
        </div>,
        document.body
      )}

      {/* 6. MODAL CADASTRO TAMANHO */}
      {activeModal === 'tamanho' && createPortal(
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setActiveModal(null); }}>
          <div className="modal-content glass" style={{ maxWidth: '450px' }}>
            <div className="modal-header">
              <h4><Ruler size={20} style={{ color: '#fbbf24' }} /> Popup Cadastro de Tamanho</h4>
              <button className="btn-close" onClick={() => setActiveModal(null)}><X size={18} /></button>
            </div>
            <form onSubmit={handleSaveTamanhoModal}>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem', padding: '1rem 0' }}>
                <div className="form-group">
                  <label>Descrição do Tamanho *</label>
                  <input type="text" required value={tamanhoForm.tamanho} onChange={(e) => setTamanhoForm(prev => ({ ...prev, tamanho: e.target.value }))} placeholder="Ex: Grande / 42" />
                </div>
                <div className="form-group">
                  <label>Sigla *</label>
                  <input type="text" required value={tamanhoForm.sigla} onChange={(e) => setTamanhoForm(prev => ({ ...prev, sigla: e.target.value }))} placeholder="Ex: G, GG, 42" />
                </div>
                <div className="form-group">
                  <label>Valor / Adicional</label>
                  <input type="number" step="0.01" value={tamanhoForm.valor} onChange={(e) => setTamanhoForm(prev => ({ ...prev, valor: parseFloat(e.target.value) || 0 }))} />
                </div>
              </div>
              <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.6rem', marginTop: '1rem' }}>
                <button type="button" className="btn-secondary" onClick={() => setActiveModal(null)}>Cancelar</button>
                <button type="submit" className="btn-primary" disabled={loading}>Salvar Tamanho</button>
              </div>
            </form>
          </div>
        </div>,
        document.body
      )}

      {/* MODAL DETALHES DA COMPRA */}
      {showDetailModal && createPortal(
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setShowDetailModal(null); }}>
          <div className="modal-content glass" style={{ maxWidth: '750px' }}>
            <div className="modal-header">
              <h4><FileText size={20} style={{ color: 'var(--accent-primary)' }} /> Detalhes da Compra #${showDetailModal.id} - NF {showDetailModal.numero_nf || 'S/N'}</h4>
              <button className="btn-close" onClick={() => setShowDetailModal(null)}><X size={18} /></button>
            </div>
            <div className="modal-body" style={{ padding: '1rem 0' }}>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem', marginBottom: '1rem' }}>
                <div><strong>Fornecedor:</strong> {showDetailModal.fornecedor_nome}</div>
                <div><strong>Valor Total:</strong> {formatCurrency(showDetailModal.valor_total)}</div>
                <div><strong>Data Emissão:</strong> {showDetailModal.data_emissao}</div>
                <div><strong>Data Entrada:</strong> {showDetailModal.data_entrada}</div>
              </div>
              {showDetailModal.chave_nfe && <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}><strong>Chave NFe:</strong> {showDetailModal.chave_nfe}</p>}

              <h5 style={{ marginTop: '1.5rem', marginBottom: '0.8rem' }}>Itens da Compra & Custos Atualizados no Banco</h5>
              <div className="table-responsive">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Cód</th>
                      <th>Produto</th>
                      <th>Qtd</th>
                      <th>Custo Entrada</th>
                      <th>Custo Mercadoria</th>
                      <th>Custo Médio</th>
                      <th>Custo Operacional</th>
                    </tr>
                  </thead>
                  <tbody>
                    {(showDetailModal.itens || []).map((it, idx) => (
                      <tr key={idx}>
                        <td>#{it.produto_codigo}</td>
                        <td>{it.produto_nome}</td>
                        <td>{it.quantidade}</td>
                        <td>{formatCurrency(it.valor_unitario)}</td>
                        <td><span className="badge badge-info">{formatCurrency(it.custo_mercadoria)}</span></td>
                        <td><strong>{formatCurrency(it.custo_medio)}</strong></td>
                        <td>{formatCurrency(it.custo_operacional)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
            <div className="modal-footer" style={{ textAlign: 'right', marginTop: '1rem' }}>
              <button className="btn-secondary" onClick={() => setShowDetailModal(null)}>Fechar</button>
            </div>
          </div>
        </div>,
        document.body
      )}

    </div>
  );
}
