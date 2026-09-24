import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // ==========================
  // 🔐 INSCRIPTION
  // ==========================
  Future<void> inscrire({
    required String email,
    required String motDePasse,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: motDePasse,
    );
  }

  // ==========================
  // 🔑 CONNEXION
  // ==========================
  Future<void> connecter({
    required String email,
    required String motDePasse,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: motDePasse,
    );
  }

  // ==========================
  // ✉️ CONFIRMATION OTP EMAIL
  // ==========================
  Future<void> confirmerOtpEmail({
    required String email,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: token,
    );
  }

  // ==========================
  // 🔁 RENVOYER OTP EMAIL
  // ==========================
  Future<void> renvoyerOtpEmail({
    required String email,
  }) async {
    await _client.auth.resend(
      type: OtpType.email,
      email: email,
    );
  }

// ==========================
// ✉️ ENVOYER OTP EMAIL (INSCRIPTION)
// ==========================
  Future<void> envoyerOtpEmail({
    required String email,
  }) async {
    await _client.auth.signInWithOtp(
      email: email,
    );
  }

  // ==========================
  // 🚪 DÉCONNEXION
  // ==========================
  Future<void> deconnecter() async {
    await _client.auth.signOut();
  }

  // ==========================
  // 👤 UTILISATEUR COURANT
  // ==========================
  User? get utilisateur => _client.auth.currentUser;

  bool get estConnecte => utilisateur != null;
}
