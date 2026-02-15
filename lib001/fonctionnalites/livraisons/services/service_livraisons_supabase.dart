import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/livraison.dart';

class ServiceLivraisonsSupabase {
  static final ServiceLivraisonsSupabase _instance =
      ServiceLivraisonsSupabase._internal();
  factory ServiceLivraisonsSupabase() => _instance;
  ServiceLivraisonsSupabase._internal();

  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<String> creerDemandeLivraison({
    required String departTexte,
    required String arriveeTexte,
    String? vendeurId,
    bool demandeSpeciale = false,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Utilisateur non connecté');

    final res = await _client
        .from('livraisons')
        .insert({
          'client_id': userId,
          'vendeur_id': vendeurId,
          'statut': 'en_attente',
          'depart_texte': departTexte.trim(),
          'arrivee_texte': arriveeTexte.trim(),
          'demande_speciale': demandeSpeciale,
          'frais_demande_speciale': demandeSpeciale ? 25 : 0,
        })
        .select('id')
        .single();

    return res['id'] as String;
  }

  Future<List<Livraison>> listerMesDemandesClient() async {
    final userId = _userId;
    if (userId == null) return [];

    final res = await _client
        .from('livraisons')
        .select()
        .eq('client_id', userId)
        .order('created_at', ascending: false);

    return (res as List).map((e) => Livraison.fromMap(e)).toList();
  }

  Future<List<Livraison>> listerDemandesDisponiblesLivreur() async {
    // MVP: livraisons en attente sans livreur assigné
    final res = await _client
        .from('livraisons')
        .select()
        .eq('statut', 'en_attente')
        .isFilter('livreur_id', null)
        .order('created_at', ascending: false);

    return (res as List).map((e) => Livraison.fromMap(e)).toList();
  }

  Future<void> accepterLivraison(String livraisonId) async {
    final userId = _userId;
    if (userId == null) throw Exception('Utilisateur non connecté');

    await _client.from('livraisons').update({
      'livreur_id': userId,
      'statut': 'acceptee',
    }).eq('id', livraisonId);
  }

  Future<void> changerStatut({
    required String livraisonId,
    required String statut,
  }) async {
    await _client.from('livraisons').update({
      'statut': statut,
    }).eq('id', livraisonId);
  }
}

