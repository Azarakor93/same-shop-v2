import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/demande_fournisseur.dart';
import '../models/reponse_fournisseur.dart';

class ServiceFournisseursSupabase {
  static final ServiceFournisseursSupabase _instance =
      ServiceFournisseursSupabase._internal();
  factory ServiceFournisseursSupabase() => _instance;
  ServiceFournisseursSupabase._internal();

  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<String> creerDemande({
    required String demandeurId,
    required String transactionId,
    required String produitRecherche,
    int? quantite,
    int? budget,
    String? ville,
    String? pays,
    String? livraisonVille,
    String? details,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Utilisateur non connecté');
    if (userId != demandeurId) {
      // Sécurité côté app (RLS fera foi côté DB)
      throw Exception('Action non autorisée');
    }

    final maintenant = DateTime.now();
    final expireAt = maintenant.add(const Duration(days: 7));

    final data = await _client
        .from('demandes_fournisseurs')
        .insert({
          'demandeur_id': demandeurId,
          'transaction_id': transactionId,
          'produit_recherche': produitRecherche.trim(),
          'quantite': quantite,
          'budget': budget,
          'ville': ville?.trim(),
          'pays': pays?.trim(),
          'livraison_ville': livraisonVille?.trim(),
          'details': details?.trim(),
          'active': true,
          'expire_at': expireAt.toIso8601String(),
        })
        .select('id')
        .single();

    return data['id'] as String;
  }

  Future<List<DemandeFournisseur>> listerMesDemandes({
    required String demandeurId,
  }) async {
    final userId = _userId;
    if (userId == null) return [];

    final response = await _client
        .from('demandes_fournisseurs')
        .select()
        .eq('demandeur_id', demandeurId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => DemandeFournisseur.fromMap(e))
        .toList();
  }

  Future<List<DemandeFournisseur>> listerDemandesActives({
    String? exclureDemandeurId,
  }) async {
    final maintenant = DateTime.now().toIso8601String();

    var query = _client
        .from('demandes_fournisseurs')
        .select()
        .eq('active', true)
        .gt('expire_at', maintenant);

    if (exclureDemandeurId != null) {
      query = query.neq('demandeur_id', exclureDemandeurId);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((e) => DemandeFournisseur.fromMap(e))
        .toList();
  }

  Future<List<ReponseFournisseur>> listerReponses({
    required String demandeId,
  }) async {
    final response = await _client
        .from('reponses_fournisseurs')
        .select()
        .eq('demande_id', demandeId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => ReponseFournisseur.fromMap(e))
        .toList();
  }

  Future<void> repondre({
    required String demandeId,
    required String fournisseurId,
    required String message,
    int? prixPropose,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Utilisateur non connecté');
    if (userId != fournisseurId) {
      throw Exception('Action non autorisée');
    }

    await _client.from('reponses_fournisseurs').insert({
      'demande_id': demandeId,
      'fournisseur_id': fournisseurId,
      'message': message.trim(),
      'prix_propose': prixPropose,
    });
  }
}

