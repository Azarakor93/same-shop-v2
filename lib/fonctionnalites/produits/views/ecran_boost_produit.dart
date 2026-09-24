// ===============================================
// 🚀 ÉCRAN BOOST PRODUIT
// ===============================================
// Permet de booster un produit pour plus de visibilité

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/produit.dart';
import '../services/service_paiement.dart';

class EcranBoostProduit extends StatefulWidget {
  final Produit produit;

  const EcranBoostProduit({
    super.key,
    required this.produit,
  });

  @override
  State<EcranBoostProduit> createState() => _EcranBoostProduitState();
}

class _EcranBoostProduitState extends State<EcranBoostProduit> {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _service = ServicePaiement();

  MethodePaiement? _methodeSelectionnee;
  bool _estEnChargement = false;
  late _PackBoost _packSelectionne;

  // Packs selon le document SAME Shop v8.0 (10 fév 2026)
  static const List<_PackBoost> _packs = [
    _PackBoost(
      code: 'classique',
      titre: 'CLASSIQUE',
      badge: null,
      jours: 1,
      prix: 200,
      description: 'Top local (~5 km) + badge BOOST',
    ),
    _PackBoost(
      code: 'premium',
      titre: 'PREMIUM',
      badge: '⭐',
      jours: 3,
      prix: 500,
      description: 'Top régional (~50 km) + notifications',
    ),
    _PackBoost(
      code: 'elite',
      titre: 'ÉLITE',
      badge: '⚡',
      jours: 10,
      prix: 1500,
      description: 'Top national + grande visibilité',
    ),
    _PackBoost(
      code: 'super',
      titre: 'SUPER BOOST',
      badge: '👑',
      jours: 30,
      prix: 9000,
      description: '#1 prolongé + pushs ciblés',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _packSelectionne = _packs.first;
  }

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _procederBoost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_methodeSelectionnee == null) {
      _afficherErreur('Veuillez sélectionner une méthode de paiement');
      return;
    }

    setState(() => _estEnChargement = true);

    try {
      final resultat = await _service.boosterProduit(
        produitId: widget.produit.id,
        methode: _methodeSelectionnee!,
        numero: _numeroController.text.trim(),
        montant: _packSelectionne.prix,
        dureeJours: _packSelectionne.jours,
      );

      if (!mounted) return;

      if (resultat.succes) {
        await _afficherDialogConfirmation(resultat);
      } else {
        _afficherErreur(resultat.message ?? 'Échec du paiement');
      }
    } catch (e) {
      if (!mounted) return;
      _afficherErreur('Erreur: $e');
    } finally {
      if (mounted) {
        setState(() => _estEnChargement = false);
      }
    }
  }

  Future<void> _afficherDialogConfirmation(ResultatPaiement resultat) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Paiement initié'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Un code a été envoyé au numéro ${_numeroController.text}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Marche à suivre :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _methodeSelectionnee == MethodePaiement.tmoney
                        ? '1. Composez *155# sur votre téléphone\n'
                            '2. Entrez votre code PIN\n'
                            '3. Validez le paiement de ${_packSelectionne.prix} FCFA'
                        : '1. Composez *155*3# sur votre téléphone\n'
                            '2. Entrez votre code PIN\n'
                            '3. Validez le paiement de ${_packSelectionne.prix} FCFA',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => _verifierPaiement(resultat.transactionId!),
            child: const Text('J\'ai payé'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifierPaiement(String transactionId) async {
    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Vérification du paiement...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final estValide = await _service.verifierPaiement(transactionId);

      if (!mounted) return;
      Navigator.pop(context);

      if (estValide) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Boost activé !'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Votre produit est maintenant boosté pour une meilleure visibilité !',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.rocket_launch, color: Colors.amber.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Durée: ${_packSelectionne.jours} jour${_packSelectionne.jours > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _afficherErreur(
          'Le paiement n\'a pas encore été validé. Veuillez réessayer.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _afficherErreur('Erreur de vérification: $e');
    }
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booster le produit'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 📦 PRODUIT
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image, size: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.produit.nom,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.produit.prixFormate,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 🚀 AVANTAGES DU BOOST
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch, color: Colors.white, size: 32),
                        SizedBox(width: 12),
                        Text(
                          'Pourquoi booster ?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildAvantage('📈 Apparaît en haut des recherches'),
                    _buildAvantage('👀 +300% de visibilité'),
                    _buildAvantage('🏷️ Badge BOOST sur le produit'),
                    _buildAvantage('🔔 Notifications vers des clients ciblés'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ⏰ PACK BOOST
              Text(
                'Choisir un pack de boost',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Column(
                children: _packs
                    .map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPackCard(p),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 24),

              // 📱 MÉTHODE DE PAIEMENT
              Text(
                'Méthode de paiement',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _buildMethodeCard(
                methode: MethodePaiement.tmoney,
                titre: 'T-Money',
                icon: Icons.phone_android,
                couleur: Colors.green,
              ),

              const SizedBox(height: 12),

              _buildMethodeCard(
                methode: MethodePaiement.flooz,
                titre: 'Flooz',
                icon: Icons.phone_iphone,
                couleur: Colors.orange,
              ),

              const SizedBox(height: 24),

              // 📞 NUMÉRO
              Text(
                'Numéro de téléphone',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _numeroController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: InputDecoration(
                  hintText: 'Ex: 90123456',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre numéro';
                  }
                  if (value.length != 8) {
                    return 'Le numéro doit contenir 8 chiffres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 💳 BOUTON PAYER
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _estEnChargement ? null : _procederBoost,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _estEnChargement
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.rocket_launch),
                            const SizedBox(width: 8),
                            Text(
                              'Booster • ${_packSelectionne.prix} FCFA',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvantage(String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texte,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackCard(_PackBoost pack) {
    final estSelectionne = _packSelectionne.code == pack.code;

    return InkWell(
      onTap: () => setState(() => _packSelectionne = pack),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: estSelectionne ? Colors.orange.shade100 : null,
          border: Border.all(
            color: estSelectionne ? Colors.orange : Colors.grey.shade300,
            width: estSelectionne ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                pack.badge ?? '🚀',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pack.titre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: estSelectionne ? Colors.orange.shade900 : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pack.jours} jour${pack.jours > 1 ? 's' : ''} • ${pack.description}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${pack.prix} FCFA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: estSelectionne ? Colors.orange.shade800 : null,
                  ),
                ),
                const SizedBox(height: 6),
                if (estSelectionne)
                  Icon(
                    Icons.check_circle,
                    color: Colors.orange.shade700,
                    size: 22,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodeCard({
    required MethodePaiement methode,
    required String titre,
    required IconData icon,
    required Color couleur,
  }) {
    final estSelectionnee = _methodeSelectionnee == methode;

    return InkWell(
      onTap: () => setState(() => _methodeSelectionnee = methode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: estSelectionnee ? couleur.withValues(alpha: 0.1) : null,
          border: Border.all(
            color: estSelectionnee ? couleur : Colors.grey.shade300,
            width: estSelectionnee ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: couleur, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                titre,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: estSelectionnee ? couleur : null,
                ),
              ),
            ),
            if (estSelectionnee) Icon(Icons.check_circle, color: couleur, size: 28),
          ],
        ),
      ),
    );
  }
}

class _PackBoost {
  final String code;
  final String titre;
  final String? badge;
  final int jours;
  final int prix;
  final String description;

  const _PackBoost({
    required this.code,
    required this.titre,
    required this.badge,
    required this.jours,
    required this.prix,
    required this.description,
  });
}
