// ===============================================
// 📦 TAB FOURNISSEURS - ANNONCES MULTI-PRODUITS
// ===============================================
import 'package:flutter/material.dart';
import '../models/demande_fournisseur.dart';
import '../services/service_fournisseurs_supabase.dart';
import 'ecran_details_demande_fournisseur.dart';

class TabFournisseurs extends StatefulWidget {
  const TabFournisseurs({super.key});

  @override
  State<TabFournisseurs> createState() => _TabFournisseursState();
}

class _TabFournisseursState extends State<TabFournisseurs> {
  final ServiceFournisseursSupabase _service = ServiceFournisseursSupabase();
  List<DemandeFournisseur> _demandes = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerDemandes();
  }

  Future<void> _chargerDemandes() async {
    setState(() => _chargement = true);
    final demandes = await _service.recupererDemandesActives();
    setState(() {
      _demandes = demandes;
      _chargement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _chargement
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : _demandes.isEmpty
              ? _buildVide(theme)
              : RefreshIndicator(
                  onRefresh: _chargerDemandes,
                  color: theme.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _demandes.length,
                    itemBuilder: (context, index) {
                      final demande = _demandes[index];
                      return _CarteDemandeFournisseur(
                        demande: demande,
                        onTap: () => _ouvrirDetails(demande),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creerDemande,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle demande'),
      ),
    );
  }

  Widget _buildVide(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 80,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune demande active',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première demande',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _creerDemande,
            icon: const Icon(Icons.add),
            label: const Text('Créer une demande'),
          ),
        ],
      ),
    );
  }

  void _creerDemande() async {
    // TODO: Récupérer la boutique de l'utilisateur
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Fonctionnalité en cours de développement\nVous devez avoir une boutique pour créer une demande'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _ouvrirDetails(DemandeFournisseur demande) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EcranDetailsDemandeFournisseur(demande: demande),
      ),
    );
  }
}

// ===============================================
// 🎴 CARTE DEMANDE FOURNISSEUR
// ===============================================
class _CarteDemandeFournisseur extends StatelessWidget {
  final DemandeFournisseur demande;
  final VoidCallback onTap;

  const _CarteDemandeFournisseur({
    required this.demande,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final joursRestants = demande.joursRestants;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  // ICÔNE
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: theme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // INFO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          demande.titre,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: theme.disabledColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${demande.ville}, ${demande.pays}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // BADGE TEMPS
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: joursRestants <= 2
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: joursRestants <= 2 ? Colors.red : Colors.orange,
                      ),
                    ),
                    child: Text(
                      joursRestants > 0 ? '$joursRestants j' : 'Expire bientôt',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: joursRestants <= 2 ? Colors.red : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // PRODUITS RECHERCHÉS
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 16,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Produits recherchés (${demande.produits.length})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...demande.produits.take(3).map((produit) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Text('•', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                produit['nom'],
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'Qté: ${produit['quantite']}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (demande.produits.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+${demande.produits.length - 3} autre(s)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.primaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // BUDGET + RÉPONSES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // BUDGET
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.disabledColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${demande.budgetTotal.toStringAsFixed(0)} FCFA',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),

                  // RÉPONSES
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.comment_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${demande.nombreReponses} réponses',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
