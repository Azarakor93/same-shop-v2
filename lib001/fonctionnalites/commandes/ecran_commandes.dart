import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/commande.dart';
import 'services/service_commandes_supabase.dart';

class EcranCommandes extends StatelessWidget {
  const EcranCommandes({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes commandes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Client'),
            ],
          ),
        ),
        body: user == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Connectez-vous pour voir vos commandes.'),
                ),
              )
            : const TabBarView(
                children: [
                  _OngletCommandesClient(),
                ],
              ),
      ),
    );
  }
}

class _OngletCommandesClient extends StatefulWidget {
  const _OngletCommandesClient();

  @override
  State<_OngletCommandesClient> createState() => _OngletCommandesClientState();
}

class _OngletCommandesClientState extends State<_OngletCommandesClient> {
  final _service = ServiceCommandesSupabase();
  late Future<List<Commande>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listerMesCommandes();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.listerMesCommandes();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Commande>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Erreur: ${snapshot.error}'),
            ),
          );
        }

        final items = snapshot.data ?? const <Commande>[];
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long,
                      size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune commande',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Les commandes passées s’afficheront ici.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final c = items[index];
              return _CarteCommande(commande: c);
            },
          ),
        );
      },
    );
  }
}

class _CarteCommande extends StatelessWidget {
  final Commande commande;

  const _CarteCommande({required this.commande});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final date = commande.createdAt;
    final dateTexte =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    final badgeCouleur = switch (commande.statut) {
      'livree' => Colors.green,
      'en_preparation' => Colors.orange,
      'expediee' => Colors.blue,
      'annulee' => Colors.red,
      _ => cs.secondary,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${commande.id.substring(0, 8)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeCouleur.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    commande.statut,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeCouleur,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  dateTexte,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Total: ${commande.total} FCFA',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
            if (commande.adresseTexte != null &&
                commande.adresseTexte!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                commande.adresseTexte!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
