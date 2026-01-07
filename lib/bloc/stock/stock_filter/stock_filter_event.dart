import 'package:flutter/foundation.dart';

@immutable
abstract class StockFilterEvent {}

class LoadFilters extends StockFilterEvent {}

class SetSearchQuery extends StockFilterEvent {
  final String query;
  SetSearchQuery(this.query);
}

class SetStatusFilter extends StockFilterEvent {
  final String status; // 'ALL', 'LOW', 'OUT', 'EXPIRED', 'OLD'
  SetStatusFilter(this.status);
}

class SetSupplierFilter extends StockFilterEvent {
  final int? supplierId;
  SetSupplierFilter(this.supplierId);
}

class SetCategoryFilter extends StockFilterEvent {
  final int? categoryId;
  SetCategoryFilter(this.categoryId);
}

class ResetFilters extends StockFilterEvent {}
