// ===============================================
// 🔌 SERVICE VENDEUR SUPABASE
// ===============================================
// Gère toutes les interactions avec la base de données
// pour l'espace vendeur

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/boutique.dart';

class ServiceVendeurSupabase {
  // ===============================================
  // 🔧 SINGLETON PATTERN
  // ===============================================
  static final ServiceVendeurSupabase _instance =
      ServiceVendeurSupabase._internal();
  factory ServiceVendeurSupabase() => _instance;
  ServiceVendeurSupabase._internal();

  // ===============================================
  // 📡 CLIENTS & GETTERS
  // ===============================================
  final SupabaseClient _client = Supabase.instance.client;

  User? get _utilisateurActuel => _client.auth.currentUser;
  String get _userId => _utilisateurActuel?.id ?? '';
  String get userId => _userId; // ✅ public

  bool get estConnecte => _utilisateurActuel != null;

  // ===============================================
  // 📊 COMPTER LES BOUTIQUES
  // ===============================================
  /// Retourne le nombre de boutiques de l'utilisateur actuel
  Future<int> nombreBoutiques() async {
    try {
      if (!estConnecte) return 0;

      final response = await _client
          .from('vendeurs')
          .select('id')
          .eq('id', _userId)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      throw _gererErreur(e, 'Impossible de compter les boutiques');
    }
  }

  // ===============================================
  // 📋 LISTER LES BOUTIQUES
  // ===============================================
  /// Récupère toutes les boutiques de l'utilisateur
  Future<List<Boutique>> listerBoutiques() async {
    try {
      if (!estConnecte) return [];

      final data = await _client
          .from('vendeurs')
          .select()
          .eq('id', _userId)
          .order('created_at', ascending: false);

      return (data as List).map((e) => Boutique.fromMap(e)).toList();
    } catch (e) {
      throw _gererErreur(e, 'Impossible de charger les boutiques');
    }
  }

