import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';
import 'app_themes.dart';

/// Theme Provider with RTL Support
/// 
/// This provider now tracks text direction and applies appropriate fonts:
/// - NooriNastaleeq for Urdu (RTL)
/// - Roboto for English (LTR)
class ThemeProvider with ChangeNotifier {
  final SettingsRepository _settingsRepository;
  static const String _colorKey = 'theme_color';
  static const String _modeKey = 'theme_mode';

  String _color = 'green';
  ThemeMode _mode = ThemeMode.system;
  bool _isRTL = false; // Track current text direction

  ThemeProvider(this._settingsRepository) {
    _loadTheme();
  }

  /// Get light theme with RTL support
  ThemeData get lightTheme => AppThemes.getTheme(
        _color,
        Brightness.light,
        isRTL: _isRTL,
      );

  /// Get dark theme with RTL support
  ThemeData get darkTheme => AppThemes.getTheme(
        _color,
        Brightness.dark,
        isRTL: _isRTL,
      );

  ThemeMode get themeMode => _mode;
  String get currentColor => _color;
  bool get isRTL => _isRTL;

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
    await _settingsRepository
        .updateAppPreferences({_modeKey: mode.toString().split('.').last});
  }

  /// Update text direction (called when language changes)
  /// 
  /// This should be called from your language change logic:
  /// ```dart
  /// themeProvider.setTextDirection(isRTL: locale.languageCode == 'ur');
  /// ```
  void setTextDirection({required bool isRTL}) {
    if (_isRTL == isRTL) return;
    _isRTL = isRTL;
    notifyListeners(); // Rebuild app with new font
  }

  ThemeMode _parseThemeMode(String modeStr) {
    if (modeStr == 'light') return ThemeMode.light;
    if (modeStr == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }
}
