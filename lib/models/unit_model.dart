class UnitCategory {
  final int id;
  final String name;
  final bool isSystem;

  const UnitCategory({
    required this.id,
    required this.name,
    this.isSystem = false,
  });

  factory UnitCategory.fromMap(Map<String, dynamic> map) {
    return UnitCategory(
      id: map['id'],
      name: map['name'],
      isSystem: map['is_system'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_system': isSystem ? 1 : 0,
    };
  }
}

class Unit {
  final int id;
  final String name;
  final String code;
  final UnitCategory category;
  final bool isSystem;
  final int? baseUnitId;
  final int multiplier;
  final bool isActive;

  const Unit({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    this.isSystem = false,
    this.baseUnitId,
    this.multiplier = 1,
    this.isActive = true,
  });

  bool get isBase => baseUnitId == null;

  factory Unit.fromMap(Map<String, dynamic> map, UnitCategory category) {
    return Unit(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      category: category,
      isSystem: map['is_system'] == 1,
      baseUnitId: map['base_unit_id'],
      multiplier: map['multiplier'],
      isActive: map['is_active'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'category_id': category.id,
      'is_system': isSystem ? 1 : 0,
      'base_unit_id': baseUnitId,
      'multiplier': multiplier,
      'is_active': isActive ? 1 : 0,
    };
  }

  Unit copyWith({
    String? name,
    String? code,
    UnitCategory? category,
    bool? isActive,
  }) {
    return Unit(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      isSystem: isSystem,
      baseUnitId: baseUnitId,
      multiplier: multiplier,
      isActive: isActive ?? this.isActive,
    );
  }
}