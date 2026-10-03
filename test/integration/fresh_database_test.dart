@Tags(['database'])
library fresh_database_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/core/repositories/invoice_repository.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/core/repositories/purchase_repository.dart';

import '../support/test_database.dart';

void main() {
  // Only database isolation: no stock or ledger fixture repairs are applied.
  useTestDatabase();

  test('sample opening stock and customer balance have matching events',
      () async {
    final db = await DatabaseHelper.instance.database;
    final product = (await db
            .query('products', where: 'item_code = ?', whereArgs: ['PRD001']))
        .single;
    expect(product['current_stock'], 45);
    final stock = await db.rawQuery(
        'SELECT SUM(quantity_change) AS total FROM stock_activities WHERE product_id = ?',
        [product['id']]);
    expect(stock.single['total'], product['current_stock']);
    final openingEvents = await db.query('stock_activities',
        where: 'product_id = ?', whereArgs: [product['id']]);
    expect(openingEvents, hasLength(1));
    expect(openingEvents.single['transaction_id'], isNotNull);
    final adjustment = await db.query('stock_adjustments',
        where: 'id = ?', whereArgs: [openingEvents.single['ref_id']]);
    expect(adjustment.single['quantity_change'], 45);
    expect(adjustment.single['product_id'], product['id']);

    final customer = (await db.query('customers',
            where: 'contact_primary = ?', whereArgs: ['0300-1111111']))
        .single;
    expect(customer['outstanding_balance'], 250000);
    final ledger = await db.rawQuery(
        'SELECT SUM(debit - credit) AS total FROM customer_ledger WHERE customer_id = ?',
        [customer['id']]);
    expect(ledger.single['total'], customer['outstanding_balance']);
    final openingEntries = await db.query('customer_ledger',
        where: 'customer_id = ?', whereArgs: [customer['id']]);
    expect(openingEntries, hasLength(1));
    expect(openingEntries.single['transaction_id'], isNotNull);
    expect(openingEntries.single['balance'], 250000);
    expect(
        (await db.rawQuery('PRAGMA user_version')).single['user_version'], 5);
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });

  test('fresh sample stock supports a cash sale and exactly-once cancellation',
      () async {
    final db = await DatabaseHelper.instance.database;
    final repository = InvoiceRepository(ItemsRepository());
    final invoiceId = await repository.createInvoiceWithTransaction(
      customerId: 1,
      grandTotal: 18000,
      cashAmount: 18000,
      items: [
        {
          'product_id': 1,
          'name_english': 'Super Basmati Rice',
          'quantity': 1,
          'unit_price': 18000,
          'total': 18000,
        }
      ],
    );
    expect(
        (await db.query('products', where: 'id = 1')).single['current_stock'],
        44);
    final cash = await db.query('cash_ledger',
        where: 'ref_type = ? AND ref_id = ?',
        whereArgs: ['INVOICE', invoiceId]);
    expect(cash, hasLength(1));
    expect(cash.single['amount'], 18000);
    expect(cash.single['type'], 'IN');

    await repository.cancelInvoice(invoiceId: invoiceId, cancelledBy: 'TEST');
    await expectLater(
      repository.cancelInvoice(invoiceId: invoiceId, cancelledBy: 'TEST'),
      throwsA(isA<Exception>().having((error) => error.toString(), 'message',
          contains('INVOICE_NOT_FOUND'))),
    );
    expect(
        (await db.query('products', where: 'id = 1')).single['current_stock'],
        45);
    final reversals = await db.query('cash_ledger',
        where: 'reversal_of_cash_ledger_id = ?',
        whereArgs: [cash.single['id']]);
    expect(reversals, hasLength(1));
    expect(reversals.single['amount'], 18000);
    expect(reversals.single['type'], 'OUT');
    final stock = await db.rawQuery(
        'SELECT SUM(quantity_change) AS total FROM stock_activities WHERE product_id = 1');
    expect(stock.single['total'], 45);
  });

  test('fresh sample stock supports purchase and cancellation', () async {
    final db = await DatabaseHelper.instance.database;
    final repository = PurchaseRepository(ItemsRepository());
    final purchaseId = await repository.createPurchase(
      supplierId: 1,
      invoiceNumber: 'FRESH-001',
      totalAmount: 17000,
      items: [
        {
          'product_id': 1,
          'quantity': 1,
          'cost_price': 17000,
          'total_amount': 17000,
        }
      ],
    );
    expect(
        (await db.query('products', where: 'id = 1')).single['current_stock'],
        46);
    expect(
        (await db.query('suppliers', where: 'id = 1'))
            .single['outstanding_balance'],
        17000);
    await repository.cancelPurchase(
        purchaseId: purchaseId, cancelledBy: 'TEST');
    expect(
        (await db.query('products', where: 'id = 1')).single['current_stock'],
        45);
    expect(
        (await db.query('suppliers', where: 'id = 1'))
            .single['outstanding_balance'],
        0);
  });

  test('fresh sample customer accepts payment against the opening balance',
      () async {
    final db = await DatabaseHelper.instance.database;
    final repository = CustomersRepository();
    final customer = (await db.query('customers',
            where: 'contact_primary = ?', whereArgs: ['0300-1111111']))
        .single;
    final customerId = customer['id'] as int;
    final receiptId = await repository.addPayment(customerId, 50000,
        DateTime.now().toUtc().toIso8601String(), 'Fresh database check');
    expect((await repository.getCustomerById(customerId))!.outstandingBalance,
        200000);
    final ledger = await db.rawQuery(
        'SELECT SUM(debit - credit) AS total FROM customer_ledger WHERE customer_id = ?',
        [customerId]);
    expect(ledger.single['total'], 200000);
    final receipt =
        await db.query('receipts', where: 'id = ?', whereArgs: [receiptId]);
    expect(receipt.single['amount'], 50000);
  });
}
