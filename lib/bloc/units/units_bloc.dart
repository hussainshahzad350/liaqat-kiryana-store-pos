import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/repositories/units_repository.dart';
import 'units_event.dart';
import 'units_state.dart';

class UnitsBloc extends Bloc<UnitsEvent, UnitsState> {
  final UnitsRepository _unitsRepository;

  UnitsBloc(this._unitsRepository) : super(UnitsInitial()) {
    on<LoadUnits>(_onLoadUnits);
    on<AddCustomUnit>(_onAddCustomUnit);
    on<UpdateCustomUnit>(_onUpdateCustomUnit);
    on<DeleteCustomUnit>(_onDeleteCustomUnit);
  }

  Future<void> _onLoadUnits(LoadUnits event, Emitter<UnitsState> emit) async {
    emit(UnitsLoading());
    try {
      final units = await _unitsRepository.getUnits();
      final categories = await _unitsRepository.getCategories();
      emit(UnitsLoaded(units: units, categories: categories));
    } catch (e) {
      emit(UnitsError("Failed to load units: ${e.toString()}"));
    }
  }

  Future<void> _onAddCustomUnit(AddCustomUnit event, Emitter<UnitsState> emit) async {
    if (state is UnitsLoaded) {
      try {
        await _unitsRepository.addUnit(event.unit);
        add(LoadUnits()); // Reload to get updated list with IDs
      } catch (e) {
        emit(UnitsError("Failed to add unit: ${e.toString()}"));
        add(LoadUnits()); // Restore state
      }
    }
  }

  Future<void> _onUpdateCustomUnit(UpdateCustomUnit event, Emitter<UnitsState> emit) async {
    if (state is UnitsLoaded) {
      try {
        await _unitsRepository.updateUnit(event.unit);
        add(LoadUnits());
      } catch (e) {
        emit(UnitsError("Failed to update unit: ${e.toString()}"));
        add(LoadUnits());
      }
    }
  }

  Future<void> _onDeleteCustomUnit(DeleteCustomUnit event, Emitter<UnitsState> emit) async {
    if (state is UnitsLoaded) {
      try {
        await _unitsRepository.deleteUnit(event.unitId);
        add(LoadUnits());
      } catch (e) {
        emit(UnitsError("Failed to delete unit: ${e.toString()}"));
        add(LoadUnits());
      }
    }
  }
}