import 'package:flutter/foundation.dart';

enum AdjustmentType { increase, decrease, set, damage, loss, found }

@immutable
class StockAdjustmentEntity {
  final int? id;
  final int productId;
  final String productName;
  final double quantityChange; // Positive or negative
  final AdjustmentType type;
  final String reason;
  final DateTime date;
  final String adjustedBy;

  const StockAdjustmentEntity({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantityChange,
    required this.type,
    required this.reason,
    required this.date,
    required this.adjustedBy,
  });
}