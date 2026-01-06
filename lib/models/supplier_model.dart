class Supplier {
  final int? id;
  final String nameEnglish;
  final String? nameUrdu;
  final String? contactPrimary;
  final String? address;
  final String? supplierType;
  final int outstandingBalance;
  final bool isActive;
  final DateTime? createdAt;

  Supplier({
    this.id,
    required this.nameEnglish,
    this.nameUrdu,
    this.contactPrimary,
    this.address,
    this.supplierType,
    this.outstandingBalance = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      nameEnglish: map['name_english'] as String? ?? '',
      nameUrdu: map['name_urdu'] as String?,
      contactPrimary: map['contact_primary'] as String?,
      address: map['address'] as String?,
      supplierType: map['supplier_type'] as String?,
      outstandingBalance: (map['outstanding_balance'] as num?)?.toInt() ?? 0,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_english': nameEnglish,
      'name_urdu': nameUrdu,
      'contact_primary': contactPrimary,
      'address': address,
      'supplier_type': supplierType,
      'outstanding_balance': outstandingBalance,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}