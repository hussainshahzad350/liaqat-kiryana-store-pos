import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaqat_store/core/repositories/settings_repository.dart';
import 'package:liaqat_store/bloc/stock/stock_bloc.dart';
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
  final SettingsRepository _settingsRepository;
  final StockBloc? _stockBloc;
  StreamSubscription? _stockSubscription;

  SalesBloc({
    required InvoiceRepository invoiceRepository,
    required ItemsRepository itemsRepository,
    required CustomersRepository customersRepository,
    required SettingsRepository settingsRepository,
    StockBloc? stockBloc,
  })  : _invoiceRepository = invoiceRepository,
        _itemsRepository = itemsRepository,
        _customersRepository = customersRepository,
        _settingsRepository = settingsRepository,
        _stockBloc = stockBloc,
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
    on<ProductsUpdated>(_onProductsUpdated);

    _stockSubscription = _stockBloc?.stream.listen((stockState) {
      if (stockState.stock.isNotEmpty) {
        add(ProductsUpdated(stockState.stock));
      }
    });
  }

  @override
  Future<void> close() {
    _stockSubscription?.cancel();
    return super.close();
  }

  void _onProductsUpdated(ProductsUpdated event, Emitter<SalesState> emit) {
    emit(state.copyWith(
      products: event.products,
      filteredProducts: event.products, // Also update filtered list
    ));
  }

  Future<void> _onStarted(SalesStarted event, Emitter<SalesState> emit) async {
    // On start, always clear any previous completed invoice.
    emit(state.copyWith(
        status: SalesStatus.loading, clearCompletedInvoice: true));
    try {
      final products = await _itemsRepository.getAllProducts();
      final recentInvoices =
          await _invoiceRepository.getRecentInvoicesWithCustomer();
      emit(state.copyWith(
        status: SalesStatus.ready,
        products: products,
        filteredProducts: products,
        recentInvoices: recentInvoices,
        clearCompletedInvoice: true, // Ensure it's clear on ready state too
      ));
    } catch (e) {
      emit(state.copyWith(
          status: SalesStatus.error,
          errorMessage: e.toString(),
          clearCompletedInvoice: true));
    }
  }

  void _onProductSearchChanged(
      ProductSearchChanged event, Emitter<SalesState> emit) {
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

  Future<void> _onCustomerSearchChanged(
      CustomerSearchChanged event, Emitter<SalesState> emit) async {
    if (event.query.isEmpty) {
      emit(state.copyWith(filteredCustomers: [], showCustomerList: false));
      return;
    }
    try {
      final results =
          await _customersRepository.searchCustomers(event.query, limit: 20);
      emit(state.copyWith(
          filteredCustomers: results, showCustomerList: results.isNotEmpty));
    } catch (e) {
      // Handle error silently or log
    }
  }

  void _onCustomerSelected(CustomerSelected event, Emitter<SalesState> emit) {
    if (event.customer == null) {
      emit(state.copyWith(clearCustomer: true, showCustomerList: false));
    } else {
      emit(state.copyWith(
          selectedCustomer: event.customer, showCustomerList: false));
    }
    _calculateTotals(emit);
  }

  void _onProductAddedToCart(
      ProductAddedToCart event, Emitter<SalesState> emit) {
    final List<CartItem> updatedCart = List.from(state.cartItems);
    final index = updatedCart.indexWhere((item) => item.id == event.product.id);
    final availableStock = (event.product.currentStock as num).toDouble();

    if (index != -1) {
      final currentQty = updatedCart[index].quantity;
      final newQty = currentQty + event.quantity;

      if (newQty > availableStock) {
        emit(state.copyWith(
            status: SalesStatus.error,
            errorMessage: 'Insufficient stock',
            clearCompletedInvoice: true));
        emit(state.copyWith(
            status: SalesStatus.ready,
            errorMessage: null,
            clearCompletedInvoice: true)); // Reset error
        return;
      }

      updatedCart[index] = updatedCart[index].copyWith(
        quantity: newQty,
        total: Money((newQty * updatedCart[index].unitPrice.paisas).round()),
      );
    } else {
      if (availableStock < event.quantity) {
        emit(state.copyWith(
            status: SalesStatus.error,
            errorMessage: 'Out of stock',
            clearCompletedInvoice: true));
        emit(state.copyWith(
            status: SalesStatus.ready,
            errorMessage: null,
            clearCompletedInvoice: true));
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
      emit(state.copyWith(
          status: SalesStatus.error,
          errorMessage: 'Stock limit reached',
          clearCompletedInvoice: true));
      emit(state.copyWith(
          status: SalesStatus.ready,
          errorMessage: null,
          clearCompletedInvoice: true));
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
    int subtotalPaisas =
        state.cartItems.fold(0, (sum, item) => sum + item.total.paisas);
    final subtotal = Money(subtotalPaisas);

    Money discount = proposedDiscount ?? state.discount;
    if (discount > subtotal) discount = subtotal;

    Money grandTotal = subtotal - discount;
    if (grandTotal < const Money(0)) grandTotal = const Money(0);

    Money previousBalance = state.selectedCustomer != null
      ? Money(state.selectedCustomer!.outstandingBalance)
      : Money.zero;

    emit(state.copyWith(
      subtotal: subtotal,
      discount: discount,
      grandTotal: grandTotal,
      previousBalance: previousBalance,
    ));
  }

  Future<void> _onInvoiceProcessed(
      InvoiceProcessed event, Emitter<SalesState> emit) async {
    emit(state.copyWith(
        status: SalesStatus.loading, clearCompletedInvoice: true));

    final cartItemsAsMaps = state.cartItems
        .map((item) => {
              'product_id': item.id,
              'quantity': item.quantity,
            })
        .toList();

    final validation = await _invoiceRepository.validateStock(cartItemsAsMaps);
    if (!validation['valid']) {
      emit(state.copyWith(
          status: SalesStatus.error,
          errorMessage: validation['error'],
          clearCompletedInvoice: true));
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
      final customer = await _customersRepository.getCustomerById(customerId);
      final shopProfile = await _settingsRepository.getShopProfile();

      final invoiceId = await _invoiceRepository.createInvoiceWithTransaction(
        customerId: customerId,
        items: invoiceItems,
        grandTotal: state.grandTotal.paisas,
        discount: state.discount.paisas,
        notes: notes,
        customerData: customer?.toMap(),
        shopProfile: shopProfile,
        stockBloc: _stockBloc,
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
      emit(state.copyWith(
          status: SalesStatus.error,
          errorMessage: e.toString(),
          clearCompletedInvoice: true));
    }
  }

  Future<void> _onInvoiceCancelled(
      InvoiceCancelled event, Emitter<SalesState> emit) async {
    emit(state.copyWith(status: SalesStatus.loading));
    try {
      await _invoiceRepository.cancelInvoice(
        invoiceId: event.invoiceId,
        cancelledBy: 'Cashier',
        reason: event.reason,
        stockBloc: _stockBloc,
      );
      add(SalesStarted()); // Refresh
      emit(state.copyWith(
          status: SalesStatus.success,
          successMessage: 'Invoice Cancelled',
          clearCompletedInvoice: true));
    } catch (e) {
      emit(state.copyWith(
          status: SalesStatus.error,
          errorMessage: e.toString(),
          clearCompletedInvoice: true));
    }
  }
}
