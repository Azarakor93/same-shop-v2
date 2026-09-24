import 'package:flutter/material.dart';

/// 🌙 THÈME SOMBRE - VERSION GLACIALE
/// Cards qui ressortent avec effet de profondeur
class ThemeSombre {
  // 🎨 PALETTE DE COULEURS GLACIALE
  static const Color tealPrimary = Color(0xFF00BFA5);
  static const Color tealDark = Color(0xFF003D33); // ← NOIR pour texte
  static const Color tealLight = Color(0xFF64FFDA);
  static const Color amberAccent = Color(0xFFFFB300);

  // ❄️ BACKGROUNDS GLACIAUX
  static const Color background = Color(0xFF0F1419); // Noir-bleuté profond
  static const Color surface = Color(0xFF1A1F26); // Gris-bleu foncé (cards)
  static const Color surfaceVariant = Color(0xFF242A32); // Gris-bleu variant

  static const Color textPrimary = Color(0xFFE8EAED);
  static const Color textSecondary = Color(0xFF9AA0A6);

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,

      primaryColor: tealPrimary,
      scaffoldBackgroundColor: background, // ← Background glacial sombre

      colorScheme: const ColorScheme.dark(
        primary: Color.fromARGB(255, 0, 225, 195),
        onPrimary: Color(0xFF003D33),
        primaryContainer: Color(0xFF005E4D),
        onPrimaryContainer: tealLight,

        secondary: amberAccent,
        onSecondary: Color(0xFF3E2723),
        secondaryContainer: Color(0xFF5D4037),
        onSecondaryContainer: Color(0xFFFFD54F),

        surface: surface, // ← Cards gris-bleu foncé
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceVariant,

        error: Color(0xFFCF6679),
        onError: Color(0xFF370B0B),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: surface, // ← AppBar gris-bleu
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(
          color: textPrimary,
          size: 22,
        ),
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.1,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.1,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tealPrimary,
          foregroundColor: Colors.black,
          elevation: 4,
          shadowColor: tealPrimary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tealLight,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tealPrimary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant, // ← Input gris-bleu
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF353B45), // ← Border glaciale sombre
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF353B45),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: tealPrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFCF6679),
            width: 1,
          ),
        ),
        labelStyle: const TextStyle(
          fontSize: 13,
          color: textSecondary,
          fontWeight: FontWeight.w400,
        ),
        hintStyle: TextStyle(
          fontSize: 13,
          color: textSecondary.withValues(alpha: 0.6),
          fontWeight: FontWeight.w400,
        ),
      ),

      // ❄️ CARDS GLACIALES - LE PLUS IMPORTANT !
      cardTheme: CardThemeData(
        elevation: 4, // ← Ombre forte
        shadowColor: Colors.black.withValues(alpha: 0.4), // ← Ombre glaciale sombre
        color: surface, // ← Gris-bleu foncé
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFF353B45), // ← Border subtile mais visible
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 4,
        ),
      ),

      sliderTheme: const SliderThemeData(
        activeTrackColor: tealPrimary,
        inactiveTrackColor: Color(0xFF353B45),
        thumbColor: tealPrimary,
        overlayColor: Color(0x1F00BFA5),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tealPrimary;
          }
          return const Color(0xFF5F6368);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tealPrimary.withValues(alpha: 0.5);
          }
          return const Color(0xFF353B45);
        }),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tealPrimary,
        foregroundColor: Colors.black,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        extendedSizeConstraints: const BoxConstraints.tightFor(height: 56),
        extendedIconLabelSpacing: 8,
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF353B45),
        thickness: 1,
        space: 1,
      ),

      // ❄️ BOTTOM SHEET GLACIAL
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 12,
        shadowColor: Colors.black,
      ),

      // ❄️ DIALOG GLACIAL
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.5),
      ),

      // ❄️ TAB BAR GLACIAL
      tabBarTheme: TabBarThemeData(
        labelColor: tealLight,
        unselectedLabelColor: textSecondary,
        indicatorColor: tealPrimary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
