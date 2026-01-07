import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/repositories/items_repository.dart';
import 'stock_event.dart';
import 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final ItemsRepository _itemsRepository;

  StockBloc({required ItemsRepository itemsRepository})
      : _itemsRepository = itemsRepository,
        super(const StockState()) {
    on<LoadStock>(_onLoadStock);
    on<SearchStock>(_onSearchStock);
  }

  Future<void> _onLoadStock(LoadStock event, Emitter<StockState> emit) async {
    emit(state.copyWith(status: StockStatus.loading));
    try {
      final products = await _itemsRepository.getAllProducts();
      emit(state.copyWith(
        status: StockStatus.loaded,
        stock: products,
        filteredStock: products,
      ));
    } catch (e) {
      emit(state.copyWith(status: StockStatus.error, errorMessage: e.toString()));
    }
  }

  void _onSearchStock(SearchStock event, Emitter<StockState> emit) {
    final query = event.query.toLowerCase();
    if (query.isEmpty) {
      emit(state.copyWith(filteredStock: state.stock));
    } else {
      final filtered = state.stock.where((product) {
        final nameLower = product.nameEnglish.toLowerCase();
        final codeLower = (product.itemCode ?? '').toLowerCase();
        return nameLower.contains(query) || codeLower.contains(query);
      }).toList();
      emit(state.copyWith(filteredStock: filtered));
    }
  }
}