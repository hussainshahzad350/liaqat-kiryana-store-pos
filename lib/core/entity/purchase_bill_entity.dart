import 'package:flutter/foundation.dart';
import '../../domain/entities/money.dart';

@immutable
class PurchaseItemEntity {
  final int productId;
  final String productName;
  final double quantity;
  final Money costPrice;
  final String? batchNumber;
  final String? expiryDate;

  const PurchaseItemEntity({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.costPrice,
    this.batchNumber,
    this.expiryDate,
  });

  // Calculated property for total amount of this line item
  Money get totalAmount => Money((costPrice.paisas * quantity).round());

  PurchaseItemEntity copyWith({
    int? productId,
    String? productName,
    double? quantity,
    Money? costPrice,
    String? batchNumber,
    String? expiryDate,
  }) {
    return PurchaseItemEntity(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}

@immutable
class PurchaseBillEntity {
  final int? id;
  final int supplierId;
  final String invoiceNumber;
  final DateTime purchaseDate;
  final Money totalAmount;
  final String? notes;
  final List<PurchaseItemEntity> items;
  final DateTime createdAt;

  const PurchaseBillEntity({
    this.id,
    required this.supplierId,
    required this.invoiceNumber,
    required this.purchaseDate,
    required this.totalAmount,
    this.notes,
    required this.items,
    required this.createdAt,
  });
}