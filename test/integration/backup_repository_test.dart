@Tags(['database'])
library backup_repository_test;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/settings_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/test_database.dart';

void main() {
  useTestDatabase();
  late SettingsRepository repository;
  setUp(() async {
    repository = SettingsRepository();
    for (final backup in await repository.getBackupFiles()) {
      await File(backup['path'] as String).delete();
    }
  });

  test('manual backup is listed and retains the original persisted data',
      () async {
    final db = await DatabaseHelper.instance.database;
    final original = await db.query('shop_profile', orderBy: 'id');
    final backupPath = await repository.createManualBackup();
    expect(backupPath, isNotNull);
    final backups = await repository.getBackupFiles();
    expect(backups.map((backup) => backup['path']), contains(backupPath));
    await db
        .update('shop_profile', {'shop_name_english': 'Changed after backup'});
    final backup = await databaseFactory.openDatabase(backupPath!,
        options: OpenDatabaseOptions(readOnly: true));
    try {
      expect(await backup.query('shop_profile', orderBy: 'id'), original);
      expect((await backup.rawQuery('PRAGMA integrity_check')).single.values,
          ['ok']);
    } finally {
      await backup.close();
    }
  });

  test('backup includes committed writes still held in the WAL', () async {
    final db = await DatabaseHelper.instance.database;
    await db.rawQuery('PRAGMA journal_mode = WAL');
    await db.rawQuery('PRAGMA wal_autocheckpoint = 0');
    await db.update('shop_profile', {'shop_name_english': 'Latest WAL value'});
    expect(await File('${db.path}-wal').length(), greaterThan(0));
    final backupPath = await repository.createManualBackup();
    expect(backupPath, isNotNull);
    final backup = await databaseFactory.openDatabase(backupPath!,
        options: OpenDatabaseOptions(readOnly: true));
    try {
      expect((await backup.query('shop_profile')).single['shop_name_english'],
          'Latest WAL value');
    } finally {
      await backup.close();
    }
  });

  test('successive backups have distinct paths and remain listed', () async {
    final paths = <String>[];
    for (var index = 0; index < 3; index++) {
      final backupPath = await repository.createManualBackup();
      expect(backupPath, isNotNull);
      paths.add(backupPath!);
    }
    expect(paths.toSet(), hasLength(3));
    expect((await repository.getBackupFiles()).map((backup) => backup['path']),
        containsAll(paths));
  });

  test('invalid retention cannot create or delete backup files', () async {
    final db = await DatabaseHelper.instance.database;
    final directory = Directory(p.dirname(db.path));
    final filesBefore =
        (await directory.list().toList()).map((file) => file.path).toList();
    await expectLater(repository.createManualBackup(0), throwsArgumentError);
    await expectLater(repository.createManualBackup(-1), throwsArgumentError);
    expect((await directory.list().toList()).map((file) => file.path),
        unorderedEquals(filesBefore));
  });

  test(
      'listing and retention recognize both names and preserve unrelated files',
      () async {
    final db = await DatabaseHelper.instance.database;
    final directory = p.dirname(db.path);
    final legacy = File(p.join(directory, 'old.backup.db'));
    final manual = File(p.join(directory, 'manual_backup_20260101_120000.db'));
    final unrelated = File(p.join(directory, 'notes.backup.db.txt'));
    await File(db.path).copy(legacy.path);
    await File(db.path).copy(manual.path);
    await unrelated.writeAsString('Must be preserved');
    await legacy.setLastModified(DateTime.utc(2020, 1, 1));
    await manual.setLastModified(DateTime.utc(2021, 1, 1));
    final listed = await repository.getBackupFiles();
    expect(listed.map((backup) => backup['path']),
        unorderedEquals([legacy.path, manual.path]));
    final newest = await repository.createManualBackup(2);
    expect(newest, isNotNull);
    expect(await legacy.exists(), isFalse);
    expect(await manual.exists(), isTrue);
    expect(await unrelated.readAsString(), 'Must be preserved');
    expect(await File(db.path).exists(), isTrue);
    expect((await repository.getBackupFiles()).map((backup) => backup['path']),
        unorderedEquals([manual.path, newest]));
  });
}
