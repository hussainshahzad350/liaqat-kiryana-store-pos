import 'package:equatable/equatable.dart';
import '../../../../models/product_model.dart';
import '../../../../models/customer_model.dart';

abstract class SalesEvent extends Equatable {
  const SalesEvent();
  @override
  List<Object?> get props => [];
}

class SalesStarted extends SalesEvent {}

class ProductSearchChanged extends SalesEvent {
  final String query;
  const ProductSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class CustomerSearchChanged extends SalesEvent {
  final String query;
  const CustomerSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class CustomerSelected extends SalesEvent {
  final Customer? customer;
  const CustomerSelected(this.customer);
  @override
  List<Object?> get props => [customer];
}

class ProductAddedToCart extends SalesEvent {
  final Product product;
  final double quantity;
  const ProductAddedToCart(this.product, {this.quantity = 1.0});
  @override
  List<Object?> get props => [product, quantity];
}

class CartItemUpdated extends SalesEvent {
  final int index;
  final double quantity;
  final int price;
  const CartItemUpdated({required this.index, required this.quantity, required this.price});
  @override
  List<Object?> get props => [index, quantity, price];
}

class CartItemRemoved extends SalesEvent {
  final int index;
  const CartItemRemoved(this.index);
  @override
  List<Object?> get props => [index];
}

class CartCleared extends SalesEvent {}

class DiscountChanged extends SalesEvent {
  final String discountText;
  const DiscountChanged(this.discountText);
  @override
  List<Object?> get props => [discountText];
}

class SaleProcessed extends SalesEvent {
  final int cash;
  final int bank;
  final int credit;
  final int change;
  final String languageCode;
  const SaleProcessed({
    required this.cash,
    required this.bank,
    required this.credit,
    required this.change,
    required this.languageCode,
  });
  @override
  List<Object?> get props => [cash, bank, credit, change, languageCode];
}

class SaleCancelled extends SalesEvent {
  final int saleId;
  final String reason;
  const SaleCancelled({required this.saleId, required this.reason});
  @override
  List<Object?> get props => [saleId, reason];
}