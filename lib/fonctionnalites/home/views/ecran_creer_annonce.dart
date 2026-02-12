import 'package:flutter/material.dart';

import 'services/supabase_annonce_service.dart';

class EcranCreerAnnonce extends StatefulWidget {
  const EcranCreerAnnonce({super.key});

  @override
  State<EcranCreerAnnonce> createState() => _EcranCreerAnnonceState();
}

class _EcranCreerAnnonceState extends State<EcranCreerAnnonce> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _lienValeurController = TextEditingController();
  final _service = SupabaseAnnonceService();

  bool _enCours = false;
  String? _lienType;
  int? _dureeJours;

  String get _labelValeurLien {
    switch (_lienType) {
      case 'vendeur':
        return 'ID boutique vendeur';
      case 'produit':
        return 'ID produit';
      case 'externe':
        return 'URL externe';
      default:
        return 'Valeur du lien (optionnel)';
    }
  }

  String get _hintValeurLien {
    switch (_lienType) {
      case 'vendeur':
        return 'UUID du vendeur';
      case 'produit':
        return 'UUID du produit';
      case 'externe':
        return 'https://...';
      default:
        return 'Renseignez une valeur si un type est choisi';
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _imageUrlController.dispose();
    _lienValeurController.dispose();
    super.dispose();
  }

  Future<void> _soumettre() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _enCours = true);

    try {
      await _service.creerAnnonce(
        titre: _titreController.text.trim().isEmpty
            ? null
            : _titreController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        lienType: _lienType,
        lienValeur: _lienValeurController.text.trim().isEmpty
            ? null
            : _lienValeurController.text.trim(),
        dateFin: _dureeJours == null
            ? null
            : DateTime.now().add(Duration(days: _dureeJours!)),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annonce créée avec succès.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la création: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle annonce')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL image *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'L\'URL image est obligatoire.';
                  final uri = Uri.tryParse(v);
                  if (uri == null ||
                      (!uri.isScheme('http') && !uri.isScheme('https'))) {
                    return 'Entrez une URL valide (http/https).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (_imageUrlController.text.trim().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imageUrlController.text.trim(),
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Container(
                      height: 150,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      alignment: Alignment.center,
                      child: const Text('Aperçu image indisponible'),
                    ),
                  ),
                ),
              if (_imageUrlController.text.trim().isNotEmpty)
                const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _lienType,
                decoration: const InputDecoration(
                  labelText: 'Type de lien (optionnel)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'vendeur',
                    child: Text('Boutique vendeur'),
                  ),
                  DropdownMenuItem(
                    value: 'produit',
                    child: Text('Produit précis'),
                  ),
                  DropdownMenuItem(value: 'externe', child: Text('Lien externe')),
                ],
                onChanged: _enCours
                    ? null
                    : (value) {
                        setState(() {
                          _lienType = value;
                          if (value == null) {
                            _lienValeurController.clear();
                          }
                        });
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Durée (jours, optionnel)',
                  hintText: 'Ex: 7',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final parsed = int.tryParse(value.trim());
                  setState(
                    () => _dureeJours = parsed != null && parsed > 0 ? parsed : null,
                  );
                },
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return null;
                  final parsed = int.tryParse(v);
                  if (parsed == null || parsed <= 0) {
                    return 'Entrez un nombre de jours supérieur à 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lienValeurController,
                enabled: _lienType != null,
                decoration: InputDecoration(
                  labelText: _labelValeurLien,
                  hintText: _hintValeurLien,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (_lienType == null) return null;
                  if (v.isEmpty) {
                    return 'Ce champ est requis pour le type de lien sélectionné.';
                  }
                  if (_lienType == 'externe') {
                    final uri = Uri.tryParse(v);
                    if (uri == null ||
                        (!uri.isScheme('http') && !uri.isScheme('https'))) {
                      return 'Entrez une URL externe valide (http/https).';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _enCours ? null : _soumettre,
                icon: _enCours
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.campaign),
                label: Text(_enCours ? 'Publication...' : 'Publier l\'annonce'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
