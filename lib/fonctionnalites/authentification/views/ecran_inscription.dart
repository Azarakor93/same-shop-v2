import 'package:flutter/material.dart';

import '../../../partage/widgets/header_connexion.dart';
import '../../../coeur/languages/gestion_langage.dart';
import '../../../coeur/services/snack_service.dart';
import '../../../coeur/services/supabase_auth_service.dart';
import '../../../coeur/services/supabase_phone_auth_service.dart';
import 'ecran_otp.dart';
import 'ecran_otp_email.dart';

enum TypeInscription { email, telephone }

class EcranInscription extends StatefulWidget {
  const EcranInscription({super.key});

  @override
  State<EcranInscription> createState() => _EcranInscriptionState();
}

class _EcranInscriptionState extends State<EcranInscription> {
  // ==========================
  // ===== ÉTAT & SERVICES ====
  // ==========================

  final _formKey = GlobalKey<FormState>();
  final SupabaseAuthService _authService = SupabaseAuthService();
  final SupabasePhoneAuthService _phoneService = SupabasePhoneAuthService();

  TypeInscription typeInscription = TypeInscription.email;

  bool afficherMotDePasse = false;
  bool afficherConfirmation = false;
  bool chargement = false;

  // ==========================
  // ===== CONTROLLERS ========
  // ==========================

  final nomController = TextEditingController();
  final emailController = TextEditingController();
  final motDePasseController = TextEditingController();
  final confirmationController = TextEditingController();
  final telephoneController = TextEditingController();

  @override
  void dispose() {
    nomController.dispose();
    emailController.dispose();
    motDePasseController.dispose();
    confirmationController.dispose();
    telephoneController.dispose();
    super.dispose();
  }

  // ==========================
  // ===== INSCRIPTION ========
  // ==========================

  Future<void> _soumettre() async {
    // 🔹 Nettoie les anciens messages
    ScaffoldMessenger.of(context).clearSnackBars();

    if (!_formKey.currentState!.validate()) return;

    setState(() => chargement = true);

    try {
      if (typeInscription == TypeInscription.telephone) {
        // 📲 Par SMS : le compte est créé quand le code est vérifié
        final phone = _numeroInternational(telephoneController.text)!;
        await _phoneService.envoyerCode(phone);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => EcranOtp(phone: phone)),
        );
        return;
      }

      await _authService.inscrire(
        email: emailController.text.trim(),
        motDePasse: motDePasseController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EcranOtpEmail(
            email: emailController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      debugPrint('ERREUR SUPABASE BRUTE: $e');
      SnackService.afficher(
        context,
        message: typeInscription == TypeInscription.telephone
            ? Langage.t(context, 'otp_send_error')
            : _messageErreur(e),
        erreur: true,
      );
    } finally {
      if (mounted) setState(() => chargement = false);
    }
  }

  // ==========================
  // ===== GESTION ERREURS ====
  // ==========================

  String _messageErreur(dynamic erreur) {
    final texte = erreur.toString().toLowerCase();

    if (texte.contains('already registered') ||
        texte.contains('already in use')) {
      return Langage.t(context, 'email_already_used');
    }

    if (texte.contains('email_provider_disabled') ||
        texte.contains('email signups are disabled')) {
      return Langage.t(context, 'email_signup_disabled');
    }

    if (texte.contains('rate limit')) {
      return Langage.t(context, 'too_many_requests');
    }

    if (texte.contains('password')) {
      return Langage.t(context, 'password_invalid');
    }

    if (texte.contains('network')) {
      return Langage.t(context, 'network_error');
    }

    return Langage.t(context, 'unknown_error');
  }

