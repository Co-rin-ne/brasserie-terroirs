import { useEffect, useState } from 'react';
import { selectionApi } from '../services/api';

export default function MaSelection() {
  const [items, setItems] = useState([]);
  const [erreur, setErreur] = useState('');
  const [succes, setSucces] = useState('');

  async function charger() {
    try { setItems(await selectionApi.getAll()); }
    catch (e) { setErreur(e.message); }
  }

  useEffect(() => { charger(); }, []);

  async function modifierQuantite(id, quantite) {
    if (quantite < 1) return;
    try { await selectionApi.update(id, quantite); charger(); }
    catch (e) { setErreur(e.message); }
  }

  async function supprimer(id) {
    if (!confirm('Retirer cet article de votre sélection ?')) return;
    try { await selectionApi.delete(id); charger(); }
    catch (e) { setErreur(e.message); }
  }

  async function validerReservation() {
    setErreur(''); setSucces('');
    try {
      await selectionApi.valider();
      setSucces('Réservation envoyée avec succès ! 🎉');
      setItems([]);
    } catch (e) {
      setErreur(e.message);
    }
  }

  // Total avec réduction (utilise sous_total = prix_reduit × quantite)
  const total = items.reduce((s, i) => s + i.sous_total, 0);

  // Total SANS réduction (prix original × quantite)
  const totalSansReduction = items.reduce((s, i) => s + (Number(i.prix) * i.quantite), 0);

  // Économies réalisées
  const economies = totalSansReduction - total;
  const yAUneReduction = economies > 0.01;  // tolérance virgule flottante

  return (
    <div className="page">
      <h2>Ma sélection</h2>
      {erreur && <p className="erreur">{erreur}</p>}
      {succes && <p className="succes" style={{ fontSize: '1rem', padding: '1rem' }}>{succes}</p>}

      {items.length === 0 && !succes ? (
        <p style={{ color: '#888', marginTop: '2rem' }}>
          Votre sélection est vide. Parcourez le catalogue pour ajouter des articles.
        </p>
      ) : items.length > 0 ? (
        <>
          <table>
            <thead>
              <tr>
                <th>Photo</th>
                <th>Produit</th>
                <th>Format</th>
                <th>Prix unit.</th>
                <th>Quantité</th>
                <th>Sous-total</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {items.map(item => (
                <tr key={item.id}>
                  <td data-label="Photo">
                    {item.image_url && <img src={item.image_url} alt={item.nom} style={{ width: 48, height: 48, objectFit: 'cover', borderRadius: 6 }} />}
                  </td>
                  <td data-label="Produit"><strong>{item.nom}</strong></td>
                  <td data-label="Format">{item.format_libelle}</td>
                  <td data-label="Prix unit.">{Number(item.prix).toFixed(2)} €</td>
                  <td data-label="Quantité">
                    <div className="qty-control">
                      <button onClick={() => modifierQuantite(item.id, item.quantite - 1)}>−</button>
                      <span>{item.quantite}</span>
                      <button onClick={() => modifierQuantite(item.id, item.quantite + 1)}>+</button>
                    </div>
                  </td>
                  <td data-label="Sous-total">{Number(item.sous_total).toFixed(2)} €</td>
                  <td data-label="Action">
                    <button className="btn-delete" onClick={() => supprimer(item.id)}>Retirer</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className="selection-footer">
            <div className="selection-total">
              {yAUneReduction ? (
                <>
                  <div style={{ fontSize: '1rem', color: '#888' }}>
                    Total :{' '}
                    <span style={{ textDecoration: 'line-through' }}>
                      {totalSansReduction.toFixed(2)} €
                    </span>
                  </div>
                  <div style={{ fontSize: '1.3rem', marginTop: '0.25rem' }}>
                    Total réduit :{' '}
                    <strong style={{ color: '#e53e3e' }}>
                      {total.toFixed(2)} €
                    </strong>
                  </div>
                  <div style={{ fontSize: '0.85rem', color: '#2e6b44', marginTop: '0.25rem' }}>
                    💰 Vous économisez {economies.toFixed(2)} €
                  </div>
                </>
              ) : (
                <>Total : <strong>{total.toFixed(2)} €</strong></>
              )}
            </div>
            <button className="btn-reserver" onClick={validerReservation}>
              Valider ma réservation
            </button>
          </div>
        </>
      ) : null}
    </div>
  );
}
