// ===============================================
// ❤️ TAB FAVORIS - GESTION PERSISTANTE
// ===============================================
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'models/favori_temp.dart';
import 'services/service_favoris_supabase.dart';

class TabFavoris extends StatefulWidget {
  const TabFavoris({super.key});

  @override
  State<TabFavoris> createState() => _TabFavorisState();
}

class _TabFavorisState extends State<TabFavoris> {
  final ServiceFavorisSupabase _service = ServiceFavorisSupabase();
  List<Favori> _favoris = [];
  bool _chargement = true;
  bool _modeSelection = false;
  final Set<String> _selection = {};

  @override
  void initState() {
    super.initState();
    _chargerFavoris();
  }

  Future<void> _chargerFavoris() async {
    setState(() => _chargement = true);
    final favoris = await _service.recupererFavoris();
    setState(() {
      _favoris = favoris;
      _chargement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _modeSelection ? _buildAppBarSelection(theme) : null,
      body: _chargement
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : _favoris.isEmpty
              ? _buildVide(theme)
              : RefreshIndicator(
                  onRefresh: _chargerFavoris,
                  color: theme.primaryColor,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _favoris.length,
                    itemBuilder: (context, index) {
                      final favori = _favoris[index];
                      final estSelectionne = _selection.contains(favori.produitId);

                      return _CarteFavori(
                        favori: favori,
                        modeSelection: _modeSelection,
                        estSelectionne: estSelectionne,
                        onTap: () => _gererTap(favori),
                        onLongPress: () => _activerModeSelection(favori),
                        onRetirerFavori: () => _retirerFavori(favori),
                      );
                    },
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBarSelection(ThemeData theme) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          setState(() {
            _modeSelection = false;
            _selection.clear();
          });
        },
      ),
      title: Text('${_selection.length} sélectionné(s)'),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _supprimerSelection,
        ),
      ],
    );
  }

  Widget _buildVide(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun favori',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des produits à vos favoris',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _gererTap(Favori favori) {
    if (_modeSelection) {
      setState(() {
        if (_selection.contains(favori.produitId)) {
          _selection.remove(favori.produitId);
        } else {
          _selection.add(favori.produitId);
        }
      });
    } else {
      // TODO: Ouvrir détails produit (nécessite charger produit complet)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produit: ${favori.nomProduit}'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    }
  }

  void _activerModeSelection(Favori favori) {
    setState(() {
      _modeSelection = true;
      _selection.add(favori.produitId);
    });
  }

  Future<void> _retirerFavori(Favori favori) async {
    final succes = await _service.retirerFavori(favori.produitId);
    if (succes && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retiré des favoris'),
          duration: Duration(seconds: 2),
        ),
      );
      _chargerFavoris();
    }
  }

  Future<void> _supprimerSelection() async {
    if (_selection.isEmpty) return;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text('Retirer ${_selection.length} produit(s) des favoris ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    for (final produitId in _selection) {
      await _service.retirerFavori(produitId);
    }

    setState(() {
      _modeSelection = false;
      _selection.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Favoris retirés'),
          backgroundColor: Colors.green,
        ),
      );
    }

    _chargerFavoris();
  }
}

// ===============================================
// 🎴 CARTE FAVORI
// ===============================================
class _CarteFavori extends StatelessWidget {
  final Favori favori;
  final bool modeSelection;
  final bool estSelectionne;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRetirerFavori;

  const _CarteFavori({
    required this.favori,
    required this.modeSelection,
    required this.estSelectionne,
    required this.onTap,
    required this.onLongPress,
    required this.onRetirerFavori,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE
                Expanded(
                  child: Stack(
                    children: [
                      SizedBox.expand(
                        child: favori.imageProduit != null
                            ? CachedNetworkImage(
                                imageUrl: favori.imageProduit!,
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
                                    color: theme.disabledColor,
                                  ),
                                ),
                              )
                            : Container(
                                color: theme.disabledColor.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.image,
                                  color: theme.disabledColor,
                                ),
                              ),
                      ),

                      // BOUTON FAVORI
                      if (!modeSelection)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              onTap: onRetirerFavori,
                              customBorder: const CircleBorder(),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // INFOS
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favori.nomProduit,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${favori.prix.toStringAsFixed(0)} FCFA',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (favori.nomBoutique != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.store,
                              size: 12,
                              color: theme.disabledColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                favori.nomBoutique!,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // OVERLAY SÉLECTION
            if (modeSelection)
              Positioned.fill(
                child: Container(
                  color: estSelectionne ? theme.primaryColor.withValues(alpha: 0.3) : Colors.transparent,
                  child: estSelectionne
                      ? Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
