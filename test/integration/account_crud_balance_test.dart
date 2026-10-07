import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/core/repositories/suppliers_repository.dart';
import 'package:liaqat_store/models/customer_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/test_database.dart';

void main() {
  useTestDatabase();
  for (final opening in [30000, -5000, 0]) {
    test('supplier opening $opening survives payment and detail edits',
        () async {
      final repository = SuppliersRepository();
      final id = await repository.addSupplier({
        'name_english': 'Opening supplier',
        'contact_primary': '0300-8880000',
        'outstanding_balance': opening,
        'created_at': '2026-10-04T00:00:00Z',
      });
      final db = await DatabaseHelper.instance.database;
      final entries = await db
          .query('supplier_ledger', where: 'supplier_id = ?', whereArgs: [id]);
      expect(entries, hasLength(opening == 0 ? 0 : 1));
      if (opening != 0) {
        expect(entries.single['debit'], opening > 0 ? opening : 0);
        expect(entries.single['credit'], opening < 0 ? -opening : 0);
        expect(entries.single['balance'], opening);
      }
      expect(await db.query('cash_ledger'), isEmpty);
      await repository.addPayment(id, 1000, 'First payment');
      final beforeEdit = await db.query('supplier_ledger', orderBy: 'id');
      await repository.updateSupplier(id,
          {'name_english': 'Edited supplier', 'outstanding_balance': opening});
      expect((await repository.getSupplierById(id))!['outstanding_balance'],
          opening - 1000);
      expect(await db.query('supplier_ledger', orderBy: 'id'), beforeEdit);
      expect(
          (await db.rawQuery(
                  'SELECT SUM(debit - credit) AS total FROM supplier_ledger WHERE supplier_id = ?',
                  [id]))
              .single['total'],
          opening - 1000);
    });
  }

  test('supplier opening write failure rolls back the supplier', () async {
    final db = await DatabaseHelper.instance.database;
    final before = await db.query('suppliers', orderBy: 'id');
    await db.execute("""CREATE TEMP TRIGGER reject_supplier_opening
      BEFORE INSERT ON supplier_ledger BEGIN
      SELECT RAISE(ABORT, 'TEST_OPENING_FAILED'); END""");
    await expectLater(
        SuppliersRepository().addSupplier({
          'name_english': 'Rollback',
          'outstanding_balance': 30000,
        }),
        throwsA(isA<DatabaseException>()));
    expect(await db.query('suppliers', orderBy: 'id'), before);
  });

  test('duplicate supplier cannot replace existing history', () async {
    final repository = SuppliersRepository();
    final id = await repository.addSupplier({
      'name_english': 'Original',
      'outstanding_balance': 30000,
    });
    await expectLater(
        repository.addSupplier({
          'id': id,
          'name_english': 'Replacement',
          'outstanding_balance': 50000,
        }),
        throwsA(isA<DatabaseException>()));
    expect((await repository.getSupplierById(id))!['name_english'], 'Original');
  });

  test('customer detail edit preserves payment after opening the form',
      () async {
    final repository = CustomersRepository();
    final id = await repository.addCustomer(
        Customer(nameEnglish: 'Original customer', outstandingBalance: 30000));
    final stale = (await repository.getCustomerById(id))!;
    await repository.addPayment(id, 1000, '2026-10-04', 'Payment during edit');
    final db = await DatabaseHelper.instance.database;
    final before = await db.query('customer_ledger', orderBy: 'id');
    await repository.updateCustomer(
        id, stale.copyWith(nameEnglish: 'Edited customer'));
    expect((await repository.getCustomerById(id))!.outstandingBalance, 29000);
    expect(await db.query('customer_ledger', orderBy: 'id'), before);
  });
}
