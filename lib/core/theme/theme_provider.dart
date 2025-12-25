import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';
import 'app_themes.dart';

class ThemeProvider with ChangeNotifier {
  final SettingsRepository _settingsRepository;
  static const String _colorKey = 'theme_color';
  static const String _modeKey = 'theme_mode';

  String _color = 'green';
  ThemeMode _mode = ThemeMode.system;

  ThemeProvider(this._settingsRepository) {
    _loadTheme();
  }

  ThemeData get lightTheme => AppThemes.getTheme(_color, Brightness.light);
  ThemeData get darkTheme => AppThemes.getTheme(_color, Brightness.dark);
  ThemeMode get themeMode => _mode;
  String get currentColor => _color;

  void _loadTheme() async {
    final prefs = await _settingsRepository.getAppPreferences();
    _color = prefs[_colorKey] ?? 'green';
    
    final modeStr = prefs[_modeKey] ?? 'system';
    _mode = _parseThemeMode(modeStr);
    
    notifyListeners();
  }

  Future<void> setColor(String colorName) async {
    if (_color == colorName) return;
    _color = colorName;
    notifyListeners();
    await _settingsRepository.updateAppPreferences({_colorKey: colorName});
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _settingsRepository.updateAppPreferences({_modeKey: mode.toString().split('.').last});
  }

  ThemeMode _parseThemeMode(String modeStr) {
    if (modeStr == 'light') return ThemeMode.light;
    if (modeStr == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }
}
