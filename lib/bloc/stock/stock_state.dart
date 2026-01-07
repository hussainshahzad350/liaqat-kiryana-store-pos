import 'package:equatable/equatable.dart';
import '../../models/product_model.dart';

enum StockStatus { initial, loading, loaded, error }

class StockState extends Equatable {
  const StockState({
    this.status = StockStatus.initial,
    this.stock = const [],
    this.filteredStock = const [],
    this.errorMessage,
  });

  final StockStatus status;
  final List<Product> stock;
  final List<Product> filteredStock;
  final String? errorMessage;

  StockState copyWith({
    StockStatus? status,
    List<Product>? stock,
    List<Product>? filteredStock,
    String? errorMessage,
  }) {
    return StockState(
      status: status ?? this.status,
      stock: stock ?? this.stock,
      filteredStock: filteredStock ?? this.filteredStock,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, stock, filteredStock, errorMessage];
}
