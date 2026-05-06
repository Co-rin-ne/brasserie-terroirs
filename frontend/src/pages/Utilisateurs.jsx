import { useEffect, useState } from 'react';
import { clientsApi as utilisateursApi } from '../services/api';

export default function Utilisateurs() {
  const [users, setUsers] = useState([]);
  const [form, setForm] = useState({ email: '', mot_de_passe: '', confirmation: '' });
  const [erreur, setErreur] = useState('');
  const [succes, setSucces] = useState('');

  async function charger() {
    try {
      setUsers(await utilisateursApi.getAll());
    } catch (e) {
      setErreur(e.message);
    }
  }

  useEffect(() => { charger(); }, []);

  async function handleSubmit(e) {
    e.preventDefault();
    setErreur('');
    setSucces('');

    if (form.mot_de_passe !== form.confirmation) {
      setErreur('Les mots de passe ne correspondent pas');
      return;
    }

    try {
      await utilisateursApi.create({
        email: form.email,
        mot_de_passe: form.mot_de_passe,
      });
      setSucces(`Administrateur "${form.email}" créé avec succès`);
      setForm({ email: '', mot_de_passe: '', confirmation: '' });
      charger();
    } catch (e) {
      setErreur(e.message);
    }
  }

  async function handleDelete(id, email) {
    if (!confirm(`Supprimer l'admin "${email}" ?`)) return;
    setErreur('');
    try {
      await utilisateursApi.delete(id);
      charger();
    } catch (e) {
      setErreur(e.message);
    }
  }

  return (
    <div className="page">
      <h2>Administrateurs</h2>

      <form className="form-card" onSubmit={handleSubmit}>
        <h3>Nouvel administrateur</h3>

        <label>Email *</label>
        <input
          type="email"
          value={form.email}
          onChange={e => setForm({ ...form, email: e.target.value })}
          required
        />

        <label>Mot de passe * (6 caractères min)</label>
        <input
          type="password"
          value={form.mot_de_passe}
          onChange={e => setForm({ ...form, mot_de_passe: e.target.value })}
          minLength={6}
          required
        />

        <label>Confirmer le mot de passe *</label>
        <input
          type="password"
          value={form.confirmation}
          onChange={e => setForm({ ...form, confirmation: e.target.value })}
          required
        />

        {erreur && <p className="erreur">{erreur}</p>}
        {succes && <p className="succes">{succes}</p>}

        <div className="form-actions">
          <button type="submit">Créer l'administrateur</button>
        </div>
      </form>

      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Email</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          {users.map(u => (
            <tr key={u.id}>
              <td>{u.id}</td>
              <td>{u.email}</td>
              <td>
                <button className="btn-delete" onClick={() => handleDelete(u.id, u.email)}>
                  Supprimer
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
