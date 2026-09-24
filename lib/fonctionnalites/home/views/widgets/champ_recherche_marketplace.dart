import 'package:flutter/material.dart';

class ChampRechercheMarketplace extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onFiltre;
  final ValueChanged<String> onChanged;

  const ChampRechercheMarketplace({
    super.key,
    required this.controller,
    required this.onFiltre,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          // 🔍 Icône recherche
          Icon(
            Icons.search,
            size: 20,
            color: cs.secondary,
          ),

          const SizedBox(width: 8),

          // 📝 Champ de recherche
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: cs.secondary,

              // 👉 occupe toute la hauteur
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.center,

              decoration: InputDecoration(
                hintText: 'Rechercher dans SAME SHOP',

                // 🔑 TEXTE HINT UN PEU PLUS PETIT
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13, // 👈 plus petit
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                ),

                // ✅ padding interne (clé du problème)
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),

                // 🟢 Bordure visible SANS focus
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: cs.secondary,
                    width: 1.2,
                  ),
                ),

                // 🟢 Bordure visible AVEC focus
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: cs.secondary,
                    width: 1.5,
                  ),
                ),

                // 🔕 pas de label flottant
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),

              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // 🧱 Séparateur
          Container(
            height: 20,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: cs.outlineVariant,
          ),

          // 🎛 Bouton filtre
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onFiltre,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    size: 18,
                    color: cs.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Filtre',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
