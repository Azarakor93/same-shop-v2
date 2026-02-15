// ===============================================
// 🎯 FILTRES STYLE FACEBOOK MARKETPLACE
// ===============================================
import 'package:flutter/material.dart';
import '../../models/categorie.dart';
import '../../services/service_categorie.dart';

class FiltresFacebookStyle extends StatefulWidget {
  final Function(Map<String, dynamic> filtres) onFiltresApplies;

  const FiltresFacebookStyle({
    super.key,
    required this.onFiltresApplies,
  });

  @override
  State<FiltresFacebookStyle> createState() => _FiltresFacebookStyleState();
}

class _FiltresFacebookStyleState extends State<FiltresFacebookStyle> {
  final ServiceCategorie _serviceCategorie = ServiceCategorie();

  // Filtres actifs
  Categorie? _categorieSelectionnee;
  String? _localisationSelectionnee;
  RangeValues _prixRange = const RangeValues(0, 1000000);
  String? _etatSelectionne;
  String _triSelectionne = 'recent';

  List<Categorie> _categories = [];
  bool _chargement = true;

  // Options de localisation (vous pouvez les charger depuis Supabase)
  final List<String> _localisations = [
    'Lomé',
    'Kara',
    'Sokodé',
    'Atakpamé',
    'Kpalimé',
    'Dapaong',
    'Tsévié',
    'Aného',
  ];

  final List<Map<String, String>> _etats = [
    {'id': 'neuf', 'nom': 'Neuf'},
    {'id': 'comme_neuf', 'nom': 'Comme neuf'},
    {'id': 'bon_etat', 'nom': 'Bon état'},
    {'id': 'usage', 'nom': 'Usagé'},
  ];

  final List<Map<String, String>> _tris = [
    {'id': 'recent', 'nom': 'Plus récents'},
    {'id': 'prix_croissant', 'nom': 'Prix croissant'},
    {'id': 'prix_decroissant', 'nom': 'Prix décroissant'},
    {'id': 'populaire', 'nom': 'Les plus vus'},
  ];

  @override
  void initState() {
    super.initState();
    _chargerCategories();
  }

  Future<void> _chargerCategories() async {
    setState(() => _chargement = true);
    final categories = await _serviceCategorie.recupererCategoriesAvecStats();
    setState(() {
      _categories = categories;
      _chargement = false;
    });
  }

  int _nombreFiltresActifs() {
    int count = 0;
    if (_categorieSelectionnee != null) count++;
    if (_localisationSelectionnee != null) count++;
    if (_prixRange.start > 0 || _prixRange.end < 1000000) count++;
    if (_etatSelectionne != null) count++;
    return count;
  }

  void _reinitialiserFiltres() {
    setState(() {
      _categorieSelectionnee = null;
      _localisationSelectionnee = null;
      _prixRange = const RangeValues(0, 1000000);
      _etatSelectionne = null;
      _triSelectionne = 'recent';
    });
  }

  void _appliquerFiltres() {
    widget.onFiltresApplies({
      'categorie': _categorieSelectionnee?.code,
      'localisation': _localisationSelectionnee,
      'prix_min': _prixRange.start,
      'prix_max': _prixRange.end,
      'etat': _etatSelectionne,
      'tri': _triSelectionne,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // HEADER
          _buildHeader(theme),

          // CHIPS HORIZONTALES (Style Facebook)
          _buildChipsHorizontales(theme),

          const Divider(height: 1),

          // CONTENU FILTRES
          Expanded(
            child: _chargement
                ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionCategories(theme),
                        const SizedBox(height: 24),
                        _buildSectionLocalisation(theme),
                        const SizedBox(height: 24),
                        _buildSectionPrix(theme),
                        const SizedBox(height: 24),
                        _buildSectionEtat(theme),
                        const SizedBox(height: 24),
                        _buildSectionTri(theme),
                        const SizedBox(height: 80), // Espace pour le bouton
                      ],
                    ),
                  ),
          ),

