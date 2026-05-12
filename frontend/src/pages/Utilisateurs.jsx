import { useEffect, useState } from 'react';
import { clientsApi as utilisateursApi } from '../services/api';

export default function Utilisateurs() {
  const [users, setUsers] = useState([]);
  const [form, setForm] = useState({ nom: '', email: '', mot_de_passe: '', confirmation: '' });
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
        nom: form.nom,
        email: form.email,
        mot_de_passe: form.mot_de_passe,
      });
      setSucces(`Client "${form.nom}" créé avec succès`);
      setForm({ nom: '', email: '', mot_de_passe: '', confirmation: '' });
      charger();
    } catch (e) {
      setErreur(e.message);
    }
  }

  async function handleDelete(id, nom) {
    if (!confirm(`Supprimer le client "${nom}" ?`)) return;
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
      <h2>Clients</h2>

      <form className="form-card" onSubmit={handleSubmit}>
        <h3>Nouveau client</h3>

        <label>Nom *</label>
        <input
          type="text"
          value={form.nom}
          onChange={e => setForm({ ...form, nom: e.target.value })}
          required
        />

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
          <button type="submit">Créer le client</button>
        </div>
      </form>

      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Nom</th>
            <th>Email</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          {users.map(u => (
            <tr key={u.id}>
              <td data-label="ID">{u.id}</td>
              <td data-label="Nom">{u.nom}</td>
              <td data-label="Email">{u.email}</td>
              <td data-label="Action">
                <button className="btn-delete" onClick={() => handleDelete(u.id, u.nom)}>
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
