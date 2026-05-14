// lib/core/routes/app_routes.dart

class AppRoutes {
  // Prevent instantiation
  AppRoutes._();
  
  // Route names
  static const String home = '/home';
  static const String sales = '/sales';
  static const String stock = '/stock';
  static const String purchase = '/purchase';
  static const String product = '/product';
  static const String legacyItems = '/items';
  static const String legacyCategories = '/categories';
  static const String legacyUnits = '/units';

  @Deprecated('Use AppRoutes.product with AppShell navigation.')
  static const String items = legacyItems;
  @Deprecated('Use AppRoutes.product with AppShell navigation.')
  static const String categories = legacyCategories;
  @Deprecated('Use AppRoutes.product with AppShell navigation.')
  static const String units = legacyUnits;

  static const String accounts = '/accounts';
  static const String customers = '/customers';
  static const String suppliers = '/suppliers';
  static const String reports = '/reports';
  static const String cashLedger = '/cash-ledger';
  static const String settings = '/settings';
  static const String login = '/';
  static const String logout = '/logout';
}
