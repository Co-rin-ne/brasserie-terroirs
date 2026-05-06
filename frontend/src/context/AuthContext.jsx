import { createContext, useContext, useState } from 'react';
import { login as apiLogin } from '../services/api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [token, setToken]   = useState(localStorage.getItem('token'));
  const [role, setRole]     = useState(localStorage.getItem('role'));
  const [nom, setNom]       = useState(localStorage.getItem('nom'));

  async function login(email, motDePasse) {
    const data = await apiLogin(email, motDePasse);
    localStorage.setItem('token', data.token);
    localStorage.setItem('role',  data.role);
    localStorage.setItem('nom',   data.nom);
    setToken(data.token);
    setRole(data.role);
    setNom(data.nom);
  }

  function logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('role');
    localStorage.removeItem('nom');
    setToken(null);
    setRole(null);
    setNom(null);
  }

  return (
    <AuthContext.Provider value={{ token, role, nom, login, logout, isAuth: !!token }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
