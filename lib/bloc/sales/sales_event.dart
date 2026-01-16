import 'package:equatable/equatable.dart';
import '../../../../../models/product_model.dart';
import '../../../../../models/customer_model.dart';
import '../../../../../domain/entities/money.dart';

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
  final Money price;
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

class InvoiceProcessed extends SalesEvent {
  final Money cash;
  final Money bank;
  final Money credit;
  final Money change;
  final String languageCode;
  const InvoiceProcessed({
    required this.cash,
    required this.bank,
    required this.credit,
    required this.change,
    required this.languageCode,
  });
  @override
  List<Object?> get props => [cash, bank, credit, change, languageCode];
}

class InvoiceCancelled extends SalesEvent {
  final int invoiceId;
  final String reason;
  const InvoiceCancelled({required this.invoiceId, required this.reason});
  @override
  List<Object?> get props => [invoiceId, reason];
}

class ProductsUpdated extends SalesEvent {
  final List<Product> products;
  const ProductsUpdated(this.products);

  @override
  List<Object?> get props => [products];
}
