// ===============================================
// 🛡️ GUARD VENDEUR
// ===============================================
// Routeur intelligent qui dirige l'utilisateur
// vers le bon écran selon son nombre de boutiques

import 'package:flutter/material.dart';
import 'services/service_vendeur_supabase.dart';
import 'views/ecran_creation_boutique.dart';
import 'views/ecran_liste_boutiques.dart';

class GuardVendeur extends StatelessWidget {
  const GuardVendeur({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ServiceVendeurSupabase();

    return FutureBuilder<int>(
      future: service.nombreBoutiques(),
      builder: (context, snapshot) {
        // ===============================================
        // ⏳ CHARGEMENT
        // ===============================================
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement de votre espace vendeur...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        // ===============================================
        // ❌ ERREUR
        // ===============================================
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Une erreur est survenue',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Recharger la page
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const GuardVendeur(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ===============================================
        // 🎯 ROUTAGE INTELLIGENT
        // ===============================================
        final nombreBoutiques = snapshot.data ?? 0;

        // 📌 Aucune boutique → Création gratuite
        if (nombreBoutiques == 0) {
          return const EcranCreationBoutique(
            estPremiere: true,
          );
        }

        // 📌 1+ boutique → Liste des boutiques
        return const EcranListeBoutiques();
      },
    );
  }
}
