import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

String _hash(String p) =>
    sha256.convert(utf8.encode('brasserie_sel_$p')).toString();

void main() {
  final db = sqlite3.open('brasserie.db');
  db.execute('PRAGMA foreign_keys = OFF;');

  // ── Création des tables ───────────────────────────────────────────────────
  db.execute('''CREATE TABLE IF NOT EXISTS types_produits (
    id INTEGER PRIMARY KEY AUTOINCREMENT, nom TEXT NOT NULL UNIQUE, description TEXT);''');
  db.execute('''CREATE TABLE IF NOT EXISTS formats (
    id INTEGER PRIMARY KEY AUTOINCREMENT, libelle TEXT NOT NULL UNIQUE, contenance REAL NOT NULL);''');
  db.execute('''CREATE TABLE IF NOT EXISTS produits (
    id INTEGER PRIMARY KEY AUTOINCREMENT, nom TEXT NOT NULL, description TEXT,
    quantite_stock INTEGER NOT NULL DEFAULT 0, prix REAL NOT NULL, image_url TEXT,
    id_type INTEGER NOT NULL REFERENCES types_produits(id),
    id_format INTEGER NOT NULL REFERENCES formats(id));''');
  db.execute('''CREATE TABLE IF NOT EXISTS utilisateurs (
    id INTEGER PRIMARY KEY AUTOINCREMENT, nom TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE, mot_de_passe TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'client');''');
  db.execute('''CREATE TABLE IF NOT EXISTS selections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_client  INTEGER NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    id_produit INTEGER NOT NULL REFERENCES produits(id)     ON DELETE CASCADE,
    quantite INTEGER NOT NULL DEFAULT 1,
    UNIQUE(id_client, id_produit));''');

  // ── Nettoyage ─────────────────────────────────────────────────────────────
  print('Nettoyage...');
  db.execute('DELETE FROM selections;');
  db.execute('DELETE FROM produits;');
  db.execute('DELETE FROM formats;');
  db.execute('DELETE FROM types_produits;');
  db.execute('DELETE FROM utilisateurs;');
  db.execute("DELETE FROM sqlite_sequence WHERE name IN "
      "('produits','formats','types_produits','utilisateurs','selections');");
  db.execute('PRAGMA foreign_keys = ON;');

  // ── Utilisateurs ──────────────────────────────────────────────────────────
  print('Insertion des utilisateurs...');
  db.execute(
    "INSERT INTO utilisateurs (nom, email, mot_de_passe, role) VALUES (?,?,?,'admin')",
    ['Administrateur', 'admin@brasserie.fr', _hash('admin1234')],
  );
  db.execute(
    "INSERT INTO utilisateurs (nom, email, mot_de_passe, role) VALUES (?,?,?,'client')",
    ['Marie Dupont', 'marie@example.fr', _hash('client1234')],
  );
  db.execute(
    "INSERT INTO utilisateurs (nom, email, mot_de_passe, role) VALUES (?,?,?,'client')",
    ['Paul Martin', 'paul@example.fr', _hash('client1234')],
  );
  print('  ✓ admin@brasserie.fr / admin1234');
  print('  ✓ marie@example.fr   / client1234');
  print('  ✓ paul@example.fr    / client1234');

  // ── Types ─────────────────────────────────────────────────────────────────
  print('Insertion des types...');
  db.execute("INSERT INTO types_produits (nom, description) VALUES (?,?)",
      ['Bière', 'Boissons brassées à base de malt, houblon et eau.']);
  db.execute("INSERT INTO types_produits (nom, description) VALUES (?,?)",
      ['Spiritueux', 'Alcools distillés et vieillis en fûts : whisky, gin, etc.']);
  final idBiere = 1;
  final idSpiritueux = 2;

  // ── Formats ───────────────────────────────────────────────────────────────
  print('Insertion des formats...');
  db.execute("INSERT INTO formats (libelle, contenance) VALUES (?,?)", ['Bouteille 33cl', 0.33]);
  final id33 = db.lastInsertRowId;
  db.execute("INSERT INTO formats (libelle, contenance) VALUES (?,?)", ['Bouteille 50cl', 0.50]);
  final id50 = db.lastInsertRowId;
  db.execute("INSERT INTO formats (libelle, contenance) VALUES (?,?)", ['Bouteille 75cl', 0.75]);
  final id75 = db.lastInsertRowId;
  db.execute("INSERT INTO formats (libelle, contenance) VALUES (?,?)", ['Fût 30L', 30.0]);
  db.execute("INSERT INTO formats (libelle, contenance) VALUES (?,?)", ['Fût 50L', 50.0]);

  // ── Produits ──────────────────────────────────────────────────────────────
  print('Insertion des produits...');
  final produits = [
    ['Bière Blonde',
     'Légère et rafraîchissante, la bière blonde séduit par son équilibre parfait entre douceur et amertume. Brassée avec des malts soigneusement sélectionnés et des houblons aromatiques, elle offre des notes subtiles de céréales et une touche florale.',
     120, 3.50, '/produits-01.png', idBiere, id33],
    ['Bière Brune',
     'Riche et intense, la bière brune dévoile une palette de saveurs profondes. Ses malts torréfiés révèlent des arômes de chocolat noir, de caramel et une légère pointe de café.',
     85, 3.80, '/produits-02.png', idBiere, id33],
    ['Bière IPA',
     'Audacieuse et aromatique, la bière IPA se distingue par ses houblons expressifs et son amertume affirmée. Elle libère des arômes intenses d\'agrumes, de fruits tropicaux et de résine de pin.',
     60, 4.20, '/produits-03.png', idBiere, id50],
    ['Whisky',
     'Distillé avec soin et vieilli en fûts de chêne, il révèle une richesse aromatique exceptionnelle : notes de vanille, d\'épices douces, de fruits secs et une pointe de tourbe.',
     40, 38.00, '/produits-04.png', idSpiritueux, id75],
    ['Gin',
     'Élaboré à partir de plantes aromatiques locales et d\'épices soigneusement sélectionnées, il combine des notes fraîches de genièvre, des zestes d\'agrumes et des touches herbacées.',
     35, 32.00, '/produits-05.png', idSpiritueux, id75],
  ];

  for (final p in produits) {
    db.execute(
      'INSERT INTO produits (nom, description, quantite_stock, prix, image_url, id_type, id_format) VALUES (?,?,?,?,?,?,?)',
      p,
    );
    print('  ✓ ${p[0]}');
  }

  db.dispose();
  print('\nBase de données peuplée avec succès !');
}
