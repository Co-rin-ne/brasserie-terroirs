// MODÈLE TypeProduit
// Un modèle = une classe Dart qui représente une table de la BDD.
// Chaque champ correspond à une colonne.

class TypeProduit {
  final int? id;       // nullable car non connu avant l'insertion
  final String nom;
  final String? description;

  TypeProduit({this.id, required this.nom, this.description});

  // fromMap : convertit une ligne MySQL (Map) → objet Dart
  // Utilisé quand on lit depuis la BDD
  factory TypeProduit.fromMap(Map<String, dynamic> map) {
    return TypeProduit(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id']?.toString() ?? ''),
      nom: map['nom']?.toString() ?? '',
      description: map['description']?.toString(),
    );
  }

  // toMap : convertit l'objet Dart → Map pour l'écriture en BDD ou JSON
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nom': nom,
      if (description != null) 'description': description,
    };
  }
}
