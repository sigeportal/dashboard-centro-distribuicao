import { useEffect, useState, useCallback } from 'react';
import { useSearchParams } from 'react-router-dom';
import { createApi, isUnauthorizedError } from '../services/api';
import { logError } from '../utils/logger';

const emptyChartResponse = { data: { data: [] } };

const extractArrayData = (res) => {
  if (!res || !res.data) return [];
  if (Array.isArray(res.data)) return res.data;
  if (Array.isArray(res.data.data)) return res.data.data;
  return [];
};

const extractChartObject = (res) => {
  const arr = extractArrayData(res);
  return { data: arr, meta: res?.data?.meta || {} };
};

const allowEmptyExceptUnauthorized = (fallback) => (err) => {
  if (isUnauthorizedError(err)) {
    throw err;
  }
  return fallback;
};

export default function useDashboardData(showServiceOrders = false, isFinancialAllowed = false) {
  const [searchParams] = useSearchParams();
  const activeTab = searchParams.get('tab') || 'geral';

  const [data, setData] = useState({
    clientes: { data: [], meta: {} },
    movimentacoes: { data: [], meta: {} },
    produtos: { data: [], meta: {} },
    recebimentos: { data: [], meta: {} },
    vendas: { data: [], meta: {} },
    os: { data: [], meta: {} }
  });

  const [pages, setPages] = useState({
    clientes: 1,
    movimentacoes: 1,
    produtos: 1,
    recebimentos: 1,
    vendas: 1,
    os: 1
  });

  const [chartData, setChartData] = useState({
    clientes: [],
    produtos: [],
    movimentacoes: [],
    vendasDiarias: [],
    vendasPorHora: [],
    vendasMargemLucro: [],
    despesasTipoPagamento: [],
    meiosPagamento: { data: [], meta: {} },
    meiosPagamentoCompras: { data: [], meta: {} },
    meiosPagamentoRecebimentos: { data: [], meta: {} },
    meiosPagamentoPagamentos: { data: [], meta: {} },
    vendasLucroGrupo: { data: [], meta: {} },
    osDiarias: [],
    osMargemLucro: []
  });
  const [chartLoading, setChartLoading] = useState({
    clientes: false,
    movimentacoes: false,
    vendasDiarias: false,
    vendasPorHora: false,
    meiosPagamento: false,
    meiosPagamentoCompras: false,
    meiosPagamentoRecebimentos: false,
    meiosPagamentoPagamentos: false,
    vendasMargemLucro: false,
    despesasTipoPagamento: false,
    vendasLucroGrupo: false,
    osDiarias: false,
    osMargemLucro: false
  });


  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [searchTerms, setSearchTerms] = useState({
    clientes: '',
    produtos: '',
    movimentacoes: '',
    recebimentos: '',
    vendas: '',
    os: ''
  });

  const [overviewDates, setOverviewDates] = useState(() => ({
    startDate: new Date(Date.now() - 90 * 86400000).toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0]
  }));

  const [movimentacoesDates, setMovimentacoesDates] = useState(() => ({
    startDate: new Date(Date.now() - 90 * 86400000).toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0]
  }));

  const [recebimentosDates, setRecebimentosDates] = useState(() => ({
    startDate: new Date(Date.now() - 90 * 86400000).toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0]
  }));

  const [vendasDates, setVendasDates] = useState(() => ({
    startDate: new Date(Date.now() - 90 * 86400000).toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0]
  }));

  const [osDates, setOsDates] = useState(() => ({
    startDate: new Date(Date.now() - 90 * 86400000).toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0]
  }));

  const [prodFilter, setProdFilter] = useState('todos');
  const [accounts, setAccounts] = useState({ "0": "CAIXA" });
  const [selectedAccount, setSelectedAccount] = useState("0");

  const getApi = useCallback((useCdApi = false) => {
    return createApi(useCdApi);
  }, []);

  const getFilteredData = (type) => {
    return Array.isArray(data[type].data) ? data[type].data : [];
  };

  const fetchPage = async (type, newPage = 'last', searchTerm = searchTerms[type], startDate = null, endDate = null, stockStatus = prodFilter, account = selectedAccount) => {
    try {
      const api = getApi(true); // Tudo vem do CD_API (ServidorRESTConfeccoes) conforme sincronizado
      const searchParam = searchTerm ? `&search=${encodeURIComponent(searchTerm)}` : '';
      
      let dateParam = '';
      const start = startDate !== null ? startDate : (
        type === 'movimentacoes'
          ? (activeTab === 'geral' ? overviewDates.startDate : movimentacoesDates.startDate)
          : type === 'recebimentos'
            ? recebimentosDates.startDate
            : type === 'vendas'
              ? (activeTab === 'geral' ? overviewDates.startDate : vendasDates.startDate)
              : type === 'os'
                ? osDates.startDate
                : null
      );
      const end = endDate !== null ? endDate : (
        type === 'movimentacoes'
          ? (activeTab === 'geral' ? overviewDates.endDate : movimentacoesDates.endDate)
          : type === 'recebimentos'
            ? recebimentosDates.endDate
            : type === 'vendas'
              ? (activeTab === 'geral' ? overviewDates.endDate : vendasDates.endDate)
              : type === 'os'
                ? osDates.endDate
                : null
      );
      
      if (start) dateParam += `&startDate=${start}`;
      if (end) dateParam += `&endDate=${end}`;

      let stockParam = '';
      if (type === 'produtos' && stockStatus && stockStatus !== 'todos') {
        stockParam = `&stockStatus=${stockStatus}`;
      }

      let conParam = '';
      if (type === 'movimentacoes') {
        conParam = `&con=${account}`;
      }

      let targetNum = newPage === 'last' ? 1 : newPage;
      let res = await api.get(`/v1/${type}?page=${targetNum}&limit=10${searchParam}${dateParam}${stockParam}${conParam}`);
      let isArray = Array.isArray(res.data);
      let items = isArray ? res.data : (res.data?.data || []);
      let metaData = isArray ? { total: res.data.length, pages: 1 } : (res.data?.meta || {});

      if (newPage === 'last' && metaData.pages > 1) {
        targetNum = metaData.pages;
        res = await api.get(`/v1/${type}?page=${targetNum}&limit=10${searchParam}${dateParam}${stockParam}${conParam}`);
        isArray = Array.isArray(res.data);
        items = isArray ? res.data : (res.data?.data || []);
        metaData = isArray ? { total: res.data.length, pages: 1 } : (res.data?.meta || {});
      }

      setData(prev => ({
        ...prev,
        [type]: {
          data: items,
          meta: metaData
        }
      }));
      setPages(prev => ({ ...prev, [type]: metaData.page || targetNum }));
    } catch (err) {
      logError(`Erro ao buscar página ${newPage} de ${type}:`, err);
    }
  };

  const handleProdFilterChange = (newFilter) => {
    setProdFilter(newFilter);
    fetchPage('produtos', 1, searchTerms.produtos, null, null, newFilter);
  };

  const handleSearchClick = (type) => {
    fetchPage(type, 1, searchTerms[type]);
  };

  const handleClearSearch = (type) => {
    setSearchTerms(prev => ({ ...prev, [type]: '' }));
    fetchPage(type, 1, '');
  };

  const fetchCustomersChartData = useCallback(async () => {
    setChartLoading(prev => ({ ...prev, clientes: true }));

    const api = getApi(true);
    api.get('/v1/dashboard/clientes-cidade')
      .then(res => {
        setChartData(prev => ({ ...prev, clientes: extractArrayData(res) }));
      })
      .catch(allowEmptyExceptUnauthorized(emptyChartResponse))
      .finally(() => {
        setChartLoading(prev => ({ ...prev, clientes: false }));
      });
  }, [getApi]);

  const fetchChartData = useCallback(async (startDate = null, endDate = null) => {
    const today = new Date().toISOString().split('T')[0];
    const isTodayRange = startDate === today && endDate === today;

    setChartLoading(prev => ({
      ...prev,
      movimentacoes: isFinancialAllowed && !isTodayRange,
      vendasDiarias: true,
      vendasPorHora: isTodayRange,
      meiosPagamento: true,
      meiosPagamentoCompras: isFinancialAllowed,
      meiosPagamentoRecebimentos: isFinancialAllowed,
      meiosPagamentoPagamentos: isFinancialAllowed,
      vendasMargemLucro: isFinancialAllowed,
      despesasTipoPagamento: isFinancialAllowed,
      vendasLucroGrupo: isFinancialAllowed,
      osDiarias: showServiceOrders,
      osMargemLucro: showServiceOrders
    }));

    const api = getApi(true);
    const params = {};
    if (startDate) params.startDate = startDate;
    if (endDate) params.endDate = endDate;

    if (isFinancialAllowed && !isTodayRange) {
      api.get('/v1/dashboard/movimentacoes', { params })
        .then(res => {
          setChartData(prev => ({ ...prev, movimentacoes: extractArrayData(res) }));
        })
        .catch(allowEmptyExceptUnauthorized(emptyChartResponse))
        .finally(() => {
          setChartLoading(prev => ({ ...prev, movimentacoes: false }));
        });
    } else {
      setChartData(prev => ({ ...prev, movimentacoes: [] }));
      setChartLoading(prev => ({ ...prev, movimentacoes: false }));
    }

    api.get('/v1/dashboard/vendas-diarias', { params })
      .then(res => {
        setChartData(prev => ({ ...prev, vendasDiarias: extractArrayData(res) }));
      })
      .catch(allowEmptyExceptUnauthorized(emptyChartResponse))
      .finally(() => {
        setChartLoading(prev => ({ ...prev, vendasDiarias: false }));
      });

    if (isTodayRange) {
      api.get('/v1/dashboard/vendas-diarias/hora', { params })
        .then(res => {
          setChartData(prev => ({ ...prev, vendasPorHora: extractArrayData(res) }));
        })
        .catch(allowEmptyExceptUnauthorized(emptyChartResponse))
        .finally(() => {
          setChartLoading(prev => ({ ...prev, vendasPorHora: false }));
        });
    } else {
      setChartData(prev => ({ ...prev, vendasPorHora: [] }));
      setChartLoading(prev => ({ ...prev, vendasPorHora: false }));
    }

    // 4. Meios Pagamento (Vendas)
    api.get('/v1/dashboard/tipos-pagamentos-vendas', { params })
      .then(res => {
        setChartData(prev => ({
          ...prev,
          meiosPagamento: extractChartObject(res)
        }));
      })
      .catch(allowEmptyExceptUnauthorized(emptyChartResponse))
      .finally(() => {
        setChartLoading(prev => ({ ...prev, meiosPagamento: false }));
      });

    if (isFinancialAllowed) {
      api.get('/v1/dashboard/tipos-pagamentos-compras', { params })
        .then(res => {
          setChartData(prev => ({
            ...prev,
            meiosPagamentoCompras: extractChartObject(res)
          }));
        })
        .catch(allowEmptyExceptUnauthorized(emptyChartResponse))
        .finally(() => {
          setChartLoading(prev => ({ ...prev, meiosPagamentoCompras: false }));
        });

      api.get('/v1/dashboard/tipos-pagamentos-recebimentos', { params })
        .then(res => {
          setChartData(prev => ({
            ...prev,
            meiosPagamentoRecebimentos: extractChartObject(res)
          }));
        })
        .catch(allowEmptyExceptUnauthorized(emptyChartResponse))
        .finally(() => {
          setChartLoading(prev => ({ ...prev, meiosPagamentoRecebimentos: false }));
        });

      api.get('/v1/dashboard/tipos-pagamentos-pagamentos', { params })
        .then(res => {
          setChartData(prev => ({
            ...prev,
            meiosPagamentoPagamentos: extractChartObject(res)
          }));
        })
        .catch(allowEmptyExceptUnauthorized(emptyChartResponse))
        .finally(() => {
          setChartLoading(prev => ({ ...prev, meiosPagamentoPagamentos: false }));
        });

      api.get('/v1/dashboard/vendas-margem-lucro', { params })
        .then(res => {
          setChartData(prev => ({ ...prev, vendasMargemLucro: extractArrayData(res) }));
        })
        .catch(allowEmptyExceptUnauthorized(emptyChartResponse))
        .finally(() => {
          setChartLoading(prev => ({ ...prev, vendasMargemLucro: false }));
        });

      api.get('/v1/dashboard/despesas-tipo-pagamento', { params })
        .then(res => {
          setChartData(prev => ({ ...prev, despesasTipoPagamento: extractArrayData(res) }));
        })
        .catch(allowEmptyExceptUnauthorized(emptyChartResponse))
        .finally(() => {
          setChartLoading(prev => ({ ...prev, despesasTipoPagamento: false }));
        });

      api.get('/v1/dashboard/vendas-lucro-grupo', { params })
        .then(res => {
          setChartData(prev => ({
            ...prev,
            vendasLucroGrupo: extractChartObject(res)
          }));
        })
        .catch(allowEmptyExceptUnauthorized(emptyChartResponse))
        .finally(() => {
          setChartLoading(prev => ({ ...prev, vendasLucroGrupo: false }));
        });
    } else {
      setChartData(prev => ({
        ...prev,
        meiosPagamentoCompras: { data: [], meta: {} },
        meiosPagamentoRecebimentos: { data: [], meta: {} },
        meiosPagamentoPagamentos: { data: [], meta: {} },
        vendasMargemLucro: [],
        despesasTipoPagamento: [],
        vendasLucroGrupo: { data: [], meta: {} }
      }));
      setChartLoading(prev => ({
        ...prev,
        meiosPagamentoCompras: false,
        meiosPagamentoRecebimentos: false,
        meiosPagamentoPagamentos: false,
        vendasMargemLucro: false,
        despesasTipoPagamento: false,
        vendasLucroGrupo: false
      }));
    }

    if (!showServiceOrders) {
      setChartData(prev => ({
        ...prev,
        osDiarias: [],
        osMargemLucro: []
      }));
      return;
    }

    // 11. OS Diarias
    api.get('/v1/dashboard/os-diarias', { params })
      .then(res => {
        setChartData(prev => ({ ...prev, osDiarias: extractArrayData(res) }));
      })
      .catch(allowEmptyExceptUnauthorized(emptyChartResponse))
      .finally(() => {
        setChartLoading(prev => ({ ...prev, osDiarias: false }));
      });

    // 12. OS Margem Lucro
    api.get('/v1/dashboard/os-margem-lucro', { params })
      .then(res => {
        setChartData(prev => ({ ...prev, osMargemLucro: extractArrayData(res) }));
      })
      .catch(allowEmptyExceptUnauthorized(emptyChartResponse))
      .finally(() => {
        setChartLoading(prev => ({ ...prev, osMargemLucro: false }));
      });

  }, [getApi, isFinancialAllowed, showServiceOrders]);

  useEffect(() => {
    const fetchActiveTabData = async () => {
      setLoading(true);
      setError(null);
      try {
        if (activeTab === 'geral') {
          fetchChartData(overviewDates.startDate, overviewDates.endDate);
        } else if (activeTab === 'clientes') {
          fetchCustomersChartData();
          await fetchPage('clientes', 'last', searchTerms.clientes);
        } else if (activeTab === 'produtos') {
          await fetchPage('produtos', 'last', searchTerms.produtos, null, null, prodFilter);
        } else if (activeTab === 'vendas') {
          await fetchPage('vendas', 'last', searchTerms.vendas, vendasDates.startDate, vendasDates.endDate);
        } else if (activeTab === 'os') {
          await fetchPage('os', 'last', searchTerms.os, osDates.startDate, osDates.endDate);
        } else if (activeTab === 'movimentacoes' && isFinancialAllowed) {
          await fetchPage('movimentacoes', 'last', searchTerms.movimentacoes, movimentacoesDates.startDate, movimentacoesDates.endDate);
        } else if (activeTab === 'recebimentos' && isFinancialAllowed) {
          await fetchPage('recebimentos', 'last', searchTerms.recebimentos, recebimentosDates.startDate, recebimentosDates.endDate);
        }
      } catch (err) {
        logError('Erro ao buscar dados:', err);
        const message = isUnauthorizedError(err)
          ? 'Login aceito, mas a API de dados recusou o token desta conta. Verifique a URL local/ngrok e a chave JWT usada pela API de dados.'
          : 'Falha ao carregar dados do dashboard.';
        setError(message);
      } finally {
        setLoading(false);
      }
    };

    fetchActiveTabData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeTab, fetchChartData, fetchCustomersChartData]);

  useEffect(() => {
    if (activeTab === 'movimentacoes' && isFinancialAllowed) {
      const fetchAccounts = async () => {
        try {
          const api = getApi(true);
          const res = await api.get('/v1/movimentacoes/contas');
          if (res.data) {
            setAccounts(res.data);
          }
        } catch (err) {
          logError('Erro ao buscar contas de movimentacoes:', err);
        }
      };
      fetchAccounts();
    }
  }, [activeTab, getApi, isFinancialAllowed]);

  const handleDateFilterChange = (startDate, endDate) => {
    setOverviewDates({ startDate, endDate });
    fetchChartData(startDate, endDate);
  };

  const handleMovimentacoesDateChange = (startDate, endDate) => {
    setMovimentacoesDates({ startDate, endDate });
    fetchPage('movimentacoes', 1, searchTerms.movimentacoes, startDate, endDate);
  };

  const handleRecebimentosDateChange = (startDate, endDate) => {
    setRecebimentosDates({ startDate, endDate });
    fetchPage('recebimentos', 1, searchTerms.recebimentos, startDate, endDate);
  };

  const handleVendasDateChange = (startDate, endDate) => {
    setVendasDates({ startDate, endDate });
    fetchPage('vendas', 1, searchTerms.vendas, startDate, endDate);
  };

  const handleOsDateChange = (startDate, endDate) => {
    setOsDates({ startDate, endDate });
    fetchPage('os', 1, searchTerms.os, startDate, endDate);
  };

  const handleAccountChange = (newAccount) => {
    setSelectedAccount(newAccount);
    fetchPage('movimentacoes', 1, searchTerms.movimentacoes, null, null, null, newAccount);
  };

  return {
    data,
    pages,
    chartData,
    chartLoading,
    loading,
    error,
    searchTerms,
    setSearchTerms,
    prodFilter,
    setProdFilter: handleProdFilterChange,
    getFilteredData,
    fetchPage,
    handleSearchClick,
    handleClearSearch,
    handleDateFilterChange,
    handleMovimentacoesDateChange,
    handleRecebimentosDateChange,
    handleVendasDateChange,
    handleOsDateChange,
    overviewDates,
    movimentacoesDates,
    recebimentosDates,
    vendasDates,
    osDates,
    accounts,
    selectedAccount,
    onAccountChange: handleAccountChange,
  };
}
