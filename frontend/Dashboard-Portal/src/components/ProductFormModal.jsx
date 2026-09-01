import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import {
  Package, Plus, Trash2, Check, X, Edit2, Search, Grid,
  Image as ImageIcon, DollarSign, Layers, ShieldCheck,
  RefreshCw, Barcode, AlertCircle, TrendingUp,
  CheckCircle2, FolderPlus, UserPlus, FileText, Printer,
  Tag, MapPin, Save
} from 'lucide-react';
import { createApi } from '../services/api';
import { toast } from '../contexts/ToastContext';
import GradesModal from './GradesModal';
import GruposSubgruposModal from './GruposSubgruposModal';
import LookupSelect from './LookupSelect';
import { formatCurrency } from '../utils/formatters';
import './ProductFormModal.css';

export default function ProductFormModal({
  isOpen,
  onClose,
  productToEdit,
  onSaveSuccess,
  grupos = [],
  subgrupos = [],
  fornecedores = []
}) {
  if (!isOpen) return null;

  const api = createApi(true);

  // Controle de Abas
  const [activeTab, setActiveTab] = useState('geral'); // 'geral', 'precos', 'imagens', 'fiscal'
  const [mode, setMode] = useState(productToEdit ? 'browse' : 'insert'); // 'browse', 'insert', 'edit'
  const [loading, setLoading] = useState(false);
  const [successMsg, setSuccessMsg] = useState('');
  const [errorMsg, setErrorMsg] = useState('');

  // Submodais
  const [showGradesModal, setShowGradesModal] = useState(false);
  const [showGruposSubgruposModal, setShowGruposSubgruposModal] = useState(false);
  const [showQuickVendorModal, setShowQuickVendorModal] = useState(false);
  const [showQuickModeloModal, setShowQuickModeloModal] = useState(false);

  // Grupos, Subgrupos e Fornecedores autônomos
  const [gruposList, setGruposList] = useState(grupos);
  const [subgruposList, setSubgruposList] = useState(subgrupos);
  const [fornecedoresList, setFornecedoresList] = useState(fornecedores);

  // Sincroniza props se forem passadas ou atualizadas externamente
  useEffect(() => {
    if (grupos && grupos.length > 0) setGruposList(grupos);
  }, [grupos]);

  useEffect(() => {
    if (subgrupos && subgrupos.length > 0) setSubgruposList(subgrupos);
  }, [subgrupos]);

  useEffect(() => {
    if (fornecedores && fornecedores.length > 0) setFornecedoresList(fornecedores);
  }, [fornecedores]);

  // Modelos carregados do Backend
  const [modelosList, setModelosList] = useState([]);
  const [novoModeloNome, setNovoModeloNome] = useState('');

  // Cidades e Estados para Fornecedor
  const [cidadesList, setCidadesList] = useState([]);
  const [estadosList, setEstadosList] = useState([]);

  // Quick Vendor Form State com Máscara e FOR_CID
  const [quickVendorForm, setQuickVendorForm] = useState({
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

  // Lista de grades do produto
  const [grades, setGrades] = useState([]);
  const [editingGradeIndex, setEditingGradeIndex] = useState(null);

  // Grade Form State (inclusão/edição rápida)
  const [gradeForm, setGradeForm] = useState({
    codigo: 0,
    tam: '',
    tam_nome: '',
    cor: 'UNICA',
    codbarra: '',
    quantidade: 0,
    valor: 0, // Preço à Vista
    valor_dinheiro: 0, // Preço Dinheiro
    valor_prazo: 0 // Preço a Prazo
  });

  // Tamanhos Globais para o seletor da grade
  const [tamanhosList, setTamanhosList] = useState([]);

  // Form State Geral do Produto
  const [form, setForm] = useState({
    codigo: '',
    nome: '',
    marca: '',
    fabricante: '',
    cod_fabricante: '',
    colecao: '',
    referencia: '',
    cor: '',
    codbarra: '',
    abc: 'N',
    local: 'GERAL',
    ult_alteracao: new Date().toISOString().split('T')[0],
    estado: 'ATIVO',
    um: 'UN',

    // Fornecedor e Classificação
    pro_for: 1,
    pro_gru: 1,
    grupo_id: 1,
    modelo_id: '',

    // 3 Preços do Produto & Custos
    pro_valor_dinheiro: 0,
    valorv: 0, // Preço à Vista
    pro_valorv_prazo: 0, // Preço a Prazo
    custo: 0, // Custo de Entrada / Compra
    custo_medio: 0,
    preco_sugerido: 0,
    quantidade: 0,
    quant_min: 0,
    dias_validade: 0,

    // PAF-ECF / Fiscais
    ncm: '6109.10.00',
    cfop: '5102',
    cest: '',
    gtin: 'SEM GTIN',
    codTotalizador: 1,
    pro_cod_fiscal: '',
    pro_fiscal_gerar: 'S',
    pro_emitir_negativo: 'N',
    balanca: 'N',

    // Imagem
    url_Imagem: ''
  });

  // Flag se o usuário digitou manualmente o nome customizado
  const [isNameManuallyEdited, setIsNameManuallyEdited] = useState(false);

  // Margem Calculada (%)
  const [margemCalculada, setMargemCalculada] = useState(0);

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

  // Função utilitária para sugestão inteligente de nome em CAIXA ALTA
  const buildSuggestedProductName = (gId, sgId, mId, marcaText) => {
    const grp = gruposList.find(g => Number(g.codigo) === Number(gId));
    const sub = subgruposList.find(s => Number(s.codigo) === Number(sgId));
    const mod = modelosList.find(m => Number(m.codigo) === Number(mId));

    const gNome = grp ? grp.nome.replace(/^#\d+\s*-\s*/, '').trim() : '';
    const sgNome = sub ? sub.nome.replace(/^#\d+\s*-\s*/, '').trim() : '';
    const mNome = mod ? mod.nome.replace(/^#\d+\s*-\s*/, '').trim() : '';
    const mrcNome = (marcaText || '').trim();

    const parts = [gNome, sgNome, mNome, mrcNome].filter(Boolean);
    return parts.join(' ').toUpperCase();
  };

  // Carregar lista de Grupos e Subgrupos caso não tenham sido passados
  const fetchGruposESubgrupos = async () => {
    try {
      const [gRes, sRes] = await Promise.all([
        api.get('/v1/grupos?limit=300').catch(() => ({ data: [] })),
        api.get('/v1/subgrupos?limit=500').catch(() => ({ data: [] }))
      ]);
      const gData = Array.isArray(gRes.data) ? gRes.data : (gRes.data?.data || []);
      const sData = Array.isArray(sRes.data) ? sRes.data : (sRes.data?.data || []);
      setGruposList(gData);
      setSubgruposList(sData);
      return { grupos: gData, subgrupos: sData };
    } catch (err) {
      console.warn('Erro ao carregar grupos e subgrupos:', err);
      return { grupos: [], subgrupos: [] };
    }
  };

  // Carregar lista de Fornecedores caso não tenha sido passada
  const fetchFornecedores = async () => {
    try {
      const res = await api.get('/v1/fornecedores?limit=300');
      const items = Array.isArray(res.data) ? res.data : (res.data?.data || []);
      setFornecedoresList(items);
      return items;
    } catch (err) {
      console.warn('Erro ao carregar fornecedores:', err);
      return [];
    }
  };

  // Carregar lista de Modelos
  const fetchModelos = async () => {
    try {
      const res = await api.get('/v1/modelos');
      const items = Array.isArray(res.data) ? res.data : (res.data?.data || []);
      setModelosList(items);
      return items;
    } catch (err) {
      console.warn('Erro ao carregar modelos:', err);
      return [];
    }
  };

  // Carregar Cidades e Estados
  const fetchCidadesEEstados = async () => {
    try {
      const [cRes, eRes] = await Promise.all([
        api.get('/v1/cidades?limit=300').catch(() => ({ data: [] })),
        api.get('/v1/estados').catch(() => ({ data: [] }))
      ]);
      const cItems = Array.isArray(cRes.data) ? cRes.data : (cRes.data?.data || []);
      const eItems = Array.isArray(eRes.data) ? eRes.data : (eRes.data?.data || []);
      setCidadesList(cItems);
      setEstadosList(eItems);
    } catch (err) {
      console.warn('Erro ao carregar cidades e estados:', err);
    }
  };

  // Buscar tamanhos disponíveis do banco de dados
  const fetchTamanhos = async () => {
    try {
      const res = await api.get('/v1/tamanhos?limit=300');
      const items = Array.isArray(res.data) ? res.data : (res.data?.data || []);
      setTamanhosList(items);
      if (items.length > 0 && !gradeForm.tam) {
        setGradeForm(prev => ({ ...prev, tam: items[0].codigo, tam_nome: items[0].tamanho || items[0].sigla }));
      }
      return items;
    } catch (err) {
      console.warn('Erro ao carregar tamanhos:', err);
      return [];
    }
  };

  // Buscar grades existentes do produto
  const fetchGrades = async (prodCode, loadedTamanhos = tamanhosList) => {
    if (!prodCode) return;
    try {
      let items = [];
      try {
        const resProd = await api.get(`/v1/grades/produto/${prodCode}`);
        if (Array.isArray(resProd.data)) items = resProd.data;
        else if (resProd.data?.data) items = resProd.data.data;
      } catch (e1) {
        const resAll = await api.get('/v1/grades?limit=500');
        const all = Array.isArray(resAll.data) ? resAll.data : (resAll.data?.data || []);
        items = all.filter(g => String(g.pro || g.gra_pro || g.produtoId) === String(prodCode));
      }

      const tList = (loadedTamanhos && loadedTamanhos.length > 0) ? loadedTamanhos : tamanhosList;
      const normalized = (items || []).map(g => {
        const tCod = Number(g.tam ?? g.gra_tam ?? g.tamanho?.codigo ?? 0);
        const matchTam = (tList || []).find(t => Number(t.codigo) === tCod);
        const tNome = g.tam_nome || (matchTam ? (matchTam.sigla || matchTam.tamanho) : (g.tamanho?.sigla || g.tamanho?.tamanho || `Tam #${tCod}`));
        const vV = Number(g.valor ?? g.gra_valor ?? 0);
        const vD = Number(g.valor_dinheiro ?? g.valorDinheiro ?? g.gra_valor_dinheiro ?? vV);
        const vP = Number(g.valor_prazo ?? g.valorPrazo ?? g.gra_valor_prazo ?? vV);
        const q = Number(g.quantidade ?? g.gra_quantidade ?? 0);

        return {
          codigo: Number(g.codigo ?? g.gra_codigo ?? 0),
          gra_codigo: Number(g.codigo ?? g.gra_codigo ?? 0),
          pro: Number(g.pro ?? g.gra_pro ?? prodCode),
          gra_pro: Number(g.pro ?? g.gra_pro ?? prodCode),
          tam: tCod,
          gra_tam: tCod,
          tam_nome: tNome,
          tamanho: matchTam || g.tamanho || { codigo: tCod, tamanho: tNome, sigla: tNome },
          cor: (g.cor || g.gra_cor || 'UNICA').toUpperCase(),
          gra_cor: (g.cor || g.gra_cor || 'UNICA').toUpperCase(),
          codbarra: g.codbarra || g.gra_codbarra || '',
          gra_codbarra: g.codbarra || g.gra_codbarra || '',
          quantidade: q,
          gra_quantidade: q,
          valor: vV,
          gra_valor: vV,
          valor_dinheiro: vD,
          valorDinheiro: vD,
          gra_valor_dinheiro: vD,
          valor_prazo: vP,
          valorPrazo: vP,
          gra_valor_prazo: vP
        };
      });

      setGrades(normalized);
    } catch (err) {
      console.warn('Erro ao carregar grades:', err);
    }
  };

  // Inicialização e Carga dos Dados
  useEffect(() => {
    const initData = async () => {
      let currentGrupos = gruposList;
      let currentSubgrupos = subgruposList;
      let currentForns = fornecedoresList;

      if (!currentGrupos || currentGrupos.length === 0 || !currentSubgrupos || currentSubgrupos.length === 0) {
        const gs = await fetchGruposESubgrupos();
        currentGrupos = gs.grupos;
        currentSubgrupos = gs.subgrupos;
      }

      if (!currentForns || currentForns.length === 0) {
        currentForns = await fetchFornecedores();
      }

      const [loadedTams, loadedMods] = await Promise.all([
        fetchTamanhos(),
        fetchModelos(),
        fetchCidadesEEstados()
      ]);

      if (productToEdit) {
        const prodId = productToEdit.codigo || productToEdit.id || productToEdit.pro_codigo;
        const gCode = Number(productToEdit.pro_gru || productToEdit.subgrupoId || productToEdit.gru || 1);
        const sg = (currentSubgrupos || []).find(s => Number(s.codigo) === gCode);
        const gId = sg ? Number(sg.g1) : (Number(productToEdit.grupo_id || productToEdit.grupo || 1));

        // Vinculação robusta de MODELO (pro_mar, mar, modelo, modelo_id)
        const rawModelo = productToEdit.modelo_id ?? productToEdit.modelo ?? productToEdit.pro_mar ?? productToEdit.mar ?? '';
        const modeloIdFinal = (rawModelo !== '' && rawModelo !== null && rawModelo !== undefined && Number(rawModelo) > 0) ? Number(rawModelo) : '';

        const vVista = Number(productToEdit.valorv || productToEdit.valor || 0);
        const vDinheiro = Number(productToEdit.pro_valor_dinheiro || productToEdit.valor_dinheiro || vVista);
        const vPrazo = Number(productToEdit.pro_valorv_prazo || productToEdit.valorv_prazo || productToEdit.valorp || vVista);
        const custoEntrada = Number(productToEdit.custo || productToEdit.valorc || productToEdit.valorf || 0);

        setForm({
          codigo: prodId,
          nome: (productToEdit.nome || '').toUpperCase(),
          marca: (productToEdit.marca || productToEdit.fabricante || '').toUpperCase(),
          fabricante: (productToEdit.fabricante || productToEdit.marca || '').toUpperCase(),
          cod_fabricante: productToEdit.cod_fabricante || productToEdit.codigo || '',
          colecao: (productToEdit.colecao || '').toUpperCase(),
          referencia: productToEdit.referencia || '',
          cor: (productToEdit.cor || '').toUpperCase(),
          codbarra: productToEdit.codbarra || '',
          abc: productToEdit.abc || 'N',
          local: productToEdit.local || 'GERAL',
          ult_alteracao: productToEdit.ult_alteracao || new Date().toISOString().split('T')[0],
          estado: productToEdit.estado || 'ATIVO',
          um: productToEdit.um || productToEdit.embalagem || 'UN',

          pro_for: productToEdit.pro_for || productToEdit.fornecedorId || currentForns[0]?.codigo || 1,
          pro_gru: gCode,
          grupo_id: gId,
          modelo_id: modeloIdFinal,

          pro_valor_dinheiro: vDinheiro,
          valorv: vVista,
          pro_valorv_prazo: vPrazo,
          custo: custoEntrada,
          custo_medio: Number(productToEdit.custo_medio || productToEdit.valorcm || 0),
          preco_sugerido: Number(productToEdit.preco_sugerido || productToEdit.valors || 0),
          quantidade: Number(productToEdit.quantidade || 0),
          quant_min: Number(productToEdit.quant_min || productToEdit.quantidadem || 0),
          dias_validade: Number(productToEdit.dias_validade || 0),

          ncm: productToEdit.ncm || '6109.10.00',
          cfop: productToEdit.cfop || '5102',
          cest: productToEdit.cest || '',
          gtin: productToEdit.gtin || productToEdit.codbarra || 'SEM GTIN',
          codTotalizador: Number(productToEdit.codTotalizador || productToEdit.totalizadorId || 1),
          pro_cod_fiscal: productToEdit.pro_cod_fiscal || productToEdit.proCodFiscal || '',
          pro_fiscal_gerar: productToEdit.pro_fiscal_gerar || productToEdit.proFiscalGerar || 'S',
          pro_emitir_negativo: productToEdit.pro_emitir_negativo || productToEdit.proEmitirNegativo || 'N',
          balanca: productToEdit.balanca || 'N',

          url_Imagem: productToEdit.url_Imagem || ''
        });

        setIsNameManuallyEdited(true);

        if (custoEntrada > 0 && vVista > 0) {
          setMargemCalculada(((vVista - custoEntrada) / custoEntrada) * 100);
        } else {
          setMargemCalculada(0);
        }

        await fetchGrades(prodId, loadedTams);
        setMode('browse');
      } else {
        setForm(prev => ({
          ...prev,
          codigo: '',
          cod_fabricante: '',
          codbarra: '',
          pro_for: currentForns[0]?.codigo || 1,
          pro_gru: currentSubgrupos[0]?.codigo || 1,
          grupo_id: currentGrupos[0]?.codigo || 1,
          modelo_id: ''
        }));
        setIsNameManuallyEdited(false);
        setGrades([]);
        setMode('insert');
      }
    };

    initData();
  }, [productToEdit]);

  // Handler para atualizar campos de classificação e recalcular nome sugerido automaticamente
  const handleClassificationChange = (field, value) => {
    const updated = { ...form, [field]: value };

    // Se for alteração de grupo, ajusta o primeiro subgrupo
    if (field === 'grupo_id') {
      const gId = Number(value);
      const firstSg = (subgruposList || []).find(s => Number(s.g1) === gId);
      if (firstSg) updated.pro_gru = firstSg.codigo;
    }

    // Se o usuário ainda não digitou um nome fixo manual ou se o nome estiver vazio, sugere automaticamente
    if (!isNameManuallyEdited || !form.nome.trim()) {
      const suggested = buildSuggestedProductName(
        field === 'grupo_id' ? value : updated.grupo_id,
        field === 'pro_gru' ? value : updated.pro_gru,
        field === 'modelo_id' ? value : updated.modelo_id,
        field === 'marca' || field === 'fabricante' ? value : updated.marca
      );
      if (suggested) {
        updated.nome = suggested;
      }
    }

    setForm(updated);
  };

  // Forçar aplicação da sugestão de nome
  const handleApplySuggestedName = () => {
    const suggested = buildSuggestedProductName(form.grupo_id, form.pro_gru, form.modelo_id, form.marca || form.fabricante);
    if (suggested) {
      setForm(prev => ({ ...prev, nome: suggested }));
      setIsNameManuallyEdited(false);
      setSuccessMsg(`Nome sugerido aplicado: "${suggested}"`);
      setTimeout(() => setSuccessMsg(''), 3000);
    }
  };

  // Recalcula a margem de lucro ao alterar custo ou preço à vista
  const handlePrecoOuCustoChange = (field, value) => {
    const numVal = parseFloat(value) || 0;
    const updated = { ...form, [field]: numVal };

    if (field === 'valorv') {
      if (!updated.pro_valor_dinheiro || updated.pro_valor_dinheiro === 0) {
        updated.pro_valor_dinheiro = numVal;
      }
      if (!updated.pro_valorv_prazo || updated.pro_valorv_prazo === 0) {
        updated.pro_valorv_prazo = numVal;
      }
    }

    const c = field === 'custo' ? numVal : Number(updated.custo || 0);
    const v = field === 'valorv' ? numVal : Number(updated.valorv || 0);

    if (c > 0 && v > 0) {
      setMargemCalculada(((v - c) / c) * 100);
    } else {
      setMargemCalculada(0);
    }

    setForm(updated);
  };

  // Atalhos de Teclado (F2, F4, F7, F10, Ctrl+S, ESC)
  useEffect(() => {
    const handleKeyDown = (e) => {
      // Evita atalhos se algum modal secundário estiver aberto
      if (showGradesModal || showGruposSubgruposModal || showQuickVendorModal || showQuickModeloModal) {
        return;
      }

      // ESC: Fechar
      if (e.key === 'Escape') {
        e.preventDefault();
        onClose();
        return;
      }

      // Ctrl + S: Salvar
      if ((e.ctrlKey || e.metaKey) && (e.key === 's' || e.key === 'S')) {
        e.preventDefault();
        handleSave();
        return;
      }

      // F2: Novo Produto
      if (e.key === 'F2') {
        e.preventDefault();
        // F2: Limpar / Novo Formulário
        setForm({
          codigo: '',
          nome: '',
          marca: '',
          fabricante: '',
          cod_fabricante: '',
          colecao: '',
          referencia: '',
          cor: '',
          codbarra: '',
          abc: 'N',
          local: 'GERAL',
          ult_alteracao: new Date().toISOString().split('T')[0],
          estado: 'ATIVO',
          um: 'UN',
          pro_for: fornecedores[0]?.codigo || 1,
          pro_gru: subgrupos[0]?.codigo || 1,
          grupo_id: grupos[0]?.codigo || 1,
          modelo_id: '',
          pro_valor_dinheiro: 0,
          valorv: 0,
          pro_valorv_prazo: 0,
          custo: 0,
          custo_medio: 0,
          preco_sugerido: 0,
          quantidade: 0,
          quant_min: 0,
          dias_validade: 0,
          ncm: '6109.10.00',
          cfop: '5102',
          cest: '',
          gtin: 'SEM GTIN',
          codTotalizador: 1,
          pro_cod_fiscal: '',
          pro_fiscal_gerar: 'S',
          pro_emitir_negativo: 'N',
          balanca: 'N',
          url_Imagem: ''
        });
        setGrades([]);
        setIsNameManuallyEdited(false);
        setMode('insert');
        setActiveTab('geral');
        setSuccessMsg('Formulário pronto para novo cadastro!');
        setTimeout(() => setSuccessMsg(''), 3000);
        return;
      }

      // F4: Gerenciar Grupos/Subgrupos
      if (e.key === 'F4') {
        e.preventDefault();
        setShowGruposSubgruposModal(true);
        return;
      }

      // F7: Novo Fornecedor Rápido
      if (e.key === 'F7') {
        e.preventDefault();
        setShowQuickVendorModal(true);
        return;
      }

      // F10: Gerar EANs para as Grades
      if (e.key === 'F10') {
        e.preventDefault();
        handleGerarCodigosBarrasGrades();
        return;
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onClose, showGradesModal, showGruposSubgruposModal, showQuickVendorModal, showQuickModeloModal, form, grades]);

  // Gerador de EAN13 para o Produto Principal
  const handleGerarEanPrincipal = () => {
    const codNum = Number(form.codigo) || Math.floor(Math.random() * 90000) + 10000;
    const base = `789${String(codNum).padStart(9, '0')}`;
    let sum = 0;
    for (let i = 0; i < 12; i++) {
      sum += parseInt(base[i], 10) * (i % 2 === 0 ? 1 : 3);
    }
    const checkDigit = (10 - (sum % 10)) % 10;
    const ean = `${base.slice(0, 12)}${checkDigit}`;
    setForm(prev => ({ ...prev, codbarra: ean, gtin: ean }));
  };

  // F10: Gerador de Códigos de Barras EAN13 para todas as Grades
  const handleGerarCodigosBarrasGrades = () => {
    if (grades.length === 0) {
      toast.warning('Nenhuma grade cadastrada para gerar códigos de barras.');
      return;
    }
    const prodCod = Number(form.codigo) || 1;
    const updated = grades.map((g, idx) => {
      const tamCod = Number(g.tam || g.gra_tam || (idx + 1));
      const base = `789${String(prodCod).padStart(6, '0')}${String(tamCod).padStart(3, '0')}`;
      let sum = 0;
      for (let i = 0; i < 12; i++) {
        sum += parseInt(base[i], 10) * (i % 2 === 0 ? 1 : 3);
      }
      const checkDigit = (10 - (sum % 10)) % 10;
      return {
        ...g,
        codbarra: `${base.slice(0, 12)}${checkDigit}`,
        gra_codbarra: `${base.slice(0, 12)}${checkDigit}`
      };
    });
    setGrades(updated);
    setSuccessMsg('Códigos de barras EAN-13 gerados com sucesso para todas as grades (F10)!');
    setTimeout(() => setSuccessMsg(''), 4000);
  };

  // Gerador Rápido e Preciso de Grades Baseado nos TAMANHOS Reais do Banco
  const handleGerarGradeAutomatica = (tipo) => {
    if (tamanhosList.length === 0) {
      toast.warning('Nenhum tamanho cadastrado no sistema central.');
      return;
    }

    let tamanhosGerar = [];

    if (tipo === 'letras') {
      // Prioriza tamanhos em letras (PP, P, M, G, GG, XG, etc.) cadastrados no banco
      const letrasOrdem = ['PP', 'P', 'M', 'G', 'GG', 'XG', 'XGG', 'EG', 'EGG', 'UN'];
      tamanhosGerar = tamanhosList
        .filter(t => {
          const s = (t.sigla || t.tamanho || '').trim().toUpperCase();
          return isNaN(Number(s));
        })
        .sort((a, b) => {
          const sA = (a.sigla || a.tamanho || '').trim().toUpperCase();
          const sB = (b.sigla || b.tamanho || '').trim().toUpperCase();
          const idxA = letrasOrdem.indexOf(sA);
          const idxB = letrasOrdem.indexOf(sB);
          if (idxA !== -1 && idxB !== -1) return idxA - idxB;
          if (idxA !== -1) return -1;
          if (idxB !== -1) return 1;
          return sA.localeCompare(sB);
        });
      if (tamanhosGerar.length === 0) tamanhosGerar = tamanhosList.slice(0, 6);
    } else if (tipo === 'calcados' || tipo === 'numeros') {
      // Prioriza tamanhos numéricos (34, 35, 36, 37, 38, 39, 40, 42, 44, 46, 48) cadastrados no banco
      tamanhosGerar = tamanhosList
        .filter(t => {
          const s = (t.sigla || t.tamanho || '').trim();
          return !isNaN(Number(s));
        })
        .sort((a, b) => Number(a.sigla || a.tamanho) - Number(b.sigla || b.tamanho));
      if (tamanhosGerar.length === 0) tamanhosGerar = tamanhosList;
    } else {
      tamanhosGerar = [...tamanhosList].sort((a, b) => {
        const numA = Number(a.sigla || a.tamanho);
        const numB = Number(b.sigla || b.tamanho);
        if (!isNaN(numA) && !isNaN(numB)) return numA - numB;
        return (a.sigla || a.tamanho || '').localeCompare(b.sigla || b.tamanho || '');
      });
    }

    const prodCod = Number(form.codigo) || 1;
    const vVista = Number(form.valorv || 0);
    const vDinheiro = Number(form.pro_valor_dinheiro || vVista);
    const vPrazo = Number(form.pro_valorv_prazo || vVista);

    const newGrades = tamanhosGerar.map((t, idx) => {
      const tamId = Number(t.codigo || (idx + 1));
      const sigla = (t.sigla || t.tamanho || String(tamId)).toUpperCase();
      const base = `789${String(prodCod).padStart(6, '0')}${String(tamId).padStart(3, '0')}`;
      let sum = 0;
      for (let i = 0; i < 12; i++) {
        sum += parseInt(base[i], 10) * (i % 2 === 0 ? 1 : 3);
      }
      const checkDigit = (10 - (sum % 10)) % 10;

      const displayNome = t.sigla && t.tamanho && t.sigla.toUpperCase() !== t.tamanho.toUpperCase()
        ? `${t.sigla} - ${t.tamanho}`
        : (t.sigla || t.tamanho || sigla);

      return {
        codigo: 0,
        gra_codigo: 0,
        pro: prodCod,
        gra_pro: prodCod,
        tam: tamId,
        gra_tam: tamId,
        tam_nome: displayNome,
        tamanho: t,
        cor: form.cor || 'UNICA',
        gra_cor: form.cor || 'UNICA',
        codbarra: `${base.slice(0, 12)}${checkDigit}`,
        gra_codbarra: `${base.slice(0, 12)}${checkDigit}`,
        quantidade: 0,
        gra_quantidade: 0,
        valor: vVista,
        gra_valor: vVista,
        valor_dinheiro: vDinheiro,
        valorDinheiro: vDinheiro,
        gra_valor_dinheiro: vDinheiro,
        valor_prazo: vPrazo,
        valorPrazo: vPrazo,
        gra_valor_prazo: vPrazo
      };
    });

    setGrades(newGrades);
    setSuccessMsg(`Grade gerada com ${newGrades.length} variações baseadas nos tamanhos cadastrados!`);
    setTimeout(() => setSuccessMsg(''), 4000);
  };

  // Salvar Rápido de Novo Modelo
  const handleSaveQuickModelo = async (e) => {
    e.preventDefault();
    if (!novoModeloNome.trim()) return;
    try {
      const res = await api.post('/v1/modelos', {
        codigo: 0,
        nome: novoModeloNome.trim().toUpperCase()
      });
      const created = res.data;
      await fetchModelos();
      setForm(prev => ({ ...prev, modelo_id: created.codigo }));
      setShowQuickModeloModal(false);
      setNovoModeloNome('');
      setSuccessMsg(`Modelo "${created.nome}" cadastrado com sucesso!`);
      setTimeout(() => setSuccessMsg(''), 3000);
    } catch (err) {
      toast.error('Erro ao salvar modelo: ' + (err.response?.data?.error || err.message));
    }
  };

  // Salvar Rápido de Novo Fornecedor com CNPJ Mask e FOR_CID
  const handleSaveQuickVendor = async (e) => {
    e.preventDefault();
    if (!quickVendorForm.nome.trim()) {
      toast.warning('Informe o Nome / Razão Social do fornecedor.');
      return;
    }
    try {
      const payload = {
        codigo: 0,
        nome: quickVendorForm.nome.toUpperCase(),
        razao_social: quickVendorForm.nome.toUpperCase(),
        fantasia: quickVendorForm.fantasia.toUpperCase(),
        cnpj_cpf: quickVendorForm.cnpj,
        insc_estadual: quickVendorForm.inscricao,
        fone: quickVendorForm.telefone,
        email: quickVendorForm.email,
        endereco: quickVendorForm.endereco,
        bairro: quickVendorForm.bairro,
        cid: Number(quickVendorForm.for_cid) || 0,
        for_cid: Number(quickVendorForm.for_cid) || 0,
        cidade: quickVendorForm.cidade,
        uf: quickVendorForm.uf,
        contato: quickVendorForm.contato
      };

      const res = await api.post('/v1/fornecedores', payload);
      const created = res.data;
      setForm(prev => ({
        ...prev,
        pro_for: created.codigo || created.FOR_CODIGO,
        fabricante: prev.fabricante || created.nome || created.razao_social || ''
      }));
      setShowQuickVendorModal(false);
      setSuccessMsg(`Fornecedor #${created.codigo} cadastrado com sucesso!`);
      setTimeout(() => setSuccessMsg(''), 3000);
    } catch (err) {
      toast.error('Erro ao salvar fornecedor: ' + (err.response?.data?.error || err.message));
    }
  };

  // Adicionar / Salvar Item na Grade
  const handleAddOrUpdateGradeItem = () => {
    if (!gradeForm.tam) {
      toast.warning('Selecione o tamanho.');
      return;
    }
    const matchTam = tamanhosList.find(t => 
      Number(t.codigo) === Number(gradeForm.tam) ||
      (t.sigla && String(t.sigla).trim().toUpperCase() === String(gradeForm.tam_nome || gradeForm.tam).trim().toUpperCase())
    );
    const tamNome = matchTam 
      ? (matchTam.sigla && matchTam.tamanho && matchTam.sigla.toUpperCase() !== matchTam.tamanho.toUpperCase() 
          ? `${matchTam.sigla} - ${matchTam.tamanho}` 
          : (matchTam.sigla || matchTam.tamanho))
      : (gradeForm.tam_nome || `Tam #${gradeForm.tam}`);

    const prodCod = Number(form.codigo) || 1;
    const finalTamId = matchTam ? Number(matchTam.codigo) : Number(gradeForm.tam);
    let codbarraFinal = gradeForm.codbarra;
    if (!codbarraFinal) {
      const base = `789${String(prodCod).padStart(6, '0')}${String(finalTamId).padStart(3, '0')}`;
      let sum = 0;
      for (let i = 0; i < 12; i++) sum += parseInt(base[i], 10) * (i % 2 === 0 ? 1 : 3);
      const checkDigit = (10 - (sum % 10)) % 10;
      codbarraFinal = `${base.slice(0, 12)}${checkDigit}`;
    }

    const itemGrade = {
      codigo: gradeForm.codigo || 0,
      gra_codigo: gradeForm.codigo || 0,
      pro: prodCod,
      gra_pro: prodCod,
      tam: finalTamId,
      gra_tam: finalTamId,
      tam_nome: tamNome,
      tamanho: matchTam || { codigo: finalTamId, tamanho: tamNome, sigla: tamNome },
      cor: (gradeForm.cor || form.cor || 'UNICA').toUpperCase(),
      gra_cor: (gradeForm.cor || form.cor || 'UNICA').toUpperCase(),
      codbarra: codbarraFinal,
      gra_codbarra: codbarraFinal,
      quantidade: Number(gradeForm.quantidade) || 0,
      gra_quantidade: Number(gradeForm.quantidade) || 0,
      valor: Number(gradeForm.valor) || Number(form.valorv) || 0,
      gra_valor: Number(gradeForm.valor) || Number(form.valorv) || 0,
      valor_dinheiro: Number(gradeForm.valor_dinheiro) || Number(form.pro_valor_dinheiro) || Number(form.valorv) || 0,
      valorDinheiro: Number(gradeForm.valor_dinheiro) || Number(form.pro_valor_dinheiro) || Number(form.valorv) || 0,
      gra_valor_dinheiro: Number(gradeForm.valor_dinheiro) || Number(form.pro_valor_dinheiro) || Number(form.valorv) || 0,
      valor_prazo: Number(gradeForm.valor_prazo) || Number(form.pro_valorv_prazo) || Number(form.valorv) || 0,
      valorPrazo: Number(gradeForm.valor_prazo) || Number(form.pro_valorv_prazo) || Number(form.valorv) || 0,
      gra_valor_prazo: Number(gradeForm.valor_prazo) || Number(form.pro_valorv_prazo) || Number(form.valorv) || 0
    };

    if (editingGradeIndex !== null) {
      const updated = [...grades];
      updated[editingGradeIndex] = itemGrade;
      setGrades(updated);
      setEditingGradeIndex(null);
    } else {
      setGrades(prev => [...prev, itemGrade]);
    }

    // Reset Form da Grade
    setGradeForm({
      codigo: 0,
      tam: tamanhosList[0]?.codigo || '',
      tam_nome: '',
      cor: form.cor || 'UNICA',
      codbarra: '',
      quantidade: 0,
      valor: Number(form.valorv) || 0,
      valor_dinheiro: Number(form.pro_valor_dinheiro) || Number(form.valorv) || 0,
      valor_prazo: Number(form.pro_valorv_prazo) || Number(form.valorv) || 0
    });
  };

  const handleEditGradeItem = (idx) => {
    const item = grades[idx];
    setEditingGradeIndex(idx);
    
    const matchTam = tamanhosList.find(t => 
      Number(t.codigo) === Number(item.tam || item.gra_tam) ||
      (t.sigla && String(t.sigla).trim().toUpperCase() === String(item.tam_nome || item.tam).trim().toUpperCase())
    );

    const tamId = matchTam ? matchTam.codigo : (item.tam || item.gra_tam || (item.tamanho?.codigo || ''));
    const tamNome = item.tam_nome || (matchTam ? (matchTam.sigla || matchTam.tamanho) : (item.tamanho?.sigla || item.tamanho?.tamanho || ''));

    setGradeForm({
      codigo: item.codigo || item.gra_codigo || 0,
      tam: tamId,
      tam_nome: tamNome,
      cor: item.cor || item.gra_cor || 'UNICA',
      codbarra: item.codbarra || item.gra_codbarra || '',
      quantidade: item.quantidade ?? item.gra_quantidade ?? 0,
      valor: item.valor ?? item.gra_valor ?? Number(form.valorv) ?? 0,
      valor_dinheiro: item.valor_dinheiro ?? item.valorDinheiro ?? item.gra_valor_dinheiro ?? Number(form.pro_valor_dinheiro) ?? 0,
      valor_prazo: item.valor_prazo ?? item.valorPrazo ?? item.gra_valor_prazo ?? Number(form.pro_valorv_prazo) ?? 0
    });
  };

  const handleDeleteGradeItem = (idx) => {
    setGrades(prev => prev.filter((_, i) => i !== idx));
    if (editingGradeIndex === idx) setEditingGradeIndex(null);
  };

  // Salvar Produto Completo
  const handleSave = async () => {
    if (!form.nome.trim()) {
      toast.warning('Por favor, informe o Nome do Produto.');
      setActiveTab('geral');
      return;
    }

    setLoading(true);
    setErrorMsg('');
    try {
      const vVista = Number(form.valorv) || 0;
      const vDinheiro = Number(form.pro_valor_dinheiro) || vVista;
      const vPrazo = Number(form.pro_valorv_prazo) || vVista;

      const payload = {
        codigo: Number(form.codigo) || 0,
        nome: form.nome.toUpperCase(),
        marca: (form.marca || form.fabricante || 'GENERICA').toUpperCase(),
        fabricante: (form.fabricante || form.marca || 'GENERICA').toUpperCase(),
        cod_fabricante: form.cod_fabricante || String(form.codigo || ''),
        colecao: (form.colecao || '').toUpperCase(),
        referencia: form.referencia || '',
        cor: (form.cor || '').toUpperCase(),
        codbarra: form.codbarra,
        abc: form.abc || 'N',
        local: form.local || 'GERAL',
        estado: form.estado || 'ATIVO',
        embalagem: form.um || 'UN',
        um: 1,

        pro_for: Number(form.pro_for) || 1,
        forCodigo: Number(form.pro_for) || 1,
        pro_gru: Number(form.pro_gru) || 1,
        gru: Number(form.pro_gru) || 1,
        mar: Number(form.modelo_id) || 0,
        pro_mar: Number(form.modelo_id) || 0,
        modelo: Number(form.modelo_id) || 0,
        modelo_id: Number(form.modelo_id) || 0,

        // 3 Preços do Produto
        valorv: vVista,
        valor_dinheiro: vDinheiro,
        pro_valor_dinheiro: vDinheiro,
        valorv_prazo: vPrazo,
        pro_valorv_prazo: vPrazo,

        // Custos
        custo: Number(form.custo) || 0,
        valorc: Number(form.custo) || 0,
        valorf: Number(form.custo) || 0,
        valorcm: Number(form.custo_medio) || Number(form.custo) || 0,
        valors: Number(form.preco_sugerido) || (vVista * 1.2),
        preco_sugerido: Number(form.preco_sugerido) || (vVista * 1.2),

        // Estoque
        quantidade: Number(form.quantidade) || 0,
        quantidadem: Number(form.quant_min) || 0,
        dias_validade: Number(form.dias_validade) || 0,

        // Fiscais
        ncm: form.ncm || '6109.10.00',
        cfop: form.cfop || '5102',
        cest: form.cest || '',
        gtin: form.gtin || form.codbarra || 'SEM GTIN',
        codTotalizador: Number(form.codTotalizador) || 1,
        pro_cod_fiscal: Number(form.pro_cod_fiscal) || 0,
        pro_fiscal_gerar: form.pro_fiscal_gerar || 'S',
        pro_emitir_negativo: form.pro_emitir_negativo || 'N',
        balanca: form.balanca || 'N',

        url_Imagem: form.url_Imagem || '',
        cadastrar: 'S'
      };

      let savedProd;
      if (mode === 'edit' || (productToEdit && mode !== 'insert')) {
        const res = await api.put('/v1/produtos', payload);
        savedProd = res.data;
      } else {
        const res = await api.post('/v1/produtos', payload);
        savedProd = res.data;
      }

      const finalProdCod = savedProd?.codigo || Number(form.codigo) || 1;

      // Salva as Grades do Produto via Lote
      if (grades.length > 0) {
        const gradesPayload = {
          itens: grades.map(g => {
            const itemTam = Number(g.tam || g.gra_tam || g.tamanho?.codigo || 1);
            const itemVista = Number(g.valor ?? g.gra_valor ?? vVista);
            const itemDin = Number(g.valor_dinheiro ?? g.valorDinheiro ?? g.gra_valor_dinheiro ?? vDinheiro);
            const itemPrz = Number(g.valor_prazo ?? g.valorPrazo ?? g.gra_valor_prazo ?? vPrazo);
            const itemQtd = Number(g.quantidade ?? g.gra_quantidade ?? 0);
            const itemCodBarra = g.codbarra || g.gra_codbarra || form.codbarra || '';
            const itemCor = (g.cor || g.gra_cor || form.cor || 'UNICA').toUpperCase();

            return {
              codigo: Number(g.codigo || g.gra_codigo || 0),
              gra_codigo: Number(g.codigo || g.gra_codigo || 0),
              pro: Number(finalProdCod),
              gra_pro: Number(finalProdCod),
              tam: itemTam,
              gra_tam: itemTam,
              cor: itemCor,
              gra_cor: itemCor,
              codbarra: itemCodBarra,
              gra_codbarra: itemCodBarra,
              quantidade: itemQtd,
              gra_quantidade: itemQtd,
              valor: itemVista,
              gra_valor: itemVista,
              valor_dinheiro: itemDin,
              valorDinheiro: itemDin,
              gra_valor_dinheiro: itemDin,
              valor_prazo: itemPrz,
              valorPrazo: itemPrz,
              gra_valor_prazo: itemPrz,
              cadastrar: 'S',
              gra_cadastrar: 'S'
            };
          })
        };

        try {
          await api.post('/v1/grades/lote', gradesPayload);
        } catch (errGrades) {
          try {
            await api.post('/v1/grades/emLote', gradesPayload);
          } catch (e2) {
            for (const g of gradesPayload.itens) {
              await api.post('/v1/grades', g).catch(() => { });
            }
          }
        }
      }

      setSuccessMsg(`Produto "${form.nome}" salvo com sucesso!`);
      if (onSaveSuccess) onSaveSuccess();
      setTimeout(() => {
        onClose();
      }, 1000);
    } catch (err) {
      console.error('Erro ao salvar produto:', err);
      setErrorMsg('Erro ao salvar produto: ' + (err.response?.data?.error || err.message));
    } finally {
      setLoading(false);
    }
  };

  return createPortal(
    <div className="product-form-modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}>
      <div className="product-form-modal-container glass">

        {/* CABEÇALHO DO MODAL */}
        <div className="product-modal-header">
          <div className="product-modal-title-group">
            <div className="product-modal-icon-badge">
              <Package size={22} color="#ffffff" />
            </div>
            <div>
              <h3>{mode === 'insert' ? 'Novo Cadastro de Produto' : `Produto #${form.codigo} - ${form.nome || 'Edição'}`}</h3>
              <span className="product-modal-subtitle">Padrão PDV Completo • Modelos & Marcas • Matriz de Grades & Fiscal</span>
            </div>
          </div>

          <div className="product-modal-header-actions">
            <button className="product-modal-close" onClick={onClose} title="Fechar (ESC)"><X size={20} /></button>
          </div>
        </div>

        {/* MENSAGENS DE ALERTA */}
        {successMsg && (
          <div className="product-alert success">
            <CheckCircle2 size={18} /> <span>{successMsg}</span>
          </div>
        )}
        {errorMsg && (
          <div className="product-alert error">
            <AlertCircle size={18} /> <span>{errorMsg}</span>
          </div>
        )}

        {/* BARRA DE NAVEGAÇÃO POR ABAS */}
        <div className="product-modal-tabs">
          <button
            type="button"
            className={`product-tab-btn ${activeTab === 'geral' ? 'active' : ''}`}
            onClick={() => setActiveTab('geral')}
          >
            <Layers size={17} /> Dados Gerais
          </button>

          <button
            type="button"
            className={`product-tab-btn ${activeTab === 'precos' ? 'active' : ''}`}
            onClick={() => setActiveTab('precos')}
          >
            <DollarSign size={17} /> Estoque & 3 Preços
          </button>

          <button
            type="button"
            className={`product-tab-btn ${activeTab === 'imagens' ? 'active' : ''}`}
            onClick={() => setActiveTab('imagens')}
          >
            <ImageIcon size={17} /> Imagens
          </button>

          <button
            type="button"
            className={`product-tab-btn ${activeTab === 'fiscal' ? 'active' : ''}`}
            onClick={() => setActiveTab('fiscal')}
          >
            <ShieldCheck size={17} /> Outros & Fiscal
          </button>
        </div>

        {/* CONTEÚDO DO FORMULÁRIO */}
        <div className="product-modal-body">

          {/* ========================================================= */}
          {/* ABA 1: DADOS GERAIS                                       */}
          {/* ========================================================= */}
          {activeTab === 'geral' && (
            <div className="product-tab-content">

              {/* CLASSIFICAÇÃO HIERÁRQUICA, MODELOS, MARCA & FORNECEDOR */}
              <div className="product-section-card">
                <div className="product-section-title" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Layers size={16} color="#2563eb" /> Classificação & Fornecedor
                  </div>
                  <div style={{ display: 'flex', gap: '0.5rem' }}>
                    <button
                      type="button"
                      className="btn-secondary small"
                      onClick={() => setShowGruposSubgruposModal(true)}
                      title="Atalho F4: Gerenciar Grupos e Subgrupos"
                    >
                      <FolderPlus size={14} /> <kbd style={{ marginRight: '4px', fontSize: '0.68rem', padding: '1px 4px', background: '#f8fafc', border: '1px solid rgba(0,0,0,0.12)', borderBottom: '2px solid rgba(0,0,0,0.18)', borderRadius: '3px' }}>F4</kbd> Grupos/Sub
                    </button>
                    <button
                      type="button"
                      className="btn-secondary small"
                      onClick={() => setShowQuickVendorModal(true)}
                      title="Atalho F7: Cadastrar Novo Fornecedor Rápido"
                      style={{ color: '#ea580c', borderColor: '#fed7aa', background: '#fff7ed' }}
                    >
                      <UserPlus size={14} /> <kbd style={{ marginRight: '4px', fontSize: '0.68rem', padding: '1px 4px', background: '#f8fafc', border: '1px solid rgba(0,0,0,0.12)', borderBottom: '2px solid rgba(0,0,0,0.18)', borderRadius: '3px' }}>F7</kbd> + Fornecedor
                    </button>
                  </div>
                </div>

                <div className="product-row-classification">

                  {/* GRUPO */}
                  <div className="form-group">
                    <label>Grupo *</label>
                    <select
                      value={form.grupo_id}
                      onChange={(e) => handleClassificationChange('grupo_id', Number(e.target.value))}
                    >
                      {gruposList.map(g => (
                        <option key={g.codigo} value={g.codigo}>#{g.codigo} - {g.nome}</option>
                      ))}
                    </select>
                  </div>

                  {/* SUBGRUPO */}
                  <div className="form-group">
                    <label>Subgrupo *</label>
                    <select
                      value={form.pro_gru}
                      onChange={(e) => handleClassificationChange('pro_gru', Number(e.target.value))}
                    >
                      {subgruposList
                        .filter(s => !form.grupo_id || Number(s.g1) === Number(form.grupo_id))
                        .map(s => (
                          <option key={s.codigo} value={s.codigo}>#{s.codigo} - {s.nome}</option>
                        ))}
                    </select>
                  </div>

                  {/* MODELO (AO LADO DE SUBGRUPO) */}
                  <div className="form-group">
                    <label style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span>Modelo</span>
                      <button
                        type="button"
                        onClick={() => setShowQuickModeloModal(true)}
                        style={{ background: 'none', border: 'none', color: 'var(--accent)', cursor: 'pointer', padding: 0, fontSize: '0.75rem', fontWeight: 700 }}
                        title="Adicionar Novo Modelo"
                      >
                        + Novo
                      </button>
                    </label>
                    <select
                      value={form.modelo_id || ''}
                      onChange={(e) => handleClassificationChange('modelo_id', e.target.value ? Number(e.target.value) : '')}
                    >
                      <option value="">-- Selecione o Modelo --</option>
                      {modelosList.map(m => (
                        <option key={m.codigo} value={m.codigo}>
                          {m.nome}
                        </option>
                      ))}
                    </select>
                  </div>

                  {/* MARCA / FABRICANTE */}
                  <div className="form-group">
                    <label>Marca / Fabricante</label>
                    <input
                      type="text"
                      value={form.marca || form.fabricante}
                      onChange={(e) => {
                        const val = e.target.value.toUpperCase();
                        handleClassificationChange('marca', val);
                      }}
                      placeholder="Ex: MOONCITY, NIKKE"
                      style={{ textTransform: 'uppercase' }}
                    />
                  </div>

                  {/* FORNECEDOR PRINCIPAL */}
                  <div className="form-group" style={{ gridColumn: 'span 2' }}>
                    <label>Fornecedor Principal *</label>
                    <LookupSelect
                      value={form.pro_for}
                      displayValue={
                        form.pro_for
                          ? `#${form.pro_for} - ${fornecedores.find(f => Number(f.codigo) === Number(form.pro_for))?.nome || 'Fornecedor'}`
                          : ''
                      }
                      placeholder="Buscar Fornecedor..."
                      title="Selecionar Fornecedor Principal"
                      subtitle="Busca paginada por Razão Social, Fantasia, CNPJ ou Código"
                      icon={Package}
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
                        { key: 'cnpj', label: 'CNPJ / CPF', render: (f) => <code>{maskCnpjCpf(f.cnpj || f.cnpj_cpf || f.cpf_cnpj || '') || '-'}</code> },
                        { key: 'cidade', label: 'Cidade / UF', render: (f) => `${f.cidade || ''} - ${f.uf || ''}` }
                      ]}
                      onSelect={(forn) => {
                        setForm(prev => ({
                          ...prev,
                          pro_for: Number(forn.codigo),
                          fabricante: prev.fabricante || forn.nome || forn.razao_social || ''
                        }));
                      }}
                      onClear={() => {
                        setForm(prev => ({ ...prev, pro_for: 1 }));
                      }}
                    />
                  </div>

                </div>
              </div>

              {/* DADOS PRINCIPAIS DO PRODUTO */}
              <div className="product-section-card">
                <div className="product-section-title" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Package size={16} color="#f97316" /> Identificação do Produto
                  </div>
                  <button
                    type="button"
                    className="btn-secondary small"
                    onClick={handleApplySuggestedName}
                    title="Recalcular e sugerir nome baseado em Grupo + Subgrupo + Modelo + Marca"
                  >
                    <RefreshCw size={14} /> Sugerir Nome
                  </button>
                </div>

                {/* LINHA 1: NOME DO PRODUTO (DESTAQUE) */}
                <div className="product-row-ident-1">
                  <div className="form-group">
                    <label style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span>Nome do Produto (Caixa Alta) *</span>
                      <small style={{ color: '#64748b' }}>Sugerido automaticamente</small>
                    </label>
                    <input
                      type="text"
                      required
                      value={form.nome}
                      onChange={(e) => {
                        setIsNameManuallyEdited(true);
                        setForm({ ...form, nome: e.target.value.toUpperCase() });
                      }}
                      placeholder="Ex: CALÇA MASCULINA JEANS SLIM MOONCITY"
                      style={{ textTransform: 'uppercase', fontWeight: 600, fontSize: '0.95rem' }}
                    />
                  </div>

                  <div className="form-group">
                    <label>Referência Fabricante</label>
                    <input
                      type="text"
                      value={form.referencia}
                      onChange={(e) => setForm({ ...form, referencia: e.target.value.toUpperCase() })}
                      placeholder="Ex: 72110"
                      style={{ textTransform: 'uppercase' }}
                    />
                  </div>

                  <div className="form-group">
                    <label>Coleção</label>
                    <input
                      type="text"
                      value={form.colecao}
                      onChange={(e) => setForm({ ...form, colecao: e.target.value.toUpperCase() })}
                      placeholder="Ex: INVERNO 2026"
                      style={{ textTransform: 'uppercase' }}
                    />
                  </div>
                </div>

                {/* LINHA 2: COR, CODIGO DE BARRAS + GERAR EAN */}
                <div className="product-row-ident-2">
                  <div className="form-group">
                    <label>Cor Padrão</label>
                    <input
                      type="text"
                      value={form.cor}
                      onChange={(e) => setForm({ ...form, cor: e.target.value.toUpperCase() })}
                      placeholder="Ex: PRETA, AZUL"
                      style={{ textTransform: 'uppercase' }}
                    />
                  </div>

                  <div className="form-group">
                    <label>Código de Barras Principal (EAN-13)</label>
                    <div style={{ display: 'flex', gap: '6px' }}>
                      <input
                        type="text"
                        value={form.codbarra}
                        onChange={(e) => setForm({ ...form, codbarra: e.target.value, gtin: e.target.value })}
                        placeholder="789..."
                        style={{ flex: 1 }}
                      />
                      <button
                        type="button"
                        className="btn-secondary"
                        onClick={handleGerarEanPrincipal}
                        title="Gerar Código EAN-13 Oficial"
                        style={{ display: 'flex', alignItems: 'center', gap: '4px', whiteSpace: 'nowrap' }}
                      >
                        <Barcode size={16} /> Gerar EAN13
                      </button>
                    </div>
                  </div>

                  <div className="form-group">
                    <label>Estado do Produto</label>
                    <select
                      value={form.estado}
                      onChange={(e) => setForm({ ...form, estado: e.target.value })}
                    >
                      <option value="ATIVO">Ativo</option>
                      <option value="INATIVO">Inativo</option>
                      <option value="FORA_LINHA">Fora de Linha</option>
                    </select>
                  </div>
                </div>

              </div>

            </div>
          )}

          {/* ========================================================= */}
          {/* ABA 2: ESTOQUE & 3 PREÇOS (GRADES)                        */}
          {/* ========================================================= */}
          {activeTab === 'precos' && (
            <div className="product-tab-content">

              {/* CARD DE FORMAÇÃO DOS 3 PREÇOS E CUSTO */}
              <div className="product-section-card">
                <div className="product-section-title" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.5rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <DollarSign size={16} color="#16a34a" /> Formação dos 3 Preços & Custos
                  </div>
                  {margemCalculada > 0 && (
                    <div className="margin-badge">
                      <TrendingUp size={15} /> Margem de Lucro sobre Custo: {margemCalculada.toFixed(2)}%
                    </div>
                  )}
                </div>

                <div className="product-grid-precos">
                  {/* CUSTO DE ENTRADA */}
                  <div className="price-card custo">
                    <label className="price-card-label">Custo Entrada (R$)</label>
                    <input
                      type="number"
                      step="0.01"
                      className="price-card-input"
                      value={form.custo}
                      onChange={(e) => handlePrecoOuCustoChange('custo', e.target.value)}
                      placeholder="0.00"
                    />
                    <span className="price-card-desc">Custo de compra / nota</span>
                  </div>

                  {/* PREÇO 1: DINHEIRO */}
                  <div className="price-card money">
                    <label className="price-card-label">1. Vlr Dinheiro (R$)</label>
                    <input
                      type="number"
                      step="0.01"
                      className="price-card-input"
                      value={form.pro_valor_dinheiro}
                      onChange={(e) => handlePrecoOuCustoChange('pro_valor_dinheiro', e.target.value)}
                      placeholder="0.00"
                    />
                    <span className="price-card-desc">Pagamento à vista em espécie</span>
                  </div>

                  {/* PREÇO 2: À VISTA (PIX / DÉBITO) */}
                  <div className="price-card vista">
                    <label className="price-card-label">2. Vlr à Vista (PIX/Débito) *</label>
                    <input
                      type="number"
                      step="0.01"
                      required
                      className="price-card-input"
                      value={form.valorv}
                      onChange={(e) => handlePrecoOuCustoChange('valorv', e.target.value)}
                      placeholder="0.00"
                    />
                    <span className="price-card-desc">Preço base do produto</span>
                  </div>

                  {/* PREÇO 3: A PRAZO (CARTÃO PRAZO) */}
                  <div className="price-card prazo">
                    <label className="price-card-label">3. Vlr a Prazo (Cartão) (R$)</label>
                    <input
                      type="number"
                      step="0.01"
                      className="price-card-input"
                      value={form.pro_valorv_prazo}
                      onChange={(e) => handlePrecoOuCustoChange('pro_valorv_prazo', e.target.value)}
                      placeholder="0.00"
                    />
                    <span className="price-card-desc">Venda a prazo / parcelado</span>
                  </div>
                </div>
              </div>

              {/* CARD DE MATRIZ DE GRADES DO PRODUTO */}
              <div className="product-section-card">
                <div className="product-section-title" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.5rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Grid size={16} color="#f59e0b" /> Grade de Variações (Tamanhos, Cores e os 3 Preços)
                  </div>

                  {/* BOTÕES DE SUGESTÃO PRECISA BASEADA EM TAMANHOS REAIS */}
                  <div style={{ display: 'flex', gap: '0.4rem', flexWrap: 'wrap' }}>
                    <button
                      type="button"
                      className="btn-secondary small"
                      onClick={() => handleGerarGradeAutomatica('letras')}
                      title="Gerar variações com tamanhos de confecção cadastrados (ex: P, M, G, GG)"
                    >
                      <Grid size={14} /> Grade P-GG
                    </button>
                    <button
                      type="button"
                      className="btn-secondary small"
                      onClick={() => handleGerarGradeAutomatica('calcados')}
                      title="Gerar variações com tamanhos numéricos cadastrados (ex: 34..44)"
                    >
                      <Grid size={14} /> Grade 34..44
                    </button>
                    <button
                      type="button"
                      className="btn-secondary small"
                      onClick={() => handleGerarGradeAutomatica('todos')}
                      title="Gerar variações com todos os tamanhos cadastrados no banco"
                    >
                      <Layers size={14} /> Todos Tamanhos
                    </button>
                    <button
                      type="button"
                      className="btn-secondary small"
                      onClick={handleGerarCodigosBarrasGrades}
                      title="Atalho F10: Gerar EAN13 para todas as grades"
                      style={{ color: '#2563eb' }}
                    >
                      <Barcode size={14} /> <kbd style={{ marginRight: '4px', fontSize: '0.68rem', padding: '1px 4px', background: '#f8fafc', border: '1px solid rgba(0,0,0,0.12)', borderBottom: '2px solid rgba(0,0,0,0.18)', borderRadius: '3px' }}>F10</kbd> Gerar EANs
                    </button>
                  </div>
                </div>

                {/* FORMULÁRIO DE INCLUSÃO RÁPIDA DE ITEM NA GRADE */}
                <div className="product-grade-quick-add">
                  <div className="form-group">
                    <label>Tamanho *</label>
                    <select
                      value={gradeForm.tam}
                      onChange={(e) => {
                        const selectedVal = e.target.value;
                        const match = tamanhosList.find(t => String(t.codigo) === String(selectedVal));
                        const label = match
                          ? (match.sigla && match.tamanho && match.sigla.toUpperCase() !== match.tamanho.toUpperCase()
                            ? `${match.sigla} - ${match.tamanho}`
                            : (match.sigla || match.tamanho))
                          : '';
                        setGradeForm({ ...gradeForm, tam: selectedVal, tam_nome: label });
                      }}
                    >
                      {tamanhosList.map(t => {
                        const label = t.sigla && t.tamanho && t.sigla.toUpperCase() !== t.tamanho.toUpperCase()
                          ? `${t.sigla} - ${t.tamanho}`
                          : (t.sigla || t.tamanho);
                        return (
                          <option key={t.codigo} value={t.codigo}>
                            {label}
                          </option>
                        );
                      })}
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Cor</label>
                    <input
                      type="text"
                      value={gradeForm.cor}
                      onChange={(e) => setGradeForm({ ...gradeForm, cor: e.target.value.toUpperCase() })}
                      placeholder="Cor"
                      style={{ textTransform: 'uppercase' }}
                    />
                  </div>

                  <div className="form-group">
                    <label>Qtd</label>
                    <input
                      type="number"
                      value={gradeForm.quantidade}
                      onChange={(e) => setGradeForm({ ...gradeForm, quantidade: e.target.value })}
                    />
                  </div>

                  <div className="form-group">
                    <label>Cód. Barras</label>
                    <input
                      type="text"
                      value={gradeForm.codbarra}
                      onChange={(e) => setGradeForm({ ...gradeForm, codbarra: e.target.value })}
                      placeholder="EAN específico"
                    />
                  </div>

                  <div className="form-group">
                    <label style={{ color: '#16a34a' }}>Vlr Dinheiro</label>
                    <input
                      type="number"
                      step="0.01"
                      value={gradeForm.valor_dinheiro}
                      onChange={(e) => setGradeForm({ ...gradeForm, valor_dinheiro: e.target.value })}
                    />
                  </div>

                  <div className="form-group">
                    <label style={{ color: '#ea580c' }}>Vlr Vista</label>
                    <input
                      type="number"
                      step="0.01"
                      value={gradeForm.valor}
                      onChange={(e) => setGradeForm({ ...gradeForm, valor: e.target.value })}
                    />
                  </div>

                  <div className="form-group">
                    <label style={{ color: '#2563eb' }}>Vlr Prazo</label>
                    <input
                      type="number"
                      step="0.01"
                      value={gradeForm.valor_prazo}
                      onChange={(e) => setGradeForm({ ...gradeForm, valor_prazo: e.target.value })}
                    />
                  </div>

                  <button
                    type="button"
                    className="btn-primary"
                    onClick={handleAddOrUpdateGradeItem}
                    style={{ height: '42px', padding: '0 1.15rem', display: 'inline-flex', alignItems: 'center', gap: '4px', whiteSpace: 'nowrap' }}
                  >
                    {editingGradeIndex !== null ? <Save size={16} /> : <Plus size={16} />}
                    {editingGradeIndex !== null ? 'Atualizar' : 'Adicionar'}
                  </button>
                </div>

                {/* TABELA DE GRADES CADASTRADAS */}
                <div className="product-grade-table-wrap">
                  <div className="table-responsive" style={{ maxHeight: '300px', overflowY: 'auto', margin: 0 }}>
                    <table className="data-table">
                      <thead>
                        <tr>
                          <th>Tamanho</th>
                          <th>Cor</th>
                          <th style={{ textAlign: 'center' }}>Qtd</th>
                          <th>Cód. Barras</th>
                          <th style={{ textAlign: 'right', color: '#16a34a' }}>Dinheiro</th>
                          <th style={{ textAlign: 'right', color: '#ea580c' }}>À Vista</th>
                          <th style={{ textAlign: 'right', color: '#2563eb' }}>A Prazo</th>
                          <th style={{ textAlign: 'center' }}>Ações</th>
                        </tr>
                      </thead>
                      <tbody>
                        {grades.map((g, idx) => {
                          const tamObj = tamanhosList.find(t =>
                            Number(t.codigo) === Number(g.tam || g.gra_tam) ||
                            (t.sigla && String(t.sigla).trim().toUpperCase() === String(g.tam_nome || g.tam).trim().toUpperCase())
                          );

                          let tamNome = g.tam_nome || '';
                          if (tamObj) {
                            tamNome = tamObj.sigla && tamObj.tamanho && tamObj.sigla.toUpperCase() !== tamObj.tamanho.toUpperCase()
                              ? `${tamObj.sigla} - ${tamObj.tamanho}`
                              : (tamObj.sigla || tamObj.tamanho);
                          } else if (!tamNome || tamNome.startsWith('Tam #')) {
                            tamNome = g.tamanho?.sigla || g.tamanho?.tamanho || `Tam #${g.tam || g.gra_tam}`;
                          }

                          return (
                            <tr key={idx}>
                              <td><strong>{tamNome}</strong></td>
                              <td>{g.cor || 'UNICA'}</td>
                              <td style={{ textAlign: 'center' }}><strong>{g.quantidade || 0}</strong></td>
                              <td><code>{g.codbarra || '-'}</code></td>
                              <td style={{ textAlign: 'right' }}>{formatCurrency(g.valor_dinheiro ?? g.valorDinheiro ?? form.pro_valor_dinheiro ?? form.valorv ?? 0)}</td>
                              <td style={{ textAlign: 'right', fontWeight: 700 }}>{formatCurrency(g.valor ?? form.valorv ?? 0)}</td>
                              <td style={{ textAlign: 'right' }}>{formatCurrency(g.valor_prazo ?? g.valorPrazo ?? form.pro_valorv_prazo ?? form.valorv ?? 0)}</td>
                              <td className="actions-cell" style={{ textAlign: 'center' }}>
                                <button type="button" className="crud-row-btn edit" onClick={() => handleEditGradeItem(idx)}><Edit2 size={14} /></button>
                                <button type="button" className="crud-row-btn delete" onClick={() => handleDeleteGradeItem(idx)}><Trash2 size={14} /></button>
                              </td>
                            </tr>
                          );
                        })}
                        {grades.length === 0 && (
                          <tr>
                            <td colSpan="8" style={{ textAlign: 'center', padding: '1.75rem', color: '#64748b' }}>
                              Nenhuma grade cadastrada. Use os botões acima para sugestões rápidas ou adicione manualmente.
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>

              </div>

            </div>
          )}

          {/* ========================================================= */}
          {/* ABA 3: IMAGENS                                            */}
          {/* ========================================================= */}
          {activeTab === 'imagens' && (
            <div className="product-tab-content">
              <div className="product-section-card">
                <div className="product-section-title">
                  <ImageIcon size={16} color="#8b5cf6" /> Imagem do Produto
                </div>

                <div className="form-group">
                  <label>URL da Imagem</label>
                  <input
                    type="text"
                    value={form.url_Imagem}
                    onChange={(e) => setForm({ ...form, url_Imagem: e.target.value })}
                    placeholder="https://..."
                  />
                </div>

                {form.url_Imagem && (
                  <div className="product-image-preview-card">
                    <img
                      src={form.url_Imagem}
                      alt="Preview"
                      onError={(e) => { e.target.style.display = 'none'; }}
                    />
                  </div>
                )}
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* ABA 4: FISCAL                                             */}
          {/* ========================================================= */}
          {activeTab === 'fiscal' && (
            <div className="product-tab-content">
              {/* SEÇÃO 1: CLASSIFICAÇÃO FISCAL & PAF-ECF */}
              <div className="product-section-card">
                <div className="product-section-title">
                  <ShieldCheck size={16} color="#006591" /> Classificação Fiscal & PAF-ECF
                </div>

                <div className="product-grid-fiscal">
                  <div className="form-group">
                    <label>NCM (Classificação Fiscal) *</label>
                    <input
                      type="text"
                      value={form.ncm}
                      onChange={(e) => setForm({ ...form, ncm: e.target.value })}
                      placeholder="6109.10.00"
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label>CFOP Padrão</label>
                    <input
                      type="text"
                      value={form.cfop}
                      onChange={(e) => setForm({ ...form, cfop: e.target.value })}
                      placeholder="5102"
                    />
                  </div>

                  <div className="form-group">
                    <label>CEST</label>
                    <input
                      type="text"
                      value={form.cest}
                      onChange={(e) => setForm({ ...form, cest: e.target.value })}
                      placeholder="Código CEST"
                    />
                  </div>

                  <div className="form-group">
                    <label>Unidade de Medida</label>
                    <select
                      value={form.um}
                      onChange={(e) => setForm({ ...form, um: e.target.value })}
                    >
                      <option value="UN">UN - Unidade</option>
                      <option value="PC">PC - Peça</option>
                      <option value="PAR">PAR - Par</option>
                      <option value="KG">KG - Quilograma</option>
                      <option value="MT">MT - Metro</option>
                      <option value="CX">CX - Caixa</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Totalizador Fiscal</label>
                    <select
                      value={form.codTotalizador}
                      onChange={(e) => setForm({ ...form, codTotalizador: Number(e.target.value) })}
                    >
                      <option value="1">01T1700 - ICMS 17%</option>
                      <option value="2">02T1200 - ICMS 12%</option>
                      <option value="3">03T2500 - ICMS 25%</option>
                      <option value="4">F1 - Substituição Tributária</option>
                      <option value="5">I1 - Isento / Não Tributado</option>
                      <option value="6">N1 - Não Incidência</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Gerar Documento Fiscal</label>
                    <select
                      value={form.pro_fiscal_gerar || 'S'}
                      onChange={(e) => setForm({ ...form, pro_fiscal_gerar: e.target.value })}
                    >
                      <option value="S">Sim (Emitir Fiscal)</option>
                      <option value="N">Não (Controle Interno)</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Venda c/ Estoque Negativo</label>
                    <select
                      value={form.pro_emitir_negativo || 'N'}
                      onChange={(e) => setForm({ ...form, pro_emitir_negativo: e.target.value })}
                    >
                      <option value="N">Não (Bloquear Venda)</option>
                      <option value="S">Sim (Permitir Negativo)</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Balança de Checkout</label>
                    <select
                      value={form.balanca || 'N'}
                      onChange={(e) => setForm({ ...form, balanca: e.target.value })}
                    >
                      <option value="N">Não (Produto Padrão)</option>
                      <option value="S">Sim (Produto Pesável)</option>
                    </select>
                  </div>
                </div>
              </div>

              {/* SEÇÃO 2: VÍNCULO COM A BASE FISCAL & PARÂMETROS OPERACIONAIS */}
              <div className="product-section-card">
                <div className="product-section-title" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <FileText size={16} color="#f97316" /> Vínculo com a Base Fiscal & Parâmetros Operacionais
                  </div>
                  {form.pro_cod_fiscal && Number(form.pro_cod_fiscal) > 0 ? (
                    <span className="badge badge-success">
                      Vinculado ao Fiscal #{form.pro_cod_fiscal}
                    </span>
                  ) : (
                    <span className="badge badge-neutral">
                      Próprio Mestre Fiscal (Sem Vínculo)
                    </span>
                  )}
                </div>

                <div className="form-group" style={{ marginBottom: '1.25rem' }}>
                  <label>Produto Fiscal Vinculado (Código Fiscal Mestre)</label>
                  <LookupSelect
                    value={form.pro_cod_fiscal}
                    displayValue={
                      form.pro_cod_fiscal && Number(form.pro_cod_fiscal) > 0
                        ? `#${form.pro_cod_fiscal}`
                        : ''
                    }
                    placeholder="Buscar Produto na Base Fiscal para Vincular..."
                    title="Selecionar Produto Fiscal (PRO_COD_FISCAL)"
                    subtitle="Busca na base fiscal por código, descrição ou código de barras"
                    icon={ShieldCheck}
                    searchPlaceholder="Digite o nome, código ou código de barras do produto fiscal..."
                    fetchData={async (termo, targetPage, limit) => {
                      let url = `/v1/conciliacao/fiscais?page=${targetPage}&limit=${limit}`;
                      if (termo) url += `&busca=${encodeURIComponent(termo)}&termo=${encodeURIComponent(termo)}`;
                      const res = await api.get(url);
                      return res.data;
                    }}
                    columns={[
                      { key: 'codigo', label: 'Código Fiscal', width: '100px', render: (p) => <span className="item-code">#{p.codigo || p.PRO_CODIGO}</span> },
                      { key: 'nome', label: 'Descrição Fiscal', render: (p) => <strong>{p.nome || p.PRO_NOME}</strong> },
                      { key: 'codbarra', label: 'Cód. Barras', render: (p) => <code>{p.codbarra || p.PRO_CODBARRA || '-'}</code> },
                      { key: 'ncm', label: 'NCM', width: '90px' },
                      { key: 'quantidade', label: 'Estoque Fiscal', align: 'center', width: '100px' }
                    ]}
                    onSelect={(fiscProd) => {
                      const fId = fiscProd.codigo || fiscProd.PRO_CODIGO;
                      setForm(prev => ({
                        ...prev,
                        pro_cod_fiscal: Number(fId),
                        ncm: fiscProd.ncm || prev.ncm,
                        cfop: fiscProd.cfop || prev.cfop,
                        cest: fiscProd.cest || prev.cest
                      }));
                    }}
                    onClear={() => {
                      setForm(prev => ({ ...prev, pro_cod_fiscal: 0 }));
                    }}
                  />
                  <small style={{ color: '#64748b', marginTop: '4px', display: 'block' }}>
                    Se este produto for vinculado a outro produto fiscal, as baixas contábeis/fiscais serão unificadas no código mestre.
                  </small>
                </div>

                <div className="product-grid-operacional">
                  <div className="form-group">
                    <label>Localização / Prateleira</label>
                    <input
                      type="text"
                      value={form.local}
                      onChange={(e) => setForm({ ...form, local: e.target.value.toUpperCase() })}
                      placeholder="Ex: PRAT-A01, GERAL"
                      style={{ textTransform: 'uppercase' }}
                    />
                  </div>

                  <div className="form-group">
                    <label>Curva ABC</label>
                    <select
                      value={form.abc || 'N'}
                      onChange={(e) => setForm({ ...form, abc: e.target.value })}
                    >
                      <option value="A">Curva A (Alta Rotatividade)</option>
                      <option value="B">Curva B (Média Rotatividade)</option>
                      <option value="C">Curva C (Baixa Rotatividade)</option>
                      <option value="N">Neutro / Não Definido</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Estoque Mínimo</label>
                    <input
                      type="number"
                      min="0"
                      value={form.quant_min}
                      onChange={(e) => setForm({ ...form, quant_min: Number(e.target.value) || 0 })}
                      placeholder="0"
                    />
                  </div>

                  <div className="form-group">
                    <label>Validade (Dias)</label>
                    <input
                      type="number"
                      min="0"
                      value={form.dias_validade}
                      onChange={(e) => setForm({ ...form, dias_validade: Number(e.target.value) || 0 })}
                      placeholder="0 (Sem validade)"
                    />
                  </div>
                </div>
              </div>
            </div>
          )}

        </div>

        {/* RODAPÉ DO MODAL COM ATALHOS */}
        <div className="product-modal-footer">
          <div className="product-modal-shortcuts">
            <span style={{ fontSize: '0.78rem', color: '#64748b', fontWeight: 600 }}>Atalhos:</span>
            <div className="product-shortcut-item">
              <kbd>F2</kbd> <span>Novo</span>
            </div>
            <div className="product-shortcut-item">
              <kbd>F4</kbd> <span>Grupos</span>
            </div>
            <div className="product-shortcut-item">
              <kbd>F7</kbd> <span>Fornecedor</span>
            </div>
            <div className="product-shortcut-item">
              <kbd>F10</kbd> <span>EANs</span>
            </div>
            <div className="product-shortcut-item">
              <kbd>Ctrl+S</kbd> <span>Salvar</span>
            </div>
            <div className="product-shortcut-item">
              <kbd>ESC</kbd> <span>Fechar</span>
            </div>
          </div>

          <div className="product-modal-actions">
            <button type="button" className="btn-secondary" onClick={onClose}>Cancelar</button>
            <button type="button" className="btn-primary" onClick={handleSave} disabled={loading} style={{ minWidth: '150px' }}>
              {loading ? <RefreshCw size={18} className="spinner" /> : <Save size={18} />} Salvar Produto
            </button>
          </div>
        </div>

      </div>

      {/* ========================================================================= */}
      {/* MODAL POPUP: NOVO MODELO RÁPIDO                                           */}
      {/* ========================================================================= */}
      {showQuickModeloModal && (
        <div className="product-form-modal-overlay" style={{ zIndex: 1000001 }}>
          <div className="product-form-modal-container glass" style={{ maxWidth: '460px' }}>
            <div className="product-modal-header">
              <div className="product-modal-title-group">
                <div className="product-modal-icon-badge" style={{ width: '38px', height: '38px' }}>
                  <Tag size={18} color="#ffffff" />
                </div>
                <div>
                  <h4 style={{ margin: 0 }}>Cadastrar Novo Modelo</h4>
                  <span className="product-modal-subtitle">Gera sugestão automática de produto</span>
                </div>
              </div>
              <button className="product-modal-close" onClick={() => setShowQuickModeloModal(false)}><X size={18} /></button>
            </div>
            <form onSubmit={handleSaveQuickModelo} className="submodal-form-body">
              <div className="form-group">
                <label>Nome do Modelo *</label>
                <input
                  type="text"
                  required
                  autoFocus
                  value={novoModeloNome}
                  onChange={(e) => setNovoModeloNome(e.target.value.toUpperCase())}
                  placeholder="Ex: SLIM, FLARE, POLO, REGATA"
                  style={{ textTransform: 'uppercase' }}
                />
              </div>
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.65rem', marginTop: '1.25rem' }}>
                <button type="button" className="btn-secondary" onClick={() => setShowQuickModeloModal(false)}>Cancelar</button>
                <button type="submit" className="btn-primary"><Save size={16} /> Salvar Modelo</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL POPUP: NOVO FORNECEDOR COM MÁSCARA CNPJ & DROPDOWN CIDADES VIA FOR_CID*/}
      {/* ========================================================================= */}
      {showQuickVendorModal && (
        <div className="product-form-modal-overlay" style={{ zIndex: 1000001 }}>
          <div className="product-form-modal-container glass" style={{ maxWidth: '650px' }}>
            <div className="product-modal-header">
              <div className="product-modal-title-group">
                <div className="product-modal-icon-badge" style={{ width: '38px', height: '38px' }}>
                  <UserPlus size={18} color="#ffffff" />
                </div>
                <div>
                  <h4 style={{ margin: 0 }}>Novo Fornecedor Rápido</h4>
                  <span className="product-modal-subtitle">Com máscara CNPJ e vínculo de Cidade/UF (FOR_CID)</span>
                </div>
              </div>
              <button className="product-modal-close" onClick={() => setShowQuickVendorModal(false)}><X size={18} /></button>
            </div>
            <form onSubmit={handleSaveQuickVendor} className="submodal-form-body">
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div className="form-group" style={{ gridColumn: 'span 2' }}>
                  <label>Razão Social / Nome *</label>
                  <input
                    type="text"
                    required
                    autoFocus
                    value={quickVendorForm.nome}
                    onChange={(e) => setQuickVendorForm({ ...quickVendorForm, nome: e.target.value.toUpperCase() })}
                    placeholder="Ex: CONFECÇÕES ESTRELA LTDA"
                    style={{ textTransform: 'uppercase' }}
                  />
                </div>

                <div className="form-group">
                  <label>Nome Fantasia</label>
                  <input
                    type="text"
                    value={quickVendorForm.fantasia}
                    onChange={(e) => setQuickVendorForm({ ...quickVendorForm, fantasia: e.target.value.toUpperCase() })}
                    placeholder="Ex: ESTRELA MODAS"
                    style={{ textTransform: 'uppercase' }}
                  />
                </div>

                <div className="form-group">
                  <label>CNPJ / CPF (com máscara) *</label>
                  <input
                    type="text"
                    value={quickVendorForm.cnpj}
                    onChange={(e) => setQuickVendorForm({ ...quickVendorForm, cnpj: maskCnpjCpf(e.target.value) })}
                    placeholder="00.000.000/0000-00"
                  />
                </div>

                <div className="form-group">
                  <label>Telefone / Celular</label>
                  <input
                    type="text"
                    value={quickVendorForm.telefone}
                    onChange={(e) => setQuickVendorForm({ ...quickVendorForm, telefone: e.target.value })}
                    placeholder="(00) 00000-0000"
                  />
                </div>

                <div className="form-group">
                  <label>E-mail</label>
                  <input
                    type="email"
                    value={quickVendorForm.email}
                    onChange={(e) => setQuickVendorForm({ ...quickVendorForm, email: e.target.value })}
                    placeholder="contato@empresa.com"
                  />
                </div>

                {/* SELETOR DE CIDADE VINCULANDO FOR_CID E UF */}
                <div className="form-group">
                  <label>Cidade (FOR_CID) *</label>
                  <select
                    value={quickVendorForm.for_cid}
                    onChange={(e) => {
                      const cidId = Number(e.target.value);
                      const matchCid = cidadesList.find(c => Number(c.codigo) === cidId);
                      setQuickVendorForm(prev => ({
                        ...prev,
                        for_cid: cidId,
                        cidade: matchCid ? matchCid.nome : prev.cidade,
                        uf: matchCid ? matchCid.uf : prev.uf
                      }));
                    }}
                  >
                    <option value="">Selecione a Cidade...</option>
                    {cidadesList.map(c => (
                      <option key={c.codigo} value={c.codigo}>
                        {c.nome} ({c.uf})
                      </option>
                    ))}
                  </select>
                </div>

                <div className="form-group">
                  <label>Estado (UF)</label>
                  <input
                    type="text"
                    maxLength={2}
                    value={quickVendorForm.uf}
                    onChange={(e) => setQuickVendorForm({ ...quickVendorForm, uf: e.target.value.toUpperCase() })}
                    placeholder="UF"
                    style={{ textTransform: 'uppercase' }}
                  />
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.65rem', marginTop: '1.25rem' }}>
                <button type="button" className="btn-secondary" onClick={() => setShowQuickVendorModal(false)}>Cancelar</button>
                <button type="submit" className="btn-primary"><Save size={16} /> Salvar Fornecedor</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAIS ADICIONAIS */}
      {showGruposSubgruposModal && (
        <GruposSubgruposModal
          isOpen={showGruposSubgruposModal}
          onClose={() => {
            setShowGruposSubgruposModal(false);
          }}
        />
      )}

    </div>,
    document.body
  );
}
