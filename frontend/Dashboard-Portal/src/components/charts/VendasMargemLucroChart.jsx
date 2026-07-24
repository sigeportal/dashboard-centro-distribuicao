import { useMemo, useState, useEffect } from 'react';
import {
   ComposedChart,
   Bar,
   Line,
   XAxis,
   YAxis,
   CartesianGrid,
   Tooltip,
   ResponsiveContainer,
   Legend
} from 'recharts';
import { TrendingUp, Loader2 } from 'lucide-react';
import { formatDayMonth, formatFullDate, formatCurrencyShort } from './chartHelpers';
import { tooltipStyles } from './chartConstants';
import CustomLegend from './CustomLegend';
import { formatCurrency } from '../../utils/formatters';
import './Charts.css';

export default function VendasMargemLucroChart({
  data = [],
  loading = false,
  title = 'Análise de Faturamento e Margem de Lucro',
  loadingText = 'Carregando dados de faturamento e margem de lucro...',
  emptyText = 'Nenhum dado de margem de lucro disponível'
}) {
  const [visible, setVisible] = useState(false);
  const [hiddenSeries, setHiddenSeries] = useState({
    valor: false,
    margem_lucro: false
  });

  useEffect(() => {
    if (loading) return;
    const timer = setTimeout(() => setVisible(true), 60);
    return () => clearTimeout(timer);
  }, [loading]);

  const chartData = useMemo(() => {
    const raw = Array.isArray(data) ? data : [];
    const sorted = [...raw].sort((a, b) => (a.data || '').localeCompare(b.data || ''));
    
    return sorted.map(item => {
      const valor = parseFloat(item.valor) || 0;
      const margemReais = parseFloat(item.margem_lucro) || 0;
      const percentual = valor > 0 ? (margemReais / valor) * 100 : 0;
      
      return {
        ...item,
        valor,
        margem_reais: margemReais,
        margem_lucro: percentual
      };
    });
  }, [data]);

  if (loading) {
    return (
      <div className="chart-card glass full-width-chart visible chart-loading-container">
        <Loader2 size={32} className="chart-loading-spinner" />
        <p className="chart-empty-text-val">{loadingText}</p>
      </div>
    );
  }

  return (
    <div className={`chart-card glass full-width-chart ${visible ? 'visible' : ''}`}>
      {/* Header */}
      <div className="chart-header">
        <div className="chart-header-left">
          <div className="chart-icon-wrap">
            <TrendingUp size={18} />
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
          <ResponsiveContainer width="100%" height={320}>
            <ComposedChart data={chartData} margin={{ top: 10, right: -5, left: -10, bottom: 0 }}>
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

              {/* Left Y Axis for Faturamento */}
              <YAxis
                yAxisId="left"
                tickFormatter={formatCurrencyShort}
                tick={{ fontSize: 11, fontFamily: "'Inter', sans-serif", fill: '#584237' }}
                axisLine={false}
                tickLine={false}
                width={65}
              />

              {/* Right Y Axis for Margem de Lucro (%) */}
              <YAxis
                yAxisId="right"
                orientation="right"
                tickFormatter={(val) => `${Number(val).toFixed(0)}%`}
                tick={{ fontSize: 11, fontFamily: "'Inter', sans-serif", fill: '#584237' }}
                axisLine={false}
                tickLine={false}
                width={45}
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
                        const labelText = isValor ? 'Faturamento:' : 'Margem de Lucro:';
                        
                        const item = entry.payload;
                        const valueText = isValor 
                          ? formatCurrency(entry.value) 
                          : `${Number(entry.value).toFixed(1)}% (${formatCurrency(item.margem_reais)})`;
                          
                        return (
                          <div key={entry.dataKey} style={tooltipStyles.row}>
                            <span style={{ ...tooltipStyles.dot, background: dotColor }} />
                            <span style={tooltipStyles.label}>{labelText}</span>
                            <span style={{ ...tooltipStyles.value, color: dotColor, fontWeight: 700 }}>
                              {valueText}
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

              {/* Bar representing Faturamento Total */}
              <Bar
                yAxisId="left"
                dataKey="valor"
                name="Faturamento Total"
                fill="#006c49"
                radius={[4, 4, 0, 0]}
                maxBarSize={45}
                hide={hiddenSeries.valor}
              />

              {/* Line representing Margem de Lucro (%) */}
              <Line
                yAxisId="right"
                type="monotone"
                dataKey="margem_lucro"
                name="Margem de Lucro"
                stroke="var(--accent)"
                strokeWidth={3}
                dot={{ r: 4, stroke: 'var(--accent)', strokeWidth: 2, fill: '#fff' }}
                activeDot={{ r: 6 }}
                hide={hiddenSeries.margem_lucro}
              />
            </ComposedChart>
          </ResponsiveContainer>
        </div>
      )}
    </div>
  );
}
