import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'sales_event.dart';
import 'sales_state.dart';
import '../../../../../core/repositories/sales_repository.dart';
import '../../../../../core/repositories/items_repository.dart';
import '../../../../../core/repositories/customers_repository.dart';
import '../../../../../core/utils/currency_utils.dart';
import '../../../../../domain/entities/money.dart';

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final SalesRepository _salesRepository;
  final ItemsRepository _itemsRepository;
  final CustomersRepository _customersRepository;

  SalesBloc({
    required SalesRepository salesRepository,
    required ItemsRepository itemsRepository,
    required CustomersRepository customersRepository,
  })  : _salesRepository = salesRepository,
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
    on<SaleProcessed>(_onSaleProcessed);
    on<SaleCancelled>(_onSaleCancelled);
  }

  Future<void> _onStarted(SalesStarted event, Emitter<SalesState> emit) async {
    emit(state.copyWith(status: SalesStatus.loading));
    try {
      final products = await _itemsRepository.getAllProducts();
      final recentSales = await _salesRepository.getRecentSales();
      emit(state.copyWith(
        status: SalesStatus.ready,
        products: products,
        filteredProducts: products,
        recentSales: recentSales,
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
    final List<Map<String, dynamic>> updatedCart = List.from(state.cartItems);
    final index = updatedCart.indexWhere((item) => item['id'] == event.product.id);
    final availableStock = (event.product.currentStock as num).toDouble();

    if (index != -1) {
      final currentQty = updatedCart[index]['quantity'] as double;
      final newQty = currentQty + event.quantity;
      
      if (newQty > availableStock) {
        emit(state.copyWith(status: SalesStatus.error, errorMessage: 'Insufficient stock'));
        emit(state.copyWith(status: SalesStatus.ready, errorMessage: null)); // Reset error
        return;
      }

      updatedCart[index]['quantity'] = newQty;
      updatedCart[index]['total'] = (newQty * updatedCart[index]['unit_price']).round();
    } else {
      if (availableStock < event.quantity) {
        emit(state.copyWith(status: SalesStatus.error, errorMessage: 'Out of stock'));
        emit(state.copyWith(status: SalesStatus.ready, errorMessage: null));
        return;
      }

      updatedCart.add({
        'id': event.product.id,
        'name_urdu': event.product.nameUrdu,
        'name_english': event.product.nameEnglish,
        'unit_name': event.product.unitType,
        'item_code': event.product.itemCode,
        'current_stock': availableStock,
        'unit_price': event.product.salePrice,
        'quantity': event.quantity,
        'total': (event.product.salePrice * event.quantity).round(),
      });
    }

    emit(state.copyWith(cartItems: updatedCart));
    _calculateTotals(emit);
  }

  void _onCartItemUpdated(CartItemUpdated event, Emitter<SalesState> emit) {
    final List<Map<String, dynamic>> updatedCart = List.from(state.cartItems);
    if (event.index >= updatedCart.length) return;

    final item = updatedCart[event.index];
    final availableStock = (item['current_stock'] as num).toDouble();
    
    double newQty = event.quantity;
    if (newQty > availableStock) {
      newQty = availableStock;
      emit(state.copyWith(status: SalesStatus.error, errorMessage: 'Stock limit reached'));
      emit(state.copyWith(status: SalesStatus.ready, errorMessage: null));
    }

    updatedCart[event.index]['quantity'] = newQty;
    updatedCart[event.index]['unit_price'] = event.price;
    updatedCart[event.index]['total'] = (event.price * newQty).round();

    emit(state.copyWith(cartItems: updatedCart));
    _calculateTotals(emit);
  }

  void _onCartItemRemoved(CartItemRemoved event, Emitter<SalesState> emit) {
    final List<Map<String, dynamic>> updatedCart = List.from(state.cartItems);
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
    ));
  }

  void _onDiscountChanged(DiscountChanged event, Emitter<SalesState> emit) {
    // Just trigger recalc, the value is parsed in _calculateTotals or passed here
    // Ideally pass the parsed value. For now, we assume the UI passes the text and we parse it.
    // But to keep state pure, let's assume the event passes the raw text and we parse it here.
    // However, _calculateTotals needs the discount value.
    // Let's store the discount in state.
    // We need to parse it.
    final money = CurrencyUtils.parse(event.discountText);
    // We can't set discount directly because it depends on subtotal (cap).
    // So we just re-run calc with this new "proposed" discount.
    // But wait, _calculateTotals uses state.discount.
    // Let's update _calculateTotals to accept an optional discount override or use a field.
    // Actually, let's just parse and set it, then clamp in _calculateTotals.
    
    // We need to store the "user entered" discount separately if we want to persist it across cart updates?
    // For simplicity, we'll just recalc.
    _calculateTotals(emit, proposedDiscount: money);
  }

  void _calculateTotals(Emitter<SalesState> emit, {Money? proposedDiscount}) {
    int subtotalPaisas = state.cartItems.fold(0, (sum, item) => sum + (item['total'] as int));
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

  Future<void> _onSaleProcessed(SaleProcessed event, Emitter<SalesState> emit) async {
    emit(state.copyWith(status: SalesStatus.loading));
    
    // Validate Stock again
    final validation = await _salesRepository.validateStock(state.cartItems);
    if (!validation['valid']) {
      emit(state.copyWith(status: SalesStatus.error, errorMessage: validation['error']));
      emit(state.copyWith(status: SalesStatus.ready, errorMessage: null));
      return;
    }

    final saleData = {
      'customer_id': state.selectedCustomer?.id,
      'grand_total_paisas': state.grandTotal.paisas,
      'discount_paisas': state.discount.paisas,
      'cash_paisas': event.cash,
      'bank_paisas': event.bank,
      'credit_paisas': event.credit,
      'receipt_language': event.languageCode,
      'items': state.cartItems.map((item) => {
        'id': item['id'],
        'name_english': item['name_english'],
        'name_urdu': item['name_urdu'],
        'unit_name': item['unit_name'],
        'quantity': item['quantity'],
        'sale_price': item['unit_price'],
        'total': item['total'],
      }).toList(),
    };

    try {
      await _salesRepository.completeSaleWithSnapshot(saleData);
      emit(state.copyWith(status: SalesStatus.success, successMessage: 'Sale Completed'));
      add(CartCleared());
      add(SalesStarted()); // Refresh data
    } catch (e) {
      emit(state.copyWith(status: SalesStatus.error, errorMessage: e.toString()));
      emit(state.copyWith(status: SalesStatus.ready, errorMessage: null));
    }
  }

  Future<void> _onSaleCancelled(SaleCancelled event, Emitter<SalesState> emit) async {
    try {
      await _salesRepository.cancelSale(
        saleId: event.saleId,
        cancelledBy: 'Cashier',
        reason: event.reason,
      );
      add(SalesStarted()); // Refresh
      emit(state.copyWith(status: SalesStatus.success, successMessage: 'Sale Cancelled'));
    } catch (e) {
      emit(state.copyWith(status: SalesStatus.error, errorMessage: e.toString()));
    }
  }
}