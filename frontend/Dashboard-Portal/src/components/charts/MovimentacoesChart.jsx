import { useMemo, useState, useEffect } from 'react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { ArrowRightLeft, Loader2 } from 'lucide-react';
import { parseDate, formatDayMonth, formatFullDate, formatCurrencyShort } from './chartHelpers';
import { tooltipStyles } from './chartConstants';
import CustomLegend from './CustomLegend';
import { formatCurrency } from '../../utils/formatters';
import './Charts.css';

/* ─────────────────────────────────────
   Helpers
   ───────────────────────────────────── */

/** Group movimentações by date, summing crédito & débito per day */
function groupByDate(items) {
  const map = {};
  items.forEach((item) => {
    const d = parseDate(item.data);
    if (!d) return;
    const key = d.toISOString().slice(0, 10); // YYYY-MM-DD
    if (!map[key]) map[key] = { date: key, credito: 0, debito: 0 };
    map[key].credito += Number(item.credito) || 0;
    map[key].debito += Number(item.debito) || 0;
  });
  return Object.values(map).sort((a, b) => a.date.localeCompare(b.date));
}

/* ─────────────────────────────────────
   Custom Tooltip
   ───────────────────────────────────── */
function CustomTooltip({ active, payload, label }) {
  if (!active || !payload || payload.length === 0) return null;

  return (
    <div style={tooltipStyles.wrapper}>
      <p style={tooltipStyles.date}>{formatFullDate(label)}</p>
      <div style={tooltipStyles.divider} />
      {payload.map((entry) => (
        <div key={entry.dataKey} style={tooltipStyles.row}>
          <span
            style={{
              ...tooltipStyles.dot,
              background: entry.color,
            }}
          />
          <span style={tooltipStyles.label}>{entry.name}</span>
          <span style={{ ...tooltipStyles.value, color: entry.color }}>
            {formatCurrency(entry.value)}
          </span>
        </div>
      ))}
    </div>
  );
}

/* ─────────────────────────────────────
   Main Component
   ───────────────────────────────────── */
export default function MovimentacoesChart({ data = [], loading = false }) {
  const [visible, setVisible] = useState(false);
  const [hiddenSeries, setHiddenSeries] = useState({
    credito: false,
    debito: false
  });

  // Entrance animation
  useEffect(() => {
    if (loading) return;
    const timer = setTimeout(() => setVisible(true), 60);
    return () => clearTimeout(timer);
  }, [loading]);

  const chartData = useMemo(() => {
    return Array.isArray(data) ? groupByDate(data) : [];
  }, [data]);

  if (loading) {
    return (
      <div className="chart-card glass visible chart-loading-container">
        <Loader2 size={32} className="chart-loading-spinner" />
        <p className="chart-empty-text-val">Carregando dados de créditos vs. débitos...</p>
      </div>
    );
  }

  return (
    <div className={`chart-card glass ${visible ? 'mov-chart-visible' : ''}`}>
      {/* Header */}
      <div className="chart-header">
        <div className="chart-header-left">
          <div className="chart-icon-wrap">
            <ArrowRightLeft size={18} />
          </div>
          <h3 className="chart-title-text">Créditos vs. Débitos</h3>
        </div>
      </div>

      {/* Chart */}
      {chartData.length === 0 ? (
        <div className="chart-empty-state">
          <div className="chart-empty-icon">📊</div>
          <div className="chart-empty-text-val">Nenhuma movimentação encontrada</div>
          <div className="chart-empty-sub-text">
            As movimentações aparecerão aqui quando houver dados disponíveis.
          </div>
        </div>
      ) : (
        <div className="chart-wrap-div">
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart
              data={chartData}
              margin={{ top: 10, right: 10, left: -10, bottom: 0 }}
            >
              <defs>
                {/* Green gradient for Crédito */}
                <linearGradient id="gradCredito" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#006c49" stopOpacity={0.35} />
                  <stop offset="95%" stopColor="#006c49" stopOpacity={0.02} />
                </linearGradient>
                {/* Red gradient for Débito */}
                <linearGradient id="gradDebito" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#ba1a1a" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#ba1a1a" stopOpacity={0.02} />
                </linearGradient>
              </defs>

              <CartesianGrid
                strokeDasharray="3 3"
                stroke="rgba(0,0,0,0.06)"
                vertical={false}
              />

              <XAxis
                dataKey="date"
                tickFormatter={formatDayMonth}
                tick={{
                  fontSize: 12,
                  fontFamily: "'Inter', sans-serif",
                  fill: '#584237',
                }}
                axisLine={{ stroke: 'rgba(0,0,0,0.08)' }}
                tickLine={false}
                dy={8}
                interval="preserveStartEnd"
              />

              <YAxis
                tickFormatter={formatCurrencyShort}
                tick={{
                  fontSize: 12,
                  fontFamily: "'Inter', sans-serif",
                  fill: '#584237',
                }}
                axisLine={false}
                tickLine={false}
                width={72}
              />

              <Tooltip
                content={<CustomTooltip />}
                cursor={{
                  stroke: 'rgba(0,0,0,0.08)',
                  strokeWidth: 1,
                  strokeDasharray: '4 4',
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

              <Area
                type="monotone"
                dataKey="credito"
                name="Crédito"
                stroke="#006c49"
                strokeWidth={2.5}
                fill="url(#gradCredito)"
                dot={false}
                hide={hiddenSeries.credito}
                activeDot={{
                  r: 5,
                  strokeWidth: 2,
                  stroke: '#fff',
                  fill: '#006c49',
                }}
              />

              <Area
                type="monotone"
                dataKey="debito"
                name="Débito"
                stroke="#ba1a1a"
                strokeWidth={2.5}
                fill="url(#gradDebito)"
                dot={false}
                hide={hiddenSeries.debito}
                activeDot={{
                  r: 5,
                  strokeWidth: 2,
                  stroke: '#fff',
                  fill: '#ba1a1a',
                }}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      )}
    </div>
  );
}
