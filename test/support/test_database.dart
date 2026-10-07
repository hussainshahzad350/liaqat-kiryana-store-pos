import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Gives a test suite a disposable database, recreated before every test.
///
/// The factory path is installed before calling the application's reset method.
/// No database operation is allowed to use the normal desktop database path.
void useTestDatabase() {
  DatabaseFactory? previousDatabaseFactory;
  Directory? directory;
  Database? database;
  var factoryInstalled = false;

  setUpAll(() async {
    previousDatabaseFactory = databaseFactoryOrNull;
    sqfliteFfiInit();
    directory = await Directory.systemTemp.createTemp('liaqat_pos_test_');
    final factory = createDatabaseFactoryFfi();
    await factory.setDatabasesPath(directory!.path);
    databaseFactoryOrNull = factory;
    factoryInstalled = true;
  });

  setUp(() async {
    final databaseDirectory = directory;
    if (!factoryInstalled || databaseDirectory == null) {
      throw StateError('Temporary test database was not initialized');
    }
    expect(await getDatabasesPath(), databaseDirectory.path);
    await DatabaseHelper.instance.resetDatabase();
    database = await DatabaseHelper.instance.database;
    expect(path.isWithin(databaseDirectory.path, database!.path), isTrue);
  });

  tearDownAll(() async {
    try {
      await DatabaseHelper.instance.close();
    } finally {
      if (factoryInstalled) {
        databaseFactoryOrNull = previousDatabaseFactory;
      }
      final databaseDirectory = directory;
      if (databaseDirectory != null && await databaseDirectory.exists()) {
        await databaseDirectory.delete(recursive: true);
      }
    }
  });
}

/// Seeds a stock position with a matching event in the disposable test database.
/// This is fixture construction, not a production stock-adjustment operation.
Future<void> setTestStock(int productId, double quantity) async {
  final db = await DatabaseHelper.instance.database;
  await db.transaction((txn) async {
    final events = await txn.rawQuery(
      'SELECT COALESCE(SUM(quantity_change), 0) AS total FROM stock_activities WHERE product_id = ?',
      [productId],
    );
    final previous = (events.single['total'] as num).toDouble();
    final eventId = await txn.insert('stock_activities', {
      'product_id': productId,
      'quantity_change': quantity - previous,
      'transaction_type': 'ADJUSTMENT',
      'reference_type': 'TEST_FIXTURE',
      'reference_id': productId,
      'ref_type': 'TEST_FIXTURE',
      'ref_id': productId,
      'user': 'TEST',
      'created_at': '2026-01-01T00:00:00.000Z',
    });
    await txn.update(
        'stock_activities',
        {
          'transaction_id': 'TEST_FIXTURE:STOCK:$eventId',
        },
        where: 'id = ?',
        whereArgs: [eventId]);
    await txn.update('products', {'current_stock': quantity},
        where: 'id = ?', whereArgs: [productId]);
  });
}
