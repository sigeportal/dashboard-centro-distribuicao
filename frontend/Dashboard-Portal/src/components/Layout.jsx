import { useState, useEffect, useRef } from 'react';
import { Outlet, useNavigate, useSearchParams } from 'react-router-dom';
import { Building2, KeyRound, LifeBuoy, LogOut, Menu, Wrench } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import Sidebar from './Sidebar';
import PasswordModal from './PasswordModal';
import SupportModal from './SupportModal';
import './Layout.css';

export default function Layout() {
  const navigate = useNavigate();
  const { logout } = useAuth();
  const [searchParams] = useSearchParams();
  const currentTab = searchParams.get('tab') || 'geral';

  const tabLabels = {
    geral: 'Visão Geral',
    clientes: 'Clientes',
    produtos: 'Produtos',
    vendas: 'Vendas',
    os: 'OS',
    movimentacoes: 'Movimentações',
    recebimentos: 'Recebimentos',
    transferencias: 'Centro de Distribuição',
    cadastros: 'Cadastros Centralizados',
  };

  const currentTitle = tabLabels[currentTab] || 'Visão Geral';

  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [showSupportModal, setShowSupportModal] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
  const [isUserMenuOpen, setIsUserMenuOpen] = useState(false);
  const [showServiceOrders, setShowServiceOrders] = useState(() => {
    return localStorage.getItem('dashboard:show-service-orders') === 'true';
  });
  const userMenuRef = useRef(null);

  const isNavExpanded = isMobileMenuOpen || !isSidebarCollapsed;

  const closeMobileMenu = () => setIsMobileMenuOpen(false);

  const handleToggleSidebar = () => {
    if (window.innerWidth <= 768) {
      setIsMobileMenuOpen(!isMobileMenuOpen);
    } else {
      setIsSidebarCollapsed(!isSidebarCollapsed);
    }
  };

  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth <= 768) {
        setIsSidebarCollapsed(false);
      }
    };
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  useEffect(() => {
    if (!isUserMenuOpen) return;

    const handlePointerDown = (event) => {
      if (!userMenuRef.current?.contains(event.target)) {
        setIsUserMenuOpen(false);
      }
    };

    const handleKeyDown = (event) => {
      if (event.key === 'Escape') {
        setIsUserMenuOpen(false);
      }
    };

    document.addEventListener('mousedown', handlePointerDown);
    window.addEventListener('keydown', handleKeyDown);
    return () => {
      document.removeEventListener('mousedown', handlePointerDown);
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [isUserMenuOpen]);

  useEffect(() => {
    if (currentTab === 'os' && !showServiceOrders) {
      navigate('/dashboard', { replace: true });
    }
  }, [currentTab, navigate, showServiceOrders]);

  const handleLogout = () => {
    setIsUserMenuOpen(false);
    logout();
    navigate('/login');
  };

  const handleSwitchCompany = () => {
    setIsUserMenuOpen(false);
    navigate('/empresas');
  };

  const handleOpenSupport = () => {
    setIsUserMenuOpen(false);
    setShowSupportModal(true);
  };

  const handleOpenPassword = () => {
    setIsUserMenuOpen(false);
    setShowPasswordModal(true);
  };

  const handleToggleServiceOrders = () => {
    setShowServiceOrders(prev => {
      const nextValue = !prev;
      localStorage.setItem('dashboard:show-service-orders', String(nextValue));
      return nextValue;
    });
  };

  return (
    <div className="layout-container">
      <Sidebar
        currentTab={currentTab}
        isMobileMenuOpen={isMobileMenuOpen}
        onCloseMobileMenu={closeMobileMenu}
        isCollapsed={isSidebarCollapsed}
        showServiceOrders={showServiceOrders}
      />

      <main className="main-content">
        <header className="header glass">
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <button
               className="hamburger-btn"
               onClick={handleToggleSidebar}
               aria-label={isNavExpanded ? "Recolher menu de navegação" : "Expandir menu de navegação"}
               aria-expanded={isNavExpanded}
            >
              <Menu size={24} aria-hidden="true" />
            </button>
            <div className="header-title">{currentTitle}</div>
          </div>
          <div className="header-user" ref={userMenuRef}>
            <button
              type="button"
              className="user-menu-trigger"
              onClick={() => setIsUserMenuOpen(prev => !prev)}
              aria-label="Abrir menu de usuário"
              aria-haspopup="menu"
              aria-expanded={isUserMenuOpen}
            >
              <img src="/user-avatar.png" alt="" className="avatar" aria-hidden="true" />
            </button>

            {isUserMenuOpen && (
              <div className="user-dropdown" role="menu">
                <button type="button" className="user-dropdown-item support" onClick={handleOpenSupport} role="menuitem">
                  <LifeBuoy size={18} aria-hidden="true" />
                  <span>Suporte</span>
                </button>
                <button type="button" className="user-dropdown-item password" onClick={handleOpenPassword} role="menuitem">
                  <KeyRound size={18} aria-hidden="true" />
                  <span>Alterar Senha</span>
                </button>
                <button type="button" className="user-dropdown-item switch-company" onClick={handleSwitchCompany} role="menuitem">
                  <Building2 size={18} aria-hidden="true" />
                  <span>Trocar Empresa</span>
                </button>
                <button
                  type="button"
                  className="user-dropdown-item service-orders"
                  onClick={handleToggleServiceOrders}
                  role="menuitemcheckbox"
                  aria-checked={showServiceOrders}
                >
                  <Wrench size={18} aria-hidden="true" />
                  <span>Visualizar OS</span>
                  <span className={`user-dropdown-switch ${showServiceOrders ? 'is-active' : ''}`} aria-hidden="true">
                    <span className="user-dropdown-switch-thumb" />
                  </span>
                </button>
                <button type="button" className="user-dropdown-item logout" onClick={handleLogout} role="menuitem">
                  <LogOut size={18} aria-hidden="true" />
                  <span>Sair</span>
                </button>
              </div>
            )}
          </div>
        </header>

        <section className="page-content">
          <Outlet context={{ showServiceOrders }} />
        </section>
      </main>

      {isMobileMenuOpen && (
        <div className="sidebar-overlay" onClick={closeMobileMenu} />
      )}

      <PasswordModal
        isOpen={showPasswordModal}
        onClose={() => setShowPasswordModal(false)}
      />

      <SupportModal
        isOpen={showSupportModal}
        onClose={() => setShowSupportModal(false)}
      />
    </div>
  );
}
