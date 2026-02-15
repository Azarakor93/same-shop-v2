// ===============================================
// 🚚 LIVRAISONS (PDF SAME Shop)
// ===============================================
// Carte GPS + Demandes spéciales 25 FCFA

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/livraison.dart';
import 'services/service_livraisons_supabase.dart';

class EcranLivraisons extends StatelessWidget {
  const EcranLivraisons({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: const TabBar(
              tabs: [
                Tab(text: 'Mes demandes'),
                Tab(text: 'Disponible'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OngletMesDemandes(userId: user?.id),
                _OngletDisponible(userId: user?.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OngletMesDemandes extends StatefulWidget {
  final String? userId;
  const _OngletMesDemandes({required this.userId});

  @override
  State<_OngletMesDemandes> createState() => _OngletMesDemandesState();
}

class _OngletMesDemandesState extends State<_OngletMesDemandes> {
  final _service = ServiceLivraisonsSupabase();
  late Future<List<Livraison>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listerMesDemandesClient();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null) {
      return const _EtatVide(
        icon: Icons.lock_outline,
        message: 'Connexion requise',
        detail: 'Connectez-vous pour suivre vos livraisons.',
      );
    }

    return FutureBuilder<List<Livraison>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _EtatVide(
            icon: Icons.wifi_off,
            message: 'Erreur',
            detail: 'Impossible de charger vos demandes.',
            actionLabel: 'Réessayer',
            onAction: () => setState(() {
              _future = _service.listerMesDemandesClient();
            }),
          );
        }

        final items = snapshot.data ?? const <Livraison>[];
        if (items.isEmpty) {
          return _EtatVide(
            icon: Icons.local_shipping_outlined,
            message: 'Aucune demande',
            detail: 'Créez une demande de livraison en quelques secondes.',
            actionLabel: 'Nouvelle demande',
            onAction: () => _creerDemande(context),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = _service.listerMesDemandesClient());
            await _future;
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _CarteLivraison(
              livraison: items[index],
              actionLabel: items[index].statut == 'en_attente'
                  ? 'Annuler'
                  : null,
              onAction: items[index].statut == 'en_attente'
                  ? () async {
                      await _service.changerStatut(
                        livraisonId: items[index].id,
                        statut: 'annulee',
                      );
                      if (!context.mounted) return;
                      setState(() => _future = _service.listerMesDemandesClient());
                    }
                  : null,
            ),
          ),
        );
      },
    );
  }

  Future<void> _creerDemande(BuildContext context) async {
    final res = await showModalBottomSheet<_DemandeFormResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _BottomSheetCreerDemande(),
    );

    if (!context.mounted || res == null) return;

    try {
      await _service.creerDemandeLivraison(
        departTexte: res.depart,
        arriveeTexte: res.arrivee,
        demandeSpeciale: res.demandeSpeciale,
      );
      if (!context.mounted) return;
      setState(() => _future = _service.listerMesDemandesClient());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande créée')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}

class _OngletDisponible extends StatefulWidget {
  final String? userId;
  const _OngletDisponible({required this.userId});

  @override
  State<_OngletDisponible> createState() => _OngletDisponibleState();
}

class _OngletDisponibleState extends State<_OngletDisponible> {
  final _service = ServiceLivraisonsSupabase();
  late Future<List<Livraison>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listerDemandesDisponiblesLivreur();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null) {
      return const _EtatVide(
        icon: Icons.lock_outline,
        message: 'Connexion requise',
        detail: 'Connectez-vous pour accepter des livraisons.',
      );
    }

    return FutureBuilder<List<Livraison>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _EtatVide(
            icon: Icons.wifi_off,
            message: 'Erreur',
            detail: 'Impossible de charger les demandes disponibles.',
            actionLabel: 'Réessayer',
            onAction: () => setState(() {
              _future = _service.listerDemandesDisponiblesLivreur();
            }),
          );
        }

        final items = snapshot.data ?? const <Livraison>[];
        if (items.isEmpty) {
          return const _EtatVide(
            icon: Icons.inbox_outlined,
            message: 'Aucune demande disponible',
            detail: 'Revenez plus tard pour accepter une livraison.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = _service.listerDemandesDisponiblesLivreur());
            await _future;
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _CarteLivraison(
              livraison: items[index],
              actionLabel: 'Accepter',
              onAction: () async {
                try {
                  await _service.accepterLivraison(items[index].id);
                  if (!context.mounted) return;
                  setState(() {
                    _future = _service.listerDemandesDisponiblesLivreur();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Livraison acceptée')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _CarteLivraison extends StatelessWidget {
  final Livraison livraison;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CarteLivraison({
    required this.livraison,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final badge = livraison.demandeSpeciale ? 'Demande spéciale' : 'Standard';
    final badgeColor = livraison.demandeSpeciale
        ? cs.tertiary.withValues(alpha: 0.14)
        : cs.secondary.withValues(alpha: 0.14);
    final badgeTextColor =
        livraison.demandeSpeciale ? cs.tertiary : cs.secondary;

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
                    livraison.arriveeTexte ?? 'Livraison',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: badgeTextColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Départ: ${livraison.departTexte ?? '-'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Statut: ${livraison.statut}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
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

class _BottomSheetCreerDemande extends StatefulWidget {
  const _BottomSheetCreerDemande();

  @override
  State<_BottomSheetCreerDemande> createState() =>
      _BottomSheetCreerDemandeState();
}

class _BottomSheetCreerDemandeState extends State<_BottomSheetCreerDemande> {
  final _departCtrl = TextEditingController();
  final _arriveeCtrl = TextEditingController();
  bool _demandeSpeciale = false;

  @override
  void dispose() {
    _departCtrl.dispose();
    _arriveeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + viewInsets),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nouvelle livraison',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _departCtrl,
              decoration: const InputDecoration(
                labelText: 'Départ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _arriveeCtrl,
              decoration: const InputDecoration(
                labelText: 'Arrivée',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _demandeSpeciale,
              onChanged: (v) => setState(() => _demandeSpeciale = v),
              title: const Text('Demande spéciale'),
              subtitle: const Text('Frais: 25 FCFA'),
            ),
            const SizedBox(height: 10),
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
                      final depart = _departCtrl.text.trim();
                      final arrivee = _arriveeCtrl.text.trim();
                      if (depart.isEmpty || arrivee.isEmpty) return;
                      Navigator.pop(
                        context,
                        _DemandeFormResult(
                          depart: depart,
                          arrivee: arrivee,
                          demandeSpeciale: _demandeSpeciale,
                        ),
                      );
                    },
                    child: const Text('Créer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DemandeFormResult {
  final String depart;
  final String arrivee;
  final bool demandeSpeciale;

  const _DemandeFormResult({
    required this.depart,
    required this.arrivee,
    required this.demandeSpeciale,
  });
}
