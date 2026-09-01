import { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { X, AlertTriangle, ReceiptText, Printer } from 'lucide-react';
import { formatCurrency, formatDate, formatExcelDate, formatExcelTime, formatPercentage } from '../utils/formatters';
import { logError } from '../utils/logger';
import { createApi } from '../services/api';
import useFocusTrap from '../hooks/useFocusTrap';
import './SalesDetailsModal.css';

export default function SalesDetailsModal({ isOpen, onClose, sale }) {
  const modalRef = useFocusTrap(isOpen);
  const [activeTab, setActiveTab] = useState('itens');
  const [loadingSummary, setLoadingSummary] = useState(false);
  const [summaryData, setSummaryData] = useState([]);
  const [summaryError, setSummaryError] = useState(null);

  const saleCode = sale ? (sale.codigo ?? sale.code ?? '-') : '-';

  useEffect(() => {
    if (!isOpen || !saleCode || saleCode === '-') return;

    let isMounted = true;
    const fetchSummary = async () => {
      setLoadingSummary(true);
      setSummaryError(null);
      try {
        const api = createApi(true);
        const res = await api.get(`/v1/vendas/${saleCode}/resumo`);
        if (isMounted) {
          setSummaryData(res.data || []);
        }
      } catch (err) {
        logError('Erro ao carregar resumo de venda:', err);
        if (isMounted) {
          setSummaryError('Falha ao carregar as informações de parcelamento.');
        }
      } finally {
        if (isMounted) {
          setLoadingSummary(false);
        }
      }
    };

    fetchSummary();

    return () => {
      isMounted = false;
    };
  }, [isOpen, saleCode]);

  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [onClose]);

  if (!isOpen || !sale) return null;

  const isPendingReturn = sale.devolucao_p === 'S';
  const saleDate = sale.data ?? sale.date;
  const saleTime = sale.hora ?? sale.time;
  const saleTotal = sale.valor ?? sale.total ?? 0;
  const saleVendor = typeof sale.fun === 'object' && sale.fun !== null
    ? (sale.fun.nome || '-')
    : (sale.vendedor ?? sale.vendor ?? '-');
  const salePdv = sale.pdv ?? '-';
  const saleClient = typeof sale.cli === 'object' && sale.cli !== null
    ? (sale.cli.nome || '-')
    : (sale.cli ?? sale.cliente ?? '-');
  const itens = sale.itens ?? [];

  const formattedDate = saleDate ? formatExcelDate(saleDate) : '-';
  const formattedTime = saleTime ? formatExcelTime(saleTime) : '';
  const dateTimeStr = formattedTime ? `${formattedDate} ${formattedTime}` : formattedDate;

  return createPortal(
    <div className="sales-modal-overlay" onClick={onClose}>
      <div
        ref={modalRef}
        className="sales-modal glass"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="sales-modal-title"
      >
        {/* Header */}
        <div className="sales-modal-header">
          <div className="sales-modal-title-group">
            <div className="sales-modal-icon-badge">
              <ReceiptText size={22} />
            </div>
            <div>
              <h3 id="sales-modal-title">Detalhes da Venda</h3>
              <span className="sales-modal-subtitle">Comprovante #{saleCode} • Lançamento de PDV</span>
            </div>
          </div>
          <button className="sales-modal-close" onClick={onClose} aria-label="Fechar detalhes da venda">
            <X size={20} />
          </button>
        </div>

        {/* Modal Body */}
        <div className="sales-modal-body">
          {isPendingReturn && (
            <div className="sales-modal-warning">
              <AlertTriangle size={18} className="warning-icon" />
              <div>
                <strong>Devolução Pendente:</strong> Há um processo de devolução em aberto para esta venda.
              </div>
            </div>
          )}

          {/* Metadata Grid */}
          <div className="sales-metadata-grid">
            <div className="metadata-card glass">
              <span className="metadata-label">Código</span>
              <span className="metadata-value">#{saleCode}</span>
            </div>
            <div className="metadata-card glass">
              <span className="metadata-label">Data / Hora</span>
              <span className="metadata-value">{dateTimeStr}</span>
            </div>
            <div className="metadata-card glass">
              <span className="metadata-label">Vendedor</span>
              <span className="metadata-value">{saleVendor}</span>
            </div>
            <div className="metadata-card glass">
              <span className="metadata-label">PDV</span>
              <span className="metadata-value">PDV {salePdv}</span>
            </div>
            <div className="metadata-card glass">
              <span className="metadata-label">Cliente</span>
              <span className="metadata-value" title={saleClient}>{saleClient}</span>
            </div>
            <div className="metadata-card highlight glass">
              <span className="metadata-label">Valor Total</span>
              <span className="metadata-value total">{formatCurrency(saleTotal)}</span>
            </div>
          </div>

          {/* Tabs Section */}
          <div className="sales-modal-tabs">
            <button
              type="button"
              className={`sales-modal-tab-btn ${activeTab === 'itens' ? 'active' : ''}`}
              onClick={() => setActiveTab('itens')}
            >
              Itens da Venda ({itens.length})
            </button>
            <button
              type="button"
              className={`sales-modal-tab-btn ${activeTab === 'parcelamento' ? 'active' : ''}`}
              onClick={() => setActiveTab('parcelamento')}
            >
              Parcelamento / Faturamento
            </button>
          </div>

          {/* Dynamic Content */}
          {activeTab === 'itens' && (
            <div className="sales-items-section">
              <div className="sales-table-wrapper">
                <table className="sales-items-table">
                  <thead>
                    <tr>
                      <th style={{ width: '110px' }}>Cód. Produto</th>
                      <th>Nome / Descrição</th>
                      <th style={{ width: '160px' }}>GTIN / Cód. Barras</th>
                      <th className="text-center" style={{ width: '110px' }}>Quantidade</th>
                      <th className="text-right" style={{ width: '120px' }}>Val. Bruto</th>
                      <th className="text-right" style={{ width: '100px' }}>Desconto</th>
                      <th className="text-right" style={{ width: '120px' }}>Val. Líquido</th>
                    </tr>
                  </thead>
                  <tbody>
                    {itens.length === 0 ? (
                      <tr>
                        <td colSpan="7" className="empty-table-msg">
                          Nenhum item cadastrado nesta venda.
                        </td>
                      </tr>
                    ) : (
                      itens.map((item, idx) => {
                        const qty = item.quantidade ?? item.qtd ?? item.quantity ?? 0;
                        const unit = item.embalagem || item.unidade || item.un || 'UN';
                        const barcode = item.gtin || item.codbarra || item.cod_barra || '-';
                        const name = item.nome || item.descricao || item.desc || 'Item sem nome';
                        const proCode = item.pro ?? '';
                        const valGross = item.valorb ?? item.valor_bruto ?? 0;
                        const valDisc = item.desconto ?? 0;
                        const valNet = item.valor ?? item.valor_liquido ?? 0;

                        return (
                          <tr key={idx}>
                            <td data-label="Cód. Produto" className="item-code-cell">
                              {proCode ? <span className="item-code">#{proCode}</span> : '-'}
                            </td>
                            <td data-label="Nome" className="item-name" title={name}>{name}</td>
                            <td data-label="GTIN">{barcode}</td>
                            <td data-label="Quantidade" className="text-center item-qty">{qty} {unit}</td>
                            <td data-label="Val. Bruto" className="text-right">{formatCurrency(valGross)}</td>
                            <td data-label="Desconto" className="text-right discount-val">
                              {valDisc > 0 ? `-${formatPercentage(valDisc)}` : formatPercentage(valDisc)}
                            </td>
                            <td data-label="Val. Líquido" className="text-right net-val">{formatCurrency(valNet)}</td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {activeTab === 'parcelamento' && (
            <div className="sales-installments-section">
              {loadingSummary ? (
                <div className="skeleton-wrapper">
                  <div className="skeleton-row header">
                    <div className="skeleton-cell"></div>
                    <div className="skeleton-cell"></div>
                    <div className="skeleton-cell"></div>
                    <div className="skeleton-cell"></div>
                    <div className="skeleton-cell"></div>
                  </div>
                  <div className="skeleton-row">
                    <div className="skeleton-cell"></div>
                    <div className="skeleton-cell"></div>
                    <div className="skeleton-cell"></div>
                    <div className="skeleton-cell"></div>
                    <div className="skeleton-cell"></div>
                  </div>
                  <div className="skeleton-row">
                    <div className="skeleton-cell"></div>
                    <div className="skeleton-cell"></div>
                    <div className="skeleton-cell"></div>
                    <div className="skeleton-cell"></div>
                    <div className="skeleton-cell"></div>
                  </div>
                </div>
              ) : summaryError ? (
                <div className="sales-modal-error">
                  <AlertTriangle size={20} className="error-icon" />
                  <div>{summaryError}</div>
                </div>
              ) : summaryData.length === 0 ? (
                <div className="empty-table-msg">
                  Esta venda não possui parcelamento ou faturamento registrado.
                </div>
              ) : (
                <div className="sales-table-wrapper">
                  <table className="sales-installments-table">
                    <thead>
                      <tr>
                        <th>Data Faturamento</th>
                        <th>Duplicata</th>
                        <th>Vencimento</th>
                        <th>Meio de Pagamento</th>
                        <th className="text-right">Valor</th>
                      </tr>
                    </thead>
                    <tbody>
                      {summaryData.map((item, idx) => {
                        const billingDate = item.data_pf ? formatDate(item.data_pf) : '-';
                        const dueDate = item.vencimento ? formatDate(item.vencimento) : '-';
                        const duplicate = item.duplicata || '-';
                        const paymentType = item.tipo_pgm || '-';
                        const value = item.valor ?? 0;

                        return (
                          <tr key={idx}>
                            <td data-label="Data Faturamento">{billingDate}</td>
                            <td data-label="Duplicata" className="installment-duplicate">{duplicate}</td>
                            <td data-label="Vencimento">{dueDate}</td>
                            <td data-label="Meio de Pagamento" className="installment-type">{paymentType}</td>
                            <td data-label="Valor" className="text-right net-val">{formatCurrency(value)}</td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className="sales-modal-footer">
          <div className="shortcut-hint">
            <kbd>ESC</kbd> <span>Fechar</span>
          </div>
          <div className="sales-modal-footer-actions">
            <button
              type="button"
              className="btn-secondary"
              onClick={() => window.print()}
              title="Imprimir Comprovante de Venda"
            >
              <Printer size={16} />
              <span>Imprimir</span>
            </button>
            <button
              type="button"
              className="btn-secondary"
              onClick={onClose}
            >
              Fechar
            </button>
          </div>
        </div>
      </div>
    </div>,
    document.body
  );
}

