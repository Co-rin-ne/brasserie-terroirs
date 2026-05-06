import { useEffect, useState } from 'react';
import { formatsApi } from '../services/api';
import CrudTable from '../components/CrudTable';

const COLONNES = [
  { key: 'id', label: 'ID' },
  { key: 'libelle', label: 'Libellé' },
  { key: 'contenance', label: 'Contenance (L)' },
];

const VIDE = { libelle: '', contenance: '' };

export default function Formats() {
  const [formats, setFormats] = useState([]);
  const [form, setForm] = useState(VIDE);
  const [editing, setEditing] = useState(null);
  const [erreur, setErreur] = useState('');

  async function charger() {
    try {
      setFormats(await formatsApi.getAll());
    } catch (e) {
      setErreur(e.message);
    }
  }

  useEffect(() => { charger(); }, []);

  async function handleSubmit(e) {
    e.preventDefault();
    setErreur('');
    try {
      const payload = { libelle: form.libelle, contenance: parseFloat(form.contenance) };
      if (editing) {
        await formatsApi.update(editing, payload);
      } else {
        await formatsApi.create(payload);
      }
      setForm(VIDE);
      setEditing(null);
      charger();
    } catch (e) {
      setErreur(e.message);
    }
  }

  function handleEdit(format) {
    setEditing(format.id);
    setForm({ libelle: format.libelle, contenance: String(format.contenance) });
  }

  async function handleDelete(id) {
    if (!confirm('Supprimer ce format ?')) return;
    try {
      await formatsApi.delete(id);
      charger();
    } catch (e) {
      setErreur(e.message);
    }
  }

  return (
    <div className="page">
      <h2>Formats</h2>

      <form className="form-card" onSubmit={handleSubmit}>
        <h3>{editing ? 'Modifier le format' : 'Nouveau format'}</h3>
        <label>Libellé * (ex: Bouteille 33cl)</label>
        <input value={form.libelle} onChange={e => setForm({ ...form, libelle: e.target.value })} required />
        <label>Contenance en litres *</label>
        <input type="number" step="0.01" min="0" value={form.contenance} onChange={e => setForm({ ...form, contenance: e.target.value })} required />
        <div className="form-actions">
          <button type="submit">{editing ? 'Enregistrer' : 'Ajouter'}</button>
          {editing && <button type="button" onClick={() => { setEditing(null); setForm(VIDE); }}>Annuler</button>}
        </div>
      </form>

      <CrudTable colonnes={COLONNES} lignes={formats} onEdit={handleEdit} onDelete={handleDelete} erreur={erreur} />
    </div>
  );
}
