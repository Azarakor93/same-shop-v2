// ===============================================
// 📊 TAB STATISTIQUES BOUTIQUE
// ===============================================
import 'package:flutter/material.dart';
import '../../models/boutique.dart';

class TabStatsBoutique extends StatefulWidget {
  final Boutique boutique;

  const TabStatsBoutique({
    super.key,
    required this.boutique,
  });

  @override
  State<TabStatsBoutique> createState() => _TabStatsBoutiqueState();
}

class _TabStatsBoutiqueState extends State<TabStatsBoutique> {
  String _periodeSelectionnee = '7j';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // SÉLECTEUR PÉRIODE
        _buildSelecteurPeriode(theme),
        const SizedBox(height: 20),

        // CHIFFRE D'AFFAIRES
        _buildCarteCA(theme),
        const SizedBox(height: 16),

        // PRODUITS POPULAIRES
        _buildCarteProduits(theme),
        const SizedBox(height: 16),

        // PERFORMANCES
        _buildCartePerformances(theme),
      ],
    );
  }

  Widget _buildSelecteurPeriode(ThemeData theme) {
    return Row(
      children: [
        Text(
          'Période :',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: [
              _buildChipPeriode(theme, '7j', '7 jours'),
              _buildChipPeriode(theme, '30j', '30 jours'),
              _buildChipPeriode(theme, '3m', '3 mois'),
              _buildChipPeriode(theme, 'annee', 'Année'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChipPeriode(ThemeData theme, String id, String label) {
    final actif = _periodeSelectionnee == id;

    return ChoiceChip(
      label: Text(label),
      selected: actif,
      onSelected: (selected) {
        setState(() => _periodeSelectionnee = id);
      },
      selectedColor: theme.primaryColor,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: actif ? Colors.white : theme.textTheme.bodyMedium?.color,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }

  Widget _buildCarteCA(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payments,
                  color: theme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Chiffre d\'affaires',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '125 000 FCFA',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '+12% vs période précédente',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(theme, '45', 'Commandes'),
                _buildStatItem(theme, '38', 'Produits vendus'),
                _buildStatItem(theme, '2.8K', 'Vues'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String valeur, String label) {
    return Column(
      children: [
        Text(
          valeur,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildCarteProduits(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Produits les plus vus',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProduitStatItem(theme, '1', 'iPhone 15 Pro', '450', '28'),
            const SizedBox(height: 12),
            _buildProduitStatItem(theme, '2', 'Samsung Galaxy S24', '320', '19'),
            const SizedBox(height: 12),
            _buildProduitStatItem(theme, '3', 'MacBook Pro M3', '280', '15'),
          ],
        ),
      ),
    );
  }

  Widget _buildProduitStatItem(
    ThemeData theme,
    String rang,
    String nom,
    String vues,
    String ventes,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: rang == '1'
                ? Colors.amber
                : rang == '2'
                    ? Colors.grey.shade400
                    : Colors.brown.shade400,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              rang,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            nom,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$vues vues',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '$ventes ventes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCartePerformances(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed,
                  color: theme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Performances',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPerformanceItem(theme, 'Taux de conversion', 0.65, '6.5%'),
            const SizedBox(height: 12),
            _buildPerformanceItem(theme, 'Panier moyen', 0.8, '28 500 FCFA'),
            const SizedBox(height: 12),
            _buildPerformanceItem(theme, 'Satisfaction client', 0.92, '4.6/5'),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(
    ThemeData theme,
    String label,
    double progression,
    String valeur,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              valeur,
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progression,
          backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
          color: theme.primaryColor,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}
