import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EcranSuperAdmin extends StatefulWidget {
  const EcranSuperAdmin({super.key});

  @override
  State<EcranSuperAdmin> createState() => _EcranSuperAdminState();
}

class _EcranSuperAdminState extends State<EcranSuperAdmin> {
  final _client = Supabase.instance.client;

  Future<_StatsGlobales> _chargerStats() async {
    try {
      final produits = await _client
          .from('produits')
          .select('id')
          .count(CountOption.exact);
      final vendeurs = await _client
          .from('vendeurs')
          .select('id')
          .count(CountOption.exact);
      final encheres = await _client
          .from('encheres')
          .select('id')
          .count(CountOption.exact);
      final demandesFournisseurs = await _client
          .from('demandes_fournisseurs')
          .select('id')
          .count(CountOption.exact);

      final tx = await _client
          .from('transactions')
          .select('montant, statut')
          .eq('statut', 'valide');
      final txList = (tx as List).cast<Map<String, dynamic>>();
      final caTotal = txList.fold<int>(0,
          (sum, t) => sum + ((t['montant'] as num?)?.toInt() ?? 0));

      return _StatsGlobales(
        nombreProduits: produits.count,
        nombreVendeurs: vendeurs.count,
        nombreEncheres: encheres.count,
        nombreDemandesFournisseurs: demandesFournisseurs.count,
        caTotal: caTotal,
      );
    } catch (_) {
      return const _StatsGlobales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Super Admin'),
        centerTitle: true,
      ),
      body: FutureBuilder<_StatsGlobales>(
        future: _chargerStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snapshot.data ?? const _StatsGlobales();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Vue d’ensemble',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _carteStat(
                    context,
                    icone: Icons.payments_outlined,
                    couleur: Colors.green,
                    titre: 'CA total',
                    valeur: '${stats.caTotal} FCFA',
                  ),
                  _carteStat(
                    context,
                    icone: Icons.storefront_outlined,
                    couleur: Colors.blue,
                    titre: 'Boutiques',
                    valeur: stats.nombreVendeurs.toString(),
                  ),
                  _carteStat(
                    context,
                    icone: Icons.inventory_2_outlined,
                    couleur: Colors.deepPurple,
                    titre: 'Produits',
                    valeur: stats.nombreProduits.toString(),
                  ),
                  _carteStat(
                    context,
                    icone: Icons.gavel_outlined,
                    couleur: Colors.orange,
                    titre: 'Enchères',
                    valeur: stats.nombreEncheres.toString(),
                  ),
                  _carteStat(
                    context,
                    icone: Icons.search_outlined,
                    couleur: Colors.teal,
                    titre: 'Demandes fournisseurs',
                    valeur: stats.nombreDemandesFournisseurs.toString(),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _carteStat(
    BuildContext context, {
    required IconData icone,
    required Color couleur,
    required String titre,
    required String valeur,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 24,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, color: couleur),
              ),
              const SizedBox(height: 10),
              Text(
                valeur,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                titre,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGlobales {
  final int nombreProduits;
  final int nombreVendeurs;
  final int nombreEncheres;
  final int nombreDemandesFournisseurs;
  final int caTotal;

  const _StatsGlobales({
    this.nombreProduits = 0,
    this.nombreVendeurs = 0,
    this.nombreEncheres = 0,
    this.nombreDemandesFournisseurs = 0,
    this.caTotal = 0,
  });
}
