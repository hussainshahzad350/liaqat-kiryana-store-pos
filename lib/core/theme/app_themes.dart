import 'package:flutter/material.dart';

/// Defines the ThemeData for each theme in the app.
/// 
/// CRYSTAL CLEAR MODERN THEME - Features:
/// - Proper Urdu font (NooriNastaleeq) for RTL layouts
/// - Roboto for LTR layouts
/// - No pixel breaks or shady rendering
/// - Clean, modern appearance with proper contrast
/// - RTL-aware text rendering
class AppThemes {
  // LTR (English) Text Theme - Uses Roboto with proper letter spacing
  static const _ltrTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 96,
      fontWeight: FontWeight.w300,
      fontFamily: 'Roboto',
      letterSpacing: -1.5,
      height: 1.2,
    ),
    displayMedium: TextStyle(
      fontSize: 60,
      fontWeight: FontWeight.w400,
      fontFamily: 'Roboto',
      letterSpacing: -0.5,
      height: 1.2,
    ),
    displaySmall: TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w400,
      fontFamily: 'Roboto',
      letterSpacing: 0,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w400,
      fontFamily: 'Roboto',
      letterSpacing: 0.25,
      height: 1.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      fontFamily: 'Roboto',
      letterSpacing: 0,
      height: 1.3,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      fontFamily: 'Roboto',
      letterSpacing: 0.15,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      fontFamily: 'Roboto',
      letterSpacing: 0.15,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      fontFamily: 'Roboto',
      letterSpacing: 0.5,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontFamily: 'Roboto',
      letterSpacing: 0.25,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      fontFamily: 'Roboto',
      letterSpacing: 0.4,
      height: 1.5,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontFamily: 'Roboto',
      letterSpacing: 1.25,
      height: 1.4,
    ),
  );

  // RTL (Urdu) Text Theme - Uses NooriNastaleeq with extra line height
  // CRITICAL: Extra line height (1.8) prevents pixel breaks in Nastaleeq script
  static const _rtlTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 96,
      fontWeight: FontWeight.w400, // Nastaleeq looks better with regular weight
      fontFamily: 'NooriNastaleeq',
      height: 1.8, // CRITICAL: Prevents pixel breaks
    ),
    displayMedium: TextStyle(
      fontSize: 60,
      fontWeight: FontWeight.w400,
      fontFamily: 'NooriNastaleeq',
      height: 1.8,
    ),
    displaySmall: TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w400,
      fontFamily: 'NooriNastaleeq',
      height: 1.8,
    ),
    headlineMedium: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w400,
      fontFamily: 'NooriNastaleeq',
      height: 1.8,
    ),
    headlineSmall: TextStyle(
      fontSize: 26, // Slightly larger for Urdu readability
      fontWeight: FontWeight.w600,
      fontFamily: 'NooriNastaleeq',
      height: 1.8,
    ),
    titleLarge: TextStyle(
      fontSize: 24, // Larger for Urdu (was 22)
      fontWeight: FontWeight.w500,
      fontFamily: 'NooriNastaleeq',
      height: 1.8,
    ),
    titleMedium: TextStyle(
      fontSize: 20, // Larger for Urdu (was 18)
      fontWeight: FontWeight.w500,
      fontFamily: 'NooriNastaleeq',
      height: 1.8,
    ),
    bodyLarge: TextStyle(
      fontSize: 18, // Larger for Urdu readability (was 16)
      fontWeight: FontWeight.w400,
      fontFamily: 'NooriNastaleeq',
      height: 1.8,
    ),
    bodyMedium: TextStyle(
      fontSize: 16, // Larger for Urdu (was 14)
      fontWeight: FontWeight.w400,
      fontFamily: 'NooriNastaleeq',
      height: 1.8,
    ),
    bodySmall: TextStyle(
      fontSize: 14, // Larger for Urdu (was 12)
      fontWeight: FontWeight.w400,
      fontFamily: 'NooriNastaleeq',
      height: 1.8,
    ),
    labelLarge: TextStyle(
      fontSize: 16, // Larger for Urdu (was 14)
      fontWeight: FontWeight.w500,
      fontFamily: 'NooriNastaleeq',
      height: 1.8,
    ),
  );

  static MaterialColor _getMaterialColor(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'green':
      default:
        return Colors.green;
    }
  }

  /// Get theme based on color and brightness
  /// NEW: Also accepts optional isRTL parameter for font selection
  static ThemeData getTheme(
    String colorName,
    Brightness brightness, {
    bool isRTL = false, // NEW PARAMETER
  }) {
    final MaterialColor palette = _getMaterialColor(colorName);

    if (brightness == Brightness.light) {
      return _getCrystalClearLightTheme(palette, isRTL: isRTL);
    } else {
      return _getCrystalClearDarkTheme(palette, isRTL: isRTL);
    }
  }

  /// CRYSTAL CLEAR LIGHT THEME
  /// Uses pure white and vibrant colors for maximum clarity
  static ThemeData _getCrystalClearLightTheme(
    MaterialColor palette, {
    required bool isRTL,
  }) {
    // CRYSTAL CLEAR COLORS - No shading, pure whites and clean colors
    final primaryColor = palette[600]!; // Vibrant primary
    const backgroundColor = Colors.white; // Pure white, not tinted
    const surfaceColor = Colors.white; // Pure white surfaces
    const textColor = Color(0xFF000000); // Pure black text
    final dividerColor = Colors.grey[300]!; // Light grey dividers
    final inputFillColor = Colors.grey[50]!; // Very light fill

    final colorScheme = ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: palette[700]!,
      tertiary: palette[800]!,
      error: const Color(0xFFB00020),
      surface: surfaceColor,
      onSurface: textColor,
      surfaceContainerHighest: inputFillColor,
      outline: dividerColor,
      shadow: Colors.black.withOpacity(0.1), // Subtle shadows
    );

    return _buildCrystalClearTheme(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      textColor: textColor,
      dividerColor: dividerColor,
      isRTL: isRTL,
    );
  }

  /// CRYSTAL CLEAR DARK THEME
  /// Uses true dark background with high contrast text
  static ThemeData _getCrystalClearDarkTheme(
    MaterialColor palette, {
    required bool isRTL,
  }) {
    // CRYSTAL CLEAR DARK COLORS
    final primaryColor = palette[400]!; // Lighter primary for dark mode
    const backgroundColor = Color(0xFF121212); // True dark, not grey
    const surfaceColor = Color(0xFF1E1E1E); // Elevated dark
    const textColor = Color(0xFFFFFFFF); // Pure white text
    final dividerColor = Colors.grey[800]!; // Dark dividers
    final inputFillColor = Colors.grey[900]!; // Dark input fill

    final colorScheme = ColorScheme.dark(
      primary: primaryColor,
      onPrimary: Colors.black,
      secondary: palette[300]!,
      tertiary: palette[200]!,
      error: const Color(0xFFCF6679),
      surface: surfaceColor,
      onSurface: textColor,
      surfaceContainerHighest: inputFillColor,
      outline: dividerColor,
      shadow: Colors.black.withOpacity(0.3),
    );

    return _buildCrystalClearTheme(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      textColor: textColor,
      dividerColor: dividerColor,
      isRTL: isRTL,
    );
  }

  static ThemeData _buildCrystalClearTheme({
    required Brightness brightness,
    required Color primaryColor,
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color cardColor,
    required Color textColor,
    required Color dividerColor,
    required bool isRTL,
  }) {
    // Select text theme based on RTL
    final textTheme = isRTL ? _rtlTextTheme : _ltrTextTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      cardColor: cardColor,
      
      // CRITICAL: Apply correct font based on text direction
      fontFamily: isRTL ? 'NooriNastaleeq' : 'Roboto',
      
      textTheme: textTheme.apply(
        bodyColor: textColor,
        displayColor: textColor,
        decorationColor: textColor,
      ),
      
      // AppBar - Crystal clear with subtle elevation
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: textColor),
      ),
      
      // Input Fields - Clean borders, no background tint
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isRTL ? 16 : 12, // More padding for Urdu
          vertical: isRTL ? 16 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Less rounded for modern look
          borderSide: BorderSide(color: dividerColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: dividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: textColor.withOpacity(0.7),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: textColor.withOpacity(0.5),
        ),
        prefixIconColor: textColor.withOpacity(0.7),
        suffixIconColor: textColor.withOpacity(0.7),
      ),
      
      // Scrollbar - Clean and minimal
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(true),
        trackVisibility: WidgetStateProperty.all(true),
        thumbColor: WidgetStateProperty.all(textColor.withOpacity(0.3)),
        trackColor: WidgetStateProperty.all(textColor.withOpacity(0.1)),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(6),
      ),
      
      // Dialogs - Crystal clear with sharp corners
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.2),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Modern sharp corners
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: textColor,
        ),
      ),
      
      // Cards - Flat and clean
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0, // Flat cards, no shadows
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: dividerColor, width: 1),
        ),
      ),
      
      dividerColor: dividerColor,
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      
      iconTheme: IconThemeData(
        color: textColor,
        size: isRTL ? 26 : 24, // Slightly larger icons for Urdu
      ),
      
      listTileTheme: ListTileThemeData(
        iconColor: textColor,
        textColor: textColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isRTL ? 20 : 16,
          vertical: isRTL ? 12 : 8,
        ),
      ),
      
      // Elevated Buttons - Flat modern style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0, // Flat buttons
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(
            vertical: isRTL ? 20 : 18,
            horizontal: isRTL ? 28 : 24,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Buttons - Clean and minimal
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: EdgeInsets.symmetric(
            vertical: isRTL ? 14 : 12,
            horizontal: isRTL ? 20 : 16,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      
      // Floating Action Button - Crystal clear
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
