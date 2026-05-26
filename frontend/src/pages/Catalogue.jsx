import { useEffect, useState } from 'react';
import { produitsApi, selectionApi } from '../services/api';

export default function Catalogue() {
  const [produits, setProduits] = useState([]);
  const [quantites, setQuantites] = useState({});  // { idProduit: quantité }
  const [message, setMessage] = useState('');
  const [erreur, setErreur] = useState('');

  useEffect(() => {
    produitsApi.getAll().then(setProduits).catch(e => setErreur(e.message));
  }, []);

  function getQty(id) { return quantites[id] ?? 1; }
  function setQty(id, val) {
    setQuantites(q => ({ ...q, [id]: Math.max(1, Number(val)) }));
  }

  async function ajouterSelection(produit) {
    setMessage(''); setErreur('');
    try {
      await selectionApi.add(produit.id, getQty(produit.id));
      setMessage(`"${produit.nom}" (×${getQty(produit.id)}) ajouté à votre sélection !`);
      setTimeout(() => setMessage(''), 3000);
    } catch (e) {
      setErreur(e.message);
    }
  }

  return (
    <div className="page">
      <h2>Catalogue</h2>
      {erreur  && <p className="erreur">{erreur}</p>}
      {message && <p className="succes">{message}</p>}

      <div className="catalogue-grid">
        {produits.map(p => (
          <div key={p.id} className="carte-produit">
            {/* Badge promo en haut à droite de l'image */}
            {p.pourcentage > 0 && (
              <span className="badge-promo">−{p.pourcentage}%</span>
            )}

            {p.image_url
              ? <img src={p.image_url} alt={p.nom} />
              : <div style={{ height: 180, background: '#e8f4eb', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#999' }}>Pas d'image</div>
            }
            <div className="carte-corps">
              <span className="carte-type">{p.type_nom}</span>
              <h3>{p.nom}</h3>
              <p className="carte-description">{p.description}</p>

              <div className="carte-footer">
                {p.pourcentage > 0 ? (
                  <div>
                    <span style={{ textDecoration: 'line-through', color: '#999', marginRight: '0.5rem', fontSize: '0.9rem' }}>
                      {Number(p.prix).toFixed(2)} €
                    </span>
                    <span className="carte-prix" style={{ color: '#e53e3e' }}>
                      {Number(p.prix_reduit).toFixed(2)} €
                    </span>
                  </div>
                ) : (
                  <span className="carte-prix">{Number(p.prix).toFixed(2)} €</span>
                )}
                <span className="carte-format">{p.format_libelle}</span>
              </div>

              {p.promo_libelle && (
                <p style={{ fontSize: '0.75rem', color: '#e53e3e', fontWeight: 600, marginTop: '0.25rem' }}>
                  🏷️ {p.promo_libelle}
                </p>
              )}

              {p.quantite_stock > 0 ? (
                <>
                  <div className="qty-control" style={{ marginTop: '0.75rem' }}>
                    <button onClick={() => setQty(p.id, getQty(p.id) - 1)}>−</button>
                    <span>{getQty(p.id)}</span>
                    <button onClick={() => setQty(p.id, getQty(p.id) + 1)}>+</button>
                  </div>
                  <button className="btn-ajouter" onClick={() => ajouterSelection(p)}>
                    Ajouter à ma sélection
                  </button>
                </>
              ) : (
                <button className="btn-ajouter" disabled>Rupture de stock</button>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
