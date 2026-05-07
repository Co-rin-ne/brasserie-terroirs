// MODÈLE Format
// Représente la contenance d'un produit : bouteille 33cl, fût 30L, etc.

class Format {
  final int? id;
  final String libelle;  // ex: "Bouteille 33cl", "Fût 30L"
  final double contenance; // en litres (0.33, 30.0...)

  Format({this.id, required this.libelle, required this.contenance});

  factory Format.fromMap(Map<String, dynamic> map) {
    return Format(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id']?.toString() ?? ''),
      libelle: map['libelle']?.toString() ?? '',
      contenance: _toDouble(map['contenance']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'libelle': libelle,
      'contenance': contenance,
    };
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
