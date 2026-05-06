import { useState } from 'react';
import { register } from '../services/api';

export default function Inscription({ onRetourLogin }) {
  const [form, setForm] = useState({ nom: '', email: '', mot_de_passe: '', confirmation: '' });
  const [erreur, setErreur] = useState('');
  const [succes, setSucces] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setErreur('');
    if (form.mot_de_passe !== form.confirmation) {
      setErreur('Les mots de passe ne correspondent pas');
      return;
    }
    try {
      await register(form.nom, form.email, form.mot_de_passe);
      setSucces(true);
    } catch (err) {
      setErreur(err.message);
    }
  }

  if (succes) {
    return (
      <div className="login-page">
        <div className="login-card" style={{ textAlign: 'center' }}>
          <h1>Brasserie T&S</h1>
          <p className="succes" style={{ marginTop: '1rem' }}>Compte créé avec succès !</p>
          <button onClick={onRetourLogin} style={{ marginTop: '1rem', width: '100%', padding: '0.7rem', background: '#2e6b44', color: '#fff', border: 'none', borderRadius: '4px', cursor: 'pointer', fontSize: '1rem' }}>
            Se connecter
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <h1>Brasserie T&S</h1>
        <h2>Créer un compte</h2>
        <form onSubmit={handleSubmit}>
          <label>Nom complet</label>
          <input value={form.nom} onChange={e => setForm({ ...form, nom: e.target.value })} required />
          <label>Email</label>
          <input type="email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} required />
          <label>Mot de passe (6 car. min)</label>
          <input type="password" value={form.mot_de_passe} onChange={e => setForm({ ...form, mot_de_passe: e.target.value })} minLength={6} required />
          <label>Confirmer le mot de passe</label>
          <input type="password" value={form.confirmation} onChange={e => setForm({ ...form, confirmation: e.target.value })} required />
          {erreur && <p className="erreur">{erreur}</p>}
          <button type="submit">Créer mon compte</button>
        </form>
        <p style={{ textAlign: 'center', marginTop: '1rem', fontSize: '0.875rem', color: '#666' }}>
          Déjà un compte ?{' '}
          <button onClick={onRetourLogin} style={{ background: 'none', border: 'none', color: '#2e6b44', cursor: 'pointer', fontWeight: '600', fontSize: '0.875rem' }}>
            Se connecter
          </button>
        </p>
      </div>
    </div>
  );
}
