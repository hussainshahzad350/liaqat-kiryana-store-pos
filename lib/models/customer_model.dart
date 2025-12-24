class Customer {
  final int? id;
  final String nameEnglish;
  final String? nameUrdu;
  final String? contactPrimary;
  final String? address;
  final int creditLimit;
  final int outstandingBalance;
  final bool isActive;
  final DateTime createdAt;

  Customer({
    this.id,
    required this.nameEnglish,
    this.nameUrdu,
    this.contactPrimary,
    this.address,
    this.creditLimit = 0,
    this.outstandingBalance = 0,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a Customer from database map
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      nameEnglish: map['name_english'] as String? ?? '',
      nameUrdu: map['name_urdu'] as String?,
      contactPrimary: map['contact_primary'] as String?,
      address: map['address'] as String?,
      creditLimit: (map['credit_limit'] ?? 0) as int,
      outstandingBalance: (map['outstanding_balance'] ?? 0) as int,
      isActive: (map['is_active'] ?? 1) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Convert Customer to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_english': nameEnglish,
      'name_urdu': nameUrdu,
      'contact_primary': contactPrimary,
      'address': address,
      'credit_limit': creditLimit,
      'outstanding_balance': outstandingBalance,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy of this Customer with some fields replaced
  Customer copyWith({
    int? id,
    String? nameEnglish,
    String? nameUrdu,
    String? contactPrimary,
    String? address,
    int? creditLimit,
    int? outstandingBalance,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      nameUrdu: nameUrdu ?? this.nameUrdu,
      contactPrimary: contactPrimary ?? this.contactPrimary,
      address: address ?? this.address,
      creditLimit: creditLimit ?? this.creditLimit,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, nameEnglish: $nameEnglish, nameUrdu: $nameUrdu, '
        'contact: $contactPrimary, outstandingBalance: $outstandingBalance, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nameEnglish == other.nameEnglish &&
          outstandingBalance == other.outstandingBalance;

  @override
  int get hashCode =>
      id.hashCode ^ nameEnglish.hashCode ^ outstandingBalance.hashCode;
}
