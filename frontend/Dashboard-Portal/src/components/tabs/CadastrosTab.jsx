import { useState, useEffect } from 'react';
import { Package, Folder, Layers, Ruler, Plus, Edit, Trash2, Save, X, RefreshCw, Grid } from 'lucide-react';
import { createApi } from '../../services/api';
import './CadastrosTab.css';

export default function CadastrosTab() {
  const api = createApi(true); // Conecta na CD_API_BASE (port 9000)
  const [activeSubTab, setActiveSubTab] = useState('produtos'); // 'produtos', 'grupos', 'subgrupos', 'grades', 'tamanhos'
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  // Listas de Dados
  const [produtos, setProdutos] = useState([]);
  const [grupos, setGrupos] = useState([]);
  const [subgrupos, setSubgrupos] = useState([]);
  const [grades, setGrades] = useState([]);
  const [tamanhos, setTamanhos] = useState([]);

  // Estados de Formulário
  const [editingItem, setEditingItem] = useState(null); // Item em edição
  const [showForm, setShowForm] = useState(false);

  // Campos de Formulário
  const [prodForm, setProdForm] = useState({ codigo: '', nome: '', fabricante: '', codbarra: '', quantidade: 0, valorv: 0, cadastrar: 'S', url_Imagem: '', distribute: true });
  const [grupoForm, setGrupoForm] = useState({ codigo: '', nome: '' });
  const [subgrupoForm, setSubgrupoForm] = useState({ codigo: '', nome: '', g1: '', tr: '0' });
  const [gradeForm, setGradeForm] = useState({ codigo: '', pro: '', valor: '', tam: '', quantidade: '', codbarra: '', cor: '' });
  const [tamanhoForm, setTamanhoForm] = useState({ codigo: '', pro: '', tamanho: '', sigla: '', valor: '' });

  useEffect(() => {
    fetchData();
  }, [activeSubTab]);

  const fetchData = async () => {
    setLoading(true);
    setError('');
    try {
      if (activeSubTab === 'produtos') {
        const res = await api.get('/v1/produtos');
        if (Array.isArray(res.data)) setProdutos(res.data);
      } else if (activeSubTab === 'grupos') {
        const res = await api.get('/v1/grupos');
        if (Array.isArray(res.data)) setGrupos(res.data);
      } else if (activeSubTab === 'subgrupos') {
        const res = await api.get('/v1/subgrupos');
        if (Array.isArray(res.data)) setSubgrupos(res.data);
      } else if (activeSubTab === 'grades') {
        const res = await api.get('/v1/grades');
        if (Array.isArray(res.data)) setGrades(res.data);
        // Busca produtos e tamanhos auxiliares para os dropdowns da grade
        const [pRes, tRes] = await Promise.all([api.get('/v1/produtos'), api.get('/v1/tamanhos')]);
        if (Array.isArray(pRes.data)) setProdutos(pRes.data);
        if (Array.isArray(tRes.data)) setTamanhos(tRes.data);
      } else if (activeSubTab === 'tamanhos') {
        const res = await api.get('/v1/tamanhos');
        if (Array.isArray(res.data)) setTamanhos(res.data);
      }
    } catch (err) {
      console.error(err);
      setError('Erro ao carregar dados do servidor central.');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenCreate = () => {
    setEditingItem(null);
    // Reset formulários
    setProdForm({ codigo: '', nome: '', fabricante: '', codbarra: '', quantidade: '', valorv: '', cadastrar: 'S', url_Imagem: '' });
    setGrupoForm({ codigo: '', nome: '' });
    setSubgrupoForm({ codigo: '', nome: '', g1: '', tr: '0' });
    setGradeForm({ codigo: '', pro: '', valor: '', tam: '', quantidade: '', codbarra: '', cor: '' });
    setTamanhoForm({ codigo: '', pro: '', tamanho: '', sigla: '', valor: '' });
    setShowForm(true);
  };

  const handleOpenEdit = (item) => {
    setEditingItem(item);
    if (activeSubTab === 'produtos') {
      setProdForm({ ...item });
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
          cadastrar: prodForm.cadastrar,
          url_Imagem: prodForm.url_Imagem
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
      fetchData();
    } catch (err) {
      console.error(err);
      alert('Erro ao salvar os dados.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="crud-container full-width">
      
      {/* Sub Menu de Cadastros */}
      <div className="crud-header-tabs glass">
        <button className={`crud-tab-btn ${activeSubTab === 'produtos' ? 'active' : ''}`} onClick={() => { setActiveSubTab('produtos'); setShowForm(false); }}>
          <Package size={18} /> Produtos
        </button>
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
                  Nome do Produto
                  <input type="text" value={prodForm.nome} onChange={(e) => setProdForm({ ...prodForm, nome: e.target.value })} required />
                </label>
                <label className="crud-input">
                  Fabricante/Marca
                  <input type="text" value={prodForm.fabricante} onChange={(e) => setProdForm({ ...prodForm, fabricante: e.target.value })} />
                </label>
                <label className="crud-input">
                  Código de Barras
                  <input type="text" value={prodForm.codbarra} onChange={(e) => setProdForm({ ...prodForm, codbarra: e.target.value })} />
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
                    <input type="checkbox" checked={prodForm.distribute} onChange={(e) => setProdForm({ ...prodForm, distribute: e.target.checked })} />
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
                        <td>{item.quantidade}</td>
                        <td>R$ {Number(item.valorv).toFixed(2)}</td>
                        <td>{item.codbarra || '-'}</td>
                        <td className="actions-cell">
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
        </div>
      )}

    </div>
  );
}
