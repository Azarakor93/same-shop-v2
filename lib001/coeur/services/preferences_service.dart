import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferencesService {
  static const _keyLangue = 'language';
  static const _keyTheme = 'theme';

  /// 🔤 LANGUE
  static Future<void> sauvegarderLangue(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLangue, locale.languageCode);
  }

  static Future<Locale> chargerLangue() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_keyLangue) ?? 'fr';
    return Locale(code);
  }

  /// 🎨 THÈME
  static Future<void> sauvegarderTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, mode.name); // light | dark | system
  }

  static Future<ThemeMode> chargerTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyTheme) ?? 'system';

    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
