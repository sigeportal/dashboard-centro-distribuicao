import { Link } from 'react-router-dom';
import { LayoutDashboard, Users, Package, ArrowRightLeft, DollarSign, ShoppingCart, ShoppingBag, Wrench, Database, FileText, FileCheck2, FileSpreadsheet } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

const navItems = [
  { tab: 'geral', to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { tab: 'clientes', to: '/dashboard?tab=clientes', icon: Users, label: 'Clientes' },
  { tab: 'produtos', to: '/dashboard?tab=produtos', icon: Package, label: 'Produtos' },
  { tab: 'compras', to: '/dashboard?tab=compras', icon: ShoppingBag, label: 'Compras', roles: ['admin', 'gerente'] },
  { tab: 'pedidos-compra', to: '/dashboard?tab=pedidos-compra', icon: FileSpreadsheet, label: 'Pedidos de Compra', roles: ['admin', 'gerente'], hidden: true },
  { tab: 'vendas', to: '/dashboard?tab=vendas', icon: ShoppingCart, label: 'Vendas' },
  { tab: 'os', to: '/dashboard?tab=os', icon: Wrench, label: 'OS' },
  { tab: 'movimentacoes', to: '/dashboard?tab=movimentacoes', icon: ArrowRightLeft, label: 'Movimentações', roles: ['admin', 'gerente'], hidden: true },
  { tab: 'recebimentos', to: '/dashboard?tab=recebimentos', icon: DollarSign, label: 'Recebimentos', roles: ['admin', 'gerente'], hidden: true },
  { tab: 'transferencias', to: '/dashboard?tab=transferencias', icon: ArrowRightLeft, label: 'Centro Distribuição', roles: ['admin', 'gerente'] },
  { tab: 'nfe', to: '/dashboard?tab=nfe', icon: FileText, label: 'Notas Fiscais (NF-e)', roles: ['admin', 'gerente'] },
  { tab: 'conciliacao', to: '/dashboard?tab=conciliacao', icon: FileCheck2, label: 'Conciliação Fiscal', roles: ['admin', 'gerente'], hidden: true },
  { tab: 'cadastros', to: '/dashboard?tab=cadastros', icon: Database, label: 'Cadastros Online', roles: ['admin', 'gerente'] },
];

export default function Sidebar({
  currentTab,
  isMobileMenuOpen,
  onCloseMobileMenu,
  isCollapsed,
  showServiceOrders = false
}) {
  const { userRole } = useAuth();

  const filteredItems = navItems.filter(item => {
    if (item.hidden) {
      return false;
    }
    if (item.tab === 'os' && !showServiceOrders) {
      return false;
    }
    if (item.roles && !item.roles.includes(userRole)) {
      return false;
    }
    return true;
  });

  return (
    <aside className={`sidebar glass ${isMobileMenuOpen ? 'sidebar--open' : ''} ${isCollapsed ? 'sidebar--collapsed' : ''}`}>
      <div className="sidebar-logo">
        <img
          src={isCollapsed ? "/portal_gerencial_icon.svg" : "/portal_gerencial_logo.svg?v=2"}
          alt="Portal Gerencial"
          className="logo-img"
        />
      </div>
      
      <nav className="sidebar-nav">
        {filteredItems.map(({ tab, to, icon: Icon, label }) => (
          <Link
            key={tab}
            to={to}
            className={`nav-item ${currentTab === tab ? 'active' : ''}`}
            onClick={onCloseMobileMenu}
          >
            <Icon size={20} />
            <span>{label}</span>
          </Link>
        ))}
      </nav>
    </aside>
  );
}
