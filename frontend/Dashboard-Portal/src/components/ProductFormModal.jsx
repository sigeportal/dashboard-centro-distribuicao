import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { 
  Package, Plus, Trash2, Check, X, Edit2, Search, Grid, 
  Image as ImageIcon, DollarSign, Layers, ShieldCheck, 
  RefreshCw, Barcode, AlertCircle, TrendingUp, Sparkles,
  CheckCircle2, FolderPlus, UserPlus, FileText, Printer
} from 'lucide-react';
import { createApi } from '../services/api';
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
    pro_for: fornecedores[0]?.codigo || 1,
    pro_gru: subgrupos[0]?.codigo || 1,
    grupo_id: grupos[0]?.codigo || 1,
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

  // Margem Calculada (%)
  const [margemCalculada, setMargemCalculada] = useState(0);

  // Inicialização e Carga dos Dados
  useEffect(() => {
    fetchTamanhos();
    if (productToEdit) {
      const gCode = Number(productToEdit.pro_gru || productToEdit.subgrupoId || productToEdit.gru || 1);
      const sg = subgrupos.find(s => Number(s.codigo) === gCode);
      const gId = sg ? Number(sg.g1) : (Number(productToEdit.grupo_id || productToEdit.grupo || 1));

      const vVista = Number(productToEdit.valorv || productToEdit.valor || 0);
      const vDinheiro = Number(productToEdit.pro_valor_dinheiro || productToEdit.valor_dinheiro || vVista);
      const vPrazo = Number(productToEdit.pro_valorv_prazo || productToEdit.valorv_prazo || productToEdit.valorp || vVista);
      const custoEntrada = Number(productToEdit.custo || productToEdit.valorc || productToEdit.valorf || 0);

      setForm({
        codigo: productToEdit.codigo || productToEdit.id,
        nome: productToEdit.nome || '',
        marca: productToEdit.marca || productToEdit.fabricante || '',
        fabricante: productToEdit.fabricante || productToEdit.marca || '',
        cod_fabricante: productToEdit.cod_fabricante || productToEdit.codigo || '',
        colecao: productToEdit.colecao || '',
        referencia: productToEdit.referencia || '',
        cor: productToEdit.cor || '',
        codbarra: productToEdit.codbarra || '',
        abc: productToEdit.abc || 'N',
        local: productToEdit.local || 'GERAL',
        ult_alteracao: productToEdit.ult_alteracao || new Date().toISOString().split('T')[0],
        estado: productToEdit.estado || 'ATIVO',
        um: productToEdit.um || productToEdit.embalagem || 'UN',

        pro_for: productToEdit.pro_for || productToEdit.fornecedorId || fornecedores[0]?.codigo || 1,
        pro_gru: gCode,
        grupo_id: gId,
        modelo_id: productToEdit.modelo || productToEdit.modelo_id || '',

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

      // Recalcular margem
      if (custoEntrada > 0 && vVista > 0) {
        setMargemCalculada(((vVista - custoEntrada) / custoEntrada) * 100);
      } else {
        setMargemCalculada(0);
      }

      fetchGrades(productToEdit.codigo || productToEdit.id);
      setMode('browse');
    } else {
      const nextCode = Math.floor(Math.random() * 90000) + 10000;
      setForm(prev => ({
        ...prev,
        codigo: nextCode,
        cod_fabricante: String(nextCode),
        codbarra: `789${String(nextCode).padStart(9, '0')}1`
      }));
      setGrades([]);
      setMode('insert');
    }
  }, [productToEdit]);

  // Recalcula a margem de lucro ao alterar custo ou preço à vista
  const handlePrecoOuCustoChange = (field, value) => {
    const numVal = parseFloat(value) || 0;
    const updated = { ...form, [field]: numVal };

    // Se estiver alterando preço à vista e dinheiro/prazo forem 0, sugere os 3
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

  // Buscar tamanhos disponíveis
  const fetchTamanhos = async () => {
    try {
      const res = await api.get('/v1/tamanhos?limit=200');
      const items = Array.isArray(res.data) ? res.data : (res.data?.data || []);
      setTamanhosList(items);
      if (items.length > 0 && !gradeForm.tam) {
        setGradeForm(prev => ({ ...prev, tam: items[0].codigo, tam_nome: items[0].tamanho || items[0].sigla }));
      }
    } catch (err) {
      console.warn('Erro ao carregar tamanhos:', err);
    }
  };

  // Buscar grades existentes do produto
  const fetchGrades = async (prodCode) => {
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
      setGrades(items);
    } catch (err) {
      console.warn('Erro ao carregar grades:', err);
    }
  };

  // Atalhos de Teclado
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (showGradesModal || showGruposSubgruposModal) return;

      if (e.key === 'Escape') {
        onClose();
      } else if (e.key === 'F2') {
        e.preventDefault();
        setActiveTab('fiscal');
      } else if (e.key === 'F4') {
        e.preventDefault();
        setShowGruposSubgruposModal(true);
      } else if (e.key === 'F10') {
        e.preventDefault();
        handleGerarCodigosBarrasGrades();
      } else if (e.ctrlKey && e.key.toLowerCase() === 's') {
        e.preventDefault();
        handleSave();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onClose, showGradesModal, showGruposSubgruposModal, form, grades]);

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
      alert('Nenhuma grade cadastrada para gerar códigos de barras.');
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

  // Gerador Rápido de Grades por Lista de Tamanhos (ex: P, M, G, GG ou 36..44)
  const handleGerarGradeAutomatica = (tipo) => {
    let tamanhosGerar = [];
    if (tipo === 'letras') {
      tamanhosGerar = ['P', 'M', 'G', 'GG'];
    } else if (tipo === 'numeros') {
      tamanhosGerar = ['34', '36', '38', '40', '42', '44'];
    } else if (tipo === 'calcados') {
      tamanhosGerar = ['35', '36', '37', '38', '39', '40'];
    }

    const prodCod = Number(form.codigo) || 1;
    const vVista = Number(form.valorv || 0);
    const vDinheiro = Number(form.pro_valor_dinheiro || vVista);
    const vPrazo = Number(form.pro_valorv_prazo || vVista);

    const newGrades = tamanhosGerar.map((sigla, idx) => {
      const matchTam = tamanhosList.find(t => (t.sigla || t.tamanho || '').toUpperCase() === sigla.toUpperCase());
      const tamId = matchTam ? matchTam.codigo : (idx + 1);
      const base = `789${String(prodCod).padStart(6, '0')}${String(tamId).padStart(3, '0')}`;
      let sum = 0;
      for (let i = 0; i < 12; i++) {
        sum += parseInt(base[i], 10) * (i % 2 === 0 ? 1 : 3);
      }
      const checkDigit = (10 - (sum % 10)) % 10;

      return {
        codigo: Math.floor(Math.random() * 900000) + 100000,
        pro: prodCod,
        tam: tamId,
        tam_nome: sigla,
        tamanho: { codigo: tamId, tamanho: sigla, sigla: sigla },
        cor: form.cor || 'UNICA',
        codbarra: `${base.slice(0, 12)}${checkDigit}`,
        quantidade: 0,
        valor: vVista,
        valor_dinheiro: vDinheiro,
        valor_prazo: vPrazo
      };
    });

    setGrades(prev => [...prev, ...newGrades]);
    setSuccessMsg(`Grade automática gerada com ${newGrades.length} variações!`);
    setTimeout(() => setSuccessMsg(''), 4000);
  };

  // Adicionar / Salvar Item na Grade
  const handleAddOrUpdateGradeItem = () => {
    if (!gradeForm.tam) {
      alert('Selecione o tamanho.');
      return;
    }
    const matchTam = tamanhosList.find(t => Number(t.codigo) === Number(gradeForm.tam));
    const tamNome = matchTam ? (matchTam.sigla || matchTam.tamanho) : `Tam #${gradeForm.tam}`;

    const prodCod = Number(form.codigo) || 1;
    let codbarraFinal = gradeForm.codbarra;
    if (!codbarraFinal) {
      const base = `789${String(prodCod).padStart(6, '0')}${String(gradeForm.tam).padStart(3, '0')}`;
      let sum = 0;
      for (let i = 0; i < 12; i++) sum += parseInt(base[i], 10) * (i % 2 === 0 ? 1 : 3);
      const checkDigit = (10 - (sum % 10)) % 10;
      codbarraFinal = `${base.slice(0, 12)}${checkDigit}`;
    }

    const itemGrade = {
      codigo: gradeForm.codigo || (Math.floor(Math.random() * 900000) + 100000),
      pro: prodCod,
      tam: Number(gradeForm.tam),
      tam_nome: tamNome,
      tamanho: matchTam || { codigo: gradeForm.tam, tamanho: tamNome, sigla: tamNome },
      cor: gradeForm.cor || 'UNICA',
      codbarra: codbarraFinal,
      quantidade: Number(gradeForm.quantidade) || 0,
      valor: Number(gradeForm.valor) || Number(form.valorv) || 0,
      valor_dinheiro: Number(gradeForm.valor_dinheiro) || Number(form.pro_valor_dinheiro) || Number(form.valorv) || 0,
      valor_prazo: Number(gradeForm.valor_prazo) || Number(form.pro_valorv_prazo) || Number(form.valorv) || 0
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
    setGradeForm({
      codigo: item.codigo || item.gra_codigo || 0,
      tam: item.tam || item.gra_tam || (item.tamanho?.codigo || ''),
      tam_nome: item.tam_nome || item.tamanho?.sigla || item.tamanho?.tamanho || '',
      cor: item.cor || item.gra_cor || 'UNICA',
      codbarra: item.codbarra || item.gra_codbarra || '',
      quantidade: item.quantidade || item.gra_quantidade || 0,
      valor: item.valor || item.gra_valor || Number(form.valorv) || 0,
      valor_dinheiro: item.valor_dinheiro || item.gra_valor_dinheiro || Number(form.pro_valor_dinheiro) || 0,
      valor_prazo: item.valor_prazo || item.gra_valor_prazo || Number(form.pro_valorv_prazo) || 0
    });
  };

  const handleDeleteGradeItem = (idx) => {
    setGrades(prev => prev.filter((_, i) => i !== idx));
    if (editingGradeIndex === idx) setEditingGradeIndex(null);
  };

  // Salvar Produto Completo
  const handleSave = async () => {
    if (!form.nome.trim()) {
      alert('Por favor, informe o Nome do Produto.');
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
        codigo: Number(form.codigo),
        nome: form.nome,
        marca: form.marca || form.fabricante || 'GENERICA',
        fabricante: form.fabricante || form.marca || 'GENERICA',
        cod_fabricante: form.cod_fabricante || String(form.codigo),
        colecao: form.colecao || '',
        referencia: form.referencia || '',
        cor: form.cor || '',
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
        modelo: Number(form.modelo_id) || 0,

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

      if (mode === 'edit' || (productToEdit && mode !== 'insert')) {
        await api.put('/v1/produtos', payload);
      } else {
        await api.post('/v1/produtos', payload);
      }

      // Salva as Grades do Produto via Lote
      if (grades.length > 0) {
        const gradesPayload = {
          itens: grades.map(g => ({
            gra_codigo: Number(g.codigo || g.gra_codigo || (Math.floor(Math.random() * 900000) + 100000)),
            gra_pro: Number(form.codigo),
            gra_tam: Number(g.tam || g.gra_tam || g.tamanho?.codigo || 1),
            gra_cor: g.cor || g.gra_cor || form.cor || 'UNICA',
            gra_codbarra: g.codbarra || g.gra_codbarra || form.codbarra,
            gra_quantidade: Number(g.quantidade || g.gra_quantidade || 0),
            gra_valor: Number(g.valor || g.gra_valor || vVista),
            gra_valor_dinheiro: Number(g.valor_dinheiro || g.gra_valor_dinheiro || vDinheiro),
            gra_valor_prazo: Number(g.valor_prazo || g.gra_valor_prazo || vPrazo)
          }))
        };
        try {
          await api.post('/v1/grades/lote', gradesPayload);
        } catch (errGrades) {
          console.warn('Tentando salvar grades individualmente:', errGrades);
          for (const g of gradesPayload.itens) {
            await api.post('/v1/grades', g).catch(() => {});
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
              <span className="product-modal-subtitle">Padrão PDV Completo • 3 Valores de Preço • Matriz de Grades & Fiscal</span>
            </div>
          </div>
          
          <div className="product-modal-header-actions">
            <button className="btn-close" onClick={onClose} title="Fechar (ESC)"><X size={20} /></button>
          </div>
        </div>

        {/* MENSAGENS DE ALERTA */}
        {successMsg && (
          <div className="product-alert success">
            <CheckCircle2 size={18} /> {successMsg}
          </div>
        )}
        {errorMsg && (
          <div className="product-alert error">
            <AlertCircle size={18} /> {errorMsg}
          </div>
        )}

        {/* BARRA DE NAVEGAÇÃO POR ABAS (PADRÃO PDV_NOVO) */}
        <div className="product-modal-tabs">
          <button 
            type="button"
            className={`product-tab-btn ${activeTab === 'geral' ? 'active' : ''}`}
            onClick={() => setActiveTab('geral')}
          >
            <Layers size={18} /> Dados Gerais
          </button>
          
          <button 
            type="button"
            className={`product-tab-btn ${activeTab === 'precos' ? 'active' : ''}`}
            onClick={() => setActiveTab('precos')}
          >
            <DollarSign size={18} /> Estoque & 3 Preços (Grades)
          </button>
          
          <button 
            type="button"
            className={`product-tab-btn ${activeTab === 'imagens' ? 'active' : ''}`}
            onClick={() => setActiveTab('imagens')}
          >
            <ImageIcon size={18} /> Imagens
          </button>
          
          <button 
            type="button"
            className={`product-tab-btn ${activeTab === 'fiscal' ? 'active' : ''}`}
            onClick={() => setActiveTab('fiscal')}
          >
            <ShieldCheck size={18} /> Outros & Fiscal
          </button>
        </div>

        {/* CONTEÚDO DO FORMULÁRIO */}
        <div className="product-modal-body">
          
          {/* ========================================================= */}
          {/* ABA 1: DADOS GERAIS                                       */}
          {/* ========================================================= */}
          {activeTab === 'geral' && (
            <div className="product-tab-content">
              
              {/* CLASSIFICAÇÃO HIERÁRQUICA & FORNECEDOR */}
              <div className="product-section-card">
                <div className="product-section-title">
                  <Layers size={16} color="#2563eb" /> Classificação & Fornecedor
                </div>

                <div className="product-row-classification">
                  <div className="form-group">
                    <label>Grupo *</label>
                    <select 
                      value={form.grupo_id}
                      onChange={(e) => {
                        const gId = Number(e.target.value);
                        const firstSg = subgrupos.find(s => Number(s.g1) === gId);
                        setForm(prev => ({ 
                          ...prev, 
                          grupo_id: gId, 
                          pro_gru: firstSg ? firstSg.codigo : prev.pro_gru 
                        }));
                      }}
                    >
                      {grupos.map(g => (
                        <option key={g.codigo} value={g.codigo}>#{g.codigo} - {g.nome}</option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Subgrupo *</label>
                    <select 
                      value={form.pro_gru}
                      onChange={(e) => setForm(prev => ({ ...prev, pro_gru: Number(e.target.value) }))}
                    >
                      {subgrupos
                        .filter(s => !form.grupo_id || Number(s.g1) === Number(form.grupo_id))
                        .map(s => (
                          <option key={s.codigo} value={s.codigo}>#{s.codigo} - {s.nome}</option>
                        ))}
                    </select>
                  </div>

                  <div className="form-group">
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
                        { key: 'cnpj', label: 'CNPJ / CPF', render: (f) => <code>{f.cnpj || f.cpf || '-'}</code> },
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
                <div className="product-section-title">
                  <Package size={16} color="#f97316" /> Identificação do Produto
                </div>

                {/* LINHA 1: NOME (2 COLUNAS), MARCA (1 COLUNA), REFERENCIA (1 COLUNA) */}
                <div className="product-row-ident-1">
                  <div className="form-group">
                    <label>Nome do Produto *</label>
                    <input 
                      type="text" 
                      required 
                      value={form.nome} 
                      onChange={(e) => setForm({ ...form, nome: e.target.value })} 
                      placeholder="Ex: CAMISETA POLO PIQUET PREMIUM" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Marca / Fabricante</label>
                    <input 
                      type="text" 
                      value={form.marca || form.fabricante} 
                      onChange={(e) => setForm({ ...form, marca: e.target.value, fabricante: e.target.value })} 
                      placeholder="Ex: MOONCITY, NIKKE" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Referência Fabricante</label>
                    <input 
                      type="text" 
                      value={form.referencia} 
                      onChange={(e) => setForm({ ...form, referencia: e.target.value })} 
                      placeholder="Ex: 72110" 
                    />
                  </div>
                </div>

                {/* LINHA 2: COLEÇÃO (1 COLUNA), COR (1 COLUNA), CODIGO DE BARRAS + GERAR (2 COLUNAS) */}
                <div className="product-row-ident-2">
                  <div className="form-group">
                    <label>Coleção</label>
                    <input 
                      type="text" 
                      value={form.colecao} 
                      onChange={(e) => setForm({ ...form, colecao: e.target.value })} 
                      placeholder="Ex: INVERNO 2026" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Cor Padrão</label>
                    <input 
                      type="text" 
                      value={form.cor} 
                      onChange={(e) => setForm({ ...form, cor: e.target.value })} 
                      placeholder="Ex: PRETA, AZUL MARINHO" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Código de Barras (EAN-13)</label>
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
                </div>

                {/* LINHA 3: UNIDADE, CLASSIFICAÇÃO ABC, LOCALIZAÇÃO, ESTADO */}
                <div className="product-row-ident-3">
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
                      <option value="CX">CX - Caixa</option>
                      <option value="MT">MT - Metro</option>
                      <option value="L">L - Litro</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Classificação ABC</label>
                    <select 
                      value={form.abc} 
                      onChange={(e) => setForm({ ...form, abc: e.target.value })}
                    >
                      <option value="A">A - Alta Rotatividade</option>
                      <option value="B">B - Média Rotatividade</option>
                      <option value="C">C - Baixa Rotatividade</option>
                      <option value="N">N - Normal / Não Definido</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Localização Estoque</label>
                    <input 
                      type="text" 
                      value={form.local} 
                      onChange={(e) => setForm({ ...form, local: e.target.value })} 
                      placeholder="Ex: GERAL, CORREDOR A" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Estado do Produto</label>
                    <select 
                      value={form.estado} 
                      onChange={(e) => setForm({ ...form, estado: e.target.value })}
                    >
                      <option value="ATIVO">🟢 ATIVO</option>
                      <option value="INATIVO">🔴 INATIVO</option>
                    </select>
                  </div>
                </div>
              </div>

            </div>
          )}

          {/* ========================================================= */}
          {/* ABA 2: ESTOQUE & 3 PREÇOS (PRODUTO E GRADES)              */}
          {/* ========================================================= */}
          {activeTab === 'precos' && (
            <div className="product-tab-content">
              
              {/* CARD DOS 3 PREÇOS DE VENDA */}
              <div className="product-section-card highlight-prices">
                <div className="product-section-title" style={{ color: '#ea580c' }}>
                  <DollarSign size={18} /> Os 3 Valores de Preço de Venda do Produto
                </div>

                <div className="product-grid-3">
                  <div className="price-box money">
                    <span className="price-box-label">💵 PREÇO DINHEIRO (R$)</span>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={form.pro_valor_dinheiro} 
                      onChange={(e) => handlePrecoOuCustoChange('pro_valor_dinheiro', e.target.value)} 
                      placeholder="0.00"
                    />
                    <small>Preço especial para pagamento em dinheiro / PIX</small>
                  </div>

                  <div className="price-box vista">
                    <span className="price-box-label">💳 PREÇO À VISTA / PADRÃO (R$) *</span>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={form.valorv} 
                      onChange={(e) => handlePrecoOuCustoChange('valorv', e.target.value)} 
                      placeholder="0.00"
                    />
                    <small>Preço tabela padrão (Débito / 1x Cartão)</small>
                  </div>

                  <div className="price-box prazo">
                    <span className="price-box-label">📅 PREÇO A PRAZO (R$)</span>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={form.pro_valorv_prazo} 
                      onChange={(e) => handlePrecoOuCustoChange('pro_valorv_prazo', e.target.value)} 
                      placeholder="0.00"
                    />
                    <small>Preço a prazo / crediário / parcelado</small>
                  </div>
                </div>
              </div>

              {/* CARD DE CUSTOS & MARGEM */}
              <div className="product-section-card">
                <div className="product-section-title">
                  <TrendingUp size={16} color="#059669" /> Custos de Aquisição & Margem de Lucro
                </div>

                <div className="product-grid-4">
                  <div className="form-group">
                    <label>Custo de Entrada / Compra (R$)</label>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={form.custo} 
                      onChange={(e) => handlePrecoOuCustoChange('custo', e.target.value)} 
                    />
                  </div>

                  <div className="form-group">
                    <label>Custo Médio Ponderado (R$)</label>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={form.custo_medio} 
                      onChange={(e) => setForm({ ...form, custo_medio: parseFloat(e.target.value) || 0 })} 
                    />
                  </div>

                  <div className="form-group">
                    <label>Preço Sugerido (R$)</label>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={form.preco_sugerido} 
                      onChange={(e) => setForm({ ...form, preco_sugerido: parseFloat(e.target.value) || 0 })} 
                    />
                  </div>

                  <div className="form-group">
                    <label>Margem de Lucro Atual</label>
                    <div className={`margin-badge ${margemCalculada >= 30 ? 'positive' : 'warning'}`}>
                      <TrendingUp size={14} /> {margemCalculada.toFixed(2)}%
                    </div>
                  </div>

                  <div className="form-group">
                    <label>Estoque Geral Atual</label>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={form.quantidade} 
                      onChange={(e) => setForm({ ...form, quantidade: parseFloat(e.target.value) || 0 })} 
                    />
                  </div>

                  <div className="form-group">
                    <label>Estoque Mínimo</label>
                    <input 
                      type="number" 
                      step="1" 
                      value={form.quant_min} 
                      onChange={(e) => setForm({ ...form, quant_min: parseFloat(e.target.value) || 0 })} 
                    />
                  </div>

                  <div className="form-group">
                    <label>Dias de Validade</label>
                    <input 
                      type="number" 
                      step="1" 
                      value={form.dias_validade} 
                      onChange={(e) => setForm({ ...form, dias_validade: parseInt(e.target.value, 10) || 0 })} 
                    />
                  </div>
                </div>
              </div>

              {/* CARD DE GRADES E VARIAÇÕES COM OS 3 PREÇOS */}
              <div className="product-section-card">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.8rem', marginBottom: '1rem' }}>
                  <div className="product-section-title" style={{ margin: 0 }}>
                    <Grid size={16} color="#7c3aed" /> Grade de Variações (Tamanhos, Cores e os 3 Preços)
                  </div>

                  <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                    <button 
                      type="button" 
                      className="btn-secondary small" 
                      onClick={() => handleGerarGradeAutomatica('letras')}
                      title="Gerar P, M, G, GG"
                    >
                      <Sparkles size={14} /> Grade P-GG
                    </button>

                    <button 
                      type="button" 
                      className="btn-secondary small" 
                      onClick={() => handleGerarGradeAutomatica('numeros')}
                      title="Gerar 34 a 44"
                    >
                      <Sparkles size={14} /> Grade 34..44
                    </button>

                    <button 
                      type="button" 
                      className="btn-secondary small" 
                      onClick={handleGerarCodigosBarrasGrades}
                      title="Atalho F10: Gerar EAN13 para todas as grades"
                    >
                      <Barcode size={14} /> F10 - Gerar EANs
                    </button>
                  </div>
                </div>

                {/* FORMULÁRIO DE INCLUSÃO RÁPIDA DE ITEM NA GRADE */}
                <div className="grade-quick-form">
                  <div className="form-group">
                    <label>Tamanho *</label>
                    <select 
                      value={gradeForm.tam}
                      onChange={(e) => setGradeForm({ ...gradeForm, tam: e.target.value })}
                    >
                      {tamanhosList.map(t => (
                        <option key={t.codigo} value={t.codigo}>{t.sigla || t.tamanho} (#{t.codigo})</option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Cor</label>
                    <input 
                      type="text" 
                      value={gradeForm.cor} 
                      onChange={(e) => setGradeForm({ ...gradeForm, cor: e.target.value })} 
                      placeholder="Ex: PRETA" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Cód. Barras</label>
                    <input 
                      type="text" 
                      value={gradeForm.codbarra} 
                      onChange={(e) => setGradeForm({ ...gradeForm, codbarra: e.target.value })} 
                      placeholder="EAN13" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Qtd</label>
                    <input 
                      type="number" 
                      value={gradeForm.quantidade} 
                      onChange={(e) => setGradeForm({ ...gradeForm, quantidade: parseFloat(e.target.value) || 0 })} 
                    />
                  </div>

                  <div className="form-group">
                    <label>Vlr Dinheiro</label>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={gradeForm.valor_dinheiro} 
                      onChange={(e) => setGradeForm({ ...gradeForm, valor_dinheiro: parseFloat(e.target.value) || 0 })} 
                    />
                  </div>

                  <div className="form-group">
                    <label>Vlr Vista</label>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={gradeForm.valor} 
                      onChange={(e) => setGradeForm({ ...gradeForm, valor: parseFloat(e.target.value) || 0 })} 
                    />
                  </div>

                  <div className="form-group">
                    <label>Vlr Prazo</label>
                    <input 
                      type="number" 
                      step="0.01" 
                      value={gradeForm.valor_prazo} 
                      onChange={(e) => setGradeForm({ ...gradeForm, valor_prazo: parseFloat(e.target.value) || 0 })} 
                    />
                  </div>

                  <div>
                    <button 
                      type="button" 
                      className="btn-primary" 
                      onClick={handleAddOrUpdateGradeItem}
                      style={{ height: '38px', padding: '0 1rem', whiteSpace: 'nowrap' }}
                    >
                      {editingGradeIndex !== null ? 'Salvar Variação' : '+ Incluir'}
                    </button>
                  </div>
                </div>

                {/* TABELA DE GRADES CADASTRADAS */}
                <div className="table-responsive" style={{ maxHeight: '240px', overflowY: 'auto' }}>
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Tamanho</th>
                        <th>Cor</th>
                        <th>Cód. Barras</th>
                        <th style={{ textAlign: 'center' }}>Qtd</th>
                        <th style={{ textAlign: 'right' }}>Vlr Dinheiro</th>
                        <th style={{ textAlign: 'right' }}>Vlr Vista</th>
                        <th style={{ textAlign: 'right' }}>Vlr Prazo</th>
                        <th style={{ textAlign: 'center' }}>Ações</th>
                      </tr>
                    </thead>
                    <tbody>
                      {grades.length === 0 ? (
                        <tr>
                          <td colSpan="8" style={{ textAlign: 'center', padding: '1.5rem', color: '#94a3b8' }}>
                            Nenhuma variação ou grade adicionada ainda. Clique nos botões acima para gerar automaticamente.
                          </td>
                        </tr>
                      ) : (
                        grades.map((g, idx) => (
                          <tr key={idx}>
                            <td><strong>{g.tam_nome || g.tamanho?.sigla || g.tamanho?.tamanho || `Tam #${g.tam || g.gra_tam}`}</strong></td>
                            <td>{g.cor || g.gra_cor || 'UNICA'}</td>
                            <td style={{ fontFamily: 'monospace' }}>{g.codbarra || g.gra_codbarra || '-'}</td>
                            <td style={{ textAlign: 'center' }}><strong>{g.quantidade || g.gra_quantidade || 0}</strong></td>
                            <td style={{ textAlign: 'right', color: '#16a34a' }}>{formatCurrency(g.valor_dinheiro || g.gra_valor_dinheiro || g.valor || form.pro_valor_dinheiro)}</td>
                            <td style={{ textAlign: 'right', fontWeight: 700 }}>{formatCurrency(g.valor || g.gra_valor || form.valorv)}</td>
                            <td style={{ textAlign: 'right', color: '#2563eb' }}>{formatCurrency(g.valor_prazo || g.gra_valor_prazo || g.valor || form.pro_valorv_prazo)}</td>
                            <td style={{ textAlign: 'center' }}>
                              <button className="crud-row-btn edit" onClick={() => handleEditGradeItem(idx)} title="Editar Grade"><Edit2 size={14} /></button>
                              <button className="crud-row-btn delete" onClick={() => handleDeleteGradeItem(idx)} title="Excluir Grade"><Trash2 size={14} /></button>
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
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
                  <ImageIcon size={16} color="#2563eb" /> Foto Principal do Produto
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: 'minmax(200px, 300px) 1fr', gap: '1.5rem', alignItems: 'start' }}>
                  
                  {/* PREVIEW DA FOTO */}
                  <div className="product-photo-preview-box">
                    {form.url_Imagem ? (
                      <img src={form.url_Imagem} alt="Preview do Produto" className="product-photo-img" />
                    ) : (
                      <div className="product-photo-placeholder">
                        <ImageIcon size={48} color="#94a3b8" />
                        <span>Sem imagem vinculada</span>
                      </div>
                    )}
                  </div>

                  {/* CAMPOS DE URL / UPLOAD */}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    <div className="form-group">
                      <label>URL Direta da Imagem</label>
                      <input 
                        type="url" 
                        value={form.url_Imagem} 
                        onChange={(e) => setForm({ ...form, url_Imagem: e.target.value })} 
                        placeholder="https://exemplo.com/imagem.jpg" 
                      />
                    </div>

                    <div style={{ display: 'flex', gap: '0.6rem' }}>
                      {form.url_Imagem && (
                        <button 
                          type="button" 
                          className="btn-secondary" 
                          onClick={() => setForm({ ...form, url_Imagem: '' })}
                          style={{ color: '#dc2626' }}
                        >
                          <Trash2 size={16} /> Remover Foto
                        </button>
                      )}
                    </div>
                  </div>

                </div>
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* ABA 4: OUTROS & FISCAL                                    */}
          {/* ========================================================= */}
          {activeTab === 'fiscal' && (
            <div className="product-tab-content">
              
              {/* VÍNCULO FISCAL & TOTALIZADOR */}
              <div className="product-section-card">
                <div className="product-section-title">
                  <ShieldCheck size={16} color="#059669" /> Parâmetros Fiscais & Conciliação Contábil
                </div>

                <div className="product-grid-3">
                  <div className="form-group">
                    <label>NCM (Classificação Fiscal) *</label>
                    <input 
                      type="text" 
                      required 
                      value={form.ncm} 
                      onChange={(e) => setForm({ ...form, ncm: e.target.value })} 
                      placeholder="Ex: 6109.10.00" 
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
                      placeholder="Ex: 28.038.00" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Totalizador Fiscal (ICMS / ECF) *</label>
                    <select 
                      value={form.codTotalizador} 
                      onChange={(e) => setForm({ ...form, codTotalizador: Number(e.target.value) })}
                    >
                      <option value={1}>#1 - 01T1700 (Tributado ICMS 17%)</option>
                      <option value={2}>#2 - 02T1200 (Tributado ICMS 12%)</option>
                      <option value={3}>#3 - 03T2500 (Tributado ICMS 25%)</option>
                      <option value={4}>#4 - F1 (Substituição Tributária / ST)</option>
                      <option value={5}>#5 - I1 (Isento / Não Tributado)</option>
                      <option value={6}>#6 - N1 (Não Incidência)</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Cód. Produto Fiscal Mestre (Vínculo)</label>
                    <input 
                      type="number" 
                      value={form.pro_cod_fiscal} 
                      onChange={(e) => setForm({ ...form, pro_cod_fiscal: e.target.value })} 
                      placeholder="Ex: 85 (ID Fiscal)" 
                    />
                  </div>

                  <div className="form-group">
                    <label>Gerar NF Fiscal nesta Saída?</label>
                    <select 
                      value={form.pro_fiscal_gerar} 
                      onChange={(e) => setForm({ ...form, pro_fiscal_gerar: e.target.value })}
                    >
                      <option value="S">🟢 Sim (Emitir NF-e/NFC-e)</option>
                      <option value="N">🟡 Não (Venda Não Fiscal / Operacional)</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Permitir Estoque Negativo?</label>
                    <select 
                      value={form.pro_emitir_negativo} 
                      onChange={(e) => setForm({ ...form, pro_emitir_negativo: e.target.value })}
                    >
                      <option value="N">Não (Bloquear venda sem saldo)</option>
                      <option value="S">Sim (Permitir venda sem saldo)</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Produto Pesável (Balança)?</label>
                    <select 
                      value={form.balanca} 
                      onChange={(e) => setForm({ ...form, balanca: e.target.value })}
                    >
                      <option value="N">Não</option>
                      <option value="S">Sim (Etiqueta de Balança)</option>
                    </select>
                  </div>
                </div>
              </div>

            </div>
          )}

        </div>

        {/* RODAPÉ COM AÇÕES */}
        <div className="product-modal-footer">
          <div className="product-modal-footer-info">
            <span className="shortcut-hint"><strong>ESC</strong> Fechar</span>
            <span className="shortcut-hint"><strong>F4</strong> Grupos/Subgrupos</span>
            <span className="shortcut-hint"><strong>F10</strong> Gerar EANs</span>
            <span className="shortcut-hint"><strong>Ctrl+S</strong> Salvar</span>
          </div>

          <div style={{ display: 'flex', gap: '0.8rem' }}>
            <button type="button" className="btn-secondary" onClick={onClose}>Cancelar</button>
            <button 
              type="button" 
              className="btn-primary" 
              onClick={handleSave} 
              disabled={loading}
              style={{ minWidth: '160px' }}
            >
              {loading ? <RefreshCw size={18} className="spinner" /> : <Check size={18} />} Salvar Produto
            </button>
          </div>
        </div>

      </div>

      {/* SUBMODAIS */}
      {showGruposSubgruposModal && (
        <GruposSubgruposModal 
          isOpen={showGruposSubgruposModal} 
          onClose={() => setShowGruposSubgruposModal(false)}
          onSelect={(data) => {
            setForm(prev => ({ ...prev, pro_gru: data.subgrupo?.codigo || prev.pro_gru }));
            setShowGruposSubgruposModal(false);
          }}
        />
      )}
    </div>,
    document.body
  );
}
