import 'package:intl/intl.dart';

/// Represents a line item within an invoice.
/// Maps to the 'invoice_items' table.
class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final int productId;
  final String itemName; // Maps to item_name_snapshot
  final int quantity; // Scaled integer (e.g., 1500 = 1.500)
  final int rate; // Unit price in paisas
  final int subtotal; // Total price in paisas (qty * rate)

  const InvoiceItem({
    this.id,
    this.invoiceId,
    required this.productId,
    required this.itemName,
    required this.quantity,
    required this.rate,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'item_name_snapshot': itemName,
      'quantity': quantity,
      'unit_price': rate,
      'total_price': subtotal,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      productId: map['product_id'] as int,
      itemName: map['item_name_snapshot'] as String,
      quantity: (map['quantity'] as num).toInt(),
      rate: (map['unit_price'] as num).toInt(),
      subtotal: (map['total_price'] as num).toInt(),
    );
  }
}
