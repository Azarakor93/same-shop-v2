// ===============================================
// 🛒 TAB COMMANDES BOUTIQUE
// ===============================================
import 'package:flutter/material.dart';
import '../../models/boutique.dart';

class TabCommandesBoutique extends StatefulWidget {
  final Boutique boutique;

  const TabCommandesBoutique({
    super.key,
    required this.boutique,
  });

  @override
  State<TabCommandesBoutique> createState() => _TabCommandesBoutiqueState();
}

class _TabCommandesBoutiqueState extends State<TabCommandesBoutique> {
  String _filtreStatut = 'tous';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // FILTRES STATUT
        _buildFiltresStatut(theme),

        // LISTE COMMANDES
        Expanded(
          child: _buildListeCommandes(theme),
        ),
      ],
    );
  }

  Widget _buildFiltresStatut(ThemeData theme) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChipStatut(theme, 'tous', 'Toutes', Icons.all_inbox),
          const SizedBox(width: 8),
          _buildChipStatut(theme, 'en_attente', 'En attente', Icons.hourglass_empty),
          const SizedBox(width: 8),
          _buildChipStatut(theme, 'confirmee', 'Confirmées', Icons.check_circle_outline),
          const SizedBox(width: 8),
          _buildChipStatut(theme, 'en_cours', 'En cours', Icons.local_shipping),
          const SizedBox(width: 8),
          _buildChipStatut(theme, 'livree', 'Livrées', Icons.done_all),
          const SizedBox(width: 8),
          _buildChipStatut(theme, 'annulee', 'Annulées', Icons.cancel),
        ],
      ),
    );
  }

  Widget _buildChipStatut(
    ThemeData theme,
    String statut,
    String label,
    IconData icon,
  ) {
    final actif = _filtreStatut == statut;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: actif ? Colors.white : theme.textTheme.bodyMedium?.color,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: actif,
      onSelected: (selected) {
        setState(() => _filtreStatut = statut);
      },
      selectedColor: theme.primaryColor,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: actif ? Colors.white : theme.textTheme.bodyMedium?.color,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  Widget _buildListeCommandes(ThemeData theme) {
    // TODO: Charger vraies commandes
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune commande',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les commandes apparaîtront ici',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
