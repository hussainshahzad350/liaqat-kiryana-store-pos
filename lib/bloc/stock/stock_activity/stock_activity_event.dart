import 'package:flutter/foundation.dart';

@immutable
abstract class StockActivityEvent {}

class LoadStockActivities extends StockActivityEvent {}
class LoadMoreStockActivities extends StockActivityEvent {}