import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../vendeur/models/boutique.dart';
import '../../produits/services/service_paiement.dart';
import '../services/service_fournisseurs_supabase.dart';

class EcranCreerDemandeFournisseur extends StatefulWidget {
  final Boutique boutique;

  const EcranCreerDemandeFournisseur({
    super.key,
    required this.boutique,
  });

  @override
  State<EcranCreerDemandeFournisseur> createState() =>
      _EcranCreerDemandeFournisseurState();
}

class _EcranCreerDemandeFournisseurState
    extends State<EcranCreerDemandeFournisseur> {
  final _formKey = GlobalKey<FormState>();
  final _paiement = ServicePaiement();
  final _service = ServiceFournisseursSupabase();

  final _produitCtrl = TextEditingController();
  final _quantiteCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _paysCtrl = TextEditingController(text: 'TG');
  final _livraisonCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();

  final _numeroCtrl = TextEditingController();
  MethodePaiement? _methode;
  bool _loading = false;

  @override
  void dispose() {
    _produitCtrl.dispose();
    _quantiteCtrl.dispose();
    _budgetCtrl.dispose();
    _villeCtrl.dispose();
    _paysCtrl.dispose();
    _livraisonCtrl.dispose();
    _detailsCtrl.dispose();
    _numeroCtrl.dispose();
    super.dispose();
  }

  int? _parseInt(String v) => int.tryParse(v.trim());

  Future<void> _validerEtPayer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_methode == null) {
      _snack('Veuillez sélectionner une méthode de paiement', erreur: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final resultat = await _paiement.initierPaiement(
        methode: _methode!,
        numero: _numeroCtrl.text.trim(),
        montant: 2000,
        typeAbonnement: TypeAbonnement.gratuit,
        vendeurId: widget.boutique.id,
        typeTransaction: TypeTransaction.fournisseur,
        dureeJours: 7,
      );

      if (!mounted) return;
      if (!resultat.succes || resultat.transactionId == null) {
        _snack(resultat.message ?? 'Échec du paiement', erreur: true);
        return;
      }

      await _dialogPaiement(resultat.transactionId!);
    } catch (e) {
      if (!mounted) return;
      _snack('Erreur: $e', erreur: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _dialogPaiement(String transactionId) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Paiement initié'),
        content: Text(
          'Un code de paiement a été envoyé au numéro ${_numeroCtrl.text}.\n'
          'Après validation, votre annonce sera active pendant 7 jours.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => _verifierEtPublier(transactionId),
            child: const Text('J’ai payé'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifierEtPublier(String transactionId) async {
    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final ok = await _paiement.verifierPaiement(transactionId);
      if (!mounted) return;
      Navigator.pop(context);

      if (!ok) {
        _snack('Paiement non validé. Réessayez.', erreur: true);
        return;
      }

      await _service.creerDemande(
        demandeurId: widget.boutique.id,
        transactionId: transactionId,
        produitRecherche: _produitCtrl.text,
        quantite: _parseInt(_quantiteCtrl.text),
        budget: _parseInt(_budgetCtrl.text),
        ville: _villeCtrl.text.trim().isEmpty ? null : _villeCtrl.text,
        pays: _paysCtrl.text.trim().isEmpty ? null : _paysCtrl.text,
        livraisonVille:
            _livraisonCtrl.text.trim().isEmpty ? null : _livraisonCtrl.text,
        details: _detailsCtrl.text.trim().isEmpty ? null : _detailsCtrl.text,
      );

      if (!mounted) return;
      _snack('✅ Demande publiée (7 jours)');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _snack('Erreur: $e', erreur: true);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche fournisseurs'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Tarif: 2 000 FCFA • Durée: 7 jours\n'
                    'Votre annonce sera visible par toutes les boutiques.',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _produitCtrl,
                decoration: const InputDecoration(
                  labelText: 'Produit recherché',
                  hintText: 'Ex: iPhone 15',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantiteCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Quantité',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _budgetCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Budget (FCFA)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _villeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ville',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      controller: _paysCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Pays',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _livraisonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Livraison (ville/zone)',
                  hintText: 'Ex: Lomé',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _detailsCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Détails',
                  hintText:
                      'Ex: 50 unités • Budget 3 000 000 FCFA • Livraison Lomé',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Méthode de paiement',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _methodeTile(MethodePaiement.tmoney, 'T-Money'),
              const SizedBox(height: 8),
              _methodeTile(MethodePaiement.flooz, 'Flooz'),
              const SizedBox(height: 14),
              TextFormField(
                controller: _numeroCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: const InputDecoration(
                  labelText: 'Numéro (8 chiffres)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Champ obligatoire';
                  if (value.length != 8) return 'Le numéro doit contenir 8 chiffres';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _loading ? null : _validerEtPayer,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Payer 2 000 FCFA et publier'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodeTile(MethodePaiement m, String label) {
    final selected = _methode == m;
    return InkWell(
      onTap: () => setState(() => _methode = m),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? Colors.green : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: selected ? Colors.green.withValues(alpha: 0.08) : null,
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? Colors.green : Colors.grey),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

