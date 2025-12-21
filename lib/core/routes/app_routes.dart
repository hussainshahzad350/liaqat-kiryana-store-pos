// lib/core/routes/app_routes.dart

class AppRoutes {
  // Prevent instantiation
  AppRoutes._();
  
  // Route names
  static const String home = '/home';
  static const String sales = '/sales';
  static const String stock = '/stock';
  static const String items = '/items';
  static const String customers = '/customers';
  static const String suppliers = '/suppliers';
  static const String categories = '/categories';
  static const String units = '/units';
  static const String reports = '/reports';
  static const String cashLedger = '/cash-ledger';
  static const String settings = '/settings';
  static const String about = '/about';
  
  // Helper: Get route from screen type
  static String? getCurrentRoute(String screenName) {
    switch (screenName) {
      case 'HomeScreen':
        return home;
      case 'SalesScreen':
        return sales;
      case 'StockScreen':
        return stock;
      case 'ItemsScreen':
        return items;
      case 'CustomersScreen':
        return customers;
      case 'SuppliersScreen':
        return suppliers;
      case 'CategoriesScreen':
        return categories;
      case 'UnitsScreen':
        return units;
      case 'ReportsScreen':
        return reports;
      case 'CashLedgerScreen':
        return cashLedger;
      case 'SettingsScreen':
        return settings;
      case 'AboutScreen':
        return about;
      default:
        return null;
    }
  }
}