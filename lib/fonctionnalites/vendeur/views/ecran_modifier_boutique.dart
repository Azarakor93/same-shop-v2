// ===============================================
// ✏️ ÉCRAN MODIFIER BOUTIQUE - VERSION COMPLÈTE
// ===============================================
// Permet de modifier les informations d'une boutique
// Ordre: Nom → Description → Pays → Téléphone → Ville → Quartier

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../coeur/constant/pays.dart';
import '../../../coeur/services/snack_service.dart';
import '../models/boutique.dart';
import '../services/service_vendeur_supabase.dart';

class EcranModifierBoutique extends StatefulWidget {
  final Boutique boutique;

  const EcranModifierBoutique({
    super.key,
    required this.boutique,
  });

  @override
  State<EcranModifierBoutique> createState() => _EcranModifierBoutiqueState();
}

class _EcranModifierBoutiqueState extends State<EcranModifierBoutique> {
  // ===============================================
  // 🎯 FORM & SERVICES
  // ===============================================
  final _formKey = GlobalKey<FormState>();
  final _service = ServiceVendeurSupabase();

  // ===============================================
  // 📝 CONTROLLERS
  // ===============================================
  late final TextEditingController _nomController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _villeController;
  late final TextEditingController _quartierController;

  // ===============================================
  // 🌍 PAYS & ÉTAT
  // ===============================================
  Pays? _paysSelectionne;
  File? _nouveauLogo;
  bool _chargement = false;

