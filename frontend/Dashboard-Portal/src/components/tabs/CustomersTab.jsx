import { useState } from 'react';
import { Users, Eye } from 'lucide-react';
import SearchBar from '../SearchBar';
import Pagination from '../Pagination';
import CustomerDetailsModal from '../CustomerDetailsModal';
import ClientesChart from '../charts/ClientesChart';
import { maskPhone } from '../../utils/formatters';

export default function CustomersTab({
  data,
  pages,
  searchTerms,
  setSearchTerms,
  getFilteredData,
  handleSearchClick,
  handleClearSearch,
  fetchPage,
  clientesChartData,
  chartLoading
}) {
  const [selectedCustomer, setSelectedCustomer] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const handleOpenModal = (customer) => {
    setSelectedCustomer(customer);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setSelectedCustomer(null);
    setIsModalOpen(false);
  };

  const customers = getFilteredData('clientes') || [];

  return (
    <div className="crud-container">
      {/* Gráfico de Distribuição / Métricas de Clientes */}
      <ClientesChart data={clientesChartData} loading={chartLoading} />

      {/* Card da Tabela de Clientes */}
      <div className="list-card glass full-width">
        <div className="crud-title-row" style={{ marginBottom: '0.5rem', borderBottom: 'none' }}>
          <h3 style={{ margin: 0, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Users size={20} style={{ color: 'var(--accent)' }} /> 
            Tabela de Clientes Cadastrados
          </h3>
        </div>

        <SearchBar
          value={searchTerms.clientes || ''}
          onChange={(val) => setSearchTerms(prev => ({ ...prev, clientes: val }))}
          onSearch={() => handleSearchClick('clientes')}
          onClear={() => handleClearSearch('clientes')}
          placeholder="Buscar por nome, CPF/CNPJ, celular, cidade, UF..."
        />

        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th scope="col">Código</th>
                <th scope="col">Nome / Razão Social</th>
                <th scope="col">Celular / Contato</th>
                <th scope="col">Cidade</th>
                <th scope="col" style={{ textAlign: 'center' }}>UF</th>
                <th scope="col" className="text-center">Ficha Cadastral</th>
              </tr>
            </thead>
            <tbody>
              {customers.length === 0 ? (
                <tr>
                  <td colSpan="6" style={{ textAlign: 'center', padding: '2.5rem', color: 'var(--text-secondary)' }}>
                    Nenhum cliente encontrado.
                  </td>
                </tr>
              ) : (
                customers.map((item, idx) => (
                  <tr
                    key={item.codigo || idx}
                    onClick={() => handleOpenModal(item)}
                    style={{ cursor: 'pointer' }}
                  >
                    <td data-label="Código">
                      <span className="item-code">#{item.codigo}</span>
                    </td>
                    <td data-label="Nome / Razão Social" style={{ fontWeight: 600 }}>
                      {item.nome || '-'}
                    </td>
                    <td data-label="Celular / Contato">
                      {maskPhone(item.celular) || '-'}
                    </td>
                    <td data-label="Cidade">
                      {item.cidade || '-'}
                    </td>
                    <td data-label="UF" style={{ textAlign: 'center' }}>
                      {item.uf ? (
                        <span className="badge badge-info">
                          {item.uf}
                        </span>
                      ) : '-'}
                    </td>
                    <td data-label="Ficha Cadastral" className="text-center" onClick={(e) => e.stopPropagation()}>
                      <button
                        type="button"
                        onClick={() => handleOpenModal(item)}
                        className="action-btn"
                        title="Visualizar Ficha Completa do Cliente"
                        aria-label="Visualizar Ficha Completa do Cliente"
                      >
                        <Eye size={16} aria-hidden="true" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <Pagination
          currentPage={pages.clientes || 1}
          totalPages={data.clientes?.meta?.pages || 1}
          onPageChange={(page) => fetchPage('clientes', page)}
        />

        {isModalOpen && selectedCustomer && (
          <CustomerDetailsModal
            isOpen={isModalOpen}
            onClose={handleCloseModal}
            customer={selectedCustomer}
          />
        )}
      </div>
    </div>
  );
}
