import 'package:equatable/equatable.dart';
import '../../../core/entity/stock_activity_entity.dart';

abstract class StockActivityEvent extends Equatable {
  const StockActivityEvent();

  @override
  List<Object?> get props => [];
}

class LoadStockActivities extends StockActivityEvent {
  const LoadStockActivities();
}

class LoadMoreStockActivities extends StockActivityEvent {
  const LoadMoreStockActivities();
}

class AdjustStock extends StockActivityEvent {
  final int productId;
  final double quantityChange;
  final String reason;
  final String? reference;
  final String? performedBy;

  const AdjustStock({
    required this.productId,
    required this.quantityChange,
    required this.reason,
    this.reference,
    this.performedBy,
  });

  @override
  List<Object?> get props => [productId, quantityChange, reason, reference, performedBy];
}

class CancelStockActivity extends StockActivityEvent {
  final StockActivityEntity activity;
  final String reason;

  const CancelStockActivity({required this.activity, required this.reason});

  @override
  List<Object?> get props => [activity, reason];
}
