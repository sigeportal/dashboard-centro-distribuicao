import React, { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { Search, X, Check, RefreshCw, ChevronLeft, ChevronRight, AlertCircle } from 'lucide-react';
import './LookupModal.css';

export default function LookupModal({
  isOpen,
  onClose,
  title = 'Selecionar Registro',
  subtitle = 'Busque e selecione o item desejado',
  icon: Icon,
  searchPlaceholder = 'Digite para pesquisar...',
  fetchData, // async (termo, page, limit) => { data: [], meta: { page, limit, total, pages } }
  columns = [], // [ { key, label, align, width, render: (item) => ... } ]
  onSelect,
  selectedId = null,
  limit = 10
}) {
  const [searchTerm, setSearchTerm] = useState('');
  const [page, setPage] = useState(1);
  const [items, setItems] = useState([]);
  const [meta, setMeta] = useState({ page: 1, limit: limit, total: 0, pages: 1 });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const inputRef = useRef(null);

  useEffect(() => {
    if (isOpen) {
      setSearchTerm('');
      setPage(1);
      loadData('', 1);
      setTimeout(() => inputRef.current?.focus(), 100);
    }
  }, [isOpen]);

  useEffect(() => {
    if (!isOpen) return;
    const timeoutId = setTimeout(() => {
      setPage(1);
      loadData(searchTerm, 1);
    }, 300);

    return () => clearTimeout(timeoutId);
  }, [searchTerm]);

  const loadData = async (term, targetPage) => {
    if (!fetchData) return;
    setLoading(true);
    setError('');
    try {
      const res = await fetchData(term, targetPage, limit);
      if (res && Array.isArray(res.data)) {
        setItems(res.data);
        setMeta(res.meta || { page: targetPage, limit, total: res.data.length, pages: 1 });
      } else if (Array.isArray(res)) {
        setItems(res);
        setMeta({ page: 1, limit: res.length || limit, total: res.length, pages: 1 });
      } else {
        setItems([]);
        setMeta({ page: 1, limit, total: 0, pages: 1 });
      }
    } catch (err) {
      console.error('Erro ao buscar dados no LookupModal:', err);
      setError('Erro ao carregar dados. Tente novamente.');
      setItems([]);
    } finally {
      setLoading(false);
    }
  };

  const handlePageChange = (newPage) => {
    if (newPage < 1 || newPage > (meta.pages || 1)) return;
    setPage(newPage);
    loadData(searchTerm, newPage);
  };

  const handleRowClick = (item) => {
    if (onSelect) {
      onSelect(item);
    }
    if (onClose) {
      onClose();
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Escape') {
      onClose();
    }
  };

  if (!isOpen) return null;

  return createPortal(
    <div className="lookup-modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) onClose(); }} onKeyDown={handleKeyDown}>
      <div className="lookup-modal-container glass">
        
        {/* CABEÇALHO */}
        <div className="lookup-modal-header">
          <div className="lookup-title-wrap">
            {Icon && (
              <div className="lookup-icon-badge">
                <Icon size={20} />
              </div>
            )}
            <div>
              <h3>{title}</h3>
              <span>{subtitle}</span>
            </div>
          </div>
          <button className="btn-close" onClick={onClose}><X size={20} /></button>
        </div>

        {/* BARRA DE PESQUISA */}
        <div className="lookup-search-bar">
          <div className="lookup-input-wrapper">
            <Search size={18} className="search-icon" />
            <input
              ref={inputRef}
              type="text"
              className="lookup-search-input"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder={searchPlaceholder}
            />
            {searchTerm && (
              <button className="lookup-clear-btn" onClick={() => setSearchTerm('')} title="Limpar busca">
                <X size={16} />
              </button>
            )}
          </div>

          <button className="btn-secondary" onClick={() => loadData(searchTerm, page)} disabled={loading} style={{ height: '44px', padding: '0 1rem' }}>
            <RefreshCw size={16} className={loading ? 'spinner' : ''} />
          </button>
        </div>

        {/* CORPO / TABELA PAGINADA */}
        <div className="lookup-modal-body">
          {error && (
            <div style={{ padding: '1rem', background: '#fee2e2', color: '#b91c1c', display: 'flex', alignItems: 'center', gap: '0.5rem', margin: '1rem', borderRadius: '0.5rem' }}>
              <AlertCircle size={18} /> {error}
            </div>
          )}

          {loading && items.length === 0 ? (
            <div className="lookup-empty-state">
              <RefreshCw size={28} className="spinner" color="var(--accent)" />
              <p>Buscando registros...</p>
            </div>
          ) : items.length === 0 ? (
            <div className="lookup-empty-state">
              <p style={{ fontWeight: 600, color: 'var(--text-primary)' }}>Nenhum registro encontrado</p>
              <small>Tente pesquisar por outro termo ou limpe a busca.</small>
            </div>
          ) : (
            <table className="lookup-table">
              <thead>
                <tr>
                  {columns.map((col, idx) => (
                    <th key={idx} style={{ textAlign: col.align || 'left', width: col.width || 'auto' }}>
                      {col.label}
                    </th>
                  ))}
                  <th style={{ textAlign: 'center', width: '100px' }}>Ação</th>
                </tr>
              </thead>
              <tbody>
                {items.map((item, idx) => {
                  const itemId = item.id || item.codigo || item.PRO_CODIGO || item.FOR_CODIGO || idx;
                  const isSelected = selectedId && String(selectedId) === String(itemId);

                  return (
                    <tr 
                      key={itemId} 
                      className={isSelected ? 'selected' : ''} 
                      onDoubleClick={() => handleRowClick(item)}
                    >
                      {columns.map((col, cIdx) => (
                        <td key={cIdx} style={{ textAlign: col.align || 'left' }}>
                          {col.render ? col.render(item) : (item[col.key] ?? '-')}
                        </td>
                      ))}
                      <td style={{ textAlign: 'center' }}>
                        <button 
                          type="button" 
                          className="lookup-select-cell-btn"
                          onClick={() => handleRowClick(item)}
                        >
                          <Check size={13} style={{ display: 'inline', marginRight: '3px' }} /> Selecionar
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>

        {/* RODAPÉ COM PAGINAÇÃO */}
        <div className="lookup-modal-footer">
          <div style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
            Total: <strong>{meta.total || items.length}</strong> registro(s) encontrado(s) • Página <strong>{meta.page || page}</strong> de <strong>{meta.pages || 1}</strong>
          </div>

          <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
            <button 
              type="button" 
              className="btn-secondary" 
              onClick={() => handlePageChange(page - 1)} 
              disabled={page <= 1 || loading}
              style={{ height: '34px', padding: '0 0.75rem', fontSize: '0.8rem' }}
            >
              <ChevronLeft size={16} /> Anterior
            </button>
            <button 
              type="button" 
              className="btn-secondary" 
              onClick={() => handlePageChange(page + 1)} 
              disabled={page >= (meta.pages || 1) || loading}
              style={{ height: '34px', padding: '0 0.75rem', fontSize: '0.8rem' }}
            >
              Próxima <ChevronRight size={16} />
            </button>
          </div>
        </div>

      </div>
    </div>,
    document.body
  );
}
