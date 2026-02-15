import 'package:supabase_flutter/supabase_flutter.dart';

import '../../panier/models/panier_ligne.dart';
import '../models/commande.dart';

class ServiceCommandesSupabase {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<String> creerCommandeDepuisPanier({
    required List<PanierLigne> lignes,
    String? adresseTexte,
  }) async {
    if (_userId == null) {
      throw Exception('Utilisateur non connecté');
    }
    if (lignes.isEmpty) {
      throw Exception('Panier vide');
    }

    final total = lignes.fold<int>(0, (sum, l) => sum + l.total);

    try {
      // 1) Créer la commande
      final commande = await _client
          .from('commandes')
          .insert({
            'client_id': _userId,
            'total': total,
            'statut': 'en_attente',
            'adresse_texte': adresseTexte,
          })
          .select()
          .single();

      final commandeId = commande['id'] as String;

      // 2) Créer les lignes
      final lignesData = lignes
          .map((l) => {
                'commande_id': commandeId,
                'produit_id': l.produitId,
                'vendeur_id': l.vendeurId,
                'nom': l.nom,
                'prix_unitaire': l.prixUnitaire,
                'quantite': l.quantite,
                'taille': l.taille,
                'couleur': l.couleur,
              })
          .toList();

      await _client.from('commande_lignes').insert(lignesData);

      return commandeId;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Impossible de créer la commande');
    }
  }

  Future<List<Commande>> listerMesCommandes() async {
    if (_userId == null) return [];

    try {
      final data = await _client
          .from('commandes')
          .select()
          .eq('client_id', _userId!)
          .order('created_at', ascending: false);

      return (data as List)
          .map((e) => Commande.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
