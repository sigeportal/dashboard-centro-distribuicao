import React, { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { Search, X, Check, RefreshCw, ChevronLeft, ChevronRight, AlertCircle } from 'lucide-react';
import useFocusTrap from '../hooks/useFocusTrap';
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
  const modalRef = useFocusTrap(isOpen);
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

  const ModalIcon = Icon || Search;

  return createPortal(
    <div
      className="lookup-modal-overlay"
      onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}
      onKeyDown={handleKeyDown}
    >
      <div
        ref={modalRef}
        className="lookup-modal-container glass"
        role="dialog"
        aria-modal="true"
        aria-labelledby="lookup-modal-title"
      >
        {/* Cabeçalho */}
        <div className="lookup-modal-header">
          <div className="lookup-title-wrap">
            <div className="lookup-icon-badge">
              <ModalIcon size={20} />
            </div>
            <div>
              <h3 id="lookup-modal-title">{title}</h3>
              <span className="lookup-modal-subtitle">{subtitle}</span>
            </div>
          </div>
          <button className="lookup-modal-close" onClick={onClose} aria-label="Fechar busca">
            <X size={20} />
          </button>
        </div>

        {/* Barra de Pesquisa */}
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
              <button
                type="button"
                className="lookup-clear-btn"
                onClick={() => setSearchTerm('')}
                title="Limpar busca"
              >
                <X size={16} />
              </button>
            )}
          </div>

          <button
            type="button"
            className="btn-secondary"
            onClick={() => loadData(searchTerm, page)}
            disabled={loading}
            title="Atualizar resultados"
            style={{ height: '42px', padding: '0 1rem' }}
          >
            <RefreshCw size={16} className={loading ? 'spinner' : ''} />
          </button>
        </div>

        {/* Corpo / Tabela Paginada */}
        <div className="lookup-modal-body">
          {error && (
            <div className="lookup-error-banner">
              <AlertCircle size={18} />
              <span>{error}</span>
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
                  <th style={{ textAlign: 'center', width: '110px' }}>Ação</th>
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
                          <Check size={13} style={{ display: 'inline', marginRight: '3px' }} />
                          <span>Selecionar</span>
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>

        {/* Rodapé com Paginação e Atalhos */}
        <div className="lookup-modal-footer">
          <div className="lookup-footer-info">
            <div className="shortcut-hint">
              <kbd>ESC</kbd> <span>Fechar</span>
            </div>
            <div className="shortcut-hint">
              <kbd>Duplo Clique</kbd> <span>Selecionar</span>
            </div>
            <span className="lookup-total-counter">
              Total: <strong>{meta.total || items.length}</strong> • Página <strong>{meta.page || page}</strong> de <strong>{meta.pages || 1}</strong>
            </span>
          </div>

          <div className="lookup-pagination-controls">
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

