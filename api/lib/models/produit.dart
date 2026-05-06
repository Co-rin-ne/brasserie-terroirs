class Produit {
  final int? id;
  final String nom;
  final String? description;
  final int quantiteStock;
  final double prix;
  final String? imageUrl;
  final int idType;
  final int idFormat;

  Produit({
    this.id,
    required this.nom,
    this.description,
    required this.quantiteStock,
    required this.prix,
    this.imageUrl,
    required this.idType,
    required this.idFormat,
  });

  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      description: map['description'] as String?,
      quantiteStock: map['quantite_stock'] as int,
      prix: (map['prix'] as num).toDouble(),
      imageUrl: map['image_url'] as String?,
      idType: map['id_type'] as int,
      idFormat: map['id_format'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nom': nom,
      if (description != null) 'description': description,
      'quantite_stock': quantiteStock,
      'prix': prix,
      if (imageUrl != null) 'image_url': imageUrl,
      'id_type': idType,
      'id_format': idFormat,
    };
  }
}
