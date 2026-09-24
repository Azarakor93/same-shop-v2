// ===============================================
// 📦 SERVICE PRODUIT SUPABASE
// ===============================================
// Gère toutes les opérations CRUD sur les produits

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/produit.dart';
import '../models/variante_temp.dart';

class ServiceProduitSupabase {
  // ===============================================
  // 🔧 SINGLETON PATTERN
  // ===============================================
  static final ServiceProduitSupabase _instance = ServiceProduitSupabase._internal();
  factory ServiceProduitSupabase() => _instance;
  ServiceProduitSupabase._internal();

  // ===============================================
  // 📡 CLIENTS & GETTERS
  // ===============================================
  final SupabaseClient _client = Supabase.instance.client;

  User? get _utilisateurActuel => _client.auth.currentUser;
  bool get estConnecte => _utilisateurActuel != null;

  // ===============================================
  // 📊 COMPTER LES PRODUITS D'UNE BOUTIQUE
  // ===============================================
  Future<int> nombreProduitsVendeur(String vendeurId) async {
    try {
      final response = await _client.from('produits').select('id').eq('vendeur_id', vendeurId).count(CountOption.exact);

      return response.count;
    } catch (e) {
      throw _gererErreur(e, 'Impossible de compter les produits');
    }
  }

  // ===============================================
  // 📋 LISTER LES PRODUITS D'UNE BOUTIQUE
  // ===============================================
  Future<List<Produit>> listerProduitsVendeur(String vendeurId) async {
    try {
      final data = await _client.from('produits').select().eq('vendeur_id', vendeurId).order('created_at', ascending: false);

      return (data as List).map((e) => Produit.fromMap(e)).toList();
    } catch (e) {
      throw _gererErreur(e, 'Impossible de charger les produits');
    }
  }

  // ===============================================
  // 🔍 RÉCUPÉRER UN PRODUIT PAR ID
  // ===============================================
  Future<Produit?> recupererProduit(String produitId) async {
    try {
      final data = await _client.from('produits').select().eq('id', produitId).single();

      return Produit.fromMap(data);
    } catch (e) {
      throw _gererErreur(e, 'Produit introuvable');
    }
  }

  // ===============================================
// 📄 PAGINATION PRODUITS - INFINITE SCROLL
// ===============================================
  // ===============================================
// 📄 PAGINATION PRODUITS - INFINITE SCROLL
// ===============================================
  // ===============================================
// 📄 PAGINATION PRODUITS - INFINITE SCROLL
// ===============================================
  Future<List<Produit>> listerProduitsPage({
    required int page, // Page 0, 1, 2...
    required int pageSize, // 20 produits par page
  }) async {
    try {
      final offset = page * pageSize; // 0, 20, 40...

      // ✅ EXACTEMENT comme recupererProduit() + pagination
      final data = await _client
          .from('produits')
          .select()
          .eq('actif', true) // ✅ Filtre AVANT order
          .order('ordre_top', ascending: false) // ✅ Tri
          .order('nombre_vues', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + pageSize - 1); // ✅ Pagination

      return (data as List).map((e) => Produit.fromMap(e)).toList();
    } catch (e) {
      throw _gererErreur(e, 'Erreur pagination produits');
    }
  }

  Future<List<Produit>> listerAllProduitsPage({
    required int page,
    required int pageSize,
  }) async {
    try {
      final offset = page * pageSize;

      final data = await _client.from('produits').select().order('created_at', ascending: false).range(offset, offset + pageSize - 1);

      return (data as List).map((e) => Produit.fromMap(e)).toList();
    } catch (e) {
      throw _gererErreur(e, 'Pagination produits');
    }
  }

  // ===============================================
  // ➕ CRÉER UN PRODUIT
  // ===============================================
  Future<String> creerProduit({
    required String vendeurId,
    required String categorieId,
    required String nom,
    String? description,
    required int prix,
    int? stockGlobal,
    EtatProduit etatProduit = EtatProduit.neuf,
    bool livraisonDisponible = false,
    double? poids,
    String? marque,
  }) async {
    try {
      if (!estConnecte) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await _client
          .from('produits')
          .insert({
            'vendeur_id': vendeurId,
            'categorie_id': categorieId,
            'nom': nom.trim(),
            'description': description?.trim(),
            'prix': prix,
            'stock_global': stockGlobal,
            'etat_produit': etatProduit.value,
            'livraison_disponible': livraisonDisponible,
            'poids': poids,
            'marque': marque?.trim(),
            'actif': true,
            'note': 0,
            'nombre_vues': 0,
            'nombre_ventes': 0,
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw _gererErreur(e, 'Impossible de créer le produit');
    }
  }

  // ===============================================
  // ✏️ MODIFIER UN PRODUIT
  // ===============================================
  Future<void> modifierProduit(Produit produit) async {
    try {
      if (!estConnecte) {
        throw Exception('Utilisateur non connecté');
      }

      await _client.from('produits').update({
        'categorie_id': produit.categorieId,
        'nom': produit.nom.trim(),
        'description': produit.description?.trim(),
        'prix': produit.prix,
        'stock_global': produit.stockGlobal,
        'etat_produit': produit.etatProduit.value,
        'livraison_disponible': produit.livraisonDisponible,
        'poids': produit.poids,
        'marque': produit.marque?.trim(),
        'actif': produit.actif,
      }).eq('id', produit.id);
    } catch (e) {
      throw _gererErreur(e, 'Impossible de modifier le produit');
    }
  }

  // ===============================================
  // 🗑️ SUPPRIMER UN PRODUIT
  // ===============================================
  Future<void> supprimerProduit(String produitId) async {
    try {
      if (!estConnecte) {
        throw Exception('Utilisateur non connecté');
      }

      await _client.from('produits').delete().eq('id', produitId);
    } catch (e) {
      throw _gererErreur(e, 'Impossible de supprimer le produit');
    }
  }

  // ===============================================
  // 🔄 ACTIVER/DÉSACTIVER UN PRODUIT
  // ===============================================
  Future<void> toggleActif(String produitId, bool actif) async {
    try {
      await _client.from('produits').update({
        'actif': actif,
      }).eq('id', produitId);
    } catch (e) {
      throw _gererErreur(e, 'Impossible de changer le statut');
    }
  }

  // ===============================================
  // 📸 UPLOAD IMAGE PRODUIT
  // ===============================================
  Future<String?> uploadImageProduit(File fichier, String produitId) async {
    try {
      if (!estConnecte) return null;

      final extension = fichier.path.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final chemin = 'produits/$produitId/$timestamp.$extension';

      await _client.storage.from('produits').upload(
            chemin,
            fichier,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      return _client.storage.from('produits').getPublicUrl(chemin);
    } catch (e) {
      throw _gererErreur(e, 'Impossible d\'uploader l\'image');
    }
  }

  // ===============================================
  // 📸 AJOUTER UNE IMAGE AU PRODUIT
  // ===============================================
  Future<void> ajouterImage({
    required String produitId,
    required String url,
    required int ordre,
  }) async {
    try {
      await _client.from('produit_images').insert({
        'produit_id': produitId,
        'url': url,
        'ordre': ordre,
      });
    } catch (e) {
      throw _gererErreur(e, 'Impossible d\'ajouter l\'image');
    }
  }

  // ===============================================
  // 📸 LISTER LES IMAGES D'UN PRODUIT
  // ===============================================
  Future<List<ProduitImage>> listerImages(String produitId) async {
    try {
      final data = await _client.from('produit_images').select().eq('produit_id', produitId).order('ordre');

      return (data as List).map((e) => ProduitImage.fromMap(e)).toList();
    } catch (e) {
      throw _gererErreur(e, 'Impossible de charger les images');
    }
  }

  // ===============================================
  // 🗑️ SUPPRIMER UNE IMAGE
  // ===============================================
  Future<void> supprimerImage(String imageId) async {
    try {
      await _client.from('produit_images').delete().eq('id', imageId);
    } catch (e) {
      throw _gererErreur(e, 'Impossible de supprimer l\'image');
    }
  }

  // ===============================================
  // 📏 AJOUTER UNE TAILLE
  // ===============================================
  Future<void> ajouterTaille({
    required String produitId,
    required String valeur,
    required int stock,
  }) async {
    try {
      await _client.from('produit_tailles').insert({
        'produit_id': produitId,
        'valeur': valeur.trim(),
        'stock': stock,
      });
    } catch (e) {
      throw _gererErreur(e, 'Impossible d\'ajouter la taille');
    }
  }

  // ===============================================
  // 📏 LISTER LES TAILLES D'UN PRODUIT
  // ===============================================
  Future<List<ProduitTaille>> listerTailles(String produitId) async {
    try {
      final data = await _client.from('produit_tailles').select().eq('produit_id', produitId);

      return (data as List).map((e) => ProduitTaille.fromMap(e)).toList();
    } catch (e) {
      throw _gererErreur(e, 'Impossible de charger les tailles');
    }
  }

  // ===============================================
  // 🎨 AJOUTER UNE COULEUR
  // ===============================================
  Future<void> ajouterCouleur({
    required String produitId,
    required String nom,
    String? codeHex,
    required int stock,
  }) async {
    try {
      await _client.from('produit_couleurs').insert({
        'produit_id': produitId,
        'nom': nom.trim(),
        'code_hex': codeHex,
        'stock': stock,
      });
    } catch (e) {
      throw _gererErreur(e, 'Impossible d\'ajouter la couleur');
    }
  }

  // ===============================================
  // 🎨 LISTER LES COULEURS D'UN PRODUIT
  // ===============================================
  Future<List<ProduitCouleur>> listerCouleurs(String produitId) async {
    try {
      final data = await _client.from('produit_couleurs').select().eq('produit_id', produitId);

      return (data as List).map((e) => ProduitCouleur.fromMap(e)).toList();
    } catch (e) {
      throw _gererErreur(e, 'Impossible de charger les couleurs');
    }
  }

  // ===============================================
  // 👁️ INCRÉMENTER LE NOMBRE DE VUES
  // ===============================================
  Future<void> incrementerVues(String produitId) async {
    try {
      await _client.rpc('increment_vues', params: {'produit_id': produitId});
    } catch (e) {
      // Ignorer l'erreur silencieusement
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
  // 🚨 CREER PRODUITS COMPLET
  // ===============================================
  // ➕ Dans ServiceProduitSupabase
  Future<String> creerProduitComplet({
    required String vendeurId,
    required String categorieId,
    required String nom,
    String? description,
    required int prix,
    List<File> images = const [],
    required List<VarianteTemp> variantes,
    EtatProduit etatProduit = EtatProduit.neuf,
    bool livraisonDisponible = false,
    double? poids,
    String? marque,
  }) async {
    try {
      // 1. Créer produit principal
      final produitId = await creerProduit(
        vendeurId: vendeurId,
        categorieId: categorieId,
        nom: nom,
        description: description,
        prix: prix,
        etatProduit: etatProduit,
        livraisonDisponible: livraisonDisponible,
        poids: poids,
        marque: marque,
      );

      // 2. Images
      for (int i = 0; i < images.length; i++) {
        final url = await uploadImageProduit(images[i], produitId);
        if (url != null) {
          await ajouterImage(produitId: produitId, url: url, ordre: i);
        }
      }

      // 3. VARIANTS - Tailles uniques
      final taillesUniques = variantes.where((v) => v.taille.isNotEmpty).map((v) => v.taille).toSet();

      for (String taille in taillesUniques) {
        final stockTotal = variantes.where((v) => v.taille == taille).fold(0, (sum, v) => sum + v.stock);
        await ajouterTaille(
          produitId: produitId,
          valeur: taille,
          stock: stockTotal,
        );
      }

      // 4. VARIANTS - Couleurs uniques
      final couleursUniques = variantes.where((v) => v.couleur.isNotEmpty).map((v) => v.couleur).toSet();

      for (String couleur in couleursUniques) {
        final stockTotal = variantes.where((v) => v.couleur == couleur).fold(0, (sum, v) => sum + v.stock);
        await ajouterCouleur(
          produitId: produitId,
          nom: couleur,
          stock: stockTotal,
        );
      }

      // 5. VARIANTS - Combinaisons (produit_variantes)
      for (final variante in variantes) {
        if (variante.estComplet) {
          //Créer taille_id et couleur_id après insertion
          await _client.from('produit_variantes').insert({
            'produit_id': produitId,
            'taille_id': null, // À récupérer après insertion tailles
            'couleur_id': null, // À récupérer après insertion couleurs
            'stock': variante.stock,
            'prix_ajuste': variante.prixAjuste,
          });
        }
      }

      return produitId;
    } catch (e) {
      throw _gererErreur(e, 'Erreur création produit complet');
    }
  }

// ===============================================
// 🔍 FILTRES CLIENT-SIDE - 100% FONCTIONNEL
// ===============================================
  Future<List<Produit>> listerProduitsFiltres({
    String? recherche,
    String? categorie,
    String? taille,
    String? couleur,
    double? prixMin,
    double? prixMax,
    String? tri = 'popularite',
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      // 1. Charger produits (méthode existante)
      final produits = await listerProduitsPage(page: page, pageSize: pageSize * 2);

      // 2. Filtres simples (nom/prix)
      List<Produit> result = [];

      for (final produit in produits) {
        // 🔍 Recherche
        if (recherche != null && recherche.isNotEmpty) {
          if (!produit.nom.toLowerCase().contains(recherche.toLowerCase())) {
            continue;
          }
        }

        // 💰 Prix (✅ SANS LIMITE ARBITRAIRE)
        if (prixMin != null && prixMin > 0 && produit.prix < prixMin) {
          continue;
        }
        if (prixMax != null && prixMax > 0 && produit.prix > prixMax) {
          continue;
        }

        result.add(produit);
      }

      // 3. FILTRES TAILLES/COULEURS (✅ SANS SETTERS)
      if (taille != null || couleur != null) {
        final List<Produit> filtresAvances = [];

        for (final produit in result) {
          bool correspond = true;

          // 📏 Taille
          if (taille != null && taille.isNotEmpty) {
            final tailles = await listerTailles(produit.id);
            if (!tailles.any((t) => t.valeur.toLowerCase() == taille.toLowerCase())) {
              correspond = false;
            }
          }

          // 🎨 Couleur
          if (couleur != null && couleur.isNotEmpty && correspond) {
            final couleurs = await listerCouleurs(produit.id);
            if (!couleurs.any((c) => c.nom.toLowerCase() == couleur.toLowerCase())) {
              correspond = false;
            }
          }

          if (correspond) {
            filtresAvances.add(produit);
          }
        }

        result = filtresAvances;
      }

      // 4. Tri final
      switch (tri) {
        case 'prix_croissant':
          result.sort((a, b) => a.prix.compareTo(b.prix));
          break;
        case 'prix_decroissant':
          result.sort((a, b) => b.prix.compareTo(a.prix));
          break;
        case 'popularite':
          result.sort((a, b) => b.nombreVues.compareTo(a.nombreVues));
          break;
        case 'recent':
          result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }

      return result.take(pageSize).toList();
    } catch (e) {
      throw _gererErreur(e, 'Erreur filtres produits');
    }
  }

  // ===============================================
  // 🧹 NETTOYAGE
  // ===============================================
  void dispose() {
    // Cleanup si nécessaire
  }
}

// ===============================================
// 💰 LIMITES ADAPTÉES TOGO 2026
// ===============================================
class LimitesPrix {
  static const double maxMicro = 100000;
  static const double maxStandard = 5000000;
  static const double maxPro = 50000000;
  static const double maxIllimite = 999999999;

  static double limiter(double prix) => prix.clamp(0, maxPro);
  static bool estValide(double prix) => prix >= 0 && prix <= maxPro;
}
