import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Package, Plus, Trash2, Check, X, Edit2, Search, Grid, Image as ImageIcon, ArrowUpDown, Tag } from 'lucide-react';
import { createApi } from '../services/api';
import GradesModal from './GradesModal';
import GruposSubgruposModal from './GruposSubgruposModal';
import './ProductFormModal.css';

export default function ProductFormModal({ isOpen, onClose, productToEdit, onSaveSuccess, grupos = [], subgrupos = [], fornecedores = [] }) {
  if (!isOpen) return null;

  const api = createApi(true);

  const [mode, setMode] = useState(productToEdit ? 'browse' : 'insert'); // 'browse', 'insert', 'edit'
  const [loading, setLoading] = useState(false);

  // Submodals
  const [showGradesModal, setShowGradesModal] = useState(false);
  const [showGruposSubgruposModal, setShowGruposSubgruposModal] = useState(false);

  // Lista de grades do produto para preencher a mini tabela de Dados Específicos
  const [miniGrades, setMiniGrades] = useState([]);

  // Form State
  const [form, setForm] = useState({
    codigo: '',
    abc: 'N',
    nome: '',
    marca: 'GENERICA',
    cod_fabricante: '',
    fabricante: 'GENERICA',
    codbarra: '',
    pro_for: fornecedores[0]?.codigo || 1,
    local: 'L',
    ult_alteracao: new Date().toLocaleDateString('pt-BR'),

    // Grupo e SubGrupo
    pro_gru: subgrupos[0]?.codigo || 1,
    grupo_subgrupo_nome: 'BERMUDA > GENERICO',

    // Dados Específicos
    pro_valor_dinheiro: '0',
    valorv: '0', // Preço a Vista
    pro_valorv_prazo: '0', // Preço a Prazo
    quantidade: '0',
    custo: '0',
    custo_medio: '0',
    custo_mercadoria: '0',
    quant_min: '0',
    custo_operacional: '0',
    preco_sugerido: '0',
    ultima_compra: new Date().toLocaleDateString('pt-BR'),
    um: 'UN',

    // PAF-ECF / Fiscais
    ncm: '6109.10.00',
    excecao_ncm: '',
    gtin: '',
    situacao_tributaria: 'F - Substituição Tributária / 500 / 0.00',
    tipo_item: '00',
    genero: '',
    estado: 'ATIVO',
    aliq_icms_interna: '',
    perc_red_interna: '',
    ind_arredondamento: 'A',
    ind_producao: 'T',
    aliq_tributos: '',
    descricao_ncm: 'NCM não encontrado na tabela do IBPT',

    // Foto
    url_Imagem: ''
  });

  useEffect(() => {
    if (productToEdit) {
      const gCode = productToEdit.pro_gru || productToEdit.subgrupoId || 1;
      const sg = subgrupos.find(s => Number(s.codigo) === Number(gCode));
      const g = sg ? grupos.find(gr => Number(gr.codigo) === Number(sg.g1)) : null;
      const formattedGru = g && sg ? `${g.nome} > ${sg.nome}` : (sg ? sg.nome : 'GERAL');

      setForm({
        codigo: productToEdit.codigo || productToEdit.id,
        abc: productToEdit.abc || 'N',
        nome: productToEdit.nome || '',
        marca: productToEdit.marca || productToEdit.fabricante || 'GENERICA',
        cod_fabricante: productToEdit.cod_fabricante || productToEdit.codigo || '',
        fabricante: productToEdit.fabricante || 'GENERICA',
        codbarra: productToEdit.codbarra || '',
        pro_for: productToEdit.pro_for || productToEdit.fornecedorId || fornecedores[0]?.codigo || 1,
        local: productToEdit.local || 'L',
        ult_alteracao: productToEdit.ult_alteracao || new Date().toLocaleDateString('pt-BR'),

        pro_gru: gCode,
        grupo_subgrupo_nome: formattedGru,

        pro_valor_dinheiro: String(productToEdit.pro_valor_dinheiro ?? productToEdit.valorv ?? 0),
        valorv: String(productToEdit.valorv || 0),
        pro_valorv_prazo: String(productToEdit.pro_valorv_prazo ?? productToEdit.valorv ?? 0),
        quantidade: String(productToEdit.quantidade || 0),
        custo: String(productToEdit.custo || 0),
        custo_medio: String(productToEdit.custo_medio || 0),
        custo_mercadoria: String(productToEdit.custo_mercadoria || 0),
        quant_min: String(productToEdit.quant_min || 0),
        custo_operacional: String(productToEdit.custo_operacional || 0),
        preco_sugerido: String(productToEdit.preco_sugerido || 0),
        ultima_compra: productToEdit.ultima_compra || new Date().toLocaleDateString('pt-BR'),
        um: productToEdit.um || productToEdit.embalagem || 'UN',

        ncm: productToEdit.ncm || '6109.10.00',
        excecao_ncm: productToEdit.excecao_ncm || '',
        gtin: productToEdit.gtin || productToEdit.codbarra || '',
        situacao_tributaria: productToEdit.situacao_tributaria || 'F - Substituição Tributária / 500 / 0.00',
        tipo_item: productToEdit.tipo_item || '00',
        genero: productToEdit.genero || '',
        estado: productToEdit.estado || 'ATIVO',
        aliq_icms_interna: productToEdit.aliq_icms_interna || '',
        perc_red_interna: productToEdit.perc_red_interna || '',
        ind_arredondamento: productToEdit.ind_arredondamento || 'A',
        ind_producao: productToEdit.ind_producao || 'T',
        aliq_tributos: productToEdit.aliq_tributos || '',
        descricao_ncm: productToEdit.descricao_ncm || 'NCM não encontrado na tabela do IBPT',

        url_Imagem: productToEdit.url_Imagem || ''
      });
      fetchMiniGrades(productToEdit.codigo || productToEdit.id);
    } else {
      const nextCode = Math.floor(Math.random() * 90000) + 10000;
      setForm(prev => ({ ...prev, codigo: nextCode }));
    }
  }, [productToEdit]);

  // Atalhos Teclado: ESC (fechar), F2 (NCM), F4 (Grupos), F5 (Etiquetas), F6 (Marca), F9 (Pesquisa), F10 (Grades), Ctrl+S (Salvar)
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (showGradesModal || showGruposSubgruposModal) return;

      if (e.key === 'Escape') {
        onClose();
      } else if (e.key === 'F2') {
        e.preventDefault();
        const ncmEl = document.querySelector('input[name="ncm"], input[placeholder*="NCM"]');
        if (ncmEl) ncmEl.focus();
      } else if (e.key === 'F4') {
        e.preventDefault();
        setShowGruposSubgruposModal(true);
      } else if (e.key === 'F5') {
        e.preventDefault();
        alert(`F5: Etiquetas para o produto #${form.codigo || 'novo'}`);
      } else if (e.key === 'F6') {
        e.preventDefault();
        const marcaEl = document.querySelector('input[name="marca"], select[name="marca"]');
        if (marcaEl) marcaEl.focus();
      } else if (e.key === 'F9') {
        e.preventDefault();
        const nomeEl = document.querySelector('input[name="nome"]');
        if (nomeEl) nomeEl.focus();
      } else if (e.key === 'F10') {
        e.preventDefault();
        setShowGradesModal(true);
      } else if (e.ctrlKey && e.key.toLowerCase() === 's') {
        e.preventDefault();
        if (mode !== 'browse') handleSave();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onClose, showGradesModal, showGruposSubgruposModal, form, mode]);

  const fetchMiniGrades = async (prodCode) => {
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
      setMiniGrades(items);
    } catch (err) {
      console.warn('Erro ao buscar mini grades:', err);
    }
  };

  const handleSelectGrupoSubgrupoFromModal = (data) => {
    setForm(prev => ({
      ...prev,
      pro_gru: data.subgrupo.codigo,
      grupo_subgrupo_nome: data.formatted
    }));
  };

  const handleInsert = () => {
    setMode('insert');
    const nextCode = Math.floor(Math.random() * 90000) + 10000;
    setForm({
      codigo: nextCode,
      abc: 'N',
      nome: '',
      marca: 'GENERICA',
      cod_fabricante: String(nextCode),
      fabricante: 'GENERICA',
      codbarra: '',
      pro_for: fornecedores[0]?.codigo || 1,
      local: 'L',
      ult_alteracao: new Date().toLocaleDateString('pt-BR'),
      pro_gru: subgrupos[0]?.codigo || 1,
      grupo_subgrupo_nome: 'BERMUDA > GENERICO',
      pro_valor_dinheiro: '0',
      valorv: '0',
      pro_valorv_prazo: '0',
      quantidade: '0',
      custo: '0',
      custo_medio: '0',
      custo_mercadoria: '0',
      quant_min: '0',
      custo_operacional: '0',
      preco_sugerido: '0',
      ultima_compra: new Date().toLocaleDateString('pt-BR'),
      um: 'UN',
      ncm: '6109.10.00',
      excecao_ncm: '',
      gtin: '',
      situacao_tributaria: 'F - Substituição Tributária / 500 / 0.00',
      tipo_item: '00',
      genero: '',
      estado: 'ATIVO',
      aliq_icms_interna: '',
      perc_red_interna: '',
      ind_arredondamento: 'A',
      ind_producao: 'T',
      aliq_tributos: '',
      descricao_ncm: 'NCM não encontrado na tabela do IBPT',
      url_Imagem: ''
    });
  };

  const handleEdit = () => {
    setMode('edit');
  };

  const handleConfirm = async () => {
    if (!form.nome.trim()) {
      alert('Informe o nome do produto.');
      return;
    }
    setLoading(true);
    try {
      const vDin = Number(form.pro_valor_dinheiro) || Number(form.valorv) || 0;
      const vVis = Number(form.valorv) || 0;
      const vPrz = Number(form.pro_valorv_prazo) || Number(form.valorv) || 0;

      const payload = {
        codigo: Number(form.codigo),
        nome: form.nome.toUpperCase(),
        fabricante: form.fabricante,
        pro_for: Number(form.pro_for) || 1,
        forCodigo: Number(form.pro_for) || 1,
        fornecedorId: Number(form.pro_for) || 1,
        pro_gru: Number(form.pro_gru) || 1,
        gru: Number(form.pro_gru) || 1,
        subgrupoId: Number(form.pro_gru) || 1,
        codbarra: form.codbarra || form.gtin || '',
        quantidade: Number(form.quantidade) || 0,
        valorv: vVis,
        pro_valor_dinheiro: vDin,
        valor_dinheiro: vDin,
        valordinheiro: vDin,
        valorDinheiro: vDin,
        pro_valorv_prazo: vPrz,
        valor_prazo: vPrz,
        valorprazo: vPrz,
        valorPrazo: vPrz,
        codTotalizador: 1,
        ncm: form.ncm || '6109.10.00',
        um: form.um || 'UN',
        embalagem: form.um || 'UN',
        cadastrar: 'S',
        url_Imagem: form.url_Imagem || ''
      };

      if (mode === 'insert') {
        await api.post('/v1/produtos', payload);
      } else {
        await api.put('/v1/produtos', payload);
      }
      setMode('browse');
      alert('Produto salvo com sucesso!');
      if (onSaveSuccess) onSaveSuccess();
    } catch (err) {
      alert('Erro ao salvar produto.');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!form.codigo) return;
    if (!window.confirm(`Tem certeza que deseja excluir o produto #${form.codigo}?`)) return;
    setLoading(true);
    try {
      await api.delete(`/v1/produtos/${form.codigo}`);
      alert('Produto excluído com sucesso!');
      if (onSaveSuccess) onSaveSuccess();
      onClose();
    } catch (err) {
      alert('Erro ao excluir produto.');
    } finally {
      setLoading(false);
    }
  };

  const handleAddPhotoUrl = () => {
    const url = window.prompt('Informe a URL da foto do produto:', form.url_Imagem);
    if (url !== null) {
      setForm(prev => ({ ...prev, url_Imagem: url }));
    }
  };

  const handleRemovePhoto = () => {
    setForm(prev => ({ ...prev, url_Imagem: '' }));
  };

  return createPortal(
    <div className="legacy-modal-overlay">
      <div className="legacy-modal-window pro-modal-window">
        {/* Header do Pop-up */}
        <div className="legacy-modal-header">
          <div className="legacy-modal-title">
            <Package size={18} />
            <span>CADASTRO DE PRODUTOS</span>
          </div>

          {/* Barra de Comando Principal Superior */}
          <div className="pro-command-bar">
            <button className="legacy-cmd-btn btn-insert" onClick={handleInsert} disabled={mode !== 'browse'}>
              <Plus size={16} /> Inserir
            </button>
            <button className="legacy-cmd-btn btn-delete" onClick={handleDelete} disabled={mode !== 'browse' || !productToEdit}>
              <Trash2 size={16} /> Excluir
            </button>
            <button className="legacy-cmd-btn btn-confirm" onClick={handleConfirm} disabled={mode === 'browse' || loading}>
              <Check size={16} /> {loading ? 'Salvando...' : 'Confirmar'}
            </button>
            <button className="legacy-cmd-btn btn-cancel" onClick={() => setMode('browse')} disabled={mode === 'browse'}>
              <X size={16} /> Cancelar
            </button>
            <button className="legacy-cmd-btn btn-edit" onClick={handleEdit} disabled={mode !== 'browse'}>
              <Edit2 size={16} /> Editar
            </button>
          </div>

          <button className="legacy-modal-close-btn" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        {/* Corpo em 3 Bloco de Seções com Botões Laterais */}
        <div className="pro-modal-body">
          <div className="pro-left-sections">
            
            {/* SEÇÃO 1: DADOS GERAIS */}
            <fieldset className="pro-fieldset">
              <legend>Dados Gerais</legend>
              <div className="pro-fields-grid-1">
                <div className="pro-field" style={{ flex: '0 0 90px', minWidth: 0 }}>
                  <label>Código</label>
                  <input type="text" value={form.codigo} readOnly className="legacy-input pro-code-input" />
                </div>
                <div className="pro-field" style={{ flex: '0 0 70px', minWidth: 0 }}>
                  <label>ABC</label>
                  <input type="text" value={form.abc} onChange={e => setForm({ ...form, abc: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                </div>
                <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                  <label>*Grupo &gt; SubGrupo ⬇️</label>
                  <div style={{ display: 'flex', gap: '4px', minWidth: 0 }}>
                    <input type="text" value={form.grupo_subgrupo_nome} readOnly className="legacy-input" style={{ fontWeight: 700 }} />
                    <button type="button" className="btn-search-gru" onClick={() => setShowGruposSubgruposModal(true)} title="Pesquisar Grupos (F4)">
                      <Search size={14} />
                    </button>
                  </div>
                </div>
                <div className="pro-field" style={{ flex: '0 0 160px', minWidth: 0 }}>
                  <label>Marca</label>
                  <input type="text" value={form.marca} onChange={e => setForm({ ...form, marca: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                </div>
              </div>

              <div className="pro-fields-grid-2">
                <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                  <label>*Nome</label>
                  <input type="text" value={form.nome} onChange={e => setForm({ ...form, nome: e.target.value })} disabled={mode === 'browse'} className="legacy-input" required />
                </div>
                <div className="pro-field" style={{ flex: '0 0 160px', minWidth: 0 }}>
                  <label>Cód. Fabricante</label>
                  <input type="text" value={form.cod_fabricante} onChange={e => setForm({ ...form, cod_fabricante: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                </div>
              </div>

              <div className="pro-fields-grid-3">
                <div className="pro-field" style={{ flex: '0 0 150px', minWidth: 0 }}>
                  <label>Cód. Barra</label>
                  <input type="text" value={form.codbarra} onChange={e => setForm({ ...form, codbarra: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                </div>
                <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                  <label>*Fornecedor</label>
                  <select value={form.pro_for} onChange={e => setForm({ ...form, pro_for: e.target.value })} disabled={mode === 'browse'} className="legacy-input">
                    {fornecedores.map(f => (
                      <option key={f.codigo || f.id} value={f.codigo || f.id}>
                        {f.nome || f.razao_social}
                      </option>
                    ))}
                    {fornecedores.length === 0 && <option value={1}>GENERICO</option>}
                  </select>
                </div>
                <div className="pro-field" style={{ flex: '0 0 160px', minWidth: 0 }}>
                  <label>Fabricante</label>
                  <input type="text" value={form.fabricante} onChange={e => setForm({ ...form, fabricante: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                </div>
              </div>

              <div className="pro-fields-grid-4">
                <div className="pro-field" style={{ flex: '0 0 100px', minWidth: 0 }}>
                  <label>Local</label>
                  <input type="text" value={form.local} onChange={e => setForm({ ...form, local: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                </div>
                <div className="pro-field" style={{ flex: '0 0 120px', minWidth: 0 }}>
                  <label>Últ. Alteração</label>
                  <input type="text" value={form.ult_alteracao} readOnly className="legacy-input read-only" />
                </div>
              </div>
            </fieldset>

            {/* SEÇÃO 2: DADOS ESPECÍFICOS */}
            <fieldset className="pro-fieldset">
              <legend>Dados Específicos</legend>
              <div className="pro-especificos-container">
                <div className="pro-especificos-inputs">
                  <div className="pro-fields-row">
                    <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                      <label>Valor Dinheiro</label>
                      <input type="number" step="0.01" value={form.pro_valor_dinheiro} onChange={e => setForm({ ...form, pro_valor_dinheiro: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                    </div>
                    <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                      <label>Preço a Vista</label>
                      <input type="number" step="0.01" value={form.valorv} onChange={e => setForm({ ...form, valorv: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                    </div>
                    <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                      <label>Preço a Prazo</label>
                      <input type="number" step="0.01" value={form.pro_valorv_prazo} onChange={e => setForm({ ...form, pro_valorv_prazo: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                    </div>
                    <div className="pro-field" style={{ flex: '0 0 80px', minWidth: 0 }}>
                      <label>Quantidade</label>
                      <input type="number" value={form.quantidade} onChange={e => setForm({ ...form, quantidade: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                    </div>
                  </div>

                  <div className="pro-fields-row">
                    <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                      <label>Custo</label>
                      <input type="number" step="0.01" value={form.custo} onChange={e => setForm({ ...form, custo: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                    </div>
                    <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                      <label>Custo Médio</label>
                      <input type="number" step="0.01" value={form.custo_medio} onChange={e => setForm({ ...form, custo_medio: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                    </div>
                    <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                      <label>Custo Mercadoria</label>
                      <input type="number" step="0.01" value={form.custo_mercadoria} onChange={e => setForm({ ...form, custo_mercadoria: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                    </div>
                    <div className="pro-field" style={{ flex: '0 0 80px', minWidth: 0 }}>
                      <label>Quant Mín</label>
                      <input type="number" value={form.quant_min} onChange={e => setForm({ ...form, quant_min: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                    </div>
                  </div>

                  <div className="pro-fields-row">
                    <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                      <label>Custo Operacional</label>
                      <input type="number" step="0.01" value={form.custo_operacional} onChange={e => setForm({ ...form, custo_operacional: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                    </div>
                    <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                      <label>Preço Sugerido</label>
                      <input type="number" step="0.01" value={form.preco_sugerido} onChange={e => setForm({ ...form, preco_sugerido: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                    </div>
                    <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                      <label>Última Compra</label>
                      <input type="text" value={form.ultima_compra} onChange={e => setForm({ ...form, ultima_compra: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                    </div>
                    <div className="pro-field" style={{ flex: '0 0 80px', minWidth: 0 }}>
                      <label>Embalagem</label>
                      <input type="text" value={form.um} onChange={e => setForm({ ...form, um: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                    </div>
                  </div>
                </div>

                {/* Mini Tabela de Grades */}
                <div className="pro-mini-grades-box">
                  <div className="mini-grades-header">Grades</div>
                  <div className="mini-grades-table-container">
                    <table className="mini-grades-table">
                      <thead>
                        <tr>
                          <th>TAMANHO</th>
                          <th style={{ textAlign: 'center' }}>QUANT</th>
                          <th style={{ textAlign: 'right' }}>VALOR</th>
                        </tr>
                      </thead>
                      <tbody>
                        {miniGrades.map((g, idx) => (
                          <tr key={g.codigo || idx}>
                            <td><strong>{g.tam || g.tamanho}</strong></td>
                            <td style={{ textAlign: 'center' }}>{g.quantidade || 0}</td>
                            <td style={{ textAlign: 'right' }}>R$ {Number(g.valor || 0).toFixed(2)}</td>
                          </tr>
                        ))}
                        {miniGrades.length === 0 && (
                          <tr>
                            <td colSpan="3" className="empty-table-cell" style={{ fontSize: '0.75rem' }}>Nenhuma grade cadastrada.</td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </fieldset>

            {/* SEÇÃO 3: DADOS PAF-ECF / FISCAIS */}
            <fieldset className="pro-fieldset">
              <legend>Dados PAF-ECF / Fiscais</legend>
              <div className="pro-paf-grid-1">
                <div className="pro-field" style={{ flex: '0 0 110px', minWidth: 0 }}>
                  <label>NCM</label>
                  <input type="text" value={form.ncm} onChange={e => setForm({ ...form, ncm: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                </div>
                <div className="pro-field" style={{ flex: '0 0 110px', minWidth: 0 }}>
                  <label>Exceção NCM</label>
                  <input type="text" value={form.excecao_ncm} onChange={e => setForm({ ...form, excecao_ncm: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                </div>
                <div className="pro-field" style={{ flex: '0 0 130px', minWidth: 0 }}>
                  <label>*GTIN</label>
                  <input type="text" value={form.gtin || form.codbarra} onChange={e => setForm({ ...form, gtin: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                </div>
                <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                  <label>Situação Tributária / Alíquota ICMS</label>
                  <select value={form.situacao_tributaria} onChange={e => setForm({ ...form, situacao_tributaria: e.target.value })} disabled={mode === 'browse'} className="legacy-input">
                    <option value="F - Substituição Tributária / 500 / 0.00">F - Substituição Tributária / 500 / 0.00</option>
                    <option value="01T1700 - Tributado ICMS 17%">01T1700 - Tributado ICMS 17%</option>
                    <option value="02T1200 - Tributado ICMS 12%">02T1200 - Tributado ICMS 12%</option>
                    <option value="I1 - Isento / Não Tributado">I1 - Isento / Não Tributado</option>
                  </select>
                </div>
              </div>

              <div className="pro-paf-grid-2">
                <div className="pro-field" style={{ flex: '0 0 120px', minWidth: 0 }}>
                  <label>*Unid. Medida</label>
                  <select value={form.um} onChange={e => setForm({ ...form, um: e.target.value })} disabled={mode === 'browse'} className="legacy-input">
                    <option value="UN">UNIDADE (UN)</option>
                    <option value="PC">PECA (PC)</option>
                    <option value="CX">CAIXA (CX)</option>
                    <option value="KG">QUILOGRAMA (KG)</option>
                  </select>
                </div>
                <div className="pro-field" style={{ flex: '0 0 110px', minWidth: 0 }}>
                  <label>*Tipo Item</label>
                  <input type="text" value={form.tipo_item} onChange={e => setForm({ ...form, tipo_item: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                </div>
                <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                  <label>Gênero</label>
                  <input type="text" value={form.genero} onChange={e => setForm({ ...form, genero: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                </div>
                <div className="pro-field" style={{ flex: '0 0 110px', minWidth: 0 }}>
                  <label>*Estado</label>
                  <select value={form.estado} onChange={e => setForm({ ...form, estado: e.target.value })} disabled={mode === 'browse'} className="legacy-input">
                    <option value="ATIVO">ATIVO</option>
                    <option value="INATIVO">INATIVO</option>
                  </select>
                </div>
              </div>

              <div className="pro-paf-grid-3">
                <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                  <label>Alíq. ICMS Ops. Internas</label>
                  <input type="text" value={form.aliq_icms_interna} onChange={e => setForm({ ...form, aliq_icms_interna: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                </div>
                <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                  <label>Perc. Red. Ops. Internas</label>
                  <input type="text" value={form.perc_red_interna} onChange={e => setForm({ ...form, perc_red_interna: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                </div>
                <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                  <label>*Ind. Arredondamento/Truncamento</label>
                  <select value={form.ind_arredondamento} onChange={e => setForm({ ...form, ind_arredondamento: e.target.value })} disabled={mode === 'browse'} className="legacy-input">
                    <option value="A">A - Arredondamento</option>
                    <option value="T">T - Truncamento</option>
                  </select>
                </div>
              </div>

              <div className="pro-paf-grid-4">
                <div className="pro-field" style={{ flex: '0 0 180px', minWidth: 0 }}>
                  <label>*Ind. Produção Própria/Terceiros</label>
                  <select value={form.ind_producao} onChange={e => setForm({ ...form, ind_producao: e.target.value })} disabled={mode === 'browse'} className="legacy-input">
                    <option value="T">T - Terceiros</option>
                    <option value="P">P - Própria</option>
                  </select>
                </div>
                <div className="pro-field flex-1" style={{ minWidth: 0 }}>
                  <label>Alíquotas aproximadas de Tributos</label>
                  <input type="text" value={form.aliq_tributos} onChange={e => setForm({ ...form, aliq_tributos: e.target.value })} disabled={mode === 'browse'} className="legacy-input" />
                </div>
              </div>

              <div className="pro-field" style={{ marginTop: '0.4rem' }}>
                <label>Descrição do NCM</label>
                <input type="text" value={form.descricao_ncm} readOnly className="legacy-input read-only" />
              </div>
            </fieldset>
          </div>

          {/* Painel Lateral Direito: Foto + Botões de Atalho Legados */}
          <div className="pro-right-sidebar">
            {/* Foto do Produto */}
            <div className="pro-photo-container">
              <div className="pro-photo-box">
                {form.url_Imagem ? (
                  <img src={form.url_Imagem} alt="Foto Produto" className="pro-photo-img" />
                ) : (
                  <div className="pro-photo-placeholder">
                    <ImageIcon size={32} />
                    <span>Foto não carregada</span>
                  </div>
                )}
              </div>
              <div className="pro-photo-actions">
                <button type="button" className="btn-photo-action" onClick={handleAddPhotoUrl} disabled={mode === 'browse'}>
                  <Plus size={16} />
                </button>
                <button type="button" className="btn-photo-action" onClick={handleRemovePhoto} disabled={mode === 'browse' || !form.url_Imagem}>
                  <Trash2 size={16} />
                </button>
              </div>
            </div>

            {/* Botões Laterais com Ícones Legados */}
            <div className="pro-side-shortcuts">
              <button type="button" className="pro-shortcut-card" onClick={() => setShowGradesModal(true)}>
                <Grid size={24} />
                <span># Grade</span>
              </button>

              <button type="button" className="pro-shortcut-card" onClick={() => alert(`Ajuste de Estoque para o Produto #${form.codigo}`)}>
                <ArrowUpDown size={24} />
                <span>Ajuste Estoque</span>
              </button>
            </div>
          </div>
        </div>

        {/* Rodapé com Teclas de Atalho */}
        <div className="legacy-modal-footer">
          <div className="legacy-shortcuts">
            <span className="shortcut-tag"><kbd>ESC</kbd> Sair</span>
            <span className="shortcut-tag"><kbd>F2</kbd> Cad. NCM</span>
            <span className="shortcut-tag"><kbd>F4</kbd> Cad. Grupo</span>
            <span className="shortcut-tag"><kbd>F5</kbd> Etiquetas</span>
            <span className="shortcut-tag"><kbd>F6</kbd> Cad. Marca</span>
            <span className="shortcut-tag"><kbd>F9</kbd> Pesquisa</span>
          </div>
        </div>
      </div>

      {/* Submodal de Grupos e SubGrupos */}
      {showGruposSubgruposModal && (
        <GruposSubgruposModal
          isOpen={showGruposSubgruposModal}
          onClose={() => setShowGruposSubgruposModal(false)}
          onSelectGrupoSubgrupo={handleSelectGrupoSubgrupoFromModal}
        />
      )}

      {/* Submodal de Grades */}
      {showGradesModal && (
        <GradesModal
          isOpen={showGradesModal}
          onClose={() => setShowGradesModal(false)}
          product={form}
          onGradesUpdated={() => fetchMiniGrades(form.codigo)}
        />
      )}
    </div>,
    document.body
  );
}
