import 'package:liaqat_store/domain/entities/money.dart';

class Product {
  final int? id;
  final String? itemCode;
  final String nameEnglish;
  final String? nameUrdu;
  final int? categoryId;
  final int? subCategoryId;
  final String? brand;
  final int? unitId;
  final String? unitType;
  final String? packingType;
  final String? searchTags;
  final int minStockAlert;
  final int currentStock;
  final Money avgCostPrice;
  final Money salePrice;
  final DateTime? expiryDate;
  final DateTime createdAt;

  Product({
    this.id,
    this.itemCode,
    required this.nameEnglish,
    this.nameUrdu,
    this.categoryId,
    this.subCategoryId,
    this.brand,
    this.unitId,
    this.unitType,
    this.packingType,
    this.searchTags,
    this.minStockAlert = 10,
    this.currentStock = 0,
    this.avgCostPrice = const Money(0),
    this.salePrice = const Money(0),
    this.expiryDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a Product from database map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      itemCode: map['item_code'] as String?,
      nameEnglish: map['name_english'] as String? ?? '',
      nameUrdu: map['name_urdu'] as String?,
      categoryId: map['category_id'] as int?,
      subCategoryId: map['sub_category_id'] as int?,
      brand: map['brand'] as String?,
      unitId: map['unit_id'] as int?,
      unitType: map['unit_type'] as String?,
      packingType: map['packing_type'] as String?,
      searchTags: map['search_tags'] as String?,
      minStockAlert: (map['min_stock_alert'] ?? 10) as int,
      currentStock: (map['current_stock'] ?? 0) as int,
      avgCostPrice: Money((map['avg_cost_price'] ?? 0) as int),
      salePrice: Money((map['sale_price'] ?? 0) as int),
      expiryDate: map['expiry_date'] != null ? DateTime.tryParse(map['expiry_date'] as String) : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Convert Product to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_code': itemCode,
      'name_english': nameEnglish,
      'name_urdu': nameUrdu,
      'category_id': categoryId,
      'sub_category_id': subCategoryId,
      'brand': brand,
      'unit_id': unitId,
      'unit_type': unitType,
      'packing_type': packingType,
      'search_tags': searchTags,
      'min_stock_alert': minStockAlert,
      'current_stock': currentStock,
      'avg_cost_price': avgCostPrice.paisas,
      'sale_price': salePrice.paisas,
      'expiry_date': expiryDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy of this Product with some fields replaced
  Product copyWith({
    int? id,
    String? itemCode,
    String? nameEnglish,
    String? nameUrdu,
    int? categoryId,
    int? subCategoryId,
    String? brand,
    int? unitId,
    String? unitType,
    String? packingType,
    String? searchTags,
    int? minStockAlert,
    int? currentStock,
    Money? avgCostPrice,
    Money? salePrice,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      nameUrdu: nameUrdu ?? this.nameUrdu,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      brand: brand ?? this.brand,
      unitId: unitId ?? this.unitId,
      unitType: unitType ?? this.unitType,
      packingType: packingType ?? this.packingType,
      searchTags: searchTags ?? this.searchTags,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      currentStock: currentStock ?? this.currentStock,
      avgCostPrice: avgCostPrice ?? this.avgCostPrice,
      salePrice: salePrice ?? this.salePrice,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if stock is low
  bool get isLowStock => currentStock <= minStockAlert;

  /// Get profit per unit
  Money get profitPerUnit => salePrice - avgCostPrice;

  @override
  String toString() {
    return 'Product(id: $id, code: $itemCode, name: $nameEnglish, '
        'stock: $currentStock/$minStockAlert, price: $salePrice)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          itemCode == other.itemCode &&
          nameEnglish == other.nameEnglish;

  @override
  int get hashCode => id.hashCode ^ itemCode.hashCode ^ nameEnglish.hashCode;
}
