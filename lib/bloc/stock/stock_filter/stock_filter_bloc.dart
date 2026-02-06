import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/suppliers_repository.dart';
import '../../../core/repositories/categories_repository.dart';
import 'stock_filter_event.dart';
import 'stock_filter_state.dart';

class StockFilterBloc extends Bloc<StockFilterEvent, StockFilterState> {
  final SuppliersRepository _suppliersRepository;
  final CategoriesRepository _categoriesRepository;
  int _searchSequence = 0;

  StockFilterBloc(this._suppliersRepository, this._categoriesRepository) : super(const StockFilterState()) {
    on<LoadFilters>(_onLoadFilters);
    on<SetSearchQuery>(
      (event, emit) async {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!isClosed) {
          emit(state.copyWith(searchQuery: event.query));
        }
      },
      transformer: restartable(),
    );
    on<SetSearchQuery>(_onSetSearchQuery);
    on<SetStatusFilter>((event, emit) {
      emit(state.copyWith(statusFilter: event.status));
    });
    on<SetSupplierFilter>((event, emit) {
      if (event.supplierId == null) {
        emit(state.clearSupplier());
      } else {
        emit(state.copyWith(selectedSupplierId: event.supplierId));
      }
    });
    on<SetCategoryFilter>((event, emit) {
      if (event.categoryId == null) {
        emit(state.clearCategory());
      } else {
        emit(state.copyWith(selectedCategoryId: event.categoryId));
      }
    });
    on<ResetFilters>((event, emit) {
      emit(state.copyWith(searchQuery: '', statusFilter: 'ALL').clearSupplier().clearCategory());
    });
  }

  Future<void> _onSetSearchQuery(
    SetSearchQuery event,
    Emitter<StockFilterState> emit,
  ) async {
    _searchSequence++;
    final currentSequence = _searchSequence;
    await Future.delayed(const Duration(milliseconds: 300));
    if (currentSequence != _searchSequence) return;
    if (isClosed) return;
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onLoadFilters(
    LoadFilters event,
    Emitter<StockFilterState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final suppliers = await _suppliersRepository.getSuppliers();
      final categories = await _categoriesRepository.getAllCategories();
      emit(state.copyWith(
        availableSuppliers: suppliers,
        availableCategories: categories.map((c) => c.toMap()).toList(),
        isLoading: false,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
