import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/demande_fournisseur.dart';
import '../models/reponse_fournisseur.dart';
import '../services/service_fournisseurs_supabase.dart';

class EcranDetailsDemandeFournisseur extends StatefulWidget {
  final DemandeFournisseur demande;

  const EcranDetailsDemandeFournisseur({
    super.key,
    required this.demande,
  });

  @override
  State<EcranDetailsDemandeFournisseur> createState() =>
      _EcranDetailsDemandeFournisseurState();
}

class _EcranDetailsDemandeFournisseurState
    extends State<EcranDetailsDemandeFournisseur> {
  final _service = ServiceFournisseursSupabase();
  final _messageCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _prixCtrl.dispose();
    super.dispose();
  }

  bool get _estOwner {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return uid != null && uid == widget.demande.demandeurId;
  }

  int? _parsePrix() => int.tryParse(_prixCtrl.text.trim());

  Future<void> _envoyer() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final msg = _messageCtrl.text.trim();
    if (msg.isEmpty) {
      _snack('Message obligatoire', erreur: true);
      return;
    }

    setState(() => _sending = true);
    try {
      await _service.repondre(
        demandeId: widget.demande.id,
        fournisseurId: uid,
        message: msg,
        prixPropose: _parsePrix(),
      );
      if (!mounted) return;
      _messageCtrl.clear();
      _prixCtrl.clear();
      _snack('✅ Réponse envoyée');
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      _snack('Erreur: $e', erreur: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String msg, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: erreur ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.demande;
    final joursRestants =
        d.expireAt.difference(DateTime.now()).inDays.clamp(0, 999);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails demande'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.produitRecherche,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip('Expire: ${joursRestants}j'),
                      if (d.quantite != null) _chip('Qté: ${d.quantite}'),
                      if (d.budget != null) _chip('Budget: ${d.budget} FCFA'),
                      if (d.ville != null && d.ville!.isNotEmpty)
                        _chip('Ville: ${d.ville}'),
                      if (d.pays != null && d.pays!.isNotEmpty)
                        _chip('Pays: ${d.pays}'),
                      if (d.livraisonVille != null &&
                          d.livraisonVille!.isNotEmpty)
                        _chip('Livraison: ${d.livraisonVille}'),
                    ],
                  ),
                  if (d.details != null && d.details!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(d.details!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Réponses',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<ReponseFournisseur>>(
            future: _service.listerReponses(demandeId: d.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Erreur: ${snapshot.error}');
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Text('Aucune réponse pour le moment.');
              }
              return Column(
                children: items
                    .map(
                      (r) => Card(
                        child: ListTile(
                          title: Text(r.message),
                          subtitle: Text(
                            [
                              'De: ${r.fournisseurId.substring(0, 6)}…',
                              if (r.prixPropose != null)
                                'Prix: ${r.prixPropose} FCFA',
                            ].join(' • '),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          if (!_estOwner) ...[
            Text(
              'Répondre',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _messageCtrl,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Votre message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _prixCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Prix proposé (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _sending ? null : _envoyer,
                child: _sending
                    ? const CircularProgressIndicator()
                    : const Text('Envoyer la réponse'),
              ),
            ),
          ] else ...[
            const Text(
              'Vous êtes le demandeur. Les réponses apparaîtront ici.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

