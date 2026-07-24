import { useMemo, useState, useEffect } from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend
} from 'recharts';
import { Receipt, Loader2 } from 'lucide-react';
import { formatCurrencyShort } from './chartHelpers';
import { tooltipStyles } from './chartConstants';
import CustomLegend from './CustomLegend';
import { formatCurrency } from '../../utils/formatters';
import './Charts.css';

const COLORS = [
  '#006c49', // Forest Green (mandatory green)
  '#f97316', // Orange (mandatory orange)
  '#0284c7', // Sky Blue
  '#8b5cf6', // Purple
  '#eab308', // Yellow
  '#ec4899', // Pink
  '#14b8a6', // Teal
  '#f43f5e', // Rose
  '#3b82f6', // Indigo
  '#64748b'  // Slate
];

export default function DespesasTipoPagamentoChart({ data = [], loading = false }) {
  const [visible, setVisible] = useState(false);
  const [hiddenSeries, setHiddenSeries] = useState({});

  useEffect(() => {
    if (loading) return;
    const timer = setTimeout(() => setVisible(true), 60);
    return () => clearTimeout(timer);
  }, [loading]);

  // 1. Group, summarize and sort data
  const { chartData, paymentTypes } = useMemo(() => {
    const raw = Array.isArray(data) ? data : [];

    // Group by tipo_operacao
    const groups = {};
    const paymentTotals = {};

    raw.forEach(item => {
      const op = item.tipo_operacao || 'OUTRO';
      const pay = item.tipo_pagamento || 'OUTRO';
      const val = parseFloat(item.valor) || 0;

      if (!groups[op]) {
        groups[op] = { tipo_operacao: op, total: 0 };
      }
      groups[op][pay] = (groups[op][pay] || 0) + val;
      groups[op].total += val;

      paymentTotals[pay] = (paymentTotals[pay] || 0) + val;
    });

    // Convert to array and sort by total expense descending
    const sortedGroups = Object.values(groups).sort((a, b) => b.total - a.total);

    // Get unique payment types sorted by overall total usage descending
    const sortedPaymentTypes = Object.keys(paymentTotals).sort((a, b) => paymentTotals[b] - paymentTotals[a]);

    return {
      chartData: sortedGroups,
      paymentTypes: sortedPaymentTypes
    };
  }, [data]);

  // 2. Map payment types to colors
  const paymentColors = useMemo(() => {
    const mapping = {};
    paymentTypes.forEach((type, idx) => {
      mapping[type] = COLORS[idx % COLORS.length];
    });
    return mapping;
  }, [paymentTypes]);

  if (loading) {
    return (
      <div className="chart-card glass visible chart-loading-container" style={{ minHeight: 462 }}>
        <Loader2 size={32} className="chart-loading-spinner" />
        <p className="chart-empty-text-val">Carregando despesas...</p>
      </div>
    );
  }

  return (
    <div className={`chart-card glass ${visible ? 'visible' : ''}`}>
      {/* Header */}
      <div className="chart-header">
        <div className="chart-header-left">
          <div className="chart-icon-wrap">
            <Receipt size={18} />
          </div>
          <h3 className="chart-title-text">Distribuição de Despesas por Tipo de Operação</h3>
        </div>
      </div>

      {chartData.length === 0 ? (
        <div className="chart-empty-state">
          <div className="chart-empty-icon">📊</div>
          <div className="chart-empty-text-val">Nenhuma despesa encontrada</div>
        </div>
      ) : (
        <div className="chart-wrap-div">
          <ResponsiveContainer width="100%" height={340}>
            <BarChart
              data={chartData}
              layout="vertical"
              margin={{ top: 10, right: 10, left: -10, bottom: 0 }}
            >
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.06)" horizontal={false} />

              {/* XAxis type="number" represents values */}
              <XAxis
                type="number"
                tickFormatter={formatCurrencyShort}
                tick={{ fontSize: 11, fontFamily: "'Inter', sans-serif", fill: '#584237' }}
                axisLine={false}
                tickLine={false}
              />

              {/* YAxis type="category" represents the operation types */}
              <YAxis
                type="category"
                dataKey="tipo_operacao"
                tick={{ fontSize: 12, fontFamily: "'Inter', sans-serif", fill: '#0b1c30', fontWeight: 500 }}
                axisLine={{ stroke: 'rgba(0,0,0,0.08)' }}
                tickLine={false}
                width={100}
              />

              <Tooltip
                content={({ active, payload, label }) => {
                  if (!active || !payload || payload.length === 0) return null;

                  // Extract total from first item's payload
                  const total = payload[0].payload.total;

                  // Filter and sort payload segments by value descending
                  const sortedSegments = [...payload]
                    .filter(entry => (parseFloat(entry.value) || 0) > 0)
                    .sort((a, b) => b.value - a.value);

                  return (
                    <div style={tooltipStyles.wrapper}>
                      <p style={{ ...tooltipStyles.date, fontSize: '0.9rem', fontWeight: 700 }}>{label}</p>
                      <div style={tooltipStyles.divider} />
                      <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 8 }}>
                        {sortedSegments.map((entry) => {
                          const val = parseFloat(entry.value) || 0;
                          const pct = total > 0 ? ((val / total) * 100).toFixed(1) : '0.0';
                          const dotColor = entry.color;
                          return (
                            <div key={entry.dataKey} style={tooltipStyles.row}>
                              <span style={{ ...tooltipStyles.dot, background: dotColor }} />
                              <span style={tooltipStyles.label}>{entry.name}:</span>
                              <span style={{ ...tooltipStyles.value, color: dotColor, fontWeight: 700 }}>
                                    {formatCurrency(val)} ({pct}%)
                              </span>
                            </div>
                          );
                        })}
                      </div>
                      <div style={tooltipStyles.divider} />
                      <div style={tooltipStyles.row}>
                        <span style={{ ...tooltipStyles.label, fontWeight: 700 }}>Total Geral:</span>
                        <span style={{ ...tooltipStyles.value, color: '#0b1c30', fontWeight: 800 }}>
                          {formatCurrency(total)}
                        </span>
                      </div>
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

              {/* Stacked bars for each payment type */}
              {paymentTypes.map((type) => (
                <Bar
                  key={type}
                  dataKey={type}
                  name={type}
                  stackId="a"
                  fill={paymentColors[type]}
                  hide={hiddenSeries[type]}
                  barSize={18}
                  radius={[0, 4, 4, 0]}
                />
              ))}
            </BarChart>
          </ResponsiveContainer>
        </div>
      )}
    </div>
  );
}
