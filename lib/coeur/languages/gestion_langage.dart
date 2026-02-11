import 'package:flutter/material.dart';
import 'fr.dart';
import 'en.dart';

class Langage {
  static Map<String, String> getTextes(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return en;
      case 'fr':
      default:
        return fr;
    }
  }

  static String t(BuildContext context, String cle) {
    final locale = Localizations.localeOf(context);
    final textes = getTextes(locale);
    return textes[cle] ?? cle;
  }
}
