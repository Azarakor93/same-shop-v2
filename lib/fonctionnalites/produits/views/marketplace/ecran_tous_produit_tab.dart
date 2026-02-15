// ===============================================
// 🛍️ TAB PRODUITS - GRID 2 COLONNES + PAGINATION
// ===============================================
import 'package:flutter/material.dart';
import '../../models/produit.dart';
import '../../services/service_produit_supabase.dart';
import 'ecran_produit_card.dart'; // Votre card existante

class TousProduitsTab extends StatefulWidget {
  const TousProduitsTab({super.key});

  @override
  State<TousProduitsTab> createState() => _TousProduitsTabState();
}

class _TousProduitsTabState extends State<TousProduitsTab> {
  final ServiceProduitSupabase _service = ServiceProduitSupabase();
  List<Produit> _produits = [];
  int _pageIndex = 0;
  final int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chargerPremierePage();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _chargerPremierePage() async {
    setState(() {
      _pageIndex = 0;
      _produits.clear();
      _isLoading = true;
      _hasMore = true;
    });

    try {
      final produits = await _service.listerProduitsPage(page: 0, pageSize: _pageSize);
      if (mounted) {
        setState(() {
          _produits = produits;
          _hasMore = produits.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _chargerPageSuivante() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final nouveauxProduits = await _service.listerProduitsPage(
        page: ++_pageIndex,
        pageSize: _pageSize,
      );
      if (mounted) {
        setState(() {
          _produits.addAll(nouveauxProduits);
          _hasMore = nouveauxProduits.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        _chargerPageSuivante();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _chargerPremierePage,
      child: _produits.isEmpty && !_isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: theme.disabledColor.withValues(alpha: 0.5)),
                  SizedBox(height: 16),
                  Text('Aucun produit trouvé', style: theme.textTheme.titleLarge),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _chargerPremierePage,
                    icon: Icon(Icons.refresh),
                    label: Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 280, // Hauteur fixe pour chaque carte
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _produits.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _produits.length) {
                  return Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                        ),
                        SizedBox(height: 8),
                        Text('Chargement...', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  );
                }

                return ProduitGridCard(
                  produit: _produits[index],
                  service: _service,
                );
              },
            ),
    );
  }
}
