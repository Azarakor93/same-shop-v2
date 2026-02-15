import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/favori.dart';

class ServiceFavorisSupabase {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 📋 Récupérer tous les favoris de l'utilisateur
  Future<List<Favori>> recupererFavoris() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('favoris')
          .select('''
            *,
            produits!inner(nom, prix, images, boutique_id),
            boutiques(nom)
          ''')
          .eq('utilisateur_id', userId)
          .order('date_ajout', ascending: false);

      return (response as List).map((json) {
        return Favori(
          id: json['id'],
          produitId: json['produit_id'],
          nomProduit: json['produits']['nom'],
          imageProduit: (json['produits']['images'] as List?)?.firstOrNull,
          prix: (json['produits']['prix'] as num).toDouble(),
          nomBoutique: json['boutiques']?['nom'],
          dateAjout: DateTime.parse(json['date_ajout']),
        );
      }).toList();
    } catch (e) {
      print('❌ Erreur récupération favoris: $e');
      return [];
    }
  }

  // ➕ Ajouter aux favoris
  Future<bool> ajouterFavori(String produitId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('favoris').insert({
        'utilisateur_id': userId,
        'produit_id': produitId,
        'date_ajout': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('❌ Erreur ajout favori: $e');
      return false;
    }
  }

  // ➖ Retirer des favoris
  Future<bool> retirerFavori(String produitId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('favoris')
          .delete()
          .eq('utilisateur_id', userId)
          .eq('produit_id', produitId);

      return true;
    } catch (e) {
      print('❌ Erreur retrait favori: $e');
      return false;
    }
  }

  // ✅ Vérifier si un produit est en favori
  Future<bool> estEnFavori(String produitId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('favoris')
          .select('id')
          .eq('utilisateur_id', userId)
          .eq('produit_id', produitId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Erreur vérification favori: $e');
      return false;
    }
  }

  // 🔔 Stream des favoris en temps réel
  Stream<List<Favori>> streamFavoris() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('favoris')
        .stream(primaryKey: ['id'])
        .eq('utilisateur_id', userId)
        .map((data) {
          return data.map((json) => Favori.fromJson(json)).toList();
        });
  }
}
