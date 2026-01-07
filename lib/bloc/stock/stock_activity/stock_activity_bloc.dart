import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/stock_activity_repository.dart';
import 'stock_activity_event.dart';
import 'stock_activity_state.dart';

class StockActivityBloc extends Bloc<StockActivityEvent, StockActivityState> {
  final StockActivityRepository _repository;

  StockActivityBloc(this._repository) : super(StockActivityInitial()) {
    on<LoadStockActivities>(_onLoadActivities);
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
}