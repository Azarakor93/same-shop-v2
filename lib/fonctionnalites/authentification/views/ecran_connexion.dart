import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:same_shop/coeur/services/snack_service.dart';
import '../../../fonctionnalites/authentification/views/ecran_inscription.dart';
import '../../../Partage/widgets/header_connexion.dart';
import '../../../coeur/languages/gestion_langage.dart';
import '../../../coeur/constant/pays.dart';
import '../../../coeur/services/supabase_auth_service.dart';
import '../../../coeur/services/supabase_phone_auth_service.dart';
import 'ecran_otp.dart';

class EcranConnexion extends StatefulWidget {
  const EcranConnexion({super.key});

  @override
  State<EcranConnexion> createState() => _EcranConnexionState();
}

class _EcranConnexionState extends State<EcranConnexion> {
  bool connexionParTelephone = false;
  bool afficherMotDePasse = false;
  bool chargement = false;

  Pays? paysSelectionne;

  final emailController = TextEditingController();
  final motDePasseController = TextEditingController();
  final telephoneController = TextEditingController();

  final TextEditingController paysController = TextEditingController();
  final FocusNode paysFocusNode = FocusNode();

  final SupabaseAuthService _authService = SupabaseAuthService();
  final SupabasePhoneAuthService _phoneService = SupabasePhoneAuthService();

  // 🔐 règles de longueur
  static const Map<String, int> longueurNumeroParPays = {
    '+228': 8, // Togo
    '+229': 8,
    '+225': 10,
    '+221': 9,
    '+33': 9,
  };

  @override
  void initState() {
    super.initState();

    // 🇹🇬 Auto-sélection Togo
    final togo = listePays.firstWhere((p) => p.code == '+228');
    paysSelectionne = togo;
    paysController.text = '${togo.nom} (${togo.code})';
  }

  @override
  void dispose() {
    emailController.dispose();
    motDePasseController.dispose();
    telephoneController.dispose();
    paysController.dispose();
    paysFocusNode.dispose();
    super.dispose();
  }

  // ==========================
  // ===== CONNEXIONS =========
  // ==========================

  Future<void> _connexionEmail() async {
    setState(() => chargement = true);
    try {
      await _authService.connecter(
        email: emailController.text.trim(),
        motDePasse: motDePasseController.text,
      );
      if (!mounted) return;
      SnackService.afficher(context,
          message: Langage.t(context, 'login_success'));
    } catch (_) {
      if (!mounted) return;
      SnackService.afficher(context,
          message: Langage.t(context, 'login_error'), erreur: true);
    } finally {
      setState(() => chargement = false);
    }
  }

  Future<void> _connexionTelephone() async {
    if (paysSelectionne == null || telephoneController.text.trim().isEmpty) {
      SnackService.afficher(context,
          message: Langage.t(context, 'phone_invalid'), erreur: true);
      return;
    }

    final digits = telephoneController.text.replaceAll(RegExp(r'\D'), '');
    final longueur = longueurNumeroParPays[paysSelectionne!.code];

    if (longueur != null && digits.length != longueur) {
      SnackService.afficher(context,
          message: Langage.t(context, 'phone_invalid_length'), erreur: true);
      return;
    }

    final phone = '${paysSelectionne!.code}$digits';

    setState(() => chargement = true);
    try {
      await _phoneService.envoyerCode(phone);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EcranOtp(phone: phone),
        ),
      );
    } catch (e) {
      SnackService.afficher(
        context,
        message: Langage.t(context, 'otp_send_error'),
        erreur: true,
      );
    } finally {
      setState(() => chargement = false);
    }
  }

  // void _snack(String message, {bool error = false}) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(message),
  //       backgroundColor: error ? Colors.red : null,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeaderConnexion(),

// 🔐 TITRE
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Langage.t(context, 'sign_in'),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.left,
                  )),

              const SizedBox(height: 1),

              // 👋 SOUS-TITRE
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Langage.t(context, 'welcome_back'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.left,
                  )),

              const SizedBox(height: 36),

              // 🔁 Sélecteur
              Row(
                children: [
                  Expanded(
                    child: _CarteModeConnexion(
                      icon: Icons.email_outlined,
                      label: Langage.t(context, 'email'),
                      isActive: !connexionParTelephone,
                      onTap: () {
                        setState(() {
                          connexionParTelephone = false;
                          telephoneController.clear();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CarteModeConnexion(
                      icon: Icons.phone_outlined,
                      label: Langage.t(context, 'phone'),
                      isActive: connexionParTelephone,
                      onTap: () {
                        setState(() {
                          connexionParTelephone = true;
                          emailController.clear();
                          motDePasseController.clear();
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 📱 Téléphone
              if (connexionParTelephone) ...[
                _autocompletePays(theme),
                const SizedBox(height: 16),
                TextField(
                  controller: telephoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    FormatNumeroTelephone(),
                  ],
                  decoration: InputDecoration(
                    labelText: Langage.t(context, 'phone_number'),
                    prefixText: '${paysSelectionne?.code ?? ''} ',
                  ),
                ),
              ]

              // ✉️ Email
              else ...[
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: Langage.t(context, 'email'),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: motDePasseController,
                  obscureText: !afficherMotDePasse,
                  decoration: InputDecoration(
                    labelText: Langage.t(context, 'password'),
                    suffixIcon: IconButton(
                      icon: Icon(
                        afficherMotDePasse
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                        () => afficherMotDePasse = !afficherMotDePasse,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 🔘 Bouton principal
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: chargement
                      ? null
                      : connexionParTelephone
                          ? _connexionTelephone
                          : _connexionEmail,
                  child: chargement
                      ? const CircularProgressIndicator()
                      : Text(
                          connexionParTelephone
                              ? Langage.t(context, 'send_code')
                              : Langage.t(context, 'sign_in'),
                        ),
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      Langage.t(context, 'or_sign_in_with'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 20),

              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  BoutonSocial(asset: 'assets/icons/Google.png'),
                  BoutonSocial(asset: 'assets/icons/Facebook.png'),
                  BoutonSocial(asset: 'assets/icons/Phone.png'),
                ],
              ),
              const SizedBox(height: 28),
              // Ajouter partie inscription
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(Langage.t(context, 'no_account')),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EcranInscription(),
                        ),
                      );
                    },
                    child: Text(
                      Langage.t(context, 'sign_up'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================
  // ===== AUTOCOMPLETE =======
  // ==========================

  Widget _autocompletePays(ThemeData theme) {
    return Autocomplete<Pays>(
      optionsBuilder: (value) {
        final q = value.text.toLowerCase();
        return paysTries().where(
          (p) => p.nom.toLowerCase().contains(q) || p.code.contains(q),
        );
      },
      displayStringForOption: (p) => '${p.flag} ${p.nom} (${p.code})',
      onSelected: (p) {
        setState(() {
          paysSelectionne = p;
          paysController.text = '${p.nom} (${p.code})';
        });
        paysFocusNode.unfocus();
      },
      fieldViewBuilder: (context, controller, focusNode, _) {
        // 🔑 Synchronisation obligatoire
        controller.value = paysController.value;

        return TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: paysSelectionne != null,
          decoration: InputDecoration(
            labelText: Langage.t(context, 'country'),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                paysSelectionne?.flag ?? '🌐',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                ),
              ),
            ),
            suffixIcon: paysSelectionne != null
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        paysSelectionne = null;
                        paysController.clear();
                        controller.clear(); // 🔑 important
                      });
                      focusNode.requestFocus();
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
}

// ==========================
// ===== WIDGETS =========
// ==========================

class BoutonSocial extends StatelessWidget {
  final String asset;
  final VoidCallback? onTap;

  const BoutonSocial({
    super.key,
    required this.asset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color.fromARGB(255, 50, 50, 50) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color.fromARGB(255, 133, 133, 133)
                      .withValues(alpha: 0.2)
                  : const Color.fromARGB(255, 0, 78, 78).withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
          ),
        ),
        child: Center(
          child: Image.asset(asset, width: 40, height: 40),
        ),
      ),
    );
  }
}

class FormatNumeroTelephone extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i % 2 == 0 && i != 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// ==================================
// ===== CARTE MODE CONNEXION =======
// ==================================
class _CarteModeConnexion extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CarteModeConnexion({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surface,
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.4),
          ),
        ),
        child: Stack(
          alignment: Alignment.center, // 🔑 le centre NE BOUGE PAS
          children: [
            // 🎯 CONTENU ORIGINAL (centré, inchangé)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.iconTheme.color,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodyMedium?.color,
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
