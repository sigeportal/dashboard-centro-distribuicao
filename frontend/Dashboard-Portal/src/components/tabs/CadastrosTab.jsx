import { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Package, Folder, Layers, Ruler, Plus, Edit, Trash2, Save, X, RefreshCw, Grid, AlertCircle, History } from 'lucide-react';
import { createApi } from '../../services/api';
import { formatCurrency, formatDatehora } from '../../utils/formatters';
import Pagination from '../Pagination';
import SearchBar from '../SearchBar';
import './CadastrosTab.css';

export default function CadastrosTab() {
  const api = createApi(true); // Conecta na CD_API_BASE (port 9000)
  const [activeSubTab, setActiveSubTab] = useState('grupos'); // 'grupos', 'subgrupos', 'grades', 'tamanhos', 'produtos'
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [page, setPage] = useState(1);
  const [meta, setMeta] = useState({ page: 1, limit: 10, total: 0, pages: 1 });
  const [searchTerm, setSearchTerm] = useState('');

  // Histórico de Movimentações (HIS_PRO)
  const [selectedHistoryProduct, setSelectedHistoryProduct] = useState(null);
  const [historyData, setHistoryData] = useState([]);
  const [loadingHistory, setLoadingHistory] = useState(false);

  // Listas de Dados
  const [produtos, setProdutos] = useState([]);
  const [grupos, setGrupos] = useState([]);
  const [subgrupos, setSubgrupos] = useState([]);
  const [grades, setGrades] = useState([]);
  const [tamanhos, setTamanhos] = useState([]);
  const [totalizadores, setTotalizadores] = useState([]);

  // Estados de Formulário
  const [editingItem, setEditingItem] = useState(null); // Item em edição
  const [showForm, setShowForm] = useState(false);

  // Campos de Formulário
  const [prodForm, setProdForm] = useState({ 
    codigo: '', 
    nome: '', 
    fabricante: '', 
    codbarra: '', 
    quantidade: 0, 
    valorv: 0, 
    codTotalizador: 1, 
    ncm: '6109.10.00', 
    um: 'UN', 
    cadastrar: 'S', 
    url_Imagem: '', 
    distribute: true 
  });
  const [grupoForm, setGrupoForm] = useState({ codigo: '', nome: '' });
  const [subgrupoForm, setSubgrupoForm] = useState({ codigo: '', nome: '', g1: '', tr: '0' });
  const [gradeForm, setGradeForm] = useState({ codigo: '', pro: '', valor: '', tam: '', quantidade: '', codbarra: '', cor: '' });
  const [tamanhoForm, setTamanhoForm] = useState({ codigo: '', pro: '', tamanho: '', sigla: '', valor: '' });

  useEffect(() => {
    const loadTotalizadores = async () => {
      try {
        const res = await api.get('/v1/totalizadores');
        if (Array.isArray(res.data) && res.data.length > 0) {
          setTotalizadores(res.data);
        } else {
          setTotalizadores([
            { codigo: 1, totalizador: '01T1700', descricao: 'T - Tributado ICMS 17%' },
            { codigo: 2, totalizador: '02T1200', descricao: 'T - Tributado ICMS 12%' },
            { codigo: 3, totalizador: '03T2500', descricao: 'T - Tributado ICMS 25%' },
            { codigo: 4, totalizador: 'F1', descricao: 'F - Substituição Tributária' },
            { codigo: 5, totalizador: 'I1', descricao: 'I - Isento / Não Tributado' },
            { codigo: 6, totalizador: 'N1', descricao: 'N - Não Incidência' }
          ]);
        }
      } catch (err) {
        setTotalizadores([
          { codigo: 1, totalizador: '01T1700', descricao: 'T - Tributado ICMS 17%' },
          { codigo: 2, totalizador: '02T1200', descricao: 'T - Tributado ICMS 12%' },
          { codigo: 3, totalizador: '03T2500', descricao: 'T - Tributado ICMS 25%' },
          { codigo: 4, totalizador: 'F1', descricao: 'F - Substituição Tributária' },
          { codigo: 5, totalizador: 'I1', descricao: 'I - Isento / Não Tributado' },
          { codigo: 6, totalizador: 'N1', descricao: 'N - Não Incidência' }
        ]);
      }
    };
    loadTotalizadores();
  }, []);

  useEffect(() => {
    setSearchTerm('');
    fetchData('last', '');
  }, [activeSubTab]);

  const fetchData = async (targetPage = 'last', search = searchTerm) => {
    setLoading(true);
    setError('');
    try {
      let pageToFetch = targetPage === 'last' ? 1 : targetPage;
      const searchParam = search ? `&search=${encodeURIComponent(search)}` : '';
      let url = `/v1/${activeSubTab}?page=${pageToFetch}&limit=10${searchParam}`;
      let res = await api.get(url);

      let items = [];
      let metaData = { page: pageToFetch, limit: 10, total: 0, pages: 1 };

      if (Array.isArray(res.data)) {
        items = res.data;
        metaData = { page: 1, limit: items.length || 10, total: items.length, pages: 1 };
      } else if (res.data && Array.isArray(res.data.data)) {
        items = res.data.data;
        metaData = res.data.meta || metaData;
      }

      if (targetPage === 'last' && metaData.pages > 1) {
        pageToFetch = metaData.pages;
        url = `/v1/${activeSubTab}?page=${pageToFetch}&limit=10${searchParam}`;
        res = await api.get(url);
        if (Array.isArray(res.data)) {
          items = res.data;
          metaData = { page: 1, limit: items.length || 10, total: items.length, pages: 1 };
        } else if (res.data && Array.isArray(res.data.data)) {
          items = res.data.data;
          metaData = res.data.meta || metaData;
        }
      }

      if (activeSubTab === 'produtos') {
        setProdutos(items);
      } else if (activeSubTab === 'grupos') {
        setGrupos(items);
      } else if (activeSubTab === 'subgrupos') {
        setSubgrupos(items);
      } else if (activeSubTab === 'grades') {
        setGrades(items);
        const [pRes, tRes] = await Promise.all([api.get('/v1/produtos?limit=100'), api.get('/v1/tamanhos?limit=100')]);
        if (Array.isArray(pRes.data)) setProdutos(pRes.data);
        else if (pRes.data?.data) setProdutos(pRes.data.data);
        if (Array.isArray(tRes.data)) setTamanhos(tRes.data);
        else if (tRes.data?.data) setTamanhos(tRes.data.data);
      } else if (activeSubTab === 'tamanhos') {
        setTamanhos(items);
      }

      setMeta(metaData);
      setPage(metaData.page || pageToFetch);
    } catch (err) {
      console.error(err);
      setError('Erro ao carregar dados do servidor central.');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenCreate = () => {
    setEditingItem(null);
    // Reset formulários (Novo produto vem marcado para distribuição por padrão)
    setProdForm({ 
      codigo: '', 
      nome: '', 
      fabricante: '', 
      codbarra: '', 
      quantidade: '', 
      valorv: '', 
      codTotalizador: 1, 
      ncm: '6109.10.00', 
      um: 'UN', 
      cadastrar: 'S', 
      url_Imagem: '', 
      distribute: true 
    });
    setGrupoForm({ codigo: '', nome: '' });
    setSubgrupoForm({ codigo: '', nome: '', g1: '', tr: '0' });
    setGradeForm({ codigo: '', pro: '', valor: '', tam: '', quantidade: '', codbarra: '', cor: '' });
    setTamanhoForm({ codigo: '', pro: '', tamanho: '', sigla: '', valor: '' });
    setShowForm(true);
  };

  const handleOpenEdit = (item) => {
    setEditingItem(item);
    if (activeSubTab === 'produtos') {
      setProdForm({ 
        ...item,
        codTotalizador: item.codTotalizador || item.pro_totalizador || 1,
        ncm: item.ncm || item.pro_ncm || '6109.10.00',
        um: item.um || item.embalagem || item.pro_um || 'UN'
      });
    } else if (activeSubTab === 'grupos') {
      setGrupoForm({ ...item });
    } else if (activeSubTab === 'subgrupos') {
      setSubgrupoForm({ ...item });
    } else if (activeSubTab === 'grades') {
      setGradeForm({ ...item });
    } else if (activeSubTab === 'tamanhos') {
      setTamanhoForm({ ...item });
    }
    setShowForm(true);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Tem certeza que deseja remover este item?')) return;
    setLoading(true);
    try {
      if (activeSubTab === 'produtos') {
        await api.delete(`/v1/produtos/${id}`);
      } else if (activeSubTab === 'grupos') {
        await api.delete(`/v1/grupos/${id}`);
      } else if (activeSubTab === 'subgrupos') {
        await api.delete(`/v1/subgrupos/${id}`);
      } else if (activeSubTab === 'grades') {
        await api.delete(`/v1/grades/${id}`);
      } else if (activeSubTab === 'tamanhos') {
        await api.delete(`/v1/tamanhos/${id}`);
      }
      alert('Removido com sucesso!');
      fetchData();
    } catch (err) {
      alert('Erro ao excluir item.');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      if (activeSubTab === 'produtos') {
        const productCode = editingItem ? Number(prodForm.codigo) : Math.floor(Math.random() * 90000) + 10000;
        const payload = {
          codigo: productCode,
          nome: prodForm.nome,
          fabricante: prodForm.fabricante,
          codbarra: prodForm.codbarra,
          quantidade: Number(prodForm.quantidade) || 0,
          valorv: Number(prodForm.valorv) || 0,
          codTotalizador: Number(prodForm.codTotalizador) || 1,
          ncm: prodForm.ncm || '6109.10.00',
          um: prodForm.um || 'UN',
          embalagem: prodForm.um || 'UN',
          cadastrar: prodForm.cadastrar || 'S',
          url_Imagem: prodForm.url_Imagem || ''
        };
        if (editingItem) {
          await api.put('/v1/produtos', payload);
        } else {
          await api.post('/v1/produtos', payload);
          
          if (prodForm.distribute) {
            // Obter empresas e criar transferencia
            const empRes = await api.get('/v1/empresa');
            if (Array.isArray(empRes.data)) {
              const activeUnitId = Number(localStorage.getItem('selected_company_id')) || 1;
              const otherUnits = empRes.data.filter(u => u.codigo !== activeUnitId);
              
              for (const unit of otherUnits) {
                const transferId = Math.floor(Math.random() * 90000) + 10000;
                const transferData = {
                  id: transferId,
                  origem: activeUnitId,
                  destino: unit.codigo,
                  data: new Date().toISOString().split('T')[0],
                  status: 'Em Trânsito',
                  obs: 'Distribuição automática de novo produto',
                  usuarioRecebimento: '',
                  dataRecebimento: '1899-12-30'
                };
                
                await api.post('/v1/transferencias', transferData);
                
                const itemData = {
                  id: Math.floor(Math.random() * 900000) + 100000,
                  transferenciaId: transferId,
                  produtoId: productCode,
                  quantidade: payload.quantidade > 0 ? payload.quantidade : 0, // Se houver estoque inicial pode transferir a quantidade
                  valor: payload.valorv,
                  quantidadeConferida: 0
                };
                await api.post('/v1/transferenciaItens/emLote', { itens: [itemData] });
              }
            }
          }
        }
      } else if (activeSubTab === 'grupos') {
        const payload = {
          codigo: editingItem ? Number(grupoForm.codigo) : Math.floor(Math.random() * 9000) + 1000,
          nome: grupoForm.nome
        };
        if (editingItem) {
          await api.put('/v1/grupos', payload);
        } else {
          await api.post('/v1/grupos', payload);
        }
      } else if (activeSubTab === 'subgrupos') {
        const payload = {
          codigo: editingItem ? Number(subgrupoForm.codigo) : Math.floor(Math.random() * 9000) + 1000,
          nome: subgrupoForm.nome,
          g1: Number(subgrupoForm.g1),
          tr: Number(subgrupoForm.tr) || 0
        };
        if (editingItem) {
          await api.put('/v1/subgrupos', payload);
        } else {
          await api.post('/v1/subgrupos', payload);
        }
      } else if (activeSubTab === 'grades') {
        const payload = {
          codigo: editingItem ? Number(gradeForm.codigo) : Math.floor(Math.random() * 90000) + 10000,
          pro: Number(gradeForm.pro),
          valor: Number(gradeForm.valor) || 0,
          tam: Number(gradeForm.tam),
          quantidade: Number(gradeForm.quantidade) || 0,
          codbarra: gradeForm.codbarra,
          cor: gradeForm.cor
        };
        if (editingItem) {
          await api.put('/v1/grades', payload);
        } else {
          await api.post('/v1/grades', payload);
        }
      } else if (activeSubTab === 'tamanhos') {
        const payload = {
          codigo: editingItem ? Number(tamanhoForm.codigo) : Math.floor(Math.random() * 9000) + 1000,
          pro: Number(tamanhoForm.pro) || 0,
          tamanho: tamanhoForm.tamanho,
          sigla: tamanhoForm.sigla,
          valor: Number(tamanhoForm.valor) || 0
        };
        if (editingItem) {
          await api.put('/v1/tamanhos', payload);
        } else {
          await api.post('/v1/tamanhos', payload);
        }
      }

      alert('Salvo com sucesso!');
      setShowForm(false);
      fetchData(activeSubTab, page, searchTerm);
    } catch (err) {
      console.error(err);
      alert('Erro ao excluir registro.');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenHistoryModal = async (product) => {
    setSelectedHistoryProduct(product);
    setLoadingHistory(true);
    try {
      const res = await api.get(`/v1/historico-estoque?pro_codigo=${product.codigo}`);
      if (res.data && Array.isArray(res.data.data)) {
        setHistoryData(res.data.data);
      } else if (Array.isArray(res.data)) {
        setHistoryData(res.data);
      } else {
        setHistoryData([]);
      }
    } catch (err) {
      console.error('Erro ao buscar histórico de estoque:', err);
      setHistoryData([]);
    } finally {
      setLoadingHistory(false);
    }
  };

  return (
    <div className="crud-container full-width">
      
      {/* Sub Menu de Cadastros */}
      <div className="crud-header-tabs glass">
        <button className={`crud-tab-btn ${activeSubTab === 'grupos' ? 'active' : ''}`} onClick={() => { setActiveSubTab('grupos'); setShowForm(false); }}>
          <Folder size={18} /> Grupos
        </button>
        <button className={`crud-tab-btn ${activeSubTab === 'subgrupos' ? 'active' : ''}`} onClick={() => { setActiveSubTab('subgrupos'); setShowForm(false); }}>
          <Layers size={18} /> Subgrupos
        </button>
        <button className={`crud-tab-btn ${activeSubTab === 'grades' ? 'active' : ''}`} onClick={() => { setActiveSubTab('grades'); setShowForm(false); }}>
          <Grid size={18} /> Grades
        </button>
        <button className={`crud-tab-btn ${activeSubTab === 'tamanhos' ? 'active' : ''}`} onClick={() => { setActiveSubTab('tamanhos'); setShowForm(false); }}>
          <Ruler size={18} /> Tamanhos
        </button>
        <button className={`crud-tab-btn ${activeSubTab === 'produtos' ? 'active' : ''}`} onClick={() => { setActiveSubTab('produtos'); setShowForm(false); }}>
          <Package size={18} /> Produtos
        </button>
      </div>

      {error && <div className="crud-error-bar"><AlertCircle size={20} /> {error}</div>}

      {/* TELA DE FORMULÁRIO (Criação ou Edição) */}
      {showForm && (
        <div className="list-card glass">
          <div className="crud-title-row">
            <h4>{editingItem ? 'Editar Registro' : 'Cadastrar Novo Registro'}</h4>
            <button className="crud-close-btn" onClick={() => setShowForm(false)}><X size={18} /></button>
          </div>

          <form onSubmit={handleSave} className="crud-form">
            
            {/* FORM: PRODUTOS */}
            {activeSubTab === 'produtos' && (
              <div className="grid-form">
                <label className="crud-input">
                  Nome do Produto *
                  <input type="text" value={prodForm.nome} onChange={(e) => setProdForm({ ...prodForm, nome: e.target.value })} required />
                </label>
                <label className="crud-input">
                  Fabricante/Marca
                  <input type="text" value={prodForm.fabricante} onChange={(e) => setProdForm({ ...prodForm, fabricante: e.target.value })} />
                </label>
                <label className="crud-input">
                  Código de Barras (EAN)
                  <input type="text" value={prodForm.codbarra} onChange={(e) => setProdForm({ ...prodForm, codbarra: e.target.value })} />
                </label>
                <label className="crud-input">
                  NCM (Classificação Fiscal) *
                  <input type="text" required value={prodForm.ncm || '6109.10.00'} onChange={(e) => setProdForm({ ...prodForm, ncm: e.target.value })} placeholder="Ex: 6109.10.00" />
                </label>
                <label className="crud-input">
                  Unidade de Medida (UM) *
                  <select value={prodForm.um || 'UN'} onChange={(e) => setProdForm({ ...prodForm, um: e.target.value })}>
                    <option value="UN">UN - Unidade</option>
                    <option value="PC">PC - Peça</option>
                    <option value="KG">KG - Quilograma</option>
                    <option value="PAR">PAR - Par</option>
                    <option value="CX">CX - Caixa</option>
                    <option value="MT">MT - Metro</option>
                    <option value="L">L - Litro</option>
                  </select>
                </label>
                <label className="crud-input">
                  Totalizador Fiscal (ICMS/ISS) *
                  <select value={prodForm.codTotalizador || 1} onChange={(e) => setProdForm({ ...prodForm, codTotalizador: Number(e.target.value) })}>
                    {totalizadores.map(tot => (
                      <option key={tot.codigo} value={tot.codigo}>
                        #{tot.codigo} - {tot.totalizador} ({tot.descricao || 'Tributado'})
                      </option>
                    ))}
                  </select>
                </label>
                <label className="crud-input">
                  Estoque Inicial
                  <input type="number" value={prodForm.quantidade} onChange={(e) => setProdForm({ ...prodForm, quantidade: e.target.value })} />
                </label>
                <label className="crud-input">
                  Preço de Venda (R$)
                  <input type="number" step="0.01" value={prodForm.valorv} onChange={(e) => setProdForm({ ...prodForm, valorv: e.target.value })} />
                </label>
                <label className="crud-input">
                  URL da Imagem
                  <input type="text" value={prodForm.url_Imagem} onChange={(e) => setProdForm({ ...prodForm, url_Imagem: e.target.value })} />
                </label>
                {!editingItem && (
                  <label className="crud-checkbox-container" style={{ gridColumn: '1 / -1', display: 'flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', marginTop: '1rem' }}>
                    <input type="checkbox" checked={prodForm.distribute !== false} onChange={(e) => setProdForm({ ...prodForm, distribute: e.target.checked })} />
                    <span style={{ fontSize: '0.9rem', color: 'var(--text-color)' }}>
                      Distribuir para Filiais (Gera transferência de estoque agendada para outras unidades)
                    </span>
                  </label>
                )}
              </div>
            )}

            {/* FORM: GRUPOS */}
            {activeSubTab === 'grupos' && (
              <div className="grid-form">
                <label className="crud-input">
                  Nome do Grupo
                  <input type="text" value={grupoForm.nome} onChange={(e) => setGrupoForm({ ...grupoForm, nome: e.target.value })} required />
                </label>
              </div>
            )}

            {/* FORM: SUBGRUPOS */}
            {activeSubTab === 'subgrupos' && (
              <div className="grid-form">
                <label className="crud-input">
                  Nome do Subgrupo
                  <input type="text" value={subgrupoForm.nome} onChange={(e) => setSubgrupoForm({ ...subgrupoForm, nome: e.target.value })} required />
                </label>
                <label className="crud-input">
                  Associação de Grupo (G1 ID)
                  <input type="number" value={subgrupoForm.g1} onChange={(e) => setSubgrupoForm({ ...subgrupoForm, g1: e.target.value })} required />
                </label>
                <label className="crud-input">
                  TR Código (Padrão: 0)
                  <input type="number" value={subgrupoForm.tr} onChange={(e) => setSubgrupoForm({ ...subgrupoForm, tr: e.target.value })} />
                </label>
              </div>
            )}

            {/* FORM: GRADES */}
            {activeSubTab === 'grades' && (
              <div className="grid-form">
                <label className="crud-input">
                  Produto Relacionado
                  <select value={gradeForm.pro} onChange={(e) => setGradeForm({ ...gradeForm, pro: e.target.value })} required>
                    <option value="">Selecione...</option>
                    {produtos.map(p => <option key={p.codigo} value={p.codigo}>{p.nome}</option>)}
                  </select>
                </label>
                <label className="crud-input">
                  Tamanho (Variação)
                  <select value={gradeForm.tam} onChange={(e) => setGradeForm({ ...gradeForm, tam: e.target.value })} required>
                    <option value="">Selecione...</option>
                    {tamanhos.map(t => <option key={t.codigo} value={t.codigo}>{t.tamanho} ({t.sigla})</option>)}
                  </select>
                </label>
                <label className="crud-input">
                  Quantidade física na Grade
                  <input type="number" value={gradeForm.quantidade} onChange={(e) => setGradeForm({ ...gradeForm, quantidade: e.target.value })} />
                </label>
                <label className="crud-input">
                  Valor Unitário da Variação (R$)
                  <input type="number" step="0.01" value={gradeForm.valor} onChange={(e) => setGradeForm({ ...gradeForm, valor: e.target.value })} />
                </label>
                <label className="crud-input">
                  Código de Barras específico
                  <input type="text" value={gradeForm.codbarra} onChange={(e) => setGradeForm({ ...gradeForm, codbarra: e.target.value })} />
                </label>
                <label className="crud-input">
                  Cor da variação
                  <input type="text" value={gradeForm.cor} onChange={(e) => setGradeForm({ ...gradeForm, cor: e.target.value })} />
                </label>
              </div>
            )}

            {/* FORM: TAMANHOS */}
            {activeSubTab === 'tamanhos' && (
              <div className="grid-form">
                <label className="crud-input">
                  Descrição do Tamanho
                  <input type="text" value={tamanhoForm.tamanho} onChange={(e) => setTamanhoForm({ ...tamanhoForm, tamanho: e.target.value })} placeholder="Ex: Médio" required />
                </label>
                <label className="crud-input">
                  Sigla
                  <input type="text" maxLength="2" value={tamanhoForm.sigla} onChange={(e) => setTamanhoForm({ ...tamanhoForm, sigla: e.target.value })} placeholder="Ex: M" required />
                </label>
                <label className="crud-input">
                  Valor / Multiplicador
                  <input type="number" step="0.0001" value={tamanhoForm.valor} onChange={(e) => setTamanhoForm({ ...tamanhoForm, valor: e.target.value })} />
                </label>
                <label className="crud-input">
                  Código de Referência de Produto (Padrão: 0)
                  <input type="number" value={tamanhoForm.pro} onChange={(e) => setTamanhoForm({ ...tamanhoForm, pro: e.target.value })} />
                </label>
              </div>
            )}

            <button type="submit" className="crud-save-btn" disabled={loading}>
              <Save size={18} /> Salvar Alterações
            </button>
          </form>
        </div>
      )}

      {/* TELA DE TABELA / LISTA */}
      {!showForm && (
        <div className="list-card glass">
          <div className="crud-title-row">
            <h3>Gerenciamento de {activeSubTab.toUpperCase()}</h3>
            <div style={{ display: 'flex', gap: '0.75rem' }}>
              <button className="refresh-btn" onClick={fetchData} disabled={loading}><RefreshCw size={18} /> Atualizar</button>
              <button className="crud-add-btn" onClick={handleOpenCreate}><Plus size={18} /> Adicionar Novo</button>
            </div>
          </div>

          {loading && <div className="loading-bar">Buscando do Banco Online...</div>}

          <div className="table-responsive">
            <table className="data-table">
              
              {/* LIST: PRODUTOS */}
              {activeSubTab === 'produtos' && (
                <>
                  <thead>
                    <tr>
                      <th>Código</th>
                      <th>Nome</th>
                      <th>Marca</th>
                      <th>NCM</th>
                      <th>UM</th>
                      <th>Totalizador</th>
                      <th>Estoque</th>
                      <th>Preço</th>
                      <th>Cód. Barras</th>
                      <th>Ações</th>
                    </tr>
                  </thead>
                  <tbody>
                    {produtos.map((item, idx) => (
                      <tr key={item.codigo || idx}>
                        <td><span className="item-code">#{item.codigo}</span></td>
                        <td>{item.nome}</td>
                        <td>{item.fabricante || '-'}</td>
                        <td><span className="badge badge-info">{item.ncm || item.pro_ncm || '6109.10.00'}</span></td>
                        <td><strong>{item.um || item.embalagem || item.pro_um || 'UN'}</strong></td>
                        <td><span className="badge badge-success">#{item.codTotalizador || item.pro_totalizador || 1}</span></td>
                        <td>{item.quantidade}</td>
                        <td>R$ {Number(item.valorv).toFixed(2)}</td>
                        <td>{item.codbarra || '-'}</td>
                        <td className="actions-cell">
                          <button className="crud-row-btn" onClick={() => handleOpenHistoryModal(item)} title="Ver Histórico (HIS_PRO)" style={{ background: 'rgba(99, 102, 241, 0.15)', color: '#6366f1' }}><History size={14} /></button>
                          <button className="crud-row-btn edit" onClick={() => handleOpenEdit(item)}><Edit size={14} /></button>
                          <button className="crud-row-btn delete" onClick={() => handleDelete(item.codigo)}><Trash2 size={14} /></button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </>
              )}

              {/* LIST: GRUPOS */}
              {activeSubTab === 'grupos' && (
                <>
                  <thead>
                    <tr>
                      <th>Código Grupo</th>
                      <th>Nome</th>
                      <th>Ações</th>
                    </tr>
                  </thead>
                  <tbody>
                    {grupos.map((item, idx) => (
                      <tr key={item.codigo || idx}>
                        <td><span className="item-code">#{item.codigo}</span></td>
                        <td>{item.nome}</td>
                        <td className="actions-cell">
                          <button className="crud-row-btn edit" onClick={() => handleOpenEdit(item)}><Edit size={14} /></button>
                          <button className="crud-row-btn delete" onClick={() => handleDelete(item.codigo)}><Trash2 size={14} /></button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </>
              )}

              {/* LIST: SUBGRUPOS */}
              {activeSubTab === 'subgrupos' && (
                <>
                  <thead>
                    <tr>
                      <th>Código Subgrupo</th>
                      <th>Nome</th>
                      <th>ID Grupo Relacionado (G1)</th>
                      <th>TR</th>
                      <th>Ações</th>
                    </tr>
                  </thead>
                  <tbody>
                    {subgrupos.map((item, idx) => (
                      <tr key={item.codigo || idx}>
                        <td><span className="item-code">#{item.codigo}</span></td>
                        <td>{item.nome}</td>
                        <td>#{item.g1}</td>
                        <td>{item.tr}</td>
                        <td className="actions-cell">
                          <button className="crud-row-btn edit" onClick={() => handleOpenEdit(item)}><Edit size={14} /></button>
                          <button className="crud-row-btn delete" onClick={() => handleDelete(item.codigo)}><Trash2 size={14} /></button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </>
              )}

              {/* LIST: GRADES */}
              {activeSubTab === 'grades' && (
                <>
                  <thead>
                    <tr>
                      <th>Cód Grade</th>
                      <th>Produto</th>
                      <th>Tamanho</th>
                      <th>Estoque</th>
                      <th>Preço</th>
                      <th>Cor</th>
                      <th>Cod. Barras</th>
                      <th>Ações</th>
                    </tr>
                  </thead>
                  <tbody>
                    {grades.map((item, idx) => {
                      const prod = produtos.find(p => p.codigo === item.pro);
                      const tam = tamanhos.find(t => t.codigo === item.tam);
                      return (
                        <tr key={item.codigo || idx}>
                          <td><span className="item-code">#{item.codigo}</span></td>
                          <td>{prod ? prod.nome : `Produto #${item.pro}`}</td>
                          <td>{tam ? `${tam.tamanho} (${tam.sigla})` : `Tamanho #${item.tam}`}</td>
                          <td>{item.quantidade}</td>
                          <td>R$ {Number(item.valor).toFixed(2)}</td>
                          <td>{item.cor || '-'}</td>
                          <td>{item.codbarra || '-'}</td>
                          <td className="actions-cell">
                            <button className="crud-row-btn edit" onClick={() => handleOpenEdit(item)}><Edit size={14} /></button>
                            <button className="crud-row-btn delete" onClick={() => handleDelete(item.codigo)}><Trash2 size={14} /></button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </>
              )}

              {/* LIST: TAMANHOS */}
              {activeSubTab === 'tamanhos' && (
                <>
                  <thead>
                    <tr>
                      <th>Cod Tamanho</th>
                      <th>Descrição</th>
                      <th>Sigla</th>
                      <th>Valor/Peso</th>
                      <th>Pro ID</th>
                      <th>Ações</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tamanhos.map((item, idx) => (
                      <tr key={item.codigo || idx}>
                        <td><span className="item-code">#{item.codigo}</span></td>
                        <td>{item.tamanho}</td>
                        <td><span className="sigla-tag">{item.sigla}</span></td>
                        <td>{item.valor}</td>
                        <td>{item.pro}</td>
                        <td className="actions-cell">
                          <button className="crud-row-btn edit" onClick={() => handleOpenEdit(item)}><Edit size={14} /></button>
                          <button className="crud-row-btn delete" onClick={() => handleDelete(item.codigo)}><Trash2 size={14} /></button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </>
              )}

            </table>
          </div>
          
          <Pagination
            currentPage={meta.page || page}
            totalPages={meta.pages || 1}
            onPageChange={(p) => fetchData(p, searchTerm)}
          />
        </div>
      )}

      {/* MODAL POPUP DE HISTÓRICO DE MOVIMENTAÇÃO (HIS_PRO) */}
      {selectedHistoryProduct && createPortal(
        <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setSelectedHistoryProduct(null); }}>
          <div className="modal-content glass" style={{ maxWidth: '900px', width: '92vw' }}>
            <div className="modal-header">
              <h4><History size={20} style={{ color: 'var(--accent-primary)' }} /> Histórico de Movimentações (HIS_PRO): #{selectedHistoryProduct.codigo} - {selectedHistoryProduct.nome}</h4>
              <button className="btn-close" onClick={() => setSelectedHistoryProduct(null)}><X size={18} /></button>
            </div>
            <div className="modal-body" style={{ padding: '1rem 0' }}>
              {loadingHistory ? (
                <div style={{ textAlign: 'center', padding: '2rem' }}>Carregando histórico de movimentação...</div>
              ) : historyData.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>Nenhuma movimentação de estoque registrada para este produto.</div>
              ) : (
                <div className="table-responsive" style={{ maxHeight: '420px', overflowY: 'auto' }}>
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Data</th>
                        <th>Origem / Operação</th>
                        <th>Doc. / Ref</th>
                        <th>Tipo</th>
                        <th>Qtd Movimentada</th>
                        <th>Qtd Anterior</th>
                        <th>Custo Entrada</th>
                        <th>Custo Médio</th>
                        <th>Valor Venda</th>
                      </tr>
                    </thead>
                    <tbody>
                      {historyData.map((h, idx) => (
                        <tr key={h.hp_codigo || idx}>
                          <td>{formatDatehora(h.hp_data)}</td>
                          <td><strong>{h.hp_origem || '-'}</strong></td>
                          <td>{h.hp_doc || '-'}</td>
                          <td>
                            <span className={`badge ${h.hp_tipo === 'E' ? 'badge-success' : h.hp_tipo === 'S' ? 'badge-danger' : 'badge-info'}`}>
                              {h.hp_tipo === 'E' ? 'Entrada' : h.hp_tipo === 'S' ? 'Saída' : h.hp_tipo || 'Movimento'}
                            </span>
                          </td>
                          <td><strong>{h.hp_quantidade}</strong></td>
                          <td>{h.hp_quantidadea || 0}</td>
                          <td>{formatCurrency(h.hp_valorc || 0)}</td>
                          <td>{formatCurrency(h.hp_valorcm || 0)}</td>
                          <td>{formatCurrency(h.hp_valorv || 0)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
            <div className="modal-footer" style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '1rem' }}>
              <button className="btn-secondary" onClick={() => setSelectedHistoryProduct(null)}>Fechar</button>
            </div>
          </div>
        </div>,
        document.body
      )}

    </div>
  );
}
