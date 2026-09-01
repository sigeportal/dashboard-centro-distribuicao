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
      <div className="crud-title-row" style={{ marginBottom: '0.5rem', borderBottom: 'none' }}>
        <h3 style={{ margin: 0, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <Wrench size={20} style={{ color: 'var(--accent)' }} /> 
          Tabela de Ordens de Serviço (OS)
        </h3>
      </div>

      <SearchBar
        value={searchTerms.os || ''}
        onChange={(val) => setSearchTerms(prev => ({ ...prev, os: val }))}
        onSearch={() => handleSearchClick('os')}
        onClear={() => handleClearSearch('os')}
        placeholder="Buscar por código, vendedor, cliente..."
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
              <th scope="col" className="text-center">Ações</th>
            </tr>
          </thead>
          <tbody>
            {serviceOrders.length === 0 ? (
              <tr>
                <td colSpan="7" style={{ textAlign: 'center', padding: '2.5rem', color: 'var(--text-secondary)' }}>
                  Nenhuma Ordem de Serviço encontrada.
                </td>
              </tr>
            ) : (
              serviceOrders.map((item, idx) => {
                const dateStr = formatExcelDate(item.data);
                const timeStr = formatExcelTime(item.hora);

                return (
                  <tr key={item.codigo || idx}>
                    <td data-label="Código">
                      <span className="item-code">#{item.codigo}</span>
                    </td>
                    <td data-label="Data/Hora">
                      {dateStr} {timeStr}
                    </td>
                    <td data-label="Valor Total" style={{ fontWeight: 600 }}>
                      {formatCurrency(item.valor)}
                    </td>
                    <td data-label="Vendedor">
                      {typeof item.fun === 'object' && item.fun !== null
                        ? (item.fun.nome || '-')
                        : `Vendedor ${item.vendedor || '-'}`}
                    </td>
                    <td data-label="PDV">
                      <span className="badge badge-info">PDV {item.pdv}</span>
                    </td>
                    <td data-label="Cliente">
                      {typeof item.cli === 'object' && item.cli !== null
                        ? (item.cli.nome || '-')
                        : (item.cli ? `Cliente ${item.cli}` : '-')}
                    </td>
                    <td data-label="Ações" className="text-center" onClick={(e) => e.stopPropagation()}>
                      <button
                        type="button"
                        disabled
                        className="action-btn"
                        style={{
                          opacity: 0.5,
                          cursor: 'not-allowed'
                        }}
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
