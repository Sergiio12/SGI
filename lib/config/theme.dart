import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrainTheme {
  static Brightness _brightness = Brightness.dark;

  static void updateBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  static bool get _isLight => _brightness == Brightness.light;

  // Colores principales
  static Color get primaryDark =>
      _isLight ? const Color(0xFFF8F9FA) : const Color(0xFF09090B);
  static Color get surfaceDark =>
      _isLight ? const Color(0xFFF4F4F5) : const Color(0xFF141416);
  static Color get cardDark =>
      _isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C20);
  static Color get borderDark =>
      _isLight ? const Color(0xFFE4E4E7) : const Color(0xFF27272A);

  // Acentos Neon/Vibrantes
  static const Color accentPurple = Color(0xFF9D4EDD);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentCyan = Color(0xFF06B6D4);

  // Tipografia
  static Color get textPrimary =>
      _isLight ? const Color(0xFF18181B) : const Color(0xFFFAFAFA);
  static Color get textSecondary =>
      _isLight ? const Color(0xFF52525B) : const Color(0xFFA1A1AA);
  static Color get textTertiary =>
      _isLight ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

  // ─── Tema oscuro ───────────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF09090B),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: accentPurple,
        secondary: accentBlue,
        surface: Color(0xFF141416),
        error: accentRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFFAFAFA),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF09090B).withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFFAFAFA),
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFAFAFA)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1C1C20),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: Colors.white.withValues(alpha: 0.05), width: 1),
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
        fillColor: const Color(0xFF141416),
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
        hintStyle: const TextStyle(
            color: Color(0xFF71717A), fontWeight: FontWeight.w400),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF141416),
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF09090B),
        selectedItemColor: accentPurple,
        unselectedItemColor: Color(0xFF71717A),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF09090B),
        indicatorColor: accentPurple.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accentPurple);
          }
          return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF71717A));
        }),
      ),
      dividerColor: const Color(0xFF27272A),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF141416),
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF141416),
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
    );
  }

  // ─── Tema claro ────────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      colorScheme: const ColorScheme.light(
        primary: accentPurple,
        secondary: accentBlue,
        surface: Color(0xFFFFFFFF),
        error: accentRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF18181B),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFFFFFFF).withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF18181B),
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF18181B)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side:
              BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1),
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
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentPurple, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(
            color: Color(0xFFA1A1AA), fontWeight: FontWeight.w400),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF8F9FA),
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: accentPurple,
        unselectedItemColor: Color(0xFFA1A1AA),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        indicatorColor: accentPurple.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accentPurple);
          }
          return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFA1A1AA));
        }),
      ),
      dividerColor: const Color(0xFFE4E4E7),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFFFF),
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
    0xFF9D4EDD,
    0xFF3B82F6,
    0xFF10B981,
    0xFFF59E0B,
    0xFFEF4444,
    0xFFEC4899,
    0xFF06B6D4,
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
