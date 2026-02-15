// ===============================================
// 🛒 ECRAN MARKETPLACE - SANS APPBAR (CONTENU SEUL)
// ===============================================
import 'package:flutter/material.dart';
import 'ecran_tous_produit_tab.dart';
import '../../../encheres/views/tab_encheres.dart';
import '../../../fournisseurs/views/tab_fournisseurs.dart';
import '../../../favoris/tab_favoris.dart';

class EcranMarketplace extends StatefulWidget {
  const EcranMarketplace({super.key});

  @override
  State<EcranMarketplace> createState() => _EcranMarketplaceState();
}

class _EcranMarketplaceState extends State<EcranMarketplace> with TickerProviderStateMixin {
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

    return Column(
      children: [
        // 🔥 BARRE TABS SEULE (PAS D'APPBAR)
        Container(
          color: theme.cardColor,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TabBar(
            controller: _tabController,
            indicatorColor: theme.primaryColor,
            labelColor: theme.primaryColor,
            unselectedLabelColor: theme.disabledColor.withValues(alpha: 0.7),
            indicatorWeight: 3,
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.apps), text: 'Tous'),
              Tab(icon: Icon(Icons.gavel), text: 'Enchères'),
              Tab(icon: Icon(Icons.business), text: 'Fournisseurs'),
              Tab(icon: Icon(Icons.favorite_border), text: 'Favoris'),
            ],
          ),
        ),

        // 📱 CONTENU TABS
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              TousProduitsTab(),
              TabEncheres(),
              TabFournisseurs(),
              TabFavoris(),
            ],
          ),
        ),
      ],
    );
  }
}
