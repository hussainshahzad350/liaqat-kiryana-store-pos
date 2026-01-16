class Purchase {
  final int? id;
  final int supplierId;
  final String? invoiceNumber;
  final DateTime? purchaseDate;
  final int totalAmount;
  final String? notes;
  final String status;
  final DateTime? createdAt;

  Purchase({
    this.id,
    required this.supplierId,
    this.invoiceNumber,
    this.purchaseDate,
    this.totalAmount = 0,
    this.notes,
    this.status = 'COMPLETED',
    this.createdAt,
  });

  factory Purchase.fromMap(Map<String, dynamic> map) {
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
    };
  }
}

class PurchaseItem {
  final int? id;
  final int purchaseId;
  final int? productId;
  final int quantity;
  final int costPrice;
  final int totalAmount;
  final String? batchNumber;
  final DateTime? expiryDate;

  PurchaseItem({
    this.id,
    required this.purchaseId,
    this.productId,
    this.quantity = 0,
    this.costPrice = 0,
    this.totalAmount = 0,
    this.batchNumber,
    this.expiryDate,
  });

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'] as int?,
      purchaseId: map['purchase_id'] as int,
      productId: map['product_id'] as int?,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      costPrice: (map['cost_price'] as num?)?.toInt() ?? 0,
      totalAmount: (map['total_amount'] as num?)?.toInt() ?? 0,
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
}
