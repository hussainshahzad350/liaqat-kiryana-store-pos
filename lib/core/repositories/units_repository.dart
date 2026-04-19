import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../../models/unit_model.dart';

class UnitsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Permanent System Unit Categories (Synced with DB IDs in DatabaseHelper)
  final List<UnitCategory> _systemCategories = const [
    UnitCategory(id: 1, name: 'Weight', isSystem: true),
    UnitCategory(id: 2, name: 'Volume', isSystem: true),
    UnitCategory(id: 3, name: 'Count', isSystem: true),
    UnitCategory(id: 4, name: 'Length', isSystem: true),
  ];

  Future<List<Unit>> getUnits() async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps =
        await db.query('units', where: 'is_active = 1', orderBy: '''
        category_id ASC,
        CASE WHEN base_unit_id IS NULL THEN 0 ELSE 1 END ASC,
        name ASC
      ''');

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
    final map = unit.toMap();
    return await db.update(
      'units',
      map,
      where: 'id = ?',
      whereArgs: [unit.id],
    );
  }

  Future<int> checkUsage(int unitId) async {
    final db = await _dbHelper.database;

    final unitRes = await db.query(
      'units',
      columns: ['code'],
      where: 'id = ?',
      whereArgs: [unitId],
      limit: 1,
    );
    final legacyCode =
        unitRes.isNotEmpty ? unitRes.first['code'] as String? : null;

    // 1. Check Usage in Products (using unit_id)
    final productCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM products WHERE unit_id = ?',
      [unitId],
    ));

    // 2. Check legacy Usage in Products (using unit_type code)
    final legacyProductCount = (legacyCode != null && legacyCode.isNotEmpty)
        ? Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM products WHERE UPPER(unit_type) = UPPER(?)',
            [legacyCode],
          ))
        : 0;

    // 3. Check if used as Base Unit for other units
    final childUnitCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM units WHERE base_unit_id = ? AND is_active = 1',
      [unitId],
    ));

    return (productCount ?? 0) +
        (legacyProductCount ?? 0) +
        (childUnitCount ?? 0);
  }

  Future<void> deleteUnit(int id) async {
    final db = await _dbHelper.database;

    // 1. Check if System Unit
    final unitRes = await db.query('units',
        columns: ['is_system'], where: 'id = ?', whereArgs: [id]);
    if (unitRes.isEmpty) return;

    if (unitRes.first['is_system'] == 1) {
      throw Exception("System units cannot be deleted.");
    }

    // 2. Check Usage
    final usageCount = await checkUsage(id);

    if (usageCount > 0) {
      // Soft Delete
      await db.update(
        'units',
        {
          'is_active': 0,
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

    final count = Sqflite.firstIntValue(await db.query('units',
        columns: ['COUNT(*)'], where: where, whereArgs: args));
    return count == 0;
  }
}
