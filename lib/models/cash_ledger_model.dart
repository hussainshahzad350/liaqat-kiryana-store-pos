class CashLedger {
  final int? id;
  final DateTime transactionDate;
  final String? transactionTime;
  final String description;
  final String type; // 'IN', 'OUT', 'OPENING', 'CLOSING'
  final Money amount;
  final Money balanceAfter;
  final String? remarks;

  CashLedger({
    this.id,
    required this.transactionDate,
    this.transactionTime,
    required this.description,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.remarks,
  });

  /// Create a CashLedger from database map
  factory CashLedger.fromMap(Map<String, dynamic> map) {
    return CashLedger(
      id: map['id'] as int?,
      transactionDate: map['transaction_date'] != null
          ? DateTime.tryParse(map['transaction_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      transactionTime: map['transaction_time'] as String?,
      description: map['description'] as String? ?? '',
      type: (map['type'] as String?)?.toUpperCase() ?? 'IN',
      amount: Money.fromPaisas((map['amount'] as num?)?.toInt() ?? 0),
      balanceAfter: Money.fromPaisas((map['balance_after'] as num?)?.toInt() ?? 0),
      remarks: map['remarks'] as String?,
    );
  }

  /// Convert CashLedger to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_date': transactionDate.toString().split(' ')[0], // YYYY-MM-DD
      'transaction_time': transactionTime,
      'description': description,
      'type': type,
      'amount': amount.paisas,
      'balance_after': balanceAfter.paisas,
      'remarks': remarks,
    };
  }

  /// Copy with optional overrides
  CashLedger copyWith({
    int? id,
    DateTime? transactionDate,
    String? transactionTime,
    String? description,
    String? type,
    Money? amount,
    Money? balanceAfter,
    String? remarks,
  }) {
    return CashLedger(
      id: id ?? this.id,
      transactionDate: transactionDate ?? this.transactionDate,
      transactionTime: transactionTime ?? this.transactionTime,
      description: description ?? this.description,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      remarks: remarks ?? this.remarks,
    );
  }

  /// Check if this is a cash IN transaction
  bool get isInflow => type == 'IN' || type == 'OPENING';

  /// Check if this is a cash OUT transaction
  bool get isOutflow => type == 'OUT' || type == 'CLOSING';

  @override
  String toString() {
    return 'CashLedger(id: $id, date: $transactionDate, type: $type, '
        'amount: ${amount.formatted}, balance: ${balanceAfter.formatted}, desc: $description)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashLedger &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          transactionDate == other.transactionDate &&
          amount == other.amount;

  @override
  int get hashCode =>
      id.hashCode ^ transactionDate.hashCode ^ amount.hashCode;
}
