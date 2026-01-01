import 'package:equatable/equatable.dart';
import '../../../models/unit_model.dart';

abstract class UnitsEvent extends Equatable {
  const UnitsEvent();

  @override
  List<Object?> get props => [];
}

class LoadUnits extends UnitsEvent {}

class AddCustomUnit extends UnitsEvent {
  final Unit unit;
  const AddCustomUnit(this.unit);
  @override
  List<Object?> get props => [unit];
}

class UpdateCustomUnit extends UnitsEvent {
  final Unit unit;
  const UpdateCustomUnit(this.unit);
  @override
  List<Object?> get props => [unit];
}

class DeleteCustomUnit extends UnitsEvent {
  final int unitId;
  const DeleteCustomUnit(this.unitId);
  @override
  List<Object?> get props => [unitId];
}