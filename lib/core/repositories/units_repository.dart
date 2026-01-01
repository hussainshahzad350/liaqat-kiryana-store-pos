import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../../models/unit_model.dart';

class UnitsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Permanent System Unit Categories
  final List<UnitCategory> _systemCategories = const [
    UnitCategory(id: 1, name: 'Length', isSystem: true),
    UnitCategory(id: 2, name: 'Weight', isSystem: true),
    UnitCategory(id: 3, name: 'Count', isSystem: true),
    UnitCategory(id: 4, name: 'Volume', isSystem: true),
  ];

  Future<List<Unit>> getUnits() async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'units',
      where: 'is_active = 1',
      orderBy: '''
        category_id ASC,
        CASE WHEN base_unit_id IS NULL THEN 0 ELSE 1 END ASC,
        name ASC
      '''
    );

    return List.generate(maps.length, (i) {
      final catId = maps[i]['category_id'];
      final category = _systemCategories.firstWhere(
        (c) => c.id == catId,
        orElse: () => UnitCategory(id: catId, name: 'Unknown'),
      );
      return Unit.fromMap(maps[i], category);
    });
  }

  Future<List<UnitCategory>> getCategories() async {
    return _systemCategories;
  }

  Future<int> addUnit(Unit unit) async {
    final db = await _dbHelper.database;
    return await db.insert('units', unit.toMap());
  }

  Future<int> updateUnit(Unit unit) async {
    final db = await _dbHelper.database;
    if (unit.isSystem) {
      throw Exception("System units cannot be edited.");
    }
    var map = unit.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'units',
      map,
      where: 'id = ?',
      whereArgs: [unit.id],
    );
  }

  Future<void> deleteUnit(int id) async {
    final db = await _dbHelper.database;

    // 1. Check if System Unit
    final unitRes = await db.query('units', columns: ['is_system', 'code'], where: 'id = ?', whereArgs: [id]);
    if (unitRes.isEmpty) return;

    if (unitRes.first['is_system'] == 1) {
      throw Exception("System units cannot be deleted.");
    }

    final String unitCode = unitRes.first['code'] as String;

    // 2. Check Usage in Products
    final productCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM products WHERE unit_type = ?',
      [unitCode],
    ));

    // 3. Check Usage in Sale Items (Historical)
    // Note: sale_items usually stores unit_name, but if we linked by ID we'd check here.
    // Assuming we might have a unit_id column or we want to be safe if products used it.
    // If products used it, it's likely in sales history via product snapshot or direct link.
    
    // 4. Check if used as Base Unit for other units
    final childUnitCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM units WHERE base_unit_id = ? AND is_active = 1',
      [id],
    ));

    if ((productCount != null && productCount > 0) || (childUnitCount != null && childUnitCount > 0)) {
      // Soft Delete
      await db.update(
        'units',
        {
          'is_active': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      // Hard Delete
      await db.delete(
        'units',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<bool> isCodeUnique(String code, {int? excludeId}) async {
    final db = await _dbHelper.database;
    final where = excludeId != null ? 'code = ? AND id != ?' : 'code = ?';
    final args = excludeId != null ? [code, excludeId] : [code];
    
    final count = Sqflite.firstIntValue(await db.query('units', columns: ['COUNT(*)'], where: where, whereArgs: args));
    return count == 0;
  }
}