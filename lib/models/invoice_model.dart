import 'package:intl/intl.dart';
import 'invoice_item_model.dart';

/// Represents a finalized financial document (Invoice).
/// Maps to the 'invoices' table.
class Invoice {
  final int? id;
  final String invoiceNumber;
  final int customerId;
  final DateTime date;

  // Financials (Integer Paisas)
  final int totalAmount; // Grand total (Payable)
  final int discount; // Document-level discount
  final String status; // 'DRAFT', 'POSTED', 'VOID'
  final String? notes;

  // Associated items, loaded separately
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

  bool get isReadOnly => status == 'POSTED' || status == 'VOID';

  bool get isMathematicallyValid {
    final sumItems = items.fold<int>(0, (sum, item) => sum + item.subtotal);
    return (sumItems - discount) == totalAmount;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'invoice_date': DateFormat('yyyy-MM-dd HH:mm').format(date),
      'sub_total': totalAmount + discount,
      'discount_total': discount,
      'grand_total': totalAmount,
      'status': status,
      'notes': notes,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String,
      customerId: map['customer_id'] as int,
      date: DateTime.tryParse(map['invoice_date'] as String) ?? DateTime.now(),
      totalAmount: (map['grand_total'] as num).toInt(),
      discount: (map['discount_total'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'POSTED',
      notes: map['notes'] as String?,
      items: [], // Load separately via repository
    );
  }
}
