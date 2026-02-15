// ===============================================
// 🔨 TAB ENCHÈRES - DESIGN MODERNE
// ===============================================
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/enchere.dart';
import '../services/service_encheres_supabase.dart';
import 'ecran_details_enchere.dart';
import 'dart:async';

class TabEncheres extends StatefulWidget {
  const TabEncheres({super.key});

  @override
  State<TabEncheres> createState() => _TabEncheresState();
}

class _TabEncheresState extends State<TabEncheres> {
  final ServiceEncheresSupabase _service = ServiceEncheresSupabase();
  List<Enchere> _encheres = [];
  bool _chargement = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _chargerEncheres();
    // Rafraîchir chaque seconde pour les timers
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _chargerEncheres() async {
    setState(() => _chargement = true);
    final encheres = await _service.recupererEncheresPopulaires(limite: 50);
    setState(() {
      _encheres = encheres;
      _chargement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_chargement) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.primaryColor,
        ),
      );
    }

    if (_encheres.isEmpty) {
      return _buildVide(theme);
    }

    return RefreshIndicator(
      onRefresh: _chargerEncheres,
      color: theme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _encheres.length,
        itemBuilder: (context, index) {
          final enchere = _encheres[index];
          return _CarteEnchere(
            enchere: enchere,
            onTap: () => _ouvrirDetails(enchere),
          );
        },
      ),
    );
  }

  Widget _buildVide(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.gavel_outlined,
            size: 80,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune enchère active',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les enchères apparaîtront ici',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _ouvrirDetails(Enchere enchere) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EcranDetailsEnchere(enchere: enchere),
      ),
    );
  }
}

// ===============================================
// 🎴 CARTE ENCHÈRE - COMPOSANT RÉUTILISABLE
// ===============================================
class _CarteEnchere extends StatelessWidget {
  final Enchere enchere;
  final VoidCallback onTap;

  const _CarteEnchere({
    required this.enchere,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tempsRestant = enchere.tempsRestant;
    final urgence = tempsRestant.inHours < 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ IMAGE + BADGE TIMER
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: enchere.imageProduit != null
                      ? CachedNetworkImage(
                          imageUrl: enchere.imageProduit!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.disabledColor.withValues(alpha: 0.1),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.disabledColor.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: theme.disabledColor,
                            ),
                          ),
                        )
                      : Container(
                          color: theme.disabledColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: theme.disabledColor,
                          ),
                        ),
                ),
                // TIMER en haut à droite
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: urgence
                          ? Colors.red.withValues(alpha: 0.95)
                          : Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          urgence ? Icons.access_alarm : Icons.schedule,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          enchere.tempsRestantFormate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // BADGE ENCHÉRISSEURS
                if (enchere.nombreEncherisseurs > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${enchere.nombreEncherisseurs}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // 📝 INFOS
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NOM PRODUIT
                  Text(
                    enchere.nomProduit,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // BOUTIQUE
                  Row(
                    children: [
                      Icon(
                        Icons.store,
                        size: 14,
                        color: theme.disabledColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          enchere.nomBoutique,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // PRIX
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // PRIX DE DÉPART
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prix de départ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.disabledColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${enchere.prixDepart.toStringAsFixed(0)} FCFA',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: theme.disabledColor,
                            ),
                          ),
                        ],
                      ),

                      // PRIX ACTUEL
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Enchère actuelle',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${enchere.prixActuel.toStringAsFixed(0)} FCFA',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
