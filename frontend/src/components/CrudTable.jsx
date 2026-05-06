// Composant générique réutilisable pour afficher un tableau CRUD.
// La prop `renderCell` permet de personnaliser l'affichage d'une cellule (ex: image).

export default function CrudTable({ colonnes, lignes, onEdit, onDelete, erreur, renderCell }) {
  return (
    <div>
      {erreur && <p className="erreur">{erreur}</p>}
      <table>
        <thead>
          <tr>
            {colonnes.map((col) => <th key={col.key}>{col.label}</th>)}
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {lignes.length === 0 && (
            <tr><td colSpan={colonnes.length + 1} style={{ textAlign: 'center', color: '#888' }}>Aucune donnée</td></tr>
          )}
          {lignes.map((ligne) => (
            <tr key={ligne.id}>
              {colonnes.map((col) => (
                <td key={col.key}>
                  {renderCell ? renderCell(col.key, ligne[col.key], ligne) : ligne[col.key]}
                </td>
              ))}
              <td>
                <button className="btn-edit" onClick={() => onEdit(ligne)}>Modifier</button>
                <button className="btn-delete" onClick={() => onDelete(ligne.id)}>Supprimer</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
