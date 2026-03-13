import 'package:flutter/foundation.dart';

class AppLogger {
  static bool get isDebug => kDebugMode;
  
  static void info(String message, {String? tag}) {
    if (isDebug) {
      debugPrint('✅ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }
  
  static void error(String message, {String? tag}) {
    if (isDebug) {
      debugPrint('❌ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }
  
  static void db(String message) {
    if (isDebug) {
      debugPrint('🗄️ $message');
    }
  }
}
