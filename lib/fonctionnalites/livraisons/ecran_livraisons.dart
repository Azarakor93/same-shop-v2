// ===============================================
// 🚚 LIVRAISONS (PDF SAME Shop)
// ===============================================
// Carte GPS + Demandes spéciales 25 FCFA

import 'package:flutter/material.dart';

class EcranLivraisons extends StatelessWidget {
  const EcranLivraisons({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Livraisons',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Carte GPS et demandes spéciales (25 FCFA)\nseront disponibles ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
