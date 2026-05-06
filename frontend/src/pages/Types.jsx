import { useEffect, useState } from 'react';
import { typesApi } from '../services/api';
import CrudTable from '../components/CrudTable';

const COLONNES = [
  { key: 'id', label: 'ID' },
  { key: 'nom', label: 'Nom' },
  { key: 'description', label: 'Description' },
];

const VIDE = { nom: '', description: '' };

export default function Types() {
  const [types, setTypes] = useState([]);
  const [form, setForm] = useState(VIDE);
  const [editing, setEditing] = useState(null); // id en cours de modification
  const [erreur, setErreur] = useState('');

  async function charger() {
    try {
      setTypes(await typesApi.getAll());
    } catch (e) {
      setErreur(e.message);
    }
  }

  useEffect(() => { charger(); }, []);

  async function handleSubmit(e) {
    e.preventDefault();
    setErreur('');
    try {
      if (editing) {
        await typesApi.update(editing, form);
      } else {
        await typesApi.create(form);
      }
      setForm(VIDE);
      setEditing(null);
      charger();
    } catch (e) {
      setErreur(e.message);
    }
  }

  function handleEdit(type) {
    setEditing(type.id);
    setForm({ nom: type.nom, description: type.description || '' });
  }

  async function handleDelete(id) {
    if (!confirm('Supprimer ce type ?')) return;
    try {
      await typesApi.delete(id);
      charger();
    } catch (e) {
      setErreur(e.message);
    }
  }

  return (
    <div className="page">
      <h2>Types de produits</h2>

      <form className="form-card" onSubmit={handleSubmit}>
        <h3>{editing ? 'Modifier le type' : 'Nouveau type'}</h3>
        <label>Nom *</label>
        <input value={form.nom} onChange={e => setForm({ ...form, nom: e.target.value })} required />
        <label>Description</label>
        <input value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} />
        <div className="form-actions">
          <button type="submit">{editing ? 'Enregistrer' : 'Ajouter'}</button>
          {editing && <button type="button" onClick={() => { setEditing(null); setForm(VIDE); }}>Annuler</button>}
        </div>
      </form>

      <CrudTable colonnes={COLONNES} lignes={types} onEdit={handleEdit} onDelete={handleDelete} erreur={erreur} />
    </div>
  );
}
