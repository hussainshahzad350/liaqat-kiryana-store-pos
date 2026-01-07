import 'package:flutter/foundation.dart';
import '../../domain/entities/money.dart';

@immutable
class StockItemEntity {
  final int id;
  final String nameEnglish;
  final String nameUrdu;
  final String? code;
  final String? barcode;
  final double currentStock;
  final double minStockThreshold;
  final String unit;
  final Money costPrice;
  final Money salePrice;
  final String? categoryName;
  final DateTime lastUpdated;

  const StockItemEntity({
    required this.id,
    required this.nameEnglish,
    required this.nameUrdu,
    this.code,
    this.barcode,
    required this.currentStock,
    required this.minStockThreshold,
    required this.unit,
    required this.costPrice,
    required this.salePrice,
    this.categoryName,
    required this.lastUpdated,
  });

  // Domain Logic
  bool get isLowStock => currentStock > 0 && currentStock <= minStockThreshold;
  bool get isOutOfStock => currentStock <= 0;
  
  // Valuation
  Money get totalCostValue => Money((costPrice.paisas * currentStock).round());
  Money get totalSalesValue => Money((salePrice.paisas * currentStock).round());
}