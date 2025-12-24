class AppConstants {
  static const int paginationLimit = 20;
  static const int dbVersion = 6;
  static const Duration queryTimeout = Duration(seconds: 10);
  
  // Status values
  static const String saleStatusCompleted = 'COMPLETED';
  static const String saleStatusCancelled = 'CANCELLED';
}