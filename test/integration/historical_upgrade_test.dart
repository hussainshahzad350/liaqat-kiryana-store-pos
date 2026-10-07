@Tags(['database'])
library historical_upgrade_test;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/settings_repository.dart';
import 'package:liaqat_store/core/repositories/invoice_repository.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/core/repositories/purchase_repository.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/models/customer_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/test_database.dart';

typedef Snapshot = Map<String, List<Map<String, Object?>>>;

Future<Snapshot> snapshot(Database db) async {
  final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name");
  return {
    for (final table in tables)
      table['name'] as String:
          await db.query(table['name'] as String, orderBy: 'rowid'),
  };
}

Future<({String path, Snapshot data})> historicalFixture(int version,
    {bool openedVersion1 = false}) async {
  final current = await DatabaseHelper.instance.database;
  final items = ItemsRepository();
  final customerId = await CustomersRepository().addCustomer(Customer(
    nameEnglish: 'Historical credit customer',
    contactPrimary: '0300-1234567',
    creditLimit: 100000,
  ));
  await InvoiceRepository(items).createInvoiceWithTransaction(
    customerId: customerId,
    grandTotal: 18000,
    cashAmount: 6000,
    creditAmount: 12000,
    items: [
      {
        'product_id': 1,
        'name_english': 'Super Basmati Rice',
        'quantity': 1,
        'unit_price': 18000,
        'total': 18000,
      }
    ],
  );
  await PurchaseRepository(items).createPurchase(
    supplierId: 1,
    invoiceNumber: 'HISTORICAL-001',
    totalAmount: 17000,
    items: [
      {
        'product_id': 1,
        'quantity': 1,
        'cost_price': 17000,
        'total_amount': 17000,
      }
    ],
  );
  final seed = await snapshot(current);
  final path = p.join(p.dirname(current.path), 'historical_v$version.db');
  await databaseFactory.deleteDatabase(path);
  final db = await databaseFactory.openDatabase(path);
  try {
    final sql =
        (await File('test/fixtures/database/v$version.sql').readAsLines())
            .where((line) => !line.startsWith('--'))
            .join('\n');
    for (final statement in sql.split(';')) {
      if (statement.trim().isNotEmpty) await db.execute(statement);
    }
    if (openedVersion1) {
      // The actual v1 onOpen callback added this column while leaving version 1.
      final columns = await db.rawQuery('PRAGMA table_info(cash_ledger)');
      if (!columns.any((row) => row['name'] == 'payment_mode')) {
        await db.execute(
            'ALTER TABLE cash_ledger ADD COLUMN payment_mode TEXT DEFAULT "CASH"');
      }
    }
    for (final table in seed.keys) {
      final columns = (await db.rawQuery('PRAGMA table_info("$table")'))
          .map((row) => row['name'])
          .toSet();
      if (columns.isEmpty) continue;
      for (final row in seed[table]!) {
        await db.insert(table, {
          for (final entry in row.entries)
            if (columns.contains(entry.key)) entry.key: entry.value,
        });
      }
    }
    expect(await db.getVersion(), version);
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    return (path: path, data: await snapshot(db));
  } finally {
    await db.close();
  }
}

Future<void> verifyUpgrade(Database upgraded, Snapshot original) async {
  expect(await upgraded.getVersion(), 5);
  expect(await upgraded.rawQuery('PRAGMA integrity_check'), [
    {'integrity_check': 'ok'}
  ]);
  expect(await upgraded.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  for (final entry in original.entries) {
    final actual = await upgraded.query(entry.key, orderBy: 'rowid');
    expect(actual, hasLength(entry.value.length), reason: entry.key);
    for (var index = 0; index < actual.length; index++) {
      expect({
        for (final key in entry.value[index].keys) key: actual[index][key]
      }, entry.value[index], reason: '${entry.key} row $index');
    }
  }
  for (final table in [
    'stock_activities',
    'customer_ledger',
    'supplier_ledger'
  ]) {
    final events = await upgraded.query(table);
    expect(events, isNotEmpty, reason: '$table populated fixture');
    expect(
        events.every(
            (row) => (row['transaction_id'] as String?)?.isNotEmpty ?? false),
        isTrue,
        reason: '$table identities');
  }
  final after = await snapshot(upgraded);
  await DatabaseHelper.instance.close();
  expect(await snapshot(await DatabaseHelper.instance.database), after);
}

void main() {
  useTestDatabase();
  for (final version in [1, 2, 3, 4]) {
    test('historical v$version upgrades on normal database open', () async {
      final fixture = await historicalFixture(version);
      final current = await DatabaseHelper.instance.database;
      final currentPath = current.path;
      await DatabaseHelper.instance.close();
      await File(fixture.path).copy(currentPath);
      await verifyUpgrade(await DatabaseHelper.instance.database, fixture.data);
    });

    test('historical v$version restores and upgrades without changing source',
        () async {
      final fixture = await historicalFixture(version);
      expect(await SettingsRepository().restoreBackup(fixture.path), isTrue);
      await verifyUpgrade(await DatabaseHelper.instance.database, fixture.data);
      final source = await databaseFactory.openDatabase(fixture.path,
          options: OpenDatabaseOptions(readOnly: true));
      try {
        expect(await source.getVersion(), version);
        expect(await snapshot(source), fixture.data);
      } finally {
        await source.close();
      }
    });
  }

  test('previously opened v1 restores despite existing payment mode column',
      () async {
    final fixture = await historicalFixture(1, openedVersion1: true);
    expect(await SettingsRepository().restoreBackup(fixture.path), isTrue);
    await verifyUpgrade(await DatabaseHelper.instance.database, fixture.data);
  });
}
