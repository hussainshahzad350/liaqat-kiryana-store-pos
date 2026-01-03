class Department {
  final int? id;
  final String nameEn;
  final String nameUr;
  final bool isActive;
  final bool isVisibleInPOS;

  Department({this.id, required this.nameEn, this.nameUr = '', this.isActive = true, this.isVisibleInPOS = true});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_english': nameEn,
      'name_urdu': nameUr,
      'is_active': isActive ? 1 : 0,
      'is_visible_in_pos': isVisibleInPOS ? 1 : 0,
    };
  }

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'],
      nameEn: map['name_english'] ?? '',
      nameUr: map['name_urdu'] ?? '',
      isActive: (map['is_active'] ?? 1) == 1,
      isVisibleInPOS: (map['is_visible_in_pos'] ?? 1) == 1,
    );
  }
}

class Category {
  final int? id;
  final int? departmentId;
  final String nameEn;
  final String nameUr;
  final bool isActive;
  final bool isVisibleInPOS;

  Category({this.id, this.departmentId, required this.nameEn, this.nameUr = '', this.isActive = true, this.isVisibleInPOS = true});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'department_id': departmentId,
      'name_english': nameEn,
      'name_urdu': nameUr,
      'is_active': isActive ? 1 : 0,
      'is_visible_in_pos': isVisibleInPOS ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      departmentId: map['department_id'],
      nameEn: map['name_english'] ?? '',
      nameUr: map['name_urdu'] ?? '',
      isActive: (map['is_active'] ?? 1) == 1,
      isVisibleInPOS: (map['is_visible_in_pos'] ?? 1) == 1,
    );
  }
}

class SubCategory {
  final int? id;
  final int categoryId;
  final String nameEn;
  final String nameUr;
  final bool isActive;
  final bool isVisibleInPOS;

  SubCategory({this.id, required this.categoryId, required this.nameEn, this.nameUr = '', this.isActive = true, this.isVisibleInPOS = true});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name_english': nameEn,
      'name_urdu': nameUr,
      'is_active': isActive ? 1 : 0,
      'is_visible_in_pos': isVisibleInPOS ? 1 : 0,
    };
  }

  factory SubCategory.fromMap(Map<String, dynamic> map) {
    return SubCategory(
      id: map['id'],
      categoryId: map['category_id'] ?? 0,
      nameEn: map['name_english'] ?? '',
      nameUr: map['name_urdu'] ?? '',
      isActive: (map['is_active'] ?? 1) == 1,
      isVisibleInPOS: (map['is_visible_in_pos'] ?? 1) == 1,
    );
  }
}
