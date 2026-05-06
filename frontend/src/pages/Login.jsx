import { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import Inscription from './Inscription';

export default function Login() {
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [motDePasse, setMotDePasse] = useState('');
  const [erreur, setErreur] = useState('');
  const [voirInscription, setVoirInscription] = useState(false);

  if (voirInscription) {
    return <Inscription onRetourLogin={() => setVoirInscription(false)} />;
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setErreur('');
    try {
      await login(email, motDePasse);
    } catch (err) {
      setErreur(err.message);
    }
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <h1>Brasserie Terroir & Savoirs</h1>
        <h2>Connexion</h2>
        <form onSubmit={handleSubmit}>
          <label>Email</label>
          <input type="email" value={email} onChange={e => setEmail(e.target.value)} required />
          <label>Mot de passe</label>
          <input type="password" value={motDePasse} onChange={e => setMotDePasse(e.target.value)} required />
          {erreur && <p className="erreur">{erreur}</p>}
          <button type="submit">Se connecter</button>
        </form>
        <p style={{ textAlign: 'center', marginTop: '1rem', fontSize: '0.875rem', color: '#666' }}>
          Pas encore de compte ?{' '}
          <button onClick={() => setVoirInscription(true)} style={{ background: 'none', border: 'none', color: '#2e6b44', cursor: 'pointer', fontWeight: '600', fontSize: '0.875rem' }}>
            Créer un compte
          </button>
        </p>
      </div>
    </div>
  );
}
