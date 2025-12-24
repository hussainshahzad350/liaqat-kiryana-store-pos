import 'package:shared_preferences/shared_preferences.dart';

class ThemeStorageUtil {
  static const String _themeKey = 'currentTheme';

  /// Saves the current theme name to SharedPreferences.
  static Future<void> saveTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeName);
  }

  /// Retrieves the saved theme name from SharedPreferences.
  /// Returns null if no theme preference is found.
  static Future<String?> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey);
  }
}