  // void _snack(String message, {bool erreur = false}) {
  //   final theme = Theme.of(context);

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(
  //         message,
  //         style: TextStyle(
  //           color: erreur
  //               ? theme.colorScheme.onError
  //               : theme.colorScheme.onPrimary,
  //           fontWeight: FontWeight.w600,
  //         ),
  //       ),
  //       backgroundColor:
  //           erreur ? theme.colorScheme.error : theme.colorScheme.primary,
  //       behavior: SnackBarBehavior.floating,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       margin: const EdgeInsets.all(16),
  //     ),
  //   );
  // }

  // ==========================
  // ===== UI =================
  // ==========================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeaderConnexion(),
                _titre(theme),
                const SizedBox(height: 24),
                _selecteurType(),
                const SizedBox(height: 24),
                typeInscription == TypeInscription.email
                    ? _formulaireEmail()
                    : _formulaireTelephone(),
                const SizedBox(height: 28),
                _boutonPrincipal(),
                const SizedBox(height: 24),
                _lienConnexion(theme),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================
  // ===== SECTIONS UI ========
  // ==========================

  Widget _titre(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Langage.t(context, 'create_account'),
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(Langage.t(context, 'join_same_shop')),
      ],
    );
  }

  Widget _selecteurType() {
    return SegmentedButton<TypeInscription>(
      segments: const [
        ButtonSegment(
          value: TypeInscription.email,
          label: Text('Email'),
          icon: Icon(Icons.email_outlined),
        ),
        ButtonSegment(
          value: TypeInscription.telephone,
          label: Text('Téléphone'),
          icon: Icon(Icons.phone_outlined),
        ),
      ],
      selected: {typeInscription},
      onSelectionChanged: (value) {
        setState(() => typeInscription = value.first);
      },
    );
  }

  Widget _formulaireEmail() {
    return Column(
      children: [
        TextFormField(
          controller: nomController,
          decoration:
              InputDecoration(labelText: Langage.t(context, 'full_name')),
          validator: (v) => v == null || v.trim().isEmpty
              ? Langage.t(context, 'name_required')
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          onChanged: (_) {
            ScaffoldMessenger.of(context).clearSnackBars();
          },
          decoration: InputDecoration(
            labelText: Langage.t(context, 'email'),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return Langage.t(context, 'email_required');
            }
            if (!v.contains('@')) {
              return Langage.t(context, 'email_invalid');
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: motDePasseController,
          obscureText: !afficherMotDePasse,
          decoration: InputDecoration(
            labelText: Langage.t(context, 'password'),
            suffixIcon: IconButton(
              icon: Icon(
                afficherMotDePasse ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => afficherMotDePasse = !afficherMotDePasse),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return Langage.t(context, 'password_required');
            }
            if (v.length < 8) {
              return Langage.t(context, 'password_too_short');
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: confirmationController,
          obscureText: !afficherConfirmation,
          decoration: InputDecoration(
            labelText: Langage.t(context, 'confirm_password'),
            suffixIcon: IconButton(
              icon: Icon(
                afficherConfirmation ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => afficherConfirmation = !afficherConfirmation),
            ),
          ),
          validator: (v) => v != motDePasseController.text
              ? Langage.t(context, 'password_not_match')
              : null,
        ),
      ],
    );
  }

  Widget _formulaireTelephone() {
    return TextFormField(
      controller: telephoneController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: Langage.t(context, 'phone_number'),
        hintText: '+228 90 00 00 00',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return Langage.t(context, 'phone_required');
        }
        if (_numeroInternational(v) == null) {
          return Langage.t(context, 'phone_invalid');
        }
        return null;
      },
    );
  }

  // 📞 Format international exigé par Supabase.
  // Sans indicatif, on suppose le Togo (+228), comme l'écran de connexion.
  String? _numeroInternational(String saisie) {
    final texte = saisie.trim();
    final chiffres = texte.replaceAll(RegExp(r'\D'), '');

    if (texte.startsWith('+')) {
      return chiffres.length >= 8 && chiffres.length <= 15
          ? '+$chiffres'
          : null;
    }
    return chiffres.length == 8 ? '+228$chiffres' : null;
  }

  Widget _boutonPrincipal() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: chargement ? null : _soumettre,
        child: chargement
            ? const CircularProgressIndicator()
            : Text(Langage.t(context, 'create_account')),
      ),
    );
  }

  Widget _lienConnexion(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(Langage.t(context, 'already_have_account')),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            Langage.t(context, 'sign_in'),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
