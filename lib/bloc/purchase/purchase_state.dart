import 'package:equatable/equatable.dart';
import '../../../core/entity/purchase_bill_entity.dart';
import '../../../domain/entities/money.dart';
import '../../../models/product_model.dart';

enum PurchaseStatus { initial, loading, ready, submitting, success, failure }

class PurchaseState extends Equatable {
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
    // Fix: Use totalAmount.paisas (int) instead of undefined totalCost or double calculations
    int totalPaisas = cartItems.fold(0, (sum, item) => sum + item.totalAmount.paisas);
    return Money(totalPaisas);
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

  @override
  List<Object?> get props => [status, suppliers, products, selectedSupplierId, cartItems, error];
}