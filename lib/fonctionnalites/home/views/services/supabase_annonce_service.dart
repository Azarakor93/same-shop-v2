import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/annonces.dart';

class SupabaseAnnonceService {
  final _client = Supabase.instance.client;

  Future<List<Annonce>> chargerAnnonces() async {
    final maintenant = DateTime.now().toIso8601String();

    final response = await _client
        .from('annonces')
        .select()
        .eq('active', true)
        .or('date_debut.is.null,date_debut.lte.$maintenant')
        .or('date_fin.is.null,date_fin.gte.$maintenant')
        .order('ordre');

    return (response as List).map((e) => Annonce.fromMap(e)).toList();
  }

  Future<void> creerAnnonce({
    required String imageUrl,
    String? titre,
    String? lienType,
    String? lienValeur,
    DateTime? dateFin,
  }) async {
    await _client.from('annonces').insert({
      'titre': titre,
      'image_url': imageUrl,
      'lien_type': lienType,
      'lien_valeur': lienValeur,
      'active': true,
      'date_debut': DateTime.now().toIso8601String(),
      'date_fin': dateFin?.toIso8601String(),
    });
  }

}
