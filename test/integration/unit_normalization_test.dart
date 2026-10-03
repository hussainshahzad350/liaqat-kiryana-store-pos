@Tags(['database'])
library unit_normalization_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';

import '../support/test_database.dart';

void main() {
  useTestDatabase();

  test('normalization restores category names and is idempotent', () async {
    final db = await DatabaseHelper.instance.database;
    final schema = await db.rawQuery(
        'SELECT type, name, sql FROM sqlite_master ORDER BY type, name');
    final unitsBefore = await db.query('units', orderBy: 'id');
    await db.update('unit_categories', {'name': 'Changed category'},
        where: 'id IN (?, ?, ?, ?)', whereArgs: [1, 2, 3, 4]);

    // Call the transaction method directly so SQL errors cannot be swallowed
    // by the public on-open wrapper's logging catch block.
    await db.transaction(DatabaseHelper.ensureStandardUnitsInTransaction);

    final categories = await db.query('unit_categories',
        where: 'id IN (?, ?, ?, ?)', whereArgs: [1, 2, 3, 4], orderBy: 'id');
    expect(categories.map((row) => row['name']),
        ['Weight', 'Volume', 'Count', 'Length']);
    final normalizedUnits = await db.query('units', orderBy: 'id');
    expect(normalizedUnits.map((row) => row['id']),
        unitsBefore.map((row) => row['id']));

    await db.transaction(DatabaseHelper.ensureStandardUnitsInTransaction);
    expect(await db.query('units', orderBy: 'id'), normalizedUnits);
    expect(
        await db.rawQuery(
            'SELECT type, name, sql FROM sqlite_master ORDER BY type, name'),
        schema);
  });
}
