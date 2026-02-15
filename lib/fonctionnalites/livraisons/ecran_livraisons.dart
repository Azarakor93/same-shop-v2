import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EcranLivraisons extends StatefulWidget {
  const EcranLivraisons({super.key});

  @override
  State<EcranLivraisons> createState() => _EcranLivraisonsState();
}

class _EcranLivraisonsState extends State<EcranLivraisons> {
  static const List<String> _statuts = [
    'tous',
    'en_attente',
    'acceptee',
    'en_cours',
    'livree',
    'annulee',
  ];

  String _statutActif = 'tous';

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _chargerLivraisons(String userId) async {
    final response = await _client.from('livraisons').select('id, statut, prix_livraison, commission, created_at, depart_texte, arrivee_texte, client_id, vendeur_id, livreur_id').or('client_id.eq.$userId,vendeur_id.eq.$userId,livreur_id.eq.$userId').order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> _filtrer(List<Map<String, dynamic>> livraisons) {
    if (_statutActif == 'tous') return livraisons;
    return livraisons.where((l) => l['statut'] == _statutActif).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Center(child: Text('Connectez-vous pour accéder aux livraisons.'));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _chargerLivraisons(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Impossible de charger les livraisons.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final items = _filtrer(snapshot.data ?? []);

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Suivi des livraisons',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Consultez vos livraisons (client, vendeur ou livreur) et leur statut.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statuts.map((statut) {
                  return ChoiceChip(
                    label: Text(_labelStatut(statut)),
                    selected: _statutActif == statut,
                    onSelected: (_) => setState(() => _statutActif = statut),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text('Aucune livraison trouvée pour ce filtre.'),
                  ),
                )
              else
                ...items.map((item) => _CarteLivraison(item: item)),
            ],
          ),
        );
      },
    );
  }

  String _labelStatut(String statut) {
    switch (statut) {
      case 'tous':
        return 'Tous';
      case 'en_attente':
        return 'En attente';
      case 'acceptee':
        return 'Acceptée';
      case 'en_cours':
        return 'En cours';
      case 'livree':
        return 'Livrée';
      case 'annulee':
        return 'Annulée';
      default:
        return statut;
    }
  }
}

class _CarteLivraison extends StatelessWidget {
  const _CarteLivraison({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse('${item['created_at'] ?? ''}');
    final statut = '${item['statut'] ?? '-'}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Livraison #${_idCourt(item['id'])}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _BadgeStatut(statut: statut),
              ],
            ),
            const SizedBox(height: 8),
            Text('Départ: ${item['depart_texte'] ?? 'Non renseigné'}'),
            Text('Arrivée: ${item['arrivee_texte'] ?? 'Non renseigné'}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                Text('Prix: ${item['prix_livraison'] ?? '-'} FCFA'),
                Text('Commission: ${item['commission'] ?? '-'} FCFA'),
                Text('Créée: ${_dateFr(createdAt)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _idCourt(dynamic raw) {
    final id = (raw ?? '').toString();
    if (id.length <= 8) return id.isEmpty ? '-' : id;
    return id.substring(0, 8);
  }

  String _dateFr(DateTime? dt) {
    if (dt == null) return '-';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final mn = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$mn';
  }
}

class _BadgeStatut extends StatelessWidget {
  const _BadgeStatut({required this.statut});

  final String statut;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _style(statut, Theme.of(context));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(statut),
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  (Color, Color) _style(String value, ThemeData theme) {
    switch (value) {
      case 'livree':
        return (Colors.green.withValues(alpha: 0.16), Colors.green[800]!);
      case 'annulee':
        return (Colors.red.withValues(alpha: 0.14), Colors.red[800]!);
      case 'en_cours':
        return (Colors.blue.withValues(alpha: 0.14), Colors.blue[800]!);
      case 'acceptee':
        return (theme.colorScheme.primary.withValues(alpha: 0.16), theme.colorScheme.primary);
      case 'en_attente':
      default:
        return (Colors.orange.withValues(alpha: 0.18), Colors.orange[900]!);
    }
  }

  String _label(String value) {
    switch (value) {
      case 'en_attente':
        return 'En attente';
      case 'acceptee':
        return 'Acceptée';
      case 'en_cours':
        return 'En cours';
      case 'livree':
        return 'Livrée';
      case 'annulee':
        return 'Annulée';
      default:
        return value;
    }
  }
}
