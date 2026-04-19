import 'package:equatable/equatable.dart';
import '../../../models/unit_model.dart';

abstract class UnitsState extends Equatable {
  const UnitsState();
  
  @override
  List<Object?> get props => [];
}

class UnitsInitial extends UnitsState {}

class UnitsLoading extends UnitsState {}

class UnitsLoaded extends UnitsState {
  final List<Unit> units;
  final List<UnitCategory> categories;
  final Map<int, List<Unit>> unitsByCategory;
  final Map<int, Unit?> baseUnitByCategory;

  const UnitsLoaded({
    required this.units,
    required this.categories,
    required this.unitsByCategory,
    required this.baseUnitByCategory,
  });

  bool hasBaseUnit(int categoryId) => baseUnitByCategory[categoryId] != null;

  @override
  List<Object?> get props => [units, categories, unitsByCategory, baseUnitByCategory];
}

class UnitsError extends UnitsState {
  final String message;
  const UnitsError(this.message);
  @override
  List<Object?> get props => [message];
}
