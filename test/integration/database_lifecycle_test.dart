@Tags(['database'])
library database_lifecycle_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';

import '../support/test_database.dart';

void main() {
  useTestDatabase();

  test('database access reopens an externally closed connection', () async {
    final original = await DatabaseHelper.instance.database;
    await original.update('shop_profile', {'shop_name_english': 'Preserved'});
    await original.close();
    final reopened = await DatabaseHelper.instance.database;
    expect(reopened.isOpen, isTrue);
    expect((await reopened.query('shop_profile')).single['shop_name_english'],
        'Preserved');
    expect((await reopened.rawQuery('PRAGMA foreign_keys')).single.values, [1]);
  });

  test('helper close permits repeated close and subsequent access', () async {
    final original = await DatabaseHelper.instance.database;
    await original.update('shop_profile', {'shop_name_english': 'Still here'});
    await DatabaseHelper.instance.close();
    await DatabaseHelper.instance.close();
    final reopened = await DatabaseHelper.instance.database;
    expect(reopened.isOpen, isTrue);
    expect((await reopened.query('shop_profile')).single['shop_name_english'],
        'Still here');
  });
}
