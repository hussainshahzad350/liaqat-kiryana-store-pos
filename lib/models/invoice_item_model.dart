/// Represents a line item within an invoice.
/// Maps to the 'invoice_items' table.
class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final int productId;
  final String itemName; // Maps to item_name_snapshot
  final int quantity; // Scaled integer (e.g., 1500 = 1.500)
  final int unitPrice; // Unit price in paisas (unit_price)
  final int totalPrice; // Total price in paisas (total_price)

  const InvoiceItem({
    this.id,
    this.invoiceId,
    required this.productId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? productId,
    String? itemName,
    int? quantity,
    int? unitPrice,
    int? totalPrice,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'item_name_snapshot': itemName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      productId: map['product_id'] as int,
      itemName: map['item_name_snapshot'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: (map['unit_price'] as num).toInt(),
      totalPrice: (map['total_price'] as num).toInt(),
    );
  }
}
