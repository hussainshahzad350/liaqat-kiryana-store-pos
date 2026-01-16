class SupplierPayment {
  final int? id;
  final int supplierId;
  final int amount;
  final DateTime? paymentDate;
  final String? notes;
  final DateTime? createdAt;

  SupplierPayment({
    this.id,
    required this.supplierId,
    this.amount = 0,
    this.paymentDate,
    this.notes,
    this.createdAt,
  });

  factory SupplierPayment.fromMap(Map<String, dynamic> map) {
    return SupplierPayment(
      id: map['id'] as int?,
      supplierId: map['supplier_id'] as int,
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      paymentDate: map['payment_date'] != null
          ? DateTime.tryParse(map['payment_date'] as String)
          : null,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'amount': amount,
      'payment_date': paymentDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
