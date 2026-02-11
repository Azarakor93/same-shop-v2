import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'coeur/themes/theme_clair.dart';
import 'coeur/themes/theme_sombre.dart';
// import 'coeur/langages/gestion_langage.dart';
import 'coeur/services/preferences_service.dart';
import 'coeur/services/supabase_preferences_service.dart';
import 'coeur/configuration/supabase_config.dart';

import 'partage/widgets/auth_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔗 Initialisation Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // 📦 Chargement des préférences locales
  final initialLocale = await PreferencesService.chargerLangue();
  final initialThemeMode = await PreferencesService.chargerTheme();

  runApp(
    SameShopApp(
      initialLocale: initialLocale,
      initialThemeMode: initialThemeMode,
    ),
  );
}

class SameShopApp extends StatefulWidget {
  final Locale initialLocale;
  final ThemeMode initialThemeMode;

  const SameShopApp({
    super.key,
    required this.initialLocale,
    required this.initialThemeMode,
  });

  @override
  State<SameShopApp> createState() => _SameShopAppState();
}

class _SameShopAppState extends State<SameShopApp> {
  late Locale _locale;
  late ThemeMode _themeMode;

  final SupabasePreferencesService _supabasePrefs =
      SupabasePreferencesService();

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    _themeMode = widget.initialThemeMode;
  }

  // 🌍 Changer la langue
  Future<void> changerLangue(Locale locale) async {
    setState(() => _locale = locale);

    // 📦 Local
    await PreferencesService.sauvegarderLangue(locale);

    // ☁️ Supabase (si connecté)
    await _supabasePrefs.sauvegarderPreferences(
      locale: locale,
      themeMode: _themeMode,
    );
  }

  // 🎨 Changer le thème
  Future<void> changerTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);

    // 📦 Local
    await PreferencesService.sauvegarderTheme(mode);

    // ☁️ Supabase (si connecté)
    await _supabasePrefs.sauvegarderPreferences(
      locale: _locale,
      themeMode: mode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🌍 LANGUE
      locale: _locale,
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 🎨 THÈMES
      theme: ThemeClair.theme,
      darkTheme: ThemeSombre.theme,
      themeMode: _themeMode,

      // 🔐 ROUTEUR D’AUTHENTIFICATION
      home: const AuthRouter(),
    );
  }
}
