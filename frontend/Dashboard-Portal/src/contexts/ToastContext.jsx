import { createContext, useContext, useState, useCallback, useEffect } from 'react';
import { CheckCircle2, AlertTriangle, AlertCircle, Info, X } from 'lucide-react';
import './ToastContext.css';

const ToastContext = createContext(null);

const listeners = new Set();

export const toast = {
  show: (message, type = 'info', duration = 4000) => {
    const id = Date.now() + Math.random().toString(36).substring(2, 9);
    const item = { id, message, type, duration };
    listeners.forEach((listener) => listener(item));
    return id;
  },
  success: (message, duration = 4000) => toast.show(message, 'success', duration),
  error: (message, duration = 5000) => toast.show(message, 'error', duration),
  warning: (message, duration = 4500) => toast.show(message, 'warning', duration),
  info: (message, duration = 4000) => toast.show(message, 'info', duration),
};

export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);

  const removeToast = useCallback((id) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const addToast = useCallback((toastItem) => {
    setToasts((prev) => [...prev, toastItem]);

    if (toastItem.duration > 0) {
      setTimeout(() => {
        removeToast(toastItem.id);
      }, toastItem.duration);
    }
  }, [removeToast]);

  useEffect(() => {
    listeners.add(addToast);
    return () => {
      listeners.delete(addToast);
    };
  }, [addToast]);

  const getIcon = (type) => {
    switch (type) {
      case 'success':
        return <CheckCircle2 size={20} className="toast-icon success" />;
      case 'warning':
        return <AlertTriangle size={20} className="toast-icon warning" />;
      case 'error':
        return <AlertCircle size={20} className="toast-icon error" />;
      default:
        return <Info size={20} className="toast-icon info" />;
    }
  };

  return (
    <ToastContext.Provider value={{ toast, toasts, removeToast }}>
      {children}
      <div className="toast-container" aria-live="polite">
        {toasts.map((item) => (
          <div key={item.id} className={`toast-card toast-${item.type} glass`}>
            <div className="toast-content">
              {getIcon(item.type)}
              <div className="toast-message">{item.message}</div>
            </div>
            <button
              type="button"
              className="toast-close-btn"
              onClick={() => removeToast(item.id)}
              aria-label="Fechar notificação"
            >
              <X size={16} />
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const context = useContext(ToastContext);
  if (!context) {
    return { toast };
  }
  return context;
}

export default toast;
