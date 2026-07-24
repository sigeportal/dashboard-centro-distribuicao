import { useMemo } from 'react';
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { Package, Loader2 } from 'lucide-react';
import { formatCurrency } from '../../utils/formatters';
import { tooltipStyles } from './chartConstants';
import './Charts.css';

/* ── Color Palette (consistent with MeiosPagamentoChart) ── */
const COLORS = [
  '#f97316', // Orange
  '#006c49', // Green
  '#0284c7', // Blue
  '#8b5cf6', // Purple
  '#eab308', // Yellow
  '#ec4899', // Pink
  '#14b8a6', // Teal
  '#64748b'  // Slate
];

/* ── Custom Tooltip ── */
const CustomTooltip = ({ active, payload }) => {
  if (!active || !payload?.length) return null;
  const d = payload[0].payload;

  return (
    <div style={tooltipStyles.wrapper}>
      <p style={{ ...tooltipStyles.date, fontSize: '0.85rem', fontWeight: 700 }}>{d.nome || 'Outro'}</p>
      <div style={tooltipStyles.divider} />
      <div style={tooltipStyles.row}>
        <span style={tooltipStyles.label}>Lucro</span>
        <span style={{ ...tooltipStyles.value, fontWeight: 700, color: d.color }}>
          {formatCurrency(d.lucro)}
        </span>
      </div>
      <div style={tooltipStyles.row}>
        <span style={tooltipStyles.label}>Faturamento</span>
        <span style={tooltipStyles.value}>{formatCurrency(d.valor)}</span>
      </div>
      <div style={tooltipStyles.row}>
        <span style={tooltipStyles.label}>Percentual</span>
        <span style={tooltipStyles.value}>{d.percentage}%</span>
      </div>
    </div>
  );
};

/* ── Main Component ── */
export default function VendasLucroGrupoChart({
  data,
  title = "Lucro de Vendas por Grupo",
  loading,
  innerRadius = 0,
  paddingAngle = 0,
  strokeWidth = 2,
  loadingText = 'Carregando dados de lucro por grupo...',
  emptyText = 'Sem dados de lucro por grupo de produtos disponíveis'
}) {
  const chartData = useMemo(() => {
    const raw = Array.isArray(data) ? data : (data?.data || []);
    // Filter out zero/negative values for profit (lucro) to avoid empty or invalid slices
    const filtered = raw.filter(item => (Number(item.lucro) || 0) > 0);
    const totalFaturamento = filtered.reduce((sum, item) => sum + (Number(item.valor) || 0), 0);

    return filtered.map((item, idx) => {
      const profit = Number(item.lucro) || 0;
      const revenue = Number(item.valor) || 0;
      const pct = totalFaturamento > 0 ? ((revenue / totalFaturamento) * 100).toFixed(1) : '0.0';
      return {
        ...item,
        lucro: profit,
        percentage: pct,
        color: COLORS[idx % COLORS.length]
      };
    });
  }, [data]);

  const totalValue = useMemo(() => {
    return chartData.reduce((sum, item) => sum + item.lucro, 0);
  }, [chartData]);

  /* ─── loading state ─── */
  if (loading) {
    return (
      <div className="chart-card glass visible chart-loading-container" style={{ minHeight: 326 }}>
        <Loader2 size={32} className="chart-loading-spinner" />
        <p className="chart-empty-text-val">{loadingText}</p>
      </div>
    );
  }

  /* ─── empty state ─── */
  if (chartData.length === 0) {
    return (
      <div className="chart-card glass visible">
        <div className="chart-header">
          <div className="chart-header-left">
            <div className="chart-icon-wrap">
              <Package size={18} />
            </div>
            <h3 className="chart-title-text">{title}</h3>
          </div>
        </div>
        <div className="chart-empty-state">
          <Package size={40} strokeWidth={1.2} color="#ccc" className="chart-empty-icon" />
          <p className="chart-empty-text-val">{emptyText}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="chart-card glass visible">
      {/* Header */}
      <div className="chart-header">
        <div className="chart-header-left">
          <div className="chart-icon-wrap">
            <Package size={18} />
          </div>
          <h3 className="chart-title-text">{title}</h3>
        </div>
        <div className="chart-badge-text">
          Lucro Total: {formatCurrency(totalValue)}
        </div>
      </div>

      {/* Chart and Legend container */}
      <div className="chart-pie-container">
        <div className="chart-pie-wrap">
          <ResponsiveContainer width="100%" height={240}>
            <PieChart>
              <Pie
                data={chartData}
                cx="50%"
                cy="50%"
                innerRadius={innerRadius}
                outerRadius={85}
                paddingAngle={paddingAngle}
                dataKey="lucro"
                nameKey="nome"
                animationDuration={800}
                animationEasing="ease-out"
                stroke="#ffffff"
                strokeWidth={strokeWidth}
              >
                {chartData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip content={<CustomTooltip />} wrapperStyle={{ zIndex: 10 }} />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Custom scrollable legend */}
        <div className="chart-pie-legend-wrap">
          {chartData.map((item, idx) => (
            <div key={idx} className="chart-pie-legend-item">
              <div className="chart-pie-legend-left">
                <span className="chart-pie-legend-dot" style={{ backgroundColor: item.color }} />
                <span className="chart-pie-legend-label" title={item.nome}>
                  {item.nome}
                </span>
              </div>
              <div className="chart-pie-legend-right">
                <span className="chart-pie-legend-percentage">{item.percentage}%</span>
                <span className="chart-pie-legend-value">{formatCurrency(item.lucro)}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
