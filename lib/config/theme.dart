import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrainTheme {
  // Colores principales (Premium OLED Dark)
  static const Color primaryDark = Color(0xFF09090B); // Background
  static const Color surfaceDark = Color(0xFF141416); // Surfaces
  static const Color cardDark = Color(0xFF1C1C20); // Cards
  static const Color borderDark = Color(0xFF27272A); // Borders

  // Acentos Neon/Vibrantes
  static const Color accentPurple = Color(0xFF9D4EDD);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentCyan = Color(0xFF06B6D4);

  // Tipografia de alto contraste
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textTertiary = Color(0xFF71717A);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: accentPurple,
        secondary: accentBlue,
        surface: surfaceDark,
        error: accentRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDark.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side:
              BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentPurple,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentPurple, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle:
            const TextStyle(color: textTertiary, fontWeight: FontWeight.w400),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark,
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryDark,
        selectedItemColor: accentPurple,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: primaryDark,
        indicatorColor: accentPurple.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: accentPurple);
          }
          return const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: textTertiary);
        }),
      ),
      dividerColor: borderDark,
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
    );
  }

  // Colores para prioridades de tareas
  static Color priorityColor(int index) {
    switch (index) {
      case 0:
        return accentGreen;
      case 1:
        return accentBlue;
      case 2:
        return accentOrange;
      case 3:
        return accentRed;
      default:
        return accentBlue;
    }
  }

  // Colores para proyectos
  static const List<int> projectColors = [
    0xFF9D4EDD, // accentPurple
    0xFF3B82F6, // accentBlue
    0xFF10B981, // accentGreen
    0xFFF59E0B, // accentOrange
    0xFFEF4444, // accentRed
    0xFFEC4899, // accentPink
    0xFF06B6D4, // accentCyan
    0xFFa78bfa,
    0xFF34d399,
    0xFFfbbf24,
  ];

  // Emojis para proyectos
  static const List<String> projectEmojis = [
    '📁',
    '🚀',
    '💡',
    '🎯',
    '📚',
    '💻',
    '🎨',
    '🏗️',
    '📊',
    '🔬',
    '✍️',
    '🎮',
    '🎵',
    '📸',
    '🌍',
    '🧪',
  ];

  // Utility para BoxShadow estilo glow
  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: accentPurple.withValues(alpha: 0.15),
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 8),
        ),
      ];
}
