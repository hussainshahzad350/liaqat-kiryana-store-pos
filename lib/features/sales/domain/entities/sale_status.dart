/// Represents the lifecycle status of a sale/invoice.
enum SaleStatus {
  completed,
  cancelled;

  /// The database string representation of this status
  String get dbValue {
    switch (this) {
      case SaleStatus.completed:
        return 'COMPLETED';
      case SaleStatus.cancelled:
        return 'CANCELLED';
    }
  }

  /// Parse from database string value
  static SaleStatus fromDbValue(String value) {
    return SaleStatus.values.firstWhere(
      (s) => s.dbValue == value,
      orElse: () => SaleStatus.completed,
    );
  }
}
