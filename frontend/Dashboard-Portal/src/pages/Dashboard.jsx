import { useOutletContext, useSearchParams } from 'react-router-dom';
import useDashboardData from '../hooks/useDashboardData';
import OverviewTab from '../components/tabs/OverviewTab';
import { useAuth } from '../contexts/AuthContext';
import './Dashboard.css';
import CustomersTab from '../components/tabs/CustomersTab';
import ProductsTab from '../components/tabs/ProductsTab';
import TransactionsTab from '../components/tabs/TransactionsTab';
import ReceivablesTab from '../components/tabs/ReceivablesTab';
import SalesTab from '../components/tabs/SalesTab';
import ServiceOrdersTab from '../components/tabs/ServiceOrdersTab';
import TransferTab from '../components/tabs/TransferTab';
import CadastrosTab from '../components/tabs/CadastrosTab';
import PurchasesTab from '../components/tabs/PurchasesTab';
import PurchaseOrdersTab from '../components/tabs/PurchaseOrdersTab';
import NfeTab from '../components/tabs/NfeTab';
import ConciliacaoFiscalModal from '../components/ConciliacaoFiscalModal';

export default function Dashboard() {
  const [searchParams] = useSearchParams();
  const { showServiceOrders = false } = useOutletContext() || {};
  const activeTab = searchParams.get('tab') || 'geral';
  const { userRole } = useAuth();
  const isFinancialAllowed = userRole === 'admin' || userRole === 'gerente';

  const {
    data, pages, chartData, chartLoading, loading, error,
    searchTerms, setSearchTerms, prodFilter, setProdFilter,
    getFilteredData, fetchPage,
    handleSearchClick, handleClearSearch,
    handleDateFilterChange, handleMovimentacoesDateChange, handleRecebimentosDateChange, handleVendasDateChange, handleOsDateChange,
    overviewDates, movimentacoesDates, recebimentosDates, vendasDates, osDates,
    accounts, selectedAccount, onAccountChange,
  } = useDashboardData(showServiceOrders, isFinancialAllowed);

  if (loading) {
    return <div className="loading-state">Carregando métricas...</div>;
  }

  if (error) {
    return <div className="error-state">{error}</div>;
  }

  if (!isFinancialAllowed && (activeTab === 'movimentacoes' || activeTab === 'recebimentos')) {
    return (
      <div className="error-state" style={{ color: 'var(--danger)', padding: '2rem', textAlign: 'center' }}>
        Acesso Restrito: Sua conta não tem permissão para acessar esta área.
      </div>
    );
  }

  const numeroVendas = Array.isArray(chartData.vendasDiarias)
    ? chartData.vendasDiarias.reduce((acc, curr) => acc + (Number(curr.quantidade) || 0), 0)
    : 0;
  const valorTotalVendido = Array.isArray(chartData.vendasDiarias)
    ? chartData.vendasDiarias.reduce((acc, curr) => acc + (Number(curr.valor) || 0), 0)
    : 0;
  const ticketMedio = numeroVendas > 0 ? valorTotalVendido / numeroVendas : 0;
  const lucroTotal = Array.isArray(chartData.vendasMargemLucro)
    ? chartData.vendasMargemLucro.reduce((acc, curr) => acc + (Number(curr.margem_lucro) || 0), 0)
    : 0;

  return (
    <div className="dashboard-container">
      {activeTab === 'geral' && (
        <OverviewTab
          numeroVendas={numeroVendas}
          valorTotalVendido={valorTotalVendido}
          ticketMedio={ticketMedio}
          lucroTotal={lucroTotal}
          chartData={chartData}
          chartLoading={chartLoading}
          showServiceOrders={showServiceOrders}
          onDateFilterChange={handleDateFilterChange}
          startDate={overviewDates.startDate}
          endDate={overviewDates.endDate}
        />
      )}

      {activeTab === 'clientes' && (
        <CustomersTab
          data={data} pages={pages} searchTerms={searchTerms} setSearchTerms={setSearchTerms}
          getFilteredData={getFilteredData} handleSearchClick={handleSearchClick}
          handleClearSearch={handleClearSearch} fetchPage={fetchPage}
          clientesChartData={chartData.clientes}
          chartLoading={chartLoading.clientes}
        />
      )}

      {activeTab === 'produtos' && (
        <ProductsTab
          data={data} pages={pages} searchTerms={searchTerms} setSearchTerms={setSearchTerms}
          prodFilter={prodFilter} setProdFilter={setProdFilter}
          getFilteredData={getFilteredData} handleSearchClick={handleSearchClick}
          handleClearSearch={handleClearSearch} fetchPage={fetchPage}
        />
      )}

      {activeTab === 'vendas' && (
        <SalesTab
          data={data} pages={pages} searchTerms={searchTerms} setSearchTerms={setSearchTerms}
          getFilteredData={getFilteredData} handleSearchClick={handleSearchClick}
          handleClearSearch={handleClearSearch} fetchPage={fetchPage}
          onDateChange={handleVendasDateChange}
          startDate={vendasDates.startDate}
          endDate={vendasDates.endDate}
        />
      )}

      {activeTab === 'os' && (
        <ServiceOrdersTab
          data={data} pages={pages} searchTerms={searchTerms} setSearchTerms={setSearchTerms}
          getFilteredData={getFilteredData} handleSearchClick={handleSearchClick}
          handleClearSearch={handleClearSearch} fetchPage={fetchPage}
          onDateChange={handleOsDateChange}
          startDate={osDates.startDate}
          endDate={osDates.endDate}
        />
      )}

      {activeTab === 'movimentacoes' && (
        <TransactionsTab
          data={data} pages={pages} searchTerms={searchTerms} setSearchTerms={setSearchTerms}
          getFilteredData={getFilteredData} handleSearchClick={handleSearchClick}
          handleClearSearch={handleClearSearch} fetchPage={fetchPage}
          onDateChange={handleMovimentacoesDateChange}
          startDate={movimentacoesDates.startDate}
          endDate={movimentacoesDates.endDate}
          accounts={accounts}
          selectedAccount={selectedAccount}
          onAccountChange={onAccountChange}
        />
      )}

      {activeTab === 'recebimentos' && (
        <ReceivablesTab
          data={data} pages={pages} searchTerms={searchTerms} setSearchTerms={setSearchTerms}
          getFilteredData={getFilteredData} handleSearchClick={handleSearchClick}
          handleClearSearch={handleClearSearch} fetchPage={fetchPage}
          onDateChange={handleRecebimentosDateChange}
          startDate={recebimentosDates.startDate}
          endDate={recebimentosDates.endDate}
        />
      )}

      {activeTab === 'compras' && <PurchasesTab />}
      {activeTab === 'pedidos-compra' && <PurchaseOrdersTab />}
      {activeTab === 'transferencias' && <TransferTab />}
      {activeTab === 'nfe' && <NfeTab />}
      {activeTab === 'conciliacao' && <ConciliacaoFiscalModal onClose={() => navigate('/dashboard?tab=produtos')} />}
      {activeTab === 'cadastros' && <CadastrosTab />}
    </div>
  );
}
