import React from 'react';
import { Printer, X, PackageCheck, Truck, ShieldCheck, FileText } from 'lucide-react';
import { formatDate, formatCurrency } from '../utils/formatters';
import './RomaneioModal.css';

export default function RomaneioModal({ transfer, items, products, units, onClose }) {
  if (!transfer) return null;

  const getUnitName = (unitId) => {
    if (!unitId) return 'N/A';
    const found = units.find(u => Number(u.id) === Number(unitId));
    return found ? found.name : `Unidade #${unitId}`;
  };

  const handlePrint = () => {
    window.print();
  };

  // Cálculo de totalizadores
  const totalDistinctItems = items.length;
  const totalPiecesSent = items.reduce((acc, item) => acc + (Number(item.quantidade) || 0), 0);
  const totalPiecesChecked = items.reduce((acc, item) => acc + (Number(item.quantidadeConferida ?? item.quantidade) || 0), 0);
  const totalValue = items.reduce((acc, item) => acc + ((Number(item.quantidade) || 0) * (Number(item.valor) || 0)), 0);

  const isConferido = transfer.status === 'Conferido/Aprovado' || transfer.status === 'Aceito Parcialmente' || transfer.status === 'Rejeitado';

  return (
    <div className="romaneio-overlay">
      <div className="romaneio-modal-container">
        {/* Barra de Ações (Oculta na Impressão) */}
        <div className="romaneio-action-bar no-print">
          <div className="romaneio-action-title">
            <Printer size={20} />
            <span>Guia de Romaneio de Transferência #{transfer.id}</span>
          </div>
          <div className="romaneio-action-buttons">
            <button className="romaneio-btn print-btn" onClick={handlePrint}>
              <Printer size={18} /> Imprimir / Salvar PDF
            </button>
            <button className="romaneio-btn close-btn" onClick={onClose}>
              <X size={18} /> Fechar
            </button>
          </div>
        </div>

        {/* Área de Impressão (Romaneio A4) */}
        <div className="romaneio-document-sheet romaneio-print-area">
          {/* Cabeçalho do Documento */}
          <div className="romaneio-header">
            <div className="romaneio-header-logo">
              <div className="romaneio-brand-badge">
                <PackageCheck size={28} />
                <div>
                  <h2>CENTRO DE DISTRIBUIÇÃO</h2>
                  <p>SISTEMA DE GESTÃO DE ESTOQUE UNIFICADO</p>
                </div>
              </div>
            </div>
            <div className="romaneio-header-meta">
              <div className="romaneio-doc-title">ROMANEIO DE TRANSFERÊNCIA</div>
              <div className="romaneio-doc-number">LOTE #{transfer.id}</div>
              <div className="romaneio-doc-date">Emissão: {formatDate(transfer.data || new Date().toISOString())}</div>
            </div>
          </div>

          <hr className="romaneio-divider" />

          {/* Dados Gerais da Transferência */}
          <div className="romaneio-info-grid">
            <div className="romaneio-info-box">
              <h4><Truck size={16} /> REMETENTE (ORIGEM)</h4>
              <p className="romaneio-info-highlight">{getUnitName(transfer.origem)}</p>
              <p className="romaneio-info-sub">Código Origem: #{transfer.origem}</p>
            </div>

            <div className="romaneio-info-box">
              <h4><ShieldCheck size={16} /> DESTINATÁRIO (DESTINO)</h4>
              <p className="romaneio-info-highlight">{getUnitName(transfer.destino)}</p>
              <p className="romaneio-info-sub">Código Destino: #{transfer.destino}</p>
            </div>

            <div className="romaneio-info-box">
              <h4><FileText size={16} /> DETALHES FISCAIS / STATUS</h4>
              <p><strong>Status:</strong> {transfer.status || 'Em Trânsito'}</p>
              <p><strong>Tipo:</strong> {transfer.tipoFiscal === 'NAO_FISCAL' ? '📦 Não Fiscal (Interna)' : '📄 Fiscal (Com NF-e)'}</p>
              {transfer.numeroNf && <p><strong>NF-e Nº:</strong> #{transfer.numeroNf}</p>}
              {transfer.chaveNfe && <p className="romaneio-info-sub" style={{ wordBreak: 'break-all' }}><strong>Chave NFe:</strong> {transfer.chaveNfe}</p>}
            </div>
          </div>

          {transfer.obs && (
            <div className="romaneio-obs-box">
              <strong>Observações Logísticas:</strong> {transfer.obs}
            </div>
          )}

          {/* Tabela de Produtos / Itens do Lote */}
          <div className="romaneio-table-container">
            <table className="romaneio-table">
              <thead>
                <tr>
                  <th style={{ width: '60px' }}>Item</th>
                  <th style={{ width: '100px' }}>Código</th>
                  <th>Descrição do Produto</th>
                  <th style={{ width: '90px', textAlign: 'center' }}>Qtd Enviada</th>
                  <th style={{ width: '90px', textAlign: 'center' }}>Qtd Conf.</th>
                  <th style={{ width: '110px', textAlign: 'right' }}>Valor Unit.</th>
                  <th style={{ width: '120px', textAlign: 'right' }}>Subtotal</th>
                </tr>
              </thead>
              <tbody>
                {items.map((item, idx) => {
                  const prod = products.find(p => p.codigo === item.produtoId);
                  const prodName = prod ? prod.nome : (item.nome || `Produto #${item.produtoId}`);
                  const qtdEnviada = Number(item.quantidade) || 0;
                  const qtdConf = isConferido ? (Number(item.quantidadeConferida ?? item.quantidade) || 0) : qtdEnviada;
                  const valorUnit = Number(item.valor) || 0;
                  const subtotal = qtdEnviada * valorUnit;

                  return (
                    <tr key={item.id || idx}>
                      <td style={{ textAlign: 'center' }}>#{idx + 1}</td>
                      <td><strong>#{item.produtoId}</strong></td>
                      <td>
                        {prodName}
                        {item.justificativa && (
                          <div className="romaneio-item-obs">Obs: {item.justificativa}</div>
                        )}
                      </td>
                      <td style={{ textAlign: 'center', fontWeight: 'bold' }}>{qtdEnviada}</td>
                      <td style={{ textAlign: 'center' }}>{isConferido ? qtdConf : '-'}</td>
                      <td style={{ textAlign: 'right' }}>{formatCurrency(valorUnit)}</td>
                      <td style={{ textAlign: 'right', fontWeight: 'bold' }}>{formatCurrency(subtotal)}</td>
                    </tr>
                  );
                })}

                {items.length === 0 && (
                  <tr>
                    <td colSpan="7" style={{ textAlign: 'center', padding: '1.5rem' }}>
                      Nenhum item listado neste lote.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          {/* Resumo de Totalizadores */}
          <div className="romaneio-totals-bar">
            <div className="romaneio-total-item">
              <span>Itens Distintos:</span>
              <strong>{totalDistinctItems}</strong>
            </div>
            <div className="romaneio-total-item">
              <span>Total Peças Enviadas:</span>
              <strong>{totalPiecesSent} un</strong>
            </div>
            {isConferido && (
              <div className="romaneio-total-item">
                <span>Total Peças Conferidas:</span>
                <strong>{totalPiecesChecked} un</strong>
              </div>
            )}
            <div className="romaneio-total-item highlight">
              <span>Valor Total da Carga:</span>
              <strong>{formatCurrency(totalValue)}</strong>
            </div>
          </div>

          {/* Bloco de Assinaturas e Conferência Física */}
          <div className="romaneio-signatures-container">
            <div className="romaneio-signature-box">
              <div className="romaneio-signature-line"></div>
              <p className="romaneio-signature-title">Expedição (Origem)</p>
              <p className="romaneio-signature-sub">{getUnitName(transfer.origem)}</p>
              <p className="romaneio-signature-sub">Data: ____/____/________</p>
            </div>

            <div className="romaneio-signature-box">
              <div className="romaneio-signature-line"></div>
              <p className="romaneio-signature-title">Transportador / Motorista</p>
              <p className="romaneio-signature-sub">Nome: _______________________</p>
              <p className="romaneio-signature-sub">Placa: _______________________</p>
            </div>

            <div className="romaneio-signature-box">
              <div className="romaneio-signature-line"></div>
              <p className="romaneio-signature-title">Conferência / Recebimento</p>
              <p className="romaneio-signature-sub">{getUnitName(transfer.destino)}</p>
              <p className="romaneio-signature-sub">Data: ____/____/________</p>
            </div>
          </div>

          {/* Rodapé do Documento */}
          <div className="romaneio-footer-note">
            Documento emitido via Dashboard Centro de Distribuição em {new Date().toLocaleString('pt-BR')}.
          </div>
        </div>
      </div>
    </div>
  );
}
