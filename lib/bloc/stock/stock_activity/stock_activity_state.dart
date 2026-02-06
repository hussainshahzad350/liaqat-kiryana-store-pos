import 'package:flutter/foundation.dart';
import '../../../core/entity/stock_activity_entity.dart';

@immutable
abstract class StockActivityState {}

class StockActivityInitial extends StockActivityState {}

class StockActivityLoading extends StockActivityState {}

class StockActivityLoaded extends StockActivityState {
  final List<StockActivityEntity> activities;
  final bool hasReachedMax;

  StockActivityLoaded({
    required this.activities,
    this.hasReachedMax = false,
  });
}

class StockActivityError extends StockActivityState {
  final String message;
  StockActivityError(this.message);
}

class StockActivityActionSuccess extends StockActivityState {
  final String message;
  StockActivityActionSuccess(this.message);
}

class StockActivityActionError extends StockActivityState {
  final String message;
  StockActivityActionError(this.message);
}
