import 'package:equatable/equatable.dart';
import '../../../../../models/product_model.dart';
import '../../../../../models/customer_model.dart';
import '../../../../../models/sale_model.dart';
import '../../../../../domain/entities/money.dart';
import '../../../../../models/cart_item_model.dart';

enum SalesStatus { initial, loading, ready, success, error }

class SalesState extends Equatable {
  final SalesStatus status;
  final List<Product> products;
  final List<Product> filteredProducts;
  final List<Customer> filteredCustomers;
  final List<Sale> recentSales;
  final List<CartItem> cartItems;
  final Customer? selectedCustomer;
  final Money subtotal;
  final Money discount;
  final Money grandTotal;
  final Money previousBalance;
  final String? errorMessage;
  final String? successMessage;
  final bool showCustomerList;

  const SalesState({
    this.status = SalesStatus.initial,
    this.products = const [],
    this.filteredProducts = const [],
    this.filteredCustomers = const [],
    this.recentSales = const [],
    this.cartItems = const [],
    this.selectedCustomer,
    this.subtotal = const Money(0),
    this.discount = const Money(0),
    this.grandTotal = const Money(0),
    this.previousBalance = const Money(0),
    this.errorMessage,
    this.successMessage,
    this.showCustomerList = false,
  });

  SalesState copyWith({
    SalesStatus? status,
    List<Product>? products,
    List<Product>? filteredProducts,
    List<Customer>? filteredCustomers,
    List<Sale>? recentSales,
    List<CartItem>? cartItems,
    Customer? selectedCustomer,
    bool clearCustomer = false,
    Money? subtotal,
    Money? discount,
    Money? grandTotal,
    Money? previousBalance,
    String? errorMessage,
    String? successMessage,
    bool? showCustomerList,
  }) {
    return SalesState(
      status: status ?? this.status,
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      recentSales: recentSales ?? this.recentSales,
      cartItems: cartItems ?? this.cartItems,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      grandTotal: grandTotal ?? this.grandTotal,
      previousBalance: previousBalance ?? this.previousBalance,
      errorMessage: errorMessage,
      successMessage: successMessage,
      showCustomerList: showCustomerList ?? this.showCustomerList,
    );
  }

  @override
  List<Object?> get props => [
        status,
        products,
        filteredProducts,
        filteredCustomers,
        recentSales,
        cartItems,
        selectedCustomer,
        subtotal,
        discount,
        grandTotal,
        previousBalance,
        errorMessage,
        successMessage,
        showCustomerList,
      ];
}