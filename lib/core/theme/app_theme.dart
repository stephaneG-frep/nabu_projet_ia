import 'package:flutter/material.dart';

/// Apple-Color: palette "NabuProjet"
class NabuColors {
  static const Color violet = Color(0xFF7C4DFF);
  static const Color deepViolet = Color(0xFF5E35B1);
  static const Color electricBlue = Color(0xFF2979FF);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color turquoise = Color(0xFF1DE9B6);
  static const Color green = Color(0xFF00C853);
  static const Color orange = Color(0xFFFF9100);
  static const Color magenta = Color(0xFFE040FB);
  static const Color rose = Color(0xFFFF4081);
  static const Color red = Color(0xFFFF5252);
  static const Color amber = Color(0xFFFFC400);

  static const Color bgDark = Color(0xFF0E0B1E);
  static const Color bgDark2 = Color(0xFF1A1233);
  static const Color bgLight = Color(0xFFF4F2FF);
}

/// Mapping of category colors used across the app.
class CategoryColors {
  static const Map<String, Color> map = {
    'Informatique': NabuColors.electricBlue,
    'Apprentissage': NabuColors.violet,
    'Bricolage': NabuColors.orange,
    'Maison': NabuColors.rose,
    'Jardin': NabuColors.green,
    'Professionnel': NabuColors.cyan,
    'Entreprise': NabuColors.magenta,
    'Créatif': NabuColors.magenta,
    'Voyage': NabuColors.turquoise,
    'Personnel': NabuColors.deepViolet,
    'Autre': NabuColors.cyan,
  };

  static List<Color> get gradientSeed => [
        NabuColors.violet,
        NabuColors.electricBlue,
        NabuColors.magenta,
        NabuColors.orange,
        NabuColors.turquoise,
        NabuColors.rose,
        NabuColors.cyan,
        NabuColors.deepViolet,
      ];

  static Color forCategory(String category) =>
      map[category] ?? NabuColors.cyan;
}

class AppTheme {
  static ThemeData dark() => _base(Brightness.dark);
  static ThemeData light() => _base(Brightness.light);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: NabuColors.violet,
      brightness: brightness,
    ).copyWith(
      primary: NabuColors.violet,
      secondary: NabuColors.electricBlue,
      tertiary: NabuColors.cyan,
      surface: isDark ? NabuColors.bgDark2 : Colors.white,
      surfaceContainerLowest: isDark ? const Color(0xFF171031) : Colors.white,
      surfaceContainerHighest: isDark ? NabuColors.bgDark2 : Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? NabuColors.bgDark : NabuColors.bgLight,
      fontFamily: 'Poppins',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: isDark ? Colors.white : const Color(0xFF1A1233),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF1A1233),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: NabuColors.violet, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.35),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? Colors.white10 : Colors.black87,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF171031)
            : Colors.white,
        selectedItemColor: NabuColors.violet,
        unselectedItemColor: isDark
            ? Colors.white.withValues(alpha: 0.45)
            : Colors.black.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF1F1840) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),
    );
  }

  static LinearGradient appBackground(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [
              Color(0xFF0E0B1E),
              Color(0xFF171031),
              Color(0xFF1A1233),
            ]
          : const [
              Color(0xFFF4F2FF),
              Color(0xFFEAF6FF),
              Color(0xFFF0FCF9),
            ],
      stops: const [0, 0.5, 1],
    );
  }

  static final List<LinearGradient> projectGradients = [
    const LinearGradient(colors: [NabuColors.violet, NabuColors.electricBlue]),
    const LinearGradient(colors: [NabuColors.electricBlue, NabuColors.cyan]),
    const LinearGradient(colors: [NabuColors.cyan, NabuColors.turquoise]),
    const LinearGradient(colors: [NabuColors.magenta, NabuColors.violet]),
    const LinearGradient(colors: [NabuColors.orange, NabuColors.rose]),
    const LinearGradient(colors: [NabuColors.turquoise, NabuColors.deepViolet]),
    const LinearGradient(colors: [NabuColors.rose, NabuColors.magenta]),
    const LinearGradient(colors: [NabuColors.deepViolet, NabuColors.electricBlue]),
  ];

  static LinearGradient projectGradient(int seed) =>
      projectGradients[seed % projectGradients.length];
}