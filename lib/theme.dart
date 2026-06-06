import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fleet-inspired theme: civic-clean structure, confident navy primary,
/// Lora (serif) display + Montserrat (sans) body — the same Google Fonts
/// pairing Boston's Fleet pattern library uses. The palette is original;
/// we borrow the *feel* (paper-like surface, structured neutrals,
/// semantic colors per NPS bucket) without copying any city's identity.
class AppTheme {
  AppTheme._();

  // Civic-clean palette
  static const Color primary = Color(0xFF1A4480);
  static const Color primaryDark = Color(0xFF0F2E5C);
  static const Color surface = Color(0xFFFAFAF7);
  static const Color surfaceElevated = Color(0xFFF0F0EC);
  static const Color onSurface = Color(0xFF1F1F1F);
  static const Color onSurfaceMuted = Color(0xFF5A5A5A);
  static const Color border = Color(0xFFD9D9D6);

  // Semantic — used to tint the rating chips and the success state
  static const Color detractor = Color(0xFFC0392B);
  static const Color passive = Color(0xFFD4A535);
  static const Color promoter = Color(0xFF2E8B5C);

  /// Map an NPS rating (1..10) to its bucket color.
  static Color colorForRating(int rating) {
    if (rating <= 6) return detractor;
    if (rating <= 8) return passive;
    return promoter;
  }

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: primaryDark,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: onSurface,
        error: detractor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: surface,
    );

    final body = GoogleFonts.montserratTextTheme(base.textTheme).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );
    final display = GoogleFonts.loraTextTheme(base.textTheme).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    final textTheme = body.copyWith(
      displayLarge: display.displayLarge,
      displayMedium: display.displayMedium,
      displaySmall: display.displaySmall,
      headlineLarge: display.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
      headlineMedium: display.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
      headlineSmall: display.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: GoogleFonts.montserrat(color: onSurfaceMuted),
        hintStyle: GoogleFonts.montserrat(color: onSurfaceMuted),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
