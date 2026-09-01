import React, { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { Folder, Plus, Trash2, Check, X, Edit2, Search, Layers } from 'lucide-react';
import { createApi } from '../services/api';
import { toast } from '../contexts/ToastContext';
import './GruposSubgruposModal.css';

export default function GruposSubgruposModal({ isOpen, onClose, onSelectGrupoSubgrupo }) {
  if (!isOpen) return null;

  const api = createApi(true);
  const searchInputRef = useRef(null);

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

  // Atalhos de Teclado (ESC fecha o modal, F2 insere grupo, F9 foca pesquisa)
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape') {
        onClose();
      } else if (e.key === 'F2' || e.key === 'Insert') {
        e.preventDefault();
        if (grupoMode === 'browse') handleGrupoInsert();
      } else if (e.key === 'F9') {
        e.preventDefault();
        if (searchInputRef.current) {
          searchInputRef.current.focus();
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onClose, grupoMode, subgrupoMode]);

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
      const res = await api.get('/v1/subgrupos?limit=500');
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
      toast.warning('Informe o nome do grupo.');
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
      toast.error('Erro ao salvar grupo.');
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
      toast.error('Erro ao excluir grupo.');
    } finally {
      setLoading(false);
    }
  };

  // CRUD SUBGRUPOS
  const handleSubgrupoInsert = () => {
    if (!selectedGrupo) {
      toast.warning('Selecione um Grupo primeiro.');
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
      toast.warning('Informe o nome do subgrupo.');
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
      toast.error('Erro ao salvar subgrupo.');
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
      toast.error('Erro ao excluir subgrupo.');
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
    (g.nome && g.nome.toLowerCase().includes(searchTerm.toLowerCase())) || 
    String(g.codigo).includes(searchTerm)
  );

  return createPortal(
    <div className="gru-modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}>
      <div className="gru-modal-container glass">
        {/* Cabeçalho Padronizado */}
        <div className="gru-modal-header">
          <div className="gru-title-wrap">
            <div className="gru-icon-badge">
              <Folder size={20} />
            </div>
            <div>
              <h3>Cadastro de Grupos & SubGrupos</h3>
              <span>Categorização e hierarquia de produtos e relatórios</span>
            </div>
          </div>
          <button className="gru-btn-close" onClick={onClose} title="Fechar (ESC)">
            <X size={20} />
          </button>
        </div>

        {/* Corpo Dual Side-by-Side */}
        <div className="gru-modal-body">
          {/* Painel de Grupos (Esquerda) */}
          <div className="gru-panel">
            <div className="gru-panel-header">
              <div className="gru-panel-title">
                <Layers size={16} />
                <span>Grupos Principais</span>
              </div>
              <span className="gru-count-badge">{filteredGrupos.length} cadastrados</span>
            </div>

            <div className="gru-inputs-row">
              <div className="gru-input-group" style={{ width: '80px' }}>
                <label>Código</label>
                <input 
                  type="text" 
                  value={grupoForm.codigo} 
                  readOnly 
                  className="gru-input gru-input-readonly" 
                />
              </div>
              <div className="gru-input-group flex-1">
                <label>*Nome do Grupo</label>
                <input 
                  type="text" 
                  value={grupoForm.nome} 
                  onChange={(e) => setGrupoForm({ ...grupoForm, nome: e.target.value })}
                  disabled={grupoMode === 'browse'}
                  className="gru-input"
                  placeholder="Nome do grupo principal"
                  required
                />
              </div>
            </div>

            {/* Busca Rápida de Grupos */}
            <div className="gru-search-wrap">
              <Search size={15} className="gru-search-icon" />
              <input
                ref={searchInputRef}
                type="text"
                className="gru-search-input"
                placeholder="Filtrar grupos (F9)..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
              {searchTerm && (
                <button className="gru-search-clear" onClick={() => setSearchTerm('')} title="Limpar">
                  <X size={14} />
                </button>
              )}
            </div>

            <div className="gru-table-and-actions">
              <div className="gru-table-container">
                <table className="gru-data-table">
                  <thead>
                    <tr>
                      <th style={{ width: '80px' }}>CÓDIGO</th>
                      <th>DESCRIÇÃO DO GRUPO</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredGrupos.map((g) => {
                      const isSelected = selectedGrupo && String(selectedGrupo.codigo) === String(g.codigo);
                      return (
                        <tr 
                          key={g.codigo} 
                          className={isSelected ? 'selected-row' : ''}
                          onClick={() => handleSelectGrupo(g)}
                        >
                          <td>
                            <span className="gru-item-code">#{g.codigo}</span>
                          </td>
                          <td className="gru-name-cell">{g.nome}</td>
                        </tr>
                      );
                    })}
                    {filteredGrupos.length === 0 && (
                      <tr>
                        <td colSpan="2" className="empty-table-cell">
                          {loading ? 'Carregando grupos...' : 'Nenhum grupo encontrado.'}
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>

              {/* Botões de Ação Laterais (Grupos) */}
              <div className="gru-side-buttons">
                <button 
                  className="gru-cmd-btn btn-insert" 
                  onClick={handleGrupoInsert}
                  disabled={grupoMode !== 'browse'}
                  title="Inserir novo grupo (F2)"
                >
                  <Plus size={15} /> Inserir
                </button>
                <button 
                  className="gru-cmd-btn btn-edit" 
                  onClick={handleGrupoEdit}
                  disabled={grupoMode !== 'browse' || !selectedGrupo}
                  title="Editar grupo selecionado"
                >
                  <Edit2 size={15} /> Editar
                </button>
                <button 
                  className="gru-cmd-btn btn-confirm" 
                  onClick={handleGrupoConfirm}
                  disabled={grupoMode === 'browse'}
                  title="Salvar alterações"
                >
                  <Check size={15} /> Gravar
                </button>
                <button 
                  className="gru-cmd-btn btn-cancel" 
                  onClick={() => setGrupoMode('browse')}
                  disabled={grupoMode === 'browse'}
                  title="Cancelar edição"
                >
                  <X size={15} /> Cancelar
                </button>
                <button 
                  className="gru-cmd-btn btn-delete" 
                  onClick={handleGrupoDelete}
                  disabled={grupoMode !== 'browse' || !selectedGrupo}
                  title="Excluir grupo selecionado"
                >
                  <Trash2 size={15} /> Excluir
                </button>
              </div>
            </div>
          </div>

          {/* Painel de SubGrupos (Direita) */}
          <div className="gru-panel">
            <div className="gru-panel-header">
              <div className="gru-panel-title">
                <Folder size={16} />
                <span>
                  SubGrupos {selectedGrupo ? <span className="gru-parent-tag">↳ {selectedGrupo.nome}</span> : ''}
                </span>
              </div>
              <span className="gru-count-badge">{subgrupos.length} vinculados</span>
            </div>

            <div className="gru-inputs-row">
              <div className="gru-input-group" style={{ width: '80px' }}>
                <label>Código</label>
                <input 
                  type="text" 
                  value={subgrupoForm.codigo} 
                  readOnly 
                  className="gru-input gru-input-readonly" 
                />
              </div>
              <div className="gru-input-group flex-1">
                <label>*Nome do SubGrupo</label>
                <input 
                  type="text" 
                  value={subgrupoForm.nome} 
                  onChange={(e) => setSubgrupoForm({ ...subgrupoForm, nome: e.target.value })}
                  disabled={subgrupoMode === 'browse'}
                  className="gru-input"
                  placeholder={selectedGrupo ? `Subgrupo de ${selectedGrupo.nome}` : 'Selecione um grupo primeiro'}
                  required
                />
              </div>
            </div>

            <div className="gru-info-callout">
              <span>Pertence ao Grupo Mestre: <strong>{selectedGrupo ? `[#${selectedGrupo.codigo}] ${selectedGrupo.nome}` : 'Nenhum grupo selecionado'}</strong></span>
            </div>

            <div className="gru-table-and-actions">
              <div className="gru-table-container">
                <table className="gru-data-table">
                  <thead>
                    <tr>
                      <th style={{ width: '80px' }}>CÓDIGO</th>
                      <th>DESCRIÇÃO DO SUBGRUPO</th>
                    </tr>
                  </thead>
                  <tbody>
                    {subgrupos.map((sg) => {
                      const isSelected = selectedSubgrupo && String(selectedSubgrupo.codigo) === String(sg.codigo);
                      return (
                        <tr 
                          key={sg.codigo} 
                          className={isSelected ? 'selected-row' : ''}
                          onClick={() => handleSelectSubgrupo(sg)}
                        >
                          <td>
                            <span className="gru-item-code">#{sg.codigo}</span>
                          </td>
                          <td className="gru-name-cell">{sg.nome}</td>
                        </tr>
                      );
                    })}
                    {subgrupos.length === 0 && (
                      <tr>
                        <td colSpan="2" className="empty-table-cell">
                          {selectedGrupo ? 'Nenhum subgrupo para este grupo.' : 'Selecione um grupo ao lado.'}
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>

              {/* Botões de Ação Laterais (SubGrupos) */}
              <div className="gru-side-buttons">
                <button 
                  className="gru-cmd-btn btn-insert" 
                  onClick={handleSubgrupoInsert}
                  disabled={subgrupoMode !== 'browse' || !selectedGrupo}
                  title="Inserir novo subgrupo"
                >
                  <Plus size={15} /> Inserir
                </button>
                <button 
                  className="gru-cmd-btn btn-edit" 
                  onClick={handleSubgrupoEdit}
                  disabled={subgrupoMode !== 'browse' || !selectedSubgrupo}
                  title="Editar subgrupo selecionado"
                >
                  <Edit2 size={15} /> Editar
                </button>
                <button 
                  className="gru-cmd-btn btn-confirm" 
                  onClick={handleSubgrupoConfirm}
                  disabled={subgrupoMode === 'browse'}
                  title="Salvar alterações"
                >
                  <Check size={15} /> Gravar
                </button>
                <button 
                  className="gru-cmd-btn btn-cancel" 
                  onClick={() => setSubgrupoMode('browse')}
                  disabled={subgrupoMode === 'browse'}
                  title="Cancelar edição"
                >
                  <X size={15} /> Cancelar
                </button>
                <button 
                  className="gru-cmd-btn btn-delete" 
                  onClick={handleSubgrupoDelete}
                  disabled={subgrupoMode !== 'browse' || !selectedSubgrupo}
                  title="Excluir subgrupo selecionado"
                >
                  <Trash2 size={15} /> Excluir
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Rodapé do Modal com Atalhos Raycast/Linear */}
        <div className="gru-modal-footer">
          <div className="gru-shortcuts">
            <span className="gru-shortcut-item"><kbd>ESC</kbd> Sair</span>
            <span className="gru-shortcut-item"><kbd>F2</kbd> Inserir Grupo</span>
            <span className="gru-shortcut-item"><kbd>F9</kbd> Pesquisar</span>
            <span className="gru-shortcut-required">*Campos obrigatórios</span>
          </div>

          {onSelectGrupoSubgrupo && selectedGrupo && selectedSubgrupo && (
            <button className="gru-select-btn" onClick={handleConfirmSelection}>
              <Check size={16} /> Selecionar [{selectedGrupo.nome} &gt; {selectedSubgrupo.nome}]
            </button>
          )}
        </div>
      </div>
    </div>,
    document.body
  );
}
