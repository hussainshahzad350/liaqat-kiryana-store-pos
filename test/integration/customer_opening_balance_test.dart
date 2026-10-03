@Tags(['database'])
library customer_opening_balance_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/models/customer_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/test_database.dart';

void main() {
  useTestDatabase();
  late CustomersRepository repository;
  setUp(() => repository = CustomersRepository());

  for (final amount in [100000, -25000]) {
    test('opening balance $amount has one matching ledger entry', () async {
      final createdAt = DateTime.utc(2026, 1, 1);
      final id = await repository.addCustomer(Customer(
        nameEnglish: 'Opening balance test',
        outstandingBalance: amount,
        createdAt: createdAt,
      ));
      final db = await DatabaseHelper.instance.database;
      final entries = await db
          .query('customer_ledger', where: 'customer_id = ?', whereArgs: [id]);
      expect(entries, hasLength(1));
      final entry = entries.single;
      expect(entry['debit'], amount > 0 ? amount : 0);
      expect(entry['credit'], amount < 0 ? -amount : 0);
      expect(entry['balance'], amount);
      expect(entry['ref_type'], 'ADJUSTMENT');
      expect(entry['ref_id'], id);
      expect(entry['transaction_id'], 'CUSTOMER:$id:INITIAL');
      expect(DateTime.parse(entry['transaction_date'] as String), createdAt);
      expect(
          (await repository.getCustomerById(id))!.outstandingBalance, amount);
      expect(await db.query('receipts'), isEmpty);
      expect(await db.query('cash_ledger'), isEmpty);
    });
  }

  test('zero opening balance creates no financial entry', () async {
    final id = await repository.addCustomer(Customer(nameEnglish: 'Zero'));
    final db = await DatabaseHelper.instance.database;
    expect((await repository.getCustomerById(id))!.outstandingBalance, 0);
    expect(
        await db.query('customer_ledger',
            where: 'customer_id = ?', whereArgs: [id]),
        isEmpty);
    expect(await db.query('receipts'), isEmpty);
    expect(await db.query('cash_ledger'), isEmpty);
  });

  for (final opening in [100000, -25000]) {
    test('payment preserves ledger consistency from opening balance $opening',
        () async {
      final id = await repository.addCustomer(Customer(
        nameEnglish: 'Payment test',
        outstandingBalance: opening,
        createdAt: DateTime.utc(2026, 1, 1),
      ));
      final receiptId = await repository.addPayment(
          id, 50000, '2026-01-15T00:00:00.000Z', 'Payment');
      final db = await DatabaseHelper.instance.database;
      final total = await db.rawQuery(
          'SELECT SUM(debit - credit) AS total FROM customer_ledger WHERE customer_id = ?',
          [id]);
      expect(total.single['total'], opening - 50000);
      expect((await repository.getCustomerById(id))!.outstandingBalance,
          opening - 50000);
      expect(
          (await db.query('receipts', where: 'id = ?', whereArgs: [receiptId]))
              .single['amount'],
          50000);
    });
  }

  test('ledger insertion failure rolls back customer creation', () async {
    final db = await DatabaseHelper.instance.database;
    final customersBefore = await db.query('customers', orderBy: 'id');
    final ledgerBefore = await db.query('customer_ledger', orderBy: 'id');
    // Fault injection is confined to this disposable database connection.
    await db.execute('''
      CREATE TEMP TRIGGER reject_opening_ledger
      BEFORE INSERT ON customer_ledger
      BEGIN
        SELECT RAISE(ABORT, 'TEST_LEDGER_WRITE_FAILED');
      END
    ''');
    await expectLater(
      repository.addCustomer(Customer(
        nameEnglish: 'Must roll back',
        outstandingBalance: 100000,
      )),
      throwsA(isA<DatabaseException>()),
    );
    expect(await db.query('customers', orderBy: 'id'), customersBefore);
    expect(await db.query('customer_ledger', orderBy: 'id'), ledgerBefore);
  });

  for (final duplicateField in ['phone', 'id']) {
    test('duplicate $duplicateField cannot replace an existing customer',
        () async {
      final id = await repository.addCustomer(Customer(
        nameEnglish: 'Original',
        contactPrimary: '0300-7000001',
      ));
      final db = await DatabaseHelper.instance.database;
      final customersBefore = await db.query('customers', orderBy: 'id');
      final ledgerBefore = await db.query('customer_ledger', orderBy: 'id');
      await expectLater(
        repository.addCustomer(Customer(
          id: duplicateField == 'id' ? id : null,
          nameEnglish: 'Replacement',
          contactPrimary:
              duplicateField == 'phone' ? '0300-7000001' : '0300-7000002',
          outstandingBalance: 100000,
        )),
        throwsA(isA<DatabaseException>()),
      );
      expect(await db.query('customers', orderBy: 'id'), customersBefore);
      expect(await db.query('customer_ledger', orderBy: 'id'), ledgerBefore);
    });
  }
}
