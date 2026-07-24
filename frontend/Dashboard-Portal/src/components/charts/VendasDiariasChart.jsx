import { useMemo, useState, useEffect } from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend
} from 'recharts';
import { ShoppingBag, Loader2 } from 'lucide-react';
import { formatDayMonth, formatFullDate, formatCurrencyShort } from './chartHelpers';
import { tooltipStyles } from './chartConstants';
import CustomLegend from './CustomLegend';
import { formatCurrency } from '../../utils/formatters';
import './Charts.css';

export default function VendasDiariasChart({
  data = [],
  loading = false,
  title = 'Faturamento vs. Maior Venda',
  loadingText = 'Carregando vendas diárias...',
  emptyText = 'Nenhuma venda encontrada',
  secondaryDataKey = 'maior_venda',
  secondaryName = 'Maior Venda'
}) {
  const [visible, setVisible] = useState(false);
  const [hiddenSeries, setHiddenSeries] = useState({
    valor: false,
    [secondaryDataKey]: false
  });

  useEffect(() => {
    if (loading) return;
    const timer = setTimeout(() => setVisible(true), 60);
    return () => clearTimeout(timer);
  }, [loading]);

  const chartData = useMemo(() => {
    return Array.isArray(data)
      ? [...data].sort((a, b) => (a.data || '').localeCompare(b.data || ''))
      : [];
  }, [data]);

  if (loading) {
    return (
      <div className="chart-card glass visible chart-loading-container">
        <Loader2 size={32} className="chart-loading-spinner" />
        <p className="chart-empty-text-val">{loadingText}</p>
      </div>
    );
  }

  return (
    <div className={`chart-card glass ${visible ? 'visible' : ''}`}>
      {/* Header */}
      <div className="chart-header">
        <div className="chart-header-left">
          <div className="chart-icon-wrap">
            <ShoppingBag size={18} />
          </div>
          <h3 className="chart-title-text">{title}</h3>
        </div>
      </div>

      {chartData.length === 0 ? (
        <div className="chart-empty-state">
          <div className="chart-empty-icon">📊</div>
          <div className="chart-empty-text-val">{emptyText}</div>
        </div>
      ) : (
        <div className="chart-wrap-div">
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={chartData} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.06)" vertical={false} />

              <XAxis
                dataKey="data"
                tickFormatter={formatDayMonth}
                tick={{ fontSize: 12, fontFamily: "'Inter', sans-serif", fill: '#584237' }}
                axisLine={{ stroke: 'rgba(0,0,0,0.08)' }}
                tickLine={false}
                dy={8}
                interval="preserveStartEnd"
              />

              <YAxis
                tickFormatter={formatCurrencyShort}
                tick={{ fontSize: 11, fontFamily: "'Inter', sans-serif", fill: '#584237' }}
                axisLine={false}
                tickLine={false}
                width={70}
              />

              <Tooltip
                content={({ active, payload, label }) => {
                  if (!active || !payload || payload.length === 0) return null;
                  return (
                    <div style={tooltipStyles.wrapper}>
                      <p style={tooltipStyles.date}>{formatFullDate(label)}</p>
                      <div style={tooltipStyles.divider} />
                      {payload.map((entry) => {
                        const isValor = entry.dataKey === 'valor';
                        const dotColor = isValor ? '#006c49' : 'var(--accent)';
                        const labelText = isValor ? 'Faturamento Total:' : `${secondaryName}:`;
                        return (
                          <div key={entry.dataKey} style={tooltipStyles.row}>
                            <span style={{ ...tooltipStyles.dot, background: dotColor }} />
                            <span style={tooltipStyles.label}>{labelText}</span>
                            <span style={{ ...tooltipStyles.value, color: dotColor, fontWeight: 700 }}>
                              {formatCurrency(entry.value)}
                            </span>
                          </div>
                        );
                      })}
                    </div>
                  );
                }}
              />

              <Legend
                content={
                  <CustomLegend
                    hiddenSeries={hiddenSeries}
                    onLegendClick={(dataKey) => {
                      setHiddenSeries(prev => ({
                        ...prev,
                        [dataKey]: !prev[dataKey]
                      }));
                    }}
                  />
                }
              />

              <Line
                type="monotone"
                dataKey="valor"
                name="Faturamento Total"
                stroke="#006c49"
                strokeWidth={3}
                dot={{ r: 4, stroke: '#006c49', strokeWidth: 2, fill: '#fff' }}
                activeDot={{ r: 6 }}
                hide={hiddenSeries.valor}
              />

              <Line
                type="monotone"
                dataKey={secondaryDataKey}
                name={secondaryName}
                stroke="var(--accent)"
                strokeWidth={3}
                dot={{ r: 4, stroke: 'var(--accent)', strokeWidth: 2, fill: '#fff' }}
                activeDot={{ r: 6 }}
                hide={hiddenSeries[secondaryDataKey]}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      )}
    </div>
  );
}
