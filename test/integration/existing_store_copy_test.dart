@Tags(['database'])
library existing_store_copy_test;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/settings_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/test_database.dart';

const storeCopyPath = String.fromEnvironment('STORE_COPY_PATH');

Future<Map<String, List<Map<String, Object?>>>> storeRows(Database db) async {
  final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name");
  return {
    for (final table in tables)
      table['name'] as String:
          await db.query(table['name'] as String, orderBy: 'rowid'),
  };
}

void main() {
  useTestDatabase();
  test(
      'existing standalone copy opens, diagnoses and restores without source writes',
      () async {
    final sourceFile = File(storeCopyPath);
    final sourceHash =
        sha256.convert(await sourceFile.readAsBytes()).toString();
    final source = await databaseFactory.openDatabase(storeCopyPath,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false));
    late Map<String, List<Map<String, Object?>>> original;
    late int sourceVersion;
    try {
      original = await storeRows(source);
      sourceVersion = await source.getVersion();
      expect(await source.rawQuery('PRAGMA integrity_check'), [
        {'integrity_check': 'ok'}
      ]);
    } finally {
      await source.close();
    }
    final temporary = await DatabaseHelper.instance.database;
    expect(p.equals(temporary.path, storeCopyPath), isFalse);
    final temporaryPath = temporary.path;
    await DatabaseHelper.instance.close();
    await sourceFile.copy(temporaryPath);
    final upgraded = await DatabaseHelper.instance.database;
    expect(await upgraded.getVersion(), 5);
    expect(await upgraded.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    final afterOpen = await storeRows(upgraded);
    for (final table in original.keys
        .where((table) => !['units', 'unit_categories'].contains(table))) {
      expect(afterOpen[table], hasLength(original[table]!.length),
          reason: table);
      for (var index = 0; index < original[table]!.length; index++) {
        expect({
          for (final key in original[table]![index].keys)
            key: afterOpen[table]![index][key]
        }, original[table]![index], reason: '$table row $index');
      }
    }
    final stock = await upgraded.rawQuery('''
      SELECT COUNT(*) AS count FROM products p
      WHERE ABS(p.current_stock - COALESCE((SELECT SUM(quantity_change)
        FROM stock_activities s WHERE s.product_id=p.id), 0)) > 0.000001
    ''');
    final customers = await upgraded.rawQuery('''
      SELECT COUNT(*) AS count FROM customers c
      WHERE c.outstanding_balance != COALESCE((SELECT SUM(debit-credit)
        FROM customer_ledger l WHERE l.customer_id=c.id), 0)
    ''');
    final suppliers = await upgraded.rawQuery('''
      SELECT COUNT(*) AS count FROM suppliers s
      WHERE s.outstanding_balance != COALESCE((SELECT SUM(debit-credit)
        FROM supplier_ledger l WHERE l.supplier_id=s.id), 0)
    ''');
    final diagnosis = {
      'sourceVersion': sourceVersion,
      'openedVersion': await upgraded.getVersion(),
      'rowCounts': {
        for (final entry in afterOpen.entries) entry.key: entry.value.length
      },
      'stockCacheMismatches': stock.single['count'],
      'customerBalanceMismatches': customers.single['count'],
      'supplierBalanceMismatches': suppliers.single['count'],
      'sourceUnchanged': true,
      'provenance':
          'Captured existing database; real-store provenance unconfirmed',
    };
    final repository = SettingsRepository();
    final backup = (await repository.createManualBackup())!;
    await upgraded.update('shop_profile',
        {'shop_name_english': 'Temporary restore verification'});
    expect(await repository.restoreBackup(backup), isTrue);
    expect(await storeRows(await DatabaseHelper.instance.database), afterOpen);
    expect(
        sha256.convert(await sourceFile.readAsBytes()).toString(), sourceHash);
    await File('build/existing-store-diagnosis.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(diagnosis));
  },
      skip: storeCopyPath.isEmpty
          ? 'Supply STORE_COPY_PATH for a captured standalone copy'
          : false);
}
