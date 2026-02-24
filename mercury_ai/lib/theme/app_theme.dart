import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── NexusAI Neo Brutalism Design System ──────────────────────────────────────
// Principles: Bold borders, hard shadows, flat colors, no gradients, high contrast

class AppColors {
  // ── Core ──
  static const black = Color(0xFF0A0A0A);
  static const white = Color(0xFFF5F5F0);
  static const offWhite = Color(0xFFEEEDE8);
  static const darkBg = Color(0xFF111111);
  static const darkSurface = Color(0xFF1A1A1A);
  static const darkCard = Color(0xFF222222);

  // ── Accents ──
  static const accent = Color(0xFF00FF88);       // Electric green
  static const accentDim = Color(0xFF00CC6A);
  static const accentAlt = Color(0xFF0088FF);     // Blue for user
  static const warning = Color(0xFFFFCC00);
  static const error = Color(0xFFFF3333);
  static const muted = Color(0xFF888888);
  static const mutedDark = Color(0xFF444444);

  // ── Borders ──
  static const border = Color(0xFF0A0A0A);
  static const borderLight = Color(0xFFD0CFCA);
}

class AppTheme {
  static const double borderWidth = 2.0;
  static const double shadowOffset = 4.0;
  static const double cardRadius = 0.0; // Neo brutalism = no radius
  static const double buttonRadius = 0.0;

  // ── Hard shadow helper ─────────────────────────────────────────────────────
  static BoxShadow hardShadow(Color color, {double offset = 4.0}) {
    return BoxShadow(
      color: color,
      offset: Offset(offset, offset),
      blurRadius: 0,
    );
  }

  static BoxDecoration brutalistCard({
    Color? bg,
    Color? border,
    double shadowOffset = 4.0,
    Color? shadowColor,
    bool dark = false,
  }) {
    final bgColor = bg ?? (dark ? AppColors.darkCard : AppColors.white);
    final borderColor = border ?? (dark ? AppColors.white : AppColors.black);
    final shadow = shadowColor ?? (dark ? AppColors.accent : AppColors.black);
    return BoxDecoration(
      color: bgColor,
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [hardShadow(shadow, offset: shadowOffset)],
    );
  }

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.offWhite,
      colorScheme: const ColorScheme.light(
        primary: AppColors.black,
        secondary: AppColors.accent,
        surface: AppColors.white,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSurface: AppColors.black,
      ),
      textTheme: _textTheme(AppColors.black),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        titleTextStyle: GoogleFonts.spaceMono(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
          letterSpacing: 1.5,
        ),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: AppColors.black, width: 2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.black, width: borderWidth),
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.black, width: borderWidth),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.black, width: 3),
          borderRadius: BorderRadius.zero,
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.spaceMono(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.hovered) ? AppColors.mutedDark : null,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.black,
        thickness: 2,
        space: 0,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.black),
        trackColor: WidgetStateProperty.all(AppColors.borderLight),
        thickness: WidgetStateProperty.all(6),
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentAlt,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: AppColors.black,
        onSurface: AppColors.white,
      ),
      textTheme: _textTheme(AppColors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.spaceMono(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.accent,
          letterSpacing: 1.5,
        ),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent, width: borderWidth),
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.mutedDark, width: borderWidth),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent, width: 3),
          borderRadius: BorderRadius.zero,
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.black,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.spaceMono(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.mutedDark,
        thickness: 1,
        space: 0,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.accent),
        trackColor: WidgetStateProperty.all(AppColors.darkCard),
        thickness: WidgetStateProperty.all(6),
      ),
    );
  }

  static TextTheme _textTheme(Color color) {
    return TextTheme(
      displayLarge: GoogleFonts.spaceMono(fontSize: 32, fontWeight: FontWeight.w900, color: color),
      displayMedium: GoogleFonts.spaceMono(fontSize: 24, fontWeight: FontWeight.w700, color: color),
      headlineLarge: GoogleFonts.spaceMono(fontSize: 20, fontWeight: FontWeight.w700, color: color),
      headlineMedium: GoogleFonts.spaceMono(fontSize: 18, fontWeight: FontWeight.w600, color: color),
      titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color),
      titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: color),
      bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: color, height: 1.6),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: color, height: 1.5),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: color.withOpacity(0.7)),
      labelLarge: GoogleFonts.spaceMono(fontSize: 13, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.8),
      labelSmall: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.w400, color: color.withOpacity(0.6)),
    );
  }
}
