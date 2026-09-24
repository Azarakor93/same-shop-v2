// ===============================================
// 📱 ÉCRAN DÉTAILS PRODUIT - VERSION COMPACTE
// ===============================================

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/produit.dart';
import '../services/service_produit_supabase.dart';
import '../utils/utils_icones.dart';
import 'ecran_modifier_produit.dart';
import '../../vendeur/models/boutique.dart';

class EcranDetailsProduit extends StatefulWidget {
  final Produit produit;
  final Boutique boutique;

  const EcranDetailsProduit({
    super.key,
    required this.produit,
    required this.boutique,
  });

  @override
  State<EcranDetailsProduit> createState() => _EcranDetailsProduitState();
}

class _EcranDetailsProduitState extends State<EcranDetailsProduit> with SingleTickerProviderStateMixin {
  final _service = ServiceProduitSupabase();
  final PageController _pageController = PageController();

  late TabController _tabController;
  int _currentImageIndex = 0;
  String? _couleurSelectionnee;
  String? _tailleSelectionnee;

  List<ProduitImage> _images = [];
  List<ProduitCouleur> _couleurs = [];
  List<ProduitTaille> _tailles = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chargerDonnees();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    try {
      final images = await _service.listerImages(widget.produit.id);
      final couleurs = await _service.listerCouleurs(widget.produit.id);
      final tailles = await _service.listerTailles(widget.produit.id);
      if (mounted) {
        setState(() {
          _images = images;
          _couleurs = couleurs;
          _tailles = tailles;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  String _dureeDepuisMiseEnLigne() {
    final diff = DateTime.now().difference(widget.produit.createdAt);
    if (diff.inDays >= 365) return 'Il y a ${(diff.inDays / 365).floor()}an(s)';
    if (diff.inDays >= 30) return 'Il y a ${(diff.inDays / 30).floor()}mois';
    if (diff.inDays >= 1) return 'Il y a ${diff.inDays}j';
    if (diff.inHours >= 1) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inMinutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1419) : const Color(0xFFF4F6FA),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(slivers: [
              _buildAppBar(theme, isDark),
              _buildContent(theme, isDark),
            ]),
      bottomNavigationBar: _buildBottomBar(theme, isDark),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _afficherBoostSheet(theme, isDark),
        backgroundColor: Colors.deepOrange,
        shape: const CircleBorder(),
        mini: true,
        tooltip: 'Booster',
        child: const Icon(Icons.rocket_launch, color: Colors.white, size: 24),
      ),
    );
  }

  // ===============================================
  // 📸 APP BAR
  // ===============================================
  Widget _buildAppBar(ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1A1F26) : Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EcranModifierProduit(
                    boutique: widget.boutique,
                    produit: widget.produit,
                  ),
                ),
              );
              if (result == true && mounted) _chargerDonnees();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 5, bottom: 5),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.share_outlined, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _images.isEmpty
            ? _buildPlaceholder(isDark)
            : Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                    itemCount: _images.length,
                    itemBuilder: (_, index) => CachedNetworkImage(
                      imageUrl: _images[index].url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => _buildPlaceholder(isDark),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPill(Icons.access_time_rounded, _dureeDepuisMiseEnLigne()),
                        _buildPill(Icons.photo_library_outlined, '${_currentImageIndex + 1}/${_images.length}'),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 11),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ===============================================
  // 📄 CONTENU
  // ===============================================
  Widget _buildContent(ThemeData theme, bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F26) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            _buildHeader(theme, isDark),
            const SizedBox(height: 7),
            if (_couleurs.isNotEmpty) _buildCouleurs(theme),
            if (_tailles.isNotEmpty) _buildTailles(theme, isDark),
            _buildBadges(),
            const SizedBox(height: 5),
            _buildOnglets(theme, isDark),
            const SizedBox(height: 55),
          ],
        ),
      ),
    );
  }

  // ===============================================
  // 📌 HEADER
  // ===============================================
  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.produit.nom,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.produit.actif ? Colors.green.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: widget.produit.actif ? Colors.green.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.produit.actif ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.produit.actif ? 'Actif' : 'Inactif',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.produit.actif ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                widget.produit.prixFormate,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_outlined, size: 15, color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      widget.boutique.nomBoutique,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 15, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(_dureeDepuisMiseEnLigne(), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(width: 4),
              Icon(Icons.visibility_outlined, size: 15, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('${widget.produit.nombreVues} vues', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  // ===============================================
  // 🎨 COULEURS
  // ===============================================
  Widget _buildCouleurs(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Couleur', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            children: _couleurs.map((couleur) {
              final nom = couleur.nom;
              final isSelected = _couleurSelectionnee == nom;
              final couleurObj = couleursProduits.firstWhere((c) => c.nom == nom, orElse: () => couleursProduits.first);
              return GestureDetector(
                onTap: () => setState(() => _couleurSelectionnee = nom),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: couleurObj.couleur,
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                      width: isSelected ? 2 : 1.5,
                    ),
                    boxShadow: isSelected ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 5, spreadRadius: 1)] : null,
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 7),
        ],
      ),
    );
  }

  // ===============================================
  // 📏 TAILLES
  // ===============================================
  Widget _buildTailles(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Taille', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tailles.map((taille) {
              final valeur = taille.valeur;
              final isSelected = _tailleSelectionnee == valeur;
              return GestureDetector(
                onTap: () => setState(() => _tailleSelectionnee = valeur),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : (isDark ? const Color(0xFF242A32) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : (isDark ? const Color(0xFF353B45) : Colors.grey.shade300),
                    ),
                  ),
                  child: Text(valeur,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 7),
        ],
      ),
    );
  }

  // ===============================================
  // 🏷️ BADGES
  // ===============================================
  Widget _buildBadges() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _buildInfoBadge(widget.produit.estNeuf ? 'Neuf' : 'Occasion', widget.produit.estNeuf ? Colors.green : Colors.orange, Icons.label_outline),
          _buildInfoBadge(widget.produit.estEnRupture ? 'Rupture' : 'Stock: ${widget.produit.stockGlobal ?? 0}', widget.produit.estEnRupture ? Colors.red : Colors.blue, Icons.inventory_2_outlined),
          if (widget.produit.livraisonDisponible) _buildInfoBadge('Livraison', Colors.purple, Icons.local_shipping_outlined),
        ],
      ),
    );
  }

  // ===============================================
  // 📋 ONGLETS
  // ===============================================
  Widget _buildOnglets(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF242A32) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(7),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade500,
            indicator: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(7),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            padding: const EdgeInsets.all(4),
            tabs: const [
              Tab(text: 'Spécifications'),
              Tab(text: 'Description'),
              Tab(text: 'Avis'),
            ],
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 180,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSpecificationsTab(isDark),
              _buildDescriptionTab(isDark),
              _buildReviewsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecificationsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Column(
        children: [
          _buildSpecRow('Prix', widget.produit.prixFormate, Icons.sell_outlined, Colors.blue, isDark),
          _buildSpecRow('État', widget.produit.estNeuf ? 'Neuf' : 'Occasion', Icons.new_releases_outlined, widget.produit.estNeuf ? Colors.green : Colors.orange, isDark),
          _buildSpecRow('Stock', '${widget.produit.stockGlobal ?? 0} unité(s)', Icons.inventory_2_outlined, Colors.indigo, isDark),
          _buildSpecRow('Livraison', widget.produit.livraisonDisponible ? 'Disponible' : 'Non disponible', Icons.local_shipping_outlined, Colors.purple, isDark),
          if (_couleurs.isNotEmpty) _buildSpecRow('Couleurs', '${_couleurs.length} disponible(s)', Icons.palette_outlined, Colors.pink, isDark),
          if (_tailles.isNotEmpty) _buildSpecRow('Tailles', '${_tailles.length} disponible(s)', Icons.straighten_outlined, Colors.teal, isDark),
          _buildSpecRow('En ligne', _dureeDepuisMiseEnLigne(), Icons.access_time_rounded, Colors.grey, isDark),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, IconData icon, Color color, bool isDark) {
    const rowColor = Color(0xFF646464);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: rowColor),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: rowColor)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: rowColor)),
        ],
      ),
    );
  }

  Widget _buildDescriptionTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 6),
      child: Text(
        widget.produit.description ?? 'Aucune description disponible.',
        style: TextStyle(
          fontSize: 11,
          height: 1.5,
          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 5),
          Text('Aucun avis pour le moment', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }

  // ===============================================
  // 📊 BOTTOM BAR
  // ===============================================
  Widget _buildBottomBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F26) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(child: _buildStatBottom(icon: Icons.visibility_outlined, label: 'Vues', value: '${widget.produit.nombreVues}', color: Colors.blue, isDark: isDark)),
            const SizedBox(width: 4),
            Expanded(child: _buildStatBottom(icon: Icons.shopping_bag_outlined, label: 'Ventes', value: '${widget.produit.nombreVentes}', color: Colors.green, isDark: isDark)),
            const SizedBox(width: 4),
            Expanded(child: _buildStatBottom(icon: Icons.share_outlined, label: 'Partages', value: '0', color: Colors.orange, isDark: isDark)),
          ],
        ),
      ),
    );
  }

  // ===============================================
  // 🚀 BOOST
  // ===============================================
  void _afficherBoostSheet(ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F26) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rocket_launch, color: Colors.deepOrange, size: 18),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Booster ce produit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                          Text('Plus de visibilité = plus de ventes', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Divider(color: isDark ? const Color(0xFF353B45) : Colors.grey.shade200),
                  const SizedBox(height: 7),
                  _buildBoostOption(context: context, isDark: isDark, icon: Icons.bolt, titre: '1 jour', description: 'Mise en avant 24h', prix: '200 FCFA', couleur: Colors.amber, badge: null),
                  const SizedBox(height: 5),
                  _buildBoostOption(context: context, isDark: isDark, icon: Icons.local_fire_department, titre: '3 jours', description: 'Top position 72h', prix: '500 FCFA', couleur: Colors.orange, badge: null),
                  const SizedBox(height: 5),
                  _buildBoostOption(context: context, isDark: isDark, icon: Icons.rocket_launch, titre: '1 semaine', description: 'Visibilité max 7 jours', prix: '1 500 FCFA', couleur: Colors.deepOrange, badge: 'Populaire'),
                  const SizedBox(height: 5),
                  _buildBoostOption(context: context, isDark: isDark, icon: Icons.workspace_premium, titre: '1 mois', description: 'Visibilité maximale 30 jours', prix: '3 000 FCFA', couleur: Colors.purple, badge: 'Meilleure valeur'),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 15, color: Colors.blue.shade400),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Le boost augmente la visibilité dans les résultats et la vitrine.',
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade400, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBoostOption({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String titre,
    required String description,
    required String prix,
    required Color couleur,
    required String? badge,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _confirmerBoost(titre, prix);
      },
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: couleur.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: couleur.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: couleur, size: 18),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(titre, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: couleur)),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(7)),
                          child: Text(badge, style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(description, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                ],
              ),
            ),
            Text(prix, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: couleur)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 15, color: couleur.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  void _confirmerBoost(String duree, String prix) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.rocket_launch, color: Colors.deepOrange, size: 20),
            const SizedBox(width: 4),
            const Text('Confirmer le boost', style: TextStyle(fontSize: 11)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booster "${widget.produit.nom}" pendant $duree ?', style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Montant', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text(prix, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Row(children: [
                  const Icon(Icons.rocket_launch, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text('Boost $duree activé !'),
                ]),
                backgroundColor: Colors.deepOrange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              ));
            },
            icon: const Icon(Icons.rocket_launch, size: 14),
            label: Text('Booster pour $prix', style: const TextStyle(fontSize: 11)),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================
  // 🎨 HELPERS
  // ===============================================
  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Center(child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey.shade400)),
    );
  }

  Widget _buildInfoBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildStatBottom({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 9, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500)),
        ],
      ),
    );
  }
}
