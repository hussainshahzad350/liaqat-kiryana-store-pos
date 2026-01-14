import 'package:equatable/equatable.dart';
import '../../../../../models/product_model.dart';
import '../../../../../models/customer_model.dart';
import '../../../../../domain/entities/money.dart';

abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();
  @override
  List<Object?> get props => [];
}

class InvoiceStarted extends InvoiceEvent {}

class ProductSearchChanged extends InvoiceEvent {
  final String query;
  const ProductSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class CustomerSearchChanged extends InvoiceEvent {
  final String query;
  const CustomerSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class CustomerSelected extends InvoiceEvent {
  final Customer? customer;
  const CustomerSelected(this.customer);
  @override
  List<Object?> get props => [customer];
}

class ProductAddedToCart extends InvoiceEvent {
  final Product product;
  final double quantity;
  const ProductAddedToCart(this.product, {this.quantity = 1.0});
  @override
  List<Object?> get props => [product, quantity];
}

class CartItemUpdated extends InvoiceEvent {
  final int index;
  final double quantity;
  final Money price;
  const CartItemUpdated({required this.index, required this.quantity, required this.price});
  @override
  List<Object?> get props => [index, quantity, price];
}

class CartItemRemoved extends InvoiceEvent {
  final int index;
  const CartItemRemoved(this.index);
  @override
  List<Object?> get props => [index];
}

class CartCleared extends InvoiceEvent {}

class DiscountChanged extends InvoiceEvent {
  final String discountText;
  const DiscountChanged(this.discountText);
  @override
  List<Object?> get props => [discountText];
}

class InvoiceProcessed extends InvoiceEvent {
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

class InvoiceCancelled extends InvoiceEvent {
  final int invoiceId;
  final String reason;
  const InvoiceCancelled({required this.invoiceId, required this.reason});
  @override
  List<Object?> get props => [invoiceId, reason];
}