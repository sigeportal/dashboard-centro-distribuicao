import { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Package, Folder, Layers, Ruler, Plus, Edit, Trash2, Save, X, RefreshCw, Grid, AlertCircle, History, Search, FileCheck2, UserPlus, Users, Tag } from 'lucide-react';
import { createApi } from '../../services/api';
import { formatCurrency, formatDatehora } from '../../utils/formatters';
import Pagination from '../Pagination';
import SearchBar from '../SearchBar';
import ProductFormModal from '../ProductFormModal';
import GruposSubgruposModal from '../GruposSubgruposModal';
import GradesModal from '../GradesModal';
import ConciliacaoFiscalModal from '../ConciliacaoFiscalModal';
import './CadastrosTab.css';

export default function CadastrosTab() {
  const api = createApi(true); // Conecta na CD_API_BASE (port 9000)
  const [activeSubTab, setActiveSubTab] = useState('grupos'); // 'grupos', 'subgrupos', 'modelos', 'grades', 'tamanhos', 'produtos', 'fornecedores'
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [page, setPage] = useState(1);
  const [meta, setMeta] = useState({ page: 1, limit: 10, total: 0, pages: 1 });
  const [searchTerm, setSearchTerm] = useState('');
  const [gradeProductFilter, setGradeProductFilter] = useState('');

  // Modal de Conciliação Fiscal de Produtos (Madenorte / PDV)
  const [showConciliacaoModal, setShowConciliacaoModal] = useState(false);

  // Histórico de Movimentações (HIS_PRO)
  const [selectedHistoryProduct, setSelectedHistoryProduct] = useState(null);
  const [historyData, setHistoryData] = useState([]);
  const [loadingHistory, setLoadingHistory] = useState(false);

  // Modal de Gerenciamento de Grades por Produto
  const [selectedProductGrades, setSelectedProductGrades] = useState(null);
  const [productGradesList, setProductGradesList] = useState([]);
  const [loadingProductGrades, setLoadingProductGrades] = useState(false);
  const [showProductGradeForm, setShowProductGradeForm] = useState(false);
  const [editingProductGrade, setEditingProductGrade] = useState(null);
  const [productGradeForm, setProductGradeForm] = useState({
    codigo: '',
    pro: '',
    tam: '',
    cor: '',
    quantidade: '',
    valor: '',
    valor_dinheiro: '',
    valor_prazo: '',
    codbarra: ''
  });

  // Novos Modais de Cadastro Legados (Pop-ups)
  const [showProductModal, setShowProductModal] = useState(false);
  const [productToEditModal, setProductToEditModal] = useState(null);
  const [showGruposSubgruposModal, setShowGruposSubgruposModal] = useState(false);
  const [showGradesModal, setShowGradesModal] = useState(false);
  const [productForGrades, setProductForGrades] = useState(null);

  // Saldo de Estoque Consolidado (Soma de Todas as Filiais)
  const [consolidatedStocks, setConsolidatedStocks] = useState({});
  const [activeUnitStocks, setActiveUnitStocks] = useState({});
  const activeUnitId = Number(localStorage.getItem('selected_company_id')) || 1;
  const activeUnitName = localStorage.getItem('selected_company_name') || (activeUnitId === 1 ? 'CD DOURADINA' : `Unidade #${activeUnitId}`);
  const isMatriz = activeUnitId === 1 || activeUnitName.toUpperCase().includes('CD') || activeUnitName.toUpperCase().includes('DOURADINA');

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
      console.warn('Erro ao buscar saldos de estoque no cadastro:', err);
    }
  };

  useEffect(() => {
    fetchStocks();
  }, [activeUnitId]);

  const getProductStockForActiveUnit = (item) => {
    const prodId = Number(item.codigo || item.id || item.pro_codigo);
    if (prodId && consolidatedStocks[prodId] !== undefined) {
      return consolidatedStocks[prodId];
    }
    return Number(item.quantidade || item.pro_quantidade || item.PRO_QUANTIDADE) || 0;
  };

  // Listas de Dados
  const [produtos, setProdutos] = useState([]);
  const [grupos, setGrupos] = useState([]);
  const [subgrupos, setSubgrupos] = useState([]);
  const [modelos, setModelos] = useState([]);
  const [grades, setGrades] = useState([]);
  const [tamanhos, setTamanhos] = useState([]);
  const [totalizadores, setTotalizadores] = useState([]);
  const [fornecedores, setFornecedores] = useState([]);
  const [cidades, setCidades] = useState([]);
  const [estados, setEstados] = useState([]);

  // Estados de Formulário
  const [editingItem, setEditingItem] = useState(null);
  const [showForm, setShowForm] = useState(false);

  // Campos de Formulário
  const [prodForm, setProdForm] = useState({ 
    codigo: '', 
    nome: '', 
    fabricante: '', 
    pro_for: 0,
    pro_gru: 0,
    codbarra: '', 
    quantidade: 0, 
    valorv: 0,
    pro_valor_dinheiro: 0,
    pro_valorv_prazo: 0,
    codTotalizador: 1, 
    ncm: '6109.10.00', 
    um: 'UN', 
    cadastrar: 'S', 
    url_Imagem: '', 
    distribute: true 
  });
  const [grupoForm, setGrupoForm] = useState({ codigo: '', nome: '' });
  const [subgrupoForm, setSubgrupoForm] = useState({ codigo: '', nome: '', g1: '', tr: '0' });
  const [modeloForm, setModeloForm] = useState({ codigo: '', nome: '' });
  const [gradeForm, setGradeForm] = useState({ codigo: '', pro: '', valor: '', valor_dinheiro: '', valor_prazo: '', tam: '', quantidade: '', codbarra: '', cor: '' });
  const [tamanhoForm, setTamanhoForm] = useState({ codigo: '', pro: '', tamanho: '', sigla: '', valor: '' });
  const [fornForm, setFornForm] = useState({ 
    codigo: '', 
    nome: '', 
    fantasia: '', 
    cnpj: '', 
    inscricao: '', 
    telefone: '', 
    email: '', 
    endereco: '', 
    bairro: '', 
    for_cid: '',
    cidade: '', 
    uf: 'PR', 
    contato: '' 
  });

  // Função utilitária de Máscara de CNPJ / CPF
  const maskCnpjCpf = (value) => {
    if (!value) return '';
    const digits = value.replace(/\D/g, '').slice(0, 14);
    if (digits.length <= 11) {
      return digits
        .replace(/(\d{3})(\d)/, '$1.$2')
        .replace(/(\d{3})(\d)/, '$1.$2')
        .replace(/(\d{3})(\d{1,2})$/, '$1-$2');
    }
    return digits
      .replace(/^(\d{2})(\d)/, '$1.$2')
      .replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3')
      .replace(/\.(\d{3})(\d)/, '.$1/$2')
      .replace(/(\d{4})(\d)/, '$1-$2');
  };

  const fetchLookups = async () => {
    try {
      const [gRes, sgRes, mRes, fRes, cRes, eRes] = await Promise.all([
        api.get('/v1/grupos?limit=500').catch(() => ({ data: [] })),
        api.get('/v1/subgrupos?limit=500').catch(() => ({ data: [] })),
        api.get('/v1/modelos').catch(() => ({ data: [] })),
        api.get('/v1/fornecedores?limit=500').catch(() => ({ data: [] })),
        api.get('/v1/cidades?limit=300').catch(() => ({ data: [] })),
        api.get('/v1/estados').catch(() => ({ data: [] }))
      ]);

      const gItems = Array.isArray(gRes.data) ? gRes.data : (gRes.data?.data || []);
      const sgItems = Array.isArray(sgRes.data) ? sgRes.data : (sgRes.data?.data || []);
      const mItems = Array.isArray(mRes.data) ? mRes.data : (mRes.data?.data || []);
      const fItems = Array.isArray(fRes.data) ? fRes.data : (fRes.data?.data || []);
      const cItems = Array.isArray(cRes.data) ? cRes.data : (cRes.data?.data || []);
      const eItems = Array.isArray(eRes.data) ? eRes.data : (eRes.data?.data || []);

      if (gItems.length > 0) setGrupos(gItems);
      if (sgItems.length > 0) setSubgrupos(sgItems);
      if (mItems.length > 0) setModelos(mItems);
      if (fItems.length > 0) setFornecedores(fItems);
      if (cItems.length > 0) setCidades(cItems);
      if (eItems.length > 0) setEstados(eItems);
    } catch (e) {
      console.warn('Erro ao carregar dados auxiliares de cadastros:', e);
    }
  };

  useEffect(() => {
    fetchLookups();
  }, []);

  useEffect(() => {
    const loadTotalizadores = async () => {
      try {
        const res = await api.get('/v1/totalizadores');
        if (Array.isArray(res.data) && res.data.length > 0) {
          setTotalizadores(res.data);
        } else {
          setTotalizadores([
            { codigo: 1, totalizador: '01T1700', descricao: 'T - Tributado ICMS 17%' },
            { codigo: 2, totalizador: '02T1200', descricao: 'T - Tributado ICMS 12%' },
            { codigo: 3, totalizador: '03T2500', descricao: 'T - Tributado ICMS 25%' },
            { codigo: 4, totalizador: 'F1', descricao: 'F - Substituição Tributária' },
            { codigo: 5, totalizador: 'I1', descricao: 'I - Isento / Não Tributado' },
            { codigo: 6, totalizador: 'N1', descricao: 'N - Não Incidência' }
          ]);
        }
      } catch (err) {
        setTotalizadores([
          { codigo: 1, totalizador: '01T1700', descricao: 'T - Tributado ICMS 17%' },
          { codigo: 2, totalizador: '02T1200', descricao: 'T - Tributado ICMS 12%' },
          { codigo: 3, totalizador: '03T2500', descricao: 'T - Tributado ICMS 25%' },
          { codigo: 4, totalizador: 'F1', descricao: 'F - Substituição Tributária' },
          { codigo: 5, totalizador: 'I1', descricao: 'I - Isento / Não Tributado' },
          { codigo: 6, totalizador: 'N1', descricao: 'N - Não Incidência' }
        ]);
      }
    };
    loadTotalizadores();
  }, []);

  useEffect(() => {
    setSearchTerm('');
    fetchData('last', '');
  }, [activeSubTab]);

  const fetchData = async (targetPage = 'last', search = searchTerm) => {
    setLoading(true);
    setError('');
    try {
      let pageToFetch = targetPage === 'last' ? 1 : targetPage;
      const searchParam = search ? `&search=${encodeURIComponent(search)}` : '';
      let url = `/v1/${activeSubTab}?page=${pageToFetch}&limit=10${searchParam}`;
      let res = await api.get(url);

      let items = [];
      let metaData = { page: pageToFetch, limit: 10, total: 0, pages: 1 };

      if (Array.isArray(res.data)) {
        items = res.data;
        metaData = { page: 1, limit: items.length || 10, total: items.length, pages: 1 };
      } else if (res.data && Array.isArray(res.data.data)) {
        items = res.data.data;
        metaData = res.data.meta || metaData;
      }

      if (targetPage === 'last' && metaData.pages > 1) {
        pageToFetch = metaData.pages;
        url = `/v1/${activeSubTab}?page=${pageToFetch}&limit=10${searchParam}`;
        res = await api.get(url);
        if (Array.isArray(res.data)) {
          items = res.data;
          metaData = { page: 1, limit: items.length || 10, total: items.length, pages: 1 };
        } else if (res.data && Array.isArray(res.data.data)) {
          items = res.data.data;
          metaData = res.data.meta || metaData;
        }
      }

      if (activeSubTab === 'produtos') {
        setProdutos(items);
      } else if (activeSubTab === 'grupos') {
        setGrupos(items);
      } else if (activeSubTab === 'subgrupos') {
        setSubgrupos(items);
      } else if (activeSubTab === 'modelos') {
        setModelos(items);
      } else if (activeSubTab === 'grades') {
        setGrades(items);
        const [pRes, tRes] = await Promise.all([api.get('/v1/produtos?limit=100'), api.get('/v1/tamanhos?limit=100')]);
        if (Array.isArray(pRes.data)) setProdutos(pRes.data);
        else if (pRes.data?.data) setProdutos(pRes.data.data);
        if (Array.isArray(tRes.data)) setTamanhos(tRes.data);
        else if (tRes.data?.data) setTamanhos(tRes.data.data);
      } else if (activeSubTab === 'tamanhos') {
        setTamanhos(items);
      } else if (activeSubTab === 'fornecedores') {
        setFornecedores(items);
      }

      setMeta(metaData);
      setPage(metaData.page || pageToFetch);
    } catch (err) {
      console.error(err);
      setError('Erro ao carregar dados do servidor central.');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenCreate = () => {
    if (activeSubTab === 'produtos') {
      setProductToEditModal(null);
      setShowProductModal(true);
      return;
    }
    if (activeSubTab === 'grupos' || activeSubTab === 'subgrupos') {
      setShowGruposSubgruposModal(true);
      return;
    }
    if (activeSubTab === 'grades') {
      setProductForGrades(produtos[0] || null);
      setShowGradesModal(true);
      return;
    }
    if (activeSubTab === 'modelos') {
      setModeloForm({ codigo: '', nome: '' });
    }
    if (activeSubTab === 'tamanhos') {
      setTamanhoForm({ codigo: '', pro: '', tamanho: '', sigla: '', valor: '' });
    }
    if (activeSubTab === 'fornecedores') {
      setFornForm({ codigo: '', nome: '', fantasia: '', cnpj: '', inscricao: '', telefone: '', email: '', endereco: '', bairro: '', for_cid: '', cidade: '', uf: 'PR', contato: '' });
    }
    setEditingItem(null);
    setShowForm(true);
  };

  const handleOpenEdit = (item) => {
    if (activeSubTab === 'produtos') {
      setProductToEditModal(item);
      setShowProductModal(true);
      return;
    }
    if (activeSubTab === 'grupos' || activeSubTab === 'subgrupos') {
      setShowGruposSubgruposModal(true);
      return;
    }
    if (activeSubTab === 'grades') {
      const prod = produtos.find(p => Number(p.codigo) === Number(item.pro));
      setProductForGrades(prod || { codigo: item.pro, nome: `Produto #${item.pro}` });
      setShowGradesModal(true);
      return;
    }
    if (activeSubTab === 'modelos') {
      setModeloForm({
        codigo: item.codigo,
        nome: item.nome || ''
      });
    }
    if (activeSubTab === 'tamanhos') {
      setTamanhoForm({
        codigo: item.codigo,
        pro: item.pro || '',
        tamanho: item.tamanho || '',
        sigla: item.sigla || '',
        valor: item.valor || ''
      });
    }
    if (activeSubTab === 'fornecedores') {
      let cidNome = '';
      let cidCod = item.for_cid || item.cid || '';
      if (item.cidade) {
        if (typeof item.cidade === 'object') {
          cidNome = item.cidade.nome || item.cidade.descricao || '';
          cidCod = item.cidade.codigo || cidCod;
        } else {
          cidNome = String(item.cidade);
        }
      }

      let ufSigla = 'PR';
      if (item.uf) {
        if (typeof item.uf === 'object') {
          ufSigla = item.uf.sigla || item.uf.uf || 'PR';
        } else {
          ufSigla = String(item.uf);
        }
      } else if (item.cidade && typeof item.cidade === 'object' && item.cidade.uf) {
        ufSigla = item.cidade.uf;
      }

      setFornForm({
        codigo: item.codigo,
        nome: typeof item.nome === 'string' ? item.nome : (item.razao_social || ''),
        fantasia: typeof item.fantasia === 'string' ? item.fantasia : (item.nome_fantasia || ''),
        cnpj: maskCnpjCpf(item.cnpj || item.cnpj_cpf || item.cpf_cnpj || ''),
        inscricao: item.inscricao || item.insc_estadual || item.ie || '',
        telefone: item.telefone || item.fone || item.celular || '',
        email: typeof item.email === 'string' ? item.email : '',
        endereco: typeof item.endereco === 'string' ? item.endereco : '',
        bairro: typeof item.bairro === 'string' ? item.bairro : '',
        for_cid: cidCod,
        cidade: cidNome,
        uf: ufSigla,
        contato: typeof item.contato === 'string' ? item.contato : ''
      });
    }
    setEditingItem(item);
    setShowForm(true);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Tem certeza que deseja remover este item?')) return;
    setLoading(true);
    try {
      if (activeSubTab === 'produtos') {
        await api.delete(`/v1/produtos/${id}`);
      } else if (activeSubTab === 'grupos') {
        await api.delete(`/v1/grupos/${id}`);
      } else if (activeSubTab === 'subgrupos') {
        await api.delete(`/v1/subgrupos/${id}`);
      } else if (activeSubTab === 'modelos') {
        await api.delete(`/v1/modelos/${id}`);
      } else if (activeSubTab === 'grades') {
        await api.delete(`/v1/grades/${id}`);
      } else if (activeSubTab === 'tamanhos') {
        await api.delete(`/v1/tamanhos/${id}`);
      } else if (activeSubTab === 'fornecedores') {
        await api.delete(`/v1/fornecedores/${id}`);
      }
      alert('Removido com sucesso!');
      fetchData();
    } catch (err) {
      alert('Erro ao excluir item.');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      if (activeSubTab === 'produtos') {
        const productCode = editingItem ? Number(prodForm.codigo) : 0;
        const vDin = Number(prodForm.pro_valor_dinheiro) || Number(prodForm.valorv) || 0;
        const vPrz = Number(prodForm.pro_valorv_prazo) || Number(prodForm.valorv) || 0;
        const payload = {
          codigo: productCode,
          nome: (prodForm.nome || '').toUpperCase(),
          fabricante: (prodForm.fabricante || '').toUpperCase(),
          pro_for: Number(prodForm.pro_for) || 0,
          forCodigo: Number(prodForm.pro_for) || 0,
          fornecedorId: Number(prodForm.pro_for) || 0,
          pro_gru: Number(prodForm.pro_gru) || 0,
          gru: Number(prodForm.pro_gru) || 0,
          subgrupoId: Number(prodForm.pro_gru) || 0,
          codbarra: prodForm.codbarra,
          quantidade: Number(prodForm.quantidade) || 0,
          valorv: Number(prodForm.valorv) || 0,
          pro_valor_dinheiro: vDin,
          valor_dinheiro: vDin,
          pro_valorv_prazo: vPrz,
          valor_prazo: vPrz,
          codTotalizador: Number(prodForm.codTotalizador) || 1,
          ncm: prodForm.ncm || '6109.10.00',
          um: prodForm.um || 'UN',
          embalagem: prodForm.um || 'UN',
          cadastrar: 'S',
          url_Imagem: prodForm.url_Imagem || ''
        };
        if (editingItem) {
          await api.put('/v1/produtos', payload);
        } else {
          await api.post('/v1/produtos', payload);
        }
      } else if (activeSubTab === 'grupos') {
        const payload = {
          codigo: editingItem ? Number(grupoForm.codigo) : 0,
          nome: (grupoForm.nome || '').toUpperCase()
        };
        if (editingItem) {
          await api.put('/v1/grupos', payload);
        } else {
          await api.post('/v1/grupos', payload);
        }
      } else if (activeSubTab === 'subgrupos') {
        const payload = {
          codigo: editingItem ? Number(subgrupoForm.codigo) : 0,
          nome: (subgrupoForm.nome || '').toUpperCase(),
          g1: Number(subgrupoForm.g1) || 0,
          gru_g1: Number(subgrupoForm.g1) || 0,
          tr: Number(subgrupoForm.tr) || 0
        };
        if (editingItem) {
          await api.put('/v1/subgrupos', payload);
        } else {
          await api.post('/v1/subgrupos', payload);
        }
      } else if (activeSubTab === 'modelos') {
        const payload = {
          codigo: editingItem ? Number(modeloForm.codigo) : 0,
          nome: (modeloForm.nome || '').toUpperCase()
        };
        if (editingItem) {
          await api.put('/v1/modelos', payload);
        } else {
          await api.post('/v1/modelos', payload);
        }
      } else if (activeSubTab === 'grades') {
        const gDin = Number(gradeForm.valor_dinheiro) || Number(gradeForm.valor) || 0;
        const gPrz = Number(gradeForm.valor_prazo) || Number(gradeForm.valor) || 0;
        const payload = {
          codigo: editingItem ? Number(gradeForm.codigo) : 0,
          pro: Number(gradeForm.pro),
          valor: Number(gradeForm.valor) || 0,
          valor_dinheiro: gDin,
          valor_prazo: gPrz,
          tam: Number(gradeForm.tam),
          quantidade: Number(gradeForm.quantidade) || 0,
          codbarra: gradeForm.codbarra,
          cor: (gradeForm.cor || 'UNICA').toUpperCase()
        };
        if (editingItem) {
          await api.put('/v1/grades', payload);
        } else {
          await api.post('/v1/grades', payload);
        }
      } else if (activeSubTab === 'tamanhos') {
        const payload = {
          codigo: editingItem ? Number(tamanhoForm.codigo) : 0,
          pro: Number(tamanhoForm.pro) || 0,
          tamanho: (tamanhoForm.tamanho || '').toUpperCase(),
          sigla: (tamanhoForm.sigla || '').toUpperCase(),
          valor: Number(tamanhoForm.valor) || 0
        };
        if (editingItem) {
          await api.put('/v1/tamanhos', payload);
        } else {
          await api.post('/v1/tamanhos', payload);
        }
      } else if (activeSubTab === 'fornecedores') {
        const payload = {
          codigo: editingItem ? Number(fornForm.codigo) : 0,
          nome: (fornForm.nome || '').toUpperCase(),
          razao_social: (fornForm.nome || '').toUpperCase(),
          fantasia: (fornForm.fantasia || '').toUpperCase(),
          cnpj_cpf: fornForm.cnpj,
          insc_estadual: fornForm.inscricao,
          fone: fornForm.telefone,
          email: fornForm.email,
          endereco: fornForm.endereco,
          bairro: fornForm.bairro,
          cid: Number(fornForm.for_cid) || 0,
          for_cid: Number(fornForm.for_cid) || 0,
          uf: (fornForm.uf || 'PR').toUpperCase(),
          contato: fornForm.contato
        };
        if (editingItem) {
          await api.put('/v1/fornecedores', payload);
        } else {
          await api.post('/v1/fornecedores', payload);
        }
      }

      alert('Salvo com sucesso!');
      setShowForm(false);
      fetchData(activeSubTab, page, searchTerm);
      fetchLookups();
    } catch (err) {
      console.error(err);
      alert('Erro ao salvar registro: ' + (err.response?.data?.error || err.message));
    } finally {
      setLoading(false);
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

  // Funções para Modal de Grades por Produto
  const fetchProductGrades = async (productCode) => {
    setLoadingProductGrades(true);
    try {
      let res = await api.get(`/v1/grades/produto/${productCode}`);
      let items = [];
      if (Array.isArray(res.data)) items = res.data;
      else if (res.data?.data) items = res.data.data;
      
      setProductGradesList(items);
    } catch (err) {
      try {
        let resAll = await api.get('/v1/grades?limit=100');
        let allGrades = Array.isArray(resAll.data) ? resAll.data : (resAll.data?.data || []);
        setProductGradesList(allGrades.filter(g => Number(g.pro) === Number(productCode)));
      } catch (e2) {
        setProductGradesList([]);
      }
    } finally {
      setLoadingProductGrades(false);
    }
  };

  const handleOpenProductGradesModal = async (product) => {
    setSelectedProductGrades(product);
    setShowProductGradeForm(false);
    setEditingProductGrade(null);

    let defaultTam = tamanhos[0]?.codigo || '';
    if (tamanhos.length === 0) {
      try {
        const tRes = await api.get('/v1/tamanhos?limit=100');
        let loadedTams = [];
        if (Array.isArray(tRes.data)) loadedTams = tRes.data;
        else if (tRes.data?.data) loadedTams = tRes.data.data;
        setTamanhos(loadedTams);
        if (loadedTams.length > 0) defaultTam = loadedTams[0].codigo;
      } catch (err) {
        console.warn('Erro ao carregar tamanhos:', err);
      }
    }

    setProductGradeForm({
      codigo: '',
      pro: product.codigo,
      tam: defaultTam,
      cor: '',
      quantidade: '',
      valor: product.valorv || 0,
      valor_dinheiro: product.pro_valor_dinheiro || product.valorv || 0,
      valor_prazo: product.pro_valorv_prazo || product.valorv || 0,
      codbarra: product.codbarra || ''
    });

    await fetchProductGrades(product.codigo);
  };

  const handleSaveProductGrade = async (e) => {
    e.preventDefault();
    if (!productGradeForm.tam) {
      alert('Selecione um tamanho para a variação.');
      return;
    }
    setLoadingProductGrades(true);
    try {
      const pgDin = Number(productGradeForm.valor_dinheiro) || Number(productGradeForm.valor) || 0;
      const pgPrz = Number(productGradeForm.valor_prazo) || Number(productGradeForm.valor) || 0;
      const payload = {
        codigo: editingProductGrade ? Number(productGradeForm.codigo) : 0,
        pro: Number(selectedProductGrades.codigo),
        tam: Number(productGradeForm.tam),
        quantidade: Number(productGradeForm.quantidade) || 0,
        valor: Number(productGradeForm.valor) || 0,
        valor_dinheiro: pgDin,
        valor_prazo: pgPrz,
        codbarra: productGradeForm.codbarra || '',
        cor: (productGradeForm.cor || '').toUpperCase()
      };

      if (editingProductGrade) {
        await api.put('/v1/grades', payload);
      } else {
        await api.post('/v1/grades', payload);
      }

      alert('Grade salva com sucesso!');
      setShowProductGradeForm(false);
      setEditingProductGrade(null);
      setProductGradeForm({
        codigo: '',
        pro: selectedProductGrades.codigo,
        tam: tamanhos[0]?.codigo || '',
        cor: '',
        quantidade: '',
        valor: selectedProductGrades.valorv || 0,
        codbarra: selectedProductGrades.codbarra || ''
      });
      await fetchProductGrades(selectedProductGrades.codigo);
      if (activeSubTab === 'grades') fetchData();
    } catch (err) {
      console.error(err);
      alert('Erro ao salvar grade do produto.');
    } finally {
      setLoadingProductGrades(false);
    }
  };

  const handleDeleteProductGrade = async (gradeId) => {
    if (!window.confirm('Tem certeza que deseja excluir esta grade?')) return;
    setLoadingProductGrades(true);
    try {
      await api.delete(`/v1/grades/${gradeId}`);
      alert('Grade excluída com sucesso!');
      await fetchProductGrades(selectedProductGrades.codigo);
      if (activeSubTab === 'grades') fetchData();
    } catch (err) {
      alert('Erro ao excluir grade.');
    } finally {
      setLoadingProductGrades(false);
    }
  };

  return (
    <div className="crud-container full-width">
      
      {/* Sub Menu de Cadastros */}
      <div className="crud-header-tabs glass">
        <button className={`crud-tab-btn ${activeSubTab === 'grupos' ? 'active' : ''}`} onClick={() => { setActiveSubTab('grupos'); setShowForm(false); }}>
          <Folder size={18} /> Grupos
        </button>
        <button className={`crud-tab-btn ${activeSubTab === 'subgrupos' ? 'active' : ''}`} onClick={() => { setActiveSubTab('subgrupos'); setShowForm(false); }}>
          <Layers size={18} /> Subgrupos
        </button>
        <button className={`crud-tab-btn ${activeSubTab === 'modelos' ? 'active' : ''}`} onClick={() => { setActiveSubTab('modelos'); setShowForm(false); }}>
          <Tag size={18} /> Modelos
        </button>
        <button className={`crud-tab-btn ${activeSubTab === 'grades' ? 'active' : ''}`} onClick={() => { setActiveSubTab('grades'); setShowForm(false); }}>
          <Grid size={18} /> Grades
        </button>
        <button className={`crud-tab-btn ${activeSubTab === 'tamanhos' ? 'active' : ''}`} onClick={() => { setActiveSubTab('tamanhos'); setShowForm(false); }}>
          <Ruler size={18} /> Tamanhos
        </button>
        <button className={`crud-tab-btn ${activeSubTab === 'produtos' ? 'active' : ''}`} onClick={() => { setActiveSubTab('produtos'); setShowForm(false); }}>
          <Package size={18} /> Produtos
        </button>
        <button className={`crud-tab-btn ${activeSubTab === 'fornecedores' ? 'active' : ''}`} onClick={() => { setActiveSubTab('fornecedores'); setShowForm(false); }}>
          <UserPlus size={18} /> Fornecedores
        </button>
        <button 
          className="crud-tab-btn" 
          style={{ background: 'linear-gradient(135deg, #1e40af, #2563eb)', color: '#ffffff', marginLeft: 'auto', gap: '6px' }}
          onClick={() => setShowConciliacaoModal(true)}
          title="Abrir Relatório Comparativo de Estoque Fiscal vs Físico"
        >
          <FileCheck2 size={18} /> Conciliação Fiscal
        </button>
      </div>

      {error && <div className="crud-error-bar"><AlertCircle size={20} /> {error}</div>}

      {/* TELA DE FORMULÁRIO (Criação ou Edição) */}
      {showForm && (
        <div className="list-card glass">
          <div className="crud-title-row">
            <h4>{editingItem ? 'Editar Registro' : 'Cadastrar Novo Registro'}</h4>
            <button className="crud-close-btn" onClick={() => setShowForm(false)}><X size={18} /></button>
          </div>

          <form onSubmit={handleSave}>
            
            {/* FORM: PRODUTOS */}
            {activeSubTab === 'produtos' && (
              <div className="grid-form">
                <label className="crud-input">
                  Nome do Produto *
                  <input type="text" value={prodForm.nome} onChange={(e) => setProdForm({ ...prodForm, nome: e.target.value.toUpperCase() })} required style={{ textTransform: 'uppercase' }} />
                </label>
                <label className="crud-input">
                  Fabricante/Marca
                  <input type="text" value={prodForm.fabricante} onChange={(e) => setProdForm({ ...prodForm, fabricante: e.target.value.toUpperCase() })} style={{ textTransform: 'uppercase' }} />
                </label>
                <label className="crud-input">
                  Fornecedor (Amarração)
                  <select 
                    value={prodForm.pro_for || 0} 
                    onChange={(e) => setProdForm({ ...prodForm, pro_for: Number(e.target.value) })}
                  >
                    <option value="0">-- Nenhum / Selecione Fornecedor --</option>
                    {fornecedores.map(f => (
                      <option key={f.codigo} value={f.codigo}>
                        #{f.codigo} - {f.nome || f.razao_social || f.fantasia}
                      </option>
                    ))}
                  </select>
                </label>
                <label className="crud-input">
                  Subgrupo / Grupo (Amarração)
                  <select 
                    value={prodForm.pro_gru || 0} 
                    onChange={(e) => setProdForm({ ...prodForm, pro_gru: Number(e.target.value) })}
                  >
                    <option value="0">-- Nenhum / Selecione Subgrupo --</option>
                    {subgrupos.map(sg => {
                      const grp = grupos.find(g => Number(g.codigo) === Number(sg.g1 || sg.gru_g1));
                      return (
                        <option key={sg.codigo} value={sg.codigo}>
                          #{sg.codigo} - {sg.nome}{grp ? ` [Grupo: ${grp.nome}]` : ''}
                        </option>
                      );
                    })}
                  </select>
                </label>
                <label className="crud-input">
                  Código de Barras (EAN)
                  <input type="text" value={prodForm.codbarra} onChange={(e) => setProdForm({ ...prodForm, codbarra: e.target.value })} />
                </label>
                <label className="crud-input">
                  NCM (Classificação Fiscal) *
                  <input type="text" required value={prodForm.ncm || '6109.10.00'} onChange={(e) => setProdForm({ ...prodForm, ncm: e.target.value })} placeholder="Ex: 6109.10.00" />
                </label>
                <label className="crud-input">
                  Unidade de Medida (UM) *
                  <select value={prodForm.um || 'UN'} onChange={(e) => setProdForm({ ...prodForm, um: e.target.value })}>
                    <option value="UN">UN - Unidade</option>
                    <option value="PC">PC - Peça</option>
                    <option value="KG">KG - Quilograma</option>
                    <option value="PAR">PAR - Par</option>
                    <option value="CX">CX - Caixa</option>
                    <option value="MT">MT - Metro</option>
                    <option value="L">L - Litro</option>
                  </select>
                </label>
                <label className="crud-input">
                  Totalizador Fiscal (ICMS/ISS) *
                  <select value={prodForm.codTotalizador || 1} onChange={(e) => setProdForm({ ...prodForm, codTotalizador: Number(e.target.value) })}>
                    {totalizadores.map(tot => (
                      <option key={tot.codigo} value={tot.codigo}>
                        #{tot.codigo} - {tot.totalizador} ({tot.descricao || 'Tributado'})
                      </option>
                    ))}
                  </select>
                </label>
                <label className="crud-input">
                  Estoque Inicial
                  <input type="number" value={prodForm.quantidade} onChange={(e) => setProdForm({ ...prodForm, quantidade: e.target.value })} />
                </label>
                <label className="crud-input">
                  Valor Dinheiro (R$)
                  <input type="number" step="0.01" value={prodForm.pro_valor_dinheiro} onChange={(e) => setProdForm({ ...prodForm, pro_valor_dinheiro: e.target.value })} placeholder="Ex: 55.00" />
                </label>
                <label className="crud-input">
                  Preço Vista (Débito / PIX) (R$) *
                  <input type="number" step="0.01" value={prodForm.valorv} onChange={(e) => setProdForm({ ...prodForm, valorv: e.target.value })} placeholder="Ex: 59.90" required />
                </label>
                <label className="crud-input">
                  Preço a Prazo (Cartão Prazo) (R$)
                  <input type="number" step="0.01" value={prodForm.pro_valorv_prazo} onChange={(e) => setProdForm({ ...prodForm, pro_valorv_prazo: e.target.value })} placeholder="Ex: 65.90" />
                </label>
                <label className="crud-input">
                  URL da Imagem
                  <input type="text" value={prodForm.url_Imagem} onChange={(e) => setProdForm({ ...prodForm, url_Imagem: e.target.value })} />
                </label>
              </div>
            )}

            {/* FORM: GRUPOS */}
            {activeSubTab === 'grupos' && (
              <div className="grid-form">
                <label className="crud-input">
                  Nome do Grupo *
                  <input type="text" value={grupoForm.nome} onChange={(e) => setGrupoForm({ ...grupoForm, nome: e.target.value.toUpperCase() })} required style={{ textTransform: 'uppercase' }} />
                </label>
              </div>
            )}

            {/* FORM: SUBGRUPOS */}
            {activeSubTab === 'subgrupos' && (
              <div className="grid-form">
                <label className="crud-input">
                  Nome do Subgrupo *
                  <input type="text" value={subgrupoForm.nome} onChange={(e) => setSubgrupoForm({ ...subgrupoForm, nome: e.target.value.toUpperCase() })} required style={{ textTransform: 'uppercase' }} />
                </label>
                <label className="crud-input">
                  Grupo Principal (G1) *
                  <select 
                    value={subgrupoForm.g1 || ''} 
                    onChange={(e) => setSubgrupoForm({ ...subgrupoForm, g1: e.target.value })} 
                    required
                  >
                    <option value="">-- Selecione o Grupo --</option>
                    {grupos.map(g => (
                      <option key={g.codigo} value={g.codigo}>
                        #{g.codigo} - {g.nome}
                      </option>
                    ))}
                  </select>
                </label>
                <label className="crud-input">
                  TR Código (Padrão: 0)
                  <input type="number" value={subgrupoForm.tr} onChange={(e) => setSubgrupoForm({ ...subgrupoForm, tr: e.target.value })} />
                </label>
              </div>
            )}

            {/* FORM: MODELOS (NOVO) */}
            {activeSubTab === 'modelos' && (
              <div className="grid-form">
                <label className="crud-input">
                  Nome do Modelo *
                  <input 
                    type="text" 
                    value={modeloForm.nome} 
                    onChange={(e) => setModeloForm({ ...modeloForm, nome: e.target.value.toUpperCase() })} 
                    required 
                    placeholder="Ex: SLIM, REGATA, POLO, FLARE, BASIC" 
                    style={{ textTransform: 'uppercase' }}
                  />
                </label>
              </div>
            )}

            {/* FORM: GRADES */}
            {activeSubTab === 'grades' && (
              <div className="grid-form">
                <label className="crud-input">
                  Produto Relacionado *
                  <select value={gradeForm.pro} onChange={(e) => setGradeForm({ ...gradeForm, pro: e.target.value })} required>
                    <option value="">Selecione...</option>
                    {produtos.map(p => <option key={p.codigo} value={p.codigo}>{p.nome}</option>)}
                  </select>
                </label>
                <label className="crud-input">
                  Tamanho (Variação) *
                  <select value={gradeForm.tam} onChange={(e) => setGradeForm({ ...gradeForm, tam: e.target.value })} required>
                    <option value="">Selecione...</option>
                    {tamanhos.map(t => <option key={t.codigo} value={t.codigo}>{t.tamanho} ({t.sigla})</option>)}
                  </select>
                </label>
                <label className="crud-input">
                  Quantidade física na Grade
                  <input type="number" value={gradeForm.quantidade} onChange={(e) => setGradeForm({ ...gradeForm, quantidade: e.target.value })} />
                </label>
                <label className="crud-input">
                  Preço Vista (Débito / PIX) (R$)
                  <input type="number" step="0.01" value={gradeForm.valor} onChange={(e) => setGradeForm({ ...gradeForm, valor: e.target.value })} placeholder="Ex: 59.90" />
                </label>
                <label className="crud-input">
                  Valor Dinheiro (R$)
                  <input type="number" step="0.01" value={gradeForm.valor_dinheiro} onChange={(e) => setGradeForm({ ...gradeForm, valor_dinheiro: e.target.value })} placeholder="Ex: 55.00" />
                </label>
                <label className="crud-input">
                  Preço a Prazo (Cartão Prazo) (R$)
                  <input type="number" step="0.01" value={gradeForm.valor_prazo} onChange={(e) => setGradeForm({ ...gradeForm, valor_prazo: e.target.value })} placeholder="Ex: 65.90" />
                </label>
                <label className="crud-input">
                  Cor
                  <input type="text" value={gradeForm.cor} onChange={(e) => setGradeForm({ ...gradeForm, cor: e.target.value.toUpperCase() })} placeholder="Ex: Azul, Preto" style={{ textTransform: 'uppercase' }} />
                </label>
                <label className="crud-input">
                  Código de Barras Específico
                  <input type="text" value={gradeForm.codbarra} onChange={(e) => setGradeForm({ ...gradeForm, codbarra: e.target.value })} />
                </label>
              </div>
            )}

            {/* FORM: TAMANHOS */}
            {activeSubTab === 'tamanhos' && (
              <div className="grid-form">
                <label className="crud-input">
                  Descrição do Tamanho (ex: P, M, G, 42) *
                  <input type="text" value={tamanhoForm.tamanho} onChange={(e) => setTamanhoForm({ ...tamanhoForm, tamanho: e.target.value.toUpperCase() })} required style={{ textTransform: 'uppercase' }} />
                </label>
                <label className="crud-input">
                  Sigla Curta (ex: P, 42) *
                  <input type="text" value={tamanhoForm.sigla} onChange={(e) => setTamanhoForm({ ...tamanhoForm, sigla: e.target.value.toUpperCase() })} required style={{ textTransform: 'uppercase' }} />
                </label>
                <label className="crud-input">
                  Valor / Peso Adicional
                  <input type="number" step="0.01" value={tamanhoForm.valor} onChange={(e) => setTamanhoForm({ ...tamanhoForm, valor: e.target.value })} />
                </label>
              </div>
            )}

            {/* FORM: FORNECEDORES COM MÁSCARA E CIDADES (FOR_CID) */}
            {activeSubTab === 'fornecedores' && (
              <div className="grid-form">
                <label className="crud-input">
                  Razão Social / Nome do Fornecedor *
                  <input type="text" required value={fornForm.nome} onChange={(e) => setFornForm({ ...fornForm, nome: e.target.value.toUpperCase() })} placeholder="Ex: DISTRIBUIDORA DE TECIDOS LTDA" style={{ textTransform: 'uppercase' }} />
                </label>
                <label className="crud-input">
                  Nome Fantasia
                  <input type="text" value={fornForm.fantasia} onChange={(e) => setFornForm({ ...fornForm, fantasia: e.target.value.toUpperCase() })} placeholder="Ex: TECIDOS BRASIL" style={{ textTransform: 'uppercase' }} />
                </label>
                <label className="crud-input">
                  CNPJ / CPF (com máscara) *
                  <input 
                    type="text" 
                    value={fornForm.cnpj} 
                    onChange={(e) => setFornForm({ ...fornForm, cnpj: maskCnpjCpf(e.target.value) })} 
                    placeholder="00.000.000/0000-00" 
                  />
                </label>
                <label className="crud-input">
                  Inscrição Estadual (IE)
                  <input type="text" value={fornForm.inscricao} onChange={(e) => setFornForm({ ...fornForm, inscricao: e.target.value })} placeholder="Isento ou Nº" />
                </label>
                <label className="crud-input">
                  Telefone / WhatsApp
                  <input type="text" value={fornForm.telefone} onChange={(e) => setFornForm({ ...fornForm, telefone: e.target.value })} placeholder="(00) 00000-0000" />
                </label>
                <label className="crud-input">
                  E-mail
                  <input type="email" value={fornForm.email} onChange={(e) => setFornForm({ ...fornForm, email: e.target.value })} placeholder="contato@fornecedor.com.br" />
                </label>
                <label className="crud-input" style={{ gridColumn: 'span 2' }}>
                  Endereço
                  <input type="text" value={fornForm.endereco} onChange={(e) => setFornForm({ ...fornForm, endereco: e.target.value })} placeholder="Rua, Av, Número" />
                </label>
                <label className="crud-input">
                  Bairro
                  <input type="text" value={fornForm.bairro} onChange={(e) => setFornForm({ ...fornForm, bairro: e.target.value })} placeholder="Centro" />
                </label>
                <label className="crud-input">
                  Cidade (FOR_CID) *
                  <select 
                    value={fornForm.for_cid} 
                    onChange={(e) => {
                      const cidId = Number(e.target.value);
                      const matchCid = cidades.find(c => Number(c.codigo) === cidId);
                      setFornForm({
                        ...fornForm,
                        for_cid: cidId,
                        cidade: matchCid ? matchCid.nome : fornForm.cidade,
                        uf: matchCid ? matchCid.uf : fornForm.uf
                      });
                    }}
                  >
                    <option value="">-- Selecione a Cidade --</option>
                    {cidades.map(c => (
                      <option key={c.codigo} value={c.codigo}>
                        {c.nome} ({c.uf})
                      </option>
                    ))}
                  </select>
                </label>
                <label className="crud-input">
                  UF
                  <input type="text" maxLength={2} value={fornForm.uf} onChange={(e) => setFornForm({ ...fornForm, uf: e.target.value.toUpperCase() })} placeholder="PR" style={{ textTransform: 'uppercase' }} />
                </label>
                <label className="crud-input">
                  Contato / Vendedor
                  <input type="text" value={fornForm.contato} onChange={(e) => setFornForm({ ...fornForm, contato: e.target.value })} placeholder="Nome do representante" />
                </label>
              </div>
            )}

            <div className="crud-form-actions">
              <button type="button" className="btn-secondary" onClick={() => setShowForm(false)}>Cancelar</button>
              <button type="submit" className="btn-primary" disabled={loading}><Save size={16} /> Salvar Registro</button>
            </div>
          </form>
        </div>
      )}

      {/* BARRA DE PESQUISA E BOTÃO DE NOVO REGISTRO */}
      <div className="crud-actions-bar">
        <SearchBar
          value={searchTerm}
          onChange={(val) => {
            setSearchTerm(val);
            fetchData(1, val);
          }}
          placeholder={`Buscar em ${activeSubTab}...`}
        />

        {activeSubTab === 'grades' && (
          <select 
            value={gradeProductFilter}
            onChange={(e) => setGradeProductFilter(e.target.value)}
            className="filter-select"
            style={{ maxWidth: '300px' }}
          >
            <option value="">Todos os Produtos</option>
            {produtos.map(p => (
              <option key={p.codigo} value={p.codigo}>#{p.codigo} - {p.nome}</option>
            ))}
          </select>
        )}

        <button className="btn-primary" onClick={handleOpenCreate}>
          <Plus size={16} /> + Novo Registro
        </button>
      </div>

      {/* TABELA DE REGISTROS */}
      <div className="list-card glass">
        <div className="table-responsive">
          <table className="data-table">
            
            {/* LIST: GRUPOS */}
            {activeSubTab === 'grupos' && (
              <>
                <thead>
                  <tr>
                    <th>Código Grupo</th>
                    <th>Nome</th>
                    <th>Ações</th>
                  </tr>
                </thead>
                <tbody>
                  {(grupos || []).map((item, idx) => (
                    <tr key={item.codigo || idx}>
                      <td><span className="item-code">#{item.codigo}</span></td>
                      <td><strong>{item.nome}</strong></td>
                      <td className="actions-cell">
                        <button className="crud-row-btn edit" onClick={() => handleOpenEdit(item)}><Edit size={14} /></button>
                        <button className="crud-row-btn delete" onClick={() => handleDelete(item.codigo)}><Trash2 size={14} /></button>
                      </td>
                    </tr>
                  ))}
                  {(!grupos || grupos.length === 0) && (
                    <tr>
                      <td colSpan="3" style={{ textAlign: 'center', padding: '2rem', color: '#64748b' }}>
                        Nenhum grupo cadastrado.
                      </td>
                    </tr>
                  )}
                </tbody>
              </>
            )}

            {/* LIST: SUBGRUPOS */}
            {activeSubTab === 'subgrupos' && (
              <>
                <thead>
                  <tr>
                    <th>Código Subgrupo</th>
                    <th>Nome Subgrupo</th>
                    <th>Grupo Principal (G1)</th>
                    <th>TR</th>
                    <th>Ações</th>
                  </tr>
                </thead>
                <tbody>
                  {(subgrupos || []).map((item, idx) => {
                    const grpId = Number(item.g1 || item.gru_g1);
                    const grp = (grupos || []).find(g => Number(g.codigo) === grpId);

                    return (
                      <tr key={item.codigo || idx}>
                        <td><span className="item-code">#{item.codigo}</span></td>
                        <td><strong>{item.nome}</strong></td>
                        <td>
                          {grp ? (
                            <span className="badge badge-info">#{grp.codigo} - {grp.nome}</span>
                          ) : (
                            <span className="sigla-tag">#{item.g1 || '-'}</span>
                          )}
                        </td>
                        <td>{item.tr}</td>
                        <td className="actions-cell">
                          <button className="crud-row-btn edit" onClick={() => handleOpenEdit(item)}><Edit size={14} /></button>
                          <button className="crud-row-btn delete" onClick={() => handleDelete(item.codigo)}><Trash2 size={14} /></button>
                        </td>
                      </tr>
                    );
                  })}
                  {(!subgrupos || subgrupos.length === 0) && (
                    <tr>
                      <td colSpan="5" style={{ textAlign: 'center', padding: '2rem', color: '#64748b' }}>
                        Nenhum subgrupo cadastrado.
                      </td>
                    </tr>
                  )}
                </tbody>
              </>
            )}

            {/* LIST: MODELOS (NOVO) */}
            {activeSubTab === 'modelos' && (
              <>
                <thead>
                  <tr>
                    <th>Código Modelo</th>
                    <th>Nome do Modelo</th>
                    <th>Ações</th>
                  </tr>
                </thead>
                <tbody>
                  {(modelos || []).map((item, idx) => (
                    <tr key={item.codigo || idx}>
                      <td><span className="item-code">#{item.codigo}</span></td>
                      <td><strong>{item.nome}</strong></td>
                      <td className="actions-cell">
                        <button className="crud-row-btn edit" onClick={() => handleOpenEdit(item)}><Edit size={14} /></button>
                        <button className="crud-row-btn delete" onClick={() => handleDelete(item.codigo)}><Trash2 size={14} /></button>
                      </td>
                    </tr>
                  ))}
                  {(!modelos || modelos.length === 0) && (
                    <tr>
                      <td colSpan="3" style={{ textAlign: 'center', padding: '2rem', color: '#64748b' }}>
                        Nenhum modelo cadastrado.
                      </td>
                    </tr>
                  )}
                </tbody>
              </>
            )}

            {/* LIST: GRADES */}
            {activeSubTab === 'grades' && (
              <>
                <thead>
                  <tr>
                    <th>Cód Grade</th>
                    <th>Produto</th>
                    <th>Tamanho</th>
                    <th>Estoque</th>
                    <th>Preços (Vista / Din. / Prazo)</th>
                    <th>Cor</th>
                    <th>Cod. Barras</th>
                    <th>Ações</th>
                  </tr>
                </thead>
                <tbody>
                  {(grades || [])
                    .filter(g => !gradeProductFilter || Number(g.pro) === Number(gradeProductFilter))
                    .map((item, idx) => {
                      const prod = (produtos || []).find(p => p.codigo === item.pro);
                      const tam = (tamanhos || []).find(t => t.codigo === item.tam);
                      return (
                        <tr key={item.codigo || idx}>
                          <td><span className="item-code">#{item.codigo}</span></td>
                          <td className="product-name-cell" title={prod ? prod.nome : `Produto #${item.pro}`}>{prod ? prod.nome : `Produto #${item.pro}`}</td>
                          <td>{tam ? `${tam.tamanho} (${tam.sigla})` : `Tamanho #${item.tam}`}</td>
                          <td><strong>{item.quantidade}</strong></td>
                          <td className="prices-cell">
                            <div className="price-badge-container">
                              <div className="price-primary" title="Preço Vista (Débito / PIX)">
                                <span className="price-label">Vista:</span> {formatCurrency(item.valor || 0)}
                              </div>
                              <div className="price-secondary-row">
                                <span className="price-tag" title="Valor Dinheiro">Din: {formatCurrency(item.valor_dinheiro ?? item.valor ?? 0)}</span>
                                <span className="price-tag" title="Preço a Prazo">Prazo: {formatCurrency(item.valor_prazo ?? item.valor ?? 0)}</span>
                              </div>
                            </div>
                          </td>
                          <td>{item.cor ? <span className="sigla-tag">{item.cor}</span> : '-'}</td>
                          <td className="codbarra-cell">{item.codbarra || '-'}</td>
                          <td className="actions-cell">
                            <button className="crud-row-btn edit" onClick={() => handleOpenEdit(item)}><Edit size={14} /></button>
                            <button className="crud-row-btn delete" onClick={() => handleDelete(item.codigo)}><Trash2 size={14} /></button>
                          </td>
                        </tr>
                      );
                    })}
                  {(!grades || grades.length === 0) && (
                    <tr>
                      <td colSpan="8" style={{ textAlign: 'center', padding: '2rem', color: '#64748b' }}>
                        Nenhuma grade cadastrada.
                      </td>
                    </tr>
                  )}
                </tbody>
              </>
            )}

            {/* LIST: TAMANHOS (SEQUENCIAIS) */}
            {activeSubTab === 'tamanhos' && (
              <>
                <thead>
                  <tr>
                    <th>Cod Tamanho</th>
                    <th>Descrição</th>
                    <th>Sigla</th>
                    <th>Valor/Peso</th>
                    <th>Pro ID</th>
                    <th>Ações</th>
                  </tr>
                </thead>
                <tbody>
                  {(tamanhos || []).map((item, idx) => (
                    <tr key={item.codigo || idx}>
                      <td><span className="item-code">#{item.codigo}</span></td>
                      <td><strong>{item.tamanho}</strong></td>
                      <td><span className="sigla-tag">{item.sigla}</span></td>
                      <td>{item.valor || 0}</td>
                      <td>{item.pro || 0}</td>
                      <td className="actions-cell">
                        <button className="crud-row-btn edit" onClick={() => handleOpenEdit(item)}><Edit size={14} /></button>
                        <button className="crud-row-btn delete" onClick={() => handleDelete(item.codigo)}><Trash2 size={14} /></button>
                      </td>
                    </tr>
                  ))}
                  {(!tamanhos || tamanhos.length === 0) && (
                    <tr>
                      <td colSpan="6" style={{ textAlign: 'center', padding: '2rem', color: '#64748b' }}>
                        Nenhum tamanho cadastrado.
                      </td>
                    </tr>
                  )}
                </tbody>
              </>
            )}

            {/* LIST: PRODUTOS */}
            {activeSubTab === 'produtos' && (
              <>
                <thead>
                  <tr>
                    <th>Código</th>
                    <th>Nome do Produto</th>
                    <th>Fabricante/Marca</th>
                    <th style={{ textAlign: 'center' }} title="Estoque Total Consolidado (Soma de Todas as Filiais)">Estoque Total</th>
                    <th>Preços (Vista / Din. / Prazo)</th>
                    <th>Cód. Barras</th>
                    <th>Ações</th>
                  </tr>
                </thead>
                <tbody>
                  {(produtos || []).map((item, idx) => {
                    const stockTotal = getProductStockForActiveUnit(item);
                    return (
                      <tr key={item.codigo || idx}>
                        <td><span className="item-code">#{item.codigo}</span></td>
                        <td><strong>{item.nome}</strong></td>
                        <td>{item.fabricante || item.marca || '-'}</td>
                        <td style={{ textAlign: 'center' }}>
                          <strong style={{ color: stockTotal > 0 ? '#10b981' : '#ef4444' }}>
                            {stockTotal}
                          </strong>
                        </td>
                        <td className="prices-cell">
                        <div className="price-badge-container">
                          <div className="price-primary" title="Preço Vista (Débito / PIX)">
                            <span className="price-label">Vista:</span> {formatCurrency(item.valorv || 0)}
                          </div>
                          <div className="price-secondary-row">
                            <span className="price-tag" title="Valor Dinheiro">Din: {formatCurrency(item.pro_valor_dinheiro ?? item.valorv ?? 0)}</span>
                            <span className="price-tag" title="Preço a Prazo">Prazo: {formatCurrency(item.pro_valorv_prazo ?? item.valorv ?? 0)}</span>
                          </div>
                        </div>
                      </td>
                      <td><code>{item.codbarra || '-'}</code></td>
                      <td className="actions-cell">
                        <button className="crud-row-btn edit" onClick={() => handleOpenEdit(item)} title="Editar Produto"><Edit size={14} /></button>
                        <button className="crud-row-btn delete" onClick={() => handleDelete(item.codigo)} title="Excluir Produto"><Trash2 size={14} /></button>
                      </td>
                    </tr>
                  );
                })}
                  {(!produtos || produtos.length === 0) && (
                    <tr>
                      <td colSpan="7" style={{ textAlign: 'center', padding: '2.5rem', color: '#64748b' }}>
                        Nenhum produto cadastrado no catálogo. Clique em <strong>"+ Novo Registro"</strong> para cadastrar.
                      </td>
                    </tr>
                  )}
                </tbody>
              </>
            )}

            {/* LIST: FORNECEDORES */}
            {activeSubTab === 'fornecedores' && (
              <>
                <thead>
                  <tr>
                    <th style={{ width: '90px' }}>Código</th>
                    <th>Razão Social / Nome</th>
                    <th>Nome Fantasia</th>
                    <th>CNPJ / CPF</th>
                    <th>Telefone / Contato</th>
                    <th>Cidade / UF</th>
                    <th style={{ textAlign: 'center', width: '120px' }}>Ações</th>
                  </tr>
                </thead>
                <tbody>
                  {fornecedores.map((item, idx) => {
                    const cidStr = typeof item.cidade === 'object' && item.cidade !== null
                      ? (item.cidade.nome || item.cidade.descricao || '')
                      : (item.cidade || '');
                    const ufStr = typeof item.uf === 'object' && item.uf !== null
                      ? (item.uf.sigla || item.uf.uf || '')
                      : (item.uf || (item.cidade && typeof item.cidade === 'object' ? item.cidade.uf : ''));
                    const locStr = cidStr ? (ufStr ? `${cidStr}/${ufStr}` : cidStr) : (ufStr || '-');

                    return (
                      <tr key={item.codigo || idx}>
                        <td><span className="item-code">#{item.codigo}</span></td>
                        <td><strong>{item.nome || item.razao_social}</strong></td>
                        <td>{item.fantasia || item.nome_fantasia || '-'}</td>
                        <td><code>{maskCnpjCpf(item.cnpj || item.cnpj_cpf || item.cpf_cnpj || '') || '-'}</code></td>
                        <td>{item.telefone || item.fone || item.contato || '-'}</td>
                        <td>{locStr}</td>
                        <td className="actions-cell">
                          <button className="crud-row-btn edit" onClick={() => handleOpenEdit(item)} title="Editar Fornecedor"><Edit size={14} /></button>
                          <button className="crud-row-btn delete" onClick={() => handleDelete(item.codigo)} title="Excluir Fornecedor"><Trash2 size={14} /></button>
                        </td>
                      </tr>
                    );
                  })}
                  {fornecedores.length === 0 && (
                    <tr>
                      <td colSpan="7" style={{ textAlign: 'center', padding: '2rem', color: '#64748b' }}>
                        Nenhum fornecedor cadastrado.
                      </td>
                    </tr>
                  )}
                </tbody>
              </>
            )}

          </table>
        </div>
        
        <Pagination
          currentPage={meta.page || page}
          totalPages={meta.pages || 1}
          onPageChange={(p) => fetchData(p, searchTerm)}
        />
      </div>

      {/* MODAL POPUP DE HISTÓRICO DE MOVIMENTAÇÃO (HIS_PRO) */}
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
                          <td>{formatDatehora(h.hp_data)}</td>
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

      {/* POP-UPS DE CADASTRO */}
      {showProductModal && (
        <ProductFormModal
          isOpen={showProductModal}
          onClose={() => setShowProductModal(false)}
          productToEdit={productToEditModal}
          onSaveSuccess={() => {
            setShowProductModal(false);
            fetchData();
          }}
          grupos={grupos}
          subgrupos={subgrupos}
          fornecedores={fornecedores}
        />
      )}

      {showGruposSubgruposModal && (
        <GruposSubgruposModal
          isOpen={showGruposSubgruposModal}
          onClose={() => {
            setShowGruposSubgruposModal(false);
            fetchData();
          }}
        />
      )}

      {showGradesModal && (
        <GradesModal
          isOpen={showGradesModal}
          onClose={() => {
            setShowGradesModal(false);
            fetchData();
          }}
          product={productForGrades}
          onGradesUpdated={() => fetchData()}
        />
      )}

      {showConciliacaoModal && (
        <ConciliacaoFiscalModal
          onClose={() => setShowConciliacaoModal(false)}
        />
      )}

    </div>
  );
}
