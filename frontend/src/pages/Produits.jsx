import { useEffect, useState } from 'react';
import { produitsApi, typesApi, formatsApi } from '../services/api';
import CrudTable from '../components/CrudTable';

const COLONNES = [
  { key: 'image_url', label: 'Photo' },
  { key: 'nom', label: 'Nom' },
  { key: 'type_nom', label: 'Type' },
  { key: 'format_libelle', label: 'Format' },
  { key: 'quantite_stock', label: 'Stock' },
  { key: 'prix', label: 'Prix (€)' },
];

const VIDE = { nom: '', description: '', quantite_stock: 0, prix: '', image_url: '', id_type: '', id_format: '' };

function renderCell(key, value) {
  if (key === 'image_url' && value) {
    return <img src={value} alt="" style={{ width: 48, height: 48, objectFit: 'cover', borderRadius: 6 }} />;
  }
  if (key === 'prix' && value !== undefined) return `${Number(value).toFixed(2)} €`;
  return value ?? '—';
}

export default function Produits() {
  const [produits, setProduits] = useState([]);
  const [types, setTypes] = useState([]);
  const [formats, setFormats] = useState([]);
  const [form, setForm] = useState(VIDE);
  const [editing, setEditing] = useState(null);
  const [erreur, setErreur] = useState('');

  async function charger() {
    try {
      const [p, t, f] = await Promise.all([
        produitsApi.getAll(),
        typesApi.getAll(),
        formatsApi.getAll(),
      ]);
      setProduits(p);
      setTypes(t);
      setFormats(f);
    } catch (e) {
      setErreur(e.message);
    }
  }

  useEffect(() => { charger(); }, []);

  async function handleSubmit(e) {
    e.preventDefault();
    setErreur('');
    try {
      const payload = {
        ...form,
        prix: parseFloat(form.prix),
        quantite_stock: parseInt(form.quantite_stock),
        id_type: parseInt(form.id_type),
        id_format: parseInt(form.id_format),
      };
      if (editing) {
        await produitsApi.update(editing, payload);
      } else {
        await produitsApi.create(payload);
      }
      setForm(VIDE);
      setEditing(null);
      charger();
    } catch (e) {
      setErreur(e.message);
    }
  }

  function handleEdit(produit) {
    setEditing(produit.id);
    setForm({
      nom: produit.nom,
      description: produit.description || '',
      quantite_stock: produit.quantite_stock,
      prix: String(produit.prix),
      image_url: produit.image_url || '',
      id_type: String(produit.id_type),
      id_format: String(produit.id_format),
    });
  }

  async function handleDelete(id) {
    if (!confirm('Supprimer ce produit ?')) return;
    try {
      await produitsApi.delete(id);
      charger();
    } catch (e) {
      setErreur(e.message);
    }
  }

  function set(field) {
    return (e) => setForm({ ...form, [field]: e.target.value });
  }

  return (
    <div className="page">
      <h2>Produits</h2>

      <form className="form-card" onSubmit={handleSubmit}>
        <h3>{editing ? 'Modifier le produit' : 'Nouveau produit'}</h3>

        <div className="form-grid">
          <div>
            <label>Nom *</label>
            <input value={form.nom} onChange={set('nom')} required />
          </div>
          <div>
            <label>Prix (€) *</label>
            <input type="number" step="0.01" min="0" value={form.prix} onChange={set('prix')} required />
          </div>
          <div>
            <label>Type *</label>
            <select value={form.id_type} onChange={set('id_type')} required>
              <option value="">-- Choisir --</option>
              {types.map(t => <option key={t.id} value={t.id}>{t.nom}</option>)}
            </select>
          </div>
          <div>
            <label>Format *</label>
            <select value={form.id_format} onChange={set('id_format')} required>
              <option value="">-- Choisir --</option>
              {formats.map(f => <option key={f.id} value={f.id}>{f.libelle}</option>)}
            </select>
          </div>
          <div>
            <label>Quantité en stock</label>
            <input type="number" min="0" value={form.quantite_stock} onChange={set('quantite_stock')} />
          </div>
          <div>
            <label>Description</label>
            <input value={form.description} onChange={set('description')} />
          </div>
          <div>
            <label>Image (ex: /produits-01.png)</label>
            <input value={form.image_url} onChange={set('image_url')} placeholder="/produits-01.png" />
          </div>
        </div>

        <div className="form-actions">
          <button type="submit">{editing ? 'Enregistrer' : 'Ajouter'}</button>
          {editing && <button type="button" onClick={() => { setEditing(null); setForm(VIDE); }}>Annuler</button>}
        </div>
      </form>

      <CrudTable colonnes={COLONNES} lignes={produits} onEdit={handleEdit} onDelete={handleDelete} erreur={erreur} renderCell={renderCell} />
    </div>
  );
}
