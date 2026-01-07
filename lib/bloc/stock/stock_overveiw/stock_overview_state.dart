import 'package:flutter/foundation.dart';
import '../../../core/entity/stock_item_entity.dart';
import '../../../core/entity/stock_summary_entity.dart';

@immutable
abstract class StockOverviewState {}

class StockOverviewInitial extends StockOverviewState {}

class StockOverviewLoading extends StockOverviewState {}

class StockOverviewLoaded extends StockOverviewState {
  final List<StockItemEntity> items;
  final StockSummaryEntity summary;

  StockOverviewLoaded({required this.items, required this.summary});
}

class StockOverviewError extends StockOverviewState {
  final String message;
  StockOverviewError(this.message);
}