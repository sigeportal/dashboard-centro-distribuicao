import { DollarSign, CheckCircle2, CreditCard } from 'lucide-react';
import SearchBar from '../SearchBar';
import Pagination from '../Pagination';
import DateRangeFilter from '../DateRangeFilter';
import { formatCurrency, formatDate } from '../../utils/formatters';

export default function ReceivablesTab({ 
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
  const receivables = getFilteredData('recebimentos') || [];

  const totalRecebido = receivables.reduce((acc, item) => acc + (Number(item.valor) || 0), 0);
  const totalTitulos = receivables.length;

  return (
    <div className="crud-container">
      {/* Cards de Métricas de Recebimento */}
      <div className="dashboard-grid" style={{ marginBottom: '0.25rem' }}>
        <div className="metric-card glass credits-metric-card">
          <div className="metric-header">
            <span>Total Recebido no Período</span>
            <DollarSign className="metric-icon" size={20} />
          </div>
          <div className="metric-value">
            {formatCurrency(totalRecebido)}
          </div>
        </div>

        <div className="metric-card glass">
          <div className="metric-header">
            <span>Títulos Baixados / Recebidos</span>
            <CheckCircle2 className="metric-icon" size={20} style={{ color: 'var(--accent)' }} />
          </div>
          <div className="metric-value">
            {totalTitulos}
          </div>
        </div>
      </div>

      {/* Card da Tabela de Recebimentos */}
      <div className="list-card glass full-width">
        <div className="crud-title-row" style={{ marginBottom: '0.5rem', borderBottom: 'none' }}>
          <h3 style={{ margin: 0, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <DollarSign size={20} style={{ color: 'var(--accent)' }} /> 
            Tabela de Títulos Recebidos
          </h3>
        </div>

        <SearchBar
          value={searchTerms.recebimentos || ''}
          onChange={(val) => setSearchTerms(prev => ({ ...prev, recebimentos: val }))}
          onSearch={() => handleSearchClick('recebimentos')}
          onClear={() => handleClearSearch('recebimentos')}
          placeholder="Buscar por código, duplicata, tipo ou observação..."
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
                <th scope="col">Cód. Lançamento</th>
                <th scope="col">Nº Duplicata</th>
                <th scope="col">Forma / Tipo</th>
                <th scope="col">Data do Pagamento</th>
                <th scope="col" style={{ textAlign: 'right' }}>Valor Recebido</th>
              </tr>
            </thead>
            <tbody>
              {receivables.length === 0 ? (
                <tr>
                  <td colSpan="5" style={{ textAlign: 'center', padding: '2.5rem', color: 'var(--text-secondary)' }}>
                    Nenhum título recebido encontrado para o período selecionado.
                  </td>
                </tr>
              ) : (
                receivables.map((item, idx) => (
                  <tr key={item.codigo || idx}>
                    <td data-label="Cód. Lançamento">
                      <span className="item-code">#{item.codigo}</span>
                    </td>
                    <td data-label="Nº Duplicata">
                      <span className="item-code" style={{ color: 'var(--text-primary)', fontWeight: 600 }}>
                        {item.duplicata || '-'}
                      </span>
                    </td>
                    <td data-label="Forma / Tipo">
                      <span className="badge badge-info" style={{ textTransform: 'uppercase' }}>
                        {item.tipo || 'Diversos'}
                      </span>
                    </td>
                    <td data-label="Data do Pagamento">
                      {formatDate(item.datapgm)}
                    </td>
                    <td 
                      data-label="Valor Recebido" 
                      style={{ 
                        textAlign: 'right', 
                        color: 'var(--success, #006c49)', 
                        fontWeight: 700 
                      }}
                    >
                      {formatCurrency(item.valor)}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <Pagination
          currentPage={pages.recebimentos || 1}
          totalPages={data.recebimentos?.meta?.pages || 1}
          onPageChange={(page) => fetchPage('recebimentos', page)}
        />
      </div>
    </div>
  );
}
