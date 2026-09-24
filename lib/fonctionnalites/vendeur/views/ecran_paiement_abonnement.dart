// ===============================================
// 💎 ÉCRAN ABONNEMENT PREMIUM
// ===============================================
// Écran pour souscrire au premium et créer
// une boutique supplémentaire (5000 FCFA)

import 'package:flutter/material.dart';
import '../services/service_vendeur_supabase.dart';
import 'ecran_creation_boutique.dart';

enum MoyenPaiement { tmoney, flooz }

class EcranAbonnementPremium extends StatefulWidget {
  const EcranAbonnementPremium({super.key});

  @override
  State<EcranAbonnementPremium> createState() => _EcranAbonnementPremiumState();
}

class _EcranAbonnementPremiumState extends State<EcranAbonnementPremium> {
  final _service = ServiceVendeurSupabase();

  MoyenPaiement _moyenSelectionne = MoyenPaiement.tmoney;
  bool _chargement = false;

  // ===============================================
  // 💳 INITIER LE PAIEMENT
  // ===============================================
  Future<void> _initierPaiement() async {
    setState(() => _chargement = true);

    try {
      // Créer la demande d'abonnement
      await _service.creerAbonnement(
        boutiqueId: _service.userId, // Temporary ID
        moyenPaiement: _moyenSelectionne == MoyenPaiement.tmoney ? 'tmoney' : 'flooz',
      );

      if (!mounted) return;

      // Afficher le succès
      _afficherMessage('✅ Paiement initié avec succès !');

      // TODO: Intégrer l'API de paiement réelle
      // Pour l'instant, on simule le succès et on redirige

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // Rediriger vers la création de boutique
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const EcranCreationBoutique(
            estPremiere: false,
          ),
        ),
      );
    } catch (e) {
      _afficherMessage(e.toString(), estErreur: true);
    } finally {
      if (mounted) {
        setState(() => _chargement = false);
      }
    }
  }

  // ===============================================
  // 💬 AFFICHER UN MESSAGE
  // ===============================================
  void _afficherMessage(String message, {bool estErreur = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: estErreur ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ===============================================
  // 🎨 BUILD UI
  // ===============================================
  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      // ===============================================
      // 📱 APP BAR
      // ===============================================
      appBar: AppBar(
        title: const Text('Abonnement Premium'),
        centerTitle: true,
        elevation: 0,
      ),

      // ===============================================
      // 📄 BODY
      // ===============================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===============================================
            // 👑 HEADER PREMIUM
            // ===============================================
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFD700),
                    Color(0xFFFFA500),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Passez au Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Créez des boutiques illimitées',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      '5 000 FCFA',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFA500),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ===============================================
            // ✨ AVANTAGES PREMIUM
            // ===============================================
            _buildSectionTitle('Avantages Premium'),
            const SizedBox(height: 16),

            _buildAvantage(
              icon: Icons.store,
              titre: 'Boutiques illimitées',
              description: 'Créez autant de boutiques que vous voulez',
            ),

            _buildAvantage(
              icon: Icons.analytics,
              titre: 'Statistiques avancées',
              description: 'Analysez vos performances en détail',
            ),

            _buildAvantage(
              icon: Icons.verified,
              titre: 'Badge vérifié',
              description: 'Inspirez confiance à vos clients',
            ),

            _buildAvantage(
              icon: Icons.support_agent,
              titre: 'Support prioritaire',
              description: 'Assistance dédiée 24/7',
            ),

            _buildAvantage(
              icon: Icons.star,
              titre: 'Promotion featured',
              description: 'Apparaissez en premier dans les recherches',
            ),

            const SizedBox(height: 32),

            // ===============================================
            // 💳 MOYEN DE PAIEMENT
            // ===============================================
            _buildSectionTitle('Choisissez votre moyen de paiement'),
            const SizedBox(height: 16),

            _buildMoyenPaiement(
              moyen: MoyenPaiement.tmoney,
              logo: '📱',
              nom: 'T-Money',
              description: 'Paiement sécurisé via T-Money',
            ),

            const SizedBox(height: 12),

            _buildMoyenPaiement(
              moyen: MoyenPaiement.flooz,
              logo: '💳',
              nom: 'Flooz',
              description: 'Paiement sécurisé via Flooz',
            ),

            const SizedBox(height: 32),

            // ===============================================
            // 💰 BOUTON PAYER
            // ===============================================
            ElevatedButton(
              onPressed: _chargement ? null : _initierPaiement,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: const Color(0xFFFFA500),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _chargement
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '💳 Payer 5 000 FCFA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // ===============================================
            // ℹ️ NOTE DE SÉCURITÉ
            // ===============================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Paiement 100% sécurisé\nVos données sont protégées',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ===============================================
  // 🧩 WIDGET - TITRE DE SECTION
  // ===============================================
  Widget _buildSectionTitle(String titre) {
    return Text(
      titre,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ===============================================
  // 🧩 WIDGET - AVANTAGE
  // ===============================================
  Widget _buildAvantage({
    required IconData icon,
    required String titre,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.green[700],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================
  // 🧩 WIDGET - MOYEN DE PAIEMENT
  // ===============================================
  Widget _buildMoyenPaiement({
    required MoyenPaiement moyen,
    required String logo,
    required String nom,
    required String description,
  }) {
    final estSelectionne = _moyenSelectionne == moyen;

    return GestureDetector(
      onTap: () {
        setState(() {
          _moyenSelectionne = moyen;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: estSelectionne ? Colors.orange[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: estSelectionne ? const Color(0xFFFFA500) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(
              logo,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (estSelectionne)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFFA500),
                size: 28,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: Colors.grey[400],
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
