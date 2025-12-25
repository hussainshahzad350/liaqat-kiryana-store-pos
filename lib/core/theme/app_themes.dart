import 'package:flutter/material.dart';

/// Defines the ThemeData for each theme in the app.
class AppThemes {
  // Common Text Theme for consistency
  static const _baseTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 96, fontWeight: FontWeight.w300),
    displayMedium: TextStyle(fontSize: 60, fontWeight: FontWeight.w400),
    displaySmall: TextStyle(fontSize: 48, fontWeight: FontWeight.w400),
    headlineMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w400),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.25),
  );

  static MaterialColor _getMaterialColor(String colorName) {
    switch (colorName) {
      case 'blue': return Colors.blue;
      case 'orange': return Colors.orange;
      case 'green':
      default: return Colors.green;
    }
  }

  static ThemeData getTheme(String colorName, Brightness brightness) {
    final MaterialColor palette = _getMaterialColor(colorName);
    
    if (brightness == Brightness.light) {
      return _getShadedLightTheme(palette);
    } else {
      return _getShadedDarkTheme(palette);
    }
  }

  static ThemeData _getShadedLightTheme(MaterialColor palette) {
    // Light Mode Rules:
    // Surfaces: 50-200 range
    // Primary Actions: 500-600 range
    // Text: Dark Grey/Black

    final primaryColor = palette[600]!; // Slightly darker for text contrast
    final backgroundColor = palette[50]!;
    const textColor = Color(0xFF212121);
    final dividerColor = palette[200]!;

    final colorScheme = ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: palette[700]!,
      tertiary: palette[800]!,
      error: const Color(0xFFB00020),
      surface: backgroundColor,
      onSurface: textColor,
      surfaceContainerHighest: palette[200], // For input fields
      outline: dividerColor,
    );

    return _buildTheme(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: backgroundColor,
      textColor: textColor,
      dividerColor: dividerColor,
      useMaterial3: true,
      buttonBackgroundColor: palette[500]!,
      buttonForegroundColor: Colors.white,
      appBarColor: palette[200]!,
      appBarForeground: textColor,
    );
  }

  static ThemeData _getShadedDarkTheme(MaterialColor palette) {
    // Dark Mode Rules:
    // Surfaces: 800-900 range (Deep shades)
    // Primary Actions: 500 range (Mid shade)
    // Text: White/Near-White

    final primaryColor = palette[400]!; // Lighter for contrast on dark
    final backgroundColor = palette[900]!; // Deep shade
    final surfaceColor = palette[800]!;
    const textColor = Color(0xFFEEEEEE);
    final dividerColor = palette[700]!;

    final colorScheme = ColorScheme.dark(
      primary: primaryColor,
      onPrimary: Colors.black,
      secondary: palette[200]!,
      tertiary: palette[100]!,
      error: const Color(0xFFCF6679),
      surface: surfaceColor,
      onSurface: textColor,
      surfaceContainerHighest: palette[700], // For input fields
      outline: dividerColor,
    );

    return _buildTheme(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      textColor: textColor,
      dividerColor: dividerColor,
      useMaterial3: true,
      buttonBackgroundColor: palette[600]!,
      buttonForegroundColor: Colors.white,
      appBarColor: palette[900]!,
      appBarForeground: textColor,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color cardColor,
    required Color textColor,
    required Color dividerColor,
    required bool useMaterial3,
    required Color buttonBackgroundColor,
    required Color buttonForegroundColor,
    required Color appBarColor,
    required Color appBarForeground,
  }) {
    return ThemeData(
      useMaterial3: useMaterial3,
      brightness: brightness,
      primaryColor: primaryColor,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      cardColor: cardColor,
      textTheme: _baseTextTheme.apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: appBarForeground,
        elevation: 0,
        iconTheme: IconThemeData(color: appBarForeground),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        prefixIconColor: textColor.withOpacity(0.7),
        suffixIconColor: textColor.withOpacity(0.7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: MaterialStateProperty.all(true),
        trackVisibility: MaterialStateProperty.all(true),
        thumbColor: MaterialStateProperty.all(textColor.withOpacity(0.4)),
        radius: const Radius.circular(10),
        thickness: MaterialStateProperty.all(8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: textColor, fontSize: 16),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerColor: dividerColor,
      iconTheme: IconThemeData(color: textColor),
      listTileTheme: ListTileThemeData(
        iconColor: textColor,
        textColor: textColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBackgroundColor,
          foregroundColor: buttonForegroundColor,
          elevation: 0,
          // Removed border side for cleaner look in colored themes, or keep if desired
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24), // Adjusted for visual balance with text
        ),
      ),
    );
  }
}
