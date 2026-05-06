import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

class AppDatabase {
  static AppDatabase? _instance;
  late final Database _db;

  AppDatabase._();

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  Database get db => _db;

  void init() {
    _db = sqlite3.open('brasserie.db');
    _createTables();
    _seedAdmin();
  }

  void _createTables() {
    _db.execute('PRAGMA foreign_keys = ON;');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS types_produits (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        nom         TEXT NOT NULL UNIQUE,
        description TEXT
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS formats (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        libelle    TEXT NOT NULL UNIQUE,
        contenance REAL NOT NULL
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS produits (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        nom            TEXT NOT NULL,
        description    TEXT,
        quantite_stock INTEGER NOT NULL DEFAULT 0,
        prix           REAL    NOT NULL,
        image_url      TEXT,
        id_type        INTEGER NOT NULL REFERENCES types_produits(id),
        id_format      INTEGER NOT NULL REFERENCES formats(id)
      );
    ''');

    // role = 'admin' ou 'client'
    _db.execute('''
      CREATE TABLE IF NOT EXISTS utilisateurs (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        nom          TEXT NOT NULL,
        email        TEXT NOT NULL UNIQUE,
        mot_de_passe TEXT NOT NULL,
        role         TEXT NOT NULL DEFAULT 'client'
      );
    ''');

    // Panier temporaire du client
    _db.execute('''
      CREATE TABLE IF NOT EXISTS selections (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        id_client   INTEGER NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
        id_produit  INTEGER NOT NULL REFERENCES produits(id)     ON DELETE CASCADE,
        quantite    INTEGER NOT NULL DEFAULT 1,
        UNIQUE(id_client, id_produit)
      );
    ''');

    // Commandes validées (historique des réservations)
    _db.execute('''
      CREATE TABLE IF NOT EXISTS commandes (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        id_client     INTEGER NOT NULL REFERENCES utilisateurs(id),
        date_commande TEXT    NOT NULL DEFAULT (datetime('now')),
        statut        TEXT    NOT NULL DEFAULT 'en_attente'
      );
    ''');

    // Lignes d'une commande
    _db.execute('''
      CREATE TABLE IF NOT EXISTS lignes_commande (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        id_commande  INTEGER NOT NULL REFERENCES commandes(id) ON DELETE CASCADE,
        id_produit   INTEGER NOT NULL REFERENCES produits(id),
        quantite     INTEGER NOT NULL,
        prix_unitaire REAL   NOT NULL
      );
    ''');
  }

  void _seedAdmin() {
    final rows = _db.select(
      "SELECT COUNT(*) as c FROM utilisateurs WHERE role = 'admin';",
    );
    if (rows.first['c'] == 0) {
      final hash = hashPassword('admin1234');
      _db.execute(
        'INSERT INTO utilisateurs (nom, email, mot_de_passe, role) VALUES (?, ?, ?, ?)',
        ['Administrateur', 'admin@brasserie.fr', hash, 'admin'],
      );
    }
  }

  static String hashPassword(String password) {
    final bytes = utf8.encode('brasserie_sel_$password');
    return sha256.convert(bytes).toString();
  }
}
