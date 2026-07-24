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

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem', width: '100%' }}>
      <ClientesChart data={clientesChartData} loading={chartLoading} />

      <div className="list-card glass full-width">
      <h3><Users size={20} /> Tabela de Clientes</h3>
      <SearchBar
        value={searchTerms.clientes}
        onChange={(val) => setSearchTerms(prev => ({ ...prev, clientes: val }))}
        onSearch={() => handleSearchClick('clientes')}
        onClear={() => handleClearSearch('clientes')}
        placeholder="Buscar por nome, celular, cidade, UF..."
      />
      <div className="table-responsive">
        <table className="data-table">
          <thead>
            <tr>
              <th scope="col">Código</th>
              <th scope="col">Nome</th>
              <th scope="col">Celular</th>
              <th scope="col">Cidade</th>
              <th scope="col">UF</th>
              <th scope="col" className="text-center">Ações</th>
            </tr>
          </thead>
          <tbody>
            {getFilteredData('clientes').map((item, idx) => (
              <tr
                key={item.codigo || idx}
                onClick={() => handleOpenModal(item)}
                style={{ cursor: 'pointer' }}
              >
                <td data-label="Código">{item.codigo}</td>
                <td data-label="Nome">{item.nome}</td>
                <td data-label="Celular">{maskPhone(item.celular)}</td>
                <td data-label="Cidade">{item.cidade}</td>
                <td data-label="UF">{item.uf}</td>
                <td data-label="Ações" className="text-center" onClick={(e) => e.stopPropagation()}>
                  <button
                    onClick={() => handleOpenModal(item)}
                    className="action-btn"
                    title="Ver Ficha do Cliente"
                    aria-label="Ver Ficha do Cliente"
                  >
                    <Eye size={16} aria-hidden="true" />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pagination
        currentPage={pages.clientes}
        totalPages={data.clientes.meta?.pages || 1}
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
