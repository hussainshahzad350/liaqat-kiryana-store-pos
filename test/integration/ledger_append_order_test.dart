import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/core/repositories/invoice_repository.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/core/repositories/purchase_repository.dart';
import 'package:liaqat_store/core/repositories/suppliers_repository.dart';
import 'package:liaqat_store/models/customer_model.dart';

import '../support/test_database.dart';

void main() {
  useTestDatabase();

  test('sale and cancellation use the last recorded customer balance',
      () async {
    final customers = CustomersRepository();
    final invoices = InvoiceRepository(ItemsRepository());
    final id = await customers.addCustomer(Customer(
      nameEnglish: 'Future dated opening',
      outstandingBalance: 30000,
      createdAt: DateTime.utc(2099),
    ));
    await customers.addPayment(id, 10000, '2026-10-04 10:00:00', 'Receipt');
    final invoice = await invoices.createInvoiceWithTransaction(
      customerId: id,
      grandTotal: 18000,
      creditAmount: 18000,
      items: [
        {
          'product_id': 1,
          'name_english': 'Test Product',
          'quantity': 1.0,
          'unit_price': 18000,
          'total': 18000,
          'cost_price': 15000
        },
      ],
    );
    expect((await customers.getCustomerById(id))!.outstandingBalance, 38000);
    await customers.addPayment(id, 5000, '2025-01-01', 'Backdated receipt');
    await invoices.cancelInvoice(invoiceId: invoice, cancelledBy: 'TEST');
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('customer_ledger',
        where: 'customer_id = ?', whereArgs: [id], orderBy: 'id');
    expect(
        rows.map((row) => row['balance']), [30000, 20000, 38000, 33000, 15000]);
    expect((await customers.getCustomerById(id))!.outstandingBalance, 15000);
    expect((await db.query('products')).single['current_stock'], 45);
  });

  test('purchases, payments and reversal follow supplier append order',
      () async {
    final db = await DatabaseHelper.instance.database;
    final suppliers = SuppliersRepository();
    final purchases = PurchaseRepository(ItemsRepository());
    final opening =
        (await db.query('suppliers')).single['outstanding_balance'] as int;
    Future<int> purchase(String number) =>
        purchases.createPurchaseWithTransaction(
          supplierId: 1,
          totalAmount: 30000,
          invoiceNumber: number,
          items: [
            {
              'product_id': 1,
              'quantity': 2.0,
              'cost_price': 15000,
              'total_amount': 30000
            }
          ],
        );
    final first = await purchase('ORDER-1');
    // Only change date metadata in the disposable fixture: emulate a future
    // dated legacy event without changing any financial amounts or balances.
    await db.update(
        'supplier_ledger', {'transaction_date': '2099-01-01T00:00:00Z'},
        where: 'supplier_id = ? AND ref_type = ? AND ref_id = ?',
        whereArgs: [1, 'PURCHASE', first]);
    await suppliers.addPayment(1, 10000, 'First payment');
    await suppliers.addPayment(1, 5000, 'Second payment');
    await purchase('ORDER-2');
    await purchases.cancelPurchase(purchaseId: first, cancelledBy: 'TEST');
    final rows = await db.query('supplier_ledger',
        where: 'supplier_id = ?', whereArgs: [1], orderBy: 'id');
    expect(rows.last['balance'], opening + 15000);
    expect((await db.query('suppliers')).single['outstanding_balance'],
        opening + 15000);
    expect(
        (await db.rawQuery(
                'SELECT SUM(debit - credit) AS total FROM supplier_ledger WHERE supplier_id = 1'))
            .single['total'],
        opening + 15000);
    expect((await db.query('cash_ledger', orderBy: 'id')).last['balance_after'],
        -15000);
    expect((await db.query('products')).single['current_stock'], 47);
  });
}
