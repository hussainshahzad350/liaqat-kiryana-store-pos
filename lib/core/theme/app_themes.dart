import 'package:flutter/material.dart';
import 'app_colors.dart';

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

  static final ThemeData lightGreenTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.lightGreenPrimary,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.teal,
      accentColor: AppColors.lightGreenAccent,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.grey[50],
    textTheme: _baseTextTheme.apply(bodyColor: AppColors.darkBackground, displayColor: AppColors.darkBackground),
    appBarTheme: const AppBarTheme(
      color: AppColors.lightGreenPrimary,
      foregroundColor: Colors.white,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      selectedIconTheme: const IconThemeData(color: AppColors.lightGreenPrimary),
      unselectedIconTheme: IconThemeData(color: Colors.grey[600]!),
      selectedLabelTextStyle: const TextStyle(color: AppColors.lightGreenPrimary),
    ),
  );

  static final ThemeData darkGreenTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.darkGreenPrimary,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.teal,
      accentColor: AppColors.darkGreenAccent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.darkSurface,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkSurface,
    textTheme: _baseTextTheme.apply(bodyColor: AppColors.darkPrimaryText, displayColor: AppColors.darkPrimaryText),
    appBarTheme: const AppBarTheme(
      color: AppColors.darkSurface,
      foregroundColor: AppColors.darkPrimaryText,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedIconTheme: IconThemeData(color: AppColors.darkGreenAccent),
      unselectedIconTheme: IconThemeData(color: AppColors.darkSecondaryText),
      selectedLabelTextStyle: TextStyle(color: AppColors.darkGreenAccent),
    ),
     dividerColor: AppColors.darkDivider,
  );

  static final ThemeData lightBlueTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.lightBluePrimary,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.lightBlue,
      accentColor: AppColors.lightBlueAccent,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.grey[50],
    textTheme: _baseTextTheme.apply(bodyColor: AppColors.darkBackground, displayColor: AppColors.darkBackground),
     appBarTheme: const AppBarTheme(
      color: AppColors.lightBluePrimary,
      foregroundColor: Colors.white,
    ),
     navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      selectedIconTheme: const IconThemeData(color: AppColors.lightBluePrimary),
      unselectedIconTheme: IconThemeData(color: Colors.grey[600]!),
      selectedLabelTextStyle: const TextStyle(color: AppColors.lightBluePrimary),
    ),
  );

  static final ThemeData darkBlueTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.darkBluePrimary,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue,
      accentColor: AppColors.darkBlueAccent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.darkSurface,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkSurface,
    textTheme: _baseTextTheme.apply(bodyColor: AppColors.darkPrimaryText, displayColor: AppColors.darkPrimaryText),
     appBarTheme: const AppBarTheme(
      color: AppColors.darkSurface,
      foregroundColor: AppColors.darkPrimaryText,
    ),
     navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedIconTheme: IconThemeData(color: AppColors.darkBlueAccent),
      unselectedIconTheme: IconThemeData(color: AppColors.darkSecondaryText),
      selectedLabelTextStyle: TextStyle(color: AppColors.darkBlueAccent),
    ),
     dividerColor: AppColors.darkDivider,
  );


  static ThemeData getTheme(String themeName) {
    switch (themeName) {
      case 'lightGreen':
        return lightGreenTheme;
      case 'darkGreen':
        return darkGreenTheme;
      case 'lightBlue':
        return lightBlueTheme;
      case 'darkBlue':
        return darkBlueTheme;
      default:
        return lightGreenTheme; // Default theme
    }
  }
}
