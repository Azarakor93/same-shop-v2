// ===============================================
// 🔐 CONFIGURATION SUPABASE
// ===============================================
// Valeurs injectées au lancement, jamais écrites dans le code :
//   flutter run --dart-define-from-file=config/cloud.json
// Modèle du fichier : config/example.json

class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Stoppe le démarrage avec un message clair si la config est absente.
  static void verifier() {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Configuration Supabase manquante : lance l\'app avec '
        '--dart-define-from-file=config/cloud.json (modèle : config/example.json).',
      );
    }
  }
}
