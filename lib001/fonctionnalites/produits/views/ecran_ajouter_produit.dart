// ===============================================
// ➕ ÉCRAN AJOUTER PRODUIT - VERSION AVEC THÈME ADAPTATIF
// ===============================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../vendeur/models/boutique.dart';
import '../models/produit.dart';
import '../services/service_produit_supabase.dart';
import '../models/variante_temp.dart';
import '../utils/utils_icones.dart';

class EcranAjouterProduit extends StatefulWidget {
  final Boutique boutique;

  const EcranAjouterProduit({
    super.key,
    required this.boutique,
  });

  @override
  State<EcranAjouterProduit> createState() => _EcranAjouterProduitState();
}

class _EcranAjouterProduitState extends State<EcranAjouterProduit> {
  final _formKey = GlobalKey<FormState>();
  final _service = ServiceProduitSupabase();
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  // Controllers
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();
  final _stockController = TextEditingController();

  // État
  bool _chargement = false;
  EtatProduit _etatProduit = EtatProduit.neuf;
  bool _livraisonDisponible = true;
  final List<File> _images = [];

  // Catégories hiérarchiques
  List<Map<String, dynamic>> _categoriesNiveau1 = [];
  List<Map<String, dynamic>> _categoriesNiveau2 = [];
  List<Map<String, dynamic>> _categoriesNiveau3 = [];

  String? _categorieNiveau1Id;
  String? _categorieNiveau2Id;
  String? _categorieNiveau3Id;

  String _categorieNiveau1Nom = '';
  String _categorieNiveau2Nom = '';
  String _categorieNiveau3Nom = '';

  bool _chargementCategories = true;

  // VARIANTS
  bool _hasVariants = false;
  final List<VarianteTemp> _variantesTemp = [];
  List<String> taillesDisponibles = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];

  @override
  void initState() {
    super.initState();
    _chargerCategoriesPrincipales();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // VARIANTS - MÉTHODES
  void _toggleVariants() {
    setState(() {
      _hasVariants = !_hasVariants;
      if (!_hasVariants) _variantesTemp.clear();
    });
  }

  void _ajouterVariante() {
    setState(() {
      _variantesTemp.add(VarianteTemp(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      ));
    });
  }

  void _supprimerVariante(int index) {
    setState(() => _variantesTemp.removeAt(index));
  }

  void _updateVariante(int index, String field, dynamic value) {
    setState(() {
      final variante = _variantesTemp[index];
      switch (field) {
        case 'taille':
          _variantesTemp[index] = variante.copyWith(taille: value);
          break;
        case 'couleur':
          _variantesTemp[index] = variante.copyWith(couleur: value);
          break;
        case 'stock':
          _variantesTemp[index] = variante.copyWith(stock: value ?? 0);
          break;
      }
    });
  }

  // CHARGER CATÉGORIES
  Future<void> _chargerCategoriesPrincipales() async {
    setState(() => _chargementCategories = true);
    try {
      final data = await _supabase.from('categories').select('id, code, nom, icone').isFilter('parent_id', null).eq('actif', true).order('nom');

      final sortedData = List<Map<String, dynamic>>.from(data)..sort((a, b) => compareFrancais(a['nom'], b['nom']));

      setState(() {
        _categoriesNiveau1 = sortedData;
        _chargementCategories = false;
      });
    } catch (e) {
      setState(() => _chargementCategories = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur catégories: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _chargerSousCategories(String parentId, String parentNom) async {
    try {
      final data = await _supabase.from('categories').select('id, code, nom, icone').eq('parent_id', parentId).eq('actif', true).order('nom');

      final sortedData = List<Map<String, dynamic>>.from(data)..sort((a, b) => compareFrancais(a['nom'], b['nom']));

      setState(() {
        _categorieNiveau1Id = parentId;
        _categorieNiveau1Nom = parentNom;
        _categoriesNiveau2 = sortedData;
        _categoriesNiveau3 = [];

        if (sortedData.isEmpty) {
          _categorieNiveau3Id = parentId;
          _categorieNiveau3Nom = parentNom;
          _categorieNiveau2Id = null;
          _categorieNiveau2Nom = '';
        } else {
          _categorieNiveau2Id = null;
          _categorieNiveau3Id = null;
          _categorieNiveau2Nom = '';
          _categorieNiveau3Nom = '';
        }
      });
    } catch (e) {
      print('Erreur: $e');
    }
  }

  Future<void> _chargerSousSousCategories(String parentId, String parentNom) async {
    try {
      final data = await _supabase.from('categories').select('id, code, nom, icone').eq('parent_id', parentId).eq('actif', true).order('nom');

      final sortedData = List<Map<String, dynamic>>.from(data)..sort((a, b) => compareFrancais(a['nom'], b['nom']));

      setState(() {
        _categorieNiveau2Id = parentId;
        _categorieNiveau2Nom = parentNom;
        _categoriesNiveau3 = sortedData;
        _categorieNiveau3Id = null;
        _categorieNiveau3Nom = '';
      });

      if (data.isEmpty) {
        setState(() {
          _categorieNiveau3Id = parentId;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  void _selectionnerCategoriefinale(String categorieId, String nom) {
    setState(() {
      _categorieNiveau3Id = categorieId;
      _categorieNiveau3Nom = nom;
    });
  }

  // GESTION IMAGES
  Future<void> _selectionnerImage() async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images')),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _images.add(File(image.path));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la sélection')),
      );
    }
  }

  void _supprimerImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  // CRÉER PRODUIT
  Future<void> _creerProduit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins une image')),
      );
      return;
    }

    if (_categorieNiveau3Id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez une catégorie complète')),
      );
      return;
    }

    if (_hasVariants && _variantesTemp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins une variante')),
      );
      return;
    }

    setState(() => _chargement = true);

    try {
      final produitId = await _service.creerProduit(
        vendeurId: widget.boutique.id,
        categorieId: _categorieNiveau3Id!,
        nom: _nomController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        prix: int.parse(_prixController.text.replaceAll(' ', '')),
        stockGlobal: !_hasVariants && _stockController.text.isNotEmpty ? int.parse(_stockController.text) : null,
        etatProduit: _etatProduit,
        livraisonDisponible: _livraisonDisponible,
      );

      for (int i = 0; i < _images.length; i++) {
        final url = await _service.uploadImageProduit(_images[i], produitId);
        if (url != null) {
          await _service.ajouterImage(
            produitId: produitId,
            url: url,
            ordre: i,
          );
        }
      }

      if (_hasVariants && _variantesTemp.isNotEmpty) {
        final taillesUniques = _variantesTemp.where((v) => v.taille.isNotEmpty).map((v) => v.taille).toSet();

        for (String taille in taillesUniques) {
          final stockTotal = _variantesTemp.where((v) => v.taille == taille).fold(0, (sum, v) => sum + v.stock);
          await _service.ajouterTaille(
            produitId: produitId,
            valeur: taille,
            stock: stockTotal,
          );
        }

        final couleursUniques = _variantesTemp.where((v) => v.couleur.isNotEmpty).map((v) => v.couleur).toSet();

        for (String couleur in couleursUniques) {
          final stockTotal = _variantesTemp.where((v) => v.couleur == couleur).fold(0, (sum, v) => sum + v.stock);
          await _service.ajouterCouleur(
            produitId: produitId,
            nom: couleur,
            stock: stockTotal,
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Produit ${_nomController.text} créé avec succès!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un produit'),
        centerTitle: true,
      ),
      body: _chargementCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // PHOTOS
                    const Text(
                      'Photos du produit (max 5)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._images.asMap().entries.map((entry) {
                            final index = entry.key;
                            final image = entry.value;
                            return _buildImagePreview(image, index);
                          }),
                          if (_images.length < 5) _buildAjouterImageButton(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // CATÉGORIE
                    _categoriesWidget(),
                    const SizedBox(height: 7),

                    // FORMULAIRE
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du produit *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().length < 3 ? 'Minimum 3 caractères' : null,
                    ),
                    const SizedBox(height: 7),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 7),

                    TextFormField(
                      controller: _prixController,
                      decoration: const InputDecoration(
                        labelText: 'Prix (FCFA) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => v == null || v.isEmpty ? 'Prix obligatoire' : null,
                    ),
                    const SizedBox(height: 7),

                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 7),

                    DropdownButtonFormField<EtatProduit>(
                      initialValue: _etatProduit,
                      decoration: const InputDecoration(
                        labelText: 'État',
                        border: OutlineInputBorder(),
                      ),
                      items: EtatProduit.values.map((etat) {
                        return DropdownMenuItem(
                          value: etat,
                          child: Text(etat.label),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _etatProduit = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 7),

                    SwitchListTile(
                      title: const Text('Livraison disponible'),
                      value: _livraisonDisponible,
                      onChanged: (val) {
                        setState(() {
                          _livraisonDisponible = val;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // ✅ VARIANTS AVEC THÈME ADAPTATIF
                    _buildVariantsCard(),

                    const SizedBox(height: 7),

                    // BOUTON CRÉER
                    ElevatedButton(
                      onPressed: _chargement ? null : _creerProduit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _chargement
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('✅ Créer le produit'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ✅ WIDGET VARIANTS AVEC THÈME ADAPTATIF
  Widget _buildVariantsCard() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      // ✅ COULEUR ADAPTATIVE AU THÈME
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text(
                'Variantes',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Tailles/Couleurs',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              value: _hasVariants,
              onChanged: (_) => _toggleVariants(),
              dense: true,
              controlAffinity: ListTileControlAffinity.trailing,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              visualDensity: VisualDensity.compact,
            ),
            if (_hasVariants) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Variantes produit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: ElevatedButton.icon(
                      onPressed: _ajouterVariante,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Ajouter', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._variantesTemp.asMap().entries.map((entry) {
                final index = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      // ✅ COULEUR ADAPTATIVE AU THÈME
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _variantesTemp[index].taille.isEmpty ? null : _variantesTemp[index].taille,
                            decoration: const InputDecoration(
                              labelText: 'Taille',
                              labelStyle: TextStyle(fontSize: 11),
                              contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                              border: OutlineInputBorder(),
                            ),
                            isDense: true,
                            items: taillesDisponibles
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t, style: const TextStyle(fontSize: 12)),
                                    ))
                                .toList(),
                            onChanged: (v) => _updateVariante(index, 'taille', v),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<CouleurOption>(
                            initialValue: _getCouleurSelectionnee(index),
                            isDense: true,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Couleur',
                              labelStyle: TextStyle(fontSize: 11),
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              border: OutlineInputBorder(),
                            ),
                            selectedItemBuilder: (context) => couleursProduits.map((couleur) {
                              return Container(
                                height: 28,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: couleur.couleur,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        couleur.nom,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            items: couleursProduits.map((couleur) {
                              return DropdownMenuItem<CouleurOption>(
                                value: couleur,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: couleur.couleur,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          couleur.nom,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (c) => c != null ? _updateVariante(index, 'couleur', c.nom) : null,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: _variantesTemp[index].stock.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Stock',
                              labelStyle: TextStyle(fontSize: 11),
                              contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(fontSize: 13),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (v) => _updateVariante(index, 'stock', int.tryParse(v)),
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          padding: const EdgeInsets.all(1),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => _supprimerVariante(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _categoriesWidget() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 280,
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildCategoriesScrollable(),
            ),
            if (_categorieNiveau3Id != null) ...[
              const Divider(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatCategorieComplete(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesScrollable() {
    if (_categoriesNiveau1.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categoriesNiveau3.isNotEmpty) {
      return _buildNiveauScrollable(
        titre: 'Précision',
        categories: _categoriesNiveau3,
        selectedId: _categorieNiveau3Id,
        onTap: (cat) => _selectionnerCategoriefinale(cat['id'], cat['nom']),
        backAction: () => _retourNiveau2(),
      );
    }

    if (_categoriesNiveau2.isNotEmpty) {
      return _buildNiveauScrollable(
        titre: 'Sous-catégories',
        categories: _categoriesNiveau2,
        selectedId: _categorieNiveau2Id,
        onTap: (cat) => _chargerSousSousCategories(cat['id'], cat['nom']),
        backAction: () => _retourNiveau1(),
      );
    }

    return _buildNiveauScrollable(
      titre: 'Catégorie principale',
      categories: _categoriesNiveau1,
      selectedId: _categorieNiveau1Id,
      onTap: (cat) => _chargerSousCategories(cat['id'], cat['nom']),
    );
  }

  Widget _buildNiveauScrollable({
    required String titre,
    required List<Map<String, dynamic>> categories,
    required String? selectedId,
    required Function(Map<String, dynamic>) onTap,
    VoidCallback? backAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (backAction != null) ...[
          GestureDetector(
            onTap: backAction,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios,
                    size: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Retour',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            titre,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.1,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final categorie = categories[index];
              final isSelected = selectedId == categorie['id'];

              return Card(
                elevation: isSelected ? 4 : 1,
                shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onTap(categorie),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              getIconeEmoji(categorie['icone'] ?? ''),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            categorie['nom'] ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _retourNiveau1() {
    setState(() {
      _categoriesNiveau2.clear();
      _categoriesNiveau3.clear();
      _categorieNiveau2Id = null;
      _categorieNiveau3Id = null;
      _categorieNiveau2Nom = '';
      _categorieNiveau3Nom = '';
    });
  }

  void _retourNiveau2() {
    setState(() {
      _categoriesNiveau3.clear();
      _categorieNiveau3Id = null;
      _categorieNiveau3Nom = '';
    });
  }

  String _formatCategorieComplete() {
    List<String> noms = [];
    if (_categorieNiveau1Nom.isNotEmpty) noms.add(_categorieNiveau1Nom);
    if (_categorieNiveau2Nom.isNotEmpty) noms.add(_categorieNiveau2Nom);
    if (_categorieNiveau3Nom.isNotEmpty) noms.add(_categorieNiveau3Nom);
    return noms.join(' > ');
  }

  CouleurOption? _getCouleurSelectionnee(int index) {
    if (_variantesTemp[index].couleur.isEmpty) return null;
    try {
      return couleursProduits.firstWhere((c) => c.nom == _variantesTemp[index].couleur);
    } catch (e) {
      return null;
    }
  }

  Widget _buildImagePreview(File image, int index) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: FileImage(image),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _supprimerImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAjouterImageButton() {
    return GestureDetector(
      onTap: _selectionnerImage,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 32, color: Colors.blue),
            SizedBox(height: 4),
            Text('Ajouter', style: TextStyle(color: Colors.blue, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
