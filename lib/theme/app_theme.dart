import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════
//  GoFaster Design System — Colors
// ═══════════════════════════════════════════════════════
class AppColors {
  // Primary
  static const Color primary = Color(0xFF850AFF);
  static const Color primaryLight = Color(0xFFAB5CFF);
  static const Color primaryDark = Color(0xFF5A00CC);

  // Neon accents
  static const Color neonBlue = Color(0xFF00D4FF);
  static const Color neonGreen = Color(0xFF00FF94);
  static const Color neonGreenAlt = Color(0xFFCCFF00);
  static const Color neonOrange = Color(0xFFFF8A00);

  // Backgrounds
  static const Color bgDark = Color(0xFF0A0A0C);
  static const Color bgDarkAlt = Color(0xFF0E0814);
  static const Color bgDarkDeep = Color(0xFF050505);
  static const Color surfaceDark = Color(0xFF190F23);
  static const Color cardDark = Color(0xFF14091F);

  // Semantic
  static const Color accentBlue = Color(0xFF0A84FF);
  static const Color accentGreen = Color(0xFF32D74B);
  static const Color amber = Color(0xFFF59E0B);
  static const Color error = Color(0xFFFF453A);
  static const Color indigo = Color(0xFF5B6CF9);

  // Text
  static const Color textPrimary = Color(0xFFF1F0F5);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);

  // Glass
  static Color glassWhite = Colors.white.withValues(alpha: 0.05);
  static Color glassBorder = Colors.white.withValues(alpha: 0.1);
  static Color glassPurple = const Color(0xFF850AFF).withValues(alpha: 0.05);
  static Color glassPurpleBorder = const Color(0xFF850AFF).withValues(alpha: 0.1);
}

// ═══════════════════════════════════════════════════════
//  GoFaster Design System — Typography
// ═══════════════════════════════════════════════════════
class AppTextStyles {
  static const String fontFamily = 'Poppins';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1.5,
  );

  static const TextStyle headingXL = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headingLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.8,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 1.2,
  );

  static const TextStyle scoreHuge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 80,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -4,
  );
}

// ═══════════════════════════════════════════════════════
//  GoFaster Design System — Theme
// ═══════════════════════════════════════════════════════
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.neonBlue,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),
      fontFamily: AppTextStyles.fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Gradient Helpers
// ═══════════════════════════════════════════════════════
class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.neonBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryVertical = LinearGradient(
    colors: [AppColors.primary, AppColors.neonBlue],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient actionGradient = LinearGradient(
    colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5), Color(0xFF00FF88)],
    stops: [0, 0.5, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient purpleGlow = RadialGradient(
    colors: [Color(0x26850AFF), Colors.transparent],
    radius: 0.8,
  );

  static LinearGradient glassCard = LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.08),
      Colors.white.withValues(alpha: 0.02),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ═══════════════════════════════════════════════════════
//  Glass Decoration Helper
// ═══════════════════════════════════════════════════════
BoxDecoration glassDecoration({
  double borderRadius = 20,
  Color? borderColor,
  Color? background,
  List<BoxShadow>? shadows,
}) {
  return BoxDecoration(
    color: background ?? Colors.white.withValues(alpha: 0.04),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: borderColor ?? Colors.white.withValues(alpha: 0.1),
      width: 1,
    ),
    boxShadow: shadows,
  );
}

BoxDecoration primaryGlassDecoration({double borderRadius = 20}) {
  return BoxDecoration(
    color: AppColors.primary.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: AppColors.primary.withValues(alpha: 0.2),
      width: 1,
    ),
  );
}
