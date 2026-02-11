import 'dart:async';
import 'package:flutter/material.dart';

import '../../../coeur/languages/gestion_langage.dart';
import '../../../coeur/services/snack_service.dart';
import '../../../coeur/services/supabase_phone_auth_service.dart';

class EcranOtp extends StatefulWidget {
  final String phone;

  const EcranOtp({
    super.key,
    required this.phone,
  });

  @override
  State<EcranOtp> createState() => _EcranOtpState();
}

class _EcranOtpState extends State<EcranOtp> {
  final TextEditingController codeController = TextEditingController();
  final SupabasePhoneAuthService _service = SupabasePhoneAuthService();

  bool chargement = false;
  int secondesRestantes = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _demarrerTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    codeController.dispose();
    super.dispose();
  }

  // ⏱️ Démarrer / redémarrer le timer OTP
  void _demarrerTimer() {
    secondesRestantes = 60;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondesRestantes == 0) {
        timer.cancel();
      } else {
        setState(() => secondesRestantes--);
      }
    });
  }

  // 🔁 Renvoyer le code (SMS)
  Future<void> _renvoyerCode() async {
    try {
      await _service.envoyerCode(widget.phone);
      _demarrerTimer();

      if (!mounted) return;
      SnackService.afficher(
        context,
        message: Langage.t(context, 'otp_resent'),
      );
    } catch (_) {
      if (!mounted) return;
      SnackService.afficher(
        context,
        message: Langage.t(context, 'otp_send_error'),
        erreur: true,
      );
    }
  }

  // 🔊 Appel vocal (UI prête – implémentation plus tard)
  void _appelVocal() {
    SnackService.afficher(context,
        message: Langage.t(context, 'voice_coming_soon'));
  }

  // ✅ Vérifier le code OTP
  Future<void> _verifierCode() async {
    if (codeController.text.trim().length < 6) return;

    setState(() => chargement = true);

    try {
      await _service.verifierCode(
        phone: widget.phone,
        code: codeController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context); // AuthRouter prendra le relais
    } catch (_) {
      if (!mounted) return;
      SnackService.afficher(context,
          message: Langage.t(context, 'login_error'), erreur: true);
    } finally {
      if (mounted) setState(() => chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(Langage.t(context, 'otp_title')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),

                      Icon(
                        Icons.lock_outline,
                        size: 80,
                        color: theme.colorScheme.primary,
                      ),

                      const SizedBox(height: 24),

                      Text(
                        Langage.t(context, 'otp_title'),
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '${Langage.t(context, 'otp_sent_to')} ${widget.phone}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 8),

                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          Langage.t(context, 'wrong_number'),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 🔢 Champ OTP
                      TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          letterSpacing: 8,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: Langage.t(context, 'otp_code'),
                          counterText: '',
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 🔘 Bouton Vérifier
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: chargement ? null : _verifierCode,
                          child: chargement
                              ? const CircularProgressIndicator()
                              : Text(Langage.t(context, 'otp_verify')),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ⏱️ Timer / Renvoyer
                      TextButton(
                        onPressed:
                            secondesRestantes == 0 ? _renvoyerCode : null,
                        child: secondesRestantes == 0
                            ? Text(Langage.t(context, 'resend_code'))
                            : Text(
                                '${Langage.t(context, 'resend_in')} '
                                '00:${secondesRestantes.toString().padLeft(2, '0')}',
                              ),
                      ),

                      const SizedBox(height: 8),

                      // 📞 Appel vocal
                      TextButton(
                        onPressed: _appelVocal,
                        child: Text(Langage.t(context, 'call_me')),
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
