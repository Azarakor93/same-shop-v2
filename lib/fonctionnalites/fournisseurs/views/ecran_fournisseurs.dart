import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../vendeur/models/boutique.dart';
import '../models/demande_fournisseur.dart';
import '../services/service_fournisseurs_supabase.dart';
import 'ecran_creer_demande_fournisseur.dart';
import 'ecran_details_demande_fournisseur.dart';

class EcranFournisseurs extends StatefulWidget {
  final Boutique boutique;

  const EcranFournisseurs({
    super.key,
    required this.boutique,
  });

  @override
  State<EcranFournisseurs> createState() => _EcranFournisseursState();
}

class _EcranFournisseursState extends State<EcranFournisseurs> {
  final _service = ServiceFournisseursSupabase();

  Future<void> _allerCreer() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EcranCreerDemandeFournisseur(boutique: widget.boutique),
      ),
    );
    if (ok == true && mounted) {
      setState(() {});
    }
  }

  void _ouvrirDemande(DemandeFournisseur d) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EcranDetailsDemandeFournisseur(demande: d),
      ),
    );
    if (changed == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fournisseurs'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mes demandes'),
              Tab(text: 'Annonces'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Nouvelle demande',
              icon: const Icon(Icons.add),
              onPressed: _allerCreer,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _ListeDemandes(
              future: _service.listerMesDemandes(demandeurId: widget.boutique.id),
              onTap: _ouvrirDemande,
              videTexte: 'Aucune demande pour le moment.',
            ),
            _ListeDemandes(
              future: _service.listerDemandesActives(exclureDemandeurId: userId),
              onTap: _ouvrirDemande,
              videTexte: 'Aucune annonce fournisseur active.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ListeDemandes extends StatelessWidget {
  final Future<List<DemandeFournisseur>> future;
  final void Function(DemandeFournisseur) onTap;
  final String videTexte;

  const _ListeDemandes({
    required this.future,
    required this.onTap,
    required this.videTexte,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DemandeFournisseur>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Erreur: ${snapshot.error}'),
            ),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(videTexte),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final d = items[index];
              final joursRestants =
                  d.expireAt.difference(DateTime.now()).inDays.clamp(0, 999);

              return Card(
                child: ListTile(
                  title: Text(
                    d.produitRecherche,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      if (d.quantite != null) 'Qté: ${d.quantite}',
                      if (d.budget != null) 'Budget: ${d.budget} FCFA',
                      if (d.ville != null && d.ville!.isNotEmpty) d.ville!,
                      'Expire: ${joursRestants}j',
                    ].join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onTap(d),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

