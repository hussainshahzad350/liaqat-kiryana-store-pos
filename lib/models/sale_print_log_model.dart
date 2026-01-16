class SalePrintLog {
  final int? id;
  final int saleId;
  final String receiptType;
  final DateTime generatedAt;

  SalePrintLog({
    this.id,
    required this.saleId,
    required this.receiptType,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory SalePrintLog.fromMap(Map<String, dynamic> map) {
    return SalePrintLog(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int,
      receiptType: map['receipt_type'] as String,
      generatedAt: DateTime.tryParse(map['generated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'receipt_type': receiptType,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}
