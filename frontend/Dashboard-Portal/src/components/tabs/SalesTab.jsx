import { useState } from 'react';
import { ShoppingCart, Eye } from 'lucide-react';
import SearchBar from '../SearchBar';
import Pagination from '../Pagination';
import DateRangeFilter from '../DateRangeFilter';
import SalesDetailsModal from '../SalesDetailsModal';
import { formatCurrency, formatExcelDate, formatExcelTime } from '../../utils/formatters';

export default function SalesTab({
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
  const [selectedSale, setSelectedSale] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const handleRowClick = (sale) => {
    setSelectedSale(sale);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedSale(null);
  };

  const sales = getFilteredData('vendas');


  return (
    <div className="list-card glass full-width">
      <h3>
        <ShoppingCart size={20} /> Tabela de Vendas
      </h3>
      <SearchBar
        value={searchTerms.vendas || ''}
        onChange={(val) => setSearchTerms(prev => ({ ...prev, vendas: val }))}
        onSearch={() => handleSearchClick('vendas')}
        onClear={() => handleClearSearch('vendas')}
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
            {sales.length === 0 ? (
              <tr>
                <td colSpan="7" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-secondary)' }}>
                  Nenhuma venda encontrada.
                </td>
              </tr>
            ) : (
              sales.map((item, idx) => {
                const dateStr = formatExcelDate(item.data);
                const timeStr = formatExcelTime(item.hora);
                const isPendingReturn = item.devolucao_p === 'S';

                return (
                  <tr
                    key={item.codigo || idx}
                    onClick={() => handleRowClick(item)}
                    style={{ cursor: 'pointer' }}
                    className={isPendingReturn ? 'row-warning' : ''}
                  >
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
                    <td data-label="Ações" onClick={(e) => e.stopPropagation()}>
                      <button
                        onClick={() => handleRowClick(item)}
                        style={{
                          background: 'rgba(249, 115, 22, 0.1)',
                          border: 'none',
                          color: 'var(--accent)',
                          padding: '6px 12px',
                          borderRadius: '6px',
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '6px',
                          fontSize: '0.85rem',
                          fontWeight: 500,
                          transition: 'all 0.2s ease',
                        }}
                        className="view-details-btn"
                        aria-label="Ver detalhes da venda"
                        title="Ver detalhes da venda"
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
        currentPage={pages.vendas || 1}
        totalPages={data.vendas?.meta?.pages || 1}
        onPageChange={(page) => fetchPage('vendas', page)}
      />

      {selectedSale && (
        <SalesDetailsModal
          isOpen={isModalOpen}
          onClose={handleCloseModal}
          sale={selectedSale}
        />
      )}
    </div>
  );
}