  @override
  void initState() {
    super.initState();

    // Initialiser les controllers
    _nomController = TextEditingController(text: widget.boutique.nomBoutique);
    _descriptionController = TextEditingController(
      text: widget.boutique.description ?? '',
    );
    _telephoneController = TextEditingController(
      text: widget.boutique.telephone,
    );
    _villeController = TextEditingController(text: widget.boutique.ville);
    _quartierController = TextEditingController(
      text: widget.boutique.quartier ?? '',
    );

    // Trouver le pays correspondant
    _paysSelectionne = listePays.firstWhere(
      (p) => p.nom == widget.boutique.pays,
      orElse: () => listePays.first,
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _telephoneController.dispose();
    _villeController.dispose();
    _quartierController.dispose();
    super.dispose();
  }

  // ===============================================
  // 📸 SÉLECTIONNER UN NOUVEAU LOGO
  // ===============================================
  Future<void> _selectionnerLogo() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _nouveauLogo = File(image.path);
        });
      }
    } catch (_) {
      if (!mounted) return;
      SnackService.afficher(
        context,
        message: 'Erreur lors de la sélection du logo',
        erreur: true,
      );
    }
  }

  // ===============================================
  // 💾 ENREGISTRER LES MODIFICATIONS
  // ===============================================
  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _chargement = true);

    try {
      // Upload du nouveau logo si sélectionné
      String? logoUrl = widget.boutique.logoUrl;
      if (_nouveauLogo != null) {
        logoUrl = await _service.uploadLogo(_nouveauLogo!);
      }

      // Créer la boutique modifiée
      final boutiqueModifiee = widget.boutique.copyWith(
        nomBoutique: _nomController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        telephone: _telephoneController.text.trim(),
        pays: _paysSelectionne!.nom,
        ville: _villeController.text.trim(),
        quartier: _quartierController.text.trim().isEmpty
            ? null
            : _quartierController.text.trim(),
        logoUrl: logoUrl,
      );

      // Sauvegarder
      await _service.modifierBoutique(boutiqueModifiee);

      if (!mounted) return;

      SnackService.afficher(
        context,
        message: '✅ Modifications enregistrées',
      );

      // Retour à l'écran précédent avec succès
      Navigator.of(context).pop(true);
    } catch (e) {
      SnackService.afficher(
        context,
        message: e.toString(),
        erreur: true,
      );
    } finally {
      if (mounted) {
        setState(() => _chargement = false);
      }
    }
  }

  // ===============================================
  // 🎨 BUILD UI
  // ===============================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // ===============================================
      // 📱 APP BAR
      // ===============================================
      appBar: AppBar(
        title: const Text('Modifier la boutique'),
        centerTitle: true,
        elevation: 0,
      ),

      // ===============================================
      // 📄 BODY
      // ===============================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===============================================
              // 📸 LOGO
              // ===============================================
              Center(
                child: GestureDetector(
                  onTap: _selectionnerLogo,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.outline,
                        width: 2,
                      ),
                      image: _nouveauLogo != null
                          ? DecorationImage(
                              image: FileImage(_nouveauLogo!),
                              fit: BoxFit.cover,
                            )
                          : widget.boutique.logoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(widget.boutique.logoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child:
                        _nouveauLogo == null && widget.boutique.logoUrl == null
                            ? Icon(
                                Icons.store,
                                size: 40,
                                color: colorScheme.primary,
                              )
                            : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _selectionnerLogo,
                  icon: const Icon(Icons.image),
                  label: const Text('Modifier le logo'),
                ),
              ),

              const SizedBox(height: 32),

              // ===============================================
              // 📝 FORMULAIRE - ORDRE CORRIGÉ
              // ===============================================

              // 1️⃣ NOM DE LA BOUTIQUE
              _buildTextField(
                controller: _nomController,
                label: 'Nom de la boutique',
                icon: Icons.store,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est obligatoire';
                  }
                  if (value.trim().length < 3) {
                    return 'Minimum 3 caractères';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 2️⃣ DESCRIPTION
              _buildTextField(
                controller: _descriptionController,
                label: 'Description (optionnel)',
                icon: Icons.description,
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // 3️⃣ PAYS (AVANT LE TÉLÉPHONE)
              _champPays(),

              const SizedBox(height: 16),

              // 4️⃣ TÉLÉPHONE (APRÈS LE PAYS)
              _champTelephone(),

              const SizedBox(height: 16),

              // 5️⃣ VILLE
              _buildTextField(
                controller: _villeController,
                label: 'Ville',
                icon: Icons.location_city,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La ville est obligatoire';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 6️⃣ QUARTIER
              _buildTextField(
                controller: _quartierController,
                label: 'Quartier (optionnel)',
                icon: Icons.place,
              ),

              const SizedBox(height: 32),

              // ===============================================
              // 💾 BOUTON ENREGISTRER
              // ===============================================
              ElevatedButton(
                onPressed: _chargement ? null : _enregistrer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _chargement
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '💾 Enregistrer les modifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================
  // 🧩 WIDGETS RÉUTILISABLES
  // ===============================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  // ===============================================
  // 🌍 CHAMP PAYS (AUTOCOMPLETE)
  // ===============================================
  Widget _champPays() {
    if (_paysSelectionne != null) {
      return TextFormField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Pays',
          prefixText: '${_paysSelectionne!.flag} ',
          prefixIcon: const Icon(Icons.flag),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _paysSelectionne = null;
                _telephoneController.clear();
              });
            },
          ),
        ),
        controller: TextEditingController(
          text: '${_paysSelectionne!.nom} (${_paysSelectionne!.code})',
        ),
      );
    }

    return Autocomplete<Pays>(
      optionsBuilder: (value) => paysTries().where(
        (p) => p.nom.toLowerCase().contains(value.text.toLowerCase()),
      ),
      displayStringForOption: (p) => '${p.flag} ${p.nom}',
      onSelected: (pays) {
        setState(() {
          _paysSelectionne = pays;
          _telephoneController.text = '${pays.code} ';
        });
      },
      fieldViewBuilder: (context, controller, focusNode, _) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Pays',
            hintText: 'Rechercher un pays',
            prefixIcon: const Icon(Icons.flag),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
          ),
          validator: (v) =>
              _paysSelectionne == null ? 'Veuillez sélectionner un pays' : null,
        );
      },
    );
  }

  // ===============================================
  // 📱 CHAMP TÉLÉPHONE (AVEC VALIDATION)
  // ===============================================
  Widget _champTelephone() {
    return TextFormField(
      controller: _telephoneController,
      enabled: _paysSelectionne != null,
      keyboardType: TextInputType.phone,
      inputFormatters: _paysSelectionne == null
          ? []
          : [
              LengthLimitingTextInputFormatter(
                _paysSelectionne!.code.length +
                    1 +
                    _paysSelectionne!.longueurNumero,
              ),
            ],
      validator: (v) {
        if (_paysSelectionne == null) {
          return 'Sélectionnez d\'abord un pays';
        }
        if (v == null || v.isEmpty) {
          return 'Le téléphone est obligatoire';
        }
        final numero = v.replaceAll(_paysSelectionne!.code, '').trim();
        if (numero.length != _paysSelectionne!.longueurNumero) {
          return 'Numéro invalide (${_paysSelectionne!.longueurNumero} chiffres requis)';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Téléphone',
        hintText: _paysSelectionne != null
            ? '${_paysSelectionne!.code} XX XX XX XX'
            : 'Sélectionnez un pays d\'abord',
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
    );
  }
}
