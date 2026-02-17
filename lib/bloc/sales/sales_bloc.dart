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
import '../../../../../core/repositories/receipt_repository.dart';
import '../../../../../domain/entities/money.dart';
import '../../../../../models/cart_item_model.dart';
import '../../../../../models/customer_model.dart';

const int _walkInCustomerId = 1;

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final InvoiceRepository _invoiceRepository;
  final ItemsRepository _itemsRepository;
  final CustomersRepository _customersRepository;
  final SettingsRepository _settingsRepository;
  final ReceiptRepository _receiptRepository;
  final StockBloc? _stockBloc;
  StreamSubscription? _stockSubscription;

  SalesBloc({
    required InvoiceRepository invoiceRepository,
    required ItemsRepository itemsRepository,
    required CustomersRepository customersRepository,
    required SettingsRepository settingsRepository,
    required ReceiptRepository receiptRepository,
    StockBloc? stockBloc,
  })  : _invoiceRepository = invoiceRepository,
        _itemsRepository = itemsRepository,
        _customersRepository = customersRepository,
        _settingsRepository = settingsRepository,
        _receiptRepository = receiptRepository,
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
    on<QuickCustomerAddRequested>(_onQuickCustomerAddRequested);
    on<CustomerCreditLimitUpdateRequested>(
        _onCustomerCreditLimitUpdateRequested);
    on<ReceiptPrintRequested>(_onReceiptPrintRequested);
    on<ReceiptPdfSaveRequested>(_onReceiptPdfSaveRequested);

    if (_stockBloc != null) {
      _stockSubscription = _stockBloc!.stream.distinct().listen((stockState) {
        if (stockState.stock.isNotEmpty) {
          add(ProductsUpdated(stockState.stock));
        }
      });
    }
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

      // Validate sale price
      if (event.product.salePrice.isNegative) {
        emit(state.copyWith(
            status: SalesStatus.error,
            errorMessage: 'Product sale price cannot be negative',
            clearCompletedInvoice: true));
        emit(state.copyWith(
            status: SalesStatus.ready,
            errorMessage: null,
            clearCompletedInvoice: true)); // Reset error
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

    // Validate unit price
    if (event.price.isNegative) {
      emit(state.copyWith(
          status: SalesStatus.error,
          errorMessage: 'Item price cannot be negative',
          clearCompletedInvoice: true));
      emit(state.copyWith(
          status: SalesStatus.ready,
          errorMessage: null,
          clearCompletedInvoice: true)); // Reset error
      return;
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
    Money money;
    try {
      money = Money.fromRupeesString(event.discountText);
    } catch (_) {
      money = Money.zero;
    }
    _calculateTotals(emit, proposedDiscount: money);
  }

  void _calculateTotals(Emitter<SalesState> emit, {Money? proposedDiscount}) {
    int subtotalPaisas =
        state.cartItems.fold(0, (sum, item) => sum + item.total.paisas);
    final subtotal = Money(subtotalPaisas);

    Money discount = proposedDiscount ?? state.discount;
    if (discount > subtotal) discount = subtotal;

    Money grandTotal = subtotal - discount;

    // Explicitly prevent negative grandTotal
    if (grandTotal.isNegative) {
      // Defensive safeguard: Should never trigger due to discount capping
      // and upstream negative price validations in _onProductAddedToCart
      // and _onCartItemUpdated, but protects against Money class bugs.
      emit(state.copyWith(
          status: SalesStatus.error,
          errorMessage: 'Calculated grand total cannot be negative',
          clearCompletedInvoice: true));
      emit(state.copyWith(
          status: SalesStatus.ready,
          errorMessage: null,
          clearCompletedInvoice: true)); // Reset error
      return;
    }

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

    // 1. Non-negative payment validation
    if (event.cash.isNegative ||
        event.bank.isNegative ||
        event.credit.isNegative) {
      emit(state.copyWith(
          status: SalesStatus.error,
          errorMessage: 'Payment amounts cannot be negative',
          clearCompletedInvoice: true));
      emit(state.copyWith(
          status: SalesStatus.ready,
          errorMessage: null,
          clearCompletedInvoice: true));
      return;
    }

    // Corrected walk-in customer check
    final isWalkInCustomer = state.selectedCustomer == null ||
      state.selectedCustomer?.id == _walkInCustomerId;

    // 2. Walk-in credit prevention
    if (isWalkInCustomer && event.credit > const Money(0)) {
      emit(state.copyWith(
          status: SalesStatus.error,
          errorMessage: 'Walk-in customers cannot use credit',
          clearCompletedInvoice: true));
      emit(state.copyWith(
          status: SalesStatus.ready,
          errorMessage: null,
          clearCompletedInvoice: true));
      return;
    }

    final totalCashAndBank = event.cash + event.bank;
    final totalPaymentsPlusCreditAllocated =
        event.cash + event.bank + event.credit;

    // Conditional payment validation
    if (isWalkInCustomer) {
      // For walk-in customers: cash + bank must be >= grandTotal (allows overpayment for change)
      if (totalCashAndBank < state.grandTotal) {
        emit(state.copyWith(
            status: SalesStatus.error,
            errorMessage:
                'Walk-in payment (cash + bank) must cover the bill total',
            clearCompletedInvoice: true));
        emit(state.copyWith(
            status: SalesStatus.ready,
            errorMessage: null,
            clearCompletedInvoice: true));
        return;
      }
    } else {
      // For registered customers: cash + bank + credit must exactly equal grandTotal
      if (totalPaymentsPlusCreditAllocated != state.grandTotal) {
        emit(state.copyWith(
            status: SalesStatus.error,
            errorMessage: 'Payment total must exactly match bill total',
            clearCompletedInvoice: true));
        emit(state.copyWith(
            status: SalesStatus.ready,
            errorMessage: null,
            clearCompletedInvoice: true));
        return;
      }
    }

    final cartItemsAsMaps = state.cartItems
        .map((item) => {
              'product_id': item.id,
              'quantity': item.quantity,
            })
        .toList();

    final validation = await _invoiceRepository.validateStock(cartItemsAsMaps);
    if (validation['valid'] != true) {
      emit(state.copyWith(
          status: SalesStatus.error,
          errorMessage:
              validation['error']?.toString() ?? 'Stock validation failed',
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
        cashAmount: event.cash.paisas,
        bankAmount: event.bank.paisas,
        creditAmount: event.credit.paisas,
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
        clearCustomer: true, // Clear customer selection after success
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

  Future<void> _onQuickCustomerAddRequested(
      QuickCustomerAddRequested event, Emitter<SalesState> emit) async {
    try {
      if (event.nameEnglish.trim().isEmpty) {
        emit(state.copyWith(
          status: SalesStatus.error,
          errorMessage: 'Name is required',
          clearCompletedInvoice: true,
        ));
        return;
      }

      final phoneNumber = event.phone.trim();
      if (phoneNumber.isEmpty) {
        emit(state.copyWith(
          status: SalesStatus.error,
          errorMessage: 'Phone number is required',
          clearCompletedInvoice: true,
        ));
        return;
      }

      final existingCustomers = await _customersRepository.searchCustomers(
        phoneNumber,
      );
      final phoneExists =
          existingCustomers.any((c) => c.contactPrimary == phoneNumber);

      if (phoneExists) {
        emit(state.copyWith(
          status: SalesStatus.error,
          errorMessage: 'Phone already exists',
          clearCompletedInvoice: true,
        ));
        return;
      }

      final newCustomer = Customer(
        nameEnglish: event.nameEnglish.trim(),
        nameUrdu: event.nameUrdu.trim(),
        contactPrimary: phoneNumber,
        address: event.address.trim(),
        creditLimit: event.creditLimitPaisas,
      );

      final id = await _customersRepository.addCustomer(newCustomer);
      final savedCustomer = newCustomer.copyWith(id: id);

      emit(state.copyWith(
        status: SalesStatus.success,
        selectedCustomer: savedCustomer,
        quickAddedCustomer: savedCustomer,
        showCustomerList: false,
        successMessage: null,
        clearCompletedInvoice: true,
      ));
      _calculateTotals(emit);
    } catch (e) {
      emit(state.copyWith(
        status: SalesStatus.error,
        errorMessage: e.toString(),
        clearCompletedInvoice: true,
      ));
    }
  }

  Future<void> _onCustomerCreditLimitUpdateRequested(
      CustomerCreditLimitUpdateRequested event,
      Emitter<SalesState> emit) async {
    try {
      await _customersRepository.updateCustomerCreditLimit(
        event.customerId,
        event.newLimitPaisas,
      );

      final selectedCustomer = state.selectedCustomer;
      if (selectedCustomer != null && selectedCustomer.id == event.customerId) {
        emit(state.copyWith(
          selectedCustomer:
              selectedCustomer.copyWith(creditLimit: event.newLimitPaisas),
          status: SalesStatus.success,
          successMessage: 'Credit limit updated',
          clearCompletedInvoice: true,
        ));
        _calculateTotals(emit);
        return;
      }

      emit(state.copyWith(
        status: SalesStatus.success,
        successMessage: 'Credit limit updated',
        clearCompletedInvoice: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SalesStatus.error,
        errorMessage: e.toString(),
        clearCompletedInvoice: true,
      ));
    }
  }

  Future<void> _onReceiptPrintRequested(
      ReceiptPrintRequested event, Emitter<SalesState> emit) async {
    if (event.invoice.status == 'CANCELLED') {
      emit(state.copyWith(
        status: SalesStatus.error,
        errorMessage: 'Cannot print cancelled invoice',
        clearCompletedInvoice: true,
      ));
      return;
    }

    try {
      final receiptData = await _receiptRepository.generateReceiptData(
        event.invoice,
      );
      await _receiptRepository.printReceipt(receiptData);
      final invoiceId = event.invoice.id;
      if (invoiceId != null) {
        await _receiptRepository.trackPrint(invoiceId);
      }

      final recentInvoices =
          await _invoiceRepository.getRecentInvoicesWithCustomer();
      emit(state.copyWith(
        status: SalesStatus.success,
        successMessage: 'Receipt sent to printer',
        recentInvoices: recentInvoices,
        clearCompletedInvoice: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SalesStatus.error,
        errorMessage: e.toString(),
        clearCompletedInvoice: true,
      ));
    }
  }

  Future<void> _onReceiptPdfSaveRequested(
      ReceiptPdfSaveRequested event, Emitter<SalesState> emit) async {
    if (event.invoice.status == 'CANCELLED') {
      emit(state.copyWith(
        status: SalesStatus.error,
        errorMessage: 'Cannot print cancelled invoice',
        clearCompletedInvoice: true,
      ));
      return;
    }

    try {
      final path = await _receiptRepository.saveReceiptAsPDF(event.invoice);
      emit(state.copyWith(
        status: SalesStatus.success,
        successMessage: 'Receipt saved to: $path',
        clearCompletedInvoice: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SalesStatus.error,
        errorMessage: 'Error saving PDF: $e',
        clearCompletedInvoice: true,
      ));
    }
  }
}
