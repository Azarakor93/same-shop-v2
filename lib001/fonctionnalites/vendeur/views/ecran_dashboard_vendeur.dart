// ===============================================
// 📊 ÉCRAN DASHBOARD VENDEUR - AVEC PRODUITS
// ===============================================
// Tableau de bord complet pour gérer une boutique
// avec gestion des produits intégrée

import 'package:flutter/material.dart';
import '../models/boutique.dart';
import 'ecran_modifier_boutique.dart';
import '../../produits/views/ecran_liste_produits.dart';
import '../../produits/services/service_produit_supabase.dart';
import '../../fournisseurs/views/ecran_fournisseurs.dart';

class EcranDashboardVendeur extends StatefulWidget {
  final Boutique boutique;

  const EcranDashboardVendeur({
    super.key,
    required this.boutique,
  });

  @override
  State<EcranDashboardVendeur> createState() => _EcranDashboardVendeurState();
}

class _EcranDashboardVendeurState extends State<EcranDashboardVendeur> {
  int _selectedIndex = 0;
  late Boutique _boutique;

  @override
  void initState() {
    super.initState();
    _boutique = widget.boutique;
  }

  // ===============================================
  // ✏️ MODIFIER LA BOUTIQUE
  // ===============================================
  Future<void> _modifierBoutique() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EcranModifierBoutique(boutique: _boutique),
      ),
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Boutique mise à jour'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ===============================================
  // 📱 PAGES DU DASHBOARD
  // ===============================================
  late final List<Widget> _pages = [
    _PageApercu(boutique: _boutique, onModifier: _modifierBoutique),
    _PageProduits(boutique: _boutique), // ✅ Nouvelle version
    _PageCommandes(boutique: _boutique),
    _PageStatistiques(boutique: _boutique),
  ];

  // ===============================================
  // 🎨 BUILD UI
  // ===============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _boutique.nomBoutique,
              style: const TextStyle(fontSize: 18),
            ),
            if (_boutique.estPremium)
              const Row(
                children: [
                  Icon(Icons.workspace_premium, size: 14, color: Colors.amber),
                  SizedBox(width: 4),
                  Text(
                    'Premium',
                    style: TextStyle(fontSize: 12, color: Colors.amber),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _modifierBoutique,
            tooltip: 'Modifier',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _afficherMenuOptions(context),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Aperçu',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_outlined),
            selectedIcon: Icon(Icons.inventory),
            label: 'Produits',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Commandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Stats',
          ),
        ],
      ),
    );
  }

  void _afficherMenuOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Modifier les informations'),
                onTap: () {
                  Navigator.pop(context);
                  _modifierBoutique();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Partager'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Paramètres'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              if (!_boutique.estPremium)
                ListTile(
                  leading:
                      const Icon(Icons.workspace_premium, color: Colors.amber),
                  title: const Text('Passer au Premium'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmerSuppression(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _confirmerSuppression(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la boutique ?'),
          content: const Text(
            'Cette action est irréversible. Toutes les données seront perdues.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }
}

// ===============================================
// 📊 PAGE APERÇU
// ===============================================
class _PageApercu extends StatelessWidget {
  final Boutique boutique;
  final VoidCallback onModifier;

  const _PageApercu({
    required this.boutique,
    required this.onModifier,
  });

  @override
  Widget build(BuildContext context) {
    final serviceProduit = ServiceProduitSupabase();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: ListTile(
            leading: Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text(
              'Modifier les informations',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Nom, description, téléphone, adresse...'),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: onModifier,
          ),
        ),

        const SizedBox(height: 4),

        Card(
          child: ListTile(
            leading: const Icon(Icons.search),
            title: const Text(
              'Rechercher des fournisseurs',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('2 000 FCFA • annonce 7 jours'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EcranFournisseurs(boutique: boutique),
                ),
              );
            },
          ),
        ),

        // Stats rapides avec données réelles
        FutureBuilder<int>(
          future: serviceProduit.nombreProduitsVendeur(boutique.id),
          builder: (context, snapshot) {
            final nombreProduits = snapshot.data ?? 0;

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: Icons.inventory,
                        titre: 'Produits',
                        valeur: nombreProduits.toString(),
                        couleur: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: Icons.shopping_cart,
                        titre: 'Commandes',
                        valeur: '0',
                        couleur: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: Icons.visibility,
                        titre: 'Vues',
                        valeur: '0',
                        couleur: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: Icons.star,
                        titre: 'Note',
                        valeur: '0',
                        couleur: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 6),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Informations',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: onModifier,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.phone, 'Téléphone', boutique.telephone),
                const Divider(height: 24),
                _buildInfoRow(
                    Icons.location_on, 'Adresse', boutique.adresseComplete),
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.workspace_premium,
                  'Abonnement',
                  boutique.typeAbonnement.label,
                ),
                if (boutique.description != null &&
                    boutique.description!.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildInfoRow(
                      Icons.description, 'Description', boutique.description!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String titre,
    required String valeur,
    required Color couleur,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: couleur, size: 32),
            const SizedBox(height: 8),
            Text(
              valeur,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              titre,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===============================================
// 📦 PAGE PRODUITS - INTÉGRÉE ✅
// ===============================================
class _PageProduits extends StatelessWidget {
  final Boutique boutique;

  const _PageProduits({required this.boutique});

  @override
  Widget build(BuildContext context) {
    // ✅ REMPLACE LA PAGE VIDE PAR LA VRAIE LISTE
    return EcranListeProduits(boutique: boutique);
  }
}

// ===============================================
// 🛒 PAGE COMMANDES
// ===============================================
class _PageCommandes extends StatelessWidget {
  final Boutique boutique;

  const _PageCommandes({required this.boutique});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Aucune commande'),
        ],
      ),
    );
  }
}

// ===============================================
// 📈 PAGE STATISTIQUES
// ===============================================
class _PageStatistiques extends StatelessWidget {
  final Boutique boutique;

  const _PageStatistiques({required this.boutique});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Statistiques disponibles bientôt'),
        ],
      ),
    );
  }
}
