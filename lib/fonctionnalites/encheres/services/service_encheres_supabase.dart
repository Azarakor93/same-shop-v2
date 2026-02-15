import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enchere.dart';
import '../models/enchere_offre.dart';

class ServiceEncheresSupabase {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 📋 Récupérer toutes les enchères actives
  Future<List<Enchere>> recupererEncheresActives() async {
    try {
      final response = await _supabase
          .from('encheres')
          .select('''
            *,
            produits!inner(nom, images),
            boutiques!inner(nom)
          ''')
          .eq('statut', 'en_cours')
          .gte('date_fin', DateTime.now().toIso8601String())
          .order('date_fin', ascending: true);

      return (response as List).map((json) {
        // Construction manuelle car jointures complexes
        return Enchere(
          id: json['id'],
          produitId: json['produit_id'],
          nomProduit: json['produits']['nom'],
          imageProduit: (json['produits']['images'] as List?)?.firstOrNull,
          boutiqueId: json['boutique_id'],
          nomBoutique: json['boutiques']['nom'],
          prixDepart: (json['prix_depart'] as num).toDouble(),
          prixActuel: (json['prix_actuel'] as num).toDouble(),
          dateDebut: DateTime.parse(json['date_debut']),
          dateFin: DateTime.parse(json['date_fin']),
          nombreEncherisseurs: json['nombre_encherisseurs'] ?? 0,
          dernierEncherisseurId: json['dernier_encherisseur_id'],
          dernierEncherisseurNom: json['dernier_encherisseur_nom'],
          statut: json['statut'],
          description: json['description'],
        );
      }).toList();
    } catch (e) {
      print('❌ Erreur récupération enchères: $e');
      return [];
    }
  }

  // 🔥 Récupérer les enchères populaires (nouvelles + plus d'enchérisseurs)
  Future<List<Enchere>> recupererEncheresPopulaires({int limite = 10}) async {
    try {
      final response = await _supabase
          .from('encheres')
          .select('''
            *,
            produits!inner(nom, images),
            boutiques!inner(nom)
          ''')
          .eq('statut', 'en_cours')
          .gte('date_fin', DateTime.now().toIso8601String())
          .order('nombre_encherisseurs', ascending: false)
          .limit(limite);

      return (response as List).map((json) {
        return Enchere(
          id: json['id'],
          produitId: json['produit_id'],
          nomProduit: json['produits']['nom'],
          imageProduit: (json['produits']['images'] as List?)?.firstOrNull,
          boutiqueId: json['boutique_id'],
          nomBoutique: json['boutiques']['nom'],
          prixDepart: (json['prix_depart'] as num).toDouble(),
          prixActuel: (json['prix_actuel'] as num).toDouble(),
          dateDebut: DateTime.parse(json['date_debut']),
          dateFin: DateTime.parse(json['date_fin']),
          nombreEncherisseurs: json['nombre_encherisseurs'] ?? 0,
          dernierEncherisseurId: json['dernier_encherisseur_id'],
          dernierEncherisseurNom: json['dernier_encherisseur_nom'],
          statut: json['statut'],
          description: json['description'],
        );
      }).toList();
    } catch (e) {
      print('❌ Erreur enchères populaires: $e');
      return [];
    }
  }

  // 📝 Placer une enchère
  Future<bool> placerEnchere({
    required String enchereId,
    required double montant,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Non authentifié');

      // 1. Créer l'offre
      await _supabase.from('enchere_offres').insert({
        'enchere_id': enchereId,
        'utilisateur_id': userId,
        'montant': montant,
        'date_offre': DateTime.now().toIso8601String(),
        'statut': 'active',
      });

      // 2. Mettre à jour l'enchère
      await _supabase.from('encheres').update({
        'prix_actuel': montant,
        'dernier_encherisseur_id': userId,
        'nombre_encherisseurs': _supabase.rpc('increment_encherisseurs', params: {'enchere_id': enchereId}),
      }).eq('id', enchereId);

      return true;
    } catch (e) {
      print('❌ Erreur placement enchère: $e');
      return false;
    }
  }

  // 📜 Récupérer l'historique des offres d'une enchère
  Future<List<EnchereOffre>> recupererOffres(String enchereId) async {
    try {
      final response = await _supabase
          .from('enchere_offres')
          .select('''
            *,
            profiles!inner(nom_complet)
          ''')
          .eq('enchere_id', enchereId)
          .order('montant', ascending: false);

      return (response as List).map((json) {
        return EnchereOffre(
          id: json['id'],
          enchereId: json['enchere_id'],
          utilisateurId: json['utilisateur_id'],
          nomUtilisateur: json['profiles']['nom_complet'] ?? 'Utilisateur',
          montant: (json['montant'] as num).toDouble(),
          dateOffre: DateTime.parse(json['date_offre']),
          statut: json['statut'],
        );
      }).toList();
    } catch (e) {
      print('❌ Erreur récupération offres: $e');
      return [];
    }
  }

  // 🔔 Stream d'enchère en temps réel
  Stream<Enchere?> streamEnchere(String enchereId) {
    return _supabase
        .from('encheres')
        .stream(primaryKey: ['id'])
        .eq('id', enchereId)
        .map((data) {
          if (data.isEmpty) return null;
          return Enchere.fromJson(data.first);
        });
  }
}
