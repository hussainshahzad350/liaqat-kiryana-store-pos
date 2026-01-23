class Purchase {
  final int? id;
  final int supplierId;
  final String? invoiceNumber;
  final DateTime? purchaseDate;
  final int totalAmount;
  final String? notes;
  final String status;
  final DateTime? createdAt;
  final List<PurchaseItem> items; // <- added

  Purchase({
    this.id,
    required this.supplierId,
    this.invoiceNumber,
    this.purchaseDate,
    this.totalAmount = 0,
    this.notes,
    this.status = 'COMPLETED',
    this.createdAt,
    this.items = const [], // <- default empty list
  });

  factory Purchase.fromMap(Map<String, dynamic> map, {List<PurchaseItem>? items}) {
    return Purchase(
      id: map['id'] as int?,
      supplierId: map['supplier_id'] as int,
      invoiceNumber: map['invoice_number'] as String?,
      purchaseDate: map['purchase_date'] != null
          ? DateTime.tryParse(map['purchase_date'] as String)
          : null,
      totalAmount: (map['total_amount'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'COMPLETED',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      items: items ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'invoice_number': invoiceNumber,
      'purchase_date': purchaseDate?.toIso8601String(),
      'total_amount': totalAmount,
      'notes': notes,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      // Items are handled separately in purchase_items table
    };
  }

  // Optional: Copy with method to easily add/update items
  Purchase copyWith({
    int? id,
    int? supplierId,
    String? invoiceNumber,
    DateTime? purchaseDate,
    int? totalAmount,
    String? notes,
    String? status,
    DateTime? createdAt,
    List<PurchaseItem>? items,
  }) {
    return Purchase(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
