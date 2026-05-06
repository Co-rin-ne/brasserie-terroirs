import { useEffect, useState } from 'react';
import { profilApi } from '../services/api';
import { useAuth } from '../context/AuthContext';

export default function Profil() {
  const { logout } = useAuth();
  const [profil, setProfil] = useState(null);
  const [mdp, setMdp] = useState({ ancien: '', nouveau: '', confirmation: '' });
  const [erreurMdp, setErreurMdp] = useState('');
  const [succesMdp, setSuccesMdp] = useState('');
  const [confirmerSuppression, setConfirmerSuppression] = useState(false);

  useEffect(() => {
    profilApi.get().then(setProfil).catch(() => {});
  }, []);

  async function changerMotDePasse(e) {
    e.preventDefault();
    setErreurMdp(''); setSuccesMdp('');
    if (mdp.nouveau !== mdp.confirmation) {
      setErreurMdp('Les nouveaux mots de passe ne correspondent pas');
      return;
    }
    try {
      await profilApi.changePassword(mdp.ancien, mdp.nouveau);
      setSuccesMdp('Mot de passe modifié avec succès');
      setMdp({ ancien: '', nouveau: '', confirmation: '' });
    } catch (e) {
      setErreurMdp(e.message);
    }
  }

  async function supprimerCompte() {
    try {
      await profilApi.deleteAccount();
      logout();
    } catch (e) {
      alert(e.message);
    }
  }

  return (
    <div className="page">
      <h2>Mon profil</h2>

      {profil && (
        <div className="form-card" style={{ maxWidth: 480, marginBottom: '1.5rem' }}>
          <h3>Informations</h3>
          <p style={{ marginTop: '0.5rem' }}><strong>Nom :</strong> {profil.nom}</p>
          <p style={{ marginTop: '0.25rem' }}><strong>Email :</strong> {profil.email}</p>
        </div>
      )}

      {/* Modifier mot de passe */}
      <form className="form-card" style={{ maxWidth: 480 }} onSubmit={changerMotDePasse}>
        <h3>Modifier mon mot de passe</h3>
        <label>Mot de passe actuel</label>
        <input type="password" value={mdp.ancien} onChange={e => setMdp({ ...mdp, ancien: e.target.value })} required />
        <label>Nouveau mot de passe</label>
        <input type="password" value={mdp.nouveau} onChange={e => setMdp({ ...mdp, nouveau: e.target.value })} minLength={6} required />
        <label>Confirmer le nouveau mot de passe</label>
        <input type="password" value={mdp.confirmation} onChange={e => setMdp({ ...mdp, confirmation: e.target.value })} required />
        {erreurMdp && <p className="erreur">{erreurMdp}</p>}
        {succesMdp && <p className="succes">{succesMdp}</p>}
        <div className="form-actions">
          <button type="submit">Modifier le mot de passe</button>
        </div>
      </form>

      {/* Suppression de compte */}
      <div className="form-card" style={{ maxWidth: 480, borderLeft: '4px solid #e55' }}>
        <h3 style={{ color: '#b91c1c' }}>Supprimer mon compte</h3>
        <p style={{ fontSize: '0.875rem', color: '#666', marginTop: '0.5rem' }}>
          Cette action est irréversible. Toutes vos données seront supprimées.
        </p>
        {!confirmerSuppression ? (
          <div className="form-actions">
            <button type="button" className="btn-delete" style={{ padding: '0.5rem 1.5rem' }}
              onClick={() => setConfirmerSuppression(true)}>
              Supprimer mon compte
            </button>
          </div>
        ) : (
          <div className="form-actions" style={{ marginTop: '1rem' }}>
            <p style={{ fontSize: '0.875rem', color: '#b91c1c', width: '100%' }}>Êtes-vous sûr(e) ?</p>
            <button type="button" className="btn-delete" style={{ padding: '0.5rem 1.5rem' }} onClick={supprimerCompte}>
              Oui, supprimer
            </button>
            <button type="button" onClick={() => setConfirmerSuppression(false)}>
              Annuler
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
