import { Search, X } from 'lucide-react';

export default function SearchBar({ value, onChange, onSearch, onClear, placeholder }) {
  return (
    <div className="search-bar-container" style={{ display: 'flex', alignItems: 'center', position: 'relative', marginBottom: '15px' }}>
      <input
        className="search-bar"
        type="text"
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(e.target.value.toUpperCase())}
        onKeyDown={(e) => {
          if (e.key === 'Enter') {
            onSearch();
          }
        }}
        aria-label={placeholder || "Campo de busca"}
        style={{ width: '100%', paddingRight: '70px', marginBottom: 0 }}
      />
      <div style={{ position: 'absolute', right: '10px', display: 'flex', gap: '5px' }}>
        {value && (
          <button
            onClick={onClear}
            aria-label="Limpar busca"
            style={{ background: 'transparent', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', padding: '4px', color: 'var(--text-secondary)' }}
          >
            <X size={18} aria-hidden="true" />
          </button>
        )}
        <button
          onClick={onSearch}
          aria-label="Buscar"
          style={{ background: 'transparent', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', padding: '4px', color: 'var(--text-secondary)' }}
        >
          <Search size={18} aria-hidden="true" />
        </button>
      </div>
    </div>
  );
}
