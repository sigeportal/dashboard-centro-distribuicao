import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Grid, Plus, Trash2, Check, X, Edit2, Barcode, Search } from 'lucide-react';
import { createApi } from '../services/api';
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
      alert('Nenhuma grade cadastrada para este produto.');
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
      alert('Cod. de Barras das Grades gerado com sucesso!');
      await fetchGradesForProduct();
      if (onGradesUpdated) onGradesUpdated();
    } catch (err) {
      console.error(err);
      alert('Erro ao gerar Cod. Barras das Grades.');
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
      alert('Erro ao salvar grade. Verifique se os campos estão corretos.');
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
      alert('Erro ao excluir grade.');
    } finally {
      setLoading(false);
    }
  };

  return createPortal(
    <div className="legacy-modal-overlay">
      <div className="legacy-modal-window gra-modal-window">
        {/* Header do Pop-up */}
        <div className="legacy-modal-header">
          <div className="legacy-modal-title">
            <Grid size={18} />
            <span>Cadastro de Grades - {product ? `[${product.codigo}] ${product.nome}` : ''}</span>
          </div>
          <button className="legacy-modal-close-btn" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        {/* Inputs de Entrada (Dados Gerais no Topo) */}
        <div className="gra-modal-body">
          <div className="gra-inputs-grid">
            <div className="gra-input-field">
              <label>Código</label>
              <input 
                type="text" 
                value={form.codigo} 
                readOnly 
                className="legacy-input read-only" 
              />
            </div>

            <div className="gra-input-field">
              <label>*Tamanho</label>
              <select 
                value={form.tam} 
                onChange={(e) => setForm({ ...form, tam: e.target.value })}
                disabled={mode === 'browse'}
                className="legacy-input"
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

            <div className="gra-input-field">
              <label>Cor</label>
              <select 
                value={form.cor} 
                onChange={(e) => setForm({ ...form, cor: e.target.value })}
                disabled={mode === 'browse'}
                className="legacy-input"
              >
                {coresDisponiveis.map(c => <option key={c} value={c}>{c}</option>)}
              </select>
            </div>

            <div className="gra-input-field">
              <label>Quantidade</label>
              <input 
                type="number" 
                value={form.quantidade} 
                onChange={(e) => setForm({ ...form, quantidade: e.target.value })}
                disabled={mode === 'browse'}
                className="legacy-input"
              />
            </div>

            <div className="gra-input-field">
              <label>Vlr Dinheiro</label>
              <input 
                type="number" 
                step="0.01"
                value={form.valor_dinheiro} 
                onChange={(e) => setForm({ ...form, valor_dinheiro: e.target.value })}
                disabled={mode === 'browse'}
                className="legacy-input"
              />
            </div>

            <div className="gra-input-field">
              <label>Vlr Vista</label>
              <input 
                type="number" 
                step="0.01"
                value={form.valor} 
                onChange={(e) => setForm({ ...form, valor: e.target.value })}
                disabled={mode === 'browse'}
                className="legacy-input"
              />
            </div>

            <div className="gra-input-field">
              <label>Vlr Prazo</label>
              <input 
                type="number" 
                step="0.01"
                value={form.valor_prazo} 
                onChange={(e) => setForm({ ...form, valor_prazo: e.target.value })}
                disabled={mode === 'browse'}
                className="legacy-input"
              />
            </div>

            <div className="gra-input-field gra-barcode-field" style={{ minWidth: '180px' }}>
              <label>Cód. Barras</label>
              <div style={{ display: 'flex', gap: '4px', alignItems: 'center' }}>
                <input 
                  type="text" 
                  value={form.codbarra} 
                  onChange={(e) => setForm({ ...form, codbarra: e.target.value })}
                  disabled={mode === 'browse'}
                  className="legacy-input"
                  placeholder="EAN-13 (F10)"
                  style={{ flex: 1, minWidth: '120px' }}
                />
                <button 
                  type="button"
                  className="btn-barcode-gen"
                  onClick={handleGenerateBarcode}
                  disabled={loading}
                  title="Gerar Cód. Barras EAN-13 (F10)"
                  style={{ height: '36px', padding: '0 8px', flexShrink: 0 }}
                >
                  <Barcode size={18} />
                </button>
              </div>
            </div>
          </div>

          {/* Tabela Central e Botões Laterais */}
          <div className="gra-table-and-actions">
            <div className="gra-table-container">
              <table className="legacy-data-table">
                <thead>
                  <tr>
                    <th>CODIGO</th>
                    <th>TAMANHO</th>
                    <th style={{ textAlign: 'right' }}>VLR DINHEIRO</th>
                    <th style={{ textAlign: 'right' }}>VLR VISTA</th>
                    <th style={{ textAlign: 'right' }}>VLR PRAZO</th>
                    <th style={{ textAlign: 'center' }}>QUANT</th>
                    <th>COD. BARRAS</th>
                    <th>COR</th>
                  </tr>
                </thead>
                <tbody>
                  {grades.map((g) => {
                    const isSelected = selectedGrade && selectedGrade.codigo === g.codigo;
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
                        <td><strong>#{g.codigo}</strong></td>
                        <td><span className="grade-badge">{tamLabel}</span></td>
                        <td style={{ textAlign: 'right' }}>R$ {vDin.toFixed(2)}</td>
                        <td style={{ textAlign: 'right' }}>R$ {vVis.toFixed(2)}</td>
                        <td style={{ textAlign: 'right' }}>R$ {vPrz.toFixed(2)}</td>
                        <td style={{ textAlign: 'center', fontWeight: 'bold' }}>{g.quantidade || 0}</td>
                        <td>{g.codbarra || '-'}</td>
                        <td>{g.cor || 'PADRAO'}</td>
                      </tr>
                    );
                  })}
                  {grades.length === 0 && (
                    <tr>
                      <td colSpan="8" className="empty-table-cell">Nenhuma grade cadastrada para este produto.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            {/* Botões Laterais */}
            <div className="gru-side-buttons">
              <button 
                className="legacy-cmd-btn btn-insert" 
                onClick={handleInsert}
                disabled={mode !== 'browse'}
              >
                <Plus size={16} /> Inserir
              </button>
              <button 
                className="legacy-cmd-btn btn-delete" 
                onClick={handleDelete}
                disabled={mode !== 'browse' || !selectedGrade}
              >
                <Trash2 size={16} /> Excluir
              </button>
              <button 
                className="legacy-cmd-btn btn-confirm" 
                onClick={handleConfirm}
                disabled={mode === 'browse'}
              >
                <Check size={16} /> Confirmar
              </button>
              <button 
                className="legacy-cmd-btn btn-cancel" 
                onClick={() => setMode('browse')}
                disabled={mode === 'browse'}
              >
                <X size={16} /> Cancelar
              </button>
              <button 
                className="legacy-cmd-btn btn-edit" 
                onClick={handleEdit}
                disabled={mode !== 'browse' || !selectedGrade}
              >
                <Edit2 size={16} /> Editar
              </button>
            </div>
          </div>
        </div>

        {/* Rodapé com Atalhos */}
        <div className="legacy-modal-footer">
          <div className="legacy-shortcuts">
            <span className="shortcut-tag" onClick={onClose} style={{ cursor: 'pointer' }}><kbd>ESC</kbd> Sair</span>
            <span className="shortcut-tag" onClick={handleInsert} style={{ cursor: 'pointer' }}><kbd>F2</kbd> Inserir</span>
            <span className="shortcut-tag" onClick={handleGenerateAllBarcodes} style={{ cursor: 'pointer' }}><kbd>F10</kbd> Gerar Cód. Barras</span>
          </div>
        </div>
      </div>
    </div>,
    document.body
  );
}
