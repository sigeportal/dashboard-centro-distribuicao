export const tooltipStyles = {
  wrapper: {
    background: 'rgba(255, 255, 255, 0.92)',
    backdropFilter: 'blur(16px)',
    WebkitBackdropFilter: 'blur(16px)',
    border: '1px solid rgba(0, 0, 0, 0.08)',
    borderRadius: '0.75rem',
    padding: '0.875rem 1rem',
    boxShadow: '0px 8px 24px rgba(0, 0, 0, 0.10)',
    fontFamily: "'Inter', sans-serif",
    minWidth: 180,
  },
  date: {
    fontSize: '0.8rem',
    fontWeight: 600,
    color: '#0b1c30',
    margin: 0,
    marginBottom: 6,
  },
  divider: {
    height: 1,
    background: 'rgba(0,0,0,0.08)',
    marginBottom: 8,
  },
  row: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    marginBottom: 4,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: '50%',
    flexShrink: 0,
  },
  label: {
    fontSize: '0.8rem',
    color: '#584237',
    flex: 1,
  },
  value: {
    fontSize: '0.8rem',
    fontWeight: 600,
  },
};

export const legendStyles = {
  wrapper: {
    display: 'flex',
    justifyContent: 'center',
    gap: '1.5rem',
    paddingTop: '0.5rem',
  },
  item: {
    display: 'flex',
    alignItems: 'center',
    gap: 6,
  },
  dot: {
    width: 10,
    height: 10,
    borderRadius: '50%',
  },
  text: {
    fontSize: '0.8rem',
    fontWeight: 500,
    color: '#584237',
    fontFamily: "'Inter', sans-serif",
  },
};