          // BOUTON APPLIQUER
          _buildBoutonAppliquer(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final nombreActifs = _nombreFiltresActifs();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Filtres',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (nombreActifs > 0)
            TextButton(
              onPressed: _reinitialiserFiltres,
              child: const Text('Réinitialiser'),
            ),
        ],
      ),
    );
  }

  Widget _buildChipsHorizontales(ThemeData theme) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChipFiltre(
            theme,
            icone: Icons.category_outlined,
            label: _categorieSelectionnee?.nom ?? 'Catégorie',
            actif: _categorieSelectionnee != null,
            onTap: () => _scrollToSection(0),
          ),
          const SizedBox(width: 8),
          _buildChipFiltre(
            theme,
            icone: Icons.location_on_outlined,
            label: _localisationSelectionnee ?? 'Localisation',
            actif: _localisationSelectionnee != null,
            onTap: () => _scrollToSection(1),
          ),
          const SizedBox(width: 8),
          _buildChipFiltre(
            theme,
            icone: Icons.attach_money,
            label: 'Prix',
            actif: _prixRange.start > 0 || _prixRange.end < 1000000,
            onTap: () => _scrollToSection(2),
          ),
          const SizedBox(width: 8),
          _buildChipFiltre(
            theme,
            icone: Icons.verified_outlined,
            label: _etatSelectionne != null
                ? _etats.firstWhere((e) => e['id'] == _etatSelectionne)['nom']!
                : 'État',
            actif: _etatSelectionne != null,
            onTap: () => _scrollToSection(3),
          ),
          const SizedBox(width: 8),
          _buildChipFiltre(
            theme,
            icone: Icons.sort,
            label: 'Trier',
            actif: _triSelectionne != 'recent',
            onTap: () => _scrollToSection(4),
          ),
        ],
      ),
    );
  }

  Widget _buildChipFiltre(
    ThemeData theme, {
    required IconData icone,
    required String label,
    required bool actif,
    required VoidCallback onTap,
  }) {
    return Material(
      color: actif
          ? theme.primaryColor
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icone,
                size: 18,
                color: actif ? Colors.white : theme.textTheme.bodyMedium?.color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: actif ? Colors.white : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToSection(int index) {
    // TODO: Implémenter scroll automatique vers section
  }

  Widget _buildSectionCategories(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((categorie) {
            final estSelectionne = _categorieSelectionnee?.code == categorie.code;

            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIconeCategorie(categorie.icone),
                    size: 16,
                    color: estSelectionne ? Colors.white : theme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(categorie.nom),
                ],
              ),
              selected: estSelectionne,
              onSelected: (selected) {
                setState(() {
                  _categorieSelectionnee = selected ? categorie : null;
                });
              },
              selectedColor: theme.primaryColor,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: estSelectionne ? Colors.white : theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionLocalisation(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Localisation',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _localisations.map((ville) {
            final estSelectionne = _localisationSelectionnee == ville;

            return ChoiceChip(
              label: Text(ville),
              selected: estSelectionne,
              onSelected: (selected) {
                setState(() {
                  _localisationSelectionnee = selected ? ville : null;
                });
              },
              selectedColor: theme.primaryColor,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: estSelectionne ? Colors.white : theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionPrix(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prix',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_prixRange.start.toStringAsFixed(0)} FCFA',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_prixRange.end.toStringAsFixed(0)} FCFA',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: _prixRange,
          min: 0,
          max: 1000000,
          divisions: 100,
          activeColor: theme.primaryColor,
          inactiveColor: theme.primaryColor.withValues(alpha: 0.2),
          onChanged: (RangeValues values) {
            setState(() {
              _prixRange = values;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSectionEtat(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'État du produit',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _etats.map((etat) {
            final estSelectionne = _etatSelectionne == etat['id'];

            return ChoiceChip(
              label: Text(etat['nom']!),
              selected: estSelectionne,
              onSelected: (selected) {
                setState(() {
                  _etatSelectionne = selected ? etat['id'] : null;
                });
              },
              selectedColor: theme.primaryColor,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: estSelectionne ? Colors.white : theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionTri(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trier par',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._tris.map((tri) {
          final estSelectionne = _triSelectionne == tri['id'];

          return RadioListTile<String>(
            value: tri['id']!,
            groupValue: _triSelectionne,
            onChanged: (value) {
              setState(() {
                _triSelectionne = value!;
              });
            },
            title: Text(tri['nom']!),
            activeColor: theme.primaryColor,
            contentPadding: EdgeInsets.zero,
            dense: true,
          );
        }),
      ],
    );
  }

  Widget _buildBoutonAppliquer(ThemeData theme) {
    final nombreActifs = _nombreFiltresActifs();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _appliquerFiltres,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              nombreActifs > 0
                  ? 'Afficher les résultats ($nombreActifs filtres)'
                  : 'Afficher tous les produits',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconeCategorie(String? nomIcone) {
    if (nomIcone == null) return Icons.category;

    final icones = {
      'phone': Icons.phone_android,
      'laptop': Icons.laptop,
      'tshirt': Icons.checkroom,
      'home': Icons.home,
      'car': Icons.directions_car,
      'book': Icons.menu_book,
      'sports': Icons.sports_soccer,
      'toys': Icons.toys,
      'furniture': Icons.chair,
      'electronics': Icons.devices,
    };

    return icones[nomIcone] ?? Icons.category;
  }
}
