// ===============================================
// 📊 DASHBOARD VENDEUR MODERNE - 4 TABS
// ===============================================
import 'package:flutter/material.dart';
import 'tabs/tab_apercu_boutique.dart';
import 'tabs/tab_produits_boutique.dart';
import 'tabs/tab_commandes_boutique.dart';
import 'tabs/tab_stats_boutique.dart';

class DashboardVendeurModerne extends StatefulWidget {
  final Boutique boutique;

  const DashboardVendeurModerne({
    super.key,
    required this.boutique,
  });

  @override
  State<DashboardVendeurModerne> createState() => _DashboardVendeurModerneState();
}

class _DashboardVendeurModerneState extends State<DashboardVendeurModerne> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.boutique.nomBoutique,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.boutique.typeAbonnement == TypeAbonnement.entreprise ? '🏢 Entreprise' : '👤 Particulier',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          // PARTAGER
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Partager boutique
            },
          ),
          // CARTE
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              // TODO: Ouvrir carte
            },
          ),
          // MENU
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'modifier':
                  // TODO: Modifier boutique
                  break;
                case 'abonnement':
                  // TODO: Gérer abonnement
                  break;
                case 'desactiver':
                  // TODO: Désactiver boutique
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'modifier',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 12),
                    Text('Modifier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'abonnement',
                child: Row(
                  children: [
                    Icon(Icons.card_membership, size: 20),
                    SizedBox(width: 12),
                    Text('Abonnement'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'desactiver',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Désactiver', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.disabledColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard_outlined, size: 20),
              text: 'Aperçu',
            ),
            Tab(
              icon: Icon(Icons.inventory_2_outlined, size: 20),
              text: 'Produits',
            ),
            Tab(
              icon: Icon(Icons.shopping_cart_outlined, size: 20),
              text: 'Commandes',
            ),
            Tab(
              icon: Icon(Icons.bar_chart, size: 20),
              text: 'Stats',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TabApercuBoutique(boutique: widget.boutique),
          TabProduitsBoutique(boutique: widget.boutique),
          TabCommandesBoutique(boutique: widget.boutique),
          TabStatsBoutique(boutique: widget.boutique),
        ],
      ),
    );
  }
}
