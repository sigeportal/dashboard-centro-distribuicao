import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Grid, Plus, Trash2, Check, X, Edit2, Barcode, AlertCircle } from 'lucide-react';
import { createApi } from '../services/api';
import { toast } from '../contexts/ToastContext';
import './GradesModal.css';

// Função de cálculo do Dígito Verificador EAN-13 do sistema legado (UnitFuncoesUtils.pas / GeraDVEAN)
function geraDVEAN(cadeia) {
  const str = String(cadeia).replace(/\s+/g, '');
  let indice = 3;
  let soma = 0;
  for (let i = str.length - 1; i >= 0; i--) {
    soma += parseInt(str[i], 10) * indice;
    indice = Math.abs(4 - indice);
  }
  let dv = (((Math.floor(soma / 10)) + 1) * 10) - soma;
  if (dv > 9) dv = 0;
  return dv.toString();
}

// Gera código de barras EAN-13 no padrão 189600 + 6 dígitos + DV (UnitCadGrades.pas)
function geraCodBarraGrade(gradeCodigo) {
  const codPadded = String(gradeCodigo || 1).padStart(6, '0');
  const cadeia = '18960000' + codPadded;
  const dv = geraDVEAN(cadeia);
  return '189600' + codPadded + dv;
}

export default function GradesModal({ isOpen, onClose, product, onGradesUpdated }) {
  if (!isOpen) return null;

  const api = createApi(true);

  const [grades, setGrades] = useState([]);
  const [selectedGrade, setSelectedGrade] = useState(null);
  const [mode, setMode] = useState('browse'); // 'browse', 'insert', 'edit'
  const [loading, setLoading] = useState(false);

  const [form, setForm] = useState({
    codigo: '',
    pro: product?.codigo || product?.id || 0,
    tam: 'M',
    cor: 'PADRAO',
    quantidade: '0',
    valor_dinheiro: product?.pro_valor_dinheiro ?? product?.valordinheiro ?? product?.valorv ?? '0',
    valor: product?.valorv || '0', // Vlr Vista
    valor_prazo: product?.pro_valorv_prazo ?? product?.valorprazo ?? product?.valorv ?? '0',
    codbarra: ''
  });

  const [tamanhosList, setTamanhosList] = useState([]);

  const tamanhosDisponiveis = ['P', 'M', 'G', 'GG', 'XG', 'XXG', '34', '36', '38', '40', '42', '44', '46', '48', '50', 'UN'];
  const coresDisponiveis = ['PADRAO', 'PRETO', 'BRANCO', 'AZUL', 'VERMELHO', 'AMARELO', 'VERDE', 'CINZA', 'ROSA', 'BEGE', 'MARROM', 'ESTAMPADO'];

  useEffect(() => {
    fetchTamanhos();
    if (product) {
      fetchGradesForProduct();
    }
  }, [product]);

  const fetchTamanhos = async () => {
    try {
      const res = await api.get('/v1/tamanhos?limit=100');
      const items = Array.isArray(res.data) ? res.data : (res.data?.data || []);
      setTamanhosList(items);
    } catch (e) {
      console.warn('Erro ao buscar tamanhos:', e);
    }
  };

  // Atalhos de Teclado (ESC fecha, F2 novo, F10 gera código de barras, Ctrl+S salva)
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape') {
        onClose();
      } else if (e.key === 'F10') {
        e.preventDefault();
        handleGenerateBarcode();
      } else if (e.key === 'F2' || e.key === 'Insert') {
        e.preventDefault();
        if (mode === 'browse') handleInsert();
      } else if (e.ctrlKey && e.key.toLowerCase() === 's') {
        e.preventDefault();
        if (mode !== 'browse') handleConfirm();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onClose, form, mode, grades]);

  const fetchGradesForProduct = async () => {
    setLoading(true);
    try {
      const prodCode = product.codigo || product.id || product.pro_codigo;
      let items = [];
      try {
        const resProd = await api.get(`/v1/grades/produto/${prodCode}`);
        if (Array.isArray(resProd.data)) items = resProd.data;
        else if (resProd.data?.data) items = resProd.data.data;
      } catch (e1) {
        const resAll = await api.get(`/v1/grades?limit=500`);
        const all = Array.isArray(resAll.data) ? resAll.data : (resAll.data?.data || []);
        items = all.filter(g => String(g.pro || g.gra_pro || g.produtoId) === String(prodCode));
      }
      setGrades(items);
      if (items.length > 0) {
        handleSelectGrade(items[0]);
      } else {
        setSelectedGrade(null);
      }
    } catch (err) {
      console.error('Erro ao buscar grades do produto:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSelectGrade = (g) => {
    setSelectedGrade(g);
    setForm({
      codigo: g.codigo || g.id,
      pro: g.pro || product.codigo,
      tam: g.tam || g.tamanho || (tamanhosList[0]?.codigo || 'M'),
      cor: g.cor || 'PADRAO',
      quantidade: String(g.quantidade || 0),
      valor_dinheiro: String(g.valor_dinheiro ?? g.valorDinheiro ?? g.valordinheiro ?? g.valor ?? 0),
      valor: String(g.valor || 0),
      valor_prazo: String(g.valor_prazo ?? g.valorPrazo ?? g.valorprazo ?? g.valor ?? 0),
      codbarra: g.codbarra || ''
    });
    setMode('browse');
  };

  // Gerador de código de barras (Individial ou Em Lote para todas as grades - Legado Delphi)
  const handleGenerateAllBarcodes = async () => {
    if (grades.length === 0) {
      toast.warning('Nenhuma grade cadastrada para este produto.');
      return;
    }
    if (!window.confirm('Deseja gerar código de barras EAN-13 para TODAS as grades deste produto?')) return;

    setLoading(true);
    try {
      const updatedGrades = grades.map(g => ({
        codigo: Number(g.codigo || g.id),
        pro: Number(product?.codigo || product?.id),
        tam: Number(g.tam || g.tamanho || 1),
        cor: g.cor || 'PADRAO',
        quantidade: Number(g.quantidade || 0),
        valor: Number(g.valor || 0),
        valor_dinheiro: Number(g.valor_dinheiro ?? g.valorDinheiro ?? g.valordinheiro ?? g.valor ?? 0),
        valorDinheiro: Number(g.valor_dinheiro ?? g.valorDinheiro ?? g.valordinheiro ?? g.valor ?? 0),
        valor_prazo: Number(g.valor_prazo ?? g.valorPrazo ?? g.valorprazo ?? g.valor ?? 0),
        valorPrazo: Number(g.valor_prazo ?? g.valorPrazo ?? g.valorprazo ?? g.valor ?? 0),
        codbarra: geraCodBarraGrade(g.codigo || g.id)
      }));

      await api.post('/v1/grades/emLote', { itens: updatedGrades });
      toast.success('Cód. de Barras das Grades gerado com sucesso!');
      await fetchGradesForProduct();
      if (onGradesUpdated) onGradesUpdated();
    } catch (err) {
      console.error(err);
      toast.error('Erro ao gerar Cód. de Barras das Grades.');
    } finally {
      setLoading(false);
    }
  };

  const handleGenerateBarcode = () => {
    if (mode === 'browse') {
      handleGenerateAllBarcodes();
    } else {
      const barcode = geraCodBarraGrade(form.codigo || 1);
      setForm(prev => ({ ...prev, codbarra: barcode }));
    }
  };

  const handleInsert = () => {
    setMode('insert');
    const nextCode = grades.length > 0 ? Math.max(...grades.map(g => Number(g.codigo) || 0)) + 1 : 1;
    const defaultValDin = product?.pro_valor_dinheiro ?? product?.valordinheiro ?? product?.valorv ?? 0;
    const defaultValVis = product?.valorv || 0;
    const defaultValPrz = product?.pro_valorv_prazo ?? product?.valorprazo ?? product?.valorv ?? 0;
    const defaultTam = tamanhosList.length > 0 ? tamanhosList[0].codigo : 'M';

    setForm({
      codigo: nextCode,
      pro: product?.codigo || product?.id,
      tam: defaultTam,
      cor: 'PADRAO',
      quantidade: '0',
      valor_dinheiro: String(defaultValDin),
      valor: String(defaultValVis),
      valor_prazo: String(defaultValPrz),
      codbarra: geraCodBarraGrade(nextCode)
    });
  };

  const handleEdit = () => {
    if (!selectedGrade) return;
    setMode('edit');
  };

  const handleConfirm = async () => {
    setLoading(true);
    try {
      let sizeId = 1;
      const matchedTam = tamanhosList.find(t => 
        String(t.codigo) === String(form.tam) || 
        t.sigla === form.tam || 
        t.tamanho === form.tam
      );
      if (matchedTam) {
        sizeId = Number(matchedTam.codigo);
      } else {
        const parsedNum = Number(form.tam);
        if (!isNaN(parsedNum) && parsedNum > 0) {
          sizeId = parsedNum;
        } else {
          sizeId = (tamanhosDisponiveis.indexOf(form.tam) >= 0 ? tamanhosDisponiveis.indexOf(form.tam) + 1 : 1);
        }
      }

      const payload = {
        codigo: Number(form.codigo),
        pro: Number(product?.codigo || product?.id),
        tam: sizeId,
        cor: form.cor || 'PADRAO',
        quantidade: Number(form.quantidade) || 0,
        valor: Number(form.valor) || 0,
        valor_dinheiro: Number(form.valor_dinheiro) || 0,
        valorDinheiro: Number(form.valor_dinheiro) || 0,
        valor_prazo: Number(form.valor_prazo) || 0,
        valorPrazo: Number(form.valor_prazo) || 0,
        codbarra: form.codbarra || ''
      };

      if (mode === 'insert') {
        await api.post('/v1/grades', payload);
      } else {
        await api.put('/v1/grades', payload);
      }
      setMode('browse');
      await fetchGradesForProduct();
      if (onGradesUpdated) onGradesUpdated();
    } catch (err) {
      console.error('Erro ao salvar grade:', err);
      toast.error('Erro ao salvar grade. Verifique se os campos estão corretos.');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedGrade) return;
    if (!window.confirm('Deseja realmente excluir este registro?')) return;
    setLoading(true);
    try {
      await api.delete(`/v1/grades/${selectedGrade.codigo}`);
      setSelectedGrade(null);
      await fetchGradesForProduct();
      if (onGradesUpdated) onGradesUpdated();
    } catch (err) {
      toast.error('Erro ao excluir grade.');
    } finally {
      setLoading(false);
    }
  };

  const totalGradeQty = grades.reduce((acc, g) => acc + (Number(g.quantidade || g.gra_quantidade) || 0), 0);
  const productName = product ? `[#${product.codigo || product.id || product.pro_codigo}] ${product.nome || product.descricao || ''}` : '';

  return createPortal(
    <div className="grades-modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}>
      <div className="grades-modal-container glass">
        {/* Cabeçalho Padronizado */}
        <div className="grades-modal-header">
          <div className="grades-title-wrap">
            <div className="grades-icon-badge">
              <Grid size={20} />
            </div>
            <div>
              <div className="grades-header-title-line">
                <h3>Cadastro de Grades & Variações</h3>
                <span className="grades-total-badge" title="Somatória física de todas as variações (GRA_QUANTIDADE)">
                  Total: {totalGradeQty} UN
                </span>
              </div>
              <span className="grades-subtitle">
                {productName ? `Produto: ${productName}` : 'Variações de tamanho, cor, preços e código de barras'}
              </span>
            </div>
          </div>
          <button className="grades-btn-close" onClick={onClose} title="Fechar (ESC)">
            <X size={20} />
          </button>
        </div>

        {/* Corpo do Modal */}
        <div className="grades-modal-body">
          {/* Card de Formulário Superior */}
          <div className="grades-form-card">
            <div className="grades-inputs-grid">
              <div className="grades-input-field">
                <label>Código</label>
                <input 
                  type="text" 
                  value={form.codigo} 
                  readOnly 
                  className="grades-input grades-input-readonly" 
                />
              </div>

              <div className="grades-input-field">
                <label>*Tamanho</label>
                <select 
                  value={form.tam} 
                  onChange={(e) => setForm({ ...form, tam: e.target.value })}
                  disabled={mode === 'browse'}
                  className="grades-input"
                  required
                >
                  {tamanhosList.length > 0 ? (
                    tamanhosList.map(t => (
                      <option key={t.codigo} value={t.codigo}>
                        {t.sigla ? `${t.sigla} - ${t.tamanho || ''}` : t.tamanho}
                      </option>
                    ))
                  ) : (
                    tamanhosDisponiveis.map(t => <option key={t} value={t}>{t}</option>)
                  )}
                </select>
              </div>

              <div className="grades-input-field">
                <label>Cor</label>
                <select 
                  value={form.cor} 
                  onChange={(e) => setForm({ ...form, cor: e.target.value })}
                  disabled={mode === 'browse'}
                  className="grades-input"
                >
                  {coresDisponiveis.map(c => <option key={c} value={c}>{c}</option>)}
                </select>
              </div>

              <div className="grades-input-field">
                <label>Quantidade</label>
                <input 
                  type="number" 
                  value={form.quantidade} 
                  onChange={(e) => setForm({ ...form, quantidade: e.target.value })}
                  disabled={mode === 'browse'}
                  className="grades-input"
                />
              </div>

              <div className="grades-input-field">
                <label>Vlr Dinheiro</label>
                <input 
                  type="number" 
                  step="0.01"
                  value={form.valor_dinheiro} 
                  onChange={(e) => setForm({ ...form, valor_dinheiro: e.target.value })}
                  disabled={mode === 'browse'}
                  className="grades-input"
                />
              </div>

              <div className="grades-input-field">
                <label>Vlr Vista</label>
                <input 
                  type="number" 
                  step="0.01"
                  value={form.valor} 
                  onChange={(e) => setForm({ ...form, valor: e.target.value })}
                  disabled={mode === 'browse'}
                  className="grades-input"
                />
              </div>

              <div className="grades-input-field">
                <label>Vlr Prazo</label>
                <input 
                  type="number" 
                  step="0.01"
                  value={form.valor_prazo} 
                  onChange={(e) => setForm({ ...form, valor_prazo: e.target.value })}
                  disabled={mode === 'browse'}
                  className="grades-input"
                />
              </div>

              <div className="grades-input-field grades-barcode-col">
                <label>Cód. Barras (EAN-13)</label>
                <div className="grades-barcode-input-wrap">
                  <input 
                    type="text" 
                    value={form.codbarra} 
                    onChange={(e) => setForm({ ...form, codbarra: e.target.value })}
                    disabled={mode === 'browse'}
                    className="grades-input"
                    placeholder="EAN-13 (F10)"
                  />
                  <button 
                    type="button"
                    className="grades-btn-barcode"
                    onClick={handleGenerateBarcode}
                    disabled={loading}
                    title="Gerar Cód. Barras EAN-13 (F10)"
                  >
                    <Barcode size={16} />
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Tabela Central e Botões Laterais */}
          <div className="grades-table-and-actions">
            <div className="grades-table-container">
              <table className="grades-data-table">
                <thead>
                  <tr>
                    <th style={{ width: '80px' }}>CÓDIGO</th>
                    <th style={{ width: '90px' }}>TAMANHO</th>
                    <th style={{ textAlign: 'right', width: '110px' }}>VLR DINHEIRO</th>
                    <th style={{ textAlign: 'right', width: '110px' }}>VLR VISTA</th>
                    <th style={{ textAlign: 'right', width: '110px' }}>VLR PRAZO</th>
                    <th style={{ textAlign: 'center', width: '85px' }}>QUANT</th>
                    <th>CÓD. BARRAS (EAN-13)</th>
                    <th style={{ width: '110px' }}>COR</th>
                  </tr>
                </thead>
                <tbody>
                  {grades.map((g) => {
                    const isSelected = selectedGrade && String(selectedGrade.codigo) === String(g.codigo);
                    const vDin = Number(g.valor_dinheiro ?? g.valorDinheiro ?? g.valordinheiro ?? g.valor ?? 0);
                    const vVis = Number(g.valor || 0);
                    const vPrz = Number(g.valor_prazo ?? g.valorPrazo ?? g.valorprazo ?? g.valor ?? 0);
                    const tamObj = tamanhosList.find(t => Number(t.codigo) === Number(g.tam));
                    const tamLabel = tamObj ? (tamObj.sigla || tamObj.tamanho) : (g.tamanho || g.tam || '-');

                    return (
                      <tr 
                        key={g.codigo} 
                        className={isSelected ? 'selected-row' : ''}
                        onClick={() => handleSelectGrade(g)}
                      >
                        <td>
                          <span className="grades-item-code">#{g.codigo}</span>
                        </td>
                        <td>
                          <span className="grades-size-badge">{tamLabel}</span>
                        </td>
                        <td style={{ textAlign: 'right', fontWeight: 600 }}>R$ {vDin.toFixed(2)}</td>
                        <td style={{ textAlign: 'right', fontWeight: 600 }}>R$ {vVis.toFixed(2)}</td>
                        <td style={{ textAlign: 'right', fontWeight: 600 }}>R$ {vPrz.toFixed(2)}</td>
                        <td style={{ textAlign: 'center' }}>
                          <span className="grades-qty-badge">{g.quantidade || 0}</span>
                        </td>
                        <td>
                          <span className="grades-ean-cell">{g.codbarra || '-'}</span>
                        </td>
                        <td style={{ color: '#64748b', fontSize: '0.82rem', fontWeight: 500 }}>
                          {g.cor || 'PADRAO'}
                        </td>
                      </tr>
                    );
                  })}
                  {grades.length === 0 && (
                    <tr>
                      <td colSpan="8" className="empty-table-cell">
                        {loading ? 'Carregando grades...' : 'Nenhuma grade cadastrada para este produto.'}
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            {/* Botões Laterais */}
            <div className="grades-side-buttons">
              <button 
                className="grades-cmd-btn btn-insert" 
                onClick={handleInsert}
                disabled={mode !== 'browse'}
                title="Inserir nova grade (F2)"
              >
                <Plus size={15} /> Inserir
              </button>
              <button 
                className="grades-cmd-btn btn-edit" 
                onClick={handleEdit}
                disabled={mode !== 'browse' || !selectedGrade}
                title="Editar grade selecionada"
              >
                <Edit2 size={15} /> Editar
              </button>
              <button 
                className="grades-cmd-btn btn-confirm" 
                onClick={handleConfirm}
                disabled={mode === 'browse'}
                title="Salvar alterações (Ctrl+S)"
              >
                <Check size={15} /> Gravar
              </button>
              <button 
                className="grades-cmd-btn btn-cancel" 
                onClick={() => setMode('browse')}
                disabled={mode === 'browse'}
                title="Cancelar edição"
              >
                <X size={15} /> Cancelar
              </button>
              <button 
                className="grades-cmd-btn btn-delete" 
                onClick={handleDelete}
                disabled={mode !== 'browse' || !selectedGrade}
                title="Excluir grade selecionada"
              >
                <Trash2 size={15} /> Excluir
              </button>
            </div>
          </div>
        </div>

        {/* Rodapé com Atalhos */}
        <div className="grades-modal-footer">
          <div className="grades-shortcuts">
            <span className="grades-shortcut-item"><kbd>ESC</kbd> Sair</span>
            <span className="grades-shortcut-item"><kbd>F2</kbd> Inserir</span>
            <span className="grades-shortcut-item"><kbd>F10</kbd> Gerar Cód. Barras</span>
            <span className="grades-shortcut-item"><kbd>Ctrl+S</kbd> Gravar</span>
          </div>

          <div style={{ display: 'flex', gap: '0.6rem' }}>
            <button 
              type="button"
              className="grades-btn-batch-barcode"
              onClick={handleGenerateAllBarcodes}
              disabled={loading || grades.length === 0}
              title="Gerar código de barras EAN-13 para todas as variações"
            >
              <Barcode size={15} /> Gerar EAN em Lote
            </button>
            <button className="grades-btn-secondary" onClick={onClose}>
              Fechar
            </button>
          </div>
        </div>
      </div>
    </div>,
    document.body
  );
}
