const btnStyle = {
  padding: '6px 12px',
  backgroundColor: 'rgba(0, 0, 0, 0.05)',
  border: '1px solid rgba(0, 0, 0, 0.1)',
  borderRadius: '4px',
  color: 'var(--text-primary)',
  cursor: 'pointer',
  fontSize: '0.85rem'
};

const disabledBtnStyle = {
  ...btnStyle,
  opacity: 0.5,
  cursor: 'not-allowed'
};

export default function Pagination({ currentPage, totalPages, onPageChange }) {
  return (
    <nav aria-label="Paginação">
      <div className="pagination-controls" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '15px' }}>
        <button
          style={currentPage <= 1 ? disabledBtnStyle : btnStyle}
          disabled={currentPage <= 1}
          onClick={() => onPageChange(currentPage - 1)}
          aria-label="Ir para a página anterior"
        >
          Anterior
        </button>
        <span style={{ fontSize: '0.85rem', opacity: 0.8 }}>
          Página {currentPage} de {totalPages}
        </span>
        <button
          style={currentPage >= totalPages ? disabledBtnStyle : btnStyle}
          disabled={currentPage >= totalPages}
          onClick={() => onPageChange(currentPage + 1)}
          aria-label="Ir para a próxima página"
        >
          Próximo
        </button>
      </div>
    </nav>
  );
}
