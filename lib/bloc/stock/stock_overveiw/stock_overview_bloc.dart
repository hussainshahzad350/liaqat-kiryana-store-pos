import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/repositories/stock_repository.dart';
import '../../../../bloc/stock/stock_overveiw/stock_overview_event.dart';
import '../../../../bloc/stock/stock_overveiw/stock_overview_state.dart';

class StockOverviewBloc extends Bloc<StockOverviewEvent, StockOverviewState> {
  final StockRepository _stockRepository;

  // Track current filters for pagination
  String? _currentQuery;
  String? _currentStatus;
  int? _currentSupplierId;
  int? _currentCategoryId;

  StockOverviewBloc(this._stockRepository) : super(StockOverviewInitial()) {
    on<LoadStockOverview>(_onLoadStockOverview);
    on<LoadMoreStockOverview>(_onLoadMoreStockOverview);
    on<RefreshStockOverview>((event, emit) {
      add(LoadStockOverview(query: _currentQuery, status: _currentStatus, supplierId: _currentSupplierId, categoryId: _currentCategoryId));
    });
  }

  Future<void> _onLoadStockOverview(
    LoadStockOverview event,
    Emitter<StockOverviewState> emit,
  ) async {
    // Update current filters
    _currentQuery = event.query;
    _currentStatus = event.status;
    _currentSupplierId = event.supplierId;
    _currentCategoryId = event.categoryId;

    emit(StockOverviewLoading());
    try {
      // Fetch items with filters
      final items = await _stockRepository.getStockItems(
        query: event.query,
        status: event.status,
        supplierId: event.supplierId,
        categoryId: event.categoryId,
        offset: 0,
      );

      // Fetch KPIs
      final summary = await _stockRepository.getStockSummary();

      emit(StockOverviewLoaded(
        items: items,
        summary: summary,
        hasReachedMax: items.length < 100, // Assuming default limit is 100 in Repo
      ));
    } catch (e) {
      emit(StockOverviewError(e.toString()));
    }
  }

  Future<void> _onLoadMoreStockOverview(
    LoadMoreStockOverview event,
    Emitter<StockOverviewState> emit,
  ) async {
    final currentState = state;
    if (currentState is StockOverviewLoaded && !currentState.hasReachedMax) {
      try {
        final moreItems = await _stockRepository.getStockItems(
          query: _currentQuery,
          status: _currentStatus,
          supplierId: _currentSupplierId,
          categoryId: _currentCategoryId,
          offset: currentState.items.length,
        );

        emit(currentState.copyWith(
          items: currentState.items + moreItems,
          hasReachedMax: moreItems.isEmpty,
        ));
      } catch (e) {
        // Ignore error on pagination or handle gracefully
      }
    }
  }
}