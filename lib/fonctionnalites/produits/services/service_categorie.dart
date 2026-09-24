// ===============================================
// 📂 SERVICE CATÉGORIES
// ===============================================
// Gestion des catégories hiérarchiques depuis Supabase

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/categorie.dart';

class ServiceCategorie {
  static final ServiceCategorie _instance = ServiceCategorie._internal();
  factory ServiceCategorie() => _instance;
  ServiceCategorie._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // Récupérer les catégories principales (parent_id IS NULL)
  Future<List<Categorie>> listerCategoriesPrincipales() async {
    try {
      final data = await _client
          .from('categories')
          .select()
          .isFilter('parent_id', null)
          .eq('actif', true)
          .order('nom');

      return (data as List).map((e) => Categorie.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des catégories: $e');
    }
  }

  // Récupérer les sous-catégories d'une catégorie
  Future<List<Categorie>> listerSousCategories(String parentId) async {
    try {
      final data = await _client
          .from('categories')
          .select()
          .eq('parent_id', parentId)
          .eq('actif', true)
          .order('nom');

      return (data as List).map((e) => Categorie.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des sous-catégories: $e');
    }
  }

  // Récupérer une catégorie par ID
  Future<Categorie?> recupererCategorie(String id) async {
    try {
      final data =
          await _client.from('categories').select().eq('id', id).single();

      return Categorie.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // Récupérer le chemin complet (Catégorie > Sous-catégorie > ...)
  Future<String> recupererCheminComplet(String categorieId) async {
    final categorie = await recupererCategorie(categorieId);
    if (categorie == null) return '';

    String chemin = categorie.nom;

    if (categorie.parentId != null) {
      final parent = await recupererCategorie(categorie.parentId!);
      if (parent != null) {
        chemin = '${parent.nom} > $chemin';

        // Si le parent a aussi un parent
        if (parent.parentId != null) {
          final grandParent = await recupererCategorie(parent.parentId!);
          if (grandParent != null) {
            chemin = '${grandParent.nom} > $chemin';
          }
        }
      }
    }

    return chemin;
  }
}
