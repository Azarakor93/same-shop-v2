// ===============================================
// 💳 SERVICE PAIEMENT
// ===============================================
// Gestion des paiements T-Money et Flooz

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../vendeur/models/boutique.dart';

class ServicePaiement {
  final _supabase = Supabase.instance.client;

  // ===============================================
  // 💰 INITIER UN PAIEMENT
  // ===============================================
  Future<ResultatPaiement> initierPaiement({
    required MethodePaiement methode,
    required String numero,
    required int montant,
    required TypeAbonnement typeAbonnement,
    String? boutiqueId, // compat: ancien nom (vendeur_id)
    String? vendeurId, // ✅ vendeur_id (boutique)
    String? produitId, // Pour boost produit
    TypeTransaction? typeTransaction,
    int? dureeJours, // Pour boost (et futurs modules)
  }) async {
    try {
      // Obtenir l'utilisateur courant
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final resolvedVendeurId = vendeurId ?? boutiqueId;

      // Préparer les données de transaction
      final Map<String, dynamic> transactionData = {
        'user_id': userId,
        'methode_paiement': methode.name,
        'numero_telephone': numero,
        'montant': montant,
        'type_abonnement': typeAbonnement.value,
        'type_transaction': (typeTransaction ?? TypeTransaction.abonnement).name,
        'statut': 'en_attente',
        'date_creation': DateTime.now().toIso8601String(),
      };

      if (resolvedVendeurId != null) {
        // ✅ Schéma Supabase: transactions.vendeur_id
        transactionData['vendeur_id'] = resolvedVendeurId;
      }

      if (produitId != null) {
        transactionData['produit_id'] = produitId;
      }

      if (dureeJours != null) {
        // ⚠️ Nécessite la colonne transactions.duree_jours (voir script SQL)
        transactionData['duree_jours'] = dureeJours;
      }

      // Insérer la transaction dans la base de données
      // (fallback si la colonne duree_jours n'est pas encore ajoutée)
      Map<String, dynamic> response;
      try {
        response = await _supabase
            .from('transactions')
            .insert(transactionData)
            .select()
            .single();
      } catch (e) {
        if (dureeJours != null && transactionData.containsKey('duree_jours')) {
          final sansDuree = Map<String, dynamic>.from(transactionData)
            ..remove('duree_jours');
          response = await _supabase
              .from('transactions')
              .insert(sansDuree)
              .select()
              .single();
        } else {
          rethrow;
        }
      }

      final transactionId = response['id'] as String;

      // Appeler l'API de paiement appropriée
      if (methode == MethodePaiement.tmoney) {
        await _initierPaiementTMoney(numero, montant, transactionId);
      } else {
        await _initierPaiementFlooz(numero, montant, transactionId);
      }

      return ResultatPaiement(
        succes: true,
        message: 'Paiement initié avec succès',
        transactionId: transactionId,
      );
    } catch (e) {
      return ResultatPaiement(
        succes: false,
        message: 'Erreur lors de l\'initiation du paiement: $e',
      );
    }
  }

  // ===============================================
  // 📱 T-MONEY API
  // ===============================================
  Future<void> _initierPaiementTMoney(
    String numero,
    int montant,
    String transactionId,
  ) async {
    // TODO: Intégrer l'API T-Money réelle
    // Documentation: https://developer.togocom.tg/

    /*
    EXEMPLE D'INTÉGRATION T-MONEY:
    
    final response = await http.post(
      Uri.parse('https://api.togocom.tg/v1/pay/initialize'),
      headers: {
        'Authorization': 'Bearer VOTRE_API_KEY',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'amount': montant,
        'phone': numero,
        'reference': transactionId,
        'description': 'Abonnement SameShop',
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Enregistrer les détails de la transaction
      await _supabase
          .from('transactions')
          .update({
            'reference_externe': data['transactionId'],
            'statut': 'en_cours',
          })
          .eq('id', transactionId);
    }
    */

    // SIMULATION POUR DÉVELOPPEMENT
    await Future.delayed(const Duration(seconds: 2));

    await _supabase.from('transactions').update({
      'reference_externe': 'TMONEY_${DateTime.now().millisecondsSinceEpoch}',
      'statut': 'en_cours',
    }).eq('id', transactionId);
  }

  // ===============================================
  // 📱 FLOOZ API
  // ===============================================
  Future<void> _initierPaiementFlooz(
    String numero,
    int montant,
    String transactionId,
  ) async {
    // TODO: Intégrer l'API Flooz réelle
    // Documentation: https://flooz.moov-africa.tg/

    /*
    EXEMPLE D'INTÉGRATION FLOOZ:
    
    final response = await http.post(
      Uri.parse('https://api.moov-africa.tg/v1/payments'),
      headers: {
        'Authorization': 'Bearer VOTRE_API_KEY',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'amount': montant,
        'currency': 'XOF',
        'phone': numero,
        'reference': transactionId,
        'description': 'Abonnement SameShop',
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _supabase
          .from('transactions')
          .update({
            'reference_externe': data['paymentId'],
            'statut': 'en_cours',
          })
          .eq('id', transactionId);
    }
    */

    // SIMULATION POUR DÉVELOPPEMENT
    await Future.delayed(const Duration(seconds: 2));

    await _supabase.from('transactions').update({
      'reference_externe': 'FLOOZ_${DateTime.now().millisecondsSinceEpoch}',
      'statut': 'en_cours',
    }).eq('id', transactionId);
  }

  // ===============================================
  // ✅ VÉRIFIER LE STATUT D'UN PAIEMENT
  // ===============================================
  Future<bool> verifierPaiement(String transactionId) async {
    try {
      // Récupérer la transaction
      final transaction = await _supabase.from('transactions').select().eq('id', transactionId).single();

      final statut = transaction['statut'] as String;

      // Si déjà validé, retourner true
      if (statut == 'valide') {
        return true;
      }

      // Vérifier auprès de l'API
      final methode = transaction['methode_paiement'] as String;
      final referenceExterne = transaction['reference_externe'] as String?;

      if (referenceExterne == null) {
        return false;
      }

      bool estValide = false;

      if (methode == 'tmoney') {
        estValide = await _verifierPaiementTMoney(referenceExterne);
      } else {
        estValide = await _verifierPaiementFlooz(referenceExterne);
      }

      // Si validé, mettre à jour la transaction et activer l'abonnement
      if (estValide) {
        await _supabase.from('transactions').update({
          'statut': 'valide',
          'date_validation': DateTime.now().toIso8601String(),
        }).eq('id', transactionId);

        // Activer l'abonnement
        await _activerAbonnement(transaction);
      }

      return estValide;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur vérification paiement: $e');
      }
      return false;
    }
  }

  // ===============================================
  // ✅ VÉRIFIER T-MONEY
  // ===============================================
  Future<bool> _verifierPaiementTMoney(String referenceExterne) async {
    // TODO: Appeler l'API T-Money pour vérifier le statut

    /*
    final response = await http.get(
      Uri.parse('https://api.togocom.tg/v1/pay/status/$referenceExterne'),
      headers: {
        'Authorization': 'Bearer VOTRE_API_KEY',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'SUCCESS';
    }
    */

    // SIMULATION: 80% de chance de succès
    await Future.delayed(const Duration(seconds: 1));
    return DateTime.now().second % 5 != 0;
  }

  // ===============================================
  // ✅ VÉRIFIER FLOOZ
  // ===============================================
  Future<bool> _verifierPaiementFlooz(String referenceExterne) async {
    // TODO: Appeler l'API Flooz pour vérifier le statut

    /*
    final response = await http.get(
      Uri.parse('https://api.moov-africa.tg/v1/payments/$referenceExterne'),
      headers: {
        'Authorization': 'Bearer VOTRE_API_KEY',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'COMPLETED';
    }
    */

    // SIMULATION: 80% de chance de succès
    await Future.delayed(const Duration(seconds: 1));
    return DateTime.now().second % 5 != 0;
  }

  // ===============================================
  // 🎯 ACTIVER L'ABONNEMENT
  // ===============================================
  Future<void> _activerAbonnement(Map<String, dynamic> transaction) async {
    final typeTransaction = transaction['type_transaction'] as String;

    if (typeTransaction == 'abonnement') {
      // Activer l'abonnement de la boutique
      final vendeurId = transaction['vendeur_id'] as String?;
      final typeAbonnement = transaction['type_abonnement'] as String;

      if (vendeurId != null) {
        // Calculer la date d'expiration (1 mois)
        final dateExpiration = DateTime.now().add(const Duration(days: 30));

        // ✅ Table Supabase: vendeurs
        await _supabase.from('vendeurs').update({
          'type_abonnement': typeAbonnement,
          'date_expiration_abonnement': dateExpiration.toIso8601String(),
        }).eq('id', vendeurId);
      }
    } else if (typeTransaction == 'boost') {
      // Activer le boost du produit
      final produitId = transaction['produit_id'] as String?;

      if (produitId != null) {
        // Durée boost (par défaut 7 jours si non fournie)
        final int dureeJours = (transaction['duree_jours'] as int?) ?? 7;

        final maintenant = DateTime.now();

        // ✅ Boost cumulatif (schema recommandé: boost_actif / boost_expire_at)
        try {
          final produit = await _supabase
              .from('produits')
              .select('boost_actif, boost_expire_at')
              .eq('id', produitId)
              .single();

          final boostActif = produit['boost_actif'] as bool? ?? false;
          final expireRaw = produit['boost_expire_at'] as String?;

          DateTime baseDate = maintenant;
          if (boostActif && expireRaw != null) {
            final expireActuelle = DateTime.tryParse(expireRaw);
            if (expireActuelle != null && expireActuelle.isAfter(maintenant)) {
              baseDate = expireActuelle;
            }
          }

          final nouvelleExpiration =
              baseDate.add(Duration(days: dureeJours)).toIso8601String();

          await _supabase.from('produits').update({
            'boost_actif': true,
            'boost_expire_at': nouvelleExpiration,
          }).eq('id', produitId);

          // Historique (si la table existe)
          try {
            await _supabase.from('boost_historique').insert({
              'produit_id': produitId,
              'transaction_id': transaction['id'],
              'duree_jours': dureeJours,
              'montant': transaction['montant'],
              'base_calcul': baseDate.toIso8601String(),
              'expire_at': nouvelleExpiration,
              'created_at': maintenant.toIso8601String(),
            });
          } catch (_) {
            // Ignorer si la table n'est pas encore créée
          }
        } catch (_) {
          // ✅ Fallback legacy (schema: est_booste / date_expiration_boost)
          final dateExpiration =
              maintenant.add(Duration(days: dureeJours)).toIso8601String();
          await _supabase.from('produits').update({
            'est_booste': true,
            'date_expiration_boost': dateExpiration,
          }).eq('id', produitId);
        }
      }
    }
  }

  // ===============================================
  // 📊 HISTORIQUE DES TRANSACTIONS
  // ===============================================
  Future<List<Map<String, dynamic>>> historiqueTransactions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase.from('transactions').select().eq('user_id', userId).order('date_creation', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ===============================================
  // 💰 BOOSTER UN PRODUIT
  // ===============================================
  Future<ResultatPaiement> boosterProduit({
    required String produitId,
    required MethodePaiement methode,
    required String numero,
    required int montant,
    required int dureeJours,
  }) async {
    return initierPaiement(
      methode: methode,
      numero: numero,
      montant: montant,
      typeAbonnement: TypeAbonnement.premium, // N'est pas utilisé pour boost
      produitId: produitId,
      typeTransaction: TypeTransaction.boost,
      dureeJours: dureeJours,
    );
  }
}

// ===============================================
// 📊 ENUMS & MODÈLES
// ===============================================
enum MethodePaiement {
  tmoney,
  flooz,
}

enum TypeTransaction {
  abonnement,
  boost,
  fournisseur,
}

class ResultatPaiement {
  final bool succes;
  final String? message;
  final String? transactionId;

  ResultatPaiement({
    required this.succes,
    this.message,
    this.transactionId,
  });
}
