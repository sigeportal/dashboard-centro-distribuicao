import { useState, useEffect } from 'react';
import { ArrowRightLeft, Plus, CheckCircle, AlertCircle, Eye, RefreshCw, Send, ShieldCheck, XCircle } from 'lucide-react';
import { createApi } from '../../services/api';
import './TransferTab.css';

export default function TransferTab() {
  const api = createApi(true); // Conecta na CD_API_BASE (port 9000)
  const [activeSubTab, setActiveSubTab] = useState('list'); // 'list', 'new', 'reception'
  const [loading, setLoading] = useState(false);
  const [transfers, setTransfers] = useState([]);
  const [products, setProducts] = useState([]);
  const [units, setUnits] = useState([]);
  
  // Detalhes da Transferência Selecionada
  const [selectedTransfer, setSelectedTransfer] = useState(null);
  const [selectedTransferItems, setSelectedTransferItems] = useState([]);
  const [isViewingDetails, setIsViewingDetails] = useState(false);

  // Nova Transferência
  const [origin, setOrigin] = useState('');
  const [destination, setDestination] = useState('');
  const [obs, setObs] = useState('');
  const [transferItems, setTransferItems] = useState([]); // { produto_id, quantidade, valor }
  
  // Inputs da linha de item temporário
  const [selectedProduct, setSelectedProduct] = useState('');
  const [quantity, setQuantity] = useState('');
  const [price, setPrice] = useState('');

  // Conferência de Recebimento
  const [receptionTransfer, setReceptionTransfer] = useState(null);
  const [receptionItems, setReceptionItems] = useState([]); // { item, checked_qty }
  const [checkerName, setCheckerName] = useState('');

  // Notificações
  const [notifications, setNotifications] = useState([]);

  useEffect(() => {
    fetchTransfers();
    fetchProducts();
    fetchUnits();
  }, []);

  // Notifica o gestor sobre transferências direcionadas pendentes de conferência
  useEffect(() => {
    if (transfers.length > 0) {
      const activeUnitId = Number(localStorage.getItem('selected_company_id')) || 1;
      const pendingReception = transfers.filter(
        t => t.destino === activeUnitId && t.status === 'Em Trânsito'
      );
      
      const newNotifications = pendingReception.map(t => ({
        id: t.id,
        message: `Atenção: Nova transferência #${t.id} pendente de recepção e conferência na sua unidade!`,
        type: 'warning'
      }));

      // Notifica se a matriz aprovou uma das nossas transferências enviadas
      const approvedSent = transfers.filter(
        t => t.origem === activeUnitId && t.status === 'Conferido/Aprovado'
      );

      approvedSent.forEach(t => {
        newNotifications.push({
          id: `app-${t.id}`,
          message: `Sucesso: Unidade de destino confirmou o recebimento da transferência #${t.id}!`,
          type: 'success'
        });
      });

      setNotifications(newNotifications);
    }
  }, [transfers]);

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
      const response = await api.get('/v1/produtos');
      if (Array.isArray(response.data)) {
        setProducts(response.data);
      }
    } catch (err) {
      console.error('Erro ao buscar produtos para transferência:', err);
    }
  };

  const fetchUnits = async () => {
    try {
      const response = await api.get('/v1/empresa');
      if (Array.isArray(response.data)) {
        const formattedUnits = response.data.map(u => ({
          id: u.codigo || u.Codigo,
          name: `${u.codigo || u.Codigo} - ${u.fantasia || u.Fantasia || u.razao_social || u.Razao_social || 'Unidade'}`,
          ccCodigo: u.ccCodigo || u.CcCodigo
        }));
        setUnits(formattedUnits);
      }
    } catch (err) {
      console.error('Erro ao buscar unidades (empresas):', err);
    }
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
        dataRecebimento: '1899-12-30' // Data padrão nula Delphi
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

      alert('Transferência enviada com sucesso!');
      
      // Reset formulário
      setOrigin('');
      setDestination('');
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
          quantidadeConferida: item.quantidade // Preenche inicialmente com a enviada
        })));
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

  const handleApproveReception = async (status) => {
    if (!checkerName.trim()) {
      alert('Por favor, informe o nome do conferente/responsável.');
      return;
    }

    setLoading(true);
    try {
      // 1. Atualiza cabeçalho de transferência com Status, conferente e data
      const updatedHeader = {
        ...receptionTransfer,
        status: status, // 'Conferido/Aprovado' ou 'Rejeitado'
        usuarioRecebimento: checkerName,
        dataRecebimento: new Date().toISOString().split('T')[0]
      };
      await api.put('/v1/transferencias', updatedHeader);

      // 2. Atualiza os itens com a quantidade fisicamente conferida
      await api.post('/v1/transferenciaItens/emLote', { itens: receptionItems });

      alert(status === 'Conferido/Aprovado' ? 'Recepção concluída e estoque atualizado com sucesso!' : 'Transferência Recusada!');
      
      // Reset
      setReceptionTransfer(null);
      setReceptionItems([]);
      setCheckerName('');
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
        <div className="cd-notifications-bar">
          {notifications.map((n, idx) => (
            <div key={idx} className={`cd-notification ${n.type}`}>
              {n.type === 'warning' ? <AlertCircle size={20} /> : <CheckCircle size={20} />}
              <span>{n.message}</span>
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
                    <td>{getUnitName(item.origem)}</td>
                    <td>{getUnitName(item.destino)}</td>
                    <td>{item.data}</td>
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
              <p><strong>Data Recepção:</strong> {selectedTransfer.dataRecebimento !== '1899-12-30' ? selectedTransfer.dataRecebimento : '-'}</p>
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
                  <th>Valor Unitário</th>
                </tr>
              </thead>
              <tbody>
                {selectedTransferItems.map((item, idx) => {
                  const prod = products.find(p => p.codigo === item.produtoId);
                  return (
                    <tr key={item.id || idx}>
                      <td>#{item.id}</td>
                      <td>{prod ? prod.nome : `Produto ID ${item.produtoId}`}</td>
                      <td>{item.quantidade}</td>
                      <td>{selectedTransfer.status === 'Conferido/Aprovado' ? item.quantidadeConferida : '-'}</td>
                      <td>R$ {item.valor.toFixed(2)}</td>
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

            <label className="cd-input-container">
              Observações gerais
              <input 
                type="text" 
                value={obs} 
                onChange={(e) => setObs(e.target.value)} 
                placeholder="Ex: Envio emergencial de grade de vestuário" 
                className="cd-text-input" 
              />
            </label>

            {/* Adicionar Itens */}
            <div className="cd-add-item-box">
              <h4>Adicionar Produtos ao Lote</h4>
              <div className="grid-3">
                <label className="cd-input-container">
                  Produto
                  <select 
                    value={selectedProduct} 
                    onChange={(e) => {
                      setSelectedProduct(e.target.value);
                      const prod = products.find(p => p.codigo === Number(e.target.value));
                      if (prod) setPrice(prod.valorv || '');
                    }} 
                    className="cd-select"
                  >
                    <option value="">Selecione um produto...</option>
                    {products.map(p => (
                      <option key={p.codigo} value={p.codigo}>
                        {p.nome} (Cod: #{p.codigo})
                      </option>
                    ))}
                  </select>
                </label>

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
                  </tr>
                </thead>
                <tbody>
                  {receptionItems.map((item, idx) => {
                    const prod = products.find(p => p.codigo === item.produtoId);
                    return (
                      <tr key={item.id || idx}>
                        <td>{prod ? prod.nome : `Produto ID ${item.produtoId}`}</td>
                        <td>{item.quantidade}</td>
                        <td>
                          <input 
                            type="number" 
                            value={item.quantidadeConferida} 
                            onChange={(e) => handleQtyConferidaChange(idx, e.target.value)}
                            className="cd-inline-input"
                          />
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            <div className="cd-action-row" style={{ marginTop: '2rem', display: 'flex', gap: '1rem' }}>
              <button 
                type="button" 
                className="submit-transfer-btn" 
                onClick={() => handleApproveReception('Conferido/Aprovado')}
                disabled={loading}
              >
                <CheckCircle size={18} /> Confirmar Recebimento & Incrementar Estoque
              </button>
              <button 
                type="button" 
                className="submit-transfer-btn reject" 
                onClick={() => handleApproveReception('Rejeitado')}
                disabled={loading}
              >
                <XCircle size={18} /> Rejeitar Carga / Devolver
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
