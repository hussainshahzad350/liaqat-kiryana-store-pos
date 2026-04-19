import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../utils/logger.dart';

class UnitDataFixer {
  static Future<void> fix() async {
    final db = await DatabaseHelper.instance.database;
    AppLogger.info('Starting Unit Data Fix...', tag: 'DB_FIX');

    await db.transaction((txn) async {
      // 1. Fix Categories (ensure IDs match names)
      await txn.execute('UPDATE unit_categories SET name = "Weight" WHERE id = 1');
      await txn.execute('UPDATE unit_categories SET name = "Volume" WHERE id = 2');
      await txn.execute('UPDATE unit_categories SET name = "Count" WHERE id = 3');
      await txn.execute('UPDATE unit_categories SET name = "Length" WHERE id = 4');

      // 2. Clear existing system units to avoid confusion (but keep user ones)
      // Actually, updating is safer to preserve IDs if possible, but sample data is small.
      
      // Let's identify the core units by their codes
      
      // WEIGHT
      await _upsertSystemUnit(txn, 'Gram', 'G', 1, null, 1);
      int? gId = await _getUnitId(txn, 'G');
      await _upsertSystemUnit(txn, 'Kilogram', 'KG', 1, gId, 1000);

      // VOLUME
      await _upsertSystemUnit(txn, 'Milliliter', 'ML', 2, null, 1);
      int? mlId = await _getUnitId(txn, 'ML');
      await _upsertSystemUnit(txn, 'Liter', 'L', 2, mlId, 1000);

      // COUNT
      await _upsertSystemUnit(txn, 'Piece', 'PCS', 3, null, 1);
      int? pcsId = await _getUnitId(txn, 'PCS');
      await _upsertSystemUnit(txn, 'Dozen', 'DZN', 3, pcsId, 12);

      // LENGTH
      await _upsertSystemUnit(txn, 'Centimeter', 'CM', 4, null, 1);
      int? cmId = await _getUnitId(txn, 'CM');
      await _upsertSystemUnit(txn, 'Meter', 'M', 4, cmId, 100);
      
      // 3. Fix any units that might be in the wrong category (Length vs Weight mismatch correction)
      // This is handled by the upsert above based on codes.
    });

    AppLogger.info('Unit Data Fix Completed.', tag: 'DB_FIX');
  }

  static Future<void> _upsertSystemUnit(Transaction txn, String name, String code, int categoryId, int? baseUnitId, int multiplier) async {
    final existing = await txn.query('units', where: 'code = ?', whereArgs: [code]);
    
    if (existing.isNotEmpty) {
      await txn.update('units', {
        'name': name,
        'category_id': categoryId,
        'is_system': 1,
        'base_unit_id': baseUnitId,
        'multiplier': multiplier,
        'is_active': 1,
      }, where: 'code = ?', whereArgs: [code]);
    } else {
      await txn.insert('units', {
        'name': name,
        'code': code,
        'category_id': categoryId,
        'is_system': 1,
        'base_unit_id': baseUnitId,
        'multiplier': multiplier,
        'is_active': 1,
      });
    }
  }

  static Future<int?> _getUnitId(Transaction txn, String code) async {
    final res = await txn.query('units', columns: ['id'], where: 'code = ?', whereArgs: [code]);
    if (res.isNotEmpty) return res.first['id'] as int;
    return null;
  }
}
