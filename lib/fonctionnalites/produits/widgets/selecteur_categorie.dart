// ===============================================
// 📂 SÉLECTEUR DE CATÉGORIE HIÉRARCHIQUE
// ===============================================
// Widget pour sélectionner une catégorie à 3 niveaux

import 'package:flutter/material.dart';
import '../models/categorie.dart';
import '../services/service_categorie.dart';

class SelecteurCategorie extends StatefulWidget {
  final String? categorieSelectionneeId;
  final Function(String categorieId, String cheminComplet) onCategorieSelectionnee;

  const SelecteurCategorie({
    super.key,
    this.categorieSelectionneeId,
    required this.onCategorieSelectionnee,
  });

  @override
  State<SelecteurCategorie> createState() => _SelecteurCategorieState();
}

class _SelecteurCategorieState extends State<SelecteurCategorie> {
  final _service = ServiceCategorie();
  
  Categorie? _categorieNiveau1; // Principale
  Categorie? _categorieNiveau2; // Sous-catégorie
  Categorie? _categorieNiveau3; // Sous-sous-catégorie
  
  List<Categorie> _categoriesNiveau1 = [];
  List<Categorie> _categoriesNiveau2 = [];
  List<Categorie> _categoriesNiveau3 = [];
  
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerCategoriesPrincipales();
  }

  Future<void> _chargerCategoriesPrincipales() async {
    setState(() => _chargement = true);
    try {
      final categories = await _service.listerCategoriesPrincipales();
      setState(() {
        _categoriesNiveau1 = categories;
        _chargement = false;
      });
    } catch (e) {
      setState(() => _chargement = false);
    }
  }

  Future<void> _chargerSousCategories(Categorie categorie, int niveau) async {
    try {
      final sousCategories = await _service.listerSousCategories(categorie.id);
      
      if (niveau == 1) {
        setState(() {
          _categorieNiveau1 = categorie;
          _categoriesNiveau2 = sousCategories;
          _categorieNiveau2 = null;
          _categoriesNiveau3 = [];
          _categorieNiveau3 = null;
        });
      } else if (niveau == 2) {
        setState(() {
          _categorieNiveau2 = categorie;
          _categoriesNiveau3 = sousCategories;
          _categorieNiveau3 = null;
        });
      }

      // Si pas de sous-catégories, c'est la catégorie finale
      if (sousCategories.isEmpty) {
        _selectionnerCategorie(categorie);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  void _selectionnerCategorie(Categorie categorie) async {
    final chemin = await _service.recupererCheminComplet(categorie.id);
    widget.onCategorieSelectionnee(categorie.id, chemin);
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Niveau 1 : Catégories principales
        _buildNiveauCategories(
          'Catégorie',
          _categoriesNiveau1,
          _categorieNiveau1,
          (cat) => _chargerSousCategories(cat, 1),
        ),

        if (_categoriesNiveau2.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildNiveauCategories(
            'Sous-catégorie',
            _categoriesNiveau2,
            _categorieNiveau2,
            (cat) => _chargerSousCategories(cat, 2),
          ),
        ],

        if (_categoriesNiveau3.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildNiveauCategories(
            'Précision',
            _categoriesNiveau3,
            _categorieNiveau3,
            (cat) => _selectionnerCategorie(cat),
          ),
        ],
      ],
    );
  }

  Widget _buildNiveauCategories(
    String titre,
    List<Categorie> categories,
    Categorie? categorieSelectionnee,
    Function(Categorie) onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titre,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((categorie) {
            final estSelectionnee = categorieSelectionnee?.id == categorie.id;
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getMaterialIcon(categorie.icone),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(categorie.nom),
                ],
              ),
              selected: estSelectionnee,
              onSelected: (_) => onTap(categorie),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Convertir le code icône en emoji/icône Material
  String _getMaterialIcon(String iconeCode) {
    final Map<String, String> icones = {
      'palette': '🎨',
      'music_note': '🎵',
      'menu_book': '📚',
      'brush': '🖌️',
      'checkroom': '👔',
      'handmade': '✋',
      'piano': '🎹',
      'drum': '🥁',
      'headphones': '🎧',
      'smartphone': '📱',
      'computer': '💻',
      'tv': '📺',
      'home': '🏠',
      'sports': '⚽',
      'shopping_bag': '🛍️',
      'fastfood': '🍔',
      'local_hospital': '🏥',
      'pets': '🐕',
      'child_care': '👶',
      'auto': '🚗',
    };
    return icones[iconeCode] ?? '📁';
  }
}
