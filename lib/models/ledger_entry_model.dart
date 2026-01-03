class LedgerEntry {
  final int? id;
  final int customerId;
  final DateTime date;
  final String description;
  final String refType; // INVOICE, RECEIPT, RETURN, ADJUSTMENT
  final int refId;
  final int debit;  // Increases Balance (Receivable) - Paisas
  final int credit; // Decreases Balance (Received) - Paisas
  final int balance; // Running Balance Snapshot - Paisas

  const LedgerEntry({
    this.id,
    required this.customerId,
    required this.date,
    required this.description,
    required this.refType,
    required this.refId,
    required this.debit,
    required this.credit,
    required this.balance,
  }) : assert(debit == 0 || credit == 0, 'Debit and Credit cannot both be non-zero');

  /// Derived Type for Business Logic (SALE, RECEIPT)
  String get type {
    switch (refType) {
      case 'INVOICE':
        return 'SALE';
      case 'RECEIPT':
        return 'RECEIPT';
      case 'RETURN':
        return 'RETURN';
      default:
        return 'ADJUSTMENT';
    }
  }

  /// Convert LedgerEntry to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'transaction_date': date.toIso8601String(),
      'description': description,
      'ref_type': refType,
      'ref_id': refId,
      'debit': debit,
      'credit': credit,
      'balance': balance,
    };
  }

  /// Create LedgerEntry from database map
  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      date: DateTime.parse(map['transaction_date'] as String),
      description: map['description'] as String,
      refType: map['ref_type'] as String,
      refId: map['ref_id'] as int,
      debit: (map['debit'] as num).toInt(),
      credit: (map['credit'] as num).toInt(),
      balance: (map['balance'] as num).toInt(),
    );
  }

  /// Helper to check if this entry represents a financial Debit (Increase in Debt)
  bool get isDebit => debit > 0;

  /// Helper to check if this entry represents a financial Credit (Decrease in Debt)
  bool get isCredit => credit > 0;

  @override
  String toString() {
    return 'LedgerEntry(id: $id, type: $refType, debit: $debit, credit: $credit, bal: $balance)';
  }
}