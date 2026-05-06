import { useState } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import Login from './pages/Login';
import Types from './pages/Types';
import Formats from './pages/Formats';
import Produits from './pages/Produits';
import Utilisateurs from './pages/Utilisateurs';
import Catalogue from './pages/Catalogue';
import MaSelection from './pages/MaSelection';
import Profil from './pages/Profil';

const PAGES_ADMIN  = ['Produits', 'Types', 'Formats', 'Clients'];
const PAGES_CLIENT = ['Catalogue', 'Panier', 'Profil'];

function AppContent() {
  const { isAuth, role, nom, logout } = useAuth();
  const [page, setPage] = useState(role === 'admin' ? 'Produits' : 'Catalogue');

  if (!isAuth) return <Login />;

  const pages = role === 'admin' ? PAGES_ADMIN : PAGES_CLIENT;

  return (
    <div className="app">
      <header>
        <img src="/logo.png" alt="Logo" style={{ height: 36, borderRadius: 4 }} />
        <span className="logo">Brasserie T&S</span>
        <nav>
          {pages.map(p => (
            <button key={p} className={page === p ? 'nav-active' : ''} onClick={() => setPage(p)}>
              {p}
            </button>
          ))}
        </nav>
        <span style={{ color: '#aaa', fontSize: '0.85rem' }}>{nom}</span>
        <button className="btn-logout" onClick={logout}>Déconnexion</button>
      </header>

      <main>
        {role === 'admin' && page === 'Produits'  && <Produits />}
        {role === 'admin' && page === 'Types'     && <Types />}
        {role === 'admin' && page === 'Formats'   && <Formats />}
        {role === 'admin' && page === 'Clients'   && <Utilisateurs />}

        {role === 'client' && page === 'Catalogue'    && <Catalogue />}
        {role === 'client' && page === 'Panier' && <MaSelection />}
        {role === 'client' && page === 'Profil'       && <Profil />}
      </main>
    </div>
  );
}

export default function App() {
  return <AuthProvider><AppContent /></AuthProvider>;
}
