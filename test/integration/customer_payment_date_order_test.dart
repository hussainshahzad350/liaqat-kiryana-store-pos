import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/models/customer_model.dart';

import '../support/test_database.dart';

void main() {
  useTestDatabase();
  test('mixed timestamp formats preserve sequential customer receipt balances',
      () async {
    final repository = CustomersRepository();
    final id = await repository.addCustomer(Customer(
        nameEnglish: 'Date-order regression',
        outstandingBalance: 30000,
        createdAt: DateTime.utc(2026, 10, 4, 5)));
    await repository.addPayment(
        id, 10000, '2026-10-04 10:01:00', 'First receipt');
    await repository.addPayment(
        id, 25000, '2026-10-04 10:02:00', 'Second receipt');
    final db = await DatabaseHelper.instance.database;
    expect(
        (await db.query('customers', where: 'id = ?', whereArgs: [id]))
            .single['outstanding_balance'],
        -5000);
    expect(
        (await db.query('customer_ledger',
                where: 'customer_id = ?', whereArgs: [id], orderBy: 'id'))
            .last['balance'],
        -5000);
    expect(
        (await db.rawQuery(
                'SELECT SUM(debit - credit) AS total FROM customer_ledger WHERE customer_id = ?',
                [id]))
            .single['total'],
        -5000);
    // A subsequent receipt must not fail the consistency check.
    await repository.addPayment(id, 1000, '2026-10-03 10:00:00', 'Backdated');
    expect((await repository.getCustomerById(id))!.outstandingBalance, -6000);
    expect((await db.query('cash_ledger', orderBy: 'id')).last['balance_after'],
        36000);
  });
}
