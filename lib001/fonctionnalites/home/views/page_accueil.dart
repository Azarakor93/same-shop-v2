import 'package:flutter/material.dart';

import '../../produits/widgets/selecteur_categorie.dart';
import 'models/annonces.dart';
import 'services/supabase_annonce_service.dart';
import 'widgets/carte_top_produit_skeleton.dart';
import 'widgets/champ_recherche_marketplace.dart';
import 'widgets/header_recherche_sticky.dart';
import 'widgets/slider_annonces.dart';
import '../../encheres/models/enchere.dart';
import '../../encheres/services/service_encheres_supabase.dart';
import '../../produits/models/produit.dart';
import '../../produits/services/service_produit_supabase.dart';
import '../../produits/views/ecran_produits_filtre.dart';
// import '../../produits/views/widget_selecteur_categorie_bottom_sheet.dart'; // Lint: file does not exist, commented out to avoid error

class PageAccueil extends StatefulWidget {
  const PageAccueil({super.key});

  @override
  State<PageAccueil> createState() => _PageAccueilState();
}

class _PageAccueilState extends State<PageAccueil> {
  final _rechercheCtrl = TextEditingController();
  final _annonceService = SupabaseAnnonceService();
  final _produitService = ServiceProduitSupabase();
  final _encheresService = ServiceEncheresSupabase();

  late Future<List<Annonce>> _annoncesFuture;
  late Future<List<Produit>> _boostsFuture;
  late Future<List<Produit>> _topProduitsFuture;
  late Future<List<Produit>> _produitsAccueilFuture;
  late Future<List<Enchere>> _encheresFuture;

