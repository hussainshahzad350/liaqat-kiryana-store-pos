import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';
import 'app_themes.dart';
import 'theme_constants.dart'; // Import theme_constants

class ThemeProvider with ChangeNotifier {
  final SettingsRepository _settingsRepository;
  static const String _themePrefKey = 'app_theme';

  String _themeName = ThemeConstants.defaultTheme; // Default theme from constants

  ThemeProvider(this._settingsRepository) {
    _loadTheme();
  }

  ThemeData get themeData => AppThemes.getTheme(_themeName);
  String get themeName => _themeName;

  void _loadTheme() async {
    final prefs = await _settingsRepository.getAppPreferences();
    // Use a specific key for theme to avoid conflicts
    _themeName = prefs[_themePrefKey] ?? ThemeConstants.defaultTheme;
    notifyListeners();
  }

  Future<void> setTheme(String themeName) async {
    if (_themeName == themeName) return;

    _themeName = themeName;
    notifyListeners();

    // Persist only the theme preference
    await _settingsRepository.updateAppPreferences({_themePrefKey: themeName});
  }
}
