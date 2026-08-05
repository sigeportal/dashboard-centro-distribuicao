import { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { ArrowRightLeft, Plus, CheckCircle, AlertCircle, Eye, RefreshCw, Send, ShieldCheck, XCircle, Search, Package, X } from 'lucide-react';
import { createApi } from '../../services/api';
import SearchBar from '../SearchBar';
import Pagination from '../Pagination';
import { formatCurrency, formatDate } from '../../utils/formatters';
import './TransferTab.css';

export default function TransferTab() {
  const api = createApi(true); // Conecta na CD_API_BASE (port 9000)
  const [activeSubTab, setActiveSubTab] = useState('list'); // 'list', 'new', 'reception'
  const [loading, setLoading] = useState(false);
  const [transfers, setTransfers] = useState([]);
  const [products, setProducts] = useState([]);
  const [units, setUnits] = useState([]);
  
  // Modal de Busca de Produtos Paginada e Debounced
  const [modalProducts, setModalProducts] = useState([]);
  const [modalSearchPage, setModalSearchPage] = useState(1);
  const [modalSearchMeta, setModalSearchMeta] = useState({ page: 1, limit: 10, total: 0, pages: 1 });
  const [modalSearchLoading, setModalSearchLoading] = useState(false);
  
  // Detalhes da Transferência Selecionada
  const [selectedTransfer, setSelectedTransfer] = useState(null);
  const [selectedTransferItems, setSelectedTransferItems] = useState([]);
  const [isViewingDetails, setIsViewingDetails] = useState(false);

  // Nova Transferência
  const [origin, setOrigin] = useState('');
  const [destination, setDestination] = useState('');
  const [tipoFiscal, setTipoFiscal] = useState('FISCAL'); // 'FISCAL' (Com NF-e) ou 'NAO_FISCAL' (Sem Nota)
  const [numeroNf, setNumeroNf] = useState('');
  const [chaveNfe, setChaveNfe] = useState('');
  const [obs, setObs] = useState('');
  const [transferItems, setTransferItems] = useState([]); // { produto_id, quantidade, valor }
  
  // Inputs da linha de item temporário
  const [selectedProduct, setSelectedProduct] = useState('');
  const [quantity, setQuantity] = useState('');
  const [price, setPrice] = useState('');
  const [loadingNf, setLoadingNf] = useState(false);

  const handleFetchNfItems = async () => {
    const term = (chaveNfe || '').trim() || (numeroNf || '').trim();
    if (!term) {
      alert('Por favor, informe a Chave de Acesso ou o Número da Nota Fiscal.');
      return;
    }
    setLoadingNf(true);
    try {
      const res = await api.get(`/v1/compras/buscar-nf?termo=${encodeURIComponent(term)}`);
      const compraData = res.data;
      if (compraData && Array.isArray(compraData.itens) && compraData.itens.length > 0) {
        const importedItems = compraData.itens.map(it => ({
          produto_id: it.produto_codigo,
          nome: it.produto_nome || `Produto #${it.produto_codigo}`,
          quantidade: Number(it.quantidade) || 1,
          valor: Number(it.valor_unitario) || 0
        }));
        
        setTransferItems(prev => {
          const map = new Map();
          prev.forEach(item => map.set(item.produto_id, item));
          importedItems.forEach(item => map.set(item.produto_id, item));
          return Array.from(map.values());
        });

        if (compraData.numero_nf && !numeroNf) setNumeroNf(compraData.numero_nf);
        if (compraData.chave_nfe && !chaveNfe) setChaveNfe(compraData.chave_nfe);

        alert(`Sucesso! ${importedItems.length} itens da NF #${compraData.numero_nf || term} foram carregados no lote.`);
      } else {
        alert('Nenhum item encontrado nesta Nota Fiscal.');
      }
    } catch (err) {
      console.error('Erro ao buscar itens da NF:', err);
      alert('Nota Fiscal não encontrada. Verifique se o número ou a chave foram digitados corretamente.');
    } finally {
      setLoadingNf(false);
    }
  };

  const handleEmitTransferNfe = async () => {
    if (transferItems.length === 0) {
      alert('Adicione ao menos um produto no lote da transferência antes de emitir a NF-e.');
      return;
    }
    setLoadingNf(true);
    try {
      const payload = {
        origem: Number(originUnit),
        destino: Number(destinationUnit),
        obs: obs || 'Transferência de estoque entre unidades',
        tipoFiscal: 'FISCAL',
        numeroNf: numeroNf || '0',
        chaveNfe: chaveNfe || '',
        itens: transferItems.map(it => ({
          produto_id: it.produto_id,
          quantidade: it.quantidade,
          valor: it.valor
        }))
      };
      const resTr = await api.post('/v1/transferencias', payload);
      const trId = resTr.data?.id || resTr.data?.transferencia_id || 1;

      const resNfe = await api.post('/v1/nfe/emitir-transferencia', { transferencia_id: trId });
      if (resNfe.data && resNfe.data.sucesso) {
        setNumeroNf(String(resNfe.data.numero || trId));
        setChaveNfe(resNfe.data.chave);
        alert(`NF-e Modelo 55 autorizada na SEFAZ com sucesso!\n\nLote Transferência: #${trId}\nChave NFe: ${resNfe.data.chave}\nProtocolo SEFAZ: ${resNfe.data.protocolo}`);
        fetchTransfers();
      } else {
        alert('Falha na autorização da NF-e na SEFAZ.');
      }
    } catch (err) {
      console.error('Erro ao emitir NF-e da transferência:', err);
      alert('Erro na transmissão da NF-e para a SEFAZ.');
    } finally {
      setLoadingNf(false);
    }
  };

  // Modal de Pesquisa de Produtos (Igual à tela de Produtos)
  const [showProductSearchModal, setShowProductSearchModal] = useState(false);
  const [modalSearchTerm, setModalSearchTerm] = useState('');
  const [modalStockFilter, setModalStockFilter] = useState('todos'); // 'todos', 'low', 'out'

  // Conferência de Recebimento
  const [receptionTransfer, setReceptionTransfer] = useState(null);
  const [receptionItems, setReceptionItems] = useState([]); // { item, checked_qty, justificativa }
  const [checkerName, setCheckerName] = useState('');
  const [receptionObs, setReceptionObs] = useState('');

  // Notificações
  const [notifications, setNotifications] = useState([]);

  useEffect(() => {
    fetchTransfers();
    fetchProducts();
    fetchUnits();
  }, []);

  // Gerenciamento de notificações dispensadas pelo usuário
  const [dismissedNotifications, setDismissedNotifications] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem('dismissed_transfer_notifications') || '[]');
    } catch {
      return [];
    }
  });

  // Notifica o gestor sobre transferências direcionadas pendentes de conferência
  useEffect(() => {
    if (transfers.length > 0) {
      const activeUnitId = Number(localStorage.getItem('selected_company_id')) || 1;
      const newNotifications = [];

      // Notifica se a unidade atual possui transferências recebidas pendentes de conferência
      const pendingReception = transfers.filter(
        t => t.destino === activeUnitId && t.status === 'Em Trânsito'
      );
      
      pendingReception.forEach(t => {
        const notifId = `pending-${t.id}`;
        if (!dismissedNotifications.includes(notifId)) {
          const origName = getUnitName(t.origem);
          newNotifications.push({
            id: notifId,
            message: `Atenção: Nova transferência #${t.id} enviada pela unidade [${origName}] está pendente de recepção e conferência!`,
            type: 'warning'
          });
        }
      });

      // Notifica se a unidade de destino confirmou/aprovou uma transferência enviada por esta unidade
      const approvedSent = transfers.filter(
        t => t.origem === activeUnitId && t.status === 'Conferido/Aprovado'
      );

      approvedSent.forEach(t => {
        const notifId = `app-${t.id}`;
        if (!dismissedNotifications.includes(notifId)) {
          const destName = getUnitName(t.destino);
          newNotifications.push({
            id: notifId,
            message: `Sucesso: Unidade [${destName}] confirmou e aprovou o recebimento da transferência #${t.id}!`,
            type: 'success'
          });
        }
      });

      setNotifications(newNotifications);
    }
  }, [transfers, units, dismissedNotifications]);

  const handleDismissNotification = (id) => {
    const updated = [...dismissedNotifications, id];
    setDismissedNotifications(updated);
    localStorage.setItem('dismissed_transfer_notifications', JSON.stringify(updated));
  };

  const handleClearAllNotifications = () => {
    const allIds = notifications.map(n => n.id);
    const updated = [...dismissedNotifications, ...allIds];
    setDismissedNotifications(updated);
    localStorage.setItem('dismissed_transfer_notifications', JSON.stringify(updated));
  };

  const fetchTransfers = async () => {
    setLoading(true);
    try {
      const response = await api.get('/v1/transferencias');
      if (Array.isArray(response.data)) {
        const activeUnitId = Number(localStorage.getItem('selected_company_id')) || 1;
        // Regra de Visibilidade: A Matriz (ID 1) vê todas, as filiais veem apenas as suas
        const visibleTransfers = activeUnitId === 1 
          ? response.data 
          : response.data.filter(t => t.origem === activeUnitId || t.destino === activeUnitId);
        
        setTransfers(visibleTransfers);
      }
    } catch (err) {
      console.error('Erro ao buscar transferências:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchProducts = async () => {
    try {
      const response = await api.get('/v1/produtos?limit=500');
      if (Array.isArray(response.data)) {
        setProducts(response.data);
      } else if (response.data?.data && Array.isArray(response.data.data)) {
        setProducts(response.data.data);
      }
    } catch (err) {
      console.error('Erro ao buscar produtos para transferência:', err);
    }
  };

  const fetchUnits = async () => {
    try {
      const response = await api.get('/v1/empresa');
      if (Array.isArray(response.data)) {
        const formattedUnits = response.data.map(u => {
          const rawName = u.fantasia || u.Fantasia || u.razao_social || u.Razao_social || 'Unidade';
          const code = u.codigo || u.Codigo;
          const isCd = rawName.toUpperCase().includes('CD') || code === 5 || rawName.toUpperCase().includes('DOURADINA');
          return {
            id: code,
            name: `${code} - ${rawName}`,
            ccCodigo: u.ccCodigo || u.CcCodigo,
            isCd: isCd
          };
        });

        // Ordena para que o Centro de Distribuição (CD) seja SEMPRE a 1ª OPÇÃO!
        formattedUnits.sort((a, b) => (b.isCd ? 1 : 0) - (a.isCd ? 1 : 0));

        setUnits(formattedUnits);

        // Define a unidade de origem padrão como o Centro de Distribuição (1ª opção)
        if (formattedUnits.length > 0) {
          setOrigin(String(formattedUnits[0].id));
        }
      }
    } catch (err) {
      console.error('Erro ao buscar unidades (empresas):', err);
    }
  };

  // Busca de Produtos Paginada e Servidor para o Modal (Desempenho Extremo)
  const fetchModalProducts = async (search = modalSearchTerm, targetPage = 1, stockFilter = modalStockFilter) => {
    setModalSearchLoading(true);
    try {
      const searchParam = search ? `&search=${encodeURIComponent(search)}` : '';
      const stockParam = stockFilter !== 'todos' ? `&stockStatus=${stockFilter}` : '';
      const url = `/v1/produtos?page=${targetPage}&limit=10${searchParam}${stockParam}`;
      const res = await api.get(url);

      let items = [];
      let metaData = { page: targetPage, limit: 10, total: 0, pages: 1 };

      if (Array.isArray(res.data)) {
        items = res.data;
        metaData = { page: 1, limit: items.length || 10, total: items.length, pages: 1 };
      } else if (res.data && Array.isArray(res.data.data)) {
        items = res.data.data;
        metaData = res.data.meta || metaData;
      }

      setModalProducts(items);
      setModalSearchMeta(metaData);
      setModalSearchPage(metaData.page || targetPage);
    } catch (err) {
      console.error('Erro ao buscar produtos no modal de transferência:', err);
    } finally {
      setModalSearchLoading(false);
    }
  };

  useEffect(() => {
    if (showProductSearchModal) {
      const timer = setTimeout(() => {
        fetchModalProducts(modalSearchTerm, 1, modalStockFilter);
      }, 300);
      return () => clearTimeout(timer);
    }
  }, [showProductSearchModal, modalSearchTerm, modalStockFilter]);

  const handleModalPageChange = (newPage) => {
    fetchModalProducts(modalSearchTerm, newPage, modalStockFilter);
  };

  const handleSelectProductFromModal = (prod) => {
    setSelectedProduct(String(prod.codigo));
    setPrice(prod.valorv || '');
    setShowProductSearchModal(false);
  };

  const handleViewDetails = async (transfer) => {
    setSelectedTransfer(transfer);
    setLoading(true);
    try {
      const response = await api.get(`/v1/transferenciaItens?transferencia_id=${transfer.id}`);
      if (Array.isArray(response.data)) {
        setSelectedTransferItems(response.data);
        setIsViewingDetails(true);
      }
    } catch (err) {
      alert('Erro ao carregar itens da transferência.');
    } finally {
      setLoading(false);
    }
  };

  const handleAddItemToTransfer = () => {
    if (!selectedProduct || !quantity || Number(quantity) <= 0) {
      alert('Selecione o produto e informe uma quantidade válida.');
      return;
    }

    const prod = products.find(p => p.codigo === Number(selectedProduct));
    if (!prod) return;

    // Impede duplicados no formulário
    if (transferItems.find(item => item.produto_id === prod.codigo)) {
      alert('Este produto já foi adicionado.');
      return;
    }

    setTransferItems([
      ...transferItems,
      {
        produto_id: prod.codigo,
        nome: prod.nome,
        quantidade: Number(quantity),
        valor: Number(price) || prod.valorv || 0
      }
    ]);

    setSelectedProduct('');
    setQuantity('');
    setPrice('');
  };

  const handleRemoveItemFromTransfer = (productId) => {
    setTransferItems(transferItems.filter(item => item.produto_id !== productId));
  };

  const handleCreateTransfer = async (e) => {
    e.preventDefault();
    if (!origin || !destination) {
      alert('Informe a unidade de origem e de destino.');
      return;
    }
    if (origin === destination) {
      alert('A unidade de origem não pode ser idêntica ao destino.');
      return;
    }
    if (transferItems.length === 0) {
      alert('Adicione pelo menos um produto na transferência.');
      return;
    }

    setLoading(true);
    try {
      const transferId = Math.floor(Math.random() * 90000) + 10000; // Gera código temporário para o lote
      
      const transferData = {
        id: transferId,
        origem: Number(origin),
        destino: Number(destination),
        data: new Date().toISOString().split('T')[0],
        status: 'Em Trânsito',
        obs: obs,
        usuarioRecebimento: '',
        dataRecebimento: '1899-12-30', // Data padrão nula Delphi
        tipoFiscal: tipoFiscal,
        numeroNf: tipoFiscal === 'FISCAL' ? numeroNf : '',
        chaveNfe: tipoFiscal === 'FISCAL' ? chaveNfe : ''
      };

      // Cria cabeçalho
      await api.post('/v1/transferencias', transferData);

      // Cria itens em Lote (alta performance ArrayDML)
      const formattedItems = transferItems.map((item, idx) => ({
        id: Math.floor(Math.random() * 900000) + 100000 + idx,
        transferenciaId: transferId,
        produtoId: item.produto_id,
        quantidade: item.quantidade,
        valor: item.valor,
        quantidadeConferida: 0
      }));

      await api.post('/v1/transferenciaItens/emLote', { itens: formattedItems });

      alert(`Transferência (${tipoFiscal === 'FISCAL' ? 'Fiscal com NF-e' : 'Não Fiscal / Sem Nota'}) enviada com sucesso!`);
      
      // Reset formulário
      setOrigin('');
      setDestination('');
      setTipoFiscal('FISCAL');
      setNumeroNf('');
      setChaveNfe('');
      setObs('');
      setTransferItems([]);
      setActiveSubTab('list');
      fetchTransfers();
    } catch (err) {
      console.error(err);
      alert('Erro ao processar transferência.');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenConference = async (transfer) => {
    setLoading(true);
    try {
      const response = await api.get(`/v1/transferenciaItens?transferencia_id=${transfer.id}`);
      if (Array.isArray(response.data)) {
        setReceptionTransfer(transfer);
        setReceptionItems(response.data.map(item => ({
          ...item,
          quantidadeConferida: item.quantidadeConferida ?? item.quantidade,
          justificativa: item.justificativa || ''
        })));
        setReceptionObs('');
        setActiveSubTab('reception');
      }
    } catch (err) {
      alert('Erro ao carregar itens para conferência.');
    } finally {
      setLoading(false);
    }
  };

  const handleQtyConferidaChange = (idx, value) => {
    const next = [...receptionItems];
    next[idx].quantidadeConferida = Number(value) || 0;
    setReceptionItems(next);
  };

  const handleJustificativaChange = (idx, value) => {
    const next = [...receptionItems];
    next[idx].justificativa = value;
    setReceptionItems(next);
  };

  const handleApproveReception = async (status) => {
    if (!checkerName.trim()) {
      alert('Por favor, informe o nome do conferente/responsável.');
      return;
    }

    setLoading(true);
    try {
      // 1. Atualiza cabeçalho de transferência com Status, conferente, data e observações da recepção se houver
      const finalObs = receptionObs.trim() 
        ? `${receptionTransfer.obs ? receptionTransfer.obs + ' | ' : ''}Recepção: ${receptionObs.trim()}`
        : receptionTransfer.obs;

      const updatedHeader = {
        ...receptionTransfer,
        status: status, // 'Conferido/Aprovado', 'Aceito Parcialmente' ou 'Rejeitado'
        usuarioRecebimento: checkerName,
        dataRecebimento: new Date().toISOString().split('T')[0],
        obs: finalObs
      };
      await api.put('/v1/transferencias', updatedHeader);

      // 2. Atualiza os itens com a quantidade fisicamente conferida e a justificativa por item
      const formattedReceptionItems = receptionItems.map(it => ({
        ...it,
        quantidadeConferida: Number(it.quantidadeConferida ?? it.quantidade) || 0,
        justificativa: it.justificativa || ''
      }));
      await api.post('/v1/transferenciaItens/emLote', { itens: formattedReceptionItems });

      let msg = 'Recepção concluída e estoque atualizado com sucesso!';
      if (status === 'Aceito Parcialmente') msg = 'Transferência Aceita Parcialmente com divergências registradas!';
      if (status === 'Rejeitado') msg = 'Transferência Recusada / Devolvida!';
      alert(msg);
      
      // Reset
      setReceptionTransfer(null);
      setReceptionItems([]);
      setCheckerName('');
      setReceptionObs('');
      setActiveSubTab('list');
      fetchTransfers();
    } catch (err) {
      console.error(err);
      alert('Erro ao aprovar o recebimento.');
    } finally {
      setLoading(false);
    }
  };

  const getUnitName = (id) => {
    const unit = units.find(u => u.id === Number(id));
    return unit ? unit.name : `Unidade #${id}`;
  };

  const getStatusBadge = (status) => {
    switch (status) {
      case 'Pendente':
        return <span className="badge badge-warning">Pendente</span>;
      case 'Em Trânsito':
        return <span className="badge badge-info">Em Trânsito</span>;
      case 'Conferido/Aprovado':
        return <span className="badge badge-success">Conferido & Aprovado</span>;
      case 'Aceito Parcialmente':
        return <span className="badge badge-warning" style={{ backgroundColor: '#f59e0b', color: '#ffffff' }}>Aceito em Partes</span>;
      case 'Rejeitado':
        return <span className="badge badge-danger">Recusado</span>;
      default:
        return <span className="badge">{status}</span>;
    }
  };

  return (
    <div className="cd-container full-width">
      
      {/* Alertas de Notificações */}
      {notifications.length > 0 && (
        <div className="cd-notifications-bar" style={{ marginBottom: '1.25rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.4rem', padding: '0 0.25rem' }}>
            <span style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>
              🔔 Notificações da Central ({notifications.length})
            </span>
            <button 
              onClick={handleClearAllNotifications}
              style={{
                background: 'transparent',
                border: 'none',
                color: '#6b7280',
                fontSize: '0.82rem',
                cursor: 'pointer',
                fontWeight: 600,
                textDecoration: 'underline'
              }}
            >
              Limpar Notificações
            </button>
          </div>
          {notifications.map((n) => (
            <div key={n.id} className={`cd-notification ${n.type}`} style={{ justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                {n.type === 'warning' ? <AlertCircle size={20} /> : <CheckCircle size={20} />}
                <span>{n.message}</span>
              </div>
              <button 
                onClick={() => handleDismissNotification(n.id)}
                title="Dispensar Notificação"
                style={{
                  background: 'transparent',
                  border: 'none',
                  cursor: 'pointer',
                  padding: '4px',
                  color: 'inherit',
                  opacity: 0.75,
                  display: 'flex',
                  alignItems: 'center'
                }}
              >
                <X size={16} />
              </button>
            </div>
          ))}
        </div>
      )}

      {/* Navegação SubTabs */}
      <div className="cd-header-tabs glass">
        <button 
          className={`cd-tab-btn ${activeSubTab === 'list' ? 'active' : ''}`}
          onClick={() => { setActiveSubTab('list'); setIsViewingDetails(false); }}
        >
          <ArrowRightLeft size={18} /> Transferências
        </button>
        <button 
          className={`cd-tab-btn ${activeSubTab === 'new' ? 'active' : ''}`}
          onClick={() => setActiveSubTab('new')}
        >
          <Plus size={18} /> Enviar Transferência
        </button>
      </div>

      {loading && <div className="loading-bar">Carregando dados...</div>}

      {/* SUBTAB: LISTA DE TRANSFERÊNCIAS */}
      {activeSubTab === 'list' && !isViewingDetails && (
        <div className="list-card glass">
          <div className="cd-title-row">
            <h3><ArrowRightLeft size={20} /> Controle do Centro de Distribuição</h3>
            <button className="refresh-btn" onClick={fetchTransfers} disabled={loading}>
              <RefreshCw size={18} /> Sincronizar
            </button>
          </div>

          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Cod. Lote</th>
                  <th>Tipo</th>
                  <th>Origem</th>
                  <th>Destino</th>
                  <th>Data Envio</th>
                  <th>Status</th>
                  <th>Observação</th>
                  <th>Ações</th>
                </tr>
              </thead>
              <tbody>
                {transfers.map((item, idx) => (
                  <tr key={item.id || idx}>
                    <td><span className="item-code">#{item.id}</span></td>
                    <td>
                      {item.tipoFiscal === 'NAO_FISCAL' ? (
                        <span className="badge badge-warning" title="Produtos comprados sem nota fiscal">📦 Não Fiscal</span>
                      ) : (
                        <span className="badge badge-info" title={item.numeroNf ? `NF-e #${item.numeroNf}` : 'NF-e de Transferência'}>
                          📄 Fiscal {item.numeroNf ? `#${item.numeroNf}` : ''}
                        </span>
                      )}
                    </td>
                    <td>{getUnitName(item.origem)}</td>
                    <td>{getUnitName(item.destino)}</td>
                    <td>{formatDate(item.data)}</td>
                    <td>{getStatusBadge(item.status)}</td>
                    <td>{item.obs || '-'}</td>
                    <td className="actions-cell">
                      <button 
                        className="cd-action-btn view" 
                        onClick={() => handleViewDetails(item)} 
                        title="Ver Itens"
                      >
                        <Eye size={16} /> Ver Itens
                      </button>
                      
                      {item.status === 'Em Trânsito' && (
                        <button 
                          className="cd-action-btn check" 
                          onClick={() => handleOpenConference(item)}
                          title="Conferir e Receber"
                        >
                          <ShieldCheck size={16} /> Receber
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
                {transfers.length === 0 && (
                  <tr>
                    <td colSpan="7" style={{ textAlign: 'center', padding: '2rem' }}>
                      Nenhuma transferência registrada.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* MODAL / VIEW: DETALHES DE UMA TRANSFERÊNCIA */}
      {activeSubTab === 'list' && isViewingDetails && selectedTransfer && (
        <div className="list-card glass">
          <div className="cd-title-row">
            <h3>Itens do Lote #{selectedTransfer.id}</h3>
            <button className="refresh-btn" onClick={() => setIsViewingDetails(false)}>Voltar para Lista</button>
          </div>

          <div className="cd-details-meta grid-2">
            <div>
              <p><strong>Origem:</strong> {getUnitName(selectedTransfer.origem)}</p>
              <p><strong>Destino:</strong> {getUnitName(selectedTransfer.destino)}</p>
              <p><strong>Status:</strong> {getStatusBadge(selectedTransfer.status)}</p>
            </div>
            <div>
              <p><strong>Responsável Recepção:</strong> {selectedTransfer.usuarioRecebimento || 'Não recebido ainda'}</p>
              <p><strong>Data Recepção:</strong> {formatDate(selectedTransfer.dataRecebimento)}</p>
              <p><strong>Obs:</strong> {selectedTransfer.obs || '-'}</p>
            </div>
          </div>

          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>ID Item</th>
                  <th>Produto</th>
                  <th>Qtd Enviada</th>
                  <th>Qtd Conferida (Recepção)</th>
                  <th>Status / Justificativa</th>
                  <th>Valor Unitário</th>
                </tr>
              </thead>
              <tbody>
                {selectedTransferItems.map((item, idx) => {
                  const prod = products.find(p => p.codigo === item.produtoId);
                  const isConferido = selectedTransfer.status === 'Conferido/Aprovado' || selectedTransfer.status === 'Aceito Parcialmente' || selectedTransfer.status === 'Rejeitado';
                  const qtdConferidaVal = item.quantidadeConferida ?? item.quantidade;
                  const isMatch = Number(qtdConferidaVal) === Number(item.quantidade);

                  return (
                    <tr key={item.id || idx}>
                      <td>#{item.id}</td>
                      <td>{prod ? prod.nome : `Produto ID ${item.produtoId}`}</td>
                      <td>{item.quantidade}</td>
                      <td>{isConferido ? (item.quantidadeConferida ?? item.quantidade) : '-'}</td>
                      <td>
                        {!isConferido ? (
                          <span className="badge badge-warning">Aguardando Conferência</span>
                        ) : isMatch ? (
                          <span style={{ color: '#10b981', display: 'inline-flex', alignItems: 'center', gap: '4px', fontWeight: 600 }}>
                            <CheckCircle size={16} /> OK
                          </span>
                        ) : (
                          <span style={{ color: '#eab308', display: 'inline-flex', alignItems: 'center', gap: '4px', fontWeight: 600 }} title={item.justificativa || 'Divergência de quantidade'}>
                            <AlertCircle size={16} /> {item.justificativa ? item.justificativa : `Divergência (${item.quantidadeConferida ?? 0}/${item.quantidade})`}
                          </span>
                        )}
                      </td>
                      <td>R$ {Number(item.valor).toFixed(2)}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* SUBTAB: ENVIAR TRANSFERÊNCIA (NOVA) */}
      {activeSubTab === 'new' && (
        <div className="list-card glass">
          <h3><Send size={20} /> Registrar Novo Envio de Estoque</h3>
          
          <form onSubmit={handleCreateTransfer} className="cd-form">
            <div className="grid-2">
              <label className="cd-input-container">
                Unidade de Origem (Remetente)
                <select value={origin} onChange={(e) => setOrigin(e.target.value)} className="cd-select" required>
                  <option value="">Selecione...</option>
                  {units.map(u => <option key={u.id} value={u.id}>{u.name}</option>)}
                </select>
              </label>

              <label className="cd-input-container">
                Unidade de Destino (Destinatário)
                <select value={destination} onChange={(e) => setDestination(e.target.value)} className="cd-select" required>
                  <option value="">Selecione...</option>
                  {units.map(u => <option key={u.id} value={u.id}>{u.name}</option>)}
                </select>
              </label>
            </div>

            {/* SELEÇÃO FISCAL VS NÃO FISCAL */}
            <div style={{ background: 'rgba(255, 255, 255, 0.7)', padding: '1rem', borderRadius: '10px', border: '1px solid rgba(0, 0, 0, 0.08)', margin: '0.5rem 0 1rem 0' }}>
              <label style={{ fontWeight: 600, display: 'block', marginBottom: '0.6rem', color: 'var(--text-primary)' }}>
                Tipo de Transferência de Estoque *
              </label>
              <div style={{ display: 'flex', gap: '1.5rem', flexWrap: 'wrap', marginBottom: tipoFiscal === 'FISCAL' ? '1rem' : '0' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', cursor: 'pointer', fontWeight: 500 }}>
                  <input 
                    type="radio" 
                    name="tipoFiscal" 
                    value="FISCAL" 
                    checked={tipoFiscal === 'FISCAL'} 
                    onChange={() => setTipoFiscal('FISCAL')} 
                  />
                  📄 <strong>Fiscal (Com NF-e de Transferência)</strong>
                </label>
                <label style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', cursor: 'pointer', fontWeight: 500 }}>
                  <input 
                    type="radio" 
                    name="tipoFiscal" 
                    value="NAO_FISCAL" 
                    checked={tipoFiscal === 'NAO_FISCAL'} 
                    onChange={() => setTipoFiscal('NAO_FISCAL')} 
                  />
                  📦 <strong>Não Fiscal (Produtos comprados Sem Nota / Interna)</strong>
                </label>
              </div>

              {tipoFiscal === 'FISCAL' && (
                <div style={{ marginTop: '0.75rem' }}>
                  <div className="grid-2">
                    <label className="cd-input-container">
                      Número da Nota Fiscal (NF-e)
                      <input 
                        type="text" 
                        value={numeroNf} 
                        onChange={(e) => setNumeroNf(e.target.value)} 
                        placeholder="Ex: 000.124.890" 
                        className="cd-text-input" 
                      />
                    </label>
                    <label className="cd-input-container">
                      Chave de Acesso da NF-e (44 Dígitos)
                      <input 
                        type="text" 
                        value={chaveNfe} 
                        onChange={(e) => setChaveNfe(e.target.value)} 
                        placeholder="3523..." 
                        maxLength={44} 
                        className="cd-text-input" 
                      />
                    </label>
                  </div>
                  <div style={{ marginTop: '0.65rem', display: 'flex', gap: '0.75rem', justifyContent: 'flex-end', flexWrap: 'wrap' }}>
                    <button 
                      type="button" 
                      onClick={handleFetchNfItems}
                      disabled={loadingNf}
                      style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '8px',
                        background: 'linear-gradient(135deg, #2563eb, #3b82f6)',
                        color: '#ffffff',
                        border: 'none',
                        padding: '0.6rem 1.2rem',
                        borderRadius: '8px',
                        cursor: 'pointer',
                        fontWeight: 600,
                        fontSize: '0.88rem',
                        boxShadow: '0 2px 6px rgba(37, 99, 235, 0.3)'
                      }}
                    >
                      {loadingNf ? '⌛ Processando...' : '📥 Puxar Itens da Nota de Compra'}
                    </button>

                    <button 
                      type="button" 
                      onClick={handleEmitTransferNfe}
                      disabled={loadingNf}
                      style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '8px',
                        background: 'linear-gradient(135deg, #10b981, #059669)',
                        color: '#ffffff',
                        border: 'none',
                        padding: '0.6rem 1.2rem',
                        borderRadius: '8px',
                        cursor: 'pointer',
                        fontWeight: 600,
                        fontSize: '0.88rem',
                        boxShadow: '0 2px 6px rgba(16, 185, 129, 0.3)'
                      }}
                    >
                      {loadingNf ? '⌛ Transmitindo SEFAZ...' : '⚡ Emitir Nova NF-e via SEFAZ'}
                    </button>
                  </div>
                </div>
              )}
            </div>

            <label className="cd-input-container">
              Observações gerais
              <input 
                type="text" 
                value={obs} 
                onChange={(e) => setObs(e.target.value)} 
                placeholder="Ex: Envio de mercadorias entre filiais" 
                className="cd-text-input" 
              />
            </label>

            {/* Adicionar Itens */}
            <div className="cd-add-item-box">
              <h4>Adicionar Produtos ao Lote</h4>
              <div className="grid-3">
                <div className="cd-input-container">
                  <label>Produto Selecionado *</label>
                  <button
                    type="button"
                    onClick={() => setShowProductSearchModal(true)}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justify: 'space-between',
                      padding: '0.65rem 0.9rem',
                      backgroundColor: '#ffffff',
                      border: '1px solid rgba(0, 0, 0, 0.15)',
                      borderRadius: '8px',
                      color: selectedProduct ? 'var(--text-primary)' : '#6b7280',
                      fontWeight: selectedProduct ? 600 : 400,
                      cursor: 'pointer',
                      fontSize: '0.88rem',
                      width: '100%',
                      textAlign: 'left'
                    }}
                  >
                    <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {selectedProduct ? (
                        (() => {
                          const p = products.find(prod => prod.codigo === Number(selectedProduct));
                          return p ? `#${p.codigo} - ${p.nome}` : 'Produto Selecionado';
                        })()
                      ) : (
                        '🔍 Buscar produto no estoque (Popup)...'
                      )}
                    </span>
                    <Search size={16} style={{ color: 'var(--accent-primary)', flexShrink: 0, marginLeft: '6px' }} />
                  </button>
                </div>

                <label className="cd-input-container">
                  Quantidade
                  <input 
                    type="number" 
                    value={quantity} 
                    onChange={(e) => setQuantity(e.target.value)} 
                    placeholder="Qtd" 
                    className="cd-text-input" 
                  />
                </label>

                <label className="cd-input-container">
                  Preço Venda Unitário
                  <input 
                    type="number" 
                    value={price} 
                    onChange={(e) => setPrice(e.target.value)} 
                    placeholder="Valor" 
                    className="cd-text-input" 
                  />
                </label>
              </div>
              <button type="button" className="add-item-btn" onClick={handleAddItemToTransfer}>
                + Adicionar Produto no Lote
              </button>
            </div>

            {/* Lista Temporária de Itens da Nova Transferência */}
            {transferItems.length > 0 && (
              <div className="cd-temp-items-list">
                <h5>Produtos Prontos para Envio</h5>
                <table className="temp-table">
                  <thead>
                    <tr>
                      <th>Produto</th>
                      <th>Quantidade</th>
                      <th>Valor Unitário</th>
                      <th>Ações</th>
                    </tr>
                  </thead>
                  <tbody>
                    {transferItems.map((item, idx) => (
                      <tr key={idx}>
                        <td>{item.nome}</td>
                        <td>{item.quantidade}</td>
                        <td>R$ {Number(item.valor).toFixed(2)}</td>
                        <td>
                          <button 
                            type="button" 
                            className="remove-temp-btn" 
                            onClick={() => handleRemoveItemFromTransfer(item.produto_id)}
                          >
                            Remover
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}

            <button type="submit" className="submit-transfer-btn" disabled={loading}>
              Enviar Transferência (Mudar Status para "Em Trânsito")
            </button>
          </form>
        </div>
      )}

      {/* SUBTAB: CONFERÊNCIA DE RECEBIMENTO */}
      {activeSubTab === 'reception' && receptionTransfer && (
        <div className="list-card glass">
          <h3><ShieldCheck size={20} /> Conferência física e Recebimento de Carga</h3>
          <p>Você está recebendo mercadorias destinadas a <strong>{getUnitName(receptionTransfer.destino)}</strong> vindas da unidade <strong>{getUnitName(receptionTransfer.origem)}</strong>.</p>
          
          <div className="cd-form">
            <label className="cd-input-container" style={{ marginBottom: '1.5rem' }}>
              Nome Completo do Conferente / Responsável pela Validação
              <input 
                type="text" 
                value={checkerName} 
                onChange={(e) => setCheckerName(e.target.value)} 
                placeholder="Ex: João da Silva (Gerente)" 
                className="cd-text-input" 
                required
              />
            </label>

            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Produto</th>
                    <th>Qtd Enviada</th>
                    <th>Qtd Conferida (Fisicamente Recebida)</th>
                    <th>Status / Justificativa (Divergência)</th>
                  </tr>
                </thead>
                <tbody>
                  {receptionItems.map((item, idx) => {
                    const prod = products.find(p => p.codigo === item.produtoId);
                    const isMatch = Number(item.quantidadeConferida) === Number(item.quantidade);

                    return (
                      <tr key={item.id || idx}>
                        <td>{prod ? prod.nome : `Produto ID ${item.produtoId}`}</td>
                        <td><strong>{item.quantidade}</strong></td>
                        <td>
                          <input 
                            type="number" 
                            value={item.quantidadeConferida} 
                            onChange={(e) => handleQtyConferidaChange(idx, e.target.value)}
                            className="cd-inline-input"
                            style={{ width: '90px' }}
                          />
                        </td>
                        <td>
                          {isMatch ? (
                            <span style={{ color: '#10b981', display: 'inline-flex', alignItems: 'center', gap: '4px', fontWeight: 600 }}>
                              <CheckCircle size={16} /> OK (Quantidade Correta)
                            </span>
                          ) : (
                            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                              <AlertCircle size={16} style={{ color: '#eab308', flexShrink: 0 }} />
                              <input 
                                type="text" 
                                value={item.justificativa || ''} 
                                onChange={(e) => handleJustificativaChange(idx, e.target.value)}
                                placeholder="Motivo/Justificativa da divergência..."
                                className="cd-text-input"
                                style={{ padding: '4px 8px', fontSize: '0.82rem' }}
                              />
                            </div>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            <label className="cd-input-container" style={{ marginTop: '1.25rem' }}>
              Observações Gerais sobre a Recepção (Caso haja divergência ou rejeição)
              <input 
                type="text" 
                value={receptionObs} 
                onChange={(e) => setReceptionObs(e.target.value)} 
                placeholder="Ex: 2 itens vieram com defeito na embalagem..." 
                className="cd-text-input" 
              />
            </label>

            <div className="cd-action-row" style={{ marginTop: '2rem', display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
              <button 
                type="button" 
                className="submit-transfer-btn" 
                onClick={() => handleApproveReception('Conferido/Aprovado')}
                disabled={loading}
                style={{ background: 'linear-gradient(135deg, #10b981, #059669)', flex: 1 }}
              >
                <CheckCircle size={18} /> Aceitar Total (Estoque 100% OK)
              </button>

              <button 
                type="button" 
                className="submit-transfer-btn" 
                onClick={() => handleApproveReception('Aceito Parcialmente')}
                disabled={loading}
                style={{ background: 'linear-gradient(135deg, #f59e0b, #d97706)', flex: 1 }}
              >
                <AlertCircle size={18} /> Aceitar em Partes (Com Divergências)
              </button>

              <button 
                type="button" 
                className="submit-transfer-btn reject" 
                onClick={() => handleApproveReception('Rejeitado')}
                disabled={loading}
                style={{ flex: 1 }}
              >
                <XCircle size={18} /> Rejeitar Carga / Devolver
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL POPUP DE BUSCA DE PRODUTOS PARA TRANSFERÊNCIA (IGUAL À TELA PRODUTOS) */}
      {showProductSearchModal && createPortal(
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setShowProductSearchModal(false); }}>
          <div className="modal-content glass" style={{ maxWidth: '900px', width: '92vw' }}>
            <div className="modal-header">
              <h4><Package size={20} style={{ color: 'var(--accent-primary)' }} /> Selecionar Produto do Estoque</h4>
              <button className="btn-close" onClick={() => setShowProductSearchModal(false)}><X size={18} /></button>
            </div>

            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '1rem', padding: '1rem 0' }}>
              <SearchBar
                value={modalSearchTerm}
                onChange={(val) => setModalSearchTerm(val)}
                onSearch={() => {}}
                onClear={() => setModalSearchTerm('')}
                placeholder="Buscar por nome, fabricante, código de barras..."
              />

              <div className="filter-bar" style={{ margin: 0 }}>
                <button className={`filter-btn ${modalStockFilter === 'todos' ? 'active' : ''}`} onClick={() => setModalStockFilter('todos')}>Todos</button>
                <button className={`filter-btn ${modalStockFilter === 'low' ? 'active' : ''}`} onClick={() => setModalStockFilter('low')}>Quase Acabando</button>
                <button className={`filter-btn ${modalStockFilter === 'out' ? 'active' : ''}`} onClick={() => setModalStockFilter('out')}>Sem Estoque</button>
              </div>

              <div className="table-responsive" style={{ maxHeight: '380px', overflowY: 'auto' }}>
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Código</th>
                      <th>Nome</th>
                      <th>Fabricante</th>
                      <th>Cód. Barras</th>
                      <th>Estoque Geral</th>
                      <th>Valor (Venda)</th>
                      <th>Ações</th>
                    </tr>
                  </thead>
                  <tbody>
                    {modalSearchLoading ? (
                      <tr>
                        <td colSpan="7" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                          ⌛ Buscando produtos no servidor central...
                        </td>
                      </tr>
                    ) : modalProducts.length === 0 ? (
                      <tr>
                        <td colSpan="7" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                          Nenhum produto encontrado.
                        </td>
                      </tr>
                    ) : (
                      modalProducts.map(p => (
                        <tr key={p.codigo} style={{ cursor: 'pointer' }} onClick={() => handleSelectProductFromModal(p)}>
                          <td><span className="item-code">#{p.codigo}</span></td>
                          <td><strong>{p.nome}</strong></td>
                          <td>{p.fabricante || '-'}</td>
                          <td>{p.codbarra || '-'}</td>
                          <td>
                            <span className={`badge ${p.quantidade > 5 ? 'badge-success' : p.quantidade > 0 ? 'badge-warning' : 'badge-danger'}`}>
                              {p.quantidade || 0}
                            </span>
                          </td>
                          <td><strong style={{ color: 'var(--accent-primary)' }}>{formatCurrency(p.valorv || 0)}</strong></td>
                          <td>
                            <button type="button" className="btn-primary" style={{ padding: '4px 10px', fontSize: '0.8rem' }}>
                              + Selecionar
                            </button>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>

              <Pagination
                currentPage={modalSearchMeta.page || modalSearchPage}
                totalPages={modalSearchMeta.pages || 1}
                onPageChange={handleModalPageChange}
              />
            </div>

            <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '1rem' }}>
              <button type="button" className="btn-secondary" onClick={() => setShowProductSearchModal(false)}>Fechar</button>
            </div>
          </div>
        </div>,
        document.body
      )}

    </div>
  );
}
