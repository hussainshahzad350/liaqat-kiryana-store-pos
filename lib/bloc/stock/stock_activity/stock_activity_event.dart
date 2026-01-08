import 'package:flutter/foundation.dart';
import '../../../core/entity/stock_activity_entity.dart';

@immutable
abstract class StockActivityEvent {}

class LoadStockActivities extends StockActivityEvent {}
class LoadMoreStockActivities extends StockActivityEvent {}

class AdjustStock extends StockActivityEvent {
  final int productId;
  final double quantityChange;
  final String reason;
  final String? reference;

  AdjustStock({required this.productId, required this.quantityChange, required this.reason, this.reference});
}

class CancelStockActivity extends StockActivityEvent {
  final StockActivityEntity activity;
  final String reason;

  CancelStockActivity({required this.activity, required this.reason});
}