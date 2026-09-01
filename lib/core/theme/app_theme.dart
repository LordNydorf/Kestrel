import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Hallmark-calibrated theme tokens for Kestrel (Modern-Minimal / Technical genre).
class AppColors {
  AppColors._();

  // Background & Surfaces
  static const Color paper = Color(0xFF0B0F17); // Canvas background
  static const Color surface = Color(0xFF131B2A); // Card & row surface
  static const Color surfaceHover = Color(0xFF1A2438); // Interactive hover
  static const Color surfaceElevated = Color(0xFF1E293B); // Elevated dialogs / sheets
  static const Color border = Color(0xFF23324D); // Hairline dividers & borders
  static const Color borderFocus = Color(0xFF3B82F6); // Focus outline

  // Ink / Text
  static const Color ink = Color(0xFFF1F5F9); // Primary text
  static const Color muted = Color(0xFF94A3B8); // Secondary text / metadata
  static const Color subtle = Color(0xFF64748B); // Low-contrast timestamps

  // Semantics: Gain / Loss / Accents
  static const Color gain = Color(0xFF10B981); // Emerald gain & Buy action
  static const Color gainTint = Color(0x3310B981); // 20% gain flash tint
  static const Color loss = Color(0xFFEF4444); // Crimson loss & Sell action
  static const Color lossTint = Color(0x33EF4444); // 20% loss flash tint
  static const Color accent = Color(0xFF3B82F6); // Electric blue accent

  // Action Buttons
  static const Color buyButton = Color(0xFF059669);
  static const Color sellButton = Color(0xFFDC2626);
}

/// Typography tokens implementing the 2+1 discipline:
/// 1. Space Grotesk (Display / UI text)
/// 2. JetBrains Mono with tabular-nums (Numeric & Financial Figures)
class AppTypography {
  AppTypography._();

  /// Primary UI Text (Space Grotesk)
  static TextStyle get displayLarge => GoogleFonts.spaceGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.5,
      );

  static TextStyle get titleLarge => GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.2,
      );

  static TextStyle get titleMedium => GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle get bodyMedium => GoogleFonts.spaceGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
      );

  static TextStyle get bodySmall => GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
      );

  static TextStyle get labelSmall => GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.muted,
        letterSpacing: 0.5,
      );

  /// Tabular Monospaced Numbers (JetBrains Mono + Tabular Figures)
  static TextStyle get numericLarge => GoogleFonts.jetBrainsMono(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get numericMedium => GoogleFonts.jetBrainsMono(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get numericSmall => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.muted,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get numericGain => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.gain,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get numericLoss => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.loss,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

/// Complete ThemeData for Kestrel.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.paper,
      canvasColor: AppColors.paper,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.accent,
        secondary: AppColors.gain,
        error: AppColors.loss,
        onSurface: AppColors.ink,
      ),
      dividerColor: AppColors.border,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
