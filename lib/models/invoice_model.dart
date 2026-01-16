import 'package:intl/intl.dart';

/// Represents a line item within an invoice.
/// Stores a snapshot of the product details at the time of sale.
class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final int productId;
  final String itemName; // Maps to item_name_snapshot
  final int quantity; // Scaled Integer (e.g., 1500 = 1.500)
  final int rate; // Unit Price in Paisas
  final int subtotal; // Total Price in Paisas (qty * rate / scale)

  const InvoiceItem({
    this.id,
    this.invoiceId,
    required this.productId,
    required this.itemName,
    required this.quantity,
    required this.rate,
    required this.subtotal,
  });

  /// Convert to database map
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

  /// Create from database map
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

/// Represents a finalized financial document (Invoice).
/// Strictly stores totals and metadata. Items are loaded separately.
class Invoice {
  final int? id;
  final String invoiceNumber; // e.g., SB-23100001
  final int customerId;
  final DateTime date;

  // Financials (Integer Paisas)
  final int totalAmount; // Grand total (Payable)
  final int discount; // Document-level discount
  final String status; // 'DRAFT', 'POSTED', 'VOID'
  final String? notes;

  // Associated items, usually loaded separately
  final List<InvoiceItem> items;

  const Invoice({
    this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.date,
    required this.totalAmount,
    this.discount = 0,
    this.status = 'DRAFT',
    this.notes,
    this.items = const [],
  });

  /// Business Rule: Invoice is read-only if posted or void
  bool get isReadOnly => status == 'POSTED' || status == 'VOID';

  /// Integrity Check: sum of items minus discount equals total amount
  bool get isMathematicallyValid {
    final sumItems = items.fold<int>(0, (sum, item) => sum + item.subtotal);
    return (sumItems - discount) == totalAmount;
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'invoice_date': DateFormat('yyyy-MM-dd HH:mm').format(date),
      'sub_total': totalAmount + discount, // Derived for DB schema
      'discount_total': discount,
      'grand_total': totalAmount,
      'status': status,
      'notes': notes,
    };
  }

  /// Create from database map
  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String,
      customerId: map['customer_id'] as int,
      date: DateTime.tryParse(map['invoice_date'] as String) ?? DateTime.now(),
      totalAmount: (map['grand_total'] as num).toInt(),
      discount: (map['discount_total'] as num?)?.toInt() ?? 0,
      status: map['status'] ?? 'POSTED',
      notes: map['notes'] as String?,
      items: [], // Loaded separately via repository or join
    );
  }
}
