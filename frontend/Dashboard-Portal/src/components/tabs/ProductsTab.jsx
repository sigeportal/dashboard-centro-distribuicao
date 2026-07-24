import { Package } from 'lucide-react';
import SearchBar from '../SearchBar';
import Pagination from '../Pagination';
import { formatCurrency } from '../../utils/formatters';

export default function ProductsTab({ data, pages, searchTerms, setSearchTerms, prodFilter, setProdFilter, getFilteredData, handleSearchClick, handleClearSearch, fetchPage }) {
  return (
    <div className="list-card glass full-width">
      <h3><Package size={20} /> Tabela de Produtos</h3>
      <SearchBar
        value={searchTerms.produtos}
        onChange={(val) => setSearchTerms(prev => ({ ...prev, produtos: val }))}
        onSearch={() => handleSearchClick('produtos')}
        onClear={() => handleClearSearch('produtos')}
        placeholder="Buscar por nome, fabricante, código de barras..."
      />

      {/* Filtros rápidos de Produtos */}
      <div className="filter-bar">
        <button className={`filter-btn ${prodFilter === 'todos' ? 'active' : ''}`} onClick={() => setProdFilter('todos')}>Todos</button>
        <button className={`filter-btn filter-warning ${prodFilter === 'acabando' ? 'active' : ''}`} onClick={() => setProdFilter('acabando')}>Quase Acabando</button>
        <button className={`filter-btn filter-aberto ${prodFilter === 'sem_estoque' ? 'active' : ''}`} onClick={() => setProdFilter('sem_estoque')}>Sem Estoque</button>
      </div>
      <div className="table-responsive">
        <table className="data-table">
          <thead>
            <tr>
              <th scope="col">Código</th>
              <th scope="col">Nome</th>
              <th scope="col">Fabricante</th>
              <th scope="col">Cód. Barras</th>
              <th scope="col">Quantidade</th>
              <th scope="col">Valor (Venda)</th>
            </tr>
          </thead>
          <tbody>
            {getFilteredData('produtos').map((item, idx) => (
              <tr key={item.codigo || idx} className={prodFilter === 'sem_estoque' ? 'row-danger' : prodFilter === 'acabando' ? 'row-warning' : ''}>
                <td data-label="Código">{item.codigo ? <span className="item-code">#{item.codigo}</span> : '-'}</td>
                <td data-label="Nome">{item.nome}</td>
                <td data-label="Fabricante">{item.fabricante}</td>
                <td data-label="Cód. Barras">{item.codbarra}</td>
                <td data-label="Quantidade">{item.quantidade}</td>
                <td data-label="Valor (Venda)">{formatCurrency(item.valorv)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Pagination
        currentPage={pages.produtos}
        totalPages={data.produtos.meta?.pages || 1}
        onPageChange={(page) => fetchPage('produtos', page)}
      />
    </div>
  );
}
