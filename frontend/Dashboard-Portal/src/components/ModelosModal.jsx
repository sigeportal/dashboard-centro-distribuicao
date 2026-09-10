import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Tag, Plus, Trash2, Edit, Check, X } from 'lucide-react';
import { createApi } from '../services/api';
import { toast } from '../contexts/ToastContext';
import './ModelosModal.css';

export default function ModelosModal({ isOpen, onClose }) {
  if (!isOpen) return null;

  const api = createApi(true);
  const [modelos, setModelos] = useState([]);
  const [loading, setLoading] = useState(false);
  const [novoNome, setNovoNome] = useState('');
  const [editingItem, setEditingItem] = useState(null);
  const [editNome, setEditNome] = useState('');

  const fetchModelos = async () => {
    setLoading(true);
    try {
      const res = await api.get('/v1/modelos');
      const items = Array.isArray(res.data) ? res.data : (res.data?.data || []);
      setModelos(items);
    } catch (err) {
      console.error('Erro ao buscar modelos:', err);
      toast.error('Erro ao carregar marcas/modelos.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchModelos();
  }, []);

  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onClose]);

  const handleAdd = async (e) => {
    e.preventDefault();
    if (!novoNome.trim()) return;

    setLoading(true);
    try {
      await api.post('/v1/modelos', {
        codigo: 0,
        nome: novoNome.trim().toUpperCase()
      });
      toast.success('Modelo/Marca adicionado com sucesso!');
      setNovoNome('');
      await fetchModelos();
    } catch (err) {
      console.error(err);
      toast.error('Erro ao salvar modelo: ' + (err.response?.data?.error || err.message));
    } finally {
      setLoading(false);
    }
  };

  const handleStartEdit = (item) => {
    setEditingItem(item);
    setEditNome(item.nome);
  };

  const handleSaveEdit = async (id) => {
    if (!editNome.trim()) return;
    setLoading(true);
    try {
      await api.put('/v1/modelos', {
        codigo: Number(id),
        nome: editNome.trim().toUpperCase()
      });
      toast.success('Modelo atualizado com sucesso!');
      setEditingItem(null);
      await fetchModelos();
    } catch (err) {
      console.error(err);
      toast.error('Erro ao atualizar modelo: ' + (err.response?.data?.error || err.message));
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Tem certeza que deseja remover este modelo/marca?')) return;
    setLoading(true);
    try {
      await api.delete(`/v1/modelos/${id}`);
      toast.success('Modelo removido com sucesso!');
      await fetchModelos();
    } catch (err) {
      console.error(err);
      toast.error('Erro ao excluir modelo.');
    } finally {
      setLoading(false);
    }
  };

  return createPortal(
    <div className="modelos-modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}>
      <div className="modelos-modal-container">
        
        <div className="modelos-modal-header">
          <div className="modelos-modal-header-left">
            <div className="modelos-icon-badge">
              <Tag size={20} />
            </div>
            <div>
              <h3 className="modelos-modal-title">Gestão de Modelos / Marcas</h3>
              <p className="modelos-modal-subtitle">Cadastre os modelos ou linhas dos produtos</p>
            </div>
          </div>
          <button className="modelos-btn-close" onClick={onClose} title="Fechar (ESC)">
            <X size={18} />
          </button>
        </div>

        <div className="modelos-modal-body">
          {/* Formulário de Adição Rápida */}
          <form onSubmit={handleAdd} className="modelos-input-row">
            <input 
              type="text" 
              className="modelos-input"
              placeholder="Digite o nome do novo modelo/marca..."
              value={novoNome}
              onChange={(e) => setNovoNome(e.target.value.toUpperCase())}
              style={{ textTransform: 'uppercase' }}
            />
            <button type="submit" className="modelos-btn-add" disabled={loading || !novoNome.trim()}>
              <Plus size={16} /> Adicionar
            </button>
          </form>

          {/* Lista de Modelos */}
          <div className="modelos-list">
            {modelos.map(item => (
              <div key={item.codigo} className="modelos-item">
                <div className="modelos-item-left">
                  <span className="modelos-code">#{item.codigo}</span>
                  {editingItem?.codigo === item.codigo ? (
                    <input 
                      type="text" 
                      className="modelos-input"
                      value={editNome}
                      onChange={(e) => setEditNome(e.target.value.toUpperCase())}
                      style={{ height: '32px', padding: '0 0.5rem', textTransform: 'uppercase' }}
                      autoFocus
                    />
                  ) : (
                    <span className="modelos-name">{item.nome}</span>
                  )}
                </div>

                <div className="modelos-actions">
                  {editingItem?.codigo === item.codigo ? (
                    <>
                      <button 
                        className="modelos-action-btn edit" 
                        onClick={() => handleSaveEdit(item.codigo)}
                        title="Salvar alteração"
                      >
                        <Check size={14} />
                      </button>
                      <button 
                        className="modelos-action-btn" 
                        onClick={() => setEditingItem(null)}
                        title="Cancelar"
                      >
                        <X size={14} />
                      </button>
                    </>
                  ) : (
                    <>
                      <button 
                        className="modelos-action-btn edit" 
                        onClick={() => handleStartEdit(item)}
                        title="Editar"
                      >
                        <Edit size={14} />
                      </button>
                      <button 
                        className="modelos-action-btn delete" 
                        onClick={() => handleDelete(item.codigo)}
                        title="Excluir"
                      >
                        <Trash2 size={14} />
                      </button>
                    </>
                  )}
                </div>
              </div>
            ))}

            {modelos.length === 0 && (
              <div style={{ padding: '2rem', textAlign: 'center', color: '#64748b', fontSize: '0.9rem' }}>
                {loading ? 'Carregando modelos...' : 'Nenhum modelo cadastrado.'}
              </div>
            )}
          </div>
        </div>

      </div>
    </div>,
    document.body
  );
}
