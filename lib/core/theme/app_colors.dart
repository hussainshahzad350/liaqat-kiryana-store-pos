import 'package:flutter/material.dart';

/// Defines the color palette for the application.
///
/// This class centralizes all color definitions, allowing for easy theming
/// and consistency across the app. It provides both basic utility colors
/// (e.g., success, error) and specific primary color schemes (e.g., green, blue).
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // --- Utility Colors ---
  static const Color success = Color(0xFF4CAF50); // Green 500
  static const Color error = Color(0xFFF44336); // Red 500
  static const Color warning = Color(0xFFFFC107); // Amber 500
  static const Color info = Color(0xFF2196F3); // Blue 500

  // --- Grayscale / Neutral Colors ---
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color grey = Color(0xFF9E9E9E); // Grey 500
  static const Color lightGrey = Color(0xFFE0E0E0); // Grey 300
  static const Color darkGrey = Color(0xFF616161); // Grey 700

  // --- Primary Color Swatches (based on user request) ---

  // Green Palette (Inspired by default green[700])
  static const MaterialColor green = MaterialColor(
    0xFF43A047, // Primary green value (Green 600)
    <int, Color>{
      50: Color(0xFFE8F5E9),
      100: Color(0xFFC8E6C9),
      200: Color(0xFFA5D6A7),
      300: Color(0xFF81C784),
      400: Color(0xFF66BB6A),
      500: Color(0xFF4CAF50), // Green 500
      600: Color(0xFF43A047),
      700: Color(0xFF388E3C), // Original green[700]
      800: Color(0xFF2E7D32),
      900: Color(0xFF1B5E20),
    },
  );

  // Blue Palette
  static const MaterialColor blue = MaterialColor(
    0xFF1976D2, // Primary blue value (Blue 700)
    <int, Color>{
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: Color(0xFF2196F3), // Blue 500
      600: Color(0xFF1E88E5),
      700: Color(0xFF1976D2),
      800: Color(0xFF1565C0),
      900: Color(0xFF0D47A1),
    },
  );

  // Orange Palette
  static const MaterialColor orange = MaterialColor(
    0xFFFB8C00, // Orange 600
    <int, Color>{
      50: Color(0xFFFFF3E0),
      100: Color(0xFFFFE0B2),
      200: Color(0xFFFFCC80),
      300: Color(0xFFFFB74D),
      400: Color(0xFFFFA726),
      500: Color(0xFFFF9800),
      600: Color(0xFFFB8C00),
      700: Color(0xFFF57C00),
      800: Color(0xFFEF6C00),
      900: Color(0xFFE65100),
    },
  );

  // Red Palette
  static const MaterialColor red = MaterialColor(
    0xFFE53935, // Red 600
    <int, Color>{
      50: Color(0xFFFFEBEE),
      100: Color(0xFFFFCDD2),
      200: Color(0xFFEF9A9A),
      300: Color(0xFFE57373),
      400: Color(0xFFEF5350),
      500: Color(0xFFF44336),
      600: Color(0xFFE53935),
      700: Color(0xFFD32F2F),
      800: Color(0xFFC62828),
      900: Color(0xFFB71C1C),
    },
  );

  static const MaterialColor lightGreenPrimary = AppColors.green;
  static const Color lightGreenAccent = Color(0xFF388E3C);
  static const Color darkBackground = AppColors.black;
  static const MaterialColor darkGreenPrimary = AppColors.green;
  static const Color darkGreenAccent = Color(0xFF81C784); // AppColors.green[300]
  static const Color darkSurface = AppColors.darkGrey;
  static const Color darkPrimaryText = AppColors.white;
  static const Color darkSecondaryText = AppColors.lightGrey;
  static const Color darkDivider = AppColors.darkGrey;

  static const MaterialColor lightBluePrimary = AppColors.blue;
  static const Color lightBlueAccent = Color(0xFF1976D2); // AppColors.blue[700]

  static const MaterialColor darkBluePrimary = AppColors.blue;
  static const Color darkBlueAccent = Color(0xFF64B5F6); // AppColors.blue[300]
}