import 'package:flutter/material.dart';

/// Defines constants related to theming, including theme modes
/// and keys for SharedPreferences.
class ThemeConstants {
  ThemeConstants._(); // Private constructor

  static const String themeKey = 'selected_theme';

  // Enum representing the available application theme modes.
  // The string value will be used for persistence.
  static const String lightGreen = 'lightGreen';
  static const String darkGreen = 'darkGreen';
  static const String lightBlue = 'lightBlue';
  static const String darkBlue = 'darkBlue';

  // Default theme mode
  static const String defaultTheme = lightGreen;
}

enum AppThemeVariant {
  lightGreen,
  darkGreen,
  lightBlue,
  darkBlue;

  /// The color name extracted from this variant (e.g. 'green', 'blue')
  String get colorName {
    if (name.contains('Green')) return 'green';
    if (name.contains('Blue')) return 'blue';
    return 'green';
  }

  /// Whether this variant uses dark brightness
  bool get isDark => name.startsWith('dark');

  /// The Brightness for this variant
  Brightness get brightness => isDark ? Brightness.dark : Brightness.light;

  /// Parse from a stored string, falling back to lightGreen
  static AppThemeVariant fromString(String? value) {
    return AppThemeVariant.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppThemeVariant.lightGreen,
    );
  }

  /// The opposite brightness variant (e.g. lightGreen ↔ darkGreen)
  AppThemeVariant get toggled {
    switch (this) {
      case AppThemeVariant.lightGreen:
        return AppThemeVariant.darkGreen;
      case AppThemeVariant.darkGreen:
        return AppThemeVariant.lightGreen;
      case AppThemeVariant.lightBlue:
        return AppThemeVariant.darkBlue;
      case AppThemeVariant.darkBlue:
        return AppThemeVariant.lightBlue;
    }
  }
}
