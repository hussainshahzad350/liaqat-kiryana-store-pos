class PurchaseItem {
  final int? id;
  final int? purchaseId;
  final int? productId;
  final double quantity;
  final int costPrice;
  final int totalAmount;
  final String? batchNumber;
  final DateTime? expiryDate;

  PurchaseItem({
    this.id,
    this.purchaseId,
    this.productId,
    required this.quantity,
    required this.costPrice,
    required this.totalAmount,
    this.batchNumber,
    this.expiryDate,
  });

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'] as int?,
      purchaseId: map['purchase_id'] as int?,
      productId: map['product_id'] as int?,
      quantity: (map['quantity'] as num).toDouble(),
      costPrice: (map['cost_price'] as num).toInt(),
      totalAmount: (map['total_amount'] as num).toInt(),
      batchNumber: map['batch_number'] as String?,
      expiryDate: map['expiry_date'] != null
          ? DateTime.tryParse(map['expiry_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'product_id': productId,
      'quantity': quantity,
      'cost_price': costPrice,
      'total_amount': totalAmount,
      'batch_number': batchNumber,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }

  PurchaseItem copyWith({
    int? id,
    int? purchaseId,
    int? productId,
    double? quantity,
    int? costPrice,
    int? totalAmount,
    String? batchNumber,
    DateTime? expiryDate,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}

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
