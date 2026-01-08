import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/purchase_repository.dart';
import '../../../core/repositories/suppliers_repository.dart';
import '../../../core/repositories/items_repository.dart';
import '../../../core/entity/purchase_bill_entity.dart';
import 'purchase_event.dart';
import 'purchase_state.dart';

class PurchaseBloc extends Bloc<PurchaseEvent, PurchaseState> {
  final PurchaseRepository _purchaseRepository;
  final SuppliersRepository _suppliersRepository;
  final ItemsRepository _itemsRepository;

  PurchaseBloc({
    required PurchaseRepository purchaseRepository,
    required SuppliersRepository suppliersRepository,
    required ItemsRepository itemsRepository,
  })  : _purchaseRepository = purchaseRepository,
        _suppliersRepository = suppliersRepository,
        _itemsRepository = itemsRepository,
        super(const PurchaseState()) {
    on<InitializePurchase>(_onInitialize);
    on<SelectPurchaseSupplier>((event, emit) {
      emit(state.copyWith(selectedSupplierId: event.supplierId));
    });
    on<AddPurchaseItem>((event, emit) {
      final updatedCart = List<PurchaseItemEntity>.from(state.cartItems)..add(event.item);
      emit(state.copyWith(cartItems: updatedCart));
    });
    on<RemovePurchaseItem>((event, emit) {
      final updatedCart = List<PurchaseItemEntity>.from(state.cartItems)..removeAt(event.index);
      emit(state.copyWith(cartItems: updatedCart));
    });
    on<UpdatePurchaseItem>((event, emit) {
      final updatedCart = List<PurchaseItemEntity>.from(state.cartItems);
      updatedCart[event.index] = event.item;
      emit(state.copyWith(cartItems: updatedCart));
    });
    on<SubmitPurchase>(_onSubmit);
  }

  Future<void> _onInitialize(InitializePurchase event, Emitter<PurchaseState> emit) async {
    emit(state.copyWith(status: PurchaseStatus.loading));
    try {
      final suppliers = await _suppliersRepository.getSuppliers();
      final products = await _itemsRepository.getAllProducts();
      emit(state.copyWith(
        status: PurchaseStatus.ready,
        suppliers: suppliers,
        products: products,
      ));
    } catch (e) {
      emit(state.copyWith(status: PurchaseStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onSubmit(SubmitPurchase event, Emitter<PurchaseState> emit) async {
    if (state.selectedSupplierId == null) {
      emit(state.copyWith(error: 'Please select a supplier'));
      return;
    }
    if (state.cartItems.isEmpty) {
      emit(state.copyWith(error: 'Cart is empty'));
      return;
    }

    emit(state.copyWith(status: PurchaseStatus.submitting));

    try {
      final purchaseData = {
        'supplier_id': state.selectedSupplierId,
        'invoice_number': event.invoiceNumber,
        'purchase_date': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        'total_amount': state.totalAmount.paisas,
        'notes': event.notes,
        'items': state.cartItems.map((item) => {
          'product_id': item.productId,
          'quantity': item.quantity,
          'cost_price': item.costPrice.paisas,
          'total_amount': item.totalAmount.paisas,
          'batch_number': item.batchNumber,
          'expiry_date': item.expiryDate,
        }).toList(),
      };

      await _purchaseRepository.createPurchase(purchaseData);
      emit(state.copyWith(status: PurchaseStatus.success));
    } catch (e) {
      emit(state.copyWith(status: PurchaseStatus.failure, error: e.toString()));
    }
  }
}