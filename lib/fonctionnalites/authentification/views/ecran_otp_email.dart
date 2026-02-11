import 'dart:async';
import 'package:flutter/material.dart';

import '../../../Partage/widgets/header_connexion.dart';
import '../../../coeur/languages/gestion_langage.dart';
import '../../../coeur/services/snack_service.dart';
import '../../../coeur/services/supabase_auth_service.dart';

class EcranOtpEmail extends StatefulWidget {
  final String email;

  const EcranOtpEmail({
    super.key,
    required this.email,
  });

  @override
  State<EcranOtpEmail> createState() => _EcranOtpEmailState();
}

class _EcranOtpEmailState extends State<EcranOtpEmail> {
  final SupabaseAuthService authService = SupabaseAuthService();

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _tempsRestant = 60;

  bool afficherErreur = false;
  bool otpExpire = false;

  @override
  void initState() {
    super.initState();
    _demarrerTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _codeOtp => _controllers.map((c) => c.text).join();

  bool get _otpComplet => _controllers.every((c) => c.text.isNotEmpty);

  void _demarrerTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_tempsRestant == 0) {
        timer.cancel();
        otpExpire = true;
      } else {
        setState(() => _tempsRestant--);
      }
    });
  }

  // ==========================
  // ===== CONFIRMATION =======
  // ==========================

  Future<void> _confirmerOtp() async {
    if (!_otpComplet || otpExpire) {
      setState(() => afficherErreur = true);
      return;
    }

    // ✅ BYPASS DEV
    if (_codeOtp != '939393') {
      SnackService.afficher(context,
          message: Langage.t(context, 'otp_invalid'), erreur: true);
      return;
    }

    // 🔜 PROD : confirmation réelle Supabase
    // await authService.confirmerOtpEmail(
    //   email: widget.email,
    //   token: _codeOtp,
    // );

    SnackService.afficher(context,
        message: Langage.t(context, 'account_confirmed'));

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/accueil',
      (_) => false,
    );
  }

  // void _afficherSnack(String message, {bool erreur = false}) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(message),
  //       backgroundColor: erreur ? Colors.red : null,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeaderConnexion(),
              Text(
                Langage.t(context, 'verify_email'),
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(counterText: ''),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (_otpComplet) _confirmerOtp();
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _confirmerOtp,
                  child: Text(Langage.t(context, 'confirm')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
