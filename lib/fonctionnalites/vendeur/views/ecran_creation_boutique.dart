// ===============================================
// 🏪 ÉCRAN CRÉATION BOUTIQUE
// ===============================================
// Formulaire professionnel pour créer une boutique
// Première boutique GRATUITE ✨

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../../../coeur/constant/pays.dart';
import '../../../coeur/services/snack_service.dart';
import '../services/service_vendeur_supabase.dart';
import '../services/service_localisation.dart';
import 'ecran_liste_boutiques.dart';

class EcranCreationBoutique extends StatefulWidget {
  final bool estPremiere;

  const EcranCreationBoutique({
    super.key,
    this.estPremiere = false,
  });

  @override
  State<EcranCreationBoutique> createState() => _EcranCreationBoutiqueState();
}

class _EcranCreationBoutiqueState extends State<EcranCreationBoutique> {
  // ===============================================
  // 🎯 FORM & SERVICES
  // ===============================================
  final _formKey = GlobalKey<FormState>();
  final _serviceVendeur = ServiceVendeurSupabase();
  final _serviceLocalisation = ServiceLocalisation();

  // ===============================================
  // 📝 CONTROLLERS
  // ===============================================
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _villeController = TextEditingController();
  final _quartierController = TextEditingController();

  // ===============================================
  // 🌍 PAYS & LOCALISATION
  // ===============================================
  Pays? _paysSelectionne;
  Position? _position;

  // ===============================================
  // 📦 ÉTAT
  // ===============================================
  bool _chargement = false;
  bool _localisationEnCours = false;
  File? _logoSelectionne;

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
  // 📸 SÉLECTION LOGO
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
          _logoSelectionne = File(image.path);
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
  // 📍 LOCALISATION
  // ===============================================
  Future<void> _recupererLocalisation() async {
    setState(() => _localisationEnCours = true);

    try {
      final position = await _serviceLocalisation.positionActuelle();
      setState(() {
        _position = position;
        _localisationEnCours = false;
      });

      if (!mounted) return;
      SnackService.afficher(
        context,
        message: '📍 Localisation récupérée',
      );
    } catch (e) {
      setState(() => _localisationEnCours = false);
      SnackService.afficher(
        context,
        message: e.toString(),
        erreur: true,
      );
    }
  }

  // ===============================================
  // ✅ CRÉATION BOUTIQUE
  // ===============================================
  Future<void> _creerBoutique() async {
    if (!_formKey.currentState!.validate()) return;

    if (_position == null) {
      SnackService.afficher(
        context,
        message: 'Veuillez activer la géolocalisation',
        erreur: true,
      );
      return;
    }

    setState(() => _chargement = true);

    try {
      String? logoUrl;
      if (_logoSelectionne != null) {
        logoUrl = await _serviceVendeur.uploadLogo(_logoSelectionne!);
      }

      await _serviceVendeur.creerBoutique(
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
        latitude: _position!.latitude,
        longitude: _position!.longitude,
      );

      if (!mounted) return;

      SnackService.afficher(
        context,
        message: '🎉 Boutique créée avec succès',
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const EcranListeBoutiques(),
        ),
      );
    } catch (e) {
      SnackService.afficher(
        context,
        message: e.toString(),
        erreur: true,
      );
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  // ===============================================
  // 🎨 UI
  // ===============================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.estPremiere
            ? 'Créer ma première boutique'
            : 'Créer une boutique'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🎁 BADGE PREMIÈRE BOUTIQUE GRATUITE
              if (widget.estPremiere) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.1),
                        colorScheme.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.card_giftcard,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎉 Première boutique GRATUITE !',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Créez votre boutique sans frais',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 📸 LOGO
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
                      image: _logoSelectionne != null
                          ? DecorationImage(
                              image: FileImage(_logoSelectionne!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _logoSelectionne == null
                        ? Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: colorScheme.primary,
                          )
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              _buildTextField(
                controller: _nomController,
                label: 'Nom de la boutique',
                icon: Icons.store,
                validator: (v) => v == null || v.trim().length < 3
                    ? 'Minimum 3 caractères'
                    : null,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _descriptionController,
                label: 'Description (optionnel)',
                icon: Icons.description,
                maxLines: 3,
                textAlignVertical: TextAlignVertical.center,
              ),

              const SizedBox(height: 16),

              _champPays(),
              const SizedBox(height: 16),
              _champTelephone(),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _villeController,
                label: 'Ville',
                icon: Icons.location_city,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ville obligatoire' : null,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _quartierController,
                label: 'Quartier (optionnel)',
                icon: Icons.place,
              ),

              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: _localisationEnCours ? null : _recupererLocalisation,
                icon: _localisationEnCours
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : Icon(
                        _position != null
                            ? Icons.check_circle
                            : Icons.my_location,
                      ),
                label: Text(
                  _position != null
                      ? 'Localisation activée'
                      : 'Activer la localisation',
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _chargement ? null : _creerBoutique,
                child: _chargement
                    ? const CircularProgressIndicator()
                    : const Text('🚀 Créer ma boutique'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================
  // 🧩 WIDGETS
  // ===============================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextAlignVertical? textAlignVertical,
    EdgeInsetsGeometry? contentPadding,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      textAlignVertical: textAlignVertical,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        contentPadding: contentPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
    );
  }

  Widget _champPays() {
    if (_paysSelectionne != null) {
      return TextFormField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Pays',
          prefixText: '${_paysSelectionne!.flag} ',
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
          decoration: const InputDecoration(
            labelText: 'Pays',
            prefixIcon: Icon(Icons.flag),
          ),
        );
      },
    );
  }

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
          return 'Sélectionnez un pays';
        }
        final numero = v!.replaceAll(_paysSelectionne!.code, '').trim();
        return numero.length == _paysSelectionne!.longueurNumero
            ? null
            : 'Numéro invalide';
      },
      decoration: const InputDecoration(
        labelText: 'Téléphone',
        prefixIcon: Icon(Icons.phone),
      ),
    );
  }
}
