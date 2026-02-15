// ===============================================
// 📋 TAB APERÇU BOUTIQUE
// ===============================================
import 'package:flutter/material.dart';
import '../../models/boutique.dart';
import '../ecran_modifier_boutique.dart';
import '../../../fournisseurs/views/ecran_creer_demande_fournisseur.dart';

// Import nécessaire pour TypeAbonnement
export '../../models/boutique.dart';

class TabApercuBoutique extends StatelessWidget {
  final Boutique boutique;

  const TabApercuBoutique({
    super.key,
    required this.boutique,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Rafraîchir les données
      },
      color: theme.primaryColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // CARTE INFO BOUTIQUE
          _buildCarteInfos(context, theme),
          const SizedBox(height: 16),

          // STATISTIQUES RAPIDES
          _buildStatistiquesRapides(theme),
          const SizedBox(height: 16),

          // RECHERCHE FOURNISSEURS
          _buildCarteFournisseurs(context, theme),
          const SizedBox(height: 16),

          // ACTIONS RAPIDES
          _buildActionsRapides(context, theme),
        ],
      ),
    );
  }

  Widget _buildCarteInfos(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.store,
                  color: theme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations de la boutique',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gérez les informations de votre boutique',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EcranModifierBoutique(
                          boutique: boutique,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // DESCRIPTION
            if (boutique.description != null) ...[
              _buildInfoRow(
                theme,
                icon: Icons.description,
                label: 'Description',
                valeur: boutique.description!,
              ),
              const SizedBox(height: 12),
            ],

            // LOCALISATION
            _buildInfoRow(
              theme,
              icon: Icons.location_on,
              label: 'Localisation',
              valeur: '${boutique.ville}, ${boutique.pays}',
            ),
            const SizedBox(height: 12),

            // TYPE
            _buildInfoRow(
              theme,
              icon: Icons.business,
              label: 'Type',
              valeur: boutique.typeAbonnement == TypeAbonnement.entreprise
                  ? 'Entreprise (30 000 FCFA/mois)'
                  : boutique.typeAbonnement == TypeAbonnement.premium
                      ? 'Premium (5 000 FCFA/mois)'
                      : 'Gratuit',
            ),
            const SizedBox(height: 12),

            // STATUT
            _buildInfoRow(
              theme,
              icon: Icons.verified,
              label: 'Statut',
              valeur: boutique.estActif ? 'Active ✅' : 'Suspendue ❌',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String valeur,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.disabledColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valeur,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatistiquesRapides(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            icon: Icons.inventory_2,
            label: 'Produits',
            valeur: '12',
            couleur: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            icon: Icons.shopping_cart,
            label: 'Commandes',
            valeur: '45',
            couleur: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            icon: Icons.visibility,
            label: 'Vues',
            valeur: '1.2K',
            couleur: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String valeur,
    required Color couleur,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: couleur,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              valeur,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: couleur,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarteFournisseurs(BuildContext context, ThemeData theme) {
    return Card(
      color: theme.primaryColor.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.business_center,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recherche fournisseurs',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '2 000 FCFA pour 7 jours',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Créez une annonce pour trouver des fournisseurs de produits en gros. Votre demande sera visible par toutes les boutiques pendant 7 jours.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EcranCreerDemandeFournisseur(
                        boutique: boutique,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Créer une demande'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsRapides(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          theme,
          icon: Icons.add_circle_outline,
          titre: 'Ajouter un produit',
          sousTitre: 'Ajoutez un nouveau produit à votre catalogue',
          onTap: () {
            // TODO: Ajouter produit
          },
        ),
        const SizedBox(height: 8),
        _buildActionTile(
          theme,
          icon: Icons.rocket_launch,
          titre: 'Booster un produit',
          sousTitre: 'Augmentez la visibilité de vos produits',
          onTap: () {
            // TODO: Booster produit
          },
        ),
        const SizedBox(height: 8),
        _buildActionTile(
          theme,
          icon: Icons.gavel,
          titre: 'Créer une enchère',
          sousTitre: 'Organisez une vente aux enchères (Entreprise)',
          onTap: () {
            if (boutique.typeAbonnement != TypeAbonnement.entreprise) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Réservé aux comptes Entreprise'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            // TODO: Créer enchère
          },
        ),
      ],
    );
  }

  Widget _buildActionTile(
    ThemeData theme, {
    required IconData icon,
    required String titre,
    required String sousTitre,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          titre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(sousTitre),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
