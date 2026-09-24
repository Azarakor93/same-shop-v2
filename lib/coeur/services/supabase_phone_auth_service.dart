import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePhoneAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // 📲 Envoyer le code OTP
  Future<void> envoyerCode(String phone) async {
    await _client.auth.signInWithOtp(
      phone: phone,
    );
  }

  // 🔢 Vérifier le code OTP
  Future<void> verifierCode({
    required String phone,
    required String code,
  }) async {
    await _client.auth.verifyOTP(
      phone: phone,
      token: code,
      type: OtpType.sms,
    );
  }
}
