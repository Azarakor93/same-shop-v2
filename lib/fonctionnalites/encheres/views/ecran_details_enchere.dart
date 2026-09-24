// ===============================================
// 🔨 DÉTAILS ENCHÈRE - PLACEMENT D'OFFRE
// ===============================================
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../models/enchere.dart';
import '../models/enchere_offre.dart';
import '../services/service_encheres_supabase.dart';

class EcranDetailsEnchere extends StatefulWidget {
  final Enchere enchere;

  const EcranDetailsEnchere({
    super.key,
    required this.enchere,
  });

  @override
  State<EcranDetailsEnchere> createState() => _EcranDetailsEnchereState();
}

class _EcranDetailsEnchereState extends State<EcranDetailsEnchere> {
  final ServiceEncheresSupabase _service = ServiceEncheresSupabase();
  final TextEditingController _montantController = TextEditingController();

  List<EnchereOffre> _offres = [];
  bool _chargementOffres = false;
  late Enchere _enchere;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _enchere = widget.enchere;
    _chargerOffres();

    // Timer pour actualiser le temps restant
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _chargerOffres() async {
    setState(() => _chargementOffres = true);
    final offres = await _service.recupererOffres(_enchere.id);
    setState(() {
      _offres = offres;
      _chargementOffres = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails Enchère'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Partager enchère
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🖼️ IMAGE
                  _buildImage(theme),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TITRE + TIMER
                        _buildHeader(theme),
                        const SizedBox(height: 16),

                        // PRIX
                        _buildPrix(theme),
                        const SizedBox(height: 24),

                        // BOUTIQUE
                        _buildBoutique(theme),
                        const SizedBox(height: 24),

                        // DESCRIPTION
                        if (_enchere.description != null) ...[
                          _buildDescription(theme),
                          const SizedBox(height: 24),
                        ],

                        // HISTORIQUE ENCHÈRES
                        _buildHistorique(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // BARRE ENCHÉRIR
          if (!_enchere.estTerminee) _buildBarreEncherir(theme),
        ],
      ),
    );
  }

  Widget _buildImage(ThemeData theme) {
    return AspectRatio(
      aspectRatio: 1,
      child: _enchere.imageProduit != null
          ? CachedNetworkImage(
              imageUrl: _enchere.imageProduit!,
              fit: BoxFit.cover,
            )
          : Container(
              color: theme.disabledColor.withValues(alpha: 0.1),
              child: Icon(
                Icons.image,
                size: 80,
                color: theme.disabledColor,
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final tempsRestant = _enchere.tempsRestant;
    final urgence = tempsRestant.inHours < 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _enchere.nomProduit,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // TIMER
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: urgence
                ? Colors.red.withValues(alpha: 0.1)
                : theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: urgence ? Colors.red : theme.primaryColor,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                urgence ? Icons.access_alarm : Icons.schedule,
                color: urgence ? Colors.red : theme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      urgence ? 'Se termine bientôt !' : 'Temps restant',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: urgence ? Colors.red : theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _enchere.tempsRestantFormate,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: urgence ? Colors.red : theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // NOMBRE ENCHÉRISSEURS
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_enchere.nombreEncherisseurs}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrix(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // PRIX DÉPART
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prix de départ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_enchere.prixDepart.toStringAsFixed(0)} FCFA',
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: theme.disabledColor,
                ),
              ),
            ],
          ),

          // PRIX ACTUEL
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Enchère actuelle',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_enchere.prixActuel.toStringAsFixed(0)} FCFA',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoutique(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.dividerColor,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.store,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vendu par',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _enchere.nomBoutique,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () {
              // TODO: Ouvrir boutique
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _enchere.description!,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildHistorique(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Historique des enchères',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_chargementOffres)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (_offres.isEmpty && !_chargementOffres)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Aucune enchère pour le moment.\nSoyez le premier !',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _offres.length,
            itemBuilder: (context, index) {
              final offre = _offres[index];
              final estPremier = index == 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: estPremier
                      ? theme.primaryColor.withValues(alpha: 0.1)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: estPremier
                        ? theme.primaryColor
                        : theme.dividerColor,
                  ),
                ),
                child: Row(
                  children: [
                    if (estPremier)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 16,
                        ),
                      )
                    else
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.disabledColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offre.nomUtilisateur,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDate(offre.dateOffre),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.disabledColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${offre.montant.toStringAsFixed(0)} FCFA',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: estPremier ? theme.primaryColor : null,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBarreEncherir(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _montantController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Votre enchère',
                hintText: 'Minimum: ${(_enchere.prixActuel + 100).toStringAsFixed(0)} FCFA',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: 'FCFA',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _placerEnchere,
                icon: const Icon(Icons.gavel),
                label: const Text('Placer mon enchère'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placerEnchere() async {
    final montantText = _montantController.text.trim();
    if (montantText.isEmpty) {
      _afficherErreur('Veuillez saisir un montant');
      return;
    }

    final montant = double.tryParse(montantText);
    if (montant == null || montant <= _enchere.prixActuel) {
      _afficherErreur('Le montant doit être supérieur à ${_enchere.prixActuel.toStringAsFixed(0)} FCFA');
      return;
    }

    // Confirmation
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'enchère'),
        content: Text('Vous allez placer une enchère de ${montant.toStringAsFixed(0)} FCFA'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    // Placement
    final succes = await _service.placerEnchere(
      enchereId: _enchere.id,
      montant: montant,
    );

    if (!mounted) return;

    if (succes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Enchère placée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      _montantController.clear();
      _chargerOffres();
    } else {
      _afficherErreur('Erreur lors du placement de l\'enchère');
    }
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final maintenant = DateTime.now();
    final difference = maintenant.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return 'Il y a ${difference.inDays} j';
    }
  }
}
