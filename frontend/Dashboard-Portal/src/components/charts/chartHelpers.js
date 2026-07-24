/** Parse any date string into a Date object safely */
export function parseDate(raw) {
  if (!raw) return null;
  const isDateOnly = /^\d{4}-\d{2}-\d{2}$/.test(raw.trim());
  const normalized = isDateOnly ? raw.trim().replace(/-/g, '/') : raw;
  const d = new Date(normalized);
  return isNaN(d.getTime()) ? null : d;
}

/** Format a Date to dd/MM */
export function formatDayMonth(dateStr) {
  const d = parseDate(dateStr);
  if (!d) return '';
  const dd = String(d.getDate()).padStart(2, '0');
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  return `${dd}/${mm}`;
}

/** Format a Date to dd/MM/yyyy for tooltips */
export function formatFullDate(dateStr) {
  const d = parseDate(dateStr);
  if (!d) return '';
  const dd = String(d.getDate()).padStart(2, '0');
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const yyyy = d.getFullYear();
  return `${dd}/${mm}/${yyyy}`;
}

/** Abbreviate BRL currency for Y-axis (e.g. R$ 1.2k) */
export function formatCurrencyShort(value) {
  if (value >= 1_000_000) return `R$ ${(value / 1_000_000).toFixed(1)}M`;
  if (value >= 1_000) return `R$ ${(value / 1_000).toFixed(1)}k`;
  return `R$ ${value}`;
}
