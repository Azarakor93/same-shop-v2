// ===============================================
// 🏠 PAGE ACCUEIL - Catalogue + Annonces + Recherche
// ===============================================
// Aligné PDF SAME Shop : Accueil = Catalogue + Enchères phares + BOOSTS

import 'package:flutter/material.dart';
// import '../services/supabase_annonce_service.dart';
// import '../models/annonces.dart';
// import '../widgets/slider_annonces.dart';
// import '../widgets/champ_recherche_marketplace.dart';
import '../../produits/views/ecran_liste_produits.dart';
import '../../vendeur/guard_vendeur.dart';
import '../../vendeur/services/service_vendeur_supabase.dart';
import '../../panier/ecran_panier.dart';
import '../../commandes/ecran_commandes.dart';
import '../../profil/ecran_profil.dart';
import '../../livraisons/ecran_livraisons.dart';

class PageAccueil extends StatefulWidget {
  const PageAccueil({super.key});

  @override
  State<PageAccueil> createState() => _PageAccueilState();
}

class _PageAccueilState extends State<PageAccueil> {
  final _rechercheCtrl = TextEditingController();
  // final _annonceService = SupabaseAnnonceService();

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    super.dispose();
  }

  void _ouvrirCatalogue() {
    // Catalogue global : on pourrait passer une "boutique virtuelle" ou lister tous les produits
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EcranCatalogueAccueil(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // SliverToBoxAdapter(
        //   child: Padding(
        //     padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        //     child: ChampRechercheMarketplace(
        //       controller: _rechercheCtrl,
        //       onFiltre: () {},
        //       onChanged: (_) {},
        //     ),
        //   ),
        // ),
        // SliverToBoxAdapter(
        //   child: FutureBuilder<List<Annonce>>(
        //     future: _annonceService.chargerAnnonces(),
        //     builder: (context, snapshot) {
        //       if (snapshot.hasData && snapshot.data!.isNotEmpty) {
        //         return Padding(
        //           padding: const EdgeInsets.symmetric(horizontal: 12),
        //           child: SliderAnnonces(annonces: snapshot.data!),
        //         );
        //       }
        //       return const SizedBox.shrink();
        //     },
        //   ),
        // ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Explorer',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.storefront,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: const Text('Catalogue produits'),
                    subtitle: const Text('Parcourir toutes les boutiques'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _ouvrirCatalogue,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.add_business,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: const Text('Ma boutique'),
                    subtitle: const Text('Gérer mes boutiques et produits'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const GuardVendeur(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: const Text('Panier'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EcranPanier(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.receipt_long,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: const Text('Mes commandes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EcranCommandes(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.local_shipping_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: const Text('Livraisons'),
                    subtitle:
                        const Text('Carte GPS • Demandes spéciales 25 FCFA'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EcranLivraisons(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person_outline,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: const Text('Mon profil'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EcranProfil(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Catalogue simplifié depuis l'accueil (liste produits globale à venir)
class EcranCatalogueAccueil extends StatelessWidget {
  const EcranCatalogueAccueil({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ServiceVendeurSupabase().listerToutesBoutiques(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final boutiques = snapshot.data ?? [];
        if (boutiques.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Catalogue')),
            body: const Center(
              child: Text('Aucune boutique pour le moment.'),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Catalogue')),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: boutiques.length,
            itemBuilder: (context, index) {
              final b = boutiques[index];
              return Card(
                child: ListTile(
                  title: Text(b.nomBoutique),
                  subtitle: Text(b.adresseComplete),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EcranListeProduits(boutique: b),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
