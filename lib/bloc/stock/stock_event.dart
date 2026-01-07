import 'package:equatable/equatable.dart';

abstract class StockEvent extends Equatable {
  const StockEvent();

  @override
  List<Object> get props => [];
}

class LoadStock extends StockEvent {}

class SearchStock extends StockEvent {
  final String query;

  const SearchStock(this.query);

  @override
  List<Object> get props => [query];
}