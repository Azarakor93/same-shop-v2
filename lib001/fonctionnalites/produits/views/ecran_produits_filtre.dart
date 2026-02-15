import 'package:flutter/material.dart';

import '../models/produit.dart';
import '../services/service_produit_supabase.dart';

/// 🛒 Écran liste produits pour les clients (avec filtres simples)
class EcranProduitsFiltres extends StatefulWidget {
  final String? categorieId;
  final String? categorieLabel;

  const EcranProduitsFiltres({
    super.key,
    this.categorieId,
    this.categorieLabel,
  });

  @override
  State<EcranProduitsFiltres> createState() => _EcranProduitsFiltresState();
}

class _EcranProduitsFiltresState extends State<EcranProduitsFiltres> {
  final _service = ServiceProduitSupabase();
  late Future<List<Produit>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listerProduitsMarketplace(
      categorieId: widget.categorieId,
      limit: 60,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.listerProduitsMarketplace(
        categorieId: widget.categorieId,
        limit: 60,
      );
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categorieLabel ?? 'Produits',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<List<Produit>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Impossible de charger les produits.',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          final items = snapshot.data ?? const <Produit>[];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun produit trouvé',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modifiez vos filtres pour élargir la recherche.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.7,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final p = items[index];
                return _carteProduit(context, p);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _carteProduit(BuildContext context, Produit produit) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              produit.nom,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${produit.prix} FCFA',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

