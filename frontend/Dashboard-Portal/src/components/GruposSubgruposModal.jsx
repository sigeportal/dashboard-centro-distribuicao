import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Folder, Plus, Trash2, Check, X, Edit2, Search, Printer, Layers } from 'lucide-react';
import { createApi } from '../services/api';
import './GruposSubgruposModal.css';

export default function GruposSubgruposModal({ isOpen, onClose, onSelectGrupoSubgrupo }) {
  if (!isOpen) return null;

  const api = createApi(true);

  // Estados dos Grupos (Painel Esquerdo)
  const [grupos, setGrupos] = useState([]);
  const [selectedGrupo, setSelectedGrupo] = useState(null);
  const [grupoMode, setGrupoMode] = useState('browse'); // 'browse', 'insert', 'edit'
  const [grupoForm, setGrupoForm] = useState({ codigo: '', nome: '' });

  // Estados dos SubGrupos (Painel Direito)
  const [subgrupos, setSubgrupos] = useState([]);
  const [selectedSubgrupo, setSelectedSubgrupo] = useState(null);
  const [subgrupoMode, setSubgrupoMode] = useState('browse'); // 'browse', 'insert', 'edit'
  const [subgrupoForm, setSubgrupoForm] = useState({ codigo: '', nome: '' });

  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchGrupos();
  }, []);

  // Atalhos de Teclado (ESC fecha o modal)
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onClose]);

  const fetchGrupos = async () => {
    setLoading(true);
    try {
      const res = await api.get('/v1/grupos?limit=500');
      const items = Array.isArray(res.data) ? res.data : (res.data?.data || []);
      setGrupos(items);
      if (items.length > 0 && !selectedGrupo) {
        handleSelectGrupo(items[0]);
      }
    } catch (err) {
      console.error('Erro ao buscar grupos:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchSubgrupos = async (grupoCodigo) => {
    try {
      const res = await api.get(`/v1/subgrupos?limit=500`);
      const items = Array.isArray(res.data) ? res.data : (res.data?.data || []);
      // Filtra por g1 (código do grupo pai)
      const filtered = items.filter(sg => String(sg.g1 || sg.gru_g1 || sg.grupo_id) === String(grupoCodigo));
      setSubgrupos(filtered);
      if (filtered.length > 0) {
        setSelectedSubgrupo(filtered[0]);
        setSubgrupoForm({ codigo: filtered[0].codigo, nome: filtered[0].nome });
      } else {
        setSelectedSubgrupo(null);
        setSubgrupoForm({ codigo: '', nome: '' });
      }
    } catch (err) {
      console.error('Erro ao buscar subgrupos:', err);
    }
  };

  const handleSelectGrupo = (grupo) => {
    setSelectedGrupo(grupo);
    setGrupoForm({ codigo: grupo.codigo, nome: grupo.nome });
    setGrupoMode('browse');
    fetchSubgrupos(grupo.codigo);
  };

  const handleSelectSubgrupo = (subgrupo) => {
    setSelectedSubgrupo(subgrupo);
    setSubgrupoForm({ codigo: subgrupo.codigo, nome: subgrupo.nome });
    setSubgrupoMode('browse');
  };

  // CRUD GRUPOS
  const handleGrupoInsert = () => {
    setGrupoMode('insert');
    const nextCode = grupos.length > 0 ? Math.max(...grupos.map(g => Number(g.codigo) || 0)) + 1 : 1;
    setGrupoForm({ codigo: nextCode, nome: '' });
  };

  const handleGrupoEdit = () => {
    if (!selectedGrupo) return;
    setGrupoMode('edit');
    setGrupoForm({ codigo: selectedGrupo.codigo, nome: selectedGrupo.nome });
  };

  const handleGrupoConfirm = async () => {
    if (!grupoForm.nome.trim()) {
      alert('Informe o nome do grupo.');
      return;
    }
    setLoading(true);
    try {
      const payload = {
        codigo: Number(grupoForm.codigo),
        nome: grupoForm.nome.toUpperCase()
      };
      if (grupoMode === 'insert') {
        await api.post('/v1/grupos', payload);
      } else {
        await api.put('/v1/grupos', payload);
      }
      setGrupoMode('browse');
      await fetchGrupos();
    } catch (err) {
      alert('Erro ao salvar grupo.');
    } finally {
      setLoading(false);
    }
  };

  const handleGrupoDelete = async () => {
    if (!selectedGrupo) return;
    if (!window.confirm(`Tem certeza que deseja excluir o grupo [${selectedGrupo.nome}]?`)) return;
    setLoading(true);
    try {
      await api.delete(`/v1/grupos/${selectedGrupo.codigo}`);
      setSelectedGrupo(null);
      setGrupoForm({ codigo: '', nome: '' });
      await fetchGrupos();
    } catch (err) {
      alert('Erro ao excluir grupo.');
    } finally {
      setLoading(false);
    }
  };

  // CRUD SUBGRUPOS
  const handleSubgrupoInsert = () => {
    if (!selectedGrupo) {
      alert('Selecione um Grupo primeiro.');
      return;
    }
    setSubgrupoMode('insert');
    const nextCode = subgrupos.length > 0 ? Math.max(...subgrupos.map(sg => Number(sg.codigo) || 0)) + 1 : 1;
    setSubgrupoForm({ codigo: nextCode, nome: '' });
  };

  const handleSubgrupoEdit = () => {
    if (!selectedSubgrupo) return;
    setSubgrupoMode('edit');
    setSubgrupoForm({ codigo: selectedSubgrupo.codigo, nome: selectedSubgrupo.nome });
  };

  const handleSubgrupoConfirm = async () => {
    if (!selectedGrupo) return;
    if (!subgrupoForm.nome.trim()) {
      alert('Informe o nome do subgrupo.');
      return;
    }
    setLoading(true);
    try {
      const payload = {
        codigo: Number(subgrupoForm.codigo),
        nome: subgrupoForm.nome.toUpperCase(),
        g1: selectedGrupo.codigo,
        tr: '0'
      };
      if (subgrupoMode === 'insert') {
        await api.post('/v1/subgrupos', payload);
      } else {
        await api.put('/v1/subgrupos', payload);
      }
      setSubgrupoMode('browse');
      await fetchSubgrupos(selectedGrupo.codigo);
    } catch (err) {
      alert('Erro ao salvar subgrupo.');
    } finally {
      setLoading(false);
    }
  };

  const handleSubgrupoDelete = async () => {
    if (!selectedSubgrupo) return;
    if (!window.confirm(`Tem certeza que deseja excluir o subgrupo [${selectedSubgrupo.nome}]?`)) return;
    setLoading(true);
    try {
      await api.delete(`/v1/subgrupos/${selectedSubgrupo.codigo}`);
      setSelectedSubgrupo(null);
      setSubgrupoForm({ codigo: '', nome: '' });
      await fetchSubgrupos(selectedGrupo.codigo);
    } catch (err) {
      alert('Erro ao excluir subgrupo.');
    } finally {
      setLoading(false);
    }
  };

  const handleConfirmSelection = () => {
    if (onSelectGrupoSubgrupo && selectedGrupo && selectedSubgrupo) {
      onSelectGrupoSubgrupo({
        grupo: selectedGrupo,
        subgrupo: selectedSubgrupo,
        formatted: `${selectedGrupo.nome} > ${selectedSubgrupo.nome}`
      });
      onClose();
    }
  };

  const filteredGrupos = grupos.filter(g => 
    g.nome.toLowerCase().includes(searchTerm.toLowerCase()) || 
    String(g.codigo).includes(searchTerm)
  );

  return createPortal(
    <div className="legacy-modal-overlay">
      <div className="legacy-modal-window gru-modal-window">
        {/* Header do Pop-up */}
        <div className="legacy-modal-header">
          <div className="legacy-modal-title">
            <Folder size={18} />
            <span>Cadastro de Grupos e SubGrupos de Produtos</span>
          </div>
          <button className="legacy-modal-close-btn" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        {/* Corpo Dual Side-by-Side */}
        <div className="legacy-modal-body gru-modal-body">
          {/* Painel de Grupos (Esquerda) */}
          <div className="gru-panel">
            <div className="gru-panel-header">
              <Layers size={16} /> Grupos
            </div>

            <div className="gru-inputs-row">
              <div className="gru-input-group" style={{ width: '80px' }}>
                <label>Código</label>
                <input 
                  type="text" 
                  value={grupoForm.codigo} 
                  readOnly 
                  className="legacy-input read-only" 
                />
              </div>
              <div className="gru-input-group flex-1">
                <label>*Nome</label>
                <input 
                  type="text" 
                  value={grupoForm.nome} 
                  onChange={(e) => setGrupoForm({ ...grupoForm, nome: e.target.value })}
                  disabled={grupoMode === 'browse'}
                  className="legacy-input"
                  placeholder="Nome do grupo"
                  required
                />
              </div>
            </div>

            <div className="gru-table-and-actions">
              <div className="gru-table-container">
                <table className="legacy-data-table">
                  <thead>
                    <tr>
                      <th style={{ width: '70px' }}>Código</th>
                      <th>Nome</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredGrupos.map((g) => {
                      const isSelected = selectedGrupo && selectedGrupo.codigo === g.codigo;
                      return (
                        <tr 
                          key={g.codigo} 
                          className={isSelected ? 'selected-row' : ''}
                          onClick={() => handleSelectGrupo(g)}
                        >
                          <td style={{ textAlign: 'center' }}><strong>{g.codigo}</strong></td>
                          <td>{g.nome}</td>
                        </tr>
                      );
                    })}
                    {filteredGrupos.length === 0 && (
                      <tr>
                        <td colSpan="2" className="empty-table-cell">Nenhum grupo cadastrado.</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>

              {/* Botões de Ação Laterais (Grupos) */}
              <div className="gru-side-buttons">
                <button 
                  className="legacy-cmd-btn btn-insert" 
                  onClick={handleGrupoInsert}
                  disabled={grupoMode !== 'browse'}
                >
                  <Plus size={16} /> Inserir
                </button>
                <button 
                  className="legacy-cmd-btn btn-delete" 
                  onClick={handleGrupoDelete}
                  disabled={grupoMode !== 'browse' || !selectedGrupo}
                >
                  <Trash2 size={16} /> Excluir
                </button>
                <button 
                  className="legacy-cmd-btn btn-confirm" 
                  onClick={handleGrupoConfirm}
                  disabled={grupoMode === 'browse'}
                >
                  <Check size={16} /> Confirmar
                </button>
                <button 
                  className="legacy-cmd-btn btn-cancel" 
                  onClick={() => setGrupoMode('browse')}
                  disabled={grupoMode === 'browse'}
                >
                  <X size={16} /> Cancelar
                </button>
                <button 
                  className="legacy-cmd-btn btn-edit" 
                  onClick={handleGrupoEdit}
                  disabled={grupoMode !== 'browse' || !selectedGrupo}
                >
                  <Edit2 size={16} /> Editar
                </button>
              </div>
            </div>
          </div>

          {/* Painel de SubGrupos (Direita) */}
          <div className="gru-panel">
            <div className="gru-panel-header">
              <Folder size={16} /> SubGrupos {selectedGrupo ? `[Grupo: ${selectedGrupo.nome}]` : ''}
            </div>

            <div className="gru-inputs-row">
              <div className="gru-input-group" style={{ width: '80px' }}>
                <label>Código</label>
                <input 
                  type="text" 
                  value={subgrupoForm.codigo} 
                  readOnly 
                  className="legacy-input read-only" 
                />
              </div>
              <div className="gru-input-group flex-1">
                <label>*Nome</label>
                <input 
                  type="text" 
                  value={subgrupoForm.nome} 
                  onChange={(e) => setSubgrupoForm({ ...subgrupoForm, nome: e.target.value })}
                  disabled={subgrupoMode === 'browse'}
                  className="legacy-input"
                  placeholder="Nome do subgrupo"
                  required
                />
              </div>
            </div>

            <div className="gru-table-and-actions">
              <div className="gru-table-container">
                <table className="legacy-data-table">
                  <thead>
                    <tr>
                      <th style={{ width: '70px' }}>Código</th>
                      <th>Nome</th>
                    </tr>
                  </thead>
                  <tbody>
                    {subgrupos.map((sg) => {
                      const isSelected = selectedSubgrupo && selectedSubgrupo.codigo === sg.codigo;
                      return (
                        <tr 
                          key={sg.codigo} 
                          className={isSelected ? 'selected-row' : ''}
                          onClick={() => handleSelectSubgrupo(sg)}
                        >
                          <td style={{ textAlign: 'center' }}><strong>{sg.codigo}</strong></td>
                          <td>{sg.nome}</td>
                        </tr>
                      );
                    })}
                    {subgrupos.length === 0 && (
                      <tr>
                        <td colSpan="2" className="empty-table-cell">Nenhum subgrupo para este grupo.</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>

              {/* Botões de Ação Laterais (SubGrupos) */}
              <div className="gru-side-buttons">
                <button 
                  className="legacy-cmd-btn btn-insert" 
                  onClick={handleSubgrupoInsert}
                  disabled={subgrupoMode !== 'browse' || !selectedGrupo}
                >
                  <Plus size={16} /> Inserir
                </button>
                <button 
                  className="legacy-cmd-btn btn-delete" 
                  onClick={handleSubgrupoDelete}
                  disabled={subgrupoMode !== 'browse' || !selectedSubgrupo}
                >
                  <Trash2 size={16} /> Excluir
                </button>
                <button 
                  className="legacy-cmd-btn btn-confirm" 
                  onClick={handleSubgrupoConfirm}
                  disabled={subgrupoMode === 'browse'}
                >
                  <Check size={16} /> Confirmar
                </button>
                <button 
                  className="legacy-cmd-btn btn-cancel" 
                  onClick={() => setSubgrupoMode('browse')}
                  disabled={subgrupoMode === 'browse'}
                >
                  <X size={16} /> Cancelar
                </button>
                <button 
                  className="legacy-cmd-btn btn-edit" 
                  onClick={handleSubgrupoEdit}
                  disabled={subgrupoMode !== 'browse' || !selectedSubgrupo}
                >
                  <Edit2 size={16} /> Editar
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Rodapé do Modal com Atalhos */}
        <div className="legacy-modal-footer">
          <div className="legacy-shortcuts">
            <span className="shortcut-tag"><kbd>ESC</kbd> Sair</span>
            <span className="shortcut-tag"><kbd>F1</kbd> Imprimir</span>
            <span className="shortcut-tag"><kbd>F9</kbd> Pesquisar</span>
            <span className="shortcut-required">*Campos obrigatórios</span>
          </div>

          {onSelectGrupoSubgrupo && selectedGrupo && selectedSubgrupo && (
            <button className="legacy-select-btn" onClick={handleConfirmSelection}>
              <Check size={16} /> Selecionar [{selectedGrupo.nome} &gt; {selectedSubgrupo.nome}]
            </button>
          )}
        </div>
      </div>
    </div>,
    document.body
  );
}
