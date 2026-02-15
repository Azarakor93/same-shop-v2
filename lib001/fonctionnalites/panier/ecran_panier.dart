import 'package:flutter/material.dart';

import '../commandes/services/service_commandes_supabase.dart';
import 'models/panier_ligne.dart';
import 'services/service_panier_local.dart';

class EcranPanier extends StatefulWidget {
  const EcranPanier({super.key});

  @override
  State<EcranPanier> createState() => _EcranPanierState();
}

class _EcranPanierState extends State<EcranPanier> {
  final _service = ServicePanierLocal();
  final _serviceCommandes = ServiceCommandesSupabase();
  bool _init = false;

  @override
  void initState() {
    super.initState();
    _service.initialiser().then((_) {
      if (!mounted) return;
      setState(() => _init = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panier'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              await _service.vider();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Panier vidé')),
              );
            },
            child: const Text('Vider'),
          ),
        ],
      ),
      body: !_init
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<List<PanierLigne>>(
              valueListenable: _service.panier,
              builder: (context, items, _) {
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              size: 72, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Votre panier est vide',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ajoutez des produits pour passer commande.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _CartePanier(
                      item: item,
                      onMoins: () => _service.decrementer(item.cle),
                      onPlus: () => _service.incrementer(item.cle),
                      onSupprimer: () => _service.supprimer(item.cle),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: ValueListenableBuilder<List<PanierLigne>>(
          valueListenable: _service.panier,
          builder: (context, items, _) {
            if (!_init || items.isEmpty) return const SizedBox.shrink();
            final total = _service.total;
            final nb = _service.nombreArticles;

            return Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$nb article(s)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$total FCFA',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      final lignes = List<PanierLigne>.from(items);
                      try {
                        final commandeId =
                            await _serviceCommandes.creerCommandeDepuisPanier(
                          lignes: lignes,
                        );
                        await _service.vider();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Commande $commandeId créée avec succès.'),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Valider'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CartePanier extends StatelessWidget {
  final PanierLigne item;
  final VoidCallback onMoins;
  final VoidCallback onPlus;
  final VoidCallback onSupprimer;

  const _CartePanier({
    required this.item,
    required this.onMoins,
    required this.onPlus,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 78,
                height: 78,
                color: cs.surfaceContainerHighest,
                child: item.imageUrl == null
                    ? Icon(Icons.image_not_supported,
                        color: cs.onSurfaceVariant)
                    : Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image_not_supported,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nom,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (item.taille != null && item.taille!.trim().isNotEmpty)
                        _chip(context, 'Taille: ${item.taille}'),
                      if (item.couleur != null && item.couleur!.trim().isNotEmpty)
                        _chip(context, 'Couleur: ${item.couleur}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${item.prixUnitaire} FCFA',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Supprimer',
                        onPressed: onSupprimer,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: onMoins,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(40, 36),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.remove, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${item.quantite}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: onPlus,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(40, 36),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.add, size: 18),
                      ),
                      const Spacer(),
                      Text(
                        'Total: ${item.total} FCFA',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant,
                        ),
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

  Widget _chip(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: cs.secondary,
        ),
      ),
    );
  }
}
