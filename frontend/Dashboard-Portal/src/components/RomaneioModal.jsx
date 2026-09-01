import React, { useEffect } from 'react';
import { Printer, X, PackageCheck, Truck, ShieldCheck, FileText } from 'lucide-react';
import { formatDate, formatCurrency } from '../utils/formatters';
import './RomaneioModal.css';

export default function RomaneioModal({ transfer, items = [], products = [], units = [], onClose }) {
  if (!transfer) return null;

  // Atalhos de teclado (ESC para fechar, CTRL+P para imprimir)
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape') {
        if (onClose) onClose();
      } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'p') {
        e.preventDefault();
        window.print();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onClose]);

  const cleanName = (str) => {
    if (!str) return '';
    return String(str)
      .replace(/CALÃ≠ADOS/gi, 'CALÇADOS')
      .replace(/CALÃ‡ADOS/gi, 'CALÇADOS')
      .replace(/CALÃ§ADOS/gi, 'CALÇADOS');
  };

  const getUnitName = (unitId) => {
    if (!unitId) return 'N/A';
    const found = units.find(u => Number(u.id) === Number(unitId));
    return cleanName(found ? found.name : `Unidade #${unitId}`);
  };

  const handlePrint = () => {
    window.print();
  };

  const resolveItemSize = (item, prod) => {
    if (!item) return 'UN';
    if (typeof item.tamanho === 'string' && item.tamanho.trim() && item.tamanho !== '-') return item.tamanho.trim();
    if (typeof item.tamanho_str === 'string' && item.tamanho_str.trim() && item.tamanho_str !== '-') return item.tamanho_str.trim();
    if (typeof item.tam_nome === 'string' && item.tam_nome.trim() && item.tam_nome !== '-') return item.tam_nome.trim();
    if (typeof item.sigla === 'string' && item.sigla.trim() && item.sigla !== '-') return item.sigla.trim();
    if (typeof item.tam === 'string' && item.tam.trim() && item.tam !== '-' && isNaN(Number(item.tam))) return item.tam.trim();
    if (item.tamanho && typeof item.tamanho === 'object') {
      if (item.tamanho.sigla) return item.tamanho.sigla;
      if (item.tamanho.tamanho) return item.tamanho.tamanho;
    }
    if (prod) {
      if (prod.um && String(prod.um).trim()) return String(prod.um).trim();
      if (prod.embalagem && String(prod.embalagem).trim()) return String(prod.embalagem).trim();
    }
    if (item.um && String(item.um).trim()) return String(item.um).trim();
    if (item.embalagem && String(item.embalagem).trim()) return String(item.embalagem).trim();
    return 'UN';
  };

  // Cálculo de totalizadores
  const totalDistinctItems = items.length;
  const totalPiecesSent = items.reduce((acc, item) => acc + (Number(item.quantidade) || 0), 0);
  const totalPiecesChecked = items.reduce((acc, item) => acc + (Number(item.quantidadeConferida ?? item.quantidade) || 0), 0);
  const totalValue = items.reduce((acc, item) => acc + ((Number(item.quantidade) || 0) * (Number(item.valor) || 0)), 0);

  const isConferido = transfer.status === 'Conferido/Aprovado' || transfer.status === 'Aceito Parcialmente' || transfer.status === 'Rejeitado';

  return (
    <div className="romaneio-overlay" onClick={(e) => { if (e.target === e.currentTarget && onClose) onClose(); }}>
      <div className="romaneio-container glass">
        
        {/* Cabeçalho do Modal (Oculto na Impressão) */}
        <div className="romaneio-header no-print">
          <div className="romaneio-header-title">
            <div className="romaneio-icon-badge">
              <PackageCheck size={22} />
            </div>
            <div>
              <h3>Guia de Romaneio de Transferência</h3>
              <p>Lote #{transfer.id} • {getUnitName(transfer.origem)} para {getUnitName(transfer.destino)}</p>
            </div>
          </div>

          <div className="romaneio-header-actions">
            <button className="btn-secondary btn-print" onClick={handlePrint} title="Imprimir Guia A4 (Ctrl+P)">
              <Printer size={16} /> Imprimir A4
            </button>
            <button className="romaneio-btn-close" onClick={onClose} title="Fechar (ESC)">
              <X size={20} />
            </button>
          </div>
        </div>

        {/* Corpo do Modal com Folha A4 */}
        <div className="romaneio-body">
          <div className="romaneio-document-sheet romaneio-print-area">
            
            {/* Cabeçalho Oficial do Documento A4 */}
            <div className="romaneio-doc-header">
              <div className="romaneio-doc-brand">
                <div className="romaneio-brand-symbol">
                  <PackageCheck size={28} />
                </div>
                <div>
                  <h2>CENTRO DE DISTRIBUIÇÃO</h2>
                  <p>SISTEMA DE GESTÃO DE ESTOQUE UNIFICADO</p>
                </div>
              </div>
              <div className="romaneio-doc-meta">
                <div className="romaneio-doc-type">ROMANEIO DE CARGA</div>
                <div className="romaneio-doc-lot">LOTE #{transfer.id}</div>
                <div className="romaneio-doc-timestamp">Emissão: {formatDate(transfer.data || new Date().toISOString())}</div>
              </div>
            </div>

            <hr className="romaneio-doc-divider" />

            {/* Grid de Informações da Carga */}
            <div className="romaneio-info-grid">
              <div className="romaneio-info-card">
                <div className="romaneio-info-card-header">
                  <Truck size={15} /> REMETENTE (ORIGEM)
                </div>
                <div className="romaneio-info-highlight">{getUnitName(transfer.origem)}</div>
                <div className="romaneio-info-sub">Código Origem: #{transfer.origem}</div>
              </div>

              <div className="romaneio-info-card">
                <div className="romaneio-info-card-header">
                  <ShieldCheck size={15} /> DESTINATÁRIO (DESTINO)
                </div>
                <div className="romaneio-info-highlight">{getUnitName(transfer.destino)}</div>
                <div className="romaneio-info-sub">Código Destino: #{transfer.destino}</div>
              </div>

              <div className="romaneio-info-card">
                <div className="romaneio-info-card-header">
                  <FileText size={15} /> DETALHES FISCAIS / STATUS
                </div>
                <p><strong>Status:</strong> {transfer.status || 'Em Trânsito'}</p>
                <p><strong>Tipo:</strong> {transfer.tipoFiscal === 'NAO_FISCAL' ? 'Não Fiscal (Interno)' : 'Fiscal (Com NF-e)'}</p>
                {transfer.numeroNf && <p><strong>NF-e Nº:</strong> #{transfer.numeroNf}</p>}
                {transfer.chaveNfe && (
                  <p className="romaneio-info-sub" style={{ wordBreak: 'break-all', marginTop: '2px' }}>
                    <strong>Chave:</strong> {transfer.chaveNfe}
                  </p>
                )}
              </div>
            </div>

            {transfer.obs && (
              <div className="romaneio-obs-card">
                <strong>Observações Logísticas:</strong> {cleanName(transfer.obs)}
              </div>
            )}

            {/* Tabela de Produtos do Romaneio */}
            <div className="romaneio-table-wrap">
              <table className="romaneio-table">
                <thead>
                  <tr>
                    <th style={{ width: '45px', textAlign: 'center' }}>#</th>
                    <th style={{ width: '80px' }}>CÓDIGO</th>
                    <th>DESCRIÇÃO DO PRODUTO</th>
                    <th style={{ width: '110px', textAlign: 'center' }}>TAM / GRADE</th>
                    <th style={{ width: '90px', textAlign: 'center' }}>QTD ENVIADA</th>
                    <th style={{ width: '90px', textAlign: 'center' }}>QTD CONF.</th>
                    <th style={{ width: '110px', textAlign: 'right' }}>VALOR UNIT.</th>
                    <th style={{ width: '120px', textAlign: 'right' }}>SUBTOTAL</th>
                  </tr>
                </thead>
                <tbody>
                  {items.map((item, idx) => {
                    const prod = products.find(p => Number(p.codigo) === Number(item.produtoId || item.produto_id));
                    const prodName = cleanName(prod ? prod.nome : (item.nome || `Produto #${item.produtoId || item.produto_id}`));
                    const tam = resolveItemSize(item, prod);
                    const cor = item.cor && item.cor !== 'UNICA' ? item.cor : '';
                    const qtdEnviada = Number(item.quantidade) || 0;
                    const qtdConf = isConferido ? (Number(item.quantidadeConferida ?? item.quantidade) || 0) : qtdEnviada;
                    const valorUnit = Number(item.valor) || 0;
                    const subtotal = qtdEnviada * valorUnit;

                    return (
                      <tr key={item.id || idx}>
                        <td style={{ textAlign: 'center', color: '#64748b' }}>{idx + 1}</td>
                        <td><strong>#{item.produtoId || item.produto_id}</strong></td>
                        <td>
                          <span className="romaneio-item-name">{prodName}</span>
                          {item.justificativa && (
                            <div className="romaneio-item-note">Obs: {item.justificativa}</div>
                          )}
                        </td>
                        <td style={{ textAlign: 'center' }}>
                          <span className="romaneio-tag-size">
                            {tam}{cor ? ` • ${cor}` : ''}
                          </span>
                        </td>
                        <td style={{ textAlign: 'center', fontWeight: 700 }}>{qtdEnviada}</td>
                        <td style={{ textAlign: 'center' }}>{isConferido ? qtdConf : '-'}</td>
                        <td style={{ textAlign: 'right' }}>{formatCurrency(valorUnit)}</td>
                        <td style={{ textAlign: 'right', fontWeight: 700 }}>{formatCurrency(subtotal)}</td>
                      </tr>
                    );
                  })}

                  {items.length === 0 && (
                    <tr>
                      <td colSpan="8" className="romaneio-empty-message">
                        Nenhum item listado neste lote de transferência.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            {/* Resumo de Totalizadores */}
            <div className="romaneio-totals-bar">
              <div className="romaneio-total-cell">
                <span>Itens Distintos:</span>
                <strong>{totalDistinctItems}</strong>
              </div>
              <div className="romaneio-total-cell">
                <span>Total Peças Enviadas:</span>
                <strong>{totalPiecesSent} un</strong>
              </div>
              {isConferido && (
                <div className="romaneio-total-cell">
                  <span>Total Peças Conferidas:</span>
                  <strong>{totalPiecesChecked} un</strong>
                </div>
              )}
              <div className="romaneio-total-cell highlight">
                <span>Valor Total da Carga:</span>
                <strong>{formatCurrency(totalValue)}</strong>
              </div>
            </div>

            {/* Assinaturas / Conferência */}
            <div className="romaneio-signatures">
              <div className="romaneio-sig-block">
                <div className="romaneio-sig-line"></div>
                <p className="romaneio-sig-role">Expedição (Origem)</p>
                <p className="romaneio-sig-sub">{getUnitName(transfer.origem)}</p>
                <p className="romaneio-sig-sub">Data: ____/____/________</p>
              </div>

              <div className="romaneio-sig-block">
                <div className="romaneio-sig-line"></div>
                <p className="romaneio-sig-role">Transportador / Motorista</p>
                <p className="romaneio-sig-sub">Nome: _______________________</p>
                <p className="romaneio-sig-sub">Placa: _______________________</p>
              </div>

              <div className="romaneio-sig-block">
                <div className="romaneio-sig-line"></div>
                <p className="romaneio-sig-role">Conferência / Recebimento</p>
                <p className="romaneio-sig-sub">{getUnitName(transfer.destino)}</p>
                <p className="romaneio-sig-sub">Data: ____/____/________</p>
              </div>
            </div>

            {/* Nota de rodapé da página */}
            <div className="romaneio-doc-footer-note">
              Documento emitido via Dashboard Centro de Distribuição em {new Date().toLocaleString('pt-BR')}.
            </div>

          </div>
        </div>

        {/* Rodapé da Janela Modal */}
        <div className="romaneio-footer no-print">
          <div className="romaneio-shortcuts">
            <span className="romaneio-shortcut-item"><kbd>ESC</kbd> Fechar</span>
            <span className="romaneio-shortcut-item"><kbd>CTRL</kbd> + <kbd>P</kbd> Imprimir</span>
            <span className="romaneio-count-summary">
              Total de {totalDistinctItems} itens distintos ({totalPiecesSent} peças)
            </span>
          </div>

          <div className="romaneio-footer-actions">
            <button className="btn-secondary" onClick={handlePrint}>
              <Printer size={16} /> Imprimir
            </button>
            <button className="btn-romaneio-close" onClick={onClose}>
              Fechar
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}
