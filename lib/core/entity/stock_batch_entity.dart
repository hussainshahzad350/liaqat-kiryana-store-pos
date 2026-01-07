import 'package:flutter/foundation.dart';
import '../../domain/entities/money.dart';

@immutable
class StockBatchEntity {
  final String id; // UUID or Composite Key
  final int productId;
  final int purchaseId;
  final String batchNumber;
  final double originalQuantity;
  final double remainingQuantity;
  final Money costPrice;
  final DateTime? expiryDate;
  final DateTime receivedDate;

  const StockBatchEntity({
    required this.id,
    required this.productId,
    required this.purchaseId,
    required this.batchNumber,
    required this.originalQuantity,
    required this.remainingQuantity,
    required this.costPrice,
    this.expiryDate,
    required this.receivedDate,
  });

  bool get isExpired => expiryDate != null && DateTime.now().isAfter(expiryDate!);
  bool get isActive => remainingQuantity > 0;
}