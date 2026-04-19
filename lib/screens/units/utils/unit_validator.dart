import '../../../models/unit_model.dart';

class UnitValidator {
  /// Rule: Each category must have exactly one base unit
  static String? validateBaseUnit(UnitCategory cat, List<Unit> units) {
    final baseUnits = units
        .where((u) => u.category.id == cat.id)
        .where((u) => u.isBase)
        .toList();

    if (baseUnits.isEmpty) {
      return 'Category "${cat.name}" has no base unit. Add one first.';
    }
    if (baseUnits.length > 1) {
      return 'Category "${cat.name}" has multiple base units. Only one allowed.';
    }
    return null; // Valid
  }

  /// Rule: Derived units must reference an existing base in the same category
  static String? validateDerivedUnit(Unit unit, List<Unit> allUnits) {
    if (unit.isBase) return null;

    if (unit.baseUnitId == null) {
      return 'Derived unit must reference a base unit';
    }

    try {
      final base = allUnits.firstWhere(
        (u) => u.id == unit.baseUnitId,
      );

      if (base.category.id != unit.category.id) {
        return 'Base unit must be in the same category';
      }
      if (!base.isBase) {
        return 'Referenced unit must be a base unit';
      }
    } catch (_) {
      return 'Base unit not found';
    }
    return null;
  }

  static int? parsePositiveWholeMultiplier(String rawValue) {
    final parsed = double.tryParse(rawValue.trim());
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return null;
    }
    if (parsed % 1 != 0) {
      return null;
    }
    return parsed.toInt();
  }

  static String? validatePositiveWholeMultiplier(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return 'Must be > 0';
    if (parsed % 1 != 0) return 'Must be a whole number';
    return null;
  }
}
