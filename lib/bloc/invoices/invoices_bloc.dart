import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'invoices_event.dart';
import 'invoices_state.dart';
import '../../../../../core/repositories/invoices_repository.dart';
import '../../../../../core/repositories/items_repository.dart';
import '../../../../../core/repositories/customers_repository.dart';
import '../../../../../core/utils/currency_utils.dart';
import '../../../../../domain/entities/money.dart';
import '../../../../../models/cart_item_model.dart';

class InvoicesBloc extends Bloc<InvoicesEvent, InvoicesState> {
  final InvoicesRepository _invoicesRepository;
  final ItemsRepository _itemsRepository;
  final CustomersRepository _customersRepository;

  InvoicesBloc({
    required InvoicesRepository invoicesRepository,
    required ItemsRepository itemsRepository,
    required CustomersRepository customersRepository,
  })  : _invoicesRepository = invoicesRepository,
        _itemsRepository = itemsRepository,
        _customersRepository = customersRepository,
        super(const InvoicesState()) {
    on<InvoicesStarted>(_onStarted);
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

  Future<void> _onStarted(InvoicesStarted event, Emitter<InvoicesState> emit) async {
    emit(state.copyWith(status: InvoicesStatus.loading));
    try {
      final products = await _itemsRepository.getAllProducts();
      final recentInvoices = await _invoicesRepository.getRecentInvoices();
      emit(state.copyWith(
        status: InvoicesStatus.ready,
        products: products,
        filteredProducts: products,
        recentInvoices: recentInvoices,
      ));
    } catch (e) {
      emit(state.copyWith(status: InvoicesStatus.error, errorMessage: e.toString()));
    }
  }

  void _onProductSearchChanged(ProductSearchChanged event, Emitter<InvoicesState> emit) {
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

  Future<void> _onCustomerSearchChanged(CustomerSearchChanged event, Emitter<InvoicesState> emit) async {
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

  void _onCustomerSelected(CustomerSelected event, Emitter<InvoicesState> emit) {
    if (event.customer == null) {
      emit(state.copyWith(clearCustomer: true, showCustomerList: false));
    } else {
      emit(state.copyWith(selectedCustomer: event.customer, showCustomerList: false));
    }
    _calculateTotals(emit);
  }

  void _onProductAddedToCart(ProductAddedToCart event, Emitter<InvoicesState> emit) {
    final List<CartItem> updatedCart = List.from(state.cartItems);
    final index = updatedCart.indexWhere((item) => item.id == event.product.id);
    final availableStock = (event.product.currentStock as num).toDouble();

    if (index != -1) {
      final currentQty = updatedCart[index].quantity;
      final newQty = currentQty + event.quantity;
      
      if (newQty > availableStock) {
        emit(state.copyWith(status: InvoicesStatus.error, errorMessage: 'Insufficient stock'));
        emit(state.copyWith(status: InvoicesStatus.ready, errorMessage: null)); // Reset error
        return;
      }

      updatedCart[index] = updatedCart[index].copyWith(
        quantity: newQty,
        total: Money((newQty * updatedCart[index].unitPrice.paisas).round()),
      );
    } else {
      if (availableStock < event.quantity) {
        emit(state.copyWith(status: InvoicesStatus.error, errorMessage: 'Out of stock'));
        emit(state.copyWith(status: InvoicesStatus.ready, errorMessage: null));
        return;
      }

      updatedCart.add(CartItem(
        id: event.product.id,
        nameUrdu: event.product.nameUrdu,
        nameEnglish: event.product.nameEnglish,
        unitName: event.product.unitType,
        itemCode: event.product.itemCode,
        currentStock: availableStock,
        unitPrice: Money(event.product.salePrice),
        quantity: event.quantity,
        total: Money((event.product.salePrice * event.quantity).round()),
      ));
    }

    emit(state.copyWith(cartItems: updatedCart));
    _calculateTotals(emit);
  }

  void _onCartItemUpdated(CartItemUpdated event, Emitter<InvoicesState> emit) {
    final List<CartItem> updatedCart = List.from(state.cartItems);
    if (event.index >= updatedCart.length) return;

    final item = updatedCart[event.index];
    final availableStock = item.currentStock;
    
    double newQty = event.quantity;
    if (newQty > availableStock) {
      newQty = availableStock;
      emit(state.copyWith(status: InvoicesStatus.error, errorMessage: 'Stock limit reached'));
      emit(state.copyWith(status: InvoicesStatus.ready, errorMessage: null));
    }

    updatedCart[event.index] = item.copyWith(
      quantity: newQty,
      unitPrice: event.price,
      total: Money((event.price.paisas * newQty).round()),
    );

    emit(state.copyWith(cartItems: updatedCart));
    _calculateTotals(emit);
  }

  void _onCartItemRemoved(CartItemRemoved event, Emitter<InvoicesState> emit) {
    final List<CartItem> updatedCart = List.from(state.cartItems);
    if (event.index < updatedCart.length) {
      updatedCart.removeAt(event.index);
      emit(state.copyWith(cartItems: updatedCart));
      _calculateTotals(emit);
    }
  }

  void _onCartCleared(CartCleared event, Emitter<InvoicesState> emit) {
    emit(state.copyWith(
      cartItems: [],
      clearCustomer: true,
      subtotal: const Money(0),
      discount: const Money(0),
      grandTotal: const Money(0),
      previousBalance: const Money(0),
    ));
  }

  void _onDiscountChanged(DiscountChanged event, Emitter<InvoicesState> emit) {
    final money = Money.fromRupeesString(event.discountText);
    _calculateTotals(emit, proposedDiscount: money);
  }

  void _calculateTotals(Emitter<InvoicesState> emit, {Money? proposedDiscount}) {
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

  Future<void> _onInvoiceProcessed(InvoiceProcessed event, Emitter<InvoicesState> emit) async {
    emit(state.copyWith(status: InvoicesStatus.loading));
    
    final cartItemsAsMaps = state.cartItems
        .map((item) => {
              'id': item.id,
              'quantity': item.quantity,
            })
        .toList();

    final validation = await _invoicesRepository.validateStock(cartItemsAsMaps);
    if (!validation['valid']) {
      emit(state.copyWith(status: InvoicesStatus.error, errorMessage: validation['error']));
      emit(state.copyWith(status: InvoicesStatus.ready, errorMessage: null));
      return;
    }

    final invoiceData = {
      'customer_id': state.selectedCustomer?.id,
      'grand_total_paisas': state.grandTotal.paisas,
      'discount_paisas': state.discount.paisas,
      'cash_paisas': event.cash.paisas,
      'bank_paisas': event.bank.paisas,
      'credit_paisas': event.credit.paisas,
      'receipt_language': event.languageCode,
      'items': state.cartItems.map((item) => {
        'id': item.id,
        'name_english': item.nameEnglish,
        'name_urdu': item.nameUrdu,
        'unit_name': item.unitName,
        'quantity': item.quantity,
        'sale_price': item.unitPrice.paisas,
        'total': item.total.paisas,
      }).toList(),
    };

    try {
      await _invoicesRepository.completeInvoiceWithSnapshot(invoiceData);
      emit(state.copyWith(status: InvoicesStatus.success, successMessage: 'Invoice Completed'));
      add(CartCleared());
      add(InvoicesStarted()); // Refresh data
    } catch (e) {
      emit(state.copyWith(status: InvoicesStatus.error, errorMessage: e.toString()));
      emit(state.copyWith(status: InvoicesStatus.ready, errorMessage: null));
    }
  }

  Future<void> _onInvoiceCancelled(InvoiceCancelled event, Emitter<InvoicesState> emit) async {
    try {
      await _invoicesRepository.cancelInvoice(
        invoiceId: event.invoiceId,
        cancelledBy: 'Cashier',
        reason: event.reason,
      );
      add(InvoicesStarted()); // Refresh
      emit(state.copyWith(status: InvoicesStatus.success, successMessage: 'Invoice Cancelled'));
    } catch (e) {
      emit(state.copyWith(status: InvoicesStatus.error, errorMessage: e.toString()));
    }
  }
}