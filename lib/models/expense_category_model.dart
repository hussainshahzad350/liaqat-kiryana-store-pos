class ExpenseCategory {
  final int? id;
  final String nameEnglish;
  final String? nameUrdu;
  final DateTime? createdAt;

  ExpenseCategory({
    this.id,
    required this.nameEnglish,
    this.nameUrdu,
    this.createdAt,
  });

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as int?,
      nameEnglish: map['name_english'] as String? ?? '',
      nameUrdu: map['name_urdu'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_english': nameEnglish,
      'name_urdu': nameUrdu,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
