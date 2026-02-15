import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/annonces.dart';

class SupabaseAnnonceService {
  final _client = Supabase.instance.client;

  Future<List<Annonce>> chargerAnnonces() async {
    final response = await _client
        .from('annonces')
        .select()
        .eq('active', true)
        .order('ordre');

    return (response as List).map((e) => Annonce.fromMap(e)).toList();
  }
}
