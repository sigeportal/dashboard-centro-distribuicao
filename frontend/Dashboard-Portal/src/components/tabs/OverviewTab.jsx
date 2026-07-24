import { BarChart3, CircleDollarSign, ReceiptText, ShoppingCart } from 'lucide-react';
import MovimentacoesChart from '../charts/MovimentacoesChart';
import VendasDiariasChart from '../charts/VendasDiariasChart';
import VendasPorHoraChart from '../charts/VendasPorHoraChart';
import VendasMargemLucroChart from '../charts/VendasMargemLucroChart';
import DespesasTipoPagamentoChart from '../charts/DespesasTipoPagamentoChart';
import MeiosPagamentoChart from '../charts/MeiosPagamentoChart';
import VendasLucroGrupoChart from '../charts/VendasLucroGrupoChart';
import DateRangeFilter from '../DateRangeFilter';
import { useAuth } from '../../contexts/AuthContext';
import '../charts/Charts.css';
import { formatCurrency } from '../../utils/formatters';

export default function OverviewTab({
  numeroVendas,
  valorTotalVendido,
  ticketMedio,
  lucroTotal,
  chartData,
  chartLoading,
  showServiceOrders = false,
  onDateFilterChange,
  startDate,
  endDate,
}) {
  const { userRole } = useAuth();
  const isFinancialAllowed = userRole === 'admin' || userRole === 'gerente';
  const today = new Date().toISOString().split('T')[0];
  const isTodaySelected = startDate === today && endDate === today;

  return (
    <>
      <div className="dashboard-grid">
        <div className="metric-card glass">
          <div className="metric-header">
            <span>Número de Vendas</span>
            <ShoppingCart className="metric-icon" size={24} />
          </div>
          <div className="metric-value" title={chartLoading.vendasDiarias ? "Carregando..." : numeroVendas}>
            {chartLoading.vendasDiarias ? '...' : numeroVendas}
          </div>
        </div>

        <div className="metric-card glass">
          <div className="metric-header">
            <span>Valor Total Vendido</span>
            <CircleDollarSign className="metric-icon" size={24} style={{ color: 'var(--success)', background: 'rgba(0, 108, 73, 0.1)' }} />
          </div>
          <div className="metric-value" title={chartLoading.vendasDiarias ? "Carregando..." : formatCurrency(valorTotalVendido)} style={{ color: 'var(--success)' }}>
            {chartLoading.vendasDiarias ? '...' : formatCurrency(valorTotalVendido)}
          </div>
        </div>

        <div className="metric-card glass">
          <div className="metric-header">
            <span>Ticket Médio</span>
            <ReceiptText className="metric-icon" size={24} />
          </div>
          <div className="metric-value" title={chartLoading.vendasDiarias ? "Carregando..." : formatCurrency(ticketMedio)}>
            {chartLoading.vendasDiarias ? '...' : formatCurrency(ticketMedio)}
          </div>
        </div>

        {isFinancialAllowed && (
          <>
            <div className={`metric-card glass ${lucroTotal >= 0 ? 'credits-metric-card' : 'debits-metric-card'}`}>
              <div className="metric-header">
                <span>Lucro Total</span>
                <BarChart3 className="metric-icon" size={24} />
              </div>
              <div
                className="metric-value"
                title={chartLoading.vendasMargemLucro ? "Carregando..." : `${lucroTotal > 0 ? '+' : ''}${formatCurrency(lucroTotal)}`}
              >
                {chartLoading.vendasMargemLucro ? '...' : `${lucroTotal > 0 ? '+' : ''}${formatCurrency(lucroTotal)}`}
              </div>
            </div>
          </>
        )}
      </div>

      <DateRangeFilter
        onFilterChange={onDateFilterChange}
        initialStartDate={startDate}
        initialEndDate={endDate}
      />

      {/* Charts Section */}
      <div className="charts-section">
        {isTodaySelected ? (
          <VendasPorHoraChart data={chartData.vendasPorHora} loading={chartLoading.vendasPorHora} />
        ) : (
          <>
            {isFinancialAllowed && <MovimentacoesChart data={chartData.movimentacoes} loading={chartLoading.movimentacoes} />}
            <VendasDiariasChart data={chartData.vendasDiarias} loading={chartLoading.vendasDiarias} />
          </>
        )}
        <MeiosPagamentoChart data={chartData.meiosPagamento} title="Vendas por Meio de Pagamento" loading={chartLoading.meiosPagamento} />
        {showServiceOrders && (
          <>
            <VendasDiariasChart
              data={chartData.osDiarias}
              loading={chartLoading.osDiarias}
              title="Faturamento vs. Maior OS"
              loadingText="Carregando ordens de serviço diárias..."
              emptyText="Nenhuma ordem de serviço encontrada"
              secondaryDataKey="maior_os"
              secondaryName="Maior OS"
            />
            <VendasMargemLucroChart
              data={chartData.osMargemLucro}
              loading={chartLoading.osMargemLucro}
              title="Análise de OS e Margem de Lucro"
              loadingText="Carregando dados de OS e margem de lucro..."
              emptyText="Nenhum dado de margem de lucro de OS disponível"
            />
          </>
        )}
        {isFinancialAllowed && (
          <>
            <MeiosPagamentoChart data={chartData.meiosPagamentoCompras} title="Compras por Meio de Pagamento" loading={chartLoading.meiosPagamentoCompras} />
            <MeiosPagamentoChart data={chartData.meiosPagamentoRecebimentos} title="Recebimentos por Meio de Pagamento" innerRadius={0} paddingAngle={0} strokeWidth={2} loading={chartLoading.meiosPagamentoRecebimentos} />
            <MeiosPagamentoChart data={chartData.meiosPagamentoPagamentos} title="Pagamentos por Meio de Pagamento" innerRadius={0} paddingAngle={0} strokeWidth={2} loading={chartLoading.meiosPagamentoPagamentos} />
            <VendasMargemLucroChart data={chartData.vendasMargemLucro} loading={chartLoading.vendasMargemLucro} />
            <DespesasTipoPagamentoChart data={chartData.despesasTipoPagamento} loading={chartLoading.despesasTipoPagamento} />
            <VendasLucroGrupoChart data={chartData.vendasLucroGrupo} title="Lucro de Vendas por Grupo" innerRadius={0} paddingAngle={0} strokeWidth={2} loading={chartLoading.vendasLucroGrupo} />
          </>
        )}
      </div>
    </>
  );
}
