import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EcranLivraisons extends StatefulWidget {
  const EcranLivraisons({super.key});

  @override
  State<EcranLivraisons> createState() => _EcranLivraisonsState();
}

class _EcranLivraisonsState extends State<EcranLivraisons> with TickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 👈 FONCTION MANQUANTE 1
  static Future<List<Map<String, dynamic>>> _chargerLivraisons(String userId, String statut) async {
    final client = Supabase.instance.client;

    String query = '''
      id, statut, prix_livraison, commission, created_at, 
      depart_texte, arrivee_texte, client_id, vendeur_id, livreur_id
    ''';

    String filter = "client_id.eq.$userId,vendeur_id.eq.$userId,livreur_id.eq.$userId";

    if (statut != 'tous') {
      filter += ',statut.in.(${statut.replaceAll(',', ',')})';
    }

    final response = await client.from('livraisons').select(query).or(filter).order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_shipping_outlined, size: 80, color: cs.primary),
              const SizedBox(height: 16),
              Text(
                'Connectez-vous pour accéder\naux livraisons',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            snap: true,
            title: const Text('Livraisons', style: TextStyle(fontWeight: FontWeight.w700)),
            centerTitle: false,
            bottom: TabBar(
              controller: _tabController,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 3, color: cs.primary),
                insets: const EdgeInsets.symmetric(horizontal: 24),
              ),
              tabs: const [
                Tab(text: 'Toutes', icon: Icon(Icons.list)),
                Tab(text: 'En cours', icon: Icon(Icons.local_shipping)),
                Tab(text: 'Historique', icon: Icon(Icons.history)),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _LivraisonsTab(statut: 'tous', userId: userId),
            _LivraisonsTab(statut: 'en_cours', userId: userId),
            _LivraisonsTab(statut: 'livree,annulee', userId: userId),
          ],
        ),
      ),
      floatingActionButton: _MenuDevenirLivreur(cs: cs),
    );
  }
}

// 👈 FONCTION MANQUANTE 2
class _LivraisonsTab extends StatelessWidget {
  final String statut;
  final String userId;

  const _LivraisonsTab({required this.statut, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _EcranLivraisonsState._chargerLivraisons(userId, statut),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final livraisons = snapshot.data ?? [];
        return RefreshIndicator(
          onRefresh: () => Future.delayed(const Duration(milliseconds: 500)),
          child: livraisons.isEmpty
              ? _EmptyState(statut: statut)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: livraisons.length,
                  itemBuilder: (context, index) => _CarteLivraisonPro(item: livraisons[index]),
                ),
        );
      },
    );
  }
}

// 👈 FONCTION MANQUANTE 3
class _EmptyState extends StatelessWidget {
  final String statut;
  const _EmptyState({required this.statut});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 80, color: cs.outline),
          const SizedBox(height: 16),
          Text(
            statut == 'tous' ? 'Aucune livraison' : 'Aucune livraison $_statutLabel',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par créer ou accepter une livraison',
            style: TextStyle(color: cs.outline),
          ),
        ],
      ),
    );
  }

  String get _statutLabel {
    switch (statut) {
      case 'en_cours':
        return 'en cours';
      case 'livree,annulee':
        return 'terminée';
      default:
        return 'pour ce filtre';
    }
  }
}

// 👈 FONCTION MANQUANTE 4
class _CarteLivraisonPro extends StatelessWidget {
  final Map<String, dynamic> item;
  const _CarteLivraisonPro({required this.item});

  String _idCourt(dynamic raw) {
    final id = (raw ?? '').toString();
    if (id.length <= 8) return id.isEmpty ? '-' : id;
    return id.substring(0, 8);
  }

  String _dateFr(DateTime? dt) {
    if (dt == null) return '-';
    return '${_pad(dt.day)}/${_pad(dt.month)}/${dt.year} ${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final createdAt = DateTime.tryParse('${item['created_at'] ?? ''}');
    final statut = item['statut'] ?? 'unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surface.withValues(alpha: 0.95),
            cs.surface.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Livraison #${_idCourt(item['id'])}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: cs.onSurface,
                  ),
                ),
              ),
              _BadgeStatutPro(statut: statut),
            ],
          ),
          const SizedBox(height: 12),
          _LieuItem('Départ', item['depart_texte'] ?? 'N/A'),
          const SizedBox(height: 8),
          _LieuItem('Arrivée', item['arrivee_texte'] ?? 'N/A'),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip('Prix', '${item['prix_livraison'] ?? 0} FCFA'),
              const SizedBox(width: 8),
              _InfoChip('Commission', '${item['commission'] ?? 0} FCFA'),
              const Spacer(),
              Text(
                _dateFr(createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 👈 FONCTIONS MANQUANTES 5-9
class _BadgeStatutPro extends StatelessWidget {
  final String statut;
  const _BadgeStatutPro({required this.statut});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = _style(statut, cs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(_label(statut), style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _label(String value) => switch (value) {
        'en_attente' => 'En attente',
        'acceptee' => 'Acceptée',
        'en_cours' => 'En cours',
        'livree' => 'Livrée',
        'annulee' => 'Annulée',
        _ => value,
      };

  (Color, Color) _style(String value, ColorScheme cs) {
    return switch (value) {
      'livree' => (Colors.green.withValues(alpha: 0.16), Colors.green.shade800),
      'annulee' => (Colors.red.withValues(alpha: 0.14), Colors.red.shade800),
      'en_cours' => (Colors.blue.withValues(alpha: 0.14), Colors.blue.shade800),
      'acceptee' => (cs.primary.withValues(alpha: 0.16), cs.primary),
      'en_attente' => (Colors.orange.withValues(alpha: 0.18), Colors.orange.shade900),
      _ => (cs.outline.withValues(alpha: 0.12), cs.outline),
    };
  }
}

class _LieuItem extends StatelessWidget {
  final String label;
  final String value;
  const _LieuItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on_outlined, size: 16, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.7))),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label: $value', style: TextStyle(fontSize: 11, color: cs.primary)),
    );
  }
}

// 👈 FONCTION MANQUANTE 10 - Page temporaire
class EcranDevenirLivreur extends StatelessWidget {
  const EcranDevenirLivreur({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devenir Livreur')),
      body: const Center(child: Text('Écran en construction...')),
    );
  }
}

// Menu FAB (inchangé)
class _MenuDevenirLivreur extends StatefulWidget {
  final ColorScheme cs;
  const _MenuDevenirLivreur({required this.cs});

  @override
  State<_MenuDevenirLivreur> createState() => _MenuDevenirLivreurState();
}

class _MenuDevenirLivreurState extends State<_MenuDevenirLivreur> with SingleTickerProviderStateMixin {
  bool _ouvert = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_ouvert)
          SlideTransition(
            position: Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.cs.surface.withValues(alpha: 0.95),
                    widget.cs.surface.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.cs.primary.withValues(alpha: 0.2),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: widget.cs.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.person_add, color: widget.cs.primary),
                ),
                title: const Text('Devenir livreur'),
                subtitle: Text('Gagnez de l\'argent en livrant'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EcranDevenirLivreur()),
                ),
                dense: true,
              ),
            ),
          ),
        FloatingActionButton(
          backgroundColor: widget.cs.primary,
          foregroundColor: widget.cs.onPrimary,
          onPressed: () {
            setState(() => _ouvert = !_ouvert);
            _ouvert ? _controller.forward() : _controller.reverse();
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(_ouvert ? Icons.close : Icons.add, key: ValueKey(_ouvert)),
          ),
        ),
      ],
    );
  }
}
