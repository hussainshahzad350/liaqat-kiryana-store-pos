class ShopProfile {
  final int? id;
  final String shopNameUrdu;
  final String shopNameEnglish;
  final String? shopAddress;
  final String? contactPrimary;
  final DateTime? createdAt;

  ShopProfile({
    this.id,
    required this.shopNameUrdu,
    required this.shopNameEnglish,
    this.shopAddress,
    this.contactPrimary,
    this.createdAt,
  });

  factory ShopProfile.fromMap(Map<String, dynamic> map) {
    return ShopProfile(
      id: map['id'] as int?,
      shopNameUrdu: map['shop_name_urdu'] as String? ?? '',
      shopNameEnglish: map['shop_name_english'] as String? ?? '',
      shopAddress: map['shop_address'] as String?,
      contactPrimary: map['contact_primary'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_name_urdu': shopNameUrdu,
      'shop_name_english': shopNameEnglish,
      'shop_address': shopAddress,
      'contact_primary': contactPrimary,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
