import '../../../models/unit_model.dart';

class UnitConverter {
  /// Convert quantity from one unit to another
  /// Example: convert(5, fromKG, toG) -> 5000
  static double convert(double qty, Unit from, Unit to) {
    if (from.category.id != to.category.id) {
      throw Exception(
          'Cannot convert between different categories: ${from.category.name} and ${to.category.name}');
    }

    if (!from.isBase && from.multiplier <= 0) {
      throw Exception(
        'Invalid multiplier for source unit "${from.name}" in category "${from.category.name}": ${from.multiplier}. Multiplier must be greater than 0.',
      );
    }

    if (!to.isBase && to.multiplier <= 0) {
      throw Exception(
        'Invalid multiplier for target unit "${to.name}" in category "${to.category.name}": ${to.multiplier}. Multiplier must be greater than 0.',
      );
    }

    // Convert to base unit first
    // Base units have multiplier 1 (relative to themselves)
    final double baseQty = from.isBase ? qty : qty * from.multiplier;

    // Convert from base to target
    return to.isBase ? baseQty : baseQty / to.multiplier;
  }

  /// Get conversion formula as string
  /// Example: getFormula(kg, g) -> "1 KG = 1000 g"
  static String getFormula(Unit unit, Unit? baseUnit) {
    if (unit.isBase) return unit.code;
    if (baseUnit == null) return unit.code;
    return '1 ${unit.code} = ${unit.multiplier} ${baseUnit.code}';
  }
}
