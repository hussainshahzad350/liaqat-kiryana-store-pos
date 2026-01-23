class SupplierLedger {
  int? id;
  int supplierId;
  String transactionDate;
  String description;
  String refType; // PURCHASE, PURCHASE_RETURN, PAYMENT, ADJUSTMENT
  int refId;
  int debit;
  int credit;
  int balance;
  String? createdAt;

  SupplierLedger({
    this.id,
    required this.supplierId,
    required this.transactionDate,
    required this.description,
    required this.refType,
    required this.refId,
    this.debit = 0,
    this.credit = 0,
    required this.balance,
    this.createdAt,
  });

  // Convert a SupplierLedger object into a Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'transaction_date': transactionDate,
      'description': description,
      'ref_type': refType,
      'ref_id': refId,
      'debit': debit,
      'credit': credit,
      'balance': balance,
      'created_at': createdAt,
    };
  }

  // Create a SupplierLedger object from a Map
  factory SupplierLedger.fromMap(Map<String, dynamic> map) {
    return SupplierLedger(
      id: map['id'],
      supplierId: map['supplier_id'],
      transactionDate: map['transaction_date'],
      description: map['description'],
      refType: map['ref_type'],
      refId: map['ref_id'],
      debit: map['debit'] ?? 0,
      credit: map['credit'] ?? 0,
      balance: map['balance'],
      createdAt: map['created_at'],
    );
  }
}
