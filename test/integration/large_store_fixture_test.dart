@Tags(['database'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import '../support/test_database.dart';
import '../support/large_store_fixture.dart';

void main() {
  useTestDatabase();
  test(
      'volume fixture preserves seed rows and creates unique consistent records',
      () async {
    final db = await DatabaseHelper.instance.database;
    final products = await db.query('products', orderBy: 'id');
    final customers = await db.query('customers', orderBy: 'id');
    await seedLargeStore(db, products: 3, customers: 4);
    final afterProducts = await db.query('products', orderBy: 'id');
    final afterCustomers = await db.query('customers', orderBy: 'id');
    expect(afterProducts.take(products.length), products);
    expect(afterCustomers.take(customers.length), customers);
    expect(afterProducts.length, products.length + 3);
    expect(afterCustomers.length, customers.length + 4);
    expect(
        afterProducts
            .skip(products.length)
            .every((p) => p['current_stock'] == 0),
        true);
    expect(
        afterCustomers
            .skip(customers.length)
            .map((c) => c['contact_primary'])
            .toSet(),
        hasLength(4));
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });
}
