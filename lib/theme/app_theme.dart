import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────
//  GoFaster Health – Brand Color System
//  Exact palette from gofaster.in
// ─────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Core brand
  static const Color primary       = Color(0xFFFF6B00); // Vibrant orange
  static const Color primaryLight  = Color(0xFFFFB347); // Light orange / accent
  static const Color primaryDark   = Color(0xFFCC5500); // Dark orange
  static const Color accent        = Color(0xFFFFB347); // Gradient / hover

  // Backgrounds
  static const Color background    = Color(0xFF0D0D0D); // Deep black
  static const Color bgAlt         = Color(0xFF111111); // Slightly lighter
  static const Color secondary     = Color(0xFF1A1A1A); // Near-black cards/bg
  static const Color cardBg        = Color(0xFF1E1E1E); // Card background
  static const Color surface       = Color(0xFF252525); // Surface / elevated card
  static const Color surfaceHigh   = Color(0xFF2C2C2C); // Chip / pill bg

  // Text
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color textMuted     = Color(0xFF888888);
  static const Color textDisabled  = Color(0xFF555555);

  // Semantic
  static const Color success       = Color(0xFF4CAF50);
  static const Color successLight  = Color(0xFF81C784);
  static const Color error         = Color(0xFFFF4444);
  static const Color errorLight    = Color(0xFFFF7070);
  static const Color warning       = Color(0xFFFFC107);
  static const Color info          = Color(0xFF2196F3);

  // Divider / border
  static const Color border        = Color(0xFF2A2A2A);
  static const Color borderLight   = Color(0xFF333333);

  // Sleep stages
  static const Color sleepRem      = Color(0xFFFF6B00);
  static const Color sleepCore     = Color(0xFFFFB347);
  static const Color sleepDeep     = Color(0xFFCC5500);
  static const Color sleepAwake    = Color(0xFF888888);
}

// ─────────────────────────────────────────────────────────
//  Typography
// ─────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => GoogleFonts.poppins(
    fontSize: 52, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.1,
  );
  static TextStyle get h1 => GoogleFonts.poppins(
    fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2,
  );
  static TextStyle get h2 => GoogleFonts.poppins(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.25,
  );
  static TextStyle get h3 => GoogleFonts.poppins(
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static TextStyle get h4 => GoogleFonts.poppins(
    fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static TextStyle get h5 => GoogleFonts.poppins(
    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static TextStyle get bodySm => GoogleFonts.poppins(
    fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );
  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5,
  );
  static TextStyle get label => GoogleFonts.poppins(
    fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.0,
  );
  static TextStyle get scoreHuge => GoogleFonts.poppins(
    fontSize: 72, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1.0,
  );
  static TextStyle get scoreLg => GoogleFonts.poppins(
    fontSize: 44, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.0,
  );
  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.3,
  );
  static TextStyle get buttonSm => GoogleFonts.poppins(
    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static TextStyle get tag => GoogleFonts.poppins(
    fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
  );
}

// ─────────────────────────────────────────────────────────
//  Gradients
// ─────────────────────────────────────────────────────────
class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.accent],
    begin: Alignment.centerLeft, end: Alignment.centerRight,
  );
  static const LinearGradient primaryVertical = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
  static const LinearGradient fire = LinearGradient(
    colors: [Color(0xFFFF6B00), Color(0xFFFF8C42), Color(0xFFFFB347)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient orangeGlow = LinearGradient(
    colors: [Color(0xFFFF6B00), Color(0xFFFF4500)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient darkCard = LinearGradient(
    colors: [Color(0xFF1E1E1E), Color(0xFF252525)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient scoreRing = LinearGradient(
    colors: [AppColors.primary, AppColors.accent, AppColors.primaryLight],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
  static const RadialGradient orangeRadial = RadialGradient(
    colors: [Color(0x33FF6B00), Color(0x00FF6B00)],
    radius: 1.0,
  );
  static LinearGradient get background => const LinearGradient(
    colors: [Color(0xFF0D0D0D), Color(0xFF111111)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
}

// ─────────────────────────────────────────────────────────
//  Decoration helpers
// ─────────────────────────────────────────────────────────
BoxDecoration cardDecoration({
  double radius = 20,
  Color? color,
  bool hasGlow = false,
}) {
  return BoxDecoration(
    color: color ?? AppColors.cardBg,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.border, width: 1),
    boxShadow: hasGlow
        ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.20),
              blurRadius: 20, spreadRadius: -2,
            )
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 10, offset: const Offset(0, 4),
            )
          ],
  );
}

BoxDecoration primaryCardDecoration({double radius = 20}) {
  return BoxDecoration(
    gradient: AppGradients.fire,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.35),
        blurRadius: 20, spreadRadius: -2, offset: const Offset(0, 6),
      )
    ],
  );
}

// ─────────────────────────────────────────────────────────
//  Theme
// ─────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.poppins().fontFamily,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.cardBg,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.h4,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          elevation: 0,
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.secondary,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: AppTextStyles.caption,
        unselectedLabelStyle: AppTextStyles.caption,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        side: const BorderSide(color: AppColors.border),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.surfaceHigh,
        ),
      ),

      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
