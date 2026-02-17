import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens matching the web app's theme (web-app/src/useTheme.ts).
class AppColors {
  const AppColors._();

  // Primary
  static const boogieBuster = Color(0xFFD1F366);
  static const boogieBusterDark = Color(0xFFB8DC4B);

  // Neutrals
  static const eerieBlack = Color(0xFF141627);
  static const yankeesBlue = Color(0xFF1C1F37);
  static const darkElectricBlue = Color(0xFF626577);
  static const borderLineGray = Color(0xFFB1B1B1);
  static const gray = Color(0xFF808080);
  static const offWhite = Color(0xFFF3F3F3);

  // Accents
  static const blueSky = Color(0xFF66D0F2);
  static const sunsetOrange = Color(0xFFFFD365);
  static const springGreen = Color(0xFFD1F366);
  static const peachRed = Color(0xFFFF8B8B);
}

ThemeData buildAppTheme() {
  final textTheme = GoogleFonts.promptTextTheme();

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.boogieBuster,
      primary: AppColors.boogieBuster,
      onPrimary: AppColors.eerieBlack,
      error: AppColors.peachRed,
      surface: Colors.white,
      onSurface: AppColors.eerieBlack,
    ),
    textTheme: textTheme.copyWith(
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w900,
        color: AppColors.eerieBlack,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
        color: AppColors.eerieBlack,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(
        color: AppColors.eerieBlack,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        color: AppColors.darkElectricBlue,
      ),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.eerieBlack,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.darkElectricBlue),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.darkElectricBlue),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.blueSky, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.peachRed, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      labelStyle: const TextStyle(color: AppColors.eerieBlack, fontWeight: FontWeight.bold),
      hintStyle: const TextStyle(color: AppColors.darkElectricBlue, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.boogieBuster,
        foregroundColor: AppColors.eerieBlack,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    scaffoldBackgroundColor: Colors.white,
  );
}
