// ===============================================
// 📋 ÉCRAN LISTE PRODUITS - VERSION MODERNE
// ===============================================
// Bottom sheet avec aperçu visuel et adaptatif au thème

import 'package:flutter/material.dart';
import '../../vendeur/models/boutique.dart';
import '../../vendeur/views/ecran_abonnement_vendeur.dart';
import '../models/produit.dart';
import '../services/service_produit_supabase.dart';
import 'ecran_ajouter_produit.dart';
import 'ecran_modifier_produit.dart';
import 'ecran_details_produit.dart';

enum TypeAffichage { tous, actifs, inactifs }

class EcranListeProduits extends StatefulWidget {
  final Boutique boutique;

  const EcranListeProduits({
    super.key,
    required this.boutique,
  });

  @override
  State<EcranListeProduits> createState() => _EcranListeProduitsState();
}

class _EcranListeProduitsState extends State<EcranListeProduits> {
  final _service = ServiceProduitSupabase();
  String _recherche = '';
  TypeAffichage _affichage = TypeAffichage.actifs;

  static const int limiteProduitsGratuit = 50;
  static const int limiteProduitsPremium = 150;

  Future<void> _rafraichir() async {
    setState(() {});
  }

  Future<void> _ajouterProduit() async {
    final produits = await _service.listerProduitsVendeur(widget.boutique.id);
    final typeAbo = widget.boutique.typeAbonnement;

    String? messageErreur;
    int? limiteAtteinte;

    switch (typeAbo) {
      case TypeAbonnement.gratuit:
        if (produits.length >= limiteProduitsGratuit) {
          messageErreur = 'Vous avez atteint la limite de $limiteProduitsGratuit produits pour l\'abonnement gratuit.';
          limiteAtteinte = limiteProduitsGratuit;
        }
        break;

      case TypeAbonnement.premium:
        if (produits.length >= limiteProduitsPremium) {
          messageErreur = 'Vous avez atteint la limite de $limiteProduitsPremium produits pour l\'abonnement Premium.';
          limiteAtteinte = limiteProduitsPremium;
        }
        break;

      case TypeAbonnement.entreprise:
        break;
    }

    if (messageErreur != null && limiteAtteinte != null) {
      if (!mounted) return;

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber.shade600),
              const SizedBox(width: 8),
              const Text('Limite atteinte'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                messageErreur!,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        typeAbo == TypeAbonnement.gratuit ? 'Passez à Premium (50 produits) ou Entreprise (illimité) !' : 'Passez à Entreprise pour des produits illimités !',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.workspace_premium, size: 18),
              label: const Text('Voir les abonnements'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
              ),
            ),
          ],
        ),
      );

      if (result == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const EcranAbonnementVendeur(),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EcranAjouterProduit(boutique: widget.boutique),
      ),
    );

    if (result == true) _rafraichir();
  }

  Future<void> _modifierProduit(Produit produit) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EcranModifierProduit(
          boutique: widget.boutique,
          produit: produit,
        ),
      ),
    );

    if (result == true) _rafraichir();
  }

  Future<void> _toggleActif(Produit produit) async {
    final estAbonnementGratuit = widget.boutique.typeAbonnement == TypeAbonnement.gratuit;

    if (estAbonnementGratuit) {
      if (!mounted) return;

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber.shade600),
              const SizedBox(width: 8),
              const Text('Premium requis'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'L\'activation/désactivation de produits est réservée aux abonnés Premium.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Passez à Premium pour gérer l\'activation de vos produits !',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.workspace_premium, size: 18),
              label: const Text('Passer à Premium'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
              ),
            ),
          ],
        ),
      );

      if (result == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const EcranAbonnementVendeur(),
          ),
        );
      }
      return;
    }

    try {
      await _service.toggleActif(produit.id, !produit.actif);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            produit.actif ? 'Produit désactivé' : 'Produit activé',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      _rafraichir();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _supprimerProduit(Produit produit) async {
    final estAbonnementGratuit = widget.boutique.typeAbonnement == TypeAbonnement.gratuit;

    if (estAbonnementGratuit) {
      if (!mounted) return;

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber.shade600),
              const SizedBox(width: 8),
              const Text('Premium requis'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'La suppression de produits est réservée aux abonnés Premium.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Passez à Premium pour débloquer la suppression et bien plus !',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.workspace_premium, size: 18),
              label: const Text('Passer à Premium'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
              ),
            ),
          ],
        ),
      );

      if (result == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const EcranAbonnementVendeur(),
          ),
        );
      }
      return;
    }

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le produit ?'),
        content: Text(
          'Voulez-vous vraiment supprimer "${produit.nom}" ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      await _service.supprimerProduit(produit.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit supprimé'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _rafraichir();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ✅ BOTTOM SHEET MODERNE AVEC APERÇU VISUEL
  void _afficherMenuOptions(Produit produit) {
    final estAbonnementGratuit = widget.boutique.typeAbonnement == TypeAbonnement.gratuit;
    Theme.of(context);

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 📌 HANDLE BAR
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🖼️ APERÇU PRODUIT
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // IMAGE
                        FutureBuilder<List<ProduitImage>>(
                          future: _service.listerImages(produit.id),
                          builder: (context, snapshot) {
                            return Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF242A32) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF353B45) : const Color(0xFFE2E8F0),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: snapshot.hasData && snapshot.data!.isNotEmpty
                                    ? Image.network(
                                        snapshot.data!.first.url,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                                              strokeWidth: 2,
                                            ),
                                          );
                                        },
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.image_not_supported,
                                          size: 36,
                                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                        ),
                                      )
                                    : Icon(
                                        Icons.image_not_supported,
                                        size: 36,
                                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 14),

                        // INFOS
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // NOM
                              Text(
                                produit.nom,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),

                              // PRIX
                              Text(
                                produit.prixFormate,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // BADGES
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildBadge(
                                    produit.estNeuf ? 'Neuf' : 'Occasion',
                                    produit.estNeuf ? Colors.green : Colors.orange,
                                    Icons.label_outline,
                                  ),
                                  _buildBadge(
                                    produit.estEnRupture ? 'Rupture' : 'Stock: ${produit.stockGlobal ?? 0}',
                                    produit.estEnRupture ? Colors.red : Colors.blue,
                                    Icons.inventory_2_outlined,
                                  ),
                                  _buildBadge(
                                    produit.actif ? 'Actif' : 'Inactif',
                                    produit.actif ? Colors.green : Colors.grey,
                                    produit.actif ? Icons.visibility : Icons.visibility_off,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Divider(
                    color: isDark ? const Color(0xFF353B45) : const Color(0xFFE2E8F0),
                    height: 1,
                  ),
                  const SizedBox(height: 12),

                  // 🎯 ACTIONS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        _buildActionTile(
                          icon: Icons.edit_outlined,
                          label: 'Modifier',
                          color: theme.colorScheme.primary,
                          onTap: () {
                            Navigator.pop(context);
                            _modifierProduit(produit);
                          },
                          isDark: isDark,
                        ),
                        if (!estAbonnementGratuit)
                          _buildActionTile(
                            icon: produit.actif ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            label: produit.actif ? 'Désactiver' : 'Activer',
                            color: produit.actif ? Colors.orange : Colors.green,
                            onTap: () {
                              Navigator.pop(context);
                              _toggleActif(produit);
                            },
                            isDark: isDark,
                          ),
                        if (!estAbonnementGratuit)
                          _buildActionTile(
                            icon: Icons.delete_outline,
                            label: 'Supprimer',
                            color: Colors.red,
                            onTap: () {
                              Navigator.pop(context);
                              _supprimerProduit(produit);
                            },
                            isDark: isDark,
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

  // 🎨 WIDGET BADGE
  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 WIDGET ACTION TILE
  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  List<Produit> _filtrerProduits(List<Produit> produits) {
    return produits.where((produit) {
      switch (_affichage) {
        case TypeAffichage.actifs:
          if (!produit.actif) return false;
          break;
        case TypeAffichage.inactifs:
          if (produit.actif) return false;
          break;
        case TypeAffichage.tous:
          break;
      }

      if (_recherche.isNotEmpty) {
        final rechercheLower = _recherche.toLowerCase();
        final nomLower = produit.nom.toLowerCase();
        final descLower = (produit.description ?? '').toLowerCase();

        if (!nomLower.contains(rechercheLower) && !descLower.contains(rechercheLower)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 16),

          // BARRE DE RECHERCHE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242A32) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF353B45) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  suffixIcon: _recherche.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setState(() => _recherche = ''),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (value) => setState(() => _recherche = value),
              ),
            ),
          ),

          const SizedBox(height: 5),

          // STATISTIQUES
          FutureBuilder<List<Produit>>(
            future: _service.listerProduitsVendeur(widget.boutique.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final produits = snapshot.data!;
              final nbActifs = produits.where((p) => p.actif).length;
              final nbInactifs = produits.length - nbActifs;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total',
                        produits.length,
                        Icons.inventory_2_outlined,
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.primary,
                        TypeAffichage.tous,
                        theme,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: _buildStatCard(
                        'Actifs',
                        nbActifs,
                        Icons.check_circle_outline,
                        Colors.green.shade50,
                        Colors.green.shade600,
                        TypeAffichage.actifs,
                        theme,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: _buildStatCard(
                        'Inactifs',
                        nbInactifs,
                        Icons.cancel_outlined,
                        Colors.orange.shade50,
                        Colors.orange.shade600,
                        TypeAffichage.inactifs,
                        theme,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 3),

          // LISTE PRODUITS
          Expanded(
            child: FutureBuilder<List<Produit>>(
              future: _service.listerProduitsVendeur(widget.boutique.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final tousLesProduits = snapshot.data ?? [];
                final produitsFiltres = _filtrerProduits(tousLesProduits);

                if (produitsFiltres.isEmpty) {
                  return _buildEmptyState(theme);
                }

                return RefreshIndicator(
                  onRefresh: _rafraichir,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: produitsFiltres.length,
                    itemBuilder: (context, index) {
                      return _buildProduitCard(produitsFiltres[index], theme);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterProduit,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    int valeur,
    IconData icon,
    Color bgColor,
    Color textColor,
    TypeAffichage type,
    ThemeData theme,
  ) {
    final isSelected = _affichage == type;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _affichage = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? textColor.withValues(alpha: 0.15) : bgColor) : (isDark ? const Color(0xFF1A1F26) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? textColor : (isDark ? const Color(0xFF353B45) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: textColor),
            const SizedBox(height: 6),
            Text(
              valeur.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProduitCard(Produit produit, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final estAbonnementGratuit = widget.boutique.typeAbonnement == TypeAbonnement.gratuit;

    return GestureDetector(
      onTap: () {
        // 🔥 NAVIGATION VERS DÉTAILS
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EcranDetailsProduit(
              produit: produit,
              boutique: widget.boutique,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F26) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF353B45) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: FutureBuilder<List<ProduitImage>>(
                future: _service.listerImages(produit.id),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            snapshot.data!.first.url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: produit.estNeuf ? Colors.green.withValues(alpha: 0.9) : Colors.orange.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                produit.estNeuf ? 'Neuf' : 'Occasion',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return _buildPlaceholder(isDark);
                },
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            produit.nom,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _afficherMenuOptions(produit),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.more_vert,
                              size: 16,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (produit.description != null && produit.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        produit.description!,
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Text(
                      produit.prixFormate,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory_2,
                                size: 11,
                                color: produit.estEnRupture ? Colors.red : Colors.green,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  produit.estEnRupture ? 'Rupture' : '${produit.stockGlobal ?? 0}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: produit.estEnRupture ? Colors.red : Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!estAbonnementGratuit)
                          Transform.scale(
                            scale: 0.65,
                            child: Switch(
                              value: produit.actif,
                              onChanged: (_) => _toggleActif(produit),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: produit.actif ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              produit.actif ? 'Actif' : 'Inactif',
                              style: TextStyle(
                                fontSize: 9,
                                color: produit.actif ? Colors.green : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(14),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 36,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 70,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun produit',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _recherche.isNotEmpty ? 'Aucun résultat pour "$_recherche"' : 'Ajoutez votre premier produit',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 70, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Erreur',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _rafraichir,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
