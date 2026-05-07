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
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id']?.toString() ?? ''),
      nom: map['nom']?.toString() ?? '',
      description: map['description']?.toString(),
      quantiteStock: map['quantite_stock'] is int
          ? map['quantite_stock'] as int
          : int.tryParse(map['quantite_stock']?.toString() ?? '0') ?? 0,
      prix: _toDouble(map['prix']),
      imageUrl: map['image_url']?.toString(),
      idType: map['id_type'] is int
          ? map['id_type'] as int
          : int.tryParse(map['id_type']?.toString() ?? '0') ?? 0,
      idFormat: map['id_format'] is int
          ? map['id_format'] as int
          : int.tryParse(map['id_format']?.toString() ?? '0') ?? 0,
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

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
