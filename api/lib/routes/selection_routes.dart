import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

// Un client voit et gère UNIQUEMENT sa propre sélection.
// L'id du client est lu depuis le token JWT (contexte de la requête).

Router selectionRouter() {
  final router = Router();
  final db = AppDatabase.instance.db;

  // GET /selection — retourne tous les articles sélectionnés par le client connecté
  router.get('/', (Request req) async {
    final idClient = req.context['userId'] as int;

    final rows = await db.query('''
      SELECT
        s.id, s.quantite,
        p.id as id_produit, p.nom, p.prix, p.image_url,
        tp.nom as type_nom,
        f.libelle as format_libelle
      FROM selections s
      JOIN produits p         ON p.id = s.id_produit
      JOIN types_produits tp  ON tp.id = p.id_type
      JOIN formats f          ON f.id  = p.id_format
      WHERE s.id_client = ?
      ORDER BY p.nom;
    ''', [idClient]);

    final items = rows.toMapList().map((r) {
      final prix = toDouble(r['prix']);
      final quantite = (r['quantite'] is int)
          ? r['quantite'] as int
          : int.tryParse(r['quantite']?.toString() ?? '0') ?? 0;
      return {
        'id': r['id'],
        'quantite': quantite,
        'id_produit': r['id_produit'],
        'nom': r['nom']?.toString(),
        'prix': prix,
        'image_url': r['image_url']?.toString(),
        'type_nom': r['type_nom']?.toString(),
        'format_libelle': r['format_libelle']?.toString(),
        'sous_total': prix * quantite,
      };
    }).toList();

    return Response.ok(
      jsonEncode(items),
      headers: {'content-type': 'application/json'},
    );
  });

  // POST /selection — ajoute un produit à la sélection
  router.post('/', (Request req) async {
    final idClient = req.context['userId'] as int;
    final body = await req.readAsString();
    late Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response.badRequest(
        body: '{"erreur": "JSON invalide"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final idProduit = data['id_produit'] as int?;
    final quantite = (data['quantite'] as num?)?.toInt() ?? 1;

    if (idProduit == null || quantite < 1) {
      return Response.badRequest(
        body: '{"erreur": "id_produit requis et quantite >= 1"}',
        headers: {'content-type': 'application/json'},
      );
    }

    // Vérifie que le produit existe
    final produit = await db.query(
      'SELECT id FROM produits WHERE id = ?;',
      [idProduit],
    );
    if (produit.isEmpty) {
      return Response.notFound(
        '{"erreur": "Produit introuvable"}',
        headers: {'content-type': 'application/json'},
      );
    }

    // ON DUPLICATE KEY UPDATE (MySQL/MariaDB) :
    // si le produit est déjà dans la sélection, on incrémente la quantité
    await db.query('''
      INSERT INTO selections (id_client, id_produit, quantite)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE quantite = quantite + VALUES(quantite);
    ''', [idClient, idProduit, quantite]);

    return Response(201,
      body: '{"message": "Produit ajouté à la sélection"}',
      headers: {'content-type': 'application/json'},
    );
  });

  // PUT /selection/:id — modifie la quantité d'un article
  router.put('/<id>', (Request req, String id) async {
    final idClient = req.context['userId'] as int;
    final body = await req.readAsString();
    late Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response.badRequest(
        body: '{"erreur": "JSON invalide"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final quantite = (data['quantite'] as num?)?.toInt();
    if (quantite == null || quantite < 1) {
      return Response.badRequest(
        body: '{"erreur": "quantite doit être >= 1"}',
        headers: {'content-type': 'application/json'},
      );
    }

    // Vérifie que la ligne appartient bien à ce client
    final existing = await db.query(
      'SELECT id FROM selections WHERE id = ? AND id_client = ?;',
      [int.parse(id), idClient],
    );
    if (existing.isEmpty) {
      return Response.notFound(
        '{"erreur": "Article introuvable dans votre sélection"}',
        headers: {'content-type': 'application/json'},
      );
    }

    await db.query(
      'UPDATE selections SET quantite = ? WHERE id = ? AND id_client = ?',
      [quantite, int.parse(id), idClient],
    );

    return Response.ok(
      '{"message": "Quantité mise à jour"}',
      headers: {'content-type': 'application/json'},
    );
  });

  // DELETE /selection/:id — supprime un article de la sélection
  router.delete('/<id>', (Request req, String id) async {
    final idClient = req.context['userId'] as int;

    final existing = await db.query(
      'SELECT id FROM selections WHERE id = ? AND id_client = ?;',
      [int.parse(id), idClient],
    );
    if (existing.isEmpty) {
      return Response.notFound(
        '{"erreur": "Article introuvable dans votre sélection"}',
        headers: {'content-type': 'application/json'},
      );
    }

    await db.query(
      'DELETE FROM selections WHERE id = ? AND id_client = ?',
      [int.parse(id), idClient],
    );
    return Response(204);
  });

  // POST /selection/valider — transforme le panier en commande et le vide
  router.post('/valider', (Request req) async {
    final idClient = req.context['userId'] as int;

    final items = await db.query('''
      SELECT s.id_produit, s.quantite, p.prix
      FROM selections s
      JOIN produits p ON p.id = s.id_produit
      WHERE s.id_client = ?;
    ''', [idClient]);

    if (items.isEmpty) {
      return Response.badRequest(
        body: '{"erreur": "Votre panier est vide"}',
        headers: {'content-type': 'application/json'},
      );
    }

    // Crée la commande
    final commande = await db.query(
      "INSERT INTO commandes (id_client, statut) VALUES (?, 'en_attente')",
      [idClient],
    );
    final idCommande = commande.insertId;

    // Copie chaque ligne du panier dans lignes_commande
    for (final item in items) {
      final m = item.fields;
      await db.query(
        'INSERT INTO lignes_commande (id_commande, id_produit, quantite, prix_unitaire) VALUES (?, ?, ?, ?)',
        [idCommande, m['id_produit'], m['quantite'], toDouble(m['prix'])],
      );
    }

    // Vide le panier
    await db.query('DELETE FROM selections WHERE id_client = ?', [idClient]);

    return Response(201,
      body: jsonEncode({
        'message': 'Réservation envoyée avec succès',
        'id_commande': idCommande,
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  return router;
}
