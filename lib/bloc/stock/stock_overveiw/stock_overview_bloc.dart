import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/repositories/stock_repository.dart';
import 'stock_overview_event.dart';
import 'stock_overview_state.dart';

class StockOverviewBloc extends Bloc<StockOverviewEvent, StockOverviewState> {
  final StockRepository _stockRepository;

  StockOverviewBloc(this._stockRepository) : super(StockOverviewInitial()) {
    on<LoadStockOverview>(_onLoadStockOverview);
    on<RefreshStockOverview>((event, emit) {
      // Re-trigger load with defaults or keep current state params if we tracked them
      add(const LoadStockOverview());
    });
  }

  Future<void> _onLoadStockOverview(
    LoadStockOverview event,
    Emitter<StockOverviewState> emit,
  ) async {
    emit(StockOverviewLoading());
    try {
      // Fetch items with filters
      final items = await _stockRepository.getStockItems(
        query: event.query,
        status: event.status,
        supplierId: event.supplierId,
        categoryId: event.categoryId,
      );

      // Fetch KPIs
      final summary = await _stockRepository.getStockSummary();

      emit(StockOverviewLoaded(
        items: items,
        summary: summary,
      ));
    } catch (e) {
      emit(StockOverviewError(e.toString()));
    }
  }
}