import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/stock_activity_repository.dart';
import '../../../core/repositories/items_repository.dart';
import '../../../core/repositories/purchase_repository.dart';
import '../../../core/repositories/invoice_repository.dart';
import '../../../core/entity/stock_activity_entity.dart';
import 'stock_activity_event.dart';
import 'stock_activity_state.dart';

class StockActivityBloc extends Bloc<StockActivityEvent, StockActivityState> {
  final StockActivityRepository _repository;
  final ItemsRepository _itemsRepository;
  final PurchaseRepository _purchaseRepository;
  final InvoiceRepository _invoiceRepository;

  StockActivityBloc(
    this._repository,
    this._itemsRepository,
    this._purchaseRepository,
    this._invoiceRepository,
  ) : super(StockActivityInitial()) {
    on<LoadStockActivities>(_onLoadActivities);
    on<AdjustStock>(_onAdjustStock);
    on<CancelStockActivity>(_onCancelActivity);
    on<LoadMoreStockActivities>(_onLoadMoreActivities);
  }

  Future<void> _onLoadActivities(
    LoadStockActivities event,
    Emitter<StockActivityState> emit,
  ) async {
    emit(StockActivityLoading());
    try {
      final activities = await _repository.getActivities(limit: 20, offset: 0);
      emit(StockActivityLoaded(
        activities: activities,
        hasReachedMax: activities.length < 20,
      ));
    } catch (e) {
      emit(StockActivityError(e.toString()));
    }
  }

  Future<void> _onLoadMoreActivities(
    LoadMoreStockActivities event,
    Emitter<StockActivityState> emit,
  ) async {
    final currentState = state;
    if (currentState is StockActivityLoaded && !currentState.hasReachedMax) {
      try {
        final currentActivities = currentState.activities;
        final moreActivities = await _repository.getActivities(limit: 20, offset: currentActivities.length);
        emit(StockActivityLoaded(
          activities: currentActivities + moreActivities,
          hasReachedMax: moreActivities.length < 20,
        ));
      } catch (e) {
        // Fail silently or emit error, keeping existing data
      }
    }
  }

  Future<void> _onAdjustStock(
    AdjustStock event,
    Emitter<StockActivityState> emit,
  ) async {
    // We don't emit loading here to avoid replacing the list with a spinner.
    // Instead, we perform the action and then reload.
    try {
      await _itemsRepository.adjustStock(
        event.productId,
        event.quantityChange,
        reason: event.reason,
        reference: event.reference,
      );
      add(LoadStockActivities());
    } catch (e) {
      emit(StockActivityError(e.toString()));
    }
  }

  Future<void> _onCancelActivity(
    CancelStockActivity event,
    Emitter<StockActivityState> emit,
  ) async {
    try {
      if (event.activity.type == ActivityType.purchase) {
        if (event.activity.referenceId != null) {
          await _purchaseRepository.cancelPurchase(
            event.activity.referenceId!,
            reason: event.reason,
          );
        } else {
          throw Exception('Invalid reference ID for purchase');
        }
      } else if (event.activity.type == ActivityType.sale) {
        if (event.activity.referenceId != null) {
          await _invoiceRepository.cancelInvoice(
            invoiceId: event.activity.referenceId!,
            cancelledBy: event.activity.user,
            reason: event.reason,
          );
        } else {
          throw Exception('Invalid reference ID for sale');
        }
      }
      add(LoadStockActivities());
    } catch (e) {
      emit(StockActivityError(e.toString()));
    }
  }
}
