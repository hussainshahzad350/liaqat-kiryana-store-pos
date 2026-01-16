import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'sales_event.dart';
import 'sales_state.dart';
import '../../../../../core/repositories/invoice_repository.dart';
import '../../../../../core/repositories/items_repository.dart';
import '../../../../../core/repositories/customers_repository.dart';
import '../../../../../domain/entities/money.dart';
import '../../../../../models/cart_item_model.dart';

const int _walkInCustomerId = 1;

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final InvoiceRepository _invoiceRepository;
  final ItemsRepository _itemsRepository;
  final CustomersRepository _customersRepository;

  SalesBloc({
    required InvoiceRepository invoiceRepository,
    required ItemsRepository itemsRepository,
    required CustomersRepository customersRepository,
  })  : _invoiceRepository = invoiceRepository,
         _itemsRepository = itemsRepository,
        _customersRepository = customersRepository,
        super(const SalesState()) {
    on<SalesStarted>(_onStarted);
    on<ProductSearchChanged>(_onProductSearchChanged);
    on<CustomerSearchChanged>(_onCustomerSearchChanged);
    on<CustomerSelected>(_onCustomerSelected);
    on<ProductAddedToCart>(_onProductAddedToCart);
    on<CartItemUpdated>(_onCartItemUpdated);
    on<CartItemRemoved>(_onCartItemRemoved);
    on<CartCleared>(_onCartCleared);
    on<DiscountChanged>(_onDiscountChanged);
    on<InvoiceProcessed>(_onInvoiceProcessed);
    on<InvoiceCancelled>(_onInvoiceCancelled);
  }

  Future<void> _onStarted(SalesStarted event, Emitter<SalesState> emit) async {
    emit(state.copyWith(status: SalesStatus.loading, clearCompletedInvoice: true));
    try {
      final products = await _itemsRepository.getAllProducts();
      final recentInvoices = await _invoiceRepository.getRecentInvoicesWithCustomer();
      emit(state.copyWith(
        status: SalesStatus.ready,
        products: products,
        filteredProducts: products,
        recentInvoices: recentInvoices,
      ));
    } catch (e) {
      emit(state.copyWith(status: SalesStatus.error, errorMessage: e.toString()));
    }
  }

  void _onProductSearchChanged(ProductSearchChanged event, Emitter<SalesState> emit) {
    final query = event.query.toLowerCase();
    if (query.isEmpty) {
      emit(state.copyWith(filteredProducts: state.products));
    } else {
      final filtered = state.products.where((p) {
        final nameEng = p.nameEnglish.toLowerCase();
        final itemCode = (p.itemCode ?? '').toLowerCase();
        return nameEng.contains(query) || itemCode.contains(query);
      }).toList();
      emit(state.copyWith(filteredProducts: filtered));
    }
  }

  Future<void> _onCustomerSearchChanged(CustomerSearchChanged event, Emitter<SalesState> emit) async {
    if (event.query.isEmpty) {
      emit(state.copyWith(filteredCustomers: [], showCustomerList: false));
      return;
    }
    try {
      final results = await _customersRepository.searchCustomers(event.query, limit: 20);
      emit(state.copyWith(filteredCustomers: results, showCustomerList: results.isNotEmpty));
    } catch (e) {
      // Handle error silently or log
    }
  }

  void _onCustomerSelected(CustomerSelected event, Emitter<SalesState> emit) {
    if (event.customer == null) {
      emit(state.copyWith(clearCustomer: true, showCustomerList: false));
    } else {
      emit(state.copyWith(selectedCustomer: event.customer, showCustomerList: false));
    }
    _calculateTotals(emit);
  }

  void _onProductAddedToCart(ProductAddedToCart event, Emitter<SalesState> emit) {
    final List<CartItem> updatedCart = List.from(state.cartItems);
    final index = updatedCart.indexWhere((item) => item.id == event.product.id);
    final availableStock = (event.product.currentStock as num).toDouble();

    if (index != -1) {
      final currentQty = updatedCart[index].quantity;
      final newQty = currentQty + event.quantity;
      
      if (newQty > availableStock) {
        emit(state.copyWith(status: SalesStatus.error, errorMessage: 'Insufficient stock'));
        emit(state.copyWith(status: SalesStatus.ready, errorMessage: null)); // Reset error
        return;
      }

      updatedCart[index] = updatedCart[index].copyWith(
        quantity: newQty,
        total: Money((newQty * updatedCart[index].unitPrice.paisas).round()),
      );
    } else {
      if (availableStock < event.quantity) {
        emit(state.copyWith(status: SalesStatus.error, errorMessage: 'Out of stock'));
        emit(state.copyWith(status: SalesStatus.ready, errorMessage: null));
        return;
      }

      updatedCart.add(CartItem(
        id: event.product.id ?? 0,
        nameUrdu: event.product.nameUrdu ?? '',
        nameEnglish: event.product.nameEnglish,
        unitName: event.product.unitType,
        itemCode: event.product.itemCode,
        currentStock: availableStock,
        unitPrice: event.product.salePrice,
        quantity: event.quantity,
        total: event.product.salePrice * event.quantity,
      ));
    }

    emit(state.copyWith(cartItems: updatedCart));
    _calculateTotals(emit);
  }

  void _onCartItemUpdated(CartItemUpdated event, Emitter<SalesState> emit) {
    final List<CartItem> updatedCart = List.from(state.cartItems);
    if (event.index >= updatedCart.length) return;

    final item = updatedCart[event.index];
    final availableStock = item.currentStock;
    
    double newQty = event.quantity;
    if (newQty > availableStock) {
      newQty = availableStock;
      emit(state.copyWith(status: SalesStatus.error, errorMessage: 'Stock limit reached'));
      emit(state.copyWith(status: SalesStatus.ready, errorMessage: null));
    }

    updatedCart[event.index] = item.copyWith(
      quantity: newQty,
      unitPrice: event.price,
      total: Money((event.price.paisas * newQty).round()),
    );

    emit(state.copyWith(cartItems: updatedCart));
    _calculateTotals(emit);
  }

  void _onCartItemRemoved(CartItemRemoved event, Emitter<SalesState> emit) {
    final List<CartItem> updatedCart = List.from(state.cartItems);
    if (event.index < updatedCart.length) {
      updatedCart.removeAt(event.index);
      emit(state.copyWith(cartItems: updatedCart));
      _calculateTotals(emit);
    }
  }

  void _onCartCleared(CartCleared event, Emitter<SalesState> emit) {
    emit(state.copyWith(
      cartItems: [],
      clearCustomer: true,
      subtotal: const Money(0),
      discount: const Money(0),
      grandTotal: const Money(0),
      previousBalance: const Money(0),
      clearCompletedInvoice: true,
    ));
  }

  void _onDiscountChanged(DiscountChanged event, Emitter<SalesState> emit) {
    final money = Money.fromRupeesString(event.discountText);
    _calculateTotals(emit, proposedDiscount: money);
  }

  void _calculateTotals(Emitter<SalesState> emit, {Money? proposedDiscount}) {
    int subtotalPaisas = state.cartItems.fold(0, (sum, item) => sum + item.total.paisas);
    final subtotal = Money(subtotalPaisas);

    Money discount = proposedDiscount ?? state.discount;
    if (discount > subtotal) discount = subtotal;

    Money grandTotal = subtotal - discount;
    if (grandTotal < const Money(0)) grandTotal = const Money(0);

    Money previousBalance = Money(state.selectedCustomer?.outstandingBalance ?? 0);

    emit(state.copyWith(
      subtotal: subtotal,
      discount: discount,
      grandTotal: grandTotal,
      previousBalance: previousBalance,
    ));
  }

  Future<void> _onInvoiceProcessed(InvoiceProcessed event, Emitter<SalesState> emit) async {
    emit(state.copyWith(status: SalesStatus.loading));

    final cartItemsAsMaps = state.cartItems
        .map((item) => {
              'product_id': item.id,
              'quantity': item.quantity,
            })
        .toList();

    final validation = await _invoiceRepository.validateStock(cartItemsAsMaps);
    if (!validation['valid']) {
      emit(state.copyWith(status: SalesStatus.error, errorMessage: validation['error']));
      emit(state.copyWith(status: SalesStatus.ready, errorMessage: null));
      return;
    }

    final invoiceItems = state.cartItems.map((item) {
      return {
        'product_id': item.id,
        'name_english': item.nameEnglish,
        'name_urdu': item.nameUrdu,
        'quantity': item.quantity,
        'unit_price': item.unitPrice.paisas,
        'total': item.total.paisas,
      };
    }).toList();

    final customerId = state.selectedCustomer?.id ?? _walkInCustomerId;

    final paymentDetails = {
      'cash': event.cash.paisas,
      'bank': event.bank.paisas,
      'credit': event.credit.paisas,
    };
    final notes = jsonEncode(paymentDetails);


    try {
      final invoiceId = await _invoiceRepository.createInvoiceWithTransaction(
        customerId: customerId,
        items: invoiceItems,
        grandTotal: state.grandTotal.paisas,
        discount: state.discount.paisas,
        notes: notes,
      );

      final invoice = await _invoiceRepository.getInvoiceWithItems(invoiceId);

      emit(state.copyWith(
        status: SalesStatus.success,
        successMessage: 'Invoice Completed',
        completedInvoice: invoice,
      ));
      add(CartCleared());
      add(SalesStarted()); // Refresh data
    } catch (e) {
      emit(state.copyWith(status: SalesStatus.error, errorMessage: e.toString()));
      emit(state.copyWith(status: SalesStatus.ready, errorMessage: null));
    }
  }

  Future<void> _onInvoiceCancelled(InvoiceCancelled event, Emitter<SalesState> emit) async {
    try {
      await _invoiceRepository.cancelInvoice(
        invoiceId: event.invoiceId,
        cancelledBy: 'Cashier',
        reason: event.reason,
      );
      add(SalesStarted()); // Refresh
      emit(state.copyWith(status: SalesStatus.success, successMessage: 'Invoice Cancelled'));
    } catch (e) {
      emit(state.copyWith(status: SalesStatus.error, errorMessage: e.toString()));
    }
  }
}
