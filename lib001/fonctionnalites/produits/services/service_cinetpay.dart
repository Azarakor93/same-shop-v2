// ===============================================
// 💳 SERVICE CINETPAY - SANS BACKEND
// ===============================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceCinetPay {
  // ⚠️ Remplace par tes clés sur dashboard.cinetpay.com
  static const String _apiKey = 'VOTRE_API_KEY';
  static const String _siteId = 'VOTRE_SITE_ID';

  static const String _urlPaiement = 'https://api-checkout.cinetpay.com/v2/payment';
  static const String _urlVerif = 'https://api-checkout.cinetpay.com/v2/payment/check';

  final _supabase = Supabase.instance.client;

  // ÉTAPE 1 — Créer la session de paiement
  Future<ResultatPaiement> initierPaiementBoost({
    required String produitId,
    required String nomProduit,
    required DureeBoost duree,
  }) async {
    final transactionId = 'BOOST_${produitId.replaceAll('-', '').substring(0, 8)}_'
        '${DateTime.now().millisecondsSinceEpoch}';

    try {
      final response = await http.post(
        Uri.parse(_urlPaiement),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'apikey': _apiKey,
          'site_id': _siteId,
          'transaction_id': transactionId,
          'amount': duree.prix,
          'currency': 'XOF',
          'description': 'Boost "$nomProduit" — ${duree.label}',
          'customer_id': _supabase.auth.currentUser?.id ?? '',
          'customer_name': 'Vendeur',
          'customer_email': _supabase.auth.currentUser?.email ?? '',
          'customer_phone_number': '',
          'customer_address': 'Lomé',
          'customer_city': 'Lomé',
          'customer_country': 'TG',
          'customer_state': 'TG',
          'customer_zip_code': '00228',
          'return_url': 'https://cinetpay.com/return',
          'channels': 'ALL',
          'lang': 'fr',
          'metadata': jsonEncode({
            'produit_id': produitId,
            'duree_jours': duree.jours,
          }),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == '201') {
          return ResultatPaiement(
            succes: true,
            paymentUrl: data['data']['payment_url'],
            transactionId: transactionId,
            produitId: produitId,
            duree: duree,
          );
        }
        return ResultatPaiement(
          succes: false,
          erreur: data['message'] ?? 'Erreur CinetPay (code ${data["code"]})',
        );
      }
      return ResultatPaiement(
        succes: false,
        erreur: 'Erreur réseau (HTTP ${response.statusCode})',
      );
    } catch (e) {
      return ResultatPaiement(
        succes: false,
        erreur: 'Impossible de contacter CinetPay : $e',
      );
    }
  }

  // ÉTAPE 2 — Vérifier le statut (appelé depuis l'app après retour WebView)
  Future<StatutTransaction> verifierPaiement(String transactionId) async {
    try {
      final response = await http.post(
        Uri.parse(_urlVerif),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'apikey': _apiKey,
          'site_id': _siteId,
          'transaction_id': transactionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['data']?['status'] ?? '';
        switch (status) {
          case 'ACCEPTED':
            return StatutTransaction.accepte;
          case 'REFUSED':
            return StatutTransaction.refuse;
          case 'CANCELLED':
            return StatutTransaction.annule;
          default:
            return StatutTransaction.enAttente;
        }
      }
      return StatutTransaction.erreur;
    } catch (_) {
      return StatutTransaction.erreur;
    }
  }

  // ÉTAPE 3 — Activer le boost dans Supabase directement
  Future<bool> activerBoost({
    required String produitId,
    required DureeBoost duree,
    required String transactionId,
  }) async {
    try {
      final maintenant = DateTime.now();

      // Récupérer le boost actuel du produit
      final data = await _supabase.from('produits').select('boost_actif, boost_expire_at').eq('id', produitId).single();

      final boostActif = data['boost_actif'] as bool? ?? false;
      final expireRaw = data['boost_expire_at'] as String?;

      // 🔑 Calcul intelligent de la base :
      // Boost encore actif → on ajoute à partir de la fin actuelle (cumul)
      // Boost expiré ou absent → on repart d'aujourd'hui
      DateTime baseDate;
      if (boostActif && expireRaw != null) {
        final expireActuelle = DateTime.parse(expireRaw);
        baseDate = expireActuelle.isAfter(maintenant)
            ? expireActuelle // ✅ encore valide → cumule
            : maintenant; // expiré → repart de zéro
      } else {
        baseDate = maintenant;
      }

      final nouvelleExpiration = baseDate.add(Duration(days: duree.jours)).toIso8601String();

      // Mettre à jour le produit
      await _supabase.from('produits').update({
        'boost_actif': true,
        'boost_expire_at': nouvelleExpiration,
      }).eq('id', produitId);

      // Log dans l'historique avec la base de calcul
      await _supabase.from('boost_historique').insert({
        'produit_id': produitId,
        'transaction_id': transactionId,
        'duree_jours': duree.jours,
        'montant': duree.prix,
        'base_calcul': baseDate.toIso8601String(),
        'expire_at': nouvelleExpiration,
        'created_at': maintenant.toIso8601String(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}

// ===============================================
// 📦 MODÈLES
// ===============================================

class ResultatPaiement {
  final bool succes;
  final String? paymentUrl;
  final String? transactionId;
  final String? produitId;
  final DureeBoost? duree;
  final String? erreur;

  const ResultatPaiement({
    required this.succes,
    this.paymentUrl,
    this.transactionId,
    this.produitId,
    this.duree,
    this.erreur,
  });
}

enum StatutTransaction { enAttente, accepte, refuse, annule, erreur }

class DureeBoost {
  final String label;
  final String description;
  final int jours;
  final int prix;

  const DureeBoost({
    required this.label,
    required this.description,
    required this.jours,
    required this.prix,
  });

  static const jour1 = DureeBoost(label: '1 jour', description: 'Mise en avant 24h', jours: 1, prix: 200);
  static const jours3 = DureeBoost(label: '3 jours', description: 'Top position 72h', jours: 3, prix: 500);
  static const semaine1 = DureeBoost(label: '1 semaine', description: 'Visibilité max 7 jours', jours: 7, prix: 1500);
  static const mois1 = DureeBoost(label: '1 mois', description: 'Visibilité maximale 30 jours', jours: 30, prix: 3000);

  static List<DureeBoost> get toutes => [jour1, jours3, semaine1, mois1];
}
