import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import '../test/support/kiryana_performance_fixture.dart';
import '../test/support/large_store_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('create persistent isolated kiryana performance store', () async {
    final lab = Directory('.local/performance-lab').absolute;
    await Directory('${lab.path}/database').create(recursive: true);
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await databaseFactory.setDatabasesPath('${lab.path}/database');
    initializeVerificationPreferences();
    final db = await DatabaseHelper.instance.database;
    expect(
        p.isWithin(p.normalize('${lab.path}/database'), p.normalize(db.path)),
        isTrue);
    try {
      await seedKiryanaPerformanceStore(db, lab);
    } finally {
      await DatabaseHelper.instance.close();
    }
  }, timeout: const Timeout(Duration(minutes: 15)));
}