  @override
  void initState() {
    super.initState();
    _annoncesFuture = _annonceService.chargerAnnonces();
    _boostsFuture = _produitService.listerProduitsBoostes(limit: 10);
    _topProduitsFuture = _produitService.listerTopProduits(limit: 10);
    _produitsAccueilFuture = _produitService.listerProduitsMarketplace(
      limit: 12,
    );
    _encheresFuture = _encheresService.listerEncheresEnCours();
  }

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: _bandeauIntro(context),
          ),
        ),

        /// 🔎 Recherche sticky (PDF: catalogue + filtres)
        SliverPersistentHeader(
          pinned: true,
          delegate: HeaderRechercheSticky(
            child: ChampRechercheMarketplace(
              controller: _rechercheCtrl,
              onFiltre: () => _ouvrirFiltres(context),
              onChanged: (_) {},
            ),
          ),
        ),

        /// 🖼️ Slider annonces (Supabase: table `annonces`)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: FutureBuilder<List<Annonce>>(
              future: _annoncesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _sliderPlaceholder(context);
                }
                if (snapshot.hasError) {
                  return _etatErreur(
                    context,
                    titre: 'Annonces indisponibles',
                    detail:
                        'Impossible de charger les annonces pour le moment.',
                    actionLabel: 'Réessayer',
                    onAction: () => setState(
                      () => _annoncesFuture = _annonceService.chargerAnnonces(),
                    ),
                  );
                }

                final annonces = snapshot.data ?? const <Annonce>[];
                if (annonces.isEmpty) {
                  return _etatInfo(
                    context,
                    titre: 'Aucune annonce',
                    detail: 'Ajoutez des bannières dans Supabase (table annonces).',
                  );
                }

                return SliderAnnonces(annonces: annonces);
              },
            ),
          ),
        ),

        /// 🛒 Aperçu produits (clients voient des produits dès l'ouverture)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
            child: _enteteSection(
              context,
              titre: 'Produits à découvrir',
              sousTitre: 'Un aperçu du marketplace',
              icone: Icons.shopping_bag_outlined,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 245,
            child: FutureBuilder<List<Produit>>(
              future: _produitsAccueilFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, __) => const CarteTopProduitSkeleton(),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _etatErreur(
                      context,
                      titre: 'Produits indisponibles',
                      detail:
                          'Impossible de charger les produits pour le moment.',
                      actionLabel: 'Réessayer',
                      onAction: () => setState(() {
                        _produitsAccueilFuture =
                            _produitService.listerProduitsMarketplace(
                          limit: 12,
                        );
                      }),
                    ),
                  );
                }

                final items = snapshot.data ?? const <Produit>[];
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _etatInfo(
                      context,
                      titre: 'Aucun produit pour le moment',
                      detail:
                          'Les produits actifs apparaîtront ici automatiquement.',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, index) =>
                      _carteProduitBoost(context, items[index]),
                );
              },
            ),
          ),
        ),

        /// ⭐ Section “Boosts” (PDF: boosts 200/500/1500/9000)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: _enteteSection(
              context,
              titre: 'Boosts du moment',
              sousTitre: 'Produits mis en avant près de vous',
              icone: Icons.trending_up,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 255,
            child: FutureBuilder<List<Produit>>(
              future: _boostsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, __) => const CarteTopProduitSkeleton(),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _etatErreur(
                      context,
                      titre: 'Boosts indisponibles',
                      detail:
                          'Impossible de charger les produits boostés pour le moment.',
                      actionLabel: 'Réessayer',
                      onAction: () => setState(() {
                        _boostsFuture =
                            _produitService.listerProduitsBoostes(limit: 10);
                      }),
                    ),
                  );
                }

                final items = snapshot.data ?? const <Produit>[];
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _etatInfo(
                      context,
                      titre: 'Aucun boost actif',
                      detail:
                          'Les produits boostés apparaîtront ici automatiquement.',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, index) => _carteProduitBoost(context, items[index]),
                );
              },
            ),
          ),
        ),

        /// 📣 Section “Annonces produits” (TOP produits très importants)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
            child: _enteteSection(
              context,
              titre: 'Annonces produits',
              sousTitre: 'Produits stratégiques mis en avant',
              icone: Icons.campaign_outlined,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 255,
            child: FutureBuilder<List<Produit>>(
              future: _topProduitsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, __) => const CarteTopProduitSkeleton(),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _etatErreur(
                      context,
                      titre: 'Annonces produits indisponibles',
                      detail:
                          'Impossible de charger les annonces produits pour le moment.',
                      actionLabel: 'Réessayer',
                      onAction: () => setState(() {
                        _topProduitsFuture =
                            _produitService.listerTopProduits(limit: 10);
                      }),
                    ),
                  );
                }

                final items = snapshot.data ?? const <Produit>[];
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _etatInfo(
                      context,
                      titre: 'Aucune annonce produit',
                      detail:
                          'Les produits marqués comme “top” apparaîtront ici automatiquement.',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, index) =>
                      _carteProduitAnnonce(context, items[index]),
                );
              },
            ),
          ),
        ),

        /// 🔨 Section “Enchères phares” (PDF: enchères entreprises)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
            child: _enteteSection(
              context,
              titre: 'Enchères phares',
              sousTitre: 'Les meilleures offres en cours',
              icone: Icons.gavel,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
            child: FutureBuilder<List<Enchere>>(
              future: _encheresFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _encheresPlaceholder(context);
                }
                if (snapshot.hasError) {
                  return _etatErreur(
                    context,
                    titre: 'Enchères indisponibles',
                    detail: 'Impossible de charger les enchères pour le moment.',
                    actionLabel: 'Réessayer',
                    onAction: () => setState(() {
                      _encheresFuture = _encheresService.listerEncheresEnCours();
                    }),
                  );
                }

                final items = snapshot.data ?? const <Enchere>[];
                if (items.isEmpty) {
                  return _etatInfo(
                    context,
                    titre: 'Aucune enchère en cours',
                    detail: 'Les enchères d’entreprises apparaîtront ici.',
                  );
                }

                final top = items.take(3).toList();
                return Column(
                  children: [
                    ...top.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _carteEncherePhare(context, e),
                        )),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Voir toutes les enchères'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 70),
        ),
      ],
    );
  }

  Widget _bandeauIntro(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.16),
            cs.secondary.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.storefront, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue sur SAME Shop',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Catalogue, boosts et enchères — tout au même endroit.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _enteteSection(
    BuildContext context, {
    required String titre,
    required String sousTitre,
    required IconData icone,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Icon(icone, color: cs.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                sousTitre,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('Voir tout'),
        ),
      ],
    );
  }

  Widget _sliderPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140,
        color: cs.surfaceContainerHighest,
      ),
    );
  }

  Widget _encheresPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      height: 110,
    );
  }

  Widget _carteProduitBoost(BuildContext context, Produit produit) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      width: 200,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(Icons.local_fire_department,
                      color: cs.secondary, size: 28),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                produit.nom,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${produit.prix} FCFA',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Détails'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Carte pour les annonces produits (TOP produits)
  Widget _carteProduitAnnonce(BuildContext context, Produit produit) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      width: 220,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    Icons.campaign,
                    color: cs.primary,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                produit.nom,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${produit.prix} FCFA',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Point d'entrée prévu pour la navigation vers le détail produit.
                    // L'écran de détails marketplace pourra être branché ici plus tard.
                  },
                  child: const Text('Voir le produit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _carteEncherePhare(BuildContext context, Enchere enchere) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final reste = enchere.dateFin.difference(DateTime.now());
    final resteTexte = reste.isNegative
        ? 'Terminé'
        : '${reste.inHours}h ${reste.inMinutes.remainder(60)}m';

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: cs.secondary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.gavel, color: cs.secondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enchere.titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${enchere.prixDepart} FCFA • $resteTexte',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Voir'),
          ),
        ],
      ),
    );
  }

  Widget _etatErreur(
    BuildContext context, {
    required String titre,
    required String detail,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: cs.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Widget _etatInfo(
    BuildContext context, {
    required String titre,
    required String detail,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: cs.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _ouvrirFiltres(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        String? categorieId;
        String? categorieLabel;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtres produits',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Catégorie, tailles, couleurs… pour affiner le catalogue.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Catégorie',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final res = await SelecteurCategorie.afficherCategorie(
                          context: context,
                          categorieActuelleId: categorieId,
                        );
                        if (res == null) return;
                        setModalState(() {
                          categorieId = res['id'];
                          categorieLabel = res['nomComplet'];
                        });
                      },
                      icon: const Icon(Icons.category_outlined),
                      label: Text(
                        categorieLabel ?? 'Toutes les catégories',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tailles & couleurs (à connecter aux variantes)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EcranProduitsFiltres(
                                  categorieId: categorieId,
                                  categorieLabel: categorieLabel,
                                ),
                              ),
                            );
                          },
                          child: const Text('Voir les produits'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

