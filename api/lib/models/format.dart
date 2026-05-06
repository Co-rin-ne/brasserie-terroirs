// MODÈLE Format
// Représente la contenance d'un produit : bouteille 33cl, fût 30L, etc.

class Format {
  final int? id;
  final String libelle;  // ex: "Bouteille 33cl", "Fût 30L"
  final double contenance; // en litres (0.33, 30.0...)

  Format({this.id, required this.libelle, required this.contenance});

  factory Format.fromMap(Map<String, dynamic> map) {
    return Format(
      id: map['id'] as int?,
      libelle: map['libelle'] as String,
      contenance: (map['contenance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'libelle': libelle,
      'contenance': contenance,
    };
  }
}
