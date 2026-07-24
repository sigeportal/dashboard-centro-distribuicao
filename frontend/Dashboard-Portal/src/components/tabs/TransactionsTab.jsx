import { ArrowRightLeft } from 'lucide-react';
import SearchBar from '../SearchBar';
import Pagination from '../Pagination';
import DateRangeFilter from '../DateRangeFilter';
import { formatCurrency, formatDatehora } from '../../utils/formatters';

export default function TransactionsTab({
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
  endDate,
  accounts = {},
  selectedAccount = '0',
  onAccountChange
}) {
  return (
    <div className="list-card glass full-width">
      <h3><ArrowRightLeft size={20} /> Tabela de Movimentações</h3>
      <SearchBar
        value={searchTerms.movimentacoes}
        onChange={(val) => setSearchTerms(prev => ({ ...prev, movimentacoes: val }))}
        onSearch={() => handleSearchClick('movimentacoes')}
        onClear={() => handleClearSearch('movimentacoes')}
        placeholder="Buscar por descrição, nome..."
      />
      <DateRangeFilter
        onFilterChange={onDateChange}
        initialStartDate={startDate}
        initialEndDate={endDate}
      >
        <label className="drf-select-container">
          Conta
          <select
            className="drf-input"
            value={selectedAccount}
            onChange={(e) => onAccountChange(e.target.value)}
          >
            {Object.entries(accounts).map(([key, val]) => (
              <option key={key} value={key}>
                {key} | {val}
              </option>
            ))}
          </select>
        </label>
      </DateRangeFilter>
      <div className="table-responsive">
        <table className="data-table">
          <thead>
            <tr>
              <th scope="col">Data/Hora</th>
              <th scope="col">Descrição</th>
              <th scope="col">Nome</th>
              <th scope="col">Crédito</th>
              <th scope="col">Débito</th>
              <th scope="col">Saldo Ant.</th>
            </tr>
          </thead>
          <tbody>
            {getFilteredData('movimentacoes').map((item, idx) => (
              <tr key={item.codigo || idx}>
                <td data-label="Data/Hora">{formatDatehora(item.datahora)}</td>
                <td data-label="Descrição">{item.descricao}</td>
                <td data-label="Nome">{item.nome}</td>
                <td data-label="Crédito" style={{ color: 'var(--success)' }}>{item.credito ? formatCurrency(item.credito) : '-'}</td>
                <td data-label="Débito" style={{ color: 'var(--danger)' }}>{item.debito ? formatCurrency(item.debito) : '-'}</td>
                <td data-label="Saldo Ant.">{formatCurrency(item.saldoant)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pagination
        currentPage={pages.movimentacoes}
        totalPages={data.movimentacoes.meta?.pages || 1}
        onPageChange={(page) => fetchPage('movimentacoes', page)}
      />
    </div>
  );
}
