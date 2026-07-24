import { useMemo } from 'react';
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { CreditCard, Loader2 } from 'lucide-react';
import { formatCurrency } from '../../utils/formatters';
import { tooltipStyles } from './chartConstants';
import './Charts.css';

/* ── Color Palette (mandatory orange and green, plus matching tones) ── */
const COLORS = [
  '#f97316', // Orange (mandatory)
  '#006c49', // Green (mandatory)
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
      <p style={{ ...tooltipStyles.date, fontSize: '0.85rem', fontWeight: 700 }}>{d.tipo_pagamento || 'Outro'}</p>
      <div style={tooltipStyles.divider} />
      <div style={tooltipStyles.row}>
        <span style={tooltipStyles.label}>Valor</span>
        <span style={{ ...tooltipStyles.value, fontWeight: 700, color: d.color }}>
          {formatCurrency(d.valor)}
        </span>
      </div>
      <div style={tooltipStyles.row}>
        <span style={tooltipStyles.label}>Percentual</span>
        <span style={tooltipStyles.value}>{d.percentage}%</span>
      </div>
    </div>
  );
};

/* ── Main Component ── */
export default function MeiosPagamentoChart({ data, title = "Vendas por Meio de Pagamento", loading, innerRadius = 65, paddingAngle = 4, strokeWidth = 1 }) {
  const chartData = useMemo(() => {
    const raw = Array.isArray(data) ? data : (data?.data || []);
    // Filter out zero values to avoid empty slices
    const filtered = raw.filter(item => (Number(item.valor) || 0) > 0);
    const total = filtered.reduce((sum, item) => sum + (Number(item.valor) || 0), 0);

    return filtered.map((item, idx) => {
      const val = Number(item.valor) || 0;
      const pct = total > 0 ? ((val / total) * 100).toFixed(1) : '0.0';
      return {
        ...item,
        valor: val,
        percentage: pct,
        color: COLORS[idx % COLORS.length]
      };
    });
  }, [data]);

  const totalValue = useMemo(() => {
    return chartData.reduce((sum, item) => sum + item.valor, 0);
  }, [chartData]);

  /* ─── loading state ─── */
  if (loading) {
    return (
      <div className="chart-card glass visible chart-loading-container" style={{ minHeight: 326 }}>
        <Loader2 size={32} className="chart-loading-spinner" />
        <p className="chart-empty-text-val">Carregando dados de pagamentos...</p>
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
              <CreditCard size={18} />
            </div>
            <h3 className="chart-title-text">{title}</h3>
          </div>
        </div>
        <div className="chart-empty-state">
          <CreditCard size={40} strokeWidth={1.2} color="#ccc" className="chart-empty-icon" />
          <p className="chart-empty-text-val">Sem dados de pagamentos disponíveis para o período</p>
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
            <CreditCard size={18} />
          </div>
          <h3 className="chart-title-text">{title}</h3>
        </div>
        <div className="chart-badge-text">
          Total: {formatCurrency(totalValue)}
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
                dataKey="valor"
                nameKey="tipo_pagamento"
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
                <span className="chart-pie-legend-label" title={item.tipo_pagamento}>
                  {item.tipo_pagamento}
                </span>
              </div>
              <div className="chart-pie-legend-right">
                <span className="chart-pie-legend-percentage">{item.percentage}%</span>
                <span className="chart-pie-legend-value">{formatCurrency(item.valor)}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
