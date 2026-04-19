import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/repositories/units_repository.dart';
import '../../models/unit_model.dart';
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
      
      // Group units by category
      final Map<int, List<Unit>> unitsByCategory = {};
      final Map<int, Unit?> baseUnitByCategory = {};
      
      for (var category in categories) {
        final catUnits = units.where((u) => u.category.id == category.id).toList();
        unitsByCategory[category.id] = catUnits;
        baseUnitByCategory[category.id] = catUnits.where((u) => u.isBase).firstOrNull;
      }

      emit(UnitsLoaded(
        units: units, 
        categories: categories,
        unitsByCategory: unitsByCategory,
        baseUnitByCategory: baseUnitByCategory,
      ));
    } catch (e) {
      emit(UnitsError("Failed to load units: ${e.toString()}"));
      // Double-emit pattern: re-emit previous state or initial if needed
      // Since it's initial load, we might just stay in error or emit empty loaded
      emit(const UnitsLoaded(units: [], categories: [], unitsByCategory: {}, baseUnitByCategory: {}));
    }
  }

  Future<void> _onAddCustomUnit(AddCustomUnit event, Emitter<UnitsState> emit) async {
    final currentState = state;
    try {
      await _unitsRepository.addUnit(event.unit);
      add(LoadUnits()); 
    } catch (e) {
      emit(UnitsError("Failed to add unit: ${e.toString()}"));
      if (currentState is UnitsLoaded) {
        emit(currentState); // Re-emit current state to unstick UI
      }
    }
  }

  Future<void> _onUpdateCustomUnit(UpdateCustomUnit event, Emitter<UnitsState> emit) async {
    final currentState = state;
    try {
      await _unitsRepository.updateUnit(event.unit);
      add(LoadUnits());
    } catch (e) {
      emit(UnitsError("Failed to update unit: ${e.toString()}"));
      if (currentState is UnitsLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onDeleteCustomUnit(DeleteCustomUnit event, Emitter<UnitsState> emit) async {
    final currentState = state;
    try {
      await _unitsRepository.deleteUnit(event.unitId);
      add(LoadUnits());
    } catch (e) {
      emit(UnitsError("Failed to delete unit: ${e.toString()}"));
      if (currentState is UnitsLoaded) {
        emit(currentState);
      }
    }
  }
}
