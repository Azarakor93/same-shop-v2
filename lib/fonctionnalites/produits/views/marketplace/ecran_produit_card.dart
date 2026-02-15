// ===============================================
// 🖼️ PRODUIT GRID CARD - FACEBOOK 2026 + DURÉE
// ===============================================
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/produit.dart';
import '../../services/service_produit_supabase.dart';
//import 'ecran_detail_produit.dart'; // À créer

class ProduitGridCard extends StatelessWidget {
  final Produit produit;
  final ServiceProduitSupabase service;

  const ProduitGridCard({
    super.key,
    required this.produit,
    required this.service,
  });

  Future<String?> _getImageUrl() async {
    try {
      final images = await service.listerImages(produit.id);
      return images.isNotEmpty ? images.first.url : null;
    } catch (e) {
      debugPrint('Erreur image ${produit.id}: $e');
      return null;
    }
  }

  String _dureeDepuisMiseEnLigne() {
    final diff = DateTime.now().difference(produit.createdAt); // Utilise createdAt
    if (diff.inDays >= 365) return 'Il y a ${(diff.inDays / 365).floor()}an(s)';
    if (diff.inDays >= 30) return 'Il y a ${(diff.inDays / 30).floor()}mois';
    if (diff.inDays >= 1) return 'Il y a ${diff.inDays}j';
    if (diff.inHours >= 1) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inMinutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final cardColor = theme.cardColor;
    final textTheme = theme.textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        // TODO: Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => EcranDetailProduit(produit: produit),
        //   ),
        // );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ IMAGE (55%)
            Expanded(
              flex: 55,
              child: Stack(
                children: [
                  FutureBuilder<String?>(
                    future: _getImageUrl(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasData && snapshot.data != null) {
                        return ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: CachedNetworkImage(
                            imageUrl: snapshot.data!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.grey.withValues(alpha: 0.2),
                              child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: const Icon(Icons.image, size: 50, color: Colors.grey),
                      );
                    },
                  ),

                  // 🔥 Badge TOP
                  if (produit.estTop)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '🔥 TOP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // ❤️ Favori
                  Positioned(
                    top: 6,
                    left: 6,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ajouté aux favoris ❤️'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 📝 INFO PRODUIT (45%)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 📛 NOM PRODUIT
                  Text(
                    produit.nom,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 💰 PRIX + 🕐 TA FONCTION DATE
                  Row(
                    children: [
                      // Prix principal (plus petit)
                      Text(
                        produit.prixFormate,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 12, // Prix réduit comme Facebook
                        ),
                      ),
                      const Spacer(),
                      // ✅ TA FONCTION _dureeDepuisMiseEnLigne()
                      Text(
                        _dureeDepuisMiseEnLigne(),
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // ⭐ NOTE + 👁️ VUES
                  Row(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber.withValues(alpha: 0.8), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            produit.note.toStringAsFixed(1),
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility, size: 14, color: Colors.grey.withValues(alpha: 0.6)),
                          const SizedBox(width: 2),
                          Text(
                            '${produit.nombreVues}',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.grey.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ❌ RUPTURE DE STOCK
                  if (!produit.estDisponible) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Rupture de stock',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.red.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
