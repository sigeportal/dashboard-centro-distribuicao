import { useState, useCallback, useRef, useEffect } from 'react';
import { Calendar } from 'lucide-react';

function formatDate(date) {
  return date.toISOString().split('T')[0];
}

const TODAY = formatDate(new Date());
const SEVEN_DAYS_AGO = formatDate(new Date(Date.now() - 7 * 86400000));

const CHIPS = [
  { label: 'Hoje', days: 0 },
  { label: '7 dias', days: 7 },
  { label: '15 dias', days: 15 },
  { label: '30 dias', days: 30 },
];

export default function DateRangeFilter({ onFilterChange, initialStartDate, initialEndDate, children }) {
  const getInitialActiveChip = () => {
    if (!initialStartDate || !initialEndDate || initialEndDate !== TODAY) return null;
    const diffTime = Math.abs(new Date(initialEndDate) - new Date(initialStartDate));
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    const chip = CHIPS.find(c => c.days === diffDays);
    return chip ? chip.days : null;
  };

  const [activeChip, setActiveChip] = useState(() => {
    if (!initialStartDate && !initialEndDate) {
      return 7;
    }
    return getInitialActiveChip();
  });
  const [startDate, setStartDate] = useState(() => initialStartDate || SEVEN_DAYS_AGO);
  const [endDate, setEndDate] = useState(() => initialEndDate || TODAY);

  const startDateRef = useRef(startDate);
  const endDateRef = useRef(endDate);
  const debounceTimeoutRef = useRef(null);

  // Sync refs with the latest state
  useEffect(() => {
    startDateRef.current = startDate;
    endDateRef.current = endDate;
  }, [startDate, endDate]);

  useEffect(() => {
    return () => {
      if (debounceTimeoutRef.current) {
        clearTimeout(debounceTimeoutRef.current);
      }
    };
  }, []);

  const handleChip = useCallback((days) => {
    if (debounceTimeoutRef.current) {
      clearTimeout(debounceTimeoutRef.current);
    }
    const end = TODAY;
    const start = formatDate(new Date(Date.now() - days * 86400000));
    setActiveChip(days);
    setStartDate(start);
    setEndDate(end);
    startDateRef.current = start;
    endDateRef.current = end;
    onFilterChange(start, end);
  }, [onFilterChange]);

  const handleStartChange = useCallback((e) => {
    const val = e.target.value;
    setStartDate(val);
    startDateRef.current = val;
    setActiveChip(null);
    
    if (debounceTimeoutRef.current) {
      clearTimeout(debounceTimeoutRef.current);
    }
    
    debounceTimeoutRef.current = setTimeout(() => {
      onFilterChange(startDateRef.current || null, endDateRef.current || null);
    }, 2000);
  }, [onFilterChange]);

  const handleEndChange = useCallback((e) => {
    const val = e.target.value;
    setEndDate(val);
    endDateRef.current = val;
    setActiveChip(null);
    
    if (debounceTimeoutRef.current) {
      clearTimeout(debounceTimeoutRef.current);
    }
    
    debounceTimeoutRef.current = setTimeout(() => {
      onFilterChange(startDateRef.current || null, endDateRef.current || null);
    }, 2000);
  }, [onFilterChange]);

  const handleClear = useCallback(() => {
    if (debounceTimeoutRef.current) {
      clearTimeout(debounceTimeoutRef.current);
    }
    const end = TODAY;
    const start = SEVEN_DAYS_AGO;
    setActiveChip(7);
    setStartDate(start);
    setEndDate(end);
    startDateRef.current = start;
    endDateRef.current = end;
    onFilterChange(start, end);
  }, [onFilterChange]);

  return (
    <div className="date-range-filter">
      <style>{`
        .date-range-filter {
          display: flex;
          justify-content: space-between;
          align-items: center;
          flex-wrap: wrap;
          gap: 1rem;
          padding: 1rem 1.5rem;
          background: var(--bg-secondary);
          border: 1px solid rgba(0,0,0,0.06);
          border-radius: 1rem;
          box-shadow: 0px 2px 8px rgba(0,0,0,0.04);
          margin-bottom: 1.5rem;
        }
        .date-range-filter .drf-left-group {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: 0.75rem;
        }
        .date-range-filter .drf-chips-wrapper {
          display: flex;
          align-items: center;
          flex-wrap: wrap;
          gap: 0.5rem;
        }
        .date-range-filter .drf-label {
          display: flex;
          align-items: center;
          gap: 0.35rem;
          font-size: 0.85rem;
          color: var(--text-secondary);
          font-family: inherit;
        }
        .date-range-filter .drf-input {
          padding: 8px 12px;
          border-radius: 8px;
          border: 1px solid rgba(0,0,0,0.12);
          background: #fff;
          font-family: inherit;
          font-size: 0.85rem;
          outline: none;
          color: var(--text-primary);
          transition: border-color 0.2s, box-shadow 0.2s;
        }
        .date-range-filter .drf-input:focus {
          border-color: var(--accent);
          box-shadow: 0 0 0 2px rgba(249,115,22,0.15);
        }
        .date-range-filter .drf-chip {
          padding: 8px 16px;
          border-radius: 20px;
          border: 1px solid rgba(0,0,0,0.08);
          background: rgba(0,0,0,0.03);
          color: var(--text-secondary);
          font-size: 0.85rem;
          font-family: inherit;
          cursor: pointer;
          transition: background 0.2s, color 0.2s, border-color 0.2s;
        }
        .date-range-filter .drf-chip:hover {
          background: rgba(0,0,0,0.06);
        }
        .date-range-filter .drf-chip.active {
          background: var(--accent);
          color: #fff;
          border-color: var(--accent);
          font-weight: 600;
        }
        .date-range-filter .drf-chip.active:hover {
          background: var(--accent-hover);
        }
        .date-range-filter .drf-clear {
          padding: 8px 16px;
          border-radius: 20px;
          border: 1px solid rgba(0,0,0,0.08);
          background: rgba(0,0,0,0.03);
          color: var(--text-secondary);
          font-size: 0.85rem;
          font-family: inherit;
          cursor: pointer;
          transition: background 0.2s, color 0.2s;
        }
        .date-range-filter .drf-clear:hover {
          background: rgba(0,0,0,0.08);
          color: var(--text-primary);
        }
        .date-range-filter .drf-select-container {
          display: flex;
          align-items: center;
          gap: 0.35rem;
          font-size: 0.85rem;
          color: var(--text-secondary);
        }
        @media (max-width: 768px) {
          .date-range-filter {
            flex-direction: column;
            align-items: stretch;
          }
          .date-range-filter .drf-left-group {
            flex-direction: column;
            align-items: stretch;
            width: 100%;
          }
          .date-range-filter .drf-left-group .drf-input {
            width: 100%;
          }
          .date-range-filter .drf-chips-wrapper {
            width: 100%;
            flex-wrap: wrap;
            justify-content: flex-start;
          }
          .date-range-filter .drf-select-container {
            width: 100%;
          }
          .date-range-filter .drf-select-container select {
            width: 100%;
          }
        }
      `}</style>

      <div className="drf-left-group">
        <label className="drf-label">
          <Calendar size={16} />
          De
          <input
            type="date"
            className="drf-input"
            value={startDate}
            onChange={handleStartChange}
          />
        </label>

        <label className="drf-label">
          Até
          <input
            type="date"
            className="drf-input"
            value={endDate}
            onChange={handleEndChange}
          />
        </label>

        <div className="drf-chips-wrapper">
          {CHIPS.map((chip) => (
            <button
              key={chip.days}
              type="button"
              className={`drf-chip${activeChip === chip.days ? ' active' : ''}`}
              onClick={() => handleChip(chip.days)}
              aria-pressed={activeChip === chip.days}
            >
              {chip.label}
            </button>
          ))}

          <button type="button" className="drf-clear" onClick={handleClear}>
            Limpar
          </button>
        </div>
      </div>

      {children}
    </div>
  );
}
