import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePreferencesService {
  final SupabaseClient _client = Supabase.instance.client;

  bool get estConnecte => _client.auth.currentUser != null;

  String get _userId => _client.auth.currentUser!.id;

  /// 🔄 Charger langue & thème depuis Supabase
  Future<Map<String, String>?> chargerPreferences() async {
    if (!estConnecte) return null;

    final data = await _client
        .from('profiles')
        .select('language, theme')
        .eq('id', _userId)
        .maybeSingle();

    if (data == null) return null;

    return {
      'language': data['language'] as String? ?? 'fr',
      'theme': data['theme'] as String? ?? 'system',
    };
  }

  /// 💾 Sauvegarder langue & thème vers Supabase
  Future<void> sauvegarderPreferences({
    required Locale locale,
    required ThemeMode themeMode,
  }) async {
    if (!estConnecte) return;

    await _client.from('profiles').upsert({
      'id': _userId,
      'language': locale.languageCode,
      'theme': themeMode.name, // light | dark | system
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
