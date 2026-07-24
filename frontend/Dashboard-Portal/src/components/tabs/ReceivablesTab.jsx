import { DollarSign } from 'lucide-react';
import SearchBar from '../SearchBar';
import Pagination from '../Pagination';
import DateRangeFilter from '../DateRangeFilter';
import { formatCurrency, formatDate } from '../../utils/formatters';

export default function ReceivablesTab({ data, pages, searchTerms, setSearchTerms, getFilteredData, handleSearchClick, handleClearSearch, fetchPage, onDateChange, startDate, endDate }) {
  return (
    <div className="list-card glass full-width">
      <h3><DollarSign size={20} /> Tabela de Recebimentos</h3>
      <SearchBar
        value={searchTerms.recebimentos}
        onChange={(val) => setSearchTerms(prev => ({ ...prev, recebimentos: val }))}
        onSearch={() => handleSearchClick('recebimentos')}
        onClear={() => handleClearSearch('recebimentos')}
        placeholder="Buscar por duplicata, observação..."
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
              <th scope="col">Duplicata</th>
              <th scope="col">Tipo</th>
              <th scope="col">Data Pag.</th>
              <th scope="col">Valor</th>
            </tr>
          </thead>
          <tbody>
            {getFilteredData('recebimentos').map((item, idx) => (
              <tr key={item.codigo || idx}>
                <td data-label="Código">{item.codigo}</td>
                <td data-label="Duplicata">{item.duplicata}</td>
                <td data-label="Tipo">{item.tipo || '-'}</td>
                <td data-label="Data Pag.">{formatDate(item.datapgm)}</td>
                <td data-label="Valor" style={{ color: 'var(--success)', fontWeight: 600 }}>{formatCurrency(item.valor)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pagination
        currentPage={pages.recebimentos}
        totalPages={data.recebimentos.meta?.pages || 1}
        onPageChange={(page) => fetchPage('recebimentos', page)}
      />
    </div>
  );
}
