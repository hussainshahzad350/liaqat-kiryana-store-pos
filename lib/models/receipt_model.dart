class Receipt {
  final int? id;
  final int saleId;
  final String receiptType;
  final DateTime generatedAt;

  Receipt({
    this.id,
    required this.saleId,
    required this.receiptType,
    required this.generatedAt,
  });

  /// Convert Receipt to database map
  ///
  /// This function returns a Map<String, dynamic> which represents
  /// the Receipt object in a format that can be directly
  /// inserted into a database.
  ///
  /// The returned map contains the following keys:
  ///
  /// - id: The ID of the Receipt.
  /// - sale_id: The ID of the Sale associated with the Receipt.
  /// - receipt_type: The type of the Receipt (e.g. THERMAL, PDF).
  /// - generated_at: The timestamp when the Receipt was generated, in ISO 8601 format.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'receipt_type': receiptType,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'],
      saleId: map['sale_id'],
      receiptType: map['receipt_type'],
      generatedAt: DateTime.parse(map['generated_at']),
    );
  }
}