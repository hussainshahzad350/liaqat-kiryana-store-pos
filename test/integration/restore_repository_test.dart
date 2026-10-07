@Tags(['database'])
library restore_repository_test;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/settings_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/test_database.dart';

Future<Map<String, List<Map<String, Object?>>>> rows(Database db) async {
  final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name");
  return {
    for (final table in tables)
      table['name'] as String:
          await db.query(table['name'] as String, orderBy: 'rowid'),
  };
}

void main() {
  useTestDatabase();
  final repository = SettingsRepository();
  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    for (final file in await Directory(p.dirname(db.path)).list().toList()) {
      if (file is File && file.path.contains('.emergency.')) {
        await file.delete();
      }
    }
  });

  test('restore reopens the database and preserves every backed-up row',
      () async {
    final original = await DatabaseHelper.instance.database;
    final expected = await rows(original);
    final backup = (await repository.createManualBackup())!;
    await original.rawQuery('PRAGMA journal_mode = WAL');
    await original.rawQuery('PRAGMA wal_autocheckpoint = 0');
    await original
        .update('shop_profile', {'shop_name_english': 'Before restore'});
    final beforeRestore = await rows(original);
    expect(await repository.restoreBackup(backup), isTrue);
    final restored = await DatabaseHelper.instance.database;
    expect(restored.isOpen, isTrue);
    expect(await rows(restored), expected);
    expect((await restored.rawQuery('PRAGMA foreign_keys')).single.values, [1]);
    final emergency =
        (await Directory(p.dirname(restored.path)).list().toList())
            .whereType<File>()
            .where((file) => file.path.contains('.emergency.'))
            .toList();
    expect(emergency, hasLength(1));
    final saved = await databaseFactory.openDatabase(emergency.single.path,
        options: OpenDatabaseOptions(readOnly: true));
    try {
      expect(await rows(saved), beforeRestore);
    } finally {
      await saved.close();
    }
    await restored
        .update('shop_profile', {'shop_name_english': 'Still usable'});
    expect((await restored.query('shop_profile')).single['shop_name_english'],
        'Still usable');
  });

  for (final invalid in [
    'missing',
    'corrupt',
    'unrelated',
    'newer',
    'partial',
    'self'
  ]) {
    test('$invalid restore is rejected without changing current data',
        () async {
      final db = await DatabaseHelper.instance.database;
      await db.update('shop_profile', {'shop_name_english': 'Keep current'});
      final expected = await rows(db);
      final candidate = p.join(p.dirname(db.path), 'invalid_$invalid.db');
      var restorePath = candidate;
      if (invalid == 'corrupt') {
        await File(candidate).writeAsString('This is not a SQLite database');
      } else if (invalid == 'unrelated') {
        final other = await databaseFactory.openDatabase(candidate);
        await other.execute('CREATE TABLE unrelated (id INTEGER)');
        await other.execute('PRAGMA user_version = 5');
        await other.close();
      } else if (invalid == 'newer' || invalid == 'partial') {
        await db.execute('VACUUM INTO ?', [candidate]);
        final other = await databaseFactory.openDatabase(candidate);
        if (invalid == 'newer') {
          await other.execute('PRAGMA user_version = 999');
        } else {
          await other.execute('DROP TABLE sale_print_logs');
        }
        await other.close();
      } else if (invalid == 'self') {
        restorePath = db.path;
      }
      expect(await repository.restoreBackup(restorePath), isFalse);
      final current = await DatabaseHelper.instance.database;
      expect(current.isOpen, isTrue);
      expect(await rows(current), expected);
      expect(
          (await Directory(p.dirname(db.path)).list().toList())
              .where((file) => file.path.contains('.emergency.')),
          isEmpty);
    });
  }

  test('failed legacy upgrade restores the emergency snapshot', () async {
    final db = await DatabaseHelper.instance.database;
    final backup = (await repository.createManualBackup())!;
    final candidate = await databaseFactory.openDatabase(backup);
    await candidate.execute('DROP INDEX idx_customer_ledger_transaction_id');
    final entry = Map<String, Object?>.from(
        (await candidate.query('customer_ledger')).first)
      ..remove('id');
    await candidate.insert('customer_ledger', entry);
    await candidate.execute('PRAGMA user_version = 4');
    await candidate.close();
    await db.update('shop_profile', {'shop_name_english': 'Rollback target'});
    final expected = await rows(db);
    expect(await repository.restoreBackup(backup), isFalse);
    final current = await DatabaseHelper.instance.database;
    expect(current.isOpen, isTrue);
    expect(await rows(current), expected);
    expect(await current.getVersion(), 5);
  });

  test('restore includes committed source WAL writes without changing source',
      () async {
    final backup = (await repository.createManualBackup())!;
    final source = await databaseFactory.openDatabase(backup);
    try {
      await source.rawQuery('PRAGMA journal_mode = WAL');
      await source.rawQuery('PRAGMA wal_autocheckpoint = 0');
      await source.update('shop_profile', {'shop_name_english': 'Source WAL'});
      expect(await File('$backup-wal').length(), greaterThan(0));
      final expected = await rows(source);
      expect(await repository.restoreBackup(backup), isTrue);
      expect(await rows(await DatabaseHelper.instance.database), expected);
      expect(source.isOpen, isTrue);
      expect(await rows(source), expected);
    } finally {
      await source.close();
    }
  });

  test('version 4 restore uses existing upgrade and keeps source unchanged',
      () async {
    final backup = (await repository.createManualBackup())!;
    final source = await databaseFactory.openDatabase(backup);
    await source.execute('PRAGMA user_version = 4');
    final expected = await rows(source);
    await source.close();
    expect(await repository.restoreBackup(backup), isTrue);
    final restored = await DatabaseHelper.instance.database;
    expect(await restored.getVersion(), 5);
    expect(await rows(restored), expected);
    final unchanged = await databaseFactory.openDatabase(backup,
        options: OpenDatabaseOptions(readOnly: true));
    try {
      expect(await unchanged.getVersion(), 4);
      expect(await rows(unchanged), expected);
    } finally {
      await unchanged.close();
    }
  });

  test('overlapping restores cannot replace the database simultaneously',
      () async {
    final original = await DatabaseHelper.instance.database;
    final expected = await rows(original);
    final backup = (await repository.createManualBackup())!;
    expect(
        await Future.wait([
          repository.restoreBackup(backup),
          SettingsRepository().restoreBackup(backup),
        ]),
        [true, false]);
    expect(await rows(await DatabaseHelper.instance.database), expected);
    expect(await repository.restoreBackup(backup), isTrue);
  });
}
