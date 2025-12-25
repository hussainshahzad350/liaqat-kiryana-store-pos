import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_themes.dart';
import 'theme_constants.dart';

/// Manages the application's theme, including persistence and notification
/// of theme changes.
///
/// This class extends [ChangeNotifier] to allow widgets to listen for theme
/// updates without relying on external state management packages like Provider.
class ThemeManager extends ChangeNotifier {
  late SharedPreferences _prefs;
  String _currentThemeKey = ThemeConstants.defaultTheme;

  ThemeManager() {
    _initSharedPreferences();
  }

  /// Initializes SharedPreferences and loads the saved theme.
  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadTheme();
  }

  /// Loads the theme preference from SharedPreferences.
  void _loadTheme() {
    _currentThemeKey = _prefs.getString(ThemeConstants.themeKey) ?? ThemeConstants.defaultTheme;
    notifyListeners(); // Notify listeners after loading
  }

  /// Returns the currently active ThemeData based on the [_currentThemeKey].
  ThemeData get currentThemeData {
    switch (_currentThemeKey) {
      case ThemeConstants.lightGreen:
        return AppThemes.getTheme('green', Brightness.light);
      case ThemeConstants.darkGreen:
        return AppThemes.getTheme('green', Brightness.dark);
      case ThemeConstants.lightBlue:
        return AppThemes.getTheme('blue', Brightness.light);
      case ThemeConstants.darkBlue:
        return AppThemes.getTheme('blue', Brightness.dark);
      default:
        return AppThemes.getTheme('green', Brightness.light); // Fallback to default
    }
  }

  /// Returns the key of the currently active theme.
  String get currentThemeKey => _currentThemeKey;

  /// Sets a new theme for the application.
  ///
  /// [themeKey] is the identifier for the new theme (e.g., ThemeConstants.darkGreen).
  Future<void> setTheme(String themeKey) async {
    if (_currentThemeKey == themeKey) {
      return; // No change needed
    }
    _currentThemeKey = themeKey;
    await _prefs.setString(ThemeConstants.themeKey, themeKey);
    notifyListeners(); // Notify all listening widgets to rebuild with the new theme
  }

  /// A utility function to toggle between light and dark versions of the current primary color.
  /// This is a simple example and can be expanded for more complex toggling logic.
  Future<void> toggleBrightness() async {
    String newThemeKey;
    switch (_currentThemeKey) {
      case ThemeConstants.lightGreen:
        newThemeKey = ThemeConstants.darkGreen;
        break;
      case ThemeConstants.darkGreen:
        newThemeKey = ThemeConstants.lightGreen;
        break;
      case ThemeConstants.lightBlue:
        newThemeKey = ThemeConstants.darkBlue;
        break;
      case ThemeConstants.darkBlue:
        newThemeKey = ThemeConstants.lightBlue;
        break;
      default:
        newThemeKey = ThemeConstants.darkGreen; // Fallback to dark green if unknown
    }
    await setTheme(newThemeKey);
  }
}
