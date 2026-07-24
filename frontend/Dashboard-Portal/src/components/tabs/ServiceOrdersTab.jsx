import { Wrench, Eye } from 'lucide-react';
import SearchBar from '../SearchBar';
import Pagination from '../Pagination';
import DateRangeFilter from '../DateRangeFilter';
import { formatCurrency, formatExcelDate, formatExcelTime } from '../../utils/formatters';

export default function ServiceOrdersTab({
  data,
  pages,
  searchTerms,
  setSearchTerms,
  getFilteredData,
  handleSearchClick,
  handleClearSearch,
  fetchPage,
  onDateChange,
  startDate,
  endDate
}) {
  const serviceOrders = getFilteredData('os');

  return (
    <div className="list-card glass full-width">
      <h3>
        <Wrench size={20} /> Tabela de OS
      </h3>
      <SearchBar
        value={searchTerms.os || ''}
        onChange={(val) => setSearchTerms(prev => ({ ...prev, os: val }))}
        onSearch={() => handleSearchClick('os')}
        onClear={() => handleClearSearch('os')}
        placeholder="Buscar por código, vendedor..."
      />
      <DateRangeFilter
        onFilterChange={onDateChange}
        initialStartDate={startDate}
        initialEndDate={endDate}
      />

      <div className="table-responsive">
        <table className="data-table">
          <thead>
            <tr>
              <th scope="col">Código</th>
              <th scope="col">Data/Hora</th>
              <th scope="col">Valor Total</th>
              <th scope="col">Vendedor</th>
              <th scope="col">PDV</th>
              <th scope="col">Cliente</th>
              <th scope="col">Ações</th>
            </tr>
          </thead>
          <tbody>
            {serviceOrders.length === 0 ? (
              <tr>
                <td colSpan="7" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-secondary)' }}>
                  Nenhuma OS encontrada.
                </td>
              </tr>
            ) : (
              serviceOrders.map((item, idx) => {
                const dateStr = formatExcelDate(item.data);
                const timeStr = formatExcelTime(item.hora);

                return (
                  <tr key={item.codigo || idx}>
                    <td data-label="Código">{item.codigo}</td>
                    <td data-label="Data/Hora">
                      {dateStr} {timeStr}
                    </td>
                    <td data-label="Valor Total" style={{ fontWeight: 600 }}>
                      {formatCurrency(item.valor)}
                    </td>
                    <td data-label="Vendedor">
                      {typeof item.fun === 'object' && item.fun !== null
                        ? (item.fun.nome || '-')
                        : `Vendedor ${item.vendedor}`}
                    </td>
                    <td data-label="PDV">PDV {item.pdv}</td>
                    <td data-label="Cliente">
                      {typeof item.cli === 'object' && item.cli !== null
                        ? (item.cli.nome || '-')
                        : `Cliente ${item.cli}`}
                    </td>
                    <td data-label="Ações">
                      <button
                        type="button"
                        disabled
                        style={{
                          background: 'rgba(249, 115, 22, 0.1)',
                          border: 'none',
                          color: 'var(--accent)',
                          padding: '6px 12px',
                          borderRadius: '6px',
                          cursor: 'not-allowed',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '6px',
                          fontSize: '0.85rem',
                          fontWeight: 500,
                          opacity: 0.55,
                        }}
                        className="view-details-btn"
                        aria-label="Detalhes de OS indisponíveis"
                        title="Detalhes de OS indisponíveis"
                      >
                        <Eye size={16} aria-hidden="true" />
                      </button>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      <Pagination
        currentPage={pages.os || 1}
        totalPages={data.os?.meta?.pages || 1}
        onPageChange={(page) => fetchPage('os', page)}
      />
    </div>
  );
}
