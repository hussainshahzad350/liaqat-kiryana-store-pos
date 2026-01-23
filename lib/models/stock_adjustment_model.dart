class StockAdjustment {
  final int? id;
  final int productId;
  final DateTime adjustmentDate;
  final double quantityChange;
  final String? reason;
  final String reference;
  final String user;
  final DateTime createdAt;

  StockAdjustment({
    this.id,
    required this.productId,
    required this.adjustmentDate,
    required this.quantityChange,
    this.reason,
    this.reference = 'ADJUSTMENT',
    this.user = 'SYSTEM',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory StockAdjustment.fromMap(Map<String, dynamic> map) {
    return StockAdjustment(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      adjustmentDate: DateTime.parse(map['adjustment_date'] as String),
      quantityChange: (map['quantity_change'] as num).toDouble(),
      reason: map['reason'] as String?,
      reference: map['reference'] as String? ?? 'ADJUSTMENT',
      user: map['user'] as String? ?? 'SYSTEM',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'adjustment_date': adjustmentDate.toIso8601String(),
      'quantity_change': quantityChange,
      'reason': reason,
      'reference': reference,
      'user': user,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
