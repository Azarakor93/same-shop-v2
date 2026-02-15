import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enchere.dart';
import '../models/enchere_offre.dart';

class ServiceEncheresSupabase {
  static final ServiceEncheresSupabase _instance =
      ServiceEncheresSupabase._internal();
  factory ServiceEncheresSupabase() => _instance;
  ServiceEncheresSupabase._internal();

  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<Enchere>> listerEncheresEnCours() async {
    final res = await _client
        .from('encheres')
        .select()
        .eq('statut', 'en_cours')
        .order('date_fin', ascending: true);

    return (res as List).map((e) => Enchere.fromMap(e)).toList();
  }

  Future<List<Enchere>> listerMesGains() async {
    final userId = _userId;
    if (userId == null) return [];

    final res = await _client
        .from('encheres')
        .select()
        .eq('gagnant_id', userId)
        .order('created_at', ascending: false);

    return (res as List).map((e) => Enchere.fromMap(e)).toList();
  }

  Future<List<EnchereOffre>> listerOffres(String enchereId) async {
    final res = await _client
        .from('encheres_offres')
        .select()
        .eq('enchere_id', enchereId)
        .order('created_at', ascending: false);

    return (res as List).map((e) => EnchereOffre.fromMap(e)).toList();
  }

  Future<void> placerOffre({
    required String enchereId,
    required int montant,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Utilisateur non connecté');

    await _client.from('encheres_offres').insert({
      'enchere_id': enchereId,
      'acheteur_id': userId,
      'montant': montant,
    });
  }
}

