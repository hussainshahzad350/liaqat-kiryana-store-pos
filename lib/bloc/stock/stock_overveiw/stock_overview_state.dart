import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import '../../../core/entity/stock_item_entity.dart';
import '../../../core/entity/stock_summary_entity.dart';

@immutable
abstract class StockOverviewState extends Equatable {
  const StockOverviewState();
  @override
  List<Object?> get props => [];
}

class StockOverviewInitial extends StockOverviewState {}

class StockOverviewLoading extends StockOverviewState {}

class StockOverviewLoaded extends StockOverviewState {
  final List<StockItemEntity> items;
  final StockSummaryEntity summary;
  final bool hasReachedMax;

  const StockOverviewLoaded({
    required this.items,
    required this.summary,
    this.hasReachedMax = false,
  });

  StockOverviewLoaded copyWith({
    List<StockItemEntity>? items,
    StockSummaryEntity? summary,
    bool? hasReachedMax,
  }) {
    return StockOverviewLoaded(
      items: items ?? this.items,
      summary: summary ?? this.summary,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [items, summary, hasReachedMax];
}

class StockOverviewError extends StockOverviewState {
  final String message;
  const StockOverviewError(this.message);
  @override
  List<Object?> get props => [message];
}