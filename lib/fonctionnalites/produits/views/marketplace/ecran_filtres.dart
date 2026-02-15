// ===============================================
// 🔧 ECRAN FILTRES MARKETPLACE - SUPABASE 2026 ✅
// ===============================================
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/utils_icones.dart';
import '../../services/service_produit_supabase.dart' show LimitesPrix;

class FiltresResult {
  final String? categorieCode;
  final String? pays;
  final String? ville;
  final String? quartier;
  final String? taille;
  final String? couleur;
  final double prixMin;
  final double prixMax;
  final String tri;

  FiltresResult({
    this.categorieCode,
    this.pays,
    this.ville,
    this.quartier,
    this.taille,
    this.couleur,
    required this.prixMin,
    required this.prixMax,
    required this.tri,
  });
}

typedef FiltresCallback = void Function(FiltresResult filtres);

class EcranFiltres extends StatefulWidget {
  final FiltresCallback onFiltresApplies;
  const EcranFiltres({super.key, required this.onFiltresApplies});

  @override
  State<EcranFiltres> createState() => _EcranFiltresState();
}

class _EcranFiltresState extends State<EcranFiltres> {
  String? _categorieCode;
  String? _pays;
  String? _ville;
  String? _quartier;
  String? _taille;
  String? _couleur;
  String _tri = 'popularite';
  double _prixMin = 0;
  double _prixMax = LimitesPrix.maxPro;

  List<Map<String, dynamic>> categories = [];
  List<String> paysUniques = [];
  List<String> villesUniques = [];
  List<String> quartiersUniques = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerDonneesReelles();
  }

  Future<void> _chargerDonneesReelles() async {
    final supabase = Supabase.instance.client;

    try {
      // 🔥 Catégories réelles
      final categoriesRes = await supabase.from('categories').select('code, nom, icone').eq('actif', true).order('nom');

      // ✅ CORRECTION SUPABASE : ne pas filtrer pays NULL
      final vendeursRes = await supabase.from('vendeurs').select('pays, ville, quartier').eq('est_suspendu', false); // ✅ CORRECTION 1

      if (mounted) {
        setState(() {
          categories = List<Map<String, dynamic>>.from(categoriesRes);

          paysUniques = vendeursRes.map((v) => v['pays']?.toString() ?? '').where((p) => p.isNotEmpty && p != 'null').toSet().toList()..sort();

          villesUniques = vendeursRes.map((v) => v['ville']?.toString() ?? '').where((v) => v.isNotEmpty && v != 'null').toSet().toList(); // ✅ CORRECTION 4 : supprimé ..toList() inutile

          quartiersUniques = vendeursRes.map((v) => v['quartier']?.toString() ?? '').where((q) => q.isNotEmpty && q != 'null').toSet().toList()..sort();

          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.93,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // 📱 Poignée ✅ VOTRE SYNTAXE
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.5), // ✅ VOTRE withValues
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 🎯 Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: theme.primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    _chargement ? 'Chargement...' : 'Filtres Marketplace',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _chargement ? null : _appliquerFiltres,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Appliquer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _chargement
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Chargement données réelles...'),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (categories.isNotEmpty)
                            _sectionFiltres(
                              title: 'Catégories (${categories.length})',
                              icon: Icons.category,
                              chips: ['Tous', ...categories.map((c) => c['nom'] ?? c['code'] ?? '').where((n) => n.isNotEmpty)], // ✅ CORRECTION 4
                              selected: _getNomCategorie(),
                              onChanged: _onCategorieChanged,
                            ),
                          if (paysUniques.isNotEmpty)
                            _sectionFiltres(
                              title: 'Pays (${paysUniques.length})',
                              icon: Icons.public,
                              chips: ['Tous', ...paysUniques],
                              selected: _pays,
                              onChanged: (v) => setState(() => _pays = v == 'Tous' ? null : v),
                            ),
                          if (villesUniques.isNotEmpty)
                            _sectionFiltres(
                              title: 'Villes (${villesUniques.length})',
                              icon: Icons.location_city,
                              chips: ['Toutes', ...villesUniques],
                              selected: _ville,
                              onChanged: (v) => setState(() => _ville = v == 'Toutes' ? null : v),
                            ),
                          if (quartiersUniques.isNotEmpty)
                            _sectionFiltres(
                              title: 'Quartiers (${quartiersUniques.length})',
                              icon: Icons.location_on,
                              chips: ['Tous', ...quartiersUniques.take(15)],
                              selected: _quartier,
                              onChanged: (v) => setState(() => _quartier = v == 'Tous' ? null : v),
                            ),
                          _sectionFiltresTailles(),
                          _sectionCouleurs(),
                          _sectionPrix(),
                          _sectionTri(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getNomCategorie() {
    if (_categorieCode == null) return null;
    try {
      return categories.firstWhere((c) => c['code'] == _categorieCode)['nom'];
    } catch (e) {
      return null;
    }
  }

  void _onCategorieChanged(String? nom) {
    if (nom == 'Tous') {
      setState(() => _categorieCode = null);
    } else {
      try {
        final cat = categories.firstWhere((c) => (c['nom'] ?? c['code']) == nom);
        setState(() => _categorieCode = cat['code']);
      } catch (e) {
        ///----------------------
      }
    }
  }

  Widget _sectionFiltres({
    required String title,
    required IconData icon,
    required List<String> chips,
    required String? selected,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Row(
            children: [
              Icon(icon, color: theme.primaryColor),
              const SizedBox(width: 12),
              Text(title, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: chips
              .map((chip) => FilterChip(
                    label: Text(chip),
                    selected: selected == chip,
                    onSelected: (_) => onChanged(chip),
                    selectedColor: theme.primaryColor.withValues(alpha: 0.12), // ✅ VOTRE SYNTAXE
                    checkmarkColor: theme.primaryColor,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _sectionFiltresTailles() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.straighten, color: theme.primaryColor),
              const SizedBox(width: 12),
              Text('Tailles', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: taillesProduits
              .map((taille) => FilterChip(
                    label: Text(taille.tailles),
                    selected: _taille == taille.tailles,
                    onSelected: (selected) => setState(() {
                      _taille = selected ? taille.tailles : null;
                    }),
                    selectedColor: theme.primaryColor.withValues(alpha: 0.12), // ✅ VOTRE SYNTAXE
                    checkmarkColor: theme.primaryColor,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _sectionCouleurs() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.palette, color: theme.primaryColor),
              const SizedBox(width: 12),
              Text('Couleurs', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: couleursProduits
              .take(12)
              .map((couleur) => FilterChip(
                    avatar: CircleAvatar(
                      radius: 14,
                      backgroundColor: couleur.couleur,
                    ),
                    label: Text(couleur.nom, style: const TextStyle(fontSize: 12)),
                    selected: _couleur == couleur.nom,
                    onSelected: (selected) => setState(() {
                      _couleur = selected ? couleur.nom : null;
                    }),
                    selectedColor: theme.primaryColor.withValues(alpha: 0.12), // ✅ VOTRE SYNTAXE
                    checkmarkColor: theme.primaryColor,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _sectionPrix() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 16),
          child: Row(
            children: [
              Icon(Icons.attach_money, color: theme.primaryColor),
              const SizedBox(width: 12),
              Text('Prix', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => _prixMin = double.tryParse(v) ?? 0,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Min FCFA',
                  prefixIcon: const Icon(Icons.arrow_downward, color: Colors.green),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.cardColor.withValues(alpha: 0.3), // ✅ VOTRE SYNTAXE
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                onChanged: (v) => _prixMax = double.tryParse(v) ?? LimitesPrix.maxPro,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max FCFA',
                  prefixIcon: const Icon(Icons.arrow_upward, color: Colors.red),
                  suffixText: 'FCFA',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.cardColor.withValues(alpha: 0.3), // ✅ VOTRE SYNTAXE
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTri() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.sort, color: theme.primaryColor),
              const SizedBox(width: 12),
              Text('Trier par', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilterChip(
              label: const Text('Popularité'),
              selected: _tri == 'popularite',
              onSelected: (_) => setState(() => _tri = 'popularite'),
              selectedColor: theme.primaryColor.withValues(alpha: 0.12), // ✅ VOTRE SYNTAXE
              checkmarkColor: theme.primaryColor,
            ),
            FilterChip(
              label: const Text('Prix croissant'),
              selected: _tri == 'prix_croissant',
              onSelected: (_) => setState(() => _tri = 'prix_croissant'),
              selectedColor: theme.primaryColor.withValues(alpha: 0.12),
              checkmarkColor: theme.primaryColor,
            ),
            FilterChip(
              label: const Text('Prix décroissant'),
              selected: _tri == 'prix_decroissant',
              onSelected: (_) => setState(() => _tri = 'prix_decroissant'),
              selectedColor: theme.primaryColor.withValues(alpha: 0.12),
              checkmarkColor: theme.primaryColor,
            ),
          ],
        ),
      ],
    );
  }

  void _appliquerFiltres() {
    widget.onFiltresApplies(FiltresResult(
      categorieCode: _categorieCode,
      pays: _pays,
      ville: _ville,
      quartier: _quartier,
      taille: _taille,
      couleur: _couleur,
      prixMin: _prixMin,
      prixMax: _prixMax,
      tri: _tri,
    ));
    Navigator.pop(context);
  }
}
