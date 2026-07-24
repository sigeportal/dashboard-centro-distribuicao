import { useMemo, useState } from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from 'recharts';
import { Users, Loader2 } from 'lucide-react';
import { tooltipStyles } from './chartConstants';
import './Charts.css';

/* ───────────────────────── helpers ───────────────────────────────────── */
const truncate = (str, max = 15) =>
  str && str.length > max ? `${str.slice(0, max)}…` : str;

/* ───────────────────────── custom tooltip ────────────────────────────── */
const CustomTooltip = ({ active, payload }) => {
  if (!active || !payload?.length) return null;
  const d = payload[0].payload;

  return (
    <div style={tooltipStyles.wrapper}>
      <p style={tooltipStyles.label}>{d._fullName}</p>
      <p style={tooltipStyles.value}>
        <span style={tooltipStyles.dot} />
        {payload[0].value} {payload[0].value === 1 ? 'cliente' : 'clientes'}
      </p>
    </div>
  );
};

/* ───────────────────────── component ─────────────────────────────────── */
export default function ClientesChart({ data, loading }) {
  const [hoveredIndex, setHoveredIndex] = useState(null);

  const chartData = useMemo(() => {
    const raw = Array.isArray(data) ? data : [];
    const sorted = [...raw].sort((a, b) => (Number(b.clientes) || 0) - (Number(a.clientes) || 0));
    
    // Top 8 cities to keep chart neat and tidy
    return sorted.slice(0, 8).map((c) => ({
      ...c,
      _fullName: c.cidade || 'Cidade Desconhecida',
      cidade: truncate(c.cidade || 'Cidade Desconhecida'),
    }));
  }, [data]);

  const totalCidades = useMemo(() => {
    return Array.isArray(data) ? data.length : 0;
  }, [data]);

  /* ─── loading state ─── */
  if (loading) {
    return (
      <div className="chart-card glass visible chart-loading-container">
        <Loader2 size={32} className="chart-loading-spinner" />
        <p className="chart-empty-text-val">Carregando dados de clientes por cidade...</p>
      </div>
    );
  }

  /* ─── empty state ─── */
  if (!chartData || chartData.length === 0) {
    return (
      <div className="chart-card glass visible">
        <div className="chart-header">
          <div className="chart-header-left">
            <div className="chart-icon-wrap">
              <Users size={20} />
            </div>
            <h3 className="chart-title-text">Clientes por Cidade</h3>
          </div>
        </div>
        <div className="chart-empty-state">
          <Users size={40} strokeWidth={1.2} color="#ccc" className="chart-empty-icon" />
          <p className="chart-empty-text-val">Sem dados de clientes por cidade disponíveis</p>
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
            <Users size={20} />
          </div>
          <h3 className="chart-title-text">Clientes por Cidade</h3>
        </div>
      </div>

      {/* Chart */}
      <div className="chart-wrap-div">
        <ResponsiveContainer width="100%" height={300}>
          <BarChart
            data={chartData}
            margin={{ top: 10, right: 10, left: -10, bottom: 30 }}
            barCategoryGap="20%"
          >
            {/* Gradient definition */}
            <defs>
              <linearGradient id="barGradientClientes" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#f97316" stopOpacity={1} />
                <stop offset="100%" stopColor="#fdba74" stopOpacity={0.75} />
              </linearGradient>
              <linearGradient id="barGradientClientesHover" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#ea580c" stopOpacity={1} />
                <stop offset="100%" stopColor="#f97316" stopOpacity={0.9} />
              </linearGradient>
            </defs>

            <CartesianGrid
              strokeDasharray="3 3"
              stroke="rgba(0,0,0,0.06)"
              vertical={false}
            />

            <XAxis
              dataKey="cidade"
              tick={{ fontSize: 11, fontFamily: 'Inter', fill: '#584237', fontWeight: 500 }}
              axisLine={{ stroke: 'rgba(0,0,0,0.1)' }}
              tickLine={false}
              dy={8}
              angle={-25}
              textAnchor="end"
              height={50}
            />

            <YAxis
              allowDecimals={false}
              tick={{ fontSize: 12, fontFamily: 'Inter', fill: '#584237' }}
              axisLine={false}
              tickLine={false}
              dx={-4}
            />

            <Tooltip
              content={<CustomTooltip />}
              cursor={{ fill: 'rgba(249, 115, 22, 0.06)', radius: 6 }}
            />

            <Bar
              dataKey="clientes"
              radius={[6, 6, 0, 0]}
              animationBegin={100}
              animationDuration={800}
              animationEasing="ease-out"
              onMouseLeave={() => setHoveredIndex(null)}
            >
              {chartData.map((_, index) => (
                <Cell
                  key={`cell-${index}`}
                  fill={
                    hoveredIndex === index
                      ? 'url(#barGradientClientesHover)'
                      : 'url(#barGradientClientes)'
                  }
                  onMouseEnter={() => setHoveredIndex(index)}
                  style={{
                    transition: 'filter 0.2s ease, transform 0.2s ease',
                    filter: hoveredIndex === index ? 'brightness(1.05) drop-shadow(0 4px 8px rgba(249,115,22,0.3))' : 'none',
                    cursor: 'pointer',
                  }}
                />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Footer summary */}
      <div className="chart-footer">
        <span className="chart-footer-text">
          {totalCidades} {totalCidades === 1 ? 'cidade' : 'cidades'}
        </span>
      </div>
    </div>
  );
}
