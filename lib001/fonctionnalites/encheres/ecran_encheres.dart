// ===============================================
// 🔨 ENCHÈRES ENTREPRISES (PDF SAME Shop)
// ===============================================
// En cours + Mes gains — Abonnement 30 000 FCFA illimité

import 'package:flutter/material.dart';

import 'models/enchere.dart';
import 'services/service_encheres_supabase.dart';

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
                _OngletEncheresEnCours(),
                _OngletMesGains(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OngletEncheresEnCours extends StatefulWidget {
  @override
  State<_OngletEncheresEnCours> createState() => _OngletEncheresEnCoursState();
}

class _OngletEncheresEnCoursState extends State<_OngletEncheresEnCours> {
  final _service = ServiceEncheresSupabase();
  late Future<List<Enchere>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listerEncheresEnCours();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Enchere>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _EtatVide(
            icon: Icons.wifi_off,
            message: 'Erreur de chargement',
            detail: 'Impossible de récupérer les enchères.',
            actionLabel: 'Réessayer',
            onAction: () => setState(() {
              _future = _service.listerEncheresEnCours();
            }),
          );
        }

        final items = snapshot.data ?? const <Enchere>[];
        if (items.isEmpty) {
          return const _EtatVide(
            icon: Icons.gavel,
            message: 'Aucune enchère en cours.',
            detail: 'Les enchères entreprises apparaîtront ici.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = _service.listerEncheresEnCours());
            await _future;
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _CarteEnchere(
              enchere: items[index],
              onOffre: () => _ouvrirOffre(context, items[index]),
            ),
          ),
        );
      },
    );
  }

  Future<void> _ouvrirOffre(BuildContext context, Enchere enchere) async {
    final theme = Theme.of(context);
    final ctrl = TextEditingController();

    final montant = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proposer une offre',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant (FCFA)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final v = int.tryParse(ctrl.text.trim());
                        Navigator.pop(context, v);
                      },
                      child: const Text('Envoyer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || montant == null) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _service.placerOffre(enchereId: enchere.id, montant: montant);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Offre envoyée')),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}

class _OngletMesGains extends StatefulWidget {
  @override
  State<_OngletMesGains> createState() => _OngletMesGainsState();
}

class _OngletMesGainsState extends State<_OngletMesGains> {
  final _service = ServiceEncheresSupabase();
  late Future<List<Enchere>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listerMesGains();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Enchere>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _EtatVide(
            icon: Icons.wifi_off,
            message: 'Erreur de chargement',
            detail: 'Impossible de récupérer vos gains.',
            actionLabel: 'Réessayer',
            onAction: () => setState(() {
              _future = _service.listerMesGains();
            }),
          );
        }

        final items = snapshot.data ?? const <Enchere>[];
        if (items.isEmpty) {
          return const _EtatVide(
            icon: Icons.emoji_events_outlined,
            message: 'Aucun gain pour le moment.',
            detail: 'Vos enchères gagnées s\'afficheront ici.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = _service.listerMesGains());
            await _future;
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _CarteEnchere(
              enchere: items[index],
              onOffre: null,
            ),
          ),
        );
      },
    );
  }
}

class _EtatVide extends StatelessWidget {
  final IconData icon;
  final String message;
  final String detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EtatVide({
    required this.icon,
    required this.message,
    required this.detail,
    this.actionLabel,
    this.onAction,
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CarteEnchere extends StatelessWidget {
  final Enchere enchere;
  final VoidCallback? onOffre;

  const _CarteEnchere({
    required this.enchere,
    required this.onOffre,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final reste = enchere.dateFin.difference(DateTime.now());
    final resteTexte = reste.isNegative
        ? 'Terminé'
        : '${reste.inHours}h ${reste.inMinutes.remainder(60)}m';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    enchere.titre,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    resteTexte,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              enchere.lotTexte,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Départ: ${enchere.prixDepart} FCFA',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (onOffre != null)
                  FilledButton.icon(
                    onPressed: onOffre,
                    icon: const Icon(Icons.add),
                    label: const Text('Offre'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
