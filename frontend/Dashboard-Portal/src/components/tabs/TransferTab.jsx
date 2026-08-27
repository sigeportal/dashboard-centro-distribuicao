import { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { 
  ArrowRightLeft, Plus, CheckCircle, AlertCircle, Eye, RefreshCw, Send, 
  ShieldCheck, XCircle, Search, Package, X, Printer, FileText, Barcode, 
  Trash2, Edit2, Layers, Check, ShoppingBag, Truck, Sparkles, Filter, ChevronRight,
  Building2
} from 'lucide-react';
import { createApi } from '../../services/api';
import SearchBar from '../SearchBar';
import Pagination from '../Pagination';
import LookupSelect from '../LookupSelect';
import RomaneioModal from '../RomaneioModal';
import NfeTransferModal from '../NfeTransferModal';
import { formatCurrency, formatDate } from '../../utils/formatters';
import './TransferTab.css';

export default function TransferTab() {
  const api = createApi(true); // Conecta na CD_API_BASE (port 9000)
  const [activeSubTab, setActiveSubTab] = useState('list'); // 'list', 'new', 'reception'
  const defaultUnitsList = [
    { id: 5, name: '5 - CD DOURADINA (Matriz)', isCd: true, isMatriz: true },
    { id: 6, name: '6 - RIO BRILHANTE', isCd: false, isMatriz: false },
    { id: 7, name: '7 - ITAPORA', isCd: false, isMatriz: false },
    { id: 4, name: '4 - NOVA ALVORADA', isCd: false, isMatriz: false },
    { id: 8, name: '8 - MARACAJU', isCd: false, isMatriz: false }
  ];

  const [loading, setLoading] = useState(false);
  const [transfers, setTransfers] = useState([]);
  const [products, setProducts] = useState([]);
  const [units, setUnits] = useState(defaultUnitsList);
  
  // Detalhes da Transferência Selecionada
  const [selectedTransfer, setSelectedTransfer] = useState(null);
  const [selectedTransferItems, setSelectedTransferItems] = useState([]);
  const [isViewingDetails, setIsViewingDetails] = useState(false);

  // Modal de Romaneio de Transferência (Impressão / Guia A4)
  const [showRomaneioModal, setShowRomaneioModal] = useState(false);
  const [romaneioTransfer, setRomaneioTransfer] = useState(null);
  const [romaneioItems, setRomaneioItems] = useState([]);

  // Modal de Emissão e Visualização de NF-e de Transferência
  const [showNfeModal, setShowNfeModal] = useState(false);
  const [nfeTransfer, setNfeTransfer] = useState(null);
  const [nfeItems, setNfeItems] = useState([]);

  // =========================================================================
  // ESTADO DO NOVO ROMANEIO DE TRANSFERÊNCIA (Criação com Total Liberdade)
  // =========================================================================
  const [origin, setOrigin] = useState('5'); // Padrão: 5 - CD DOURADINA (Matriz)
  const [destination, setDestination] = useState('6'); // Padrão: 6 - RIO BRILHANTE
  const [dataEnvio, setDataEnvio] = useState(new Date().toISOString().split('T')[0]);
  const [motorista, setMotorista] = useState('');
  const [placaVeiculo, setPlacaVeiculo] = useState('');
  const [obs, setObs] = useState('');
  const [transferItems, setTransferItems] = useState([]); // [{ produto_id, nome, codbarra, grade_id, tamanho, cor, quantidade, valor, pro_cod_fiscal, pro_fiscal_gerar, isFiscal }]

  // Seleção rápida de produto atual para o Romaneio
  const [selectedProductObj, setSelectedProductObj] = useState(null);
  const [productGrades, setProductGrades] = useState([]);
  const [selectedProductStock, setSelectedProductStock] = useState(0);
  const [matrixQuantities, setMatrixQuantities] = useState({}); // { [gradeId]: number }
  const [singleQty, setSingleQty] = useState(1);
  const [singlePrice, setSinglePrice] = useState('');
  const [loadingGrades, setLoadingGrades] = useState(false);

  // Bipagem rápida via Código de Barras / EAN
  const [barcodeInput, setBarcodeInput] = useState('');
  const barcodeInputRef = useRef(null);

  // Puxar itens de Compra / NF-e
  const [nfSearchTerm, setNfSearchTerm] = useState('');
  const [loadingNf, setLoadingNf] = useState(false);
  const [showNfImportBox, setShowNfImportBox] = useState(false);

  // Conferência de Recebimento na Filial (Conferência Cega)
  const [receptionTransfer, setReceptionTransfer] = useState(null);
  const [receptionItems, setReceptionItems] = useState([]);
  const [checkerName, setCheckerName] = useState('');
  const [receptionObs, setReceptionObs] = useState('');
  const [blindCheckRevealed, setBlindCheckRevealed] = useState(false); // true = mostra divergências

  // Notificações
  const [notifications, setNotifications] = useState([]);
  const [successMsg, setSuccessMsg] = useState('');

  useEffect(() => {
    fetchTransfers();
    fetchProducts();
    fetchUnits();
  }, []);

  const fetchTransfers = async () => {
    setLoading(true);
    try {
      const response = await api.get('/v1/transferencias');
      if (Array.isArray(response.data)) {
        const activeUnitId = Number(localStorage.getItem('selected_company_id')) || 5;
        // O CD MATRIZ DOURADINA (ID 5 ou 1) visualiza todas as transferências do grupo
        const isMatriz = activeUnitId === 5 || activeUnitId === 1;
        const visibleTransfers = isMatriz
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
      const response = await api.get('/v1/produtos?limit=1000');
      if (Array.isArray(response.data)) {
        setProducts(response.data);
      } else if (response.data?.data && Array.isArray(response.data.data)) {
        setProducts(response.data.data);
      }
    } catch (err) {
      console.error('Erro ao buscar produtos:', err);
    }
  };

  const fetchUnits = async () => {
    try {
      const response = await api.get('/v1/empresa');
      const unitMap = new Map();

      const fallbackCities = {
        5: 'DOURADINA',
        1: 'DOURADINA',
        6: 'RIO BRILHANTE',
        7: 'ITAPORÃ',
        4: 'NOVA ALVORADA DO SUL',
        8: 'MARACAJU'
      };

      // Mapeamento das 5 unidades reais
      if (Array.isArray(response.data) && response.data.length > 0) {
        response.data.forEach(u => {
          const rawName = (u.fantasia || u.Fantasia || u.razao_social || u.Razao_social || '').trim().toUpperCase();
          const code = Number(u.codigo || u.Codigo || u.id);
          const isMatriz = code === 5 || code === 1 || rawName.includes('CD') || rawName.includes('DOURADINA') || rawName.includes('MATRIZ');
          const city = (u.municipio || u.Municipio || u.EMP_MUNICIPIO || u.emp_municipio || fallbackCities[code] || '').trim().toUpperCase();

          let displayName = `${code} - ${rawName}${city ? ` (${city})` : ''}`;
          if (isMatriz) {
            displayName = `5 - ${rawName || 'CD DOURADINA'}${city ? ` (${city})` : ' (DOURADINA)'} [CD MATRIZ]`;
          }

          unitMap.set(isMatriz ? 5 : code, {
            id: isMatriz ? 5 : code,
            name: displayName,
            city: city,
            isCd: isMatriz,
            isMatriz: isMatriz
          });
        });
      }

      // Garante a presença das 5 unidades oficiais
      if (!unitMap.has(5)) unitMap.set(5, { id: 5, name: '5 - CD DOURADINA (DOURADINA) [CD MATRIZ]', city: 'DOURADINA', isCd: true, isMatriz: true });
      if (!unitMap.has(6)) unitMap.set(6, { id: 6, name: '6 - GIGANTE (RIO BRILHANTE)', city: 'RIO BRILHANTE', isCd: false, isMatriz: false });
      if (!unitMap.has(7)) unitMap.set(7, { id: 7, name: '7 - GIGANTE (ITAPORÃ)', city: 'ITAPORÃ', isCd: false, isMatriz: false });
      if (!unitMap.has(4)) unitMap.set(4, { id: 4, name: '4 - GIGANTE (NOVA ALVORADA DO SUL)', city: 'NOVA ALVORADA DO SUL', isCd: false, isMatriz: false });
      if (!unitMap.has(8)) unitMap.set(8, { id: 8, name: '8 - GIGANTE (MARACAJU)', city: 'MARACAJU', isCd: false, isMatriz: false });

      const finalUnits = Array.from(unitMap.values());
      finalUnits.sort((a, b) => (b.isMatriz ? 1 : 0) - (a.isMatriz ? 1 : 0));

      setUnits(finalUnits);
      setOrigin('5');
      if (!destination || destination === '5') {
        setDestination('6');
      }
    } catch (err) {
      console.error('Erro ao buscar unidades (empresas):', err);
    }
  };

  const getUnitName = (id) => {
    const numId = Number(id);
    if (numId === 1 || numId === 5) return '5 - CD DOURADINA (Matriz)';
    const unit = units.find(u => Number(u.id) === numId);
    if (unit) return unit.name;
    const fallbackMap = {
      4: '4 - NOVA ALVORADA',
      5: '5 - CD DOURADINA (Matriz)',
      6: '6 - RIO BRILHANTE',
      7: '7 - ITAPORA',
      8: '8 - MARACAJU'
    };
    return fallbackMap[numId] || `Unidade #${id}`;
  };

  // =========================================================================
  // SELEÇÃO DE PRODUTO & CARREGAMENTO DE GRADES (TAMANHOS/VARIAÇÕES)
  // =========================================================================
  const handleSelectProduct = async (prod) => {
    if (!prod) {
      setSelectedProductObj(null);
      setProductGrades([]);
      setMatrixQuantities({});
      setSelectedProductStock(0);
      return;
    }

    setSelectedProductObj(prod);
    const pId = Number(prod.codigo || prod.PRO_CODIGO);
    const defaultPrice = Number(prod.valorv || prod.custo || prod.pro_valor_dinheiro || 0);
    setSinglePrice(defaultPrice > 0 ? String(defaultPrice) : '0.00');
    setSingleQty(1);
    setMatrixQuantities({});

    setLoadingGrades(true);
    try {
      // 1. Busca posição de estoque por filial para extrair o saldo real da unidade de origem
      let originStock = 0;
      try {
        const stockRes = await api.get(`/v1/estoque/posicao?pro_codigo=${pId}`);
        const stockArr = Array.isArray(stockRes.data) ? stockRes.data : (stockRes.data?.data || []);
        const originRow = stockArr.find(st => Number(st.empresa_id) === Number(origin));
        if (originRow) {
          originStock = Number(originRow.quantidade) || 0;
        } else {
          const isOriginCd = Number(origin) === 5 || Number(origin) === 1;
          if (isOriginCd) {
            originStock = Number(prod.quantidade || prod.pro_quantidade || prod.PRO_QUANTIDADE || 0);
          }
        }
      } catch (stkErr) {
        console.warn('Erro ao consultar estoque da unidade de origem:', stkErr);
      }
      setSelectedProductStock(originStock);

      // 2. Busca variações de grade do produto
      const res = await api.get(`/v1/grades?produto_id=${pId}`);
      if (Array.isArray(res.data) && res.data.length > 0) {
        // Exibe estritamente as grades com estoque disponível (> 0)
        const availableGrades = res.data.filter(g => Number(g.quantidade || g.gra_quantidade || 0) > 0);
        setProductGrades(availableGrades);
      } else {
        setProductGrades([]);
      }
    } catch (err) {
      console.warn('Produto sem variações de grade cadastradas:', err);
      setProductGrades([]);
    } finally {
      setLoadingGrades(false);
    }
  };

  // Recarrega o estoque caso a unidade de origem seja alterada
  useEffect(() => {
    if (selectedProductObj) {
      handleSelectProduct(selectedProductObj);
    }
  }, [origin]);

  const handleMatrixQtyChange = (gradeId, value) => {
    const val = parseInt(value, 10);
    setMatrixQuantities(prev => ({
      ...prev,
      [gradeId]: isNaN(val) || val < 0 ? 0 : val
    }));
  };

  // 1. Adicionar Variações da Grade ao Romaneio com Validação de Estoque
  const handleAddGradeMatrixToTransfer = () => {
    if (!selectedProductObj) return;

    const itemsToAdd = [];
    const pId = Number(selectedProductObj.codigo || selectedProductObj.PRO_CODIGO);
    const pNome = selectedProductObj.nome || selectedProductObj.PRO_NOME;
    const pFiscalGerar = selectedProductObj.pro_fiscal_gerar || selectedProductObj.fiscalGerar || 'S';
    const pCodFiscal = Number(selectedProductObj.pro_cod_fiscal || selectedProductObj.codFiscal || 0);
    const isFiscal = pFiscalGerar !== 'N' && (pCodFiscal > 0 || pFiscalGerar === 'S');

    for (const g of productGrades) {
      const gId = g.codigo || g.id || g.gra_codigo;
      const qtd = Number(matrixQuantities[gId] || 0);
      const maxGradeQty = Number(g.quantidade || g.gra_quantidade || 0);
      
      let tamNome = 'UN';
      if (typeof g.tamanho_str === 'string' && g.tamanho_str.trim()) {
        tamNome = g.tamanho_str.trim();
      } else if (typeof g.tam_nome === 'string' && g.tam_nome.trim()) {
        tamNome = g.tam_nome.trim();
      } else if (typeof g.sigla === 'string' && g.sigla.trim()) {
        tamNome = g.sigla.trim();
      } else if (g.tamanho && typeof g.tamanho === 'object') {
        tamNome = g.tamanho.sigla || g.tamanho.tamanho || 'UN';
      } else if (typeof g.tamanho === 'string' && g.tamanho.trim()) {
        tamNome = g.tamanho.trim();
      }

      if (qtd > 0) {
        const alreadyInRomaneio = transferItems
          .filter(it => it.produto_id === pId && it.grade_id === gId)
          .reduce((acc, it) => acc + Number(it.quantidade || 0), 0);

        if (alreadyInRomaneio + qtd > maxGradeQty) {
          alert(`A quantidade informada para o tamanho "${tamNome}" (${alreadyInRomaneio + qtd} UN) ultrapassa o estoque disponível (${maxGradeQty} UN) na unidade de origem.`);
          return;
        }

        const val = Number(g.valor || g.valor_dinheiro || singlePrice || selectedProductObj.valorv || selectedProductObj.custo || 0);
        itemsToAdd.push({
          produto_id: pId,
          nome: pNome,
          codbarra: g.codbarra || selectedProductObj.codbarra || '',
          grade_id: gId,
          tamanho: tamNome,
          cor: g.cor || 'UNICA',
          quantidade: qtd,
          max_disponivel: maxGradeQty,
          valor: val,
          pro_cod_fiscal: pCodFiscal,
          pro_fiscal_gerar: pFiscalGerar,
          isFiscal: isFiscal
        });
      }
    }

    if (itemsToAdd.length === 0) {
      alert('Informe ao menos uma quantidade em um dos tamanhos da grade com saldo disponível.');
      return;
    }

    setTransferItems(prev => [...prev, ...itemsToAdd]);
    setMatrixQuantities({});
    setSelectedProductObj(null);
    setProductGrades([]);
    setSuccessMsg(`${itemsToAdd.length} variação(ões) adicionada(s) ao Romaneio!`);
    setTimeout(() => setSuccessMsg(''), 3500);
  };

  // 2. Adicionar Produto Simples (Sem Grade) ao Romaneio com Validação de Estoque
  const handleAddSingleProductToTransfer = () => {
    if (!selectedProductObj) {
      alert('Selecione um produto antes de adicionar.');
      return;
    }
    const qtd = Number(singleQty);
    if (!qtd || qtd <= 0) {
      alert('Informe uma quantidade válida maior que 0.');
      return;
    }

    const pId = Number(selectedProductObj.codigo || selectedProductObj.PRO_CODIGO);
    const maxAvailable = selectedProductStock > 0 ? selectedProductStock : Number(selectedProductObj.quantidade || selectedProductObj.pro_quantidade || 0);

    if (maxAvailable <= 0) {
      alert(`O produto #${pId} não possui estoque disponível na unidade de origem selecionada (${getUnitName(origin)}).`);
      return;
    }

    const alreadyInRomaneio = transferItems
      .filter(it => it.produto_id === pId && (!it.grade_id || it.grade_id === 0))
      .reduce((acc, it) => acc + Number(it.quantidade || 0), 0);

    if (alreadyInRomaneio + qtd > maxAvailable) {
      alert(`A quantidade total informada (${alreadyInRomaneio + qtd} UN) ultrapassa o saldo disponível na unidade de origem (${maxAvailable} UN).`);
      return;
    }

    const pNome = selectedProductObj.nome || selectedProductObj.PRO_NOME;
    const pFiscalGerar = selectedProductObj.pro_fiscal_gerar || selectedProductObj.fiscalGerar || 'S';
    const pCodFiscal = Number(selectedProductObj.pro_cod_fiscal || selectedProductObj.codFiscal || 0);
    const isFiscal = pFiscalGerar !== 'N' && (pCodFiscal > 0 || pFiscalGerar === 'S');
    const val = Number(singlePrice) || Number(selectedProductObj.valorv || selectedProductObj.custo || 0);
    const singleTam = selectedProductObj.um || selectedProductObj.embalagem || 'UN';

    const newItem = {
      produto_id: pId,
      nome: pNome,
      codbarra: selectedProductObj.codbarra || '',
      grade_id: 0,
      tamanho: singleTam,
      cor: 'UNICA',
      quantidade: qtd,
      max_disponivel: maxAvailable,
      valor: val,
      pro_cod_fiscal: pCodFiscal,
      pro_fiscal_gerar: pFiscalGerar,
      isFiscal: isFiscal
    };

    setTransferItems(prev => [...prev, newItem]);
    setSelectedProductObj(null);
    setProductGrades([]);
    setSingleQty(1);
    setSuccessMsg(`Produto #${pId} - ${pNome} (${qtd} UN) adicionado ao Romaneio!`);
    setTimeout(() => setSuccessMsg(''), 3500);
  };

  // 3. Bipagem Rápida via Código de Barras com Validação
  const handleBarcodeScan = (e) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      const code = barcodeInput.trim();
      if (!code) return;

      const matchedProd = products.find(p => p.codbarra === code || String(p.codigo) === code);
      if (matchedProd) {
        const pId = Number(matchedProd.codigo);
        const maxStock = Number(matchedProd.quantidade || matchedProd.pro_quantidade || 0);

        const existingIdx = transferItems.findIndex(it => it.produto_id === pId && (!it.grade_id || it.grade_id === 0));
        const currentQty = existingIdx >= 0 ? transferItems[existingIdx].quantidade : 0;

        if (maxStock > 0 && currentQty + 1 > maxStock) {
          alert(`Estoque insuficiente na unidade de origem (${maxStock} UN disponíveis).`);
          setBarcodeInput('');
          return;
        }

        const pFiscalGerar = matchedProd.pro_fiscal_gerar || matchedProd.fiscalGerar || 'S';
        const pCodFiscal = Number(matchedProd.pro_cod_fiscal || matchedProd.codFiscal || 0);
        const isFiscal = pFiscalGerar !== 'N' && (pCodFiscal > 0 || pFiscalGerar === 'S');

        if (existingIdx >= 0) {
          setTransferItems(prev => {
            const next = [...prev];
            next[existingIdx].quantidade += 1;
            return next;
          });
        } else {
          setTransferItems(prev => [
            ...prev,
            {
              produto_id: pId,
              nome: matchedProd.nome,
              codbarra: matchedProd.codbarra,
              grade_id: 0,
              tamanho: matchedProd.um || 'UN',
              cor: 'UNICA',
              quantidade: 1,
              max_disponivel: maxStock > 0 ? maxStock : null,
              valor: Number(matchedProd.valorv || matchedProd.custo || 0),
              pro_cod_fiscal: pCodFiscal,
              pro_fiscal_gerar: pFiscalGerar,
              isFiscal: isFiscal
            }
          ]);
        }
        setSuccessMsg(`+1 UN adicionada: #${pId} - ${matchedProd.nome}`);
        setTimeout(() => setSuccessMsg(''), 2500);
      } else {
        alert(`Código de barras "${code}" não encontrado no catálogo do CD.`);
      }
      setBarcodeInput('');
    }
  };

  // 4. Puxar Itens de Nota de Compra / XML Recente
  const handleFetchNfItems = async () => {
    const term = nfSearchTerm.trim();
    if (!term) {
      alert('Informe o número da NF ou chave de acesso da compra.');
      return;
    }
    setLoadingNf(true);
    try {
      const res = await api.get(`/v1/compras/buscar-nf?termo=${encodeURIComponent(term)}`);
      const compraData = res.data;
      if (compraData && Array.isArray(compraData.itens) && compraData.itens.length > 0) {
        const importedItems = compraData.itens.map(it => {
          const pFiscalGerar = it.pro_fiscal_gerar || 'S';
          const pCodFiscal = Number(it.pro_cod_fiscal || 0);
          return {
            produto_id: Number(it.produto_codigo || it.produto_id),
            nome: it.produto_nome || `Produto #${it.produto_codigo}`,
            codbarra: it.codbarra || '',
            grade_id: 0,
            tamanho: it.um || 'UN',
            cor: 'UNICA',
            quantidade: Number(it.quantidade) || 1,
            valor: Number(it.valor_unitario) || 0,
            pro_cod_fiscal: pCodFiscal,
            pro_fiscal_gerar: pFiscalGerar,
            isFiscal: pFiscalGerar !== 'N' && (pCodFiscal > 0 || pFiscalGerar === 'S')
          };
        });

        setTransferItems(prev => [...prev, ...importedItems]);
        setShowNfImportBox(false);
        setNfSearchTerm('');
        setSuccessMsg(`Sucesso! ${importedItems.length} itens importados da NF de compra #${compraData.numero_nf || term}!`);
        setTimeout(() => setSuccessMsg(''), 4000);
      } else {
        alert('Nenhum item encontrado nesta Nota de Compra.');
      }
    } catch (err) {
      console.error('Erro ao buscar itens da NF:', err);
      alert('Nota de compra não localizada.');
    } finally {
      setLoadingNf(false);
    }
  };

  // Edição inline de itens na tabela do Romaneio com validação de limite
  const handleUpdateItemQty = (idx, newQty) => {
    let val = parseFloat(newQty);
    if (isNaN(val) || val <= 0) val = 1;
    setTransferItems(prev => {
      const next = [...prev];
      const item = next[idx];
      if (item && item.max_disponivel && val > item.max_disponivel) {
        alert(`A quantidade informada (${val} UN) ultrapassa o estoque disponível (${item.max_disponivel} UN) para este item.`);
        val = item.max_disponivel;
      }
      next[idx].quantidade = val;
      return next;
    });
  };

  const handleUpdateItemValor = (idx, newVal) => {
    const val = parseFloat(newVal);
    setTransferItems(prev => {
      const next = [...prev];
      next[idx].valor = isNaN(val) || val < 0 ? 0 : val;
      return next;
    });
  };

  const handleToggleItemFiscal = (idx) => {
    setTransferItems(prev => {
      const next = [...prev];
      next[idx].isFiscal = !next[idx].isFiscal;
      next[idx].pro_fiscal_gerar = next[idx].isFiscal ? 'S' : 'N';
      return next;
    });
  };

  const handleRemoveItemFromTransfer = (idx) => {
    setTransferItems(prev => prev.filter((_, i) => i !== idx));
  };

  // =========================================================================
  // CÁLCULOS E CLASSIFICAÇÃO AUTOMÁTICA EM TEMPO REAL
  // =========================================================================
  const totalPecas = transferItems.reduce((acc, it) => acc + (Number(it.quantidade) || 0), 0);
  const totalValor = transferItems.reduce((acc, it) => acc + ((Number(it.quantidade) || 0) * (Number(it.valor) || 0)), 0);

  const itensFiscais = transferItems.filter(it => it.isFiscal);
  const pecasFiscais = itensFiscais.reduce((acc, it) => acc + (Number(it.quantidade) || 0), 0);
  const valorFiscal = itensFiscais.reduce((acc, it) => acc + ((Number(it.quantidade) || 0) * (Number(it.valor) || 0)), 0);

  const itensFisicos = transferItems.filter(it => !it.isFiscal);
  const pecasFisicas = itensFisicos.reduce((acc, it) => acc + (Number(it.quantidade) || 0), 0);
  const valorFisico = itensFisicos.reduce((acc, it) => acc + ((Number(it.quantidade) || 0) * (Number(it.valor) || 0)), 0);

  // =========================================================================
  // SALVAR E EXPEDIR ROMANEIO DE TRANSFERÊNCIA
  // =========================================================================
  const handleCreateTransfer = async (e) => {
    if (e) e.preventDefault();

    if (!destination) {
      alert('Selecione a Filial de Destino da transferência.');
      return;
    }

    if (transferItems.length === 0) {
      alert('Adicione ao menos um produto no Romaneio antes de expedir.');
      return;
    }

    setLoading(true);
    try {
      const payload = {
        origem: Number(origin) || 5,
        destino: Number(destination),
        data: dataEnvio,
        status: 'Em Trânsito',
        obs: obs || `Romaneio de Envio (${totalPecas} un)`,
        tipoFiscal: pecasFiscais > 0 ? 'FISCAL' : 'NAO_FISCAL',
        numeroNf: '',
        chaveNfe: '',
        itens: transferItems.map(it => ({
          produto_id: it.produto_id,
          quantidade: it.quantidade,
          valor: it.valor,
          grade_id: it.grade_id || 0,
          tamanho: it.tamanho || 'UN',
          cor: it.cor || 'UNICA',
          pro_cod_fiscal: it.pro_cod_fiscal || 0,
          pro_fiscal_gerar: it.isFiscal ? 'S' : 'N'
        }))
      };

      const res = await api.post('/v1/transferencias', payload);
      const newTrId = Number(res.data?.id || res.data?.tr_id || res.data?.TR_ID || 1);

      setSuccessMsg(`Romaneio de Transferência #${newTrId} salvo e expedido com sucesso!`);
      setTimeout(() => setSuccessMsg(''), 5000);

      // Limpa formulário
      setTransferItems([]);
      setObs('');
      setMotorista('');
      setPlacaVeiculo('');
      setActiveSubTab('list');
      fetchTransfers();
    } catch (err) {
      console.error('Erro ao salvar romaneio:', err);
      alert('Erro ao salvar e expedir transferência.');
    } finally {
      setLoading(false);
    }
  };

  // Busca e enriquece os itens com a descrição real da grade (ex: P, M, G, GG, 38)
  const fetchAndEnrichTransferItems = async (transferId) => {
    try {
      const res = await api.get(`/v1/transferenciaItens?transferencia_id=${transferId}`);
      const rawItems = Array.isArray(res.data) ? res.data : (res.data?.data || []);

      const enriched = await Promise.all(rawItems.map(async (item) => {
        let sizeName = '';
        if (typeof item.tamanho === 'string' && item.tamanho.trim() && isNaN(Number(item.tamanho)) && item.tamanho !== '-') {
          sizeName = item.tamanho.trim();
        } else if (typeof item.tam_nome === 'string' && item.tam_nome.trim() && isNaN(Number(item.tam_nome)) && item.tam_nome !== '-') {
          sizeName = item.tam_nome.trim();
        } else if (typeof item.sigla === 'string' && item.sigla.trim() && isNaN(Number(item.sigla)) && item.sigla !== '-') {
          sizeName = item.sigla.trim();
        }

        // Se ainda não tiver o tamanho textual (ex: 'P', 'M', 'G', 'GG'), consulta as variações de grade do produto
        const pId = Number(item.produtoId || item.produto_id);
        if (!sizeName && pId > 0) {
          try {
            const gRes = await api.get(`/v1/grades?produto_id=${pId}`);
            const gList = Array.isArray(gRes.data) ? gRes.data : (gRes.data?.data || []);
            if (gList.length > 0) {
              const matchedGrade = gList.find(g => Number(g.codigo || g.id || g.gra_codigo) === Number(item.grade_id || item.gradeId));
              const chosen = matchedGrade || gList[0];
              if (chosen) {
                if (chosen.tamanho && typeof chosen.tamanho === 'object') {
                  sizeName = chosen.tamanho.sigla || chosen.tamanho.tamanho || chosen.tam_nome || '';
                } else if (chosen.tamanho_str) {
                  sizeName = chosen.tamanho_str;
                } else if (chosen.tam_nome) {
                  sizeName = chosen.tam_nome;
                } else if (chosen.sigla) {
                  sizeName = chosen.sigla;
                }
              }
            }
          } catch (e) {
            console.warn('Erro ao enriquecer tamanho da grade do item:', e);
          }
        }

        if (!sizeName) {
          const prod = products.find(p => Number(p.codigo) === pId);
          if (prod && prod.um && isNaN(Number(prod.um))) {
            sizeName = String(prod.um).trim();
          } else if (item.embalagem && isNaN(Number(item.embalagem))) {
            sizeName = String(item.embalagem).trim();
          } else {
            sizeName = 'UN';
          }
        }

        return {
          ...item,
          tamanho: sizeName,
          tam: sizeName,
          tam_nome: sizeName,
          sigla: sizeName
        };
      }));

      return enriched;
    } catch (err) {
      console.error('Erro ao buscar itens enriquecidos da transferência:', err);
      return [];
    }
  };

  // Visualização e Ações
  const handleViewDetails = async (transfer) => {
    setSelectedTransfer(transfer);
    setIsViewingDetails(true);
    setLoading(true);
    try {
      const items = await fetchAndEnrichTransferItems(transfer.id);
      setSelectedTransferItems(items);
    } catch (err) {
      setSelectedTransferItems([]);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenRomaneio = async (transfer) => {
    setRomaneioTransfer(transfer);
    setLoading(true);
    try {
      const items = await fetchAndEnrichTransferItems(transfer.id);
      setRomaneioItems(items);
      setShowRomaneioModal(true);
    } catch (err) {
      setRomaneioItems([]);
      setShowRomaneioModal(true);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenNfeModal = async (transfer) => {
    setNfeTransfer(transfer);
    setLoading(true);
    try {
      const items = await fetchAndEnrichTransferItems(transfer.id);
      setNfeItems(items);
      setShowNfeModal(true);
    } catch (err) {
      setNfeItems([]);
      setShowNfeModal(true);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenConference = async (transfer) => {
    setLoading(true);
    try {
      const items = await fetchAndEnrichTransferItems(transfer.id);
      if (items.length > 0) {
        setReceptionTransfer(transfer);
        setReceptionItems(items.map(item => ({
          ...item,
          quantidadeConferida: 0, // Conferência Cega: inicia em 0, conferente digita a contagem real
          justificativa: item.justificativa || ''
        })));
        setReceptionObs('');
        setBlindCheckRevealed(false); // Esconde divergências até o conferente revelar
        setActiveSubTab('reception');
      }
    } catch (err) {
      alert('Erro ao carregar itens para conferência.');
    } finally {
      setLoading(false);
    }
  };

  const handleApproveReception = async (status) => {
    if (!checkerName.trim()) {
      alert('Por favor, informe o nome do conferente/responsável pela conferência.');
      return;
    }

    setLoading(true);
    try {
      const updatedHeader = {
        ...receptionTransfer,
        status: status,
        usuarioRecebimento: checkerName,
        dataRecebimento: new Date().toISOString().split('T')[0],
        obs: receptionObs ? `${receptionTransfer.obs || ''} | Recepção: ${receptionObs}` : receptionTransfer.obs
      };
      await api.put('/v1/transferencias', updatedHeader);

      const formattedReceptionItems = receptionItems.map(it => ({
        ...it,
        quantidadeConferida: Number(it.quantidadeConferida ?? it.quantidade) || 0,
        justificativa: it.justificativa || ''
      }));
      await api.post('/v1/transferenciaItens/emLote', { itens: formattedReceptionItems });

      alert('Recepção concluída e estoque da filial atualizado com sucesso!');
      setReceptionTransfer(null);
      setReceptionItems([]);
      setCheckerName('');
      setReceptionObs('');
      setBlindCheckRevealed(false);
      setActiveSubTab('list');
      fetchTransfers();
    } catch (err) {
      console.error(err);
      alert('Erro ao aprovar o recebimento.');
    } finally {
      setLoading(false);
    }
  };

  const getStatusBadge = (status) => {
    switch (status) {
      case 'Pendente':
        return <span className="badge badge-warning">Pendente</span>;
      case 'Em Trânsito':
        return <span className="badge badge-info" style={{ background: '#0284c7', color: '#fff' }}>🚚 Em Trânsito</span>;
      case 'Conferido/Aprovado':
        return <span className="badge badge-success">🟢 Conferido & Aprovado</span>;
      case 'Aceito Parcialmente':
        return <span className="badge badge-warning" style={{ backgroundColor: '#f59e0b', color: '#ffffff' }}>🟡 Aceito em Partes</span>;
      case 'Rejeitado':
        return <span className="badge badge-danger">🔴 Recusado</span>;
      default:
        return <span className="badge">{status}</span>;
    }
  };

  const resolveItemSize = (it, prod) => {
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
    if (prod) {
      if (prod.um && String(prod.um).trim()) return String(prod.um).trim();
      if (prod.embalagem && String(prod.embalagem).trim()) return String(prod.embalagem).trim();
    }
    if (it.um && String(it.um).trim()) return String(it.um).trim();
    if (it.embalagem && String(it.embalagem).trim()) return String(it.embalagem).trim();
    return 'UN';
  };

  return (
    <div className="cd-transfers-container full-width">
      
      {/* Banner de Feedback / Sucesso */}
      {successMsg && (
        <div className="cd-feedback-banner success">
          <CheckCircle size={20} />
          <span>{successMsg}</span>
        </div>
      )}

      {/* Navegação de Abas Superiores */}
      <div className="cd-header-tabs glass">
        <button 
          className={`cd-tab-btn ${activeSubTab === 'list' ? 'active' : ''}`}
          onClick={() => { setActiveSubTab('list'); setIsViewingDetails(false); }}
        >
          <ArrowRightLeft size={18} /> Romaneios & Transferências
        </button>
        <button 
          className={`cd-tab-btn ${activeSubTab === 'new' ? 'active' : ''}`}
          onClick={() => setActiveSubTab('new')}
        >
          <Plus size={18} /> Novo Romaneio de Envio (Livre Escolha)
        </button>
      </div>

      {loading && <div className="loading-bar">Processando dados do Centro de Distribuição...</div>}

      {/* ========================================================================= */}
      {/* SUBTAB 1: LISTAGEM DE ROMANEIOS & TRANSFERÊNCIAS                          */}
      {/* ========================================================================= */}
      {activeSubTab === 'list' && !isViewingDetails && (
        <div className="list-card glass">
          <div className="cd-title-row">
            <div>
              <h3><Truck size={22} color="#f97316" /> Romaneios de Transferência (CD ➔ Filiais | Filial ➔ Filial)</h3>
              <p style={{ fontSize: '0.84rem', color: '#64748b', margin: '2px 0 0 0' }}>
                Gestão centralizada de expedição física e emissão automática de NF-e entre quaisquer unidades
              </p>
            </div>
            <button className="refresh-btn" onClick={fetchTransfers} disabled={loading}>
              <RefreshCw size={17} /> Atualizar Lista
            </button>
          </div>

          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: '85px' }}>Romaneio</th>
                  <th style={{ width: '160px' }}>Origem</th>
                  <th style={{ width: '160px' }}>Destino</th>
                  <th style={{ width: '100px' }}>Data Envio</th>
                  <th style={{ width: '130px', textAlign: 'center' }}>Status</th>
                  <th>Observação Logística</th>
                  <th style={{ width: '120px', textAlign: 'center' }}>NF-e Mod 55</th>
                  <th style={{ width: '230px', textAlign: 'center' }}>Ações</th>
                </tr>
              </thead>
              <tbody>
                {transfers.map((item, idx) => (
                  <tr key={item.id || idx}>
                    <td><span className="item-code">#{item.id}</span></td>
                    <td>{getUnitName(item.origem)}</td>
                    <td><strong>{getUnitName(item.destino)}</strong></td>
                    <td>{formatDate(item.data)}</td>
                    <td style={{ textAlign: 'center' }}>{getStatusBadge(item.status)}</td>
                    <td>{item.obs || '-'}</td>
                    <td style={{ textAlign: 'center' }}>
                      {item.chaveNfe ? (
                        <span className="badge badge-success" title={`Chave: ${item.chaveNfe}`}>
                          <ShieldCheck size={12} /> #{item.numeroNf || 'Emitida'}
                        </span>
                      ) : item.tipoFiscal === 'NAO_FISCAL' ? (
                        <span className="badge" style={{ background: '#f1f5f9', color: '#64748b' }}>
                          📦 Controle Físico
                        </span>
                      ) : (
                        <span className="badge badge-warning" style={{ fontSize: '0.72rem' }}>
                          ⚡ Pendente Emissão
                        </span>
                      )}
                    </td>
                    <td style={{ textAlign: 'center' }}>
                      <div style={{ display: 'inline-flex', gap: '5px', justifyContent: 'center' }}>
                        <button 
                          className="cd-action-btn view" 
                          onClick={() => handleViewDetails(item)} 
                          title="Ver Itens do Romaneio"
                        >
                          <Eye size={13} /> Itens
                        </button>

                        <button 
                          className="cd-action-btn" 
                          onClick={() => handleOpenRomaneio(item)} 
                          title="Imprimir Guia de Separação / Romaneio de Carga A4"
                          style={{ background: '#2563eb', color: '#ffffff' }}
                        >
                          <Printer size={13} /> Romaneio
                        </button>

                        <button 
                          className="cd-action-btn" 
                          onClick={() => handleOpenNfeModal(item)} 
                          title="Visualizar ou Emitir NF-e de Transferência dos Itens Fiscais"
                          style={{ 
                            background: item.chaveNfe ? '#059669' : '#7c3aed', 
                            color: '#ffffff' 
                          }}
                        >
                          <FileText size={13} /> {item.chaveNfe ? 'Ver NF-e' : 'Emitir NF-e'}
                        </button>
                        
                        {item.status === 'Em Trânsito' && (
                          <button 
                            className="cd-action-btn check" 
                            onClick={() => handleOpenConference(item)}
                            title="Conferir e Receber Carga na Filial"
                          >
                            <ShieldCheck size={13} /> Receber
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
                {transfers.length === 0 && (
                  <tr>
                    <td colSpan="8" style={{ textAlign: 'center', padding: '2.5rem', color: '#94a3b8' }}>
                      Nenhuma transferência registrada. Clique em <strong>"Novo Romaneio de Envio"</strong> para começar.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* DETALHES DE UMA TRANSFERÊNCIA SELECIONADA                                 */}
      {/* ========================================================================= */}
      {activeSubTab === 'list' && isViewingDetails && selectedTransfer && (
        <div className="list-card glass">
          <div className="cd-title-row">
            <div>
              <h3>Itens do Romaneio #{selectedTransfer.id}</h3>
              <span style={{ fontSize: '0.85rem', color: '#64748b' }}>
                Origem: {getUnitName(selectedTransfer.origem)} ➔ Destino: <strong>{getUnitName(selectedTransfer.destino)}</strong>
              </span>
            </div>
            <div style={{ display: 'flex', gap: '0.6rem' }}>
              <button 
                className="refresh-btn" 
                onClick={() => handleOpenRomaneio(selectedTransfer)}
                style={{ background: '#2563eb', color: '#ffffff', border: 'none' }}
              >
                <Printer size={16} /> Imprimir Romaneio A4
              </button>
              <button 
                className="refresh-btn" 
                onClick={() => handleOpenNfeModal(selectedTransfer)}
                style={{ background: '#059669', color: '#ffffff', border: 'none' }}
              >
                <FileText size={16} /> NF-e de Transferência
              </button>
              <button className="refresh-btn" onClick={() => setIsViewingDetails(false)}>Voltar</button>
            </div>
          </div>

          <div className="table-responsive" style={{ marginTop: '1rem' }}>
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: '80px' }}>Código</th>
                  <th>Descrição do Produto</th>
                  <th style={{ width: '100px', textAlign: 'center' }}>Tam / Grade</th>
                  <th style={{ width: '130px' }}>Classificação</th>
                  <th style={{ width: '100px', textAlign: 'center' }}>Qtd Enviada</th>
                  <th style={{ width: '100px', textAlign: 'center' }}>Qtd Conferida</th>
                  <th style={{ width: '120px', textAlign: 'right' }}>Valor Unitário</th>
                  <th style={{ width: '130px', textAlign: 'right' }}>Subtotal</th>
                </tr>
              </thead>
              <tbody>
                {selectedTransferItems.map((item, idx) => {
                  const prod = products.find(p => p.codigo === (item.produtoId || item.produto_id));
                  const isFiscal = item.fiscalGerar !== 'N' && (Number(item.codFiscal || item.pro_cod_fiscal) > 0 || item.fiscalGerar === 'S');
                  const tam = resolveItemSize(item, prod);
                  const cor = item.cor && item.cor !== 'UNICA' ? item.cor : '';
                  const qtd = Number(item.quantidade) || 0;
                  const vlr = Number(item.valor) || 0;

                  return (
                    <tr key={item.id || idx}>
                      <td><span className="item-code">#{item.produtoId || item.produto_id}</span></td>
                      <td><strong>{prod ? prod.nome : (item.nome || `Produto #${item.produtoId || item.produto_id}`)}</strong></td>
                      <td style={{ textAlign: 'center' }}>
                        <span style={{ 
                          fontSize: '0.82rem', 
                          fontWeight: 700, 
                          background: '#f8fafc', 
                          color: '#1e293b', 
                          padding: '2px 8px', 
                          borderRadius: '4px',
                          border: '1px solid #cbd5e1'
                        }}>
                          {tam}{cor ? ` • ${cor}` : ''}
                        </span>
                      </td>
                      <td>
                        {isFiscal ? (
                          <span className="badge badge-success" style={{ fontSize: '0.72rem' }}>🏛️ Fiscal (NF-e)</span>
                        ) : (
                          <span className="badge" style={{ background: '#f1f5f9', color: '#475569', fontSize: '0.72rem' }}>📦 Controle Físico</span>
                        )}
                      </td>
                      <td style={{ textAlign: 'center', fontWeight: 700 }}>{qtd}</td>
                      <td style={{ textAlign: 'center' }}>{item.quantidadeConferida ?? '-'}</td>
                      <td style={{ textAlign: 'right' }}>{formatCurrency(vlr)}</td>
                      <td style={{ textAlign: 'right', fontWeight: 700 }}>{formatCurrency(qtd * vlr)}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* SUBTAB 2: NOVO ROMANEIO DE ENVIO (LIVRE ESCOLHA E CLASSIFICAÇÃO AUTO)    */}
      {/* ========================================================================= */}
      {activeSubTab === 'new' && (
        <div className="list-card glass">
          
          <div className="cd-title-row">
            <div>
              <h3><Send size={22} color="#f97316" /> Lançamento de Romaneio de Envio de Mercadorias</h3>
              <p style={{ fontSize: '0.85rem', color: '#64748b', margin: '2px 0 0 0' }}>
                Monte o romaneio livremente com qualquer produto e grade. O sistema separará automaticamente os itens fiscais para NF-e.
              </p>
            </div>
          </div>

          <form onSubmit={handleCreateTransfer} className="cd-form">
            
            {/* CABEÇALHO DO ROMANEIO */}
            <div className="transfer-header-box">
              <div className="transfer-section-title">
                <Building2 size={18} color="#f97316" />
                <span>1. Dados da Remessa & Rota de Transferência</span>
              </div>

              <div className="grid-3">
                <label className="cd-input-container">
                  Unidade de Origem (Remetente) *
                  <select 
                    value={String(origin)} 
                    onChange={(e) => {
                      const newOrigin = e.target.value;
                      setOrigin(newOrigin);
                      if (String(destination) === String(newOrigin)) {
                        const nextDest = units.find(u => String(u.id) !== String(newOrigin));
                        if (nextDest) setDestination(String(nextDest.id));
                      }
                    }} 
                    className="cd-select" 
                    required
                    style={{ fontWeight: 600 }}
                  >
                    {units.map(u => (
                      <option key={u.id} value={String(u.id)}>
                        {u.isMatriz ? '🏢' : '🏬'} {u.name}
                      </option>
                    ))}
                  </select>
                </label>

                <label className="cd-input-container">
                  Unidade de Destino (Destinatário) *
                  <select 
                    value={String(destination)} 
                    onChange={(e) => setDestination(e.target.value)} 
                    className="cd-select" 
                    required
                    style={{ fontWeight: 700, borderColor: '#f97316' }}
                  >
                    <option value="">Selecione a Unidade de Destino...</option>
                    {units.filter(u => String(u.id) !== String(origin)).map(u => (
                      <option key={u.id} value={String(u.id)}>
                        {u.isMatriz ? '🏢' : '🏬'} {u.name}
                      </option>
                    ))}
                  </select>
                </label>

                <label className="cd-input-container">
                  Data de Saída
                  <input 
                    type="date" 
                    value={dataEnvio} 
                    onChange={(e) => setDataEnvio(e.target.value)} 
                    className="cd-text-input" 
                    required 
                  />
                </label>
              </div>

              <div className="transfer-section-title" style={{ marginTop: '0.5rem' }}>
                <Truck size={18} color="#2563eb" />
                <span>2. Transporte & Observações Logísticas</span>
              </div>

              <div className="grid-3">
                <label className="cd-input-container">
                  Motorista / Transportador
                  <input 
                    type="text" 
                    value={motorista} 
                    onChange={(e) => setMotorista(e.target.value)} 
                    placeholder="Nome do motorista / transportadora..." 
                    className="cd-text-input" 
                  />
                </label>

                <label className="cd-input-container">
                  Placa do Veículo
                  <input 
                    type="text" 
                    value={placaVeiculo} 
                    onChange={(e) => setPlacaVeiculo(e.target.value.toUpperCase())} 
                    placeholder="Ex: ABC-1234" 
                    className="cd-text-input" 
                  />
                </label>

                <label className="cd-input-container">
                  Observações do Romaneio
                  <input 
                    type="text" 
                    value={obs} 
                    onChange={(e) => setObs(e.target.value)} 
                    placeholder="Ex: Caixas 01 a 05 - Coleção Inverno" 
                    className="cd-text-input" 
                  />
                </label>
              </div>
            </div>

            {/* SEÇÃO DE ADIÇÃO RÁPIDA DE PRODUTOS AO ROMANEIO */}
            <div className="transfer-add-items-card">
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.5rem', marginBottom: '1rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <Package size={20} color="#2563eb" />
                  <h4 style={{ margin: 0, fontSize: '1rem', fontWeight: 700 }}>Escolha de Produtos & Variações de Grade</h4>
                </div>

                <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                  {/* Bipagem Rápida */}
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px', background: '#ffffff', border: '1px solid #cbd5e1', borderRadius: '0.5rem', padding: '2px 8px' }}>
                    <Barcode size={18} color="#64748b" />
                    <input 
                      ref={barcodeInputRef}
                      type="text"
                      value={barcodeInput}
                      onChange={(e) => setBarcodeInput(e.target.value)}
                      onKeyDown={handleBarcodeScan}
                      placeholder="Bipar Código EAN..."
                      style={{ border: 'none', outline: 'none', fontSize: '0.85rem', width: '150px' }}
                    />
                  </div>

                  {/* Puxar de Compra / NF */}
                  <button 
                    type="button" 
                    className="btn-secondary small" 
                    onClick={() => setShowNfImportBox(!showNfImportBox)}
                    style={{ background: '#f0fdf4', color: '#16a34a', borderColor: '#bbf7d0' }}
                  >
                    📥 Puxar de Compra / NF-e
                  </button>
                </div>
              </div>

              {/* Caixa de Importação de Compra */}
              {showNfImportBox && (
                <div style={{ background: '#f8fafc', padding: '1rem', borderRadius: '0.75rem', border: '1px solid #e2e8f0', marginBottom: '1rem', display: 'flex', gap: '0.75rem', alignItems: 'flex-end' }}>
                  <div style={{ flex: 1 }}>
                    <label style={{ fontSize: '0.8rem', fontWeight: 600, color: '#475569', display: 'block', marginBottom: '4px' }}>
                      Número da Nota ou Chave de Acesso da Compra:
                    </label>
                    <input 
                      type="text" 
                      value={nfSearchTerm} 
                      onChange={(e) => setNfSearchTerm(e.target.value)} 
                      placeholder="Digite o número da NF de compra..." 
                      className="cd-text-input" 
                    />
                  </div>
                  <button 
                    type="button" 
                    className="btn-primary" 
                    onClick={handleFetchNfItems}
                    disabled={loadingNf}
                    style={{ height: '38px', padding: '0 1.25rem' }}
                  >
                    {loadingNf ? 'Importando...' : 'Carregar Itens'}
                  </button>
                </div>
              )}

              {/* Seletor com LookupSelect */}
              <div className="form-group" style={{ marginBottom: '1rem' }}>
                <label style={{ fontWeight: 600, fontSize: '0.85rem' }}>Pesquisar Produto no Catálogo do CD:</label>
                <LookupSelect
                  value={selectedProductObj ? `#${selectedProductObj.codigo} - ${selectedProductObj.nome}` : ''}
                  placeholder="Busque por descrição, código, EAN ou referência..."
                  title="Selecionar Produto para o Romaneio"
                  subtitle="Busca rápida no estoque central do CD"
                  icon={Package}
                  searchPlaceholder="Digite o nome, código ou EAN..."
                  fetchData={async (termo, targetPage, limit) => {
                    let url = `/v1/produtos?page=${targetPage}&limit=${limit}`;
                    if (termo) url += `&busca=${encodeURIComponent(termo)}&termo=${encodeURIComponent(termo)}`;
                    const res = await api.get(url);
                    return res.data;
                  }}
                  columns={[
                    { key: 'codigo', label: 'Código', width: '90px', render: (p) => <span className="item-code">#{p.codigo || p.PRO_CODIGO}</span> },
                    { key: 'nome', label: 'Descrição do Produto', render: (p) => <strong>{p.nome || p.PRO_NOME}</strong> },
                    { key: 'codbarra', label: 'Cód. Barras', render: (p) => <code>{p.codbarra || '-'}</code> },
                    { 
                      key: 'fiscal', 
                      label: 'Natureza', 
                      width: '110px',
                      render: (p) => (p.pro_fiscal_gerar !== 'N' && ((p.pro_cod_fiscal && Number(p.pro_cod_fiscal) > 0) || p.pro_fiscal_gerar === 'S'))
                        ? <span className="badge badge-success" style={{ fontSize: '0.7rem' }}>🏛️ Fiscal</span>
                        : <span className="badge" style={{ background: '#f1f5f9', color: '#475569', fontSize: '0.7rem' }}>📦 Físico</span>
                    },
                    { key: 'valorv', label: 'Preço Venda', align: 'right', render: (p) => formatCurrency(p.valorv || 0) }
                  ]}
                  onSelect={(p) => handleSelectProduct(p)}
                />
              </div>

              {/* MATRIZ DE VARIAÇÕES DE GRADE (Se o produto tiver variações cadastradas com estoque) */}
              {selectedProductObj && productGrades.length > 0 && (
                <div className="transfer-grade-matrix-card">
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem', flexWrap: 'wrap', gap: '8px' }}>
                    <div>
                      <span style={{ fontWeight: 700, color: '#1e293b', fontSize: '0.98rem' }}>
                        ✨ Variações de Tamanho / Grade com Estoque: #{selectedProductObj.codigo} - {selectedProductObj.nome}
                      </span>
                      <div style={{ fontSize: '0.8rem', color: '#64748b', marginTop: '2px' }}>
                        Unidade Origem: <strong>{getUnitName(origin)}</strong> | Saldo Total: <strong style={{ color: '#16a34a' }}>{selectedProductStock} UN</strong>
                      </div>
                    </div>
                    <span style={{ fontSize: '0.8rem', color: '#64748b' }}>
                      Informe a quantidade desejada em cada tamanho com saldo disponível:
                    </span>
                  </div>

                  <div className="transfer-grade-matrix-grid">
                    {productGrades.map(g => {
                      const gId = g.codigo || g.id || g.gra_codigo;
                      const tamNome = g.tamanho_str || (typeof g.tam_nome === 'string' && g.tam_nome) || (typeof g.sigla === 'string' && g.sigla) || (g.tamanho && typeof g.tamanho === 'object' ? (g.tamanho.sigla || g.tamanho.tamanho) : '') || 'UN';
                      const maxQtd = Number(g.quantidade || g.gra_quantidade || 0);
                      const currentVal = matrixQuantities[gId] || '';

                      return (
                        <div key={gId} className="transfer-grade-box">
                          <div className="transfer-grade-label">{tamNome}</div>
                          <div className="transfer-grade-stock" style={{ color: '#16a34a', fontWeight: 600, fontSize: '0.78rem' }}>
                            Disponível: {maxQtd} UN
                          </div>
                          <input 
                            type="number"
                            min="0"
                            max={maxQtd}
                            value={currentVal}
                            onChange={(e) => {
                              let val = parseInt(e.target.value, 10);
                              if (isNaN(val) || val < 0) val = 0;
                              if (val > maxQtd) {
                                val = maxQtd;
                                alert(`A quantidade informada ultrapassa o estoque disponível (${maxQtd} UN) para o tamanho ${tamNome}.`);
                              }
                              handleMatrixQtyChange(gId, val);
                            }}
                            placeholder="0"
                            className="transfer-grade-input"
                          />
                        </div>
                      );
                    })}
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '1rem' }}>
                    <button 
                      type="button" 
                      className="btn-primary" 
                      onClick={handleAddGradeMatrixToTransfer}
                      style={{ padding: '0.6rem 1.5rem', fontWeight: 700 }}
                    >
                      + Inserir Grade no Romaneio
                    </button>
                  </div>
                </div>
              )}

              {/* SELEÇÃO SIMPLES (Caso o produto não tenha matriz de grades ou não haja grades com saldo) */}
              {selectedProductObj && productGrades.length === 0 && (
                <div style={{ background: '#ffffff', padding: '1rem', borderRadius: '0.75rem', border: '1px solid #cbd5e1', display: 'flex', gap: '1rem', alignItems: 'flex-end', flexWrap: 'wrap' }}>
                  <div style={{ flex: 2, minWidth: '200px' }}>
                    <label style={{ fontSize: '0.8rem', fontWeight: 600, color: '#475569' }}>Produto Selecionado:</label>
                    <div style={{ fontWeight: 700, fontSize: '0.95rem', color: '#1e293b' }}>
                      #{selectedProductObj.codigo} - {selectedProductObj.nome}
                    </div>
                    <div style={{ fontSize: '0.82rem', marginTop: '4px', fontWeight: 600, color: selectedProductStock > 0 ? '#16a34a' : '#dc2626' }}>
                      {selectedProductStock > 0 
                        ? `📦 Estoque Disponível na Origem (${getUnitName(origin)}): ${selectedProductStock} UN` 
                        : `⚠️ Sem estoque disponível na unidade de origem (${getUnitName(origin)})`}
                    </div>
                  </div>

                  <div style={{ width: '110px' }}>
                    <label style={{ fontSize: '0.8rem', fontWeight: 600, color: '#475569' }}>Quantidade:</label>
                    <input 
                      type="number" 
                      min="1"
                      max={selectedProductStock > 0 ? selectedProductStock : 1}
                      value={singleQty} 
                      onChange={(e) => {
                        let val = Number(e.target.value);
                        if (selectedProductStock > 0 && val > selectedProductStock) {
                          val = selectedProductStock;
                          alert(`A quantidade não pode ultrapassar o saldo disponível (${selectedProductStock} UN).`);
                        }
                        setSingleQty(val);
                      }} 
                      className="cd-text-input" 
                      style={{ fontWeight: 700 }}
                    />
                  </div>

                  <div style={{ width: '130px' }}>
                    <label style={{ fontSize: '0.8rem', fontWeight: 600, color: '#475569' }}>Valor Unitário:</label>
                    <input 
                      type="number" 
                      step="0.01"
                      value={singlePrice} 
                      onChange={(e) => setSinglePrice(e.target.value)} 
                      className="cd-text-input" 
                    />
                  </div>

                  <button 
                    type="button" 
                    className="btn-primary" 
                    onClick={handleAddSingleProductToTransfer}
                    style={{ height: '38px', padding: '0 1.25rem' }}
                    disabled={selectedProductStock <= 0}
                  >
                    + Adicionar Item
                  </button>
                </div>
              )}

            </div>

            {/* TABELA DE ITENS INCLUSOS NO ROMANEIO */}
            <div className="product-section-card" style={{ marginTop: '1rem' }}>
              <div className="product-section-title" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <ShoppingBag size={18} color="#16a34a" /> Itens Inclusos no Romaneio de Envio ({transferItems.length} linhas)
                </div>
                {transferItems.length > 0 && (
                  <button 
                    type="button" 
                    onClick={() => setTransferItems([])}
                    style={{ background: 'transparent', border: 'none', color: '#dc2626', fontSize: '0.8rem', cursor: 'pointer', fontWeight: 600 }}
                  >
                    Limpar Todos
                  </button>
                )}
              </div>

              <div className="table-responsive" style={{ maxHeight: '320px', overflowY: 'auto' }}>
                <table className="data-table">
                  <thead>
                    <tr>
                      <th style={{ width: '80px' }}>Código</th>
                      <th>Descrição do Produto</th>
                      <th style={{ width: '120px', textAlign: 'center' }}>Variação / Tam</th>
                      <th style={{ width: '150px' }}>Classificação Fiscal Auto</th>
                      <th style={{ width: '100px', textAlign: 'center' }}>Qtd</th>
                      <th style={{ width: '120px', textAlign: 'right' }}>Vlr Unitário</th>
                      <th style={{ width: '130px', textAlign: 'right' }}>Subtotal</th>
                      <th style={{ width: '60px', textAlign: 'center' }}>Ação</th>
                    </tr>
                  </thead>
                  <tbody>
                    {transferItems.map((item, idx) => (
                      <tr key={idx}>
                        <td><span className="item-code">#{item.produto_id}</span></td>
                        <td><strong>{item.nome}</strong></td>
                        <td style={{ textAlign: 'center' }}>
                          <span className="badge badge-info" style={{ fontSize: '0.75rem' }}>
                            {item.tamanho || 'UN'} {item.cor && item.cor !== 'UNICA' ? `• ${item.cor}` : ''}
                          </span>
                        </td>
                        <td>
                          {item.isFiscal ? (
                            <span 
                              className="badge badge-success" 
                              style={{ fontSize: '0.75rem', cursor: 'pointer' }}
                              onClick={() => handleToggleItemFiscal(idx)}
                              title="Clique para alternar classificação"
                            >
                              🏛️ Fiscal (Gera NF-e)
                            </span>
                          ) : (
                            <span 
                              className="badge" 
                              style={{ background: '#f1f5f9', color: '#475569', fontSize: '0.75rem', cursor: 'pointer' }}
                              onClick={() => handleToggleItemFiscal(idx)}
                              title="Clique para alternar classificação"
                            >
                              📦 Controle Físico
                            </span>
                          )}
                        </td>
                        <td style={{ textAlign: 'center' }}>
                          <input 
                            type="number"
                            min="1"
                            value={item.quantidade}
                            onChange={(e) => handleUpdateItemQty(idx, e.target.value)}
                            style={{ width: '70px', padding: '0.25rem', textAlign: 'center', fontWeight: 700, borderRadius: '0.35rem', border: '1px solid #cbd5e1' }}
                          />
                        </td>
                        <td style={{ textAlign: 'right' }}>
                          <input 
                            type="number"
                            step="0.01"
                            value={item.valor}
                            onChange={(e) => handleUpdateItemValor(idx, e.target.value)}
                            style={{ width: '90px', padding: '0.25rem', textAlign: 'right', borderRadius: '0.35rem', border: '1px solid #cbd5e1' }}
                          />
                        </td>
                        <td style={{ textAlign: 'right', fontWeight: 700 }}>
                          {formatCurrency(item.quantidade * item.valor)}
                        </td>
                        <td style={{ textAlign: 'center' }}>
                          <button 
                            type="button" 
                            className="crud-row-btn delete" 
                            onClick={() => handleRemoveItemFromTransfer(idx)}
                            title="Remover Item"
                          >
                            <Trash2 size={14} />
                          </button>
                        </td>
                      </tr>
                    ))}
                    {transferItems.length === 0 && (
                      <tr>
                        <td colSpan="8" style={{ textAlign: 'center', padding: '2rem', color: '#94a3b8' }}>
                          Nenhum produto adicionado ao romaneio ainda. Use a pesquisa ou o leitor de código de barras acima.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* PAINEL DE RESUMO & CLASSIFICAÇÃO AUTOMÁTICA DO ROMANEIO */}
            <div className="transfer-summary-panel">
              <div className="transfer-summary-grid">
                
                <div className="transfer-kpi-card total">
                  <div className="transfer-kpi-title">📦 Total no Romaneio</div>
                  <div className="transfer-kpi-value">{totalPecas} peças</div>
                  <div className="transfer-kpi-sub">{formatCurrency(totalValor)}</div>
                </div>

                <div className="transfer-kpi-card fiscal">
                  <div className="transfer-kpi-title">🏛️ Itens Fiscais (NF-e Mod 55)</div>
                  <div className="transfer-kpi-value" style={{ color: '#059669' }}>{pecasFiscais} peças</div>
                  <div className="transfer-kpi-sub">
                    {formatCurrency(valorFiscal)} • <em>Gera NF-e de Transferência</em>
                  </div>
                </div>

                <div className="transfer-kpi-card physical">
                  <div className="transfer-kpi-title">📋 Controle Físico / Interno</div>
                  <div className="transfer-kpi-value" style={{ color: '#0284c7' }}>{pecasFisicas} peças</div>
                  <div className="transfer-kpi-sub">
                    {formatCurrency(valorFisico)} • <em>Apenas Romaneio de Carga</em>
                  </div>
                </div>

              </div>
            </div>

            {/* BOTÕES DE FINALIZAÇÃO */}
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '1rem', marginTop: '1rem' }}>
              <button 
                type="button" 
                className="btn-secondary" 
                onClick={() => { setTransferItems([]); setActiveSubTab('list'); }}
              >
                Cancelar
              </button>
              <button 
                type="submit" 
                className="btn-primary" 
                disabled={loading || transferItems.length === 0}
                style={{ padding: '0.75rem 2rem', fontSize: '1rem', fontWeight: 700 }}
              >
                <Send size={18} /> Salvar & Expedir Romaneio
              </button>
            </div>

          </form>

        </div>
      )}

      {/* ========================================================================= */}
      {/* SUBTAB 3: CONFERÊNCIA CEGA DE RECEBIMENTO NA FILIAL                      */}
      {/* ========================================================================= */}
      {activeSubTab === 'reception' && receptionTransfer && (
        <div className="list-card glass">
          <div className="cd-title-row">
            <div>
              <h3><ShieldCheck size={22} color="#10b981" /> Conferência Cega — Recebimento de Carga</h3>
              <span style={{ fontSize: '0.85rem', color: '#64748b' }}>
                Romaneio Lote #{receptionTransfer.id} • Destino: {getUnitName(receptionTransfer.destino)}
              </span>
              <p style={{ fontSize: '0.78rem', color: '#94a3b8', margin: '4px 0 0 0', fontStyle: 'italic' }}>
                🔒 Conferência Cega: conte fisicamente cada item e registre a quantidade real. A quantidade esperada ficará oculta até que você clique em "Revelar Divergências".
              </p>
            </div>
            <button className="refresh-btn" onClick={() => setActiveSubTab('list')}>Voltar</button>
          </div>

          <div className="table-responsive" style={{ marginTop: '1rem' }}>
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: '80px' }}>Código</th>
                  <th>Descrição do Produto</th>
                  <th style={{ width: '130px', textAlign: 'center' }}>Qtd Contada (Real)</th>
                  {blindCheckRevealed && (
                    <>
                      <th style={{ width: '100px', textAlign: 'center' }}>Qtd Esperada</th>
                      <th style={{ width: '110px', textAlign: 'center' }}>Divergência</th>
                    </>
                  )}
                  <th>Justificativa / Divergência</th>
                </tr>
              </thead>
              <tbody>
                {receptionItems.map((item, idx) => {
                  const prod = products.find(p => p.codigo === item.produtoId);
                  const diff = blindCheckRevealed ? (Number(item.quantidadeConferida) - Number(item.quantidade)) : null;
                  return (
                    <tr key={idx} style={blindCheckRevealed && diff !== 0 ? { background: '#fef2f2' } : {}}>
                      <td><span className="item-code">#{item.produtoId}</span></td>
                      <td><strong>{prod ? prod.nome : (item.nome || `Produto #${item.produtoId}`)}</strong></td>
                      <td style={{ textAlign: 'center' }}>
                        <input 
                          type="number"
                          min="0"
                          value={item.quantidadeConferida}
                          onChange={(e) => {
                            const next = [...receptionItems];
                            next[idx].quantidadeConferida = Number(e.target.value) || 0;
                            setReceptionItems(next);
                          }}
                          style={{ 
                            width: '90px', padding: '0.4rem', textAlign: 'center', fontWeight: 700, 
                            borderRadius: '0.35rem', border: '2px solid #10b981', fontSize: '1rem',
                            background: '#f0fdf4'
                          }}
                        />
                      </td>
                      {blindCheckRevealed && (
                        <>
                          <td style={{ textAlign: 'center', fontWeight: 700, color: '#64748b' }}>{item.quantidade}</td>
                          <td style={{ textAlign: 'center' }}>
                            {diff === 0 ? (
                              <span className="badge badge-success" style={{ fontSize: '0.75rem' }}>✅ OK</span>
                            ) : diff > 0 ? (
                              <span className="badge badge-warning" style={{ background: '#f59e0b', color: '#fff', fontSize: '0.75rem' }}>+{diff} Sobra</span>
                            ) : (
                              <span className="badge" style={{ background: '#ef4444', color: '#fff', fontSize: '0.75rem' }}>{diff} Falta</span>
                            )}
                          </td>
                        </>
                      )}
                      <td>
                        <input 
                          type="text"
                          value={item.justificativa}
                          onChange={(e) => {
                            const next = [...receptionItems];
                            next[idx].justificativa = e.target.value;
                            setReceptionItems(next);
                          }}
                          placeholder={blindCheckRevealed ? "Justifique sobras, faltas ou avarias..." : "Observação (opcional)..."}
                          style={{ width: '100%', padding: '0.35rem 0.6rem', borderRadius: '0.35rem', border: '1px solid #cbd5e1' }}
                        />
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          <div style={{ marginTop: '1.5rem', display: 'flex', gap: '1rem', alignItems: 'flex-end', flexWrap: 'wrap' }}>
            <div style={{ flex: 1, minWidth: '220px' }}>
              <label style={{ fontSize: '0.85rem', fontWeight: 600, display: 'block', marginBottom: '4px' }}>
                Nome do Conferente / Responsável *:
              </label>
              <input 
                type="text"
                value={checkerName}
                onChange={(e) => setCheckerName(e.target.value)}
                placeholder="Digite seu nome completo..."
                className="cd-text-input"
                required
              />
            </div>

            <div style={{ flex: 2, minWidth: '300px' }}>
              <label style={{ fontSize: '0.85rem', fontWeight: 600, display: 'block', marginBottom: '4px' }}>
                Observações da Recepção:
              </label>
              <input 
                type="text"
                value={receptionObs}
                onChange={(e) => setReceptionObs(e.target.value)}
                placeholder="Observações sobre o estado das caixas e lacres..."
                className="cd-text-input"
              />
            </div>

            <div style={{ display: 'flex', gap: '0.5rem' }}>
              {!blindCheckRevealed ? (
                <button 
                  type="button" 
                  className="btn-primary" 
                  onClick={() => {
                    const allZero = receptionItems.every(it => Number(it.quantidadeConferida) === 0);
                    if (allZero) {
                      alert('Nenhum item foi contado ainda. Insira a quantidade real de cada item antes de revelar as divergências.');
                      return;
                    }
                    setBlindCheckRevealed(true);
                  }}
                  style={{ background: '#7c3aed', height: '40px', padding: '0 1.5rem' }}
                >
                  <Eye size={18} /> Revelar Divergências
                </button>
              ) : (
                <button 
                  type="button" 
                  className="btn-primary" 
                  onClick={() => handleApproveReception('Conferido/Aprovado')}
                  style={{ background: '#059669', height: '40px', padding: '0 1.5rem' }}
                >
                  <CheckCircle size={18} /> Aprovar Recepção
                </button>
              )}
            </div>
          </div>

          {blindCheckRevealed && (() => {
            const divergences = receptionItems.filter(it => Number(it.quantidadeConferida) !== Number(it.quantidade));
            if (divergences.length === 0) return (
              <div style={{ marginTop: '1rem', padding: '0.75rem 1rem', background: '#f0fdf4', borderRadius: '0.5rem', border: '1px solid #86efac', fontSize: '0.9rem', color: '#166534' }}>
                ✅ Conferência 100% — Todos os {receptionItems.length} itens bateram com as quantidades esperadas.
              </div>
            );
            return (
              <div style={{ marginTop: '1rem', padding: '0.75rem 1rem', background: '#fef2f2', borderRadius: '0.5rem', border: '1px solid #fca5a5', fontSize: '0.9rem', color: '#991b1b' }}>
                ⚠️ {divergences.length} item(ns) com divergência detectada. Preencha a justificativa antes de aprovar.
              </div>
            );
          })()}

        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL DE IMPRESSÃO DO ROMANEIO (GUIA A4)                                  */}
      {/* ========================================================================= */}
      {showRomaneioModal && romaneioTransfer && (
        <RomaneioModal
          transfer={romaneioTransfer}
          items={romaneioItems}
          products={products}
          units={units}
          onClose={() => setShowRomaneioModal(false)}
        />
      )}

      {/* ========================================================================= */}
      {/* MODAL DE EMISSÃO / DANFE DA NF-e DE TRANSFERÊNCIA                         */}
      {/* ========================================================================= */}
      {showNfeModal && nfeTransfer && (
        <NfeTransferModal
          transfer={nfeTransfer}
          items={nfeItems}
          units={units}
          onClose={() => setShowNfeModal(false)}
          onNfeUpdated={() => fetchTransfers()}
        />
      )}

    </div>
  );
}
