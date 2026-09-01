import React, { useState, useEffect } from 'react';
import { 
  FileText, CheckCircle, AlertCircle, X, Printer, Send, 
  Edit3, Copy, ShieldCheck, Download, Code, Package, Building2, Truck, Plus, Trash2, Landmark
} from 'lucide-react';
import { createApi } from '../services/api';
import { toast } from '../contexts/ToastContext';
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

  // Atalhos de teclado (ESC para fechar, CTRL+P para imprimir no modo DANFE)
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape') {
        if (onClose) onClose();
      } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'p') {
        if (viewMode === 'danfe') {
          e.preventDefault();
          window.print();
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [viewMode, onClose]);

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

  // Estados do Cabeçalho da NF-e e Reforma Tributária (NT 2025.002)
  const [header, setHeader] = useState({
    numero: transfer.numeroNf || transfer.id,
    serie: 1,
    naturezaOperacao: 'TRANSFERÊNCIA DE MERCADORIAS ENTRE ESTABELECIMENTOS',
    tipoEmissao: '1 - Normal',
    modelo: '55 - NF-e Eletrônica',
    cfopPadrao: '5.152',
    finalidadeEmissao: '1 - Normal',
    dataEmissao: new Date().toISOString().split('T')[0],
    modalidadeFrete: '0 - Por conta do Emitente (CIF)',
    transpNome: 'FROTA PRÓPRIA',
    transpPlaca: '',
    transpUf: 'MS',
    // Reforma Tributária NT 2025.002 (IBS / CBS)
    cmunFgIbs: '5003801',
    cindOp: '010104',
    cstIbsCbs: '01',
    aliqIbsUf: 0.1,
    aliqIbsMun: 0.0,
    aliqCbs: 0.9,
    cstIs: '01',
    cclassTrib: '000000',
    obsFiscal: `Transferência de mercadorias entre filiais da empresa. Não incidência de ICMS conforme decisão do STF (ADC 49) e Lei Complementar nº 204/2023. Reforma Tributária NT 2025.002 (IBS/CBS). Lote de Transferência: #${transfer.id}. Origem: ${originUnit.name} para Destino: ${destUnit.name}.`
  });

  // Estados dos Itens da NF-e
  const [nfeItems, setNfeItems] = useState([]);

  useEffect(() => {
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
          valorIcms: 0,
          // Reforma Tributária NT 2025.002
          cst_ibscbs: '01',
          cclass_trib: '000000',
          aliq_ibs_uf: 0.1,
          aliq_ibs_mun: 0.0,
          aliq_cbs: 0.9
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

  // Recálculo dos Totais
  const totalProdutos = nfeItems.reduce((acc, it) => acc + (Number(it.valorTotal) || 0), 0);
  const totalFrete = 0;
  const totalNota = totalProdutos + totalFrete;
  const totalIcms = nfeItems.reduce((acc, it) => acc + (Number(it.valorIcms) || 0), 0);
  const totalIbsCbs = nfeItems.reduce((acc, it) => {
    const aliqTotal = (Number(it.aliq_ibs_uf) || 0) + (Number(it.aliq_ibs_mun) || 0) + (Number(it.aliq_cbs) || 0);
    return acc + ((Number(it.valorTotal) || 0) * (aliqTotal / 100));
  }, 0);

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
        valorIcms: 0,
        cst_ibscbs: '01',
        cclass_trib: '000000',
        aliq_ibs_uf: 0.1,
        aliq_ibs_mun: 0.0,
        aliq_cbs: 0.9
      }
    ]);
  };

  const handleRemoveItem = (index) => {
    if (nfeItems.length <= 1) {
      toast.warning('A NF-e precisa ter ao menos um item.');
      return;
    }
    setNfeItems(nfeItems.filter((_, i) => i !== index));
  };

  // Emissão / Autorização na SEFAZ
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
        finalidade_emissao: header.finalidadeEmissao.split(' ')[0],
        cmun_fg_ibs: header.cmunFgIbs,
        cind_op: header.cindOp,
        obs: header.obsFiscal,
        itens: nfeItems
      };

      const res = await api.post('/v1/nfe/emitir-transferencia', payload);
      if (res.data && res.data.sucesso) {
        setNfeStatus('AUTORIZADA');
        setChaveNfe(res.data.chave);
        setProtocolo(res.data.protocolo);
        toast.success(`NF-e de Transferência Autorizada com Sucesso!\n\nChave de Acesso:\n${res.data.chave}\n\nProtocolo SEFAZ: ${res.data.protocolo}`);
        if (onNfeUpdated) onNfeUpdated();
      } else {
        toast.error('Falha na autorização da NF-e. Verifique os dados tributários.');
      }
    } catch (err) {
      console.error(err);
      toast.error('Erro ao comunicar com o servidor de NF-e.');
    } finally {
      setLoading(false);
    }
  };

  // Visualização e Geração do XML
  const handleViewXml = () => {
    const currentChave = chaveNfe || `50260730882804000122550010000${transfer.id}100048942`;
    const xml = `<?xml version="1.0" encoding="UTF-8"?>
<NFe xmlns="http://www.portalfiscal.inf.br/nfe">
  <infNFe Id="NFe${currentChave}" versao="4.00">
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
      <cMunFG>${header.cmunFgIbs}</cMunFG>
      <tpImp>1</tpImp>
      <tpEmis>1</tpEmis>
      <cDV>2</cDV>
      <tpAmb>1</tpAmb>
      <finNFe>${header.finalidadeEmissao.split(' ')[0]}</finNFe>
      <procEmi>0</procEmi>
      <verProc>CENTRO_DISTRIBUICAO_NT2025</verProc>
      <cIndOp>${header.cindOp}</cIndOp>
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
    <det>
${nfeItems.map((it, idx) => `      <item nItem="${idx + 1}">
        <prod>
          <cProd>${it.codigo}</cProd>
          <xProd>${it.nome}</xProd>
          <NCM>${it.ncm.replace(/\D/g, '')}</NCM>
          <CEST>${(it.cest || '').replace(/\D/g, '')}</CEST>
          <CFOP>${it.cfop.replace(/\D/g, '')}</CFOP>
          <uCom>${it.unidade}</uCom>
          <qCom>${it.quantidade}</qCom>
          <vUnCom>${Number(it.valorUnitario).toFixed(2)}</vUnCom>
          <vProd>${Number(it.valorTotal).toFixed(2)}</vProd>
        </prod>
        <imposto>
          <ICMS>
            <ICMS40>
              <orig>0</orig>
              <CST>400</CST>
            </ICMS40>
          </ICMS>
          <IBS_CBS>
            <cstIBSCBS>${it.cst_ibscbs || '01'}</cstIBSCBS>
            <cClassTrib>${it.cclass_trib || '000000'}</cClassTrib>
            <vBC>${Number(it.valorTotal).toFixed(2)}</vBC>
            <pIBSUF>${it.aliq_ibs_uf || '0.10'}</pIBSUF>
            <pCBS>${it.aliq_cbs || '0.90'}</pCBS>
          </IBS_CBS>
        </imposto>
      </item>`).join('\n')}
    </det>
    <total>
      <ICMSTot>
        <vBC>0.00</vBC>
        <vICMS>0.00</vICMS>
        <vProd>${totalProdutos.toFixed(2)}</vProd>
        <vNF>${totalNota.toFixed(2)}</vNF>
      </ICMSTot>
      <IBSTot>
        <vIBS>${totalIbsCbs.toFixed(2)}</vIBS>
      </IBSTot>
    </total>
    <transp>
      <modFrete>${header.modalidadeFrete.split(' ')[0]}</modFrete>
      <transporta>
        <xNome>${header.transpNome}</xNome>
        <UF>${header.transpUf}</UF>
      </transporta>
      <veicTransp>
        <placa>${header.transpPlaca}</placa>
        <UF>${header.transpUf}</UF>
      </veicTransp>
    </transp>
    <infAdic>
      <infCpl>${header.obsFiscal}</infCpl>
    </infAdic>
  </infNFe>
</NFe>`;
    setXmlContent(xml);
    setViewMode('xml');
  };

  const handleCopyChave = () => {
    if (!chaveNfe) return;
    navigator.clipboard.writeText(chaveNfe);
    toast.success('Chave de Acesso copiada com sucesso!');
  };

  const handleCopyXml = () => {
    if (!xmlContent) return;
    navigator.clipboard.writeText(xmlContent);
    toast.success('Conteúdo XML copiado com sucesso!');
  };

  const handleDownloadXmlFile = () => {
    const currentChave = chaveNfe || `50260730882804000122550010000${transfer.id}100048942`;
    const element = document.createElement('a');
    const file = new Blob([xmlContent], { type: 'application/xml' });
    element.href = URL.createObjectURL(file);
    element.download = `${currentChave}-nfe.xml`;
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
  };

  const handleDownloadDanfePdf = () => {
    if (chaveNfe) {
      window.open(`${api.defaults.baseURL || ''}/v1/nfe/${chaveNfe}/danfe`, '_blank');
    } else {
      window.print();
    }
  };

  return (
    <div className="nfe-overlay" onClick={(e) => { if (e.target === e.currentTarget && onClose) onClose(); }}>
      <div className="nfe-container glass">
        
        {/* Cabeçalho do Modal */}
        <div className="nfe-header no-print">
          <div className="nfe-header-title">
            <div className="nfe-icon-badge">
              <FileText size={22} />
            </div>
            <div>
              <h3>Emissão e Visualização de NF-e de Transferência (Modelo 55)</h3>
              <p>Lote #{transfer.id} • {originUnit.name} para {destUnit.name}</p>
            </div>
          </div>
          
          <div className="nfe-header-actions">
            <span className={`nfe-status-pill ${nfeStatus === 'AUTORIZADA' ? 'autorizada' : 'pendente'}`}>
              {nfeStatus === 'AUTORIZADA' ? (
                <><CheckCircle size={14} /> AUTORIZADA SEFAZ</>
              ) : (
                <><AlertCircle size={14} /> PENDENTE / RASCUNHO</>
              )}
            </span>
            <button className="nfe-btn-close" onClick={onClose} title="Fechar (ESC)">
              <X size={20} />
            </button>
          </div>
        </div>

        {/* Abas Internas */}
        <div className="nfe-modal-tabs no-print">
          <button 
            type="button" 
            className={`nfe-tab-btn ${viewMode === 'form' ? 'active' : ''}`}
            onClick={() => setViewMode('form')}
          >
            <FileText size={16} /> Dados da NF-e
          </button>
          <button 
            type="button" 
            className={`nfe-tab-btn ${viewMode === 'danfe' ? 'active' : ''}`}
            onClick={() => setViewMode('danfe')}
          >
            <Printer size={16} /> Prévia DANFE
          </button>
          <button 
            type="button" 
            className={`nfe-tab-btn ${viewMode === 'xml' ? 'active' : ''}`}
            onClick={handleViewXml}
          >
            <Code size={16} /> XML da NF-e
          </button>
        </div>

        {/* CORPO DO MODAL - ABA 1: FORMULÁRIO */}
        {viewMode === 'form' && (
          <div className="nfe-body">
            
            {/* Seção 1: Dados Gerais */}
            <div className="nfe-section-card">
              <div className="nfe-section-title">
                <FileText size={16} /> Dados Gerais da Nota Fiscal & CFOP
              </div>
              <div className="nfe-grid-4">
                <div className="form-group" style={{ gridColumn: 'span 2' }}>
                  <label>Natureza da Operação</label>
                  <input 
                    type="text" 
                    value={header.naturezaOperacao} 
                    onChange={(e) => setHeader({ ...header, naturezaOperacao: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label>CFOP Padrão</label>
                  <select 
                    value={header.cfopPadrao} 
                    onChange={(e) => setHeader({ ...header, cfopPadrao: e.target.value })}
                  >
                    <option value="5.152">5.152 - Transf. mercadoria recebida de terceiros</option>
                    <option value="5.409">5.409 - Transf. mercadoria com ICMS ST</option>
                    <option value="6.152">6.152 - Transf. interestadual de mercadorias</option>
                    <option value="6.409">6.409 - Transf. interestadual com ICMS ST</option>
                  </select>
                </div>

                <div className="form-group">
                  <label>Finalidade Emissão</label>
                  <select 
                    value={header.finalidadeEmissao} 
                    onChange={(e) => setHeader({ ...header, finalidadeEmissao: e.target.value })}
                  >
                    <option value="1 - Normal">1 - Normal</option>
                    <option value="5 - Nota de Crédito">5 - Nota de Crédito (Reforma Tributária)</option>
                    <option value="6 - Nota de Débito">6 - Nota de Débito (Reforma Tributária)</option>
                  </select>
                </div>

                <div className="form-group">
                  <label>Número da NF-e</label>
                  <input 
                    type="number" 
                    value={header.numero} 
                    onChange={(e) => setHeader({ ...header, numero: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label>Série</label>
                  <input 
                    type="number" 
                    value={header.serie} 
                    onChange={(e) => setHeader({ ...header, serie: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label>Modelo</label>
                  <input type="text" value={header.modelo} readOnly />
                </div>

                <div className="form-group">
                  <label>Data de Emissão</label>
                  <input 
                    type="date" 
                    value={header.dataEmissao} 
                    onChange={(e) => setHeader({ ...header, dataEmissao: e.target.value })}
                  />
                </div>
              </div>
            </div>

            {/* Seção 2: Reforma Tributária NT 2025.002 */}
            <div className="nfe-section-card">
              <div className="nfe-section-title">
                <Landmark size={16} /> Reforma Tributária (NT 2025.002 - IBS/CBS & Imposto Seletivo)
              </div>
              <div className="nfe-grid-4">
                <div className="form-group">
                  <label>Município FG IBS (cMunFG)</label>
                  <input 
                    type="text" 
                    value={header.cmunFgIbs} 
                    onChange={(e) => setHeader({ ...header, cmunFgIbs: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label>Indicador de Operação (cIndOp)</label>
                  <select 
                    value={header.cindOp} 
                    onChange={(e) => setHeader({ ...header, cindOp: e.target.value })}
                  >
                    <option value="010104">010104 - Transf. Bens e Serviços</option>
                    <option value="010101">010101 - Comercialização Interna</option>
                    <option value="010102">010102 - Prestação de Serviço</option>
                  </select>
                </div>

                <div className="form-group">
                  <label>CST IBS/CBS Padrão</label>
                  <select 
                    value={header.cstIbsCbs} 
                    onChange={(e) => setHeader({ ...header, cstIbsCbs: e.target.value })}
                  >
                    <option value="01">01 - Tributada c/ Alíquota Padrão</option>
                    <option value="40">40 - Isenção / Não Incidência (STF)</option>
                    <option value="90">90 - Outras Operações</option>
                  </select>
                </div>

                <div className="form-group">
                  <label>Alíquota Total IBS/CBS (%)</label>
                  <input 
                    type="text" 
                    value="1.00% (0.10% IBS + 0.90% CBS)" 
                    readOnly 
                  />
                </div>
              </div>
            </div>

            {/* Seção 3: Emitente e Destinatário */}
            <div className="nfe-section-card">
              <div className="nfe-section-title">
                <Building2 size={16} /> Emitente & Destinatário
              </div>
              <div className="nfe-grid-2">
                <div className="nfe-entity-card">
                  <h4><Building2 size={15} /> REMETENTE / EMITENTE (ORIGEM)</h4>
                  <div className="nfe-entity-name">{originUnit.name}</div>
                  <div className="nfe-entity-detail"><strong>CNPJ:</strong> {originUnit.cnpj} • <strong>IE:</strong> {originUnit.ie}</div>
                  <div className="nfe-entity-detail"><strong>Endereço:</strong> {originUnit.endereco}, {originUnit.cidade} - {originUnit.uf}</div>
                </div>

                <div className="nfe-entity-card">
                  <h4><Truck size={15} /> DESTINATÁRIO (DESTINO)</h4>
                  <div className="nfe-entity-name">{destUnit.name}</div>
                  <div className="nfe-entity-detail"><strong>CNPJ:</strong> {destUnit.cnpj} • <strong>IE:</strong> {destUnit.ie}</div>
                  <div className="nfe-entity-detail"><strong>Endereço:</strong> {destUnit.endereco}, {destUnit.cidade} - {destUnit.uf}</div>
                </div>
              </div>
            </div>

            {/* Seção 4: Transportador & Frete */}
            <div className="nfe-section-card">
              <div className="nfe-section-title">
                <Truck size={16} /> Informações de Transporte & Frete
              </div>
              <div className="nfe-grid-4">
                <div className="form-group">
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

                <div className="form-group">
                  <label>Transportador / Razão Social</label>
                  <input 
                    type="text" 
                    value={header.transpNome} 
                    onChange={(e) => setHeader({ ...header, transpNome: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label>Placa do Veículo</label>
                  <input 
                    type="text" 
                    placeholder="Ex: ABC1D23"
                    value={header.transpPlaca} 
                    onChange={(e) => setHeader({ ...header, transpPlaca: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label>UF do Veículo</label>
                  <input 
                    type="text" 
                    value={header.transpUf} 
                    onChange={(e) => setHeader({ ...header, transpUf: e.target.value })}
                  />
                </div>
              </div>
            </div>

            {/* Seção 5: Itens da NF-e */}
            <div className="nfe-section-card">
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.85rem' }}>
                <div className="nfe-section-title" style={{ margin: 0, border: 'none', padding: 0 }}>
                  <Package size={16} /> Produtos / Itens da NF-e ({nfeItems.length})
                </div>
                <button 
                  type="button" 
                  className="btn-add-item-nfe"
                  onClick={handleAddItem}
                >
                  <Plus size={14} /> Adicionar Item
                </button>
              </div>

              <div className="nfe-table-wrap">
                <table className="nfe-table">
                  <thead>
                    <tr>
                      <th style={{ width: '35px', textAlign: 'center' }}>#</th>
                      <th style={{ width: '70px' }}>CÓDIGO</th>
                      <th>DESCRIÇÃO DO PRODUTO</th>
                      <th style={{ width: '90px', textAlign: 'center' }}>TAM / GRADE</th>
                      <th style={{ width: '95px' }}>NCM</th>
                      <th style={{ width: '65px' }}>CFOP</th>
                      <th style={{ width: '45px' }}>UN</th>
                      <th style={{ width: '65px' }}>QUANT</th>
                      <th style={{ width: '95px' }}>VALOR UNIT</th>
                      <th style={{ width: '105px' }}>VALOR TOTAL</th>
                      <th style={{ width: '85px' }}>CST ICMS</th>
                      <th style={{ width: '85px' }}>CST IBS</th>
                      <th style={{ width: '35px', textAlign: 'center' }}>AÇÃO</th>
                    </tr>
                  </thead>
                  <tbody>
                    {nfeItems.map((item, idx) => (
                      <tr key={item.id || idx}>
                        <td style={{ fontWeight: 700, color: '#64748b', textAlign: 'center' }}>{item.seq}</td>
                        <td><strong>#{item.codigo}</strong></td>
                        <td>
                          <input 
                            type="text" 
                            value={item.nome} 
                            onChange={(e) => handleItemChange(idx, 'nome', e.target.value)}
                          />
                        </td>
                        <td style={{ textAlign: 'center' }}>
                          <span className="nfe-tag-size">
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
                        <td style={{ fontWeight: 800, color: '#0b1c30' }}>
                          {formatCurrency(item.valorTotal)}
                        </td>
                        <td>
                          <select 
                            value={item.cst} 
                            onChange={(e) => handleItemChange(idx, 'cst', e.target.value)}
                          >
                            <option value="400">400 - Não Trib.</option>
                            <option value="00">00 - Tributada</option>
                            <option value="102">102 - Simples</option>
                          </select>
                        </td>
                        <td>
                          <select 
                            value={item.cst_ibscbs || '01'} 
                            onChange={(e) => handleItemChange(idx, 'cst_ibscbs', e.target.value)}
                          >
                            <option value="01">01 - Trib.</option>
                            <option value="40">40 - Isento</option>
                            <option value="90">90 - Outras</option>
                          </select>
                        </td>
                        <td style={{ textAlign: 'center' }}>
                          <button 
                            type="button" 
                            onClick={() => handleRemoveItem(idx)}
                            className="btn-remove-item-nfe"
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

            {/* Seção 6: Totais e Observações */}
            <div className="nfe-section-card">
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
                  <label>Previsão IBS/CBS (1%)</label>
                  <div className="nfe-total-value">{formatCurrency(totalIbsCbs)}</div>
                </div>
                <div className="nfe-total-box">
                  <label>Total dos Produtos</label>
                  <div className="nfe-total-value">{formatCurrency(totalProdutos)}</div>
                </div>
                <div className="nfe-total-box highlight">
                  <label>VALOR TOTAL DA NOTA</label>
                  <div className="nfe-total-value">{formatCurrency(totalNota)}</div>
                </div>
              </div>

              <div className="form-group" style={{ marginTop: '1rem' }}>
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

        {/* CORPO DO MODAL - ABA 2: PRÉVIA DANFE */}
        {viewMode === 'danfe' && (
          <div className="nfe-body nfe-danfe-wrapper">
            <div className="nfe-danfe-toolbar no-print">
              <span>Prévia Oficial de Impressão do DANFE A4</span>
              <div style={{ display: 'flex', gap: '0.5rem' }}>
                <button className="btn-secondary" onClick={() => window.print()} title="Imprimir DANFE A4 (Ctrl+P)">
                  <Printer size={15} /> Imprimir DANFE A4
                </button>
                <button className="btn-primary" onClick={handleDownloadDanfePdf} title="Baixar DANFE em PDF">
                  <Download size={15} /> Baixar PDF
                </button>
              </div>
            </div>

            <div className="nfe-danfe-sheet nfe-danfe-print-area">
              {/* Canhoto */}
              <div className="danfe-receipt-box">
                RECEBEMOS DE <strong>{originUnit.name}</strong> OS PRODUTOS CONSTANTES DA NOTA FISCAL INDICADA AO LADO. EMISSÃO: {formatDate(header.dataEmissao)} - VALOR TOTAL: {formatCurrency(totalNota)}
                <div className="danfe-receipt-row">
                  <span>DATA DO RECEBIMENTO: _____/_____/_________</span>
                  <span>IDENTIFICAÇÃO E ASSINATURA DO RECEBEDOR: _____________________________________________</span>
                </div>
              </div>

              {/* Cabeçalho DANFE */}
              <div className="danfe-header-grid">
                <div>
                  <h3>{originUnit.name}</h3>
                  <p>{originUnit.endereco}</p>
                  <p>{originUnit.cidade} - {originUnit.uf} • CEP: {originUnit.cep}</p>
                  <p><strong>CNPJ:</strong> {originUnit.cnpj} • <strong>IE:</strong> {originUnit.ie}</p>
                </div>
                <div className="danfe-center-meta">
                  <h4>DANFE</h4>
                  <p className="sub">Documento Auxiliar da Nota Fiscal Eletrônica</p>
                  <p><strong>1 - SAÍDA</strong></p>
                  <p className="bold">Nº {header.numero} • SÉRIE {header.serie}</p>
                </div>
                <div>
                  <p className="label">CHAVE DE ACESSO</p>
                  <p className="chave-code">
                    {chaveNfe || '50260730882804000122550010000' + transfer.id + '100048942'}
                  </p>
                  <p style={{ marginTop: '4px' }}><strong>PROTOCOLO:</strong> {protocolo || '1502600000' + transfer.id}</p>
                </div>
              </div>

              {/* Destinatário */}
              <div className="danfe-dest-box">
                <strong>DESTINATÁRIO / REMETENTE:</strong> {destUnit.name} • <strong>CNPJ:</strong> {destUnit.cnpj} • <strong>IE:</strong> {destUnit.ie}<br />
                <strong>ENDEREÇO:</strong> {destUnit.endereco}, {destUnit.cidade} - {destUnit.uf}
              </div>

              {/* Tabela de Produtos DANFE */}
              <table className="danfe-table">
                <thead>
                  <tr>
                    <th style={{ width: '40px' }}>CÓD</th>
                    <th>DESCRIÇÃO DO PRODUTO</th>
                    <th style={{ width: '50px', textAlign: 'center' }}>TAM</th>
                    <th style={{ width: '80px' }}>NCM</th>
                    <th style={{ width: '55px' }}>CFOP</th>
                    <th style={{ width: '40px' }}>UN</th>
                    <th style={{ width: '50px', textAlign: 'center' }}>QTD</th>
                    <th style={{ width: '80px', textAlign: 'right' }}>V.UNIT</th>
                    <th style={{ width: '90px', textAlign: 'right' }}>V.TOTAL</th>
                  </tr>
                </thead>
                <tbody>
                  {nfeItems.map((it, idx) => (
                    <tr key={idx}>
                      <td>{it.codigo}</td>
                      <td>{it.nome}</td>
                      <td style={{ textAlign: 'center', fontWeight: 'bold' }}>{it.tamanho || '-'}</td>
                      <td>{it.ncm}</td>
                      <td>{it.cfop}</td>
                      <td>{it.unidade}</td>
                      <td style={{ textAlign: 'center' }}>{it.quantidade}</td>
                      <td style={{ textAlign: 'right' }}>{formatCurrency(it.valorUnitario)}</td>
                      <td style={{ textAlign: 'right' }}>{formatCurrency(it.valorTotal)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {/* Totais DANFE */}
              <div className="danfe-totals-line">
                VALOR TOTAL DA NOTA FISCAL: {formatCurrency(totalNota)}
              </div>

              {/* Dados Adicionais */}
              <div className="danfe-additional-box">
                <strong>DADOS ADICIONAIS:</strong> {header.obsFiscal}
              </div>
            </div>
          </div>
        )}

        {/* CORPO DO MODAL - ABA 3: XML DA NF-E */}
        {viewMode === 'xml' && (
          <div className="nfe-body">
            <div className="nfe-section-card">
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.85rem' }}>
                <div className="nfe-section-title" style={{ margin: 0, border: 'none', padding: 0 }}>
                  <Code size={16} /> Estrutura XML da NF-e (Layout Oficial SEFAZ 4.00 & NT 2025.002)
                </div>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <button className="btn-secondary" onClick={handleCopyXml}>
                    <Copy size={14} /> Copiar XML
                  </button>
                  <button className="btn-primary" onClick={handleDownloadXmlFile}>
                    <Download size={14} /> Baixar Arquivo .xml
                  </button>
                </div>
              </div>

              <textarea 
                rows={18} 
                value={xmlContent} 
                readOnly 
                className="nfe-xml-viewer"
              />
            </div>
          </div>
        )}

        {/* Rodapé / Barra de Ações do Modal */}
        <div className="nfe-footer no-print">
          <div className="nfe-key-and-shortcuts">
            <div className="nfe-key-badge">
              <ShieldCheck size={16} color="#16a34a" />
              <span>Chave: {chaveNfe || 'Será gerada na transmissão SEFAZ'}</span>
              {chaveNfe && (
                <button 
                  type="button" 
                  onClick={handleCopyChave}
                  className="nfe-key-copy-btn"
                  title="Copiar Chave de Acesso"
                >
                  <Copy size={14} />
                </button>
              )}
            </div>
            
            <div className="nfe-shortcuts">
              <span className="nfe-shortcut-item"><kbd>ESC</kbd> Fechar</span>
            </div>
          </div>

          <div className="nfe-footer-actions">
            {viewMode !== 'form' && (
              <button className="btn-secondary" onClick={() => setViewMode('form')}>
                <Edit3 size={15} /> Voltar para Edição
              </button>
            )}

            {viewMode === 'form' && (
              <>
                <button className="btn-secondary" onClick={() => setViewMode('danfe')} title="Pré-visualizar DANFE">
                  <Printer size={15} /> Prévia DANFE
                </button>
                <button className="btn-secondary" onClick={handleViewXml} title="Visualizar XML">
                  <Code size={15} /> Ver XML
                </button>
                <button 
                  className="btn-sefaz-transmit" 
                  onClick={handleTransmitNfe} 
                  disabled={loading}
                  title="Autorizar NF-e na SEFAZ"
                >
                  <Send size={15} /> {nfeStatus === 'AUTORIZADA' ? 'Corrigir e Reenviar NF-e' : 'Autorizar na SEFAZ'}
                </button>
              </>
            )}

            {viewMode === 'danfe' && (
              <>
                <button className="btn-secondary" onClick={() => window.print()}>
                  <Printer size={15} /> Imprimir DANFE A4
                </button>
                <button className="btn-primary" onClick={handleDownloadDanfePdf}>
                  <Download size={15} /> Baixar DANFE (PDF)
                </button>
              </>
            )}

            {viewMode === 'xml' && (
              <button className="btn-primary" onClick={handleDownloadXmlFile}>
                <Download size={15} /> Baixar XML
              </button>
            )}

            <button className="btn-nfe-close-footer" onClick={onClose}>
              Cancelar
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}

