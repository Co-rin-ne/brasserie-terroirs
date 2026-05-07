import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:mysql1/mysql1.dart';

String _hash(String p) =>
    sha256.convert(utf8.encode('brasserie_sel_$p')).toString();

void main() async {
  // ── Connexion à MariaDB ───────────────────────────────────────────────────
  final settings = ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'brasserie_user',
    password: 'bts_brass',
    db: 'brasserie_db',
  );
  final db = await MySqlConnection.connect(settings);
  print('✓ Connexion MariaDB établie');

  // ── Désactivation des contraintes (pour vider proprement) ────────────────
  await db.query('SET FOREIGN_KEY_CHECKS = 0;');

  // ── Création des tables ───────────────────────────────────────────────────
  await db.query('''
    CREATE TABLE IF NOT EXISTS types_produits (
      id INT PRIMARY KEY AUTO_INCREMENT,
      nom VARCHAR(255) NOT NULL UNIQUE,
      description TEXT
    );
  ''');

  await db.query('''
    CREATE TABLE IF NOT EXISTS formats (
      id INT PRIMARY KEY AUTO_INCREMENT,
      libelle VARCHAR(255) NOT NULL UNIQUE,
      contenance DECIMAL(10,2) NOT NULL
    );
  ''');

  await db.query('''
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

  await db.query('''
    CREATE TABLE IF NOT EXISTS utilisateurs (
      id INT PRIMARY KEY AUTO_INCREMENT,
      nom VARCHAR(255) NOT NULL,
      email VARCHAR(255) NOT NULL UNIQUE,
      mot_de_passe VARCHAR(255) NOT NULL,
      role VARCHAR(50) NOT NULL DEFAULT 'client'
    );
  ''');

  await db.query('''
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

  await db.query('''
    CREATE TABLE IF NOT EXISTS commandes (
      id INT PRIMARY KEY AUTO_INCREMENT,
      id_client INT NOT NULL,
      date_commande DATETIME DEFAULT CURRENT_TIMESTAMP,
      statut VARCHAR(50) DEFAULT 'en_attente',
      FOREIGN KEY (id_client) REFERENCES utilisateurs(id)
    );
  ''');

  await db.query('''
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

  // ── Nettoyage ─────────────────────────────────────────────────────────────
  print('Nettoyage des tables...');
  await db.query('DELETE FROM lignes_commande;');
  await db.query('DELETE FROM commandes;');
  await db.query('DELETE FROM selections;');
  await db.query('DELETE FROM produits;');
  await db.query('DELETE FROM formats;');
  await db.query('DELETE FROM types_produits;');
  await db.query('DELETE FROM utilisateurs;');

  // Reset des compteurs auto-increment
  await db.query('ALTER TABLE types_produits AUTO_INCREMENT = 1;');
  await db.query('ALTER TABLE formats AUTO_INCREMENT = 1;');
  await db.query('ALTER TABLE produits AUTO_INCREMENT = 1;');
  await db.query('ALTER TABLE utilisateurs AUTO_INCREMENT = 1;');
  await db.query('ALTER TABLE selections AUTO_INCREMENT = 1;');
  await db.query('ALTER TABLE commandes AUTO_INCREMENT = 1;');
  await db.query('ALTER TABLE lignes_commande AUTO_INCREMENT = 1;');

  await db.query('SET FOREIGN_KEY_CHECKS = 1;');

  // ── Utilisateurs ──────────────────────────────────────────────────────────
  print('Insertion des utilisateurs...');
  await db.query(
    "INSERT INTO utilisateurs (nom, email, mot_de_passe, role) VALUES (?, ?, ?, 'admin')",
    ['Administrateur', 'admin@brasserie.fr', _hash('admin1234')],
  );
  await db.query(
    "INSERT INTO utilisateurs (nom, email, mot_de_passe, role) VALUES (?, ?, ?, 'client')",
    ['Marie Dupont', 'marie@example.fr', _hash('client1234')],
  );
  await db.query(
    "INSERT INTO utilisateurs (nom, email, mot_de_passe, role) VALUES (?, ?, ?, 'client')",
    ['Paul Martin', 'paul@example.fr', _hash('client1234')],
  );
  print('  ✓ admin@brasserie.fr / admin1234');
  print('  ✓ marie@example.fr   / client1234');
  print('  ✓ paul@example.fr    / client1234');

  // ── Types ─────────────────────────────────────────────────────────────────
  print('Insertion des types...');
  final biereResult = await db.query(
    "INSERT INTO types_produits (nom, description) VALUES (?, ?)",
    ['Bière', 'Boissons brassées à base de malt, houblon et eau.'],
  );
  final idBiere = biereResult.insertId;

  final spiritResult = await db.query(
    "INSERT INTO types_produits (nom, description) VALUES (?, ?)",
    ['Spiritueux', 'Alcools distillés et vieillis en fûts : whisky, gin, etc.'],
  );
  final idSpiritueux = spiritResult.insertId;

  // ── Formats ───────────────────────────────────────────────────────────────
  print('Insertion des formats...');
  final r33 = await db.query(
    "INSERT INTO formats (libelle, contenance) VALUES (?, ?)",
    ['Bouteille 33cl', 0.33],
  );
  final id33 = r33.insertId;

  final r50 = await db.query(
    "INSERT INTO formats (libelle, contenance) VALUES (?, ?)",
    ['Bouteille 50cl', 0.50],
  );
  final id50 = r50.insertId;

  final r75 = await db.query(
    "INSERT INTO formats (libelle, contenance) VALUES (?, ?)",
    ['Bouteille 75cl', 0.75],
  );
  final id75 = r75.insertId;

  await db.query(
    "INSERT INTO formats (libelle, contenance) VALUES (?, ?)",
    ['Fût 30L', 30.0],
  );
  await db.query(
    "INSERT INTO formats (libelle, contenance) VALUES (?, ?)",
    ['Fût 50L', 50.0],
  );

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
    await db.query(
      'INSERT INTO produits (nom, description, quantite_stock, prix, image_url, id_type, id_format) VALUES (?, ?, ?, ?, ?, ?, ?)',
      p,
    );
    print('  ✓ ${p[0]}');
  }

  await db.close();
  print('\n✓ Base de données peuplée avec succès !');
}
