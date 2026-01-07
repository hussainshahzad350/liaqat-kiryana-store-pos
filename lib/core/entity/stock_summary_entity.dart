import 'package:flutter/foundation.dart';
import '../../domain/entities/money.dart';

@immutable
class StockSummaryEntity {
  final int totalItemsCount;
  final Money totalStockCost;
  final Money totalStockSalesValue;
  final int lowStockItemsCount;
  final int outOfStockItemsCount;
  final int expiredOrNearExpiryCount;
  final DateTime lastUpdated;

  const StockSummaryEntity({
    required this.totalItemsCount,
    required this.totalStockCost,
    required this.totalStockSalesValue,
    required this.lowStockItemsCount,
    required this.outOfStockItemsCount,
    required this.expiredOrNearExpiryCount,
    required this.lastUpdated,
  });
}