import { legendStyles } from './chartConstants';

export default function CustomLegend({ payload, hiddenSeries, onLegendClick }) {
  if (!payload) return null;
  return (
    <div style={legendStyles.wrapper}>
      {payload.map((entry) => {
        let color = entry.color;
        if (color && color.startsWith('url(#')) {
          if (color.includes('Vendas')) {
            color = '#006c49';
          } else {
            color = 'var(--accent)';
          }
        }
        const isHidden = hiddenSeries ? hiddenSeries[entry.dataKey] : false;
        return (
          <div
            key={entry.value}
            style={{
              ...legendStyles.item,
              cursor: onLegendClick ? 'pointer' : 'default',
              opacity: isHidden ? 0.35 : 1,
              transition: 'opacity 0.2s ease',
              userSelect: 'none'
            }}
            onClick={() => {
              if (onLegendClick && entry.dataKey) {
                onLegendClick(entry.dataKey);
              }
            }}
          >
            <span
              style={{
                ...legendStyles.dot,
                background: color,
              }}
            />
            <span style={legendStyles.text}>{entry.value}</span>
          </div>
        );
      })}
    </div>
  );
}
