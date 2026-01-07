import 'package:flutter/foundation.dart';
import '../../domain/entities/money.dart';

@immutable
class PurchaseBillEntity {
  final int? id;
  final int supplierId;
  final String? supplierName;
  final String invoiceNumber;
  final DateTime purchaseDate;
  final Money totalAmount;
  final String? notes;
  final List<PurchaseItemEntity> items;
  final bool isCancelled;
  final DateTime createdAt;

  const PurchaseBillEntity({
    this.id,
    required this.supplierId,
    this.supplierName,
    required this.invoiceNumber,
    required this.purchaseDate,
    required this.totalAmount,
    this.notes,
    required this.items,
    this.isCancelled = false,
    required this.createdAt,
  });

  int get itemCount => items.length;
}

@immutable
class PurchaseItemEntity {
  final int? id;
  final int productId;
  final String productName;
  final double quantity;
  final Money costPrice;
  final Money totalCost;

  const PurchaseItemEntity({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.costPrice,
    required this.totalCost,
  });
}