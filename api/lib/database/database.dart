import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:mysql1/mysql1.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();

  late MySqlConnection _conn;

  // Getter synchrone : la connexion est initialisée au démarrage du serveur
  MySqlConnection get db => _conn;

  // Hash SHA-256 avec sel — méthode statique réutilisable
  static String hashPassword(String password) =>
      sha256.convert(utf8.encode('brasserie_sel_$password')).toString();

  Future<void> init() async {
    final settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'brasserie_user',
      password: 'bts_brass',
      db: 'brasserie_db',
    );

    _conn = await MySqlConnection.connect(settings);
    await _createTables();
  }

  Future<void> close() async {
    await _conn.close();
  }

  Future<void> _createTables() async {
    await _conn.query('''
      CREATE TABLE IF NOT EXISTS types_produits (
        id INT PRIMARY KEY AUTO_INCREMENT,
        nom VARCHAR(255) NOT NULL UNIQUE,
        description TEXT
      );
    ''');

    await _conn.query('''
      CREATE TABLE IF NOT EXISTS formats (
        id INT PRIMARY KEY AUTO_INCREMENT,
        libelle VARCHAR(255) NOT NULL UNIQUE,
        contenance DECIMAL(10,2) NOT NULL
      );
    ''');

    await _conn.query('''
      CREATE TABLE IF NOT EXISTS produits (
        id INT PRIMARY KEY AUTO_INCREMENT,
        nom VARCHAR(255) NOT NULL,
        description TEXT,
        quantite_stock INT NOT NULL DEFAULT 0,
        prix DECIMAL(10,2) NOT NULL,
        image_url VARCHAR(500),
        id_type INT NOT NULL,
        id_format INT NOT NULL,
        FOREIGN KEY (id_type) REFERENCES types_produits(id),
        FOREIGN KEY (id_format) REFERENCES formats(id)
      );
    ''');

    await _conn.query('''
      CREATE TABLE IF NOT EXISTS utilisateurs (
        id INT PRIMARY KEY AUTO_INCREMENT,
        nom VARCHAR(255) NOT NULL,
        email VARCHAR(255) NOT NULL UNIQUE,
        mot_de_passe VARCHAR(255) NOT NULL,
        role VARCHAR(50) NOT NULL DEFAULT 'client'
      );
    ''');

    await _conn.query('''
      CREATE TABLE IF NOT EXISTS selections (
        id INT PRIMARY KEY AUTO_INCREMENT,
        id_client INT NOT NULL,
        id_produit INT NOT NULL,
        quantite INT NOT NULL DEFAULT 1,
        UNIQUE KEY unique_selection (id_client, id_produit),
        FOREIGN KEY (id_client) REFERENCES utilisateurs(id) ON DELETE CASCADE,
        FOREIGN KEY (id_produit) REFERENCES produits(id) ON DELETE CASCADE
      );
    ''');

    await _conn.query('''
      CREATE TABLE IF NOT EXISTS commandes (
        id INT PRIMARY KEY AUTO_INCREMENT,
        id_client INT NOT NULL,
        date_commande DATETIME DEFAULT CURRENT_TIMESTAMP,
        statut VARCHAR(50) DEFAULT 'en_attente',
        FOREIGN KEY (id_client) REFERENCES utilisateurs(id)
      );
    ''');

    await _conn.query('''
      CREATE TABLE IF NOT EXISTS lignes_commande (
        id INT PRIMARY KEY AUTO_INCREMENT,
        id_commande INT NOT NULL,
        id_produit INT NOT NULL,
        quantite INT NOT NULL,
        prix_unitaire DECIMAL(10,2) NOT NULL,
        FOREIGN KEY (id_commande) REFERENCES commandes(id) ON DELETE CASCADE,
        FOREIGN KEY (id_produit) REFERENCES produits(id)
      );
    ''');
  }
}

// ─── Helpers pour convertir les ResultRow MySQL en Map ────────────────────────
// mysql1 retourne des ResultRow, mais nos modèles veulent des Map<String, dynamic>.
// Ces extensions facilitent la conversion sans casser le code existant.

extension ResultsToList on Results {
  List<Map<String, dynamic>> toMapList() {
    return map((row) => _rowToMap(row)).toList();
  }

  Map<String, dynamic>? get firstAsMap {
    if (isEmpty) return null;
    return _rowToMap(first);
  }
}

Map<String, dynamic> _rowToMap(ResultRow row) {
  final map = <String, dynamic>{};
  row.fields.forEach((key, value) {
    // BLOB / TEXT peuvent revenir en Blob, on convertit en String
    if (value is Blob) {
      map[key] = value.toString();
    } else if (value != null && value.runtimeType.toString().contains('Decimal')) {
      // DECIMAL vient comme un objet "Decimal", on convertit en double
      map[key] = double.tryParse(value.toString()) ?? 0.0;
    } else {
      map[key] = value;
    }
  });
  return map;
}

// Helper: convertit n'importe quoi en double (utile pour DECIMAL)
double toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return double.tryParse(v.toString()) ?? 0;
}
