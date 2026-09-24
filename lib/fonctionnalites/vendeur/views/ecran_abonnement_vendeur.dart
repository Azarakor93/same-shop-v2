import 'package:flutter/material.dart';

class EcranAbonnementVendeur extends StatelessWidget {
  const EcranAbonnementVendeur({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Abonnement requis')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.lock, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Vous avez déjà une boutique.\n'
              'Pour en créer une autre, vous devez souscrire '
              'à un abonnement de 5 000 FCFA.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text('Payer via T-Money / Flooz'),
              onPressed: () {
                // Paiement plus tard
              },
            )
          ],
        ),
      ),
    );
  }
}
