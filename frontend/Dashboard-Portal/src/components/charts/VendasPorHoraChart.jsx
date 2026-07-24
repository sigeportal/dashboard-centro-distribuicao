import { useMemo, useState, useEffect } from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { Clock3, Loader2 } from 'lucide-react';
import { formatCurrency } from '../../utils/formatters';
import { formatCurrencyShort } from './chartHelpers';
import { tooltipStyles } from './chartConstants';
import './Charts.css';

function formatHour(value) {
  if (!value) return '';
  const [hour = '00', minute = '00'] = String(value).split(':');
  return `${hour}:${minute}`;
}

export default function VendasPorHoraChart({ data = [], loading = false }) {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (loading) return;
    const timer = setTimeout(() => setVisible(true), 60);
    return () => clearTimeout(timer);
  }, [loading]);

  const chartData = useMemo(() => {
    return Array.isArray(data)
      ? [...data].sort((a, b) => String(a.hora || '').localeCompare(String(b.hora || '')))
      : [];
  }, [data]);

  if (loading) {
    return (
      <div className="chart-card glass visible chart-loading-container full-width-chart">
        <Loader2 size={32} className="chart-loading-spinner" />
        <p className="chart-empty-text-val">Carregando vendas por hora...</p>
      </div>
    );
  }

  return (
    <div className={`chart-card glass full-width-chart ${visible ? 'visible' : ''}`}>
      <div className="chart-header">
        <div className="chart-header-left">
          <div className="chart-icon-wrap">
            <Clock3 size={18} />
          </div>
          <h3 className="chart-title-text">Vendas por Hora</h3>
        </div>
      </div>

      {chartData.length === 0 ? (
        <div className="chart-empty-state">
          <div className="chart-empty-icon">📊</div>
          <div className="chart-empty-text-val">Nenhuma venda encontrada hoje</div>
        </div>
      ) : (
        <div className="chart-wrap-div">
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={chartData} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.06)" vertical={false} />

              <XAxis
                dataKey="hora"
                tickFormatter={formatHour}
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
                cursor={{ stroke: 'rgba(0,108,73,0.2)', strokeWidth: 1, strokeDasharray: '3 3' }}
                content={({ active, payload, label }) => {
                  if (!active || !payload || payload.length === 0) return null;
                  return (
                    <div style={tooltipStyles.wrapper}>
                      <p style={tooltipStyles.date}>{formatHour(label)}</p>
                      <div style={tooltipStyles.divider} />
                      <div style={tooltipStyles.row}>
                        <span style={{ ...tooltipStyles.dot, background: '#006c49' }} />
                        <span style={tooltipStyles.label}>Vendas:</span>
                        <span style={{ ...tooltipStyles.value, color: '#006c49', fontWeight: 700 }}>
                          {formatCurrency(payload[0].value)}
                        </span>
                      </div>
                    </div>
                  );
                }}
              />

              <Line
                type="monotone"
                dataKey="valor"
                name="Vendas"
                stroke="#006c49"
                strokeWidth={3}
                dot={{ r: 4, stroke: '#006c49', strokeWidth: 2, fill: '#fff' }}
                activeDot={{ r: 6, fill: '#006c49' }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      )}
    </div>
  );
}
