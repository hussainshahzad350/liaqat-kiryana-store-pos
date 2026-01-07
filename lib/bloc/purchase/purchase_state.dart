import 'package:flutter/foundation.dart';
import '../../../core/entity/purchase_bill_entity.dart';
import '../../../models/product_model.dart';
import '../../../domain/entities/money.dart';

enum PurchaseStatus { initial, loading, ready, submitting, success, failure }

@immutable
class PurchaseState {
  final PurchaseStatus status;
  final List<Map<String, dynamic>> suppliers;
  final List<Product> products;
  final int? selectedSupplierId;
  final List<PurchaseItemEntity> cartItems;
  final String? error;

  const PurchaseState({
    this.status = PurchaseStatus.initial,
    this.suppliers = const [],
    this.products = const [],
    this.selectedSupplierId,
    this.cartItems = const [],
    this.error,
  });

  Money get totalAmount {
    int total = 0;
    for (var item in cartItems) {
      total += item.totalCost.paisas;
    }
    return Money(total);
  }

  PurchaseState copyWith({
    PurchaseStatus? status,
    List<Map<String, dynamic>>? suppliers,
    List<Product>? products,
    int? selectedSupplierId,
    List<PurchaseItemEntity>? cartItems,
    String? error,
  }) {
    return PurchaseState(
      status: status ?? this.status,
      suppliers: suppliers ?? this.suppliers,
      products: products ?? this.products,
      selectedSupplierId: selectedSupplierId ?? this.selectedSupplierId,
      cartItems: cartItems ?? this.cartItems,
      error: error ?? this.error,
    );
  }
}