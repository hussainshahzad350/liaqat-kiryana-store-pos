import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class StockOverviewEvent extends Equatable {
  const StockOverviewEvent();
  @override
  List<Object?> get props => [];
}

class LoadStockOverview extends StockOverviewEvent {
  final String? query;
  final String? status; // 'ALL', 'LOW', 'OUT'
  final int? supplierId;
  final int? categoryId;

  const LoadStockOverview({this.query, this.status, this.supplierId, this.categoryId});

  @override
  List<Object?> get props => [query, status, supplierId, categoryId];
}

class LoadMoreStockOverview extends StockOverviewEvent {}

class RefreshStockOverview extends StockOverviewEvent {}