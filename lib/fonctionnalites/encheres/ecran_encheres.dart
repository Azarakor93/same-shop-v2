// ===============================================
// 🔨 ENCHÈRES ENTREPRISES (PDF SAME Shop)
// ===============================================
// En cours + Mes gains — Abonnement 30 000 FCFA illimité

import 'package:flutter/material.dart';

class EcranEncheres extends StatelessWidget {
  const EcranEncheres({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'En cours'),
                Tab(text: 'Mes gains'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ListeEncheresVide(
                  icon: Icons.gavel,
                  message: 'Aucune enchère en cours.',
                  detail: 'Les enchères entreprises apparaîtront ici.',
                ),
                _ListeEncheresVide(
                  icon: Icons.emoji_events_outlined,
                  message: 'Aucun gain pour le moment.',
                  detail: 'Vos enchères gagnées s\'afficheront ici.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListeEncheresVide extends StatelessWidget {
  final IconData icon;
  final String message;
  final String detail;

  const _ListeEncheresVide({
    required this.icon,
    required this.message,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
