class AppLogger {
  static const bool isDebug = true;
  
  static void info(String message, {String? tag}) {
    if (isDebug) {
      print('✅ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }
  
  static void error(String message, {String? tag}) {
    if (isDebug) {
      print('❌ ${tag != null ? '[$tag] ' : ''}$message');
    }
  }
  
  static void db(String message) {
    if (isDebug) {
      print('🗄️ $message');
    }
  }
}