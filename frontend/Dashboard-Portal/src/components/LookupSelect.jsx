import React, { useState } from 'react';
import { Search, X } from 'lucide-react';
import LookupModal from './LookupModal';
import './LookupModal.css';

export default function LookupSelect({
  value, // ID selecionado
  displayValue, // Texto exibido (ex: "#1 - FORNECEDOR ABC")
  placeholder = 'Selecione...',
  title = 'Selecionar Registro',
  subtitle,
  icon: Icon,
  searchPlaceholder,
  fetchData,
  columns,
  onSelect,
  onClear,
  disabled = false,
  required = false
}) {
  const [isOpen, setIsOpen] = useState(false);

  const handleOpen = () => {
    if (!disabled) {
      setIsOpen(true);
    }
  };

  const handleSelect = (item) => {
    if (onSelect) {
      onSelect(item);
    }
    setIsOpen(false);
  };

  const handleClear = (e) => {
    e.stopPropagation();
    if (onClear) {
      onClear();
    }
  };

  const hasValue = value !== null && value !== undefined && value !== '' && value !== 0;

  return (
    <>
      <div className="lookup-trigger-box">
        <div 
          className={`lookup-display-input ${!hasValue ? 'empty' : ''}`}
          onClick={handleOpen}
          tabIndex={0}
          role="button"
          onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') handleOpen(); }}
        >
          <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {hasValue ? (displayValue || `#${value}`) : placeholder}
          </span>
          
          {hasValue && onClear && !disabled && (
            <button 
              type="button" 
              className="lookup-clear-btn" 
              onClick={handleClear} 
              title="Limpar seleção"
            >
              <X size={15} />
            </button>
          )}
        </div>

        <button 
          type="button" 
          className="lookup-btn-search" 
          onClick={handleOpen}
          disabled={disabled}
          title="Abrir busca detalhada paginada"
        >
          <Search size={16} /> Buscar
        </button>
      </div>

      <LookupModal
        isOpen={isOpen}
        onClose={() => setIsOpen(false)}
        title={title}
        subtitle={subtitle}
        icon={Icon}
        searchPlaceholder={searchPlaceholder}
        fetchData={fetchData}
        columns={columns}
        onSelect={handleSelect}
        selectedId={value}
      />
    </>
  );
}
