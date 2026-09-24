import 'package:flutter/material.dart';

/// 🌞 THÈME CLAIR - VERSION GLACIALE
/// Cards qui ressortent avec effet de profondeur
class ThemeClair {
  // 🎨 PALETTE DE COULEURS GLACIALE
  static const Color tealPrimary = Color(0xFF00BFA5);
  static const Color tealDark = Color(0xFF008E76);
  static const Color tealLight = Color(0xFF5DF2D6);
  static const Color amberAccent = Color(0xFFFFB300);

  // ❄️ BACKGROUNDS GLACIAUX
  static const Color background = Color(0xFFF0F4F8); // Bleu-gris glacial
  static const Color surface = Color(0xFFFFFFFF); // Blanc pur (cards)
  static const Color surfaceVariant = Color(0xFFF8FAFB); // Blanc-bleuté

  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,

      primaryColor: tealPrimary,
      scaffoldBackgroundColor: background, // ← Background glacial

      colorScheme: const ColorScheme.light(
        primary: tealPrimary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE0F7F4),
        onPrimaryContainer: tealDark,

        secondary: amberAccent,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFFECB3),
        onSecondaryContainer: Color(0xFFE65100),

        surface: surface, // ← Cards blanches pures
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceVariant,

        error: Color.fromARGB(255, 105, 0, 0),
        onError: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: surface, // ← AppBar blanche
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
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: tealPrimary.withValues(alpha: 0.3),
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
          foregroundColor: tealPrimary,
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
          foregroundColor: Colors.white,
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
        fillColor: surface, // ← Input blanc
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0), // ← Border glaciale
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0),
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
            color: Color(0xFFD32F2F),
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
        elevation: 3, // ← Ombre moyenne
        shadowColor: const Color(0xFF64748B).withValues(alpha: 0.15), // ← Ombre glaciale
        color: surface, // ← Blanc pur
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // ← Border radius élégant
          side: const BorderSide(
            color: Color(0xFFE2E8F0), // ← Border subtile
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
        inactiveTrackColor: Color(0xFFE2E8F0),
        thumbColor: tealPrimary,
        overlayColor: Color(0x1F00BFA5),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tealPrimary;
          }
          return const Color(0xFFCBD5E0);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tealPrimary.withValues(alpha: 0.5);
          }
          return const Color(0xFFE2E8F0);
        }),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tealPrimary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        // ❄️ Ombre glaciale pour le FAB
        extendedSizeConstraints: const BoxConstraints.tightFor(height: 56),
        extendedIconLabelSpacing: 8,
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
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
        elevation: 8,
        shadowColor: Color(0xFF64748B),
      ),

      // ❄️ DIALOG GLACIAL
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        shadowColor: const Color(0xFF64748B).withValues(alpha: 0.2),
      ),

      // ❄️ TAB BAR GLACIAL
      tabBarTheme: TabBarThemeData(
        labelColor: tealPrimary,
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
