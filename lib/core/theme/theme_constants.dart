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
