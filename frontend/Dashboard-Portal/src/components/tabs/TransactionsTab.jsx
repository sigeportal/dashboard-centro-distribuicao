import { ArrowRightLeft, TrendingUp, TrendingDown, Wallet } from 'lucide-react';
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
  const transactions = getFilteredData('movimentacoes') || [];

  const totalCreditos = transactions.reduce((acc, t) => acc + (Number(t.credito) || 0), 0);
  const totalDebitos = transactions.reduce((acc, t) => acc + (Number(t.debito) || 0), 0);
  const saldoLiquido = totalCreditos - totalDebitos;

  return (
    <div className="crud-container">
      {/* Resumo Financeiro da Movimentação */}
      <div className="dashboard-grid" style={{ marginBottom: '0.25rem' }}>
        <div className="metric-card glass credits-metric-card">
          <div className="metric-header">
            <span>Total Créditos (Período)</span>
            <TrendingUp className="metric-icon" size={20} />
          </div>
          <div className="metric-value">
            {formatCurrency(totalCreditos)}
          </div>
        </div>

        <div className="metric-card glass debits-metric-card">
          <div className="metric-header">
            <span>Total Débitos (Período)</span>
            <TrendingDown className="metric-icon" size={20} />
          </div>
          <div className="metric-value">
            {formatCurrency(totalDebitos)}
          </div>
        </div>

        <div className="metric-card glass">
          <div className="metric-header">
            <span>Saldo Líquido</span>
            <Wallet className="metric-icon" size={20} />
          </div>
          <div 
            className="metric-value"
            style={{ color: saldoLiquido >= 0 ? 'var(--success, #006c49)' : 'var(--danger, #ba1a1a)' }}
          >
            {formatCurrency(saldoLiquido)}
          </div>
        </div>
      </div>

      {/* Card da Tabela de Movimentações */}
      <div className="list-card glass full-width">
        <div className="crud-title-row" style={{ marginBottom: '0.5rem', borderBottom: 'none' }}>
          <h3 style={{ margin: 0, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <ArrowRightLeft size={20} style={{ color: 'var(--accent)' }} /> 
            Tabela de Movimentações Financeiras
          </h3>
        </div>

        <SearchBar
          value={searchTerms.movimentacoes || ''}
          onChange={(val) => setSearchTerms(prev => ({ ...prev, movimentacoes: val }))}
          onSearch={() => handleSearchClick('movimentacoes')}
          onClear={() => handleClearSearch('movimentacoes')}
          placeholder="Buscar por descrição, nome, código..."
        />

        <DateRangeFilter
          onFilterChange={onDateChange}
          initialStartDate={startDate}
          initialEndDate={endDate}
        >
          <label className="drf-select-container">
            Conta Bancária / Caixa
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
                <th scope="col">Titular / Favorecido</th>
                <th scope="col" style={{ textAlign: 'right' }}>Crédito (+)</th>
                <th scope="col" style={{ textAlign: 'right' }}>Débito (-)</th>
                <th scope="col" style={{ textAlign: 'right' }}>Saldo Ant.</th>
              </tr>
            </thead>
            <tbody>
              {transactions.length === 0 ? (
                <tr>
                  <td colSpan="6" style={{ textAlign: 'center', padding: '2.5rem', color: 'var(--text-secondary)' }}>
                    Nenhuma movimentação financeira encontrada para o período selecionado.
                  </td>
                </tr>
              ) : (
                transactions.map((item, idx) => (
                  <tr key={item.codigo || idx}>
                    <td data-label="Data/Hora">
                      <span className="item-code" style={{ fontSize: '0.82rem' }}>
                        {formatDatehora(item.datahora)}
                      </span>
                    </td>
                    <td data-label="Descrição" style={{ fontWeight: 500 }}>
                      {item.descricao || '-'}
                    </td>
                    <td data-label="Titular / Favorecido">
                      {item.nome || '-'}
                    </td>
                    <td 
                      data-label="Crédito (+)" 
                      style={{ 
                        textAlign: 'right', 
                        color: 'var(--success, #006c49)', 
                        fontWeight: 600 
                      }}
                    >
                      {item.credito ? formatCurrency(item.credito) : '-'}
                    </td>
                    <td 
                      data-label="Débito (-)" 
                      style={{ 
                        textAlign: 'right', 
                        color: 'var(--danger, #ba1a1a)', 
                        fontWeight: 600 
                      }}
                    >
                      {item.debito ? formatCurrency(item.debito) : '-'}
                    </td>
                    <td data-label="Saldo Ant." style={{ textAlign: 'right', fontWeight: 500 }}>
                      {formatCurrency(item.saldoant)}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <Pagination
          currentPage={pages.movimentacoes || 1}
          totalPages={data.movimentacoes?.meta?.pages || 1}
          onPageChange={(page) => fetchPage('movimentacoes', page)}
        />
      </div>
    </div>
  );
}
