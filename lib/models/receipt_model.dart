import 'package:intl/intl.dart';

/// Represents a financial receipt (Payment received from customer).
/// Maps to the 'receipts' table.
class Receipt {
  final int? id;
  final String receiptNumber; // Unique (e.g., RCP-170000000)
  final int customerId;
  final DateTime receiptDate;
  final int amount; // Amount in Paisas
  final String paymentMode; // 'CASH', 'BANK', 'CHEQUE'
  final String? notes;

  const Receipt({
    this.id,
    required this.receiptNumber,
    required this.customerId,
    required this.receiptDate,
    required this.amount,
    this.paymentMode = 'CASH',
    this.notes,
  });

  /// Convert Receipt to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receipt_number': receiptNumber,
      'customer_id': customerId,
      'receipt_date': DateFormat('yyyy-MM-dd HH:mm').format(receiptDate),
      'amount': amount,
      'payment_mode': paymentMode,
      'notes': notes,
    };
  }

  /// Create Receipt from database map
  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'] as int?,
      receiptNumber: map['receipt_number'] as String? ?? '',
      customerId: map['customer_id'] as int,
      receiptDate: DateTime.tryParse(map['receipt_date'] as String? ?? '') ?? DateTime.now(),
      amount: (map['amount'] as num).toInt(),
      paymentMode: map['payment_mode'] as String? ?? 'CASH',
      notes: map['notes'] as String?,
    );
  }

  /// Business rule: receipt is valid only if amount > 0
  bool get isValid => amount > 0;

  @override
  String toString() => 'Receipt($receiptNumber, Amt: $amount, Mode: $paymentMode)';
}
