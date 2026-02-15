// ===============================================
// 🖼️ PRODUIT GRID CARD - FACEBOOK 2026 + BOUTIQUE
// ===============================================
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/produit.dart';
import '../../services/service_produit_supabase.dart';
import '../../../vendeur/models/boutique.dart';
import '../../../vendeur/services/service_vendeur_supabase.dart';
//import 'ecran_detail_produit.dart'; // À créer

class ProduitGridCard extends StatelessWidget {
  final Produit produit;
  final ServiceProduitSupabase service;
  final ServiceVendeurSupabase _vendeurService = ServiceVendeurSupabase();

  ProduitGridCard({
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

  Future<Boutique?> _getBoutique() async {
    try {
      return await _vendeurService.recupererBoutique(produit.vendeurId);
    } catch (e) {
      debugPrint('Erreur boutique ${produit.vendeurId}: $e');
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
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // 💰 PRIX
                    Text(
                      produit.prixFormate,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // 📛 NOM PRODUIT
                    Text(
                      produit.nom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // ⭐ NOTE + 👁️ VUES
                    Row(
                      children: [
                        // Note
                        Icon(Icons.star, color: Colors.amber.withValues(alpha: 0.8), size: 12),
                        const SizedBox(width: 2),
                        Text(
                          produit.note.toStringAsFixed(1),
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Vues
                        Icon(Icons.visibility, size: 12, color: Colors.grey.withValues(alpha: 0.6)),
                        const SizedBox(width: 2),
                        Text(
                          '${produit.nombreVues}',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // 🕐 DURÉE (ligne séparée en bas à droite)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _dureeDepuisMiseEnLigne(),
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey.withValues(alpha: 0.6),
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // 📍 DIVIDER
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),

                    const SizedBox(height: 6),

                    // 🏪 BOUTIQUE (en bas)
                    FutureBuilder<Boutique?>(
                      future: _getBoutique(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        final boutique = snapshot.data;
                        if (boutique == null) {
                          return Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.store,
                                  size: 10,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Boutique',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: Colors.grey.withValues(alpha: 0.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            // 🏪 LOGO BOUTIQUE (rond)
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: ClipOval(
                                child: boutique.logoUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: boutique.logoUrl!,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) => Icon(
                                          Icons.store,
                                          size: 10,
                                          color: primaryColor,
                                        ),
                                      )
                                    : Icon(
                                        Icons.store,
                                        size: 10,
                                        color: primaryColor,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // 📛 NOM BOUTIQUE
                            Expanded(
                              child: Text(
                                boutique.nomBoutique,
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.withValues(alpha: 0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
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
}
