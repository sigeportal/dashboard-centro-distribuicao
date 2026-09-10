import React, { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { Users, Plus, Edit, Trash2, Save, X, Search, Building, Phone, MapPin, Mail } from 'lucide-react';
import { createApi } from '../services/api';
import { toast } from '../contexts/ToastContext';
import './FornecedoresModal.css';

export default function FornecedoresModal({ isOpen, onClose }) {
  if (!isOpen) return null;

  const api = createApi(true);
  const searchInputRef = useRef(null);

  const [fornecedores, setFornecedores] = useState([]);
  const [cidades, setCidades] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  
  // Controle do Formulário (Inserção / Edição)
  const [showForm, setShowForm] = useState(false);
  const [editingItem, setEditingItem] = useState(null);
  const [formData, setFormData] = useState({
    codigo: '',
    nome: '',
    fantasia: '',
    cnpj: '',
    inscricao: '',
    telefone: '',
    email: '',
    endereco: '',
    bairro: '',
    for_cid: '',
    cidade: '',
    uf: 'PR',
    contato: ''
  });

  // Utilitário de máscara para CNPJ / CPF
  const maskCnpjCpf = (val) => {
    if (!val) return '';
    const digits = String(val).replace(/\D/g, '').slice(0, 14);
    if (digits.length <= 11) {
      return digits
        .replace(/(\d{3})(\d)/, '$1.$2')
        .replace(/(\d{3})(\d)/, '$1.$2')
        .replace(/(\d{3})(\d{1,2})$/, '$1-$2');
    }
    return digits
      .replace(/^(\d{2})(\d)/, '$1.$2')
      .replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3')
      .replace(/\.(\d{3})(\d)/, '.$1/$2')
      .replace(/(\d{4})(\d)/, '$1-$2');
  };

  const fetchFornecedores = async () => {
    setLoading(true);
    try {
      const res = await api.get('/v1/fornecedores?limit=500');
      const items = Array.isArray(res.data) ? res.data : (res.data?.data || []);
      setFornecedores(items);
    } catch (err) {
      console.error('Erro ao buscar fornecedores:', err);
      toast.error('Não foi possível carregar a lista de fornecedores.');
    } finally {
      setLoading(false);
    }
  };

  const fetchCidades = async () => {
    try {
      const res = await api.get('/v1/cidades?limit=300');
      const items = Array.isArray(res.data) ? res.data : (res.data?.data || []);
      setCidades(items);
    } catch (err) {
      console.warn('Erro ao carregar cidades:', err);
    }
  };

  useEffect(() => {
    fetchFornecedores();
  }, []);

  // Atalho de Teclado (ESC fecha o modal)
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape') {
        if (showForm) {
          setShowForm(false);
        } else {
          onClose();
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onClose, showForm]);

  const handleOpenCreate = () => {
    if (cidades.length === 0) fetchCidades();
    setEditingItem(null);
    setFormData({
      codigo: '',
      nome: '',
      fantasia: '',
      cnpj: '',
      inscricao: '',
      telefone: '',
      email: '',
      endereco: '',
      bairro: '',
      for_cid: '',
      cidade: '',
      uf: 'PR',
      contato: ''
    });
    setShowForm(true);
  };

  const handleOpenEdit = (item) => {
    if (cidades.length === 0) fetchCidades();
    let cidCod = item.for_cid || item.cid || '';
    let cidNome = typeof item.cidade === 'object' && item.cidade !== null ? (item.cidade.nome || '') : (item.cidade || '');
    let ufSigla = typeof item.uf === 'object' && item.uf !== null ? (item.uf.sigla || '') : (item.uf || 'PR');

    if (cidCod && cidades.length > 0) {
      const found = cidades.find(c => Number(c.codigo) === Number(cidCod));
      if (found) {
        cidNome = found.nome;
        ufSigla = found.uf;
      }
    }

    setEditingItem(item);
    setFormData({
      codigo: item.codigo,
      nome: item.nome || item.razao_social || '',
      fantasia: item.fantasia || item.nome_fantasia || '',
      cnpj: maskCnpjCpf(item.cnpj || item.cnpj_cpf || item.cpf_cnpj || ''),
      inscricao: item.inscricao || item.insc_estadual || '',
      telefone: item.telefone || item.fone || '',
      email: item.email || '',
      endereco: item.endereco || '',
      bairro: item.bairro || '',
      for_cid: cidCod,
      cidade: cidNome,
      uf: ufSigla,
      contato: item.contato || ''
    });
    setShowForm(true);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Tem certeza que deseja excluir este fornecedor?')) return;
    setLoading(true);
    try {
      await api.delete(`/v1/fornecedores/${id}`);
      toast.success('Fornecedor removido com sucesso!');
      await fetchFornecedores();
    } catch (err) {
      console.error(err);
      toast.error('Erro ao excluir fornecedor: ' + (err.response?.data?.error || err.message));
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (e) => {
    e.preventDefault();
    if (!formData.nome.trim()) {
      toast.error('Razão Social / Nome é obrigatório.');
      return;
    }

    setLoading(true);
    try {
      const payload = {
        codigo: editingItem ? Number(formData.codigo) : 0,
        nome: formData.nome.toUpperCase(),
        razao_social: formData.nome.toUpperCase(),
        fantasia: (formData.fantasia || formData.nome).toUpperCase(),
        cnpj_cpf: formData.cnpj.replace(/\D/g, ''),
        insc_estadual: formData.inscricao,
        fone: formData.telefone,
        email: formData.email,
        endereco: formData.endereco,
        bairro: formData.bairro,
        cid: Number(formData.for_cid) || 0,
        for_cid: Number(formData.for_cid) || 0,
        uf: (formData.uf || 'PR').toUpperCase(),
        contato: formData.contato
      };

      if (editingItem) {
        await api.put('/v1/fornecedores', payload);
        toast.success('Fornecedor atualizado com sucesso!');
      } else {
        await api.post('/v1/fornecedores', payload);
        toast.success('Fornecedor cadastrado com sucesso!');
      }

      setShowForm(false);
      await fetchFornecedores();
    } catch (err) {
      console.error(err);
      toast.error('Erro ao salvar fornecedor: ' + (err.response?.data?.error || err.message));
    } finally {
      setLoading(false);
    }
  };

  // Filtragem de fornecedores
  const filteredFornecedores = fornecedores.filter(item => {
    if (!searchTerm) return true;
    const term = searchTerm.toLowerCase();
    const nome = (item.nome || item.razao_social || '').toLowerCase();
    const fantasia = (item.fantasia || item.nome_fantasia || '').toLowerCase();
    const cnpj = String(item.cnpj || item.cnpj_cpf || '').toLowerCase();
    const cod = String(item.codigo || '');
    return nome.includes(term) || fantasia.includes(term) || cnpj.includes(term) || cod.includes(term);
  });

  return createPortal(
    <div className="fornecedores-modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}>
      <div className="fornecedores-modal-container">
        
        {/* Cabeçalho */}
        <div className="fornecedores-modal-header">
          <div className="fornecedores-modal-header-left">
            <div className="fornecedores-icon-badge">
              <Users size={22} />
            </div>
            <div>
              <h3 className="fornecedores-modal-title">Gestão de Fornecedores</h3>
              <p className="fornecedores-modal-subtitle">Consulte, cadastre e edite fornecedores parceiros do catálogo</p>
            </div>
          </div>
          <button className="fornecedores-btn-close" onClick={onClose} title="Fechar (ESC)">
            <X size={20} />
          </button>
        </div>

        {/* Corpo do Modal */}
        <div className="fornecedores-modal-body">
          
          {/* Formulário de Cadastro / Edição */}
          {showForm && (
            <div className="fornecedores-form-card">
              <div className="fornecedores-form-header">
                <h4>
                  <Building size={18} style={{ color: '#ea580c' }} />
                  {editingItem ? `Editar Fornecedor #${formData.codigo}` : 'Novo Fornecedor'}
                </h4>
                <button 
                  type="button" 
                  className="fornecedores-btn-close" 
                  onClick={() => setShowForm(false)} 
                  title="Fechar formulário"
                  style={{ width: '28px', height: '28px' }}
                >
                  <X size={16} />
                </button>
              </div>

              <form onSubmit={handleSave}>
                <div className="fornecedores-form-grid">
                  <label className="fornecedores-form-group">
                    Razão Social / Nome *
                    <input 
                      type="text" 
                      required 
                      value={formData.nome} 
                      onChange={(e) => setFormData({ ...formData, nome: e.target.value.toUpperCase() })} 
                      placeholder="Ex: INDÚSTRIA TÊXTIL LTDA"
                      style={{ textTransform: 'uppercase' }}
                    />
                  </label>

                  <label className="fornecedores-form-group">
                    Nome Fantasia
                    <input 
                      type="text" 
                      value={formData.fantasia} 
                      onChange={(e) => setFormData({ ...formData, fantasia: e.target.value.toUpperCase() })} 
                      placeholder="Ex: TÊXTIL BRASIL"
                      style={{ textTransform: 'uppercase' }}
                    />
                  </label>

                  <label className="fornecedores-form-group">
                    CNPJ / CPF
                    <input 
                      type="text" 
                      value={formData.cnpj} 
                      onChange={(e) => setFormData({ ...formData, cnpj: maskCnpjCpf(e.target.value) })} 
                      placeholder="00.000.000/0000-00"
                    />
                  </label>

                  <label className="fornecedores-form-group">
                    Inscrição Estadual
                    <input 
                      type="text" 
                      value={formData.inscricao} 
                      onChange={(e) => setFormData({ ...formData, inscricao: e.target.value })} 
                      placeholder="Ex: 90123456-78"
                    />
                  </label>

                  <label className="fornecedores-form-group">
                    Telefone / WhatsApp
                    <input 
                      type="text" 
                      value={formData.telefone} 
                      onChange={(e) => setFormData({ ...formData, telefone: e.target.value })} 
                      placeholder="(00) 00000-0000"
                    />
                  </label>

                  <label className="fornecedores-form-group">
                    E-mail
                    <input 
                      type="email" 
                      value={formData.email} 
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })} 
                      placeholder="contato@empresa.com.br"
                    />
                  </label>

                  <label className="fornecedores-form-group">
                    Endereço (Rua e Número)
                    <input 
                      type="text" 
                      value={formData.endereco} 
                      onChange={(e) => setFormData({ ...formData, endereco: e.target.value })} 
                      placeholder="Av. Brasil, 1500"
                    />
                  </label>

                  <label className="fornecedores-form-group">
                    Bairro
                    <input 
                      type="text" 
                      value={formData.bairro} 
                      onChange={(e) => setFormData({ ...formData, bairro: e.target.value })} 
                      placeholder="Centro"
                    />
                  </label>

                  <label className="fornecedores-form-group">
                    Cidade
                    <select 
                      value={formData.for_cid} 
                      onChange={(e) => {
                        const cidId = Number(e.target.value);
                        const matchCid = cidades.find(c => Number(c.codigo) === cidId);
                        setFormData({
                          ...formData,
                          for_cid: cidId,
                          cidade: matchCid ? matchCid.nome : formData.cidade,
                          uf: matchCid ? matchCid.uf : formData.uf
                        });
                      }}
                    >
                      <option value="">-- Selecione a Cidade --</option>
                      {cidades.map(c => (
                        <option key={c.codigo} value={c.codigo}>
                          {c.nome} ({c.uf})
                        </option>
                      ))}
                    </select>
                  </label>

                  <label className="fornecedores-form-group">
                    UF (Estado)
                    <input 
                      type="text" 
                      maxLength={2} 
                      value={formData.uf} 
                      onChange={(e) => setFormData({ ...formData, uf: e.target.value.toUpperCase() })} 
                      placeholder="PR"
                      style={{ textTransform: 'uppercase' }}
                    />
                  </label>

                  <label className="fornecedores-form-group">
                    Contato / Representante
                    <input 
                      type="text" 
                      value={formData.contato} 
                      onChange={(e) => setFormData({ ...formData, contato: e.target.value })} 
                      placeholder="Nome do vendedor/representante"
                    />
                  </label>
                </div>

                <div className="fornecedores-form-actions">
                  <button type="button" className="fornecedores-btn-cancelar" onClick={() => setShowForm(false)}>
                    Cancelar
                  </button>
                  <button type="submit" className="fornecedores-btn-salvar" disabled={loading}>
                    <Save size={16} /> {editingItem ? 'Atualizar Fornecedor' : 'Salvar Fornecedor'}
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* Barra de Ferramentas: Busca + Botão Novo */}
          <div className="fornecedores-toolbar">
            <div className="fornecedores-search-box">
              <Search size={18} />
              <input 
                ref={searchInputRef}
                type="text" 
                className="fornecedores-search-input"
                placeholder="Buscar por razão social, nome fantasia, CNPJ ou código..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>

            {!showForm && (
              <button className="fornecedores-btn-novo" onClick={handleOpenCreate}>
                <Plus size={18} /> Novo Fornecedor
              </button>
            )}
          </div>

          {/* Tabela de Fornecedores */}
          <div className="fornecedores-table-wrap">
            <table className="fornecedores-table">
              <thead>
                <tr>
                  <th style={{ width: '80px' }}>Código</th>
                  <th>Razão Social</th>
                  <th>Nome Fantasia</th>
                  <th>CNPJ / CPF</th>
                  <th>Telefone</th>
                  <th>Cidade / UF</th>
                  <th style={{ textAlign: 'center', width: '100px' }}>Ações</th>
                </tr>
              </thead>
              <tbody>
                {filteredFornecedores.map((item, idx) => {
                  const cidStr = typeof item.cidade === 'object' && item.cidade !== null
                    ? (item.cidade.nome || item.cidade.descricao || '')
                    : (item.cidade || '');
                  const ufStr = typeof item.uf === 'object' && item.uf !== null
                    ? (item.uf.sigla || item.uf.uf || '')
                    : (item.uf || (item.cidade && typeof item.cidade === 'object' ? item.cidade.uf : ''));
                  const locStr = cidStr ? (ufStr ? `${cidStr}/${ufStr}` : cidStr) : (ufStr || '-');

                  return (
                    <tr key={item.codigo || idx}>
                      <td><span className="fornecedores-code-badge">#{item.codigo}</span></td>
                      <td><strong>{item.nome || item.razao_social}</strong></td>
                      <td>{item.fantasia || item.nome_fantasia || '-'}</td>
                      <td style={{ fontFamily: 'monospace', fontSize: '0.85rem' }}>
                        {maskCnpjCpf(item.cnpj || item.cnpj_cpf || item.cpf_cnpj || '') || '-'}
                      </td>
                      <td>{item.telefone || item.fone || item.contato || '-'}</td>
                      <td>{locStr}</td>
                      <td className="fornecedores-actions-cell">
                        <button 
                          className="fornecedores-action-btn edit" 
                          onClick={() => handleOpenEdit(item)}
                          title="Editar Fornecedor"
                        >
                          <Edit size={14} />
                        </button>
                        <button 
                          className="fornecedores-action-btn delete" 
                          onClick={() => handleDelete(item.codigo)}
                          title="Excluir Fornecedor"
                        >
                          <Trash2 size={14} />
                        </button>
                      </td>
                    </tr>
                  );
                })}

                {filteredFornecedores.length === 0 && (
                  <tr>
                    <td colSpan="7" style={{ textAlign: 'center', padding: '2.5rem', color: '#64748b' }}>
                      {loading ? 'Carregando fornecedores...' : 'Nenhum fornecedor encontrado.'}
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

        </div>
      </div>
    </div>,
    document.body
  );
}
