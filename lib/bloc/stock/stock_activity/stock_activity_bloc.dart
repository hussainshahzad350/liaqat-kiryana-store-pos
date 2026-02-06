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
  final Map<String, DateTime> _recentActionByKey = <String, DateTime>{};

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
        emit(StockActivityActionError(e.toString()));
      }
    }
  }

  Future<void> _onAdjustStock(
    AdjustStock event,
    Emitter<StockActivityState> emit,
  ) async {
    final dedupeKey = 'ADJUST:${event.productId}:${event.quantityChange}:${event.reason}';
    if (_isRapidDuplicate(dedupeKey)) {
      emit(StockActivityActionError('Duplicate stock adjustment request blocked'));
      return;
    }

    try {
      await _itemsRepository.adjustStock(
        event.productId,
        event.quantityChange,
        reason: event.reason,
        reference: event.reference,
      );
      emit(StockActivityActionSuccess('Stock adjustment submitted'));
      add(LoadStockActivities());
    } catch (e) {
      emit(StockActivityActionError(e.toString()));
    }
  }

  Future<void> _onCancelActivity(
    CancelStockActivity event,
    Emitter<StockActivityState> emit,
  ) async {
    if (event.activity.status != 'COMPLETED') {
      emit(StockActivityActionError('Only completed activities can be cancelled'));
      return;
    }

    if (event.activity.type != ActivityType.purchase && event.activity.type != ActivityType.sale) {
      emit(StockActivityActionError('Only sale and purchase activities are cancellable'));
      return;
    }

    if (event.activity.referenceId == null) {
      emit(StockActivityActionError('Invalid reference ID'));
      return;
    }

    final dedupeKey = 'CANCEL:${event.activity.id}';
    if (_isRapidDuplicate(dedupeKey)) {
      emit(StockActivityActionError('Duplicate cancellation request blocked'));
      return;
    }

    try {
      if (event.activity.type == ActivityType.purchase) {
        await _purchaseRepository.cancelPurchase(
          purchaseId: event.activity.referenceId!,
          cancelledBy: event.activity.user,
          reason: event.reason,
        );
      } else if (event.activity.type == ActivityType.sale) {
        await _invoiceRepository.cancelInvoice(
          invoiceId: event.activity.referenceId!,
          cancelledBy: event.activity.user,
          reason: event.reason,
        );
      }
      emit(StockActivityActionSuccess('Transaction cancelled successfully'));
      add(LoadStockActivities());
    } catch (e) {
      emit(StockActivityActionError(e.toString()));
    }
  }

  bool _isRapidDuplicate(String key) {
    final now = DateTime.now();
    final previous = _recentActionByKey[key];
    _recentActionByKey[key] = now;
    if (previous == null) return false;
    return now.difference(previous) < const Duration(seconds: 2);
  }

}
