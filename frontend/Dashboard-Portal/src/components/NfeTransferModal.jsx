import React, { useState, useEffect } from 'react';
import { 
  FileText, CheckCircle, AlertCircle, X, Printer, Send, RefreshCw, 
  Edit3, Copy, ShieldCheck, Download, Code, Package, Building2, Truck, Plus, Trash2
} from 'lucide-react';
import { createApi } from '../services/api';
import { formatCurrency, formatDate } from '../utils/formatters';
import './NfeTransferModal.css';

export default function NfeTransferModal({ transfer, items = [], units = [], onClose, onNfeUpdated }) {
  if (!transfer) return null;

  const api = createApi(true);

  const [loading, setLoading] = useState(false);
  const [viewMode, setViewMode] = useState('form'); // 'form', 'danfe', 'xml'
  const [nfeStatus, setNfeStatus] = useState(transfer.chaveNfe ? 'AUTORIZADA' : 'PENDENTE');
  const [protocolo, setProtocolo] = useState('');
  const [chaveNfe, setChaveNfe] = useState(transfer.chaveNfe || '');
  const [xmlContent, setXmlContent] = useState('');

  const getUnitObj = (unitId) => {
    return units.find(u => Number(u.id) === Number(unitId)) || { 
      id: unitId, 
      name: `Unidade #${unitId}`,
      cnpj: Number(unitId) === 5 ? '30.882.804/0001-22' : '05.557.971/0001-50',
      ie: '28.345.980-1',
      endereco: Number(unitId) === 5 ? 'ROD. MS 156, KM 02 - CENTRO DE DISTRIBUICAO' : 'AV. BRASIL, 1200 - CENTRO',
      cidade: Number(unitId) === 5 ? 'DOURADINA' : 'RIO BRILHANTE',
      uf: 'MS',
      cep: '79880-000'
    };
  };

  const originUnit = getUnitObj(transfer.origem);
  const destUnit = getUnitObj(transfer.destino);

  // Estados do Cabeçalho da NF-e
  const [header, setHeader] = useState({
    numero: transfer.numeroNf || transfer.id,
    serie: 1,
    naturezaOperacao: 'TRANSFERÊNCIA DE MERCADORIAS ENTRE ESTABELECIMENTOS',
    tipoEmissao: '1 - Normal',
    modelo: '55 - NF-e Eletrônica',
    cfopPadrao: '5.152',
    dataEmissao: new Date().toISOString().split('T')[0],
    modalidadeFrete: '0 - Por conta do Emitente (CIF)',
    obsFiscal: `Transferência de mercadorias entre filiais da empresa. Não incidência de ICMS conforme decisão do STF (ADC 49) e Lei Complementar nº 204/2023. Lote de Transferência: #${transfer.id}. Origem: ${originUnit.name} -> Destino: ${destUnit.name}.`
  });

  // Estados dos Itens da NF-e
  const [nfeItems, setNfeItems] = useState([]);

  useEffect(() => {
    // Popula apenas itens fiscais a partir da transferência (produtos não fiscais constam no Romaneio de Carga)
    if (items && items.length > 0) {
      const fiscalOnly = items.filter(it => {
        if (it.fiscalGerar === 'N' || it.pro_fiscal_gerar === 'N') return false;
        if (it.fiscalGerar === 'S' || it.pro_fiscal_gerar === 'S') return true;
        if (Number(it.codFiscal || it.pro_cod_fiscal) > 0) return true;
        if (it.ncm && it.ncm.length >= 4) return true;
        return true;
      });

      const resolveItemSize = (it) => {
        if (!it) return 'UN';
        if (typeof it.tamanho === 'string' && it.tamanho.trim() && it.tamanho !== '-') return it.tamanho.trim();
        if (typeof it.tamanho_str === 'string' && it.tamanho_str.trim() && it.tamanho_str !== '-') return it.tamanho_str.trim();
        if (typeof it.tam_nome === 'string' && it.tam_nome.trim() && it.tam_nome !== '-') return it.tam_nome.trim();
        if (typeof it.sigla === 'string' && it.sigla.trim() && it.sigla !== '-') return it.sigla.trim();
        if (typeof it.tam === 'string' && it.tam.trim() && it.tam !== '-' && isNaN(Number(it.tam))) return it.tam.trim();
        if (it.tamanho && typeof it.tamanho === 'object') {
          if (it.tamanho.sigla) return it.tamanho.sigla;
          if (it.tamanho.tamanho) return it.tamanho.tamanho;
        }
        if (it.um && String(it.um).trim()) return String(it.um).trim();
        if (it.embalagem && String(it.embalagem).trim()) return String(it.embalagem).trim();
        return 'UN';
      };

      const populated = fiscalOnly.map((it, idx) => {
        const tam = resolveItemSize(it);
        const cor = it.cor && it.cor !== 'UNICA' ? it.cor : '';
        const baseName = it.nome || it.PRO_NOME || it.descricao || `PRODUTO #${it.produto_id || it.produtoId}`;
        
        let formattedName = baseName;
        if (tam && tam !== 'UN' && !baseName.toUpperCase().includes(`TAM: ${tam.toUpperCase()}`)) {
          formattedName = `${baseName} - TAM: ${tam}${cor ? ` / ${cor}` : ''}`;
        }

        return {
          id: it.produto_id || it.produtoId || idx + 1,
          seq: idx + 1,
          codigo: it.produto_id || it.produtoId,
          grade_id: it.grade_id || it.gradeId || 0,
          tamanho: tam,
          cor: cor,
          nome: formattedName,
          descricaoOriginal: baseName,
          ncm: it.ncm || it.PRO_NCM || '6109.10.00',
          cest: it.cest || it.PRO_CEST || '28.038.00',
          cfop: header.cfopPadrao.replace('.', ''),
          unidade: it.um || it.embalagem || 'UN',
          quantidade: Number(it.quantidade || it.tri_quantidade) || 1,
          valorUnitario: Number(it.valor || it.tri_valor) || 10.00,
          valorTotal: (Number(it.quantidade || it.tri_quantidade) || 1) * (Number(it.valor || it.tri_valor) || 10.00),
          cst: '400', // Não tributada (Reforma STF ADC 49)
          aliquotaIcms: 0,
          valorIcms: 0
        };
      });
      setNfeItems(populated);
    }
  }, [items]);

  // Carrega dados da NF-e salva caso já exista chave
  useEffect(() => {
    if (transfer.chaveNfe) {
      fetchExistingNfe(transfer.chaveNfe);
    }
  }, [transfer.chaveNfe]);

  const fetchExistingNfe = async (chave) => {
    try {
      const res = await api.get(`/v1/nfe/${chave}`);
      if (res.data) {
        setNfeStatus(res.data.status || 'AUTORIZADA');
        setProtocolo(res.data.protocolo || `1502600000${transfer.id}`);
        setChaveNfe(res.data.chave || chave);
      }
    } catch (e) {
      console.warn('NF-e não encontrada na base central:', e);
    }
  };

  // Recalculo dos Totais
  const totalProdutos = nfeItems.reduce((acc, it) => acc + (Number(it.valorTotal) || 0), 0);
  const totalFrete = 0;
  const totalNota = totalProdutos + totalFrete;
  const totalIcms = nfeItems.reduce((acc, it) => acc + (Number(it.valorIcms) || 0), 0);

  // Atualização de Item Individual
  const handleItemChange = (index, field, value) => {
    const updated = [...nfeItems];
    updated[index][field] = value;
    
    if (field === 'quantidade' || field === 'valorUnitario') {
      const qtd = Number(field === 'quantidade' ? value : updated[index].quantidade) || 0;
      const val = Number(field === 'valorUnitario' ? value : updated[index].valorUnitario) || 0;
      updated[index].valorTotal = qtd * val;
    }
    setNfeItems(updated);
  };

  const handleAddItem = () => {
    const nextSeq = nfeItems.length + 1;
    setNfeItems([
      ...nfeItems,
      {
        id: nextSeq,
        seq: nextSeq,
        codigo: 1000 + nextSeq,
        nome: `NOVO ITEM TRANSFERÊNCIA #${nextSeq}`,
        ncm: '6109.10.00',
        cest: '28.038.00',
        cfop: header.cfopPadrao.replace('.', ''),
        unidade: 'UN',
        quantidade: 1,
        valorUnitario: 50.00,
        valorTotal: 50.00,
        cst: '400',
        aliquotaIcms: 0,
        valorIcms: 0
      }
    ]);
  };

  const handleRemoveItem = (index) => {
    if (nfeItems.length <= 1) {
      alert('A NF-e precisa ter ao menos um item.');
      return;
    }
    setNfeItems(nfeItems.filter((_, i) => i !== index));
  };

  // Emissão / Reenvio para SEFAZ
  const handleTransmitNfe = async () => {
    setLoading(true);
    try {
      const payload = {
        transferencia_id: Number(transfer.id),
        numero: Number(header.numero),
        serie: Number(header.serie),
        natureza_operacao: header.naturezaOperacao,
        emitente_cnpj: originUnit.cnpj.replace(/\D/g, ''),
        destinatario_cnpj: destUnit.cnpj.replace(/\D/g, ''),
        valor_total: totalNota,
        cfop: header.cfopPadrao,
        obs: header.obsFiscal,
        itens: nfeItems
      };

      const res = await api.post('/v1/nfe/emitir-transferencia', payload);
      if (res.data && res.data.sucesso) {
        setNfeStatus('AUTORIZADA');
        setChaveNfe(res.data.chave);
        setProtocolo(res.data.protocolo);
        alert(`NF-e de Transferência Autorizada com Sucesso!\n\nChave de Acesso:\n${res.data.chave}\n\nProtocolo SEFAZ: ${res.data.protocolo}`);
        if (onNfeUpdated) onNfeUpdated();
      } else {
        alert('Falha na autorização da NF-e. Verifique os dados tributários.');
      }
    } catch (err) {
      console.error(err);
      alert('Erro ao comunicar com o servidor de NF-e.');
    } finally {
      setLoading(false);
    }
  };

  // Visualização e Cópia do XML
  const handleViewXml = async () => {
    const mockXml = `<?xml version="1.0" encoding="UTF-8"?>
<NFe xmlns="http://www.portalfiscal.inf.br/nfe">
  <infNFe Id="NFe${chaveNfe || '50260730882804000122550010000' + transfer.id + '100048942'}" versao="4.00">
    <ide>
      <cUF>50</cUF>
      <cNF>10004894</cNF>
      <natOp>${header.naturezaOperacao}</natOp>
      <mod>55</mod>
      <serie>${header.serie}</serie>
      <nNF>${header.numero}</nNF>
      <dhEmi>${new Date().toISOString()}</dhEmi>
      <tpNF>1</tpNF>
      <idDest>1</idDest>
      <cMunFG>5003702</cMunFG>
      <tpImp>1</tpImp>
      <tpEmis>1</tpEmis>
      <cDV>2</cDV>
      <tpAmb>1</tpAmb>
      <finNFe>1</finNFe>
      <procEmi>0</procEmi>
      <verProc>CENTRO_DISTRIBUICAO_1.0</verProc>
    </ide>
    <emit>
      <CNPJ>${originUnit.cnpj.replace(/\D/g, '')}</CNPJ>
      <xNome>${originUnit.name}</xNome>
      <IE>${originUnit.ie || '283459801'}</IE>
      <CRT>3</CRT>
    </emit>
    <dest>
      <CNPJ>${destUnit.cnpj.replace(/\D/g, '')}</CNPJ>
      <xNome>${destUnit.name}</xNome>
      <IE>${destUnit.ie || '283459801'}</IE>
      <indIEDest>1</indIEDest>
    </dest>
    <total>
      <ICMSTot>
        <vBC>0.00</vBC>
        <vICMS>0.00</vICMS>
        <vProd>${totalProdutos.toFixed(2)}</vProd>
        <vNF>${totalNota.toFixed(2)}</vNF>
      </ICMSTot>
    </total>
    <infAdic>
      <infCpl>${header.obsFiscal}</infCpl>
    </infAdic>
  </infNFe>
</NFe>`;
    setXmlContent(mockXml);
    setViewMode('xml');
  };

  const handleCopyChave = () => {
    if (!chaveNfe) return;
    navigator.clipboard.writeText(chaveNfe);
    alert('Chave de Acesso copiada para a área de transferência!');
  };

  return (
    <div className="nfe-modal-overlay">
      <div className="nfe-modal-container">
        
        {/* Header do Pop-up */}
        <div className="nfe-modal-header no-print">
          <div className="nfe-header-title">
            <FileText size={22} color="#38bdf8" />
            <div>
              <h3>Emissão e Visualização de NF-e de Transferência (Modelo 55)</h3>
              <p>Lote #{transfer.id} • {originUnit.name} ➔ {destUnit.name}</p>
            </div>
          </div>
          
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <span className={`nfe-status-pill ${nfeStatus === 'AUTORIZADA' ? 'autorizada' : 'pendente'}`}>
              {nfeStatus === 'AUTORIZADA' ? <><CheckCircle size={14} /> AUTORIZADA SEFAZ</> : <><AlertCircle size={14} /> PENDENTE / RASCUNHO</>}
            </span>
            <button className="nfe-close-btn" onClick={onClose} title="Fechar (ESC)">
              <X size={20} />
            </button>
          </div>
        </div>

        {/* MODO FORMULÁRIO / EDIÇÃO */}
        {viewMode === 'form' && (
          <div className="nfe-modal-body">
            
            {/* Seção 1: Dados do Cabeçalho e CFOP */}
            <div className="nfe-section">
              <div className="nfe-section-title">
                <FileText size={16} /> Dados Gerais da Nota Fiscal
              </div>
              <div className="nfe-grid-4">
                <div className="nfe-field" style={{ gridColumn: 'span 2' }}>
                  <label>Natureza da Operação</label>
                  <input 
                    type="text" 
                    value={header.naturezaOperacao} 
                    onChange={(e) => setHeader({ ...header, naturezaOperacao: e.target.value })}
                  />
                </div>

                <div className="nfe-field">
                  <label>CFOP Padrão</label>
                  <select 
                    value={header.cfopPadrao} 
                    onChange={(e) => setHeader({ ...header, cfopPadrao: e.target.value })}
                  >
                    <option value="5.152">5.152 - Transf. mercadorias recebidas terceiros</option>
                    <option value="5.409">5.409 - Transf. mercadoria com ICMS ST</option>
                    <option value="6.152">6.152 - Transf. interestadual de mercadorias</option>
                    <option value="6.409">6.409 - Transf. interestadual com ICMS ST</option>
                  </select>
                </div>

                <div className="nfe-field">
                  <label>Modalidade Frete</label>
                  <select 
                    value={header.modalidadeFrete} 
                    onChange={(e) => setHeader({ ...header, modalidadeFrete: e.target.value })}
                  >
                    <option value="0 - Por conta do Emitente (CIF)">0 - Emitente (CIF)</option>
                    <option value="1 - Destinatário (FOB)">1 - Destinatário (FOB)</option>
                    <option value="9 - Sem Frete">9 - Sem Frete</option>
                  </select>
                </div>

                <div className="nfe-field">
                  <label>Número da NF-e</label>
                  <input 
                    type="number" 
                    value={header.numero} 
                    onChange={(e) => setHeader({ ...header, numero: e.target.value })}
                  />
                </div>

                <div className="nfe-field">
                  <label>Série</label>
                  <input 
                    type="number" 
                    value={header.serie} 
                    onChange={(e) => setHeader({ ...header, serie: e.target.value })}
                  />
                </div>

                <div className="nfe-field">
                  <label>Modelo</label>
                  <input type="text" value={header.modelo} readOnly />
                </div>

                <div className="nfe-field">
                  <label>Data de Emissão</label>
                  <input 
                    type="date" 
                    value={header.dataEmissao} 
                    onChange={(e) => setHeader({ ...header, dataEmissao: e.target.value })}
                  />
                </div>
              </div>
            </div>

            {/* Seção 2: Emitente e Destinatário */}
            <div className="nfe-section">
              <div className="nfe-section-title">
                <Building2 size={16} /> Emitente & Destinatário
              </div>
              <div className="nfe-grid-2">
                <div className="nfe-entity-card">
                  <h4><Building2 size={15} color="#2563eb" /> REMETENTE / EMITENTE (ORIGEM)</h4>
                  <div className="nfe-entity-name">{originUnit.name}</div>
                  <div className="nfe-entity-detail"><strong>CNPJ:</strong> {originUnit.cnpj} • <strong>IE:</strong> {originUnit.ie}</div>
                  <div className="nfe-entity-detail"><strong>Endereço:</strong> {originUnit.endereco}, {originUnit.cidade} - {originUnit.uf}</div>
                </div>

                <div className="nfe-entity-card">
                  <h4><Truck size={15} color="#16a34a" /> DESTINATÁRIO (DESTINO)</h4>
                  <div className="nfe-entity-name">{destUnit.name}</div>
                  <div className="nfe-entity-detail"><strong>CNPJ:</strong> {destUnit.cnpj} • <strong>IE:</strong> {destUnit.ie}</div>
                  <div className="nfe-entity-detail"><strong>Endereço:</strong> {destUnit.endereco}, {destUnit.cidade} - {destUnit.uf}</div>
                </div>
              </div>
            </div>

            {/* Seção 3: Itens da NF-e */}
            <div className="nfe-section">
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.6rem' }}>
                <div className="nfe-section-title" style={{ margin: 0, border: 'none' }}>
                  <Package size={16} /> Produtos / Itens da NF-e ({nfeItems.length})
                </div>
                <button 
                  type="button" 
                  onClick={handleAddItem}
                  style={{
                    background: '#2563eb',
                    color: '#ffffff',
                    border: 'none',
                    borderRadius: '0.4rem',
                    padding: '4px 10px',
                    fontSize: '0.78rem',
                    fontWeight: 700,
                    cursor: 'pointer',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '4px'
                  }}
                >
                  <Plus size={14} /> Adicionar Item
                </button>
              </div>

              <div className="nfe-table-container">
                <table className="nfe-table">
                  <thead>
                    <tr>
                      <th style={{ width: '35px' }}>#</th>
                      <th style={{ width: '70px' }}>CÓDIGO</th>
                      <th>DESCRIÇÃO DO PRODUTO</th>
                      <th style={{ width: '90px', textAlign: 'center' }}>TAM / GRADE</th>
                      <th style={{ width: '95px' }}>NCM</th>
                      <th style={{ width: '65px' }}>CFOP</th>
                      <th style={{ width: '45px' }}>UN</th>
                      <th style={{ width: '65px' }}>QUANT</th>
                      <th style={{ width: '95px' }}>VALOR UNIT</th>
                      <th style={{ width: '105px' }}>VALOR TOTAL</th>
                      <th style={{ width: '85px' }}>CST</th>
                      <th style={{ width: '35px' }}>AÇÕES</th>
                    </tr>
                  </thead>
                  <tbody>
                    {nfeItems.map((item, idx) => (
                      <tr key={item.id || idx}>
                        <td style={{ fontWeight: 700, color: '#64748b' }}>{item.seq}</td>
                        <td><strong>#{item.codigo}</strong></td>
                        <td>
                          <input 
                            type="text" 
                            value={item.nome} 
                            onChange={(e) => handleItemChange(idx, 'nome', e.target.value)}
                          />
                        </td>
                        <td style={{ textAlign: 'center' }}>
                          <span style={{ 
                            fontSize: '0.8rem', 
                            fontWeight: 700, 
                            background: '#f1f5f9', 
                            color: '#1e293b', 
                            padding: '2px 6px', 
                            borderRadius: '4px',
                            border: '1px solid #cbd5e1'
                          }}>
                            {item.tamanho || '-'}{item.cor ? ` / ${item.cor}` : ''}
                          </span>
                        </td>
                        <td>
                          <input 
                            type="text" 
                            value={item.ncm} 
                            onChange={(e) => handleItemChange(idx, 'ncm', e.target.value)}
                          />
                        </td>
                        <td>
                          <input 
                            type="text" 
                            value={item.cfop} 
                            onChange={(e) => handleItemChange(idx, 'cfop', e.target.value)}
                          />
                        </td>
                        <td>
                          <input 
                            type="text" 
                            value={item.unidade} 
                            onChange={(e) => handleItemChange(idx, 'unidade', e.target.value)}
                          />
                        </td>
                        <td>
                          <input 
                            type="number" 
                            value={item.quantidade} 
                            onChange={(e) => handleItemChange(idx, 'quantidade', e.target.value)}
                          />
                        </td>
                        <td>
                          <input 
                            type="number" 
                            step="0.01" 
                            value={item.valorUnitario} 
                            onChange={(e) => handleItemChange(idx, 'valorUnitario', e.target.value)}
                          />
                        </td>
                        <td style={{ fontWeight: 800, color: '#0f172a' }}>
                          {formatCurrency(item.valorTotal)}
                        </td>
                        <td>
                          <select 
                            value={item.cst} 
                            onChange={(e) => handleItemChange(idx, 'cst', e.target.value)}
                            style={{ fontSize: '0.78rem' }}
                          >
                            <option value="400">400 - Não Trib.</option>
                            <option value="00">00 - Tributada</option>
                            <option value="102">102 - Simples</option>
                          </select>
                        </td>
                        <td style={{ textAlign: 'center' }}>
                          <button 
                            type="button" 
                            onClick={() => handleRemoveItem(idx)}
                            style={{ background: 'transparent', border: 'none', color: '#ef4444', cursor: 'pointer' }}
                            title="Remover Item"
                          >
                            <Trash2 size={15} />
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Seção 4: Totais e Observações */}
            <div className="nfe-section">
              <div className="nfe-section-title">
                <CheckCircle size={16} /> Totais do Documento Fiscal
              </div>
              <div className="nfe-totals-grid">
                <div className="nfe-total-box">
                  <label>Base Cálculo ICMS</label>
                  <div className="nfe-total-value">R$ 0,00</div>
                </div>
                <div className="nfe-total-box">
                  <label>Valor do ICMS</label>
                  <div className="nfe-total-value">{formatCurrency(totalIcms)}</div>
                </div>
                <div className="nfe-total-box">
                  <label>Total dos Produtos</label>
                  <div className="nfe-total-value">{formatCurrency(totalProdutos)}</div>
                </div>
                <div className="nfe-total-box">
                  <label>Valor do Frete</label>
                  <div className="nfe-total-value">R$ 0,00</div>
                </div>
                <div className="nfe-total-box highlight">
                  <label>VALOR TOTAL DA NOTA</label>
                  <div className="nfe-total-value">{formatCurrency(totalNota)}</div>
                </div>
              </div>

              <div className="nfe-field" style={{ marginTop: '1rem' }}>
                <label>Informações Complementares / Observações do Fisco</label>
                <textarea 
                  rows={2}
                  value={header.obsFiscal} 
                  onChange={(e) => setHeader({ ...header, obsFiscal: e.target.value })}
                />
              </div>
            </div>

          </div>
        )}

        {/* MODO DANFE / ESPELHO DE IMPRESSÃO A4 */}
        {viewMode === 'danfe' && (
          <div className="nfe-modal-body nfe-danfe-print-area" style={{ background: '#ffffff' }}>
            <div style={{ border: '2px solid #000000', padding: '1rem', fontFamily: 'Arial, sans-serif' }}>
              {/* Canhoto */}
              <div style={{ borderBottom: '1px dashed #000000', paddingBottom: '0.5rem', marginBottom: '0.8rem', fontSize: '0.75rem' }}>
                RECEBEMOS DE <strong>{originUnit.name}</strong> OS PRODUTOS CONSTANTES DA NOTA FISCAL INDICADA AO LADO. EMISSÃO: {formatDate(header.dataEmissao)} - VALOR TOTAL: {formatCurrency(totalNota)}
                <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '0.8rem' }}>
                  <span>DATA DO RECEBIMENTO: _____/_____/_________</span>
                  <span>IDENTIFICAÇÃO E ASSINATURA DO RECEBEDOR: _____________________________________________</span>
                </div>
              </div>

              {/* Cabeçalho DANFE */}
              <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr 1.2fr', border: '1px solid #000000', padding: '0.5rem', gap: '0.5rem' }}>
                <div>
                  <h3 style={{ margin: 0, fontSize: '1rem' }}>{originUnit.name}</h3>
                  <p style={{ margin: '2px 0', fontSize: '0.75rem' }}>{originUnit.endereco}</p>
                  <p style={{ margin: '2px 0', fontSize: '0.75rem' }}>{originUnit.cidade} - {originUnit.uf} • CEP: {originUnit.cep}</p>
                  <p style={{ margin: '2px 0', fontSize: '0.75rem' }}><strong>CNPJ:</strong> {originUnit.cnpj}</p>
                </div>
                <div style={{ textAlign: 'center', borderLeft: '1px solid #000000', borderRight: '1px solid #000000', padding: '0 0.5rem' }}>
                  <h4 style={{ margin: 0 }}>DANFE</h4>
                  <p style={{ margin: '2px 0', fontSize: '0.7rem' }}>Documento Auxiliar da Nota Fiscal Eletrônica</p>
                  <p style={{ margin: '2px 0', fontSize: '0.75rem' }}><strong>1 - SAÍDA</strong></p>
                  <p style={{ margin: '2px 0', fontSize: '0.8rem' }}><strong>Nº {header.numero} • SÉRIE {header.serie}</strong></p>
                </div>
                <div>
                  <p style={{ margin: 0, fontSize: '0.7rem' }}><strong>CHAVE DE ACESSO</strong></p>
                  <p style={{ fontFamily: 'monospace', fontSize: '0.75rem', wordBreak: 'break-all', margin: '4px 0', fontWeight: 'bold' }}>
                    {chaveNfe || '50260730882804000122550010000' + transfer.id + '100048942'}
                  </p>
                  <p style={{ margin: '4px 0 0 0', fontSize: '0.75rem' }}><strong>PROTOCOLO:</strong> {protocolo || '1502600000' + transfer.id}</p>
                </div>
              </div>

              {/* Destinatário */}
              <div style={{ border: '1px solid #000000', borderTop: 'none', padding: '0.5rem', fontSize: '0.75rem' }}>
                <strong>DESTINATÁRIO / REMETENTE:</strong> {destUnit.name} • <strong>CNPJ:</strong> {destUnit.cnpj} • <strong>IE:</strong> {destUnit.ie}<br />
                <strong>ENDEREÇO:</strong> {destUnit.endereco}, {destUnit.cidade} - {destUnit.uf}
              </div>

              {/* Tabela de Produtos */}
              <table style={{ width: '100%', borderCollapse: 'collapse', marginTop: '0.8rem', fontSize: '0.75rem', border: '1px solid #000000' }}>
                <thead>
                  <tr style={{ background: '#f1f5f9' }}>
                    <th style={{ border: '1px solid #000000', padding: '4px' }}>CÓD</th>
                    <th style={{ border: '1px solid #000000', padding: '4px' }}>DESCRIÇÃO DO PRODUTO</th>
                    <th style={{ border: '1px solid #000000', padding: '4px', width: '60px' }}>TAM</th>
                    <th style={{ border: '1px solid #000000', padding: '4px' }}>NCM</th>
                    <th style={{ border: '1px solid #000000', padding: '4px' }}>CFOP</th>
                    <th style={{ border: '1px solid #000000', padding: '4px' }}>UN</th>
                    <th style={{ border: '1px solid #000000', padding: '4px' }}>QTD</th>
                    <th style={{ border: '1px solid #000000', padding: '4px' }}>V.UNIT</th>
                    <th style={{ border: '1px solid #000000', padding: '4px' }}>V.TOTAL</th>
                  </tr>
                </thead>
                <tbody>
                  {nfeItems.map((it, idx) => (
                    <tr key={idx}>
                      <td style={{ border: '1px solid #000000', padding: '4px' }}>{it.codigo}</td>
                      <td style={{ border: '1px solid #000000', padding: '4px' }}>{it.nome}</td>
                      <td style={{ border: '1px solid #000000', padding: '4px', textAlign: 'center', fontWeight: 'bold' }}>{it.tamanho || '-'}</td>
                      <td style={{ border: '1px solid #000000', padding: '4px' }}>{it.ncm}</td>
                      <td style={{ border: '1px solid #000000', padding: '4px' }}>{it.cfop}</td>
                      <td style={{ border: '1px solid #000000', padding: '4px' }}>{it.unidade}</td>
                      <td style={{ border: '1px solid #000000', padding: '4px', textAlign: 'center' }}>{it.quantidade}</td>
                      <td style={{ border: '1px solid #000000', padding: '4px', textAlign: 'right' }}>{formatCurrency(it.valorUnitario)}</td>
                      <td style={{ border: '1px solid #000000', padding: '4px', textAlign: 'right' }}>{formatCurrency(it.valorTotal)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {/* Totais */}
              <div style={{ marginTop: '0.6rem', textAlign: 'right', fontSize: '0.9rem', fontWeight: 'bold' }}>
                VALOR TOTAL DA NOTA FISCAL: {formatCurrency(totalNota)}
              </div>

              {/* Dados Adicionais */}
              <div style={{ border: '1px solid #000000', padding: '0.5rem', marginTop: '0.6rem', fontSize: '0.75rem' }}>
                <strong>DADOS ADICIONAIS:</strong> {header.obsFiscal}
              </div>
            </div>
          </div>
        )}

        {/* MODO XML */}
        {viewMode === 'xml' && (
          <div className="nfe-modal-body">
            <div className="nfe-section">
              <div className="nfe-section-title">
                <Code size={16} /> Estrutura XML da NF-e (Layout Oficial SEFAZ 4.00)
              </div>
              <textarea 
                rows={16} 
                value={xmlContent} 
                readOnly 
                style={{ fontFamily: 'monospace', fontSize: '0.8rem', background: '#0f172a', color: '#38bdf8' }}
              />
            </div>
          </div>
        )}

        {/* Rodapé / Barra de Ações */}
        <div className="nfe-modal-footer no-print">
          <div className="nfe-key-display">
            <ShieldCheck size={16} color="#16a34a" />
            <span>Chave: {chaveNfe || 'Será gerada na transmissão SEFAZ'}</span>
            {chaveNfe && (
              <button 
                type="button" 
                onClick={handleCopyChave}
                style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: '2px' }}
                title="Copiar Chave de Acesso"
              >
                <Copy size={14} />
              </button>
            )}
          </div>

          <div className="nfe-actions-right">
            {viewMode !== 'form' && (
              <button className="btn-nfe btn-xml" onClick={() => setViewMode('form')}>
                <Edit3 size={15} /> Voltar para Edição
              </button>
            )}

            {viewMode === 'form' && (
              <>
                <button className="btn-nfe btn-danfe" onClick={() => setViewMode('danfe')} title="Pré-visualizar DANFE">
                  <Printer size={15} /> Pré-visualizar DANFE
                </button>
                <button className="btn-nfe btn-xml" onClick={handleViewXml} title="Visualizar XML">
                  <Code size={15} /> Ver XML
                </button>
                <button 
                  className="btn-nfe btn-transmit" 
                  onClick={handleTransmitNfe} 
                  disabled={loading}
                  title="Emitir ou Corrigir e Reenviar NF-e para SEFAZ"
                >
                  <Send size={15} /> {nfeStatus === 'AUTORIZADA' ? 'Corrigir e Reenviar NF-e' : 'Transmitir NF-e (SEFAZ)'}
                </button>
              </>
            )}

            {viewMode === 'danfe' && (
              <button className="btn-nfe btn-danfe" onClick={() => window.print()}>
                <Printer size={15} /> Imprimir DANFE A4
              </button>
            )}

            <button className="btn-nfe btn-close" onClick={onClose}>
              Fechar
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}