  /// Catalogue public : toutes les boutiques (RLS doit autoriser la lecture)
  Future<List<Boutique>> listerToutesBoutiques() async {
    try {
      final data = await _client
          .from('vendeurs')
          .select()
          .eq('est_suspendu', false)
          .order('created_at', ascending: false);

      return (data as List).map((e) => Boutique.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // ===============================================
  // 🔍 RÉCUPÉRER UNE BOUTIQUE PAR ID
  // ===============================================
  /// Récupère une boutique spécifique
  Future<Boutique?> recupererBoutique(String boutiqueId) async {
    try {
      if (!estConnecte) return null;

      final data =
          await _client.from('vendeurs').select().eq('id', boutiqueId).single();

      return Boutique.fromMap(data);
    } catch (e) {
      throw _gererErreur(e, 'Boutique introuvable');
    }
  }

  // ===============================================
  // ➕ CRÉER UNE BOUTIQUE
  // ===============================================
  /// Crée une nouvelle boutique dans la base de données
  Future<void> creerBoutique({
    required String nomBoutique,
    required String telephone,
    required String pays,
    required String ville,
    String? quartier,
    String? description,
    String? logoUrl,
    required double latitude,
    required double longitude,
  }) async {
    try {
      if (!estConnecte) {
        throw Exception('Utilisateur non connecté');
      }

      // Vérifier le nombre de boutiques
      final nbBoutiques = await nombreBoutiques();

      // Définir le type d'abonnement
      final typeAbonnement = nbBoutiques == 0 ? 'gratuit' : 'premium';

      await _client.from('vendeurs').insert({
        'id': _userId,
        'nom_boutique': nomBoutique.trim(),
        'description': description?.trim(),
        'telephone': telephone.trim(),
        'pays': pays.trim(),
        'ville': ville.trim(),
        'quartier': quartier?.trim(),
        'logo_url': logoUrl,
        'latitude': latitude,
        'longitude': longitude,
        'type_abonnement': typeAbonnement,
        'est_verifie': false,
        'est_suspendu': false,
      });
    } catch (e) {
      throw _gererErreur(e, 'Impossible de créer la boutique');
    }
  }

  // ===============================================
  // ✏️ MODIFIER UNE BOUTIQUE
  // ===============================================
  /// Met à jour les informations d'une boutique
  Future<void> modifierBoutique(Boutique boutique) async {
    try {
      if (!estConnecte) {
        throw Exception('Utilisateur non connecté');
      }

      await _client.from('vendeurs').update({
        'nom_boutique': boutique.nomBoutique.trim(),
        'description': boutique.description?.trim(),
        'telephone': boutique.telephone.trim(),
        'pays': boutique.pays.trim(),
        'ville': boutique.ville.trim(),
        'quartier': boutique.quartier?.trim(),
        'logo_url': boutique.logoUrl,
        'latitude': boutique.latitude,
        'longitude': boutique.longitude,
      }).eq('id', boutique.id);
    } catch (e) {
      throw _gererErreur(e, 'Impossible de modifier la boutique');
    }
  }

  // ===============================================
  // 🗑️ SUPPRIMER UNE BOUTIQUE
  // ===============================================
  /// Supprime définitivement une boutique
  Future<void> supprimerBoutique(String boutiqueId) async {
    try {
      if (!estConnecte) {
        throw Exception('Utilisateur non connecté');
      }

      await _client.from('vendeurs').delete().eq('id', boutiqueId);
    } catch (e) {
      throw _gererErreur(e, 'Impossible de supprimer la boutique');
    }
  }

  // ===============================================
  // 📸 UPLOAD LOGO
  // ===============================================
  /// Upload un logo de boutique et retourne l'URL publique
  Future<String?> uploadLogo(File fichier) async {
    try {
      if (!estConnecte) return null;

      final extension = fichier.path.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final chemin = 'logos/${_userId}_$timestamp.$extension';

      await _client.storage.from('boutiques').upload(
            chemin,
            fichier,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      return _client.storage.from('boutiques').getPublicUrl(chemin);
    } catch (e) {
      throw _gererErreur(e, 'Impossible d\'uploader le logo');
    }
  }

  // ===============================================
  // 💳 CRÉER UN ABONNEMENT PREMIUM
  // ===============================================
  /// Crée une demande d'abonnement premium
  Future<void> creerAbonnement({
    required String boutiqueId,
    required String moyenPaiement,
  }) async {
    try {
      if (!estConnecte) {
        throw Exception('Utilisateur non connecté');
      }

      await _client.from('abonnements').insert({
        'user_id': _userId,
        'boutique_id': boutiqueId,
        'montant': 5000,
        'moyen_paiement': moyenPaiement,
        'statut': 'en_attente',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw _gererErreur(e, 'Impossible de créer l\'abonnement');
    }
  }

  // ===============================================
  // ✅ ACTIVER L'ABONNEMENT PREMIUM
  // ===============================================
  /// Active le premium pour une boutique après paiement
  Future<void> activerPremium(String boutiqueId) async {
    try {
      if (!estConnecte) return;

      final dateExpiration = DateTime.now().add(const Duration(days: 365));

      await _client.from('vendeurs').update({
        'type_abonnement': 'premium',
        'date_expiration_abonnement': dateExpiration.toIso8601String(),
      }).eq('id', boutiqueId);
    } catch (e) {
      throw _gererErreur(e, 'Impossible d\'activer le premium');
    }
  }

  // ===============================================
  // 🚨 GESTION DES ERREURS
  // ===============================================
  Exception _gererErreur(dynamic erreur, String messageParDefaut) {
    if (erreur is PostgrestException) {
      return Exception(erreur.message);
    }
    if (erreur is StorageException) {
      return Exception(erreur.message);
    }
    return Exception(messageParDefaut);
  }

  // ===============================================
  // 🧹 NETTOYAGE
  // ===============================================
  void dispose() {
    // Cleanup si nécessaire
  }
}
