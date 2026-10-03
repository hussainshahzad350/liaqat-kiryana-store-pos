@Tags(['database'])
library invoice_accounting_invariants_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/core/repositories/invoice_repository.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/domain/entities/money.dart';
import 'package:liaqat_store/models/customer_model.dart';
import 'package:liaqat_store/models/product_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseFactory previousDatabaseFactory;
  late ItemsRepository itemsRepository;
  late InvoiceRepository invoiceRepository;
  late int productId;
  late int creditCustomerId;

  const unitPrice = 5000;
  const saleQuantity = 2.0;
  const saleTotal = 10000;

  List<Map<String, dynamic>> saleItems({
    double quantity = saleQuantity,
    int total = saleTotal,
  }) {
    return [
      {
        'product_id': productId,
        'name_english': 'Invariant Test Product',
        'quantity': quantity,
        'unit_price': unitPrice,
        'total': total,
      },
    ];
  }

  setUpAll(() {
    sqfliteFfiInit();
    previousDatabaseFactory = databaseFactory;
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() {
    databaseFactory = previousDatabaseFactory;
  });

  setUp(() async {
    await DatabaseHelper.instance.resetDatabase();
    itemsRepository = ItemsRepository();
    invoiceRepository = InvoiceRepository(itemsRepository);

    productId = await itemsRepository.addProduct(Product(
      itemCode: 'INVARIANT-PRODUCT',
      nameEnglish: 'Invariant Test Product',
      currentStock: 20,
      avgCostPrice: const Money(3000),
      salePrice: const Money(unitPrice),
    ));

    creditCustomerId = await CustomersRepository().addCustomer(Customer(
      nameEnglish: 'Invariant Credit Customer',
      contactPrimary: '0300-0000002',
      creditLimit: 100000,
    ));
  });

  group('Invoice accounting invariants', () {
    test('mixed payment persists matching stock, cash, and customer ledgers',
        () async {
      final invoiceId = await invoiceRepository.createInvoiceWithTransaction(
        customerId: creditCustomerId,
        items: saleItems(),
        grandTotal: saleTotal,
        cashAmount: 3000,
        bankAmount: 2000,
        creditAmount: 5000,
      );
      final db = await DatabaseHelper.instance.database;

      final product = await db.query(
        'products',
        columns: ['current_stock'],
        where: 'id = ?',
        whereArgs: [productId],
      );
      expect(product.single['current_stock'], 18.0);

      final cashEntries = await db.query(
        'cash_ledger',
        where: 'ref_type = ? AND ref_id = ?',
        whereArgs: ['INVOICE', invoiceId],
        orderBy: 'id ASC',
      );
      expect(cashEntries, hasLength(2));
      expect(cashEntries.map((row) => row['amount']), [3000, 2000]);
      expect(cashEntries.map((row) => row['payment_mode']), ['CASH', 'BANK']);

      final customerEntries = await db.query(
        'customer_ledger',
        where: 'customer_id = ? AND ref_type = ? AND ref_id = ?',
        whereArgs: [creditCustomerId, 'INVOICE', invoiceId],
      );
      expect(customerEntries, hasLength(1));
      expect(customerEntries.single['debit'], 5000);
      expect(customerEntries.single['balance'], 5000);

      final customer = await db.query(
        'customers',
        columns: ['outstanding_balance'],
        where: 'id = ?',
        whereArgs: [creditCustomerId],
      );
      expect(customer.single['outstanding_balance'], 5000);
    });

    test('walk-in credit is rejected without persisting partial effects',
        () async {
      await expectLater(
        invoiceRepository.createInvoiceWithTransaction(
          customerId: 1,
          items: saleItems(),
          grandTotal: saleTotal,
          cashAmount: 5000,
          creditAmount: 5000,
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('WALK_IN_CREDIT_NOT_ALLOWED'),
          ),
        ),
      );

      final db = await DatabaseHelper.instance.database;
      expect(await db.query('invoices'), isEmpty);
      expect(await db.query('cash_ledger'), isEmpty);
      final product = await itemsRepository.getProductStock(productId);
      expect(product, 20.0);
    });

    test('insufficient stock rolls back the invoice and all ledger writes',
        () async {
      await expectLater(
        invoiceRepository.createInvoiceWithTransaction(
          customerId: 1,
          items: saleItems(quantity: 21, total: 105000),
          grandTotal: 105000,
          cashAmount: 105000,
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('INSUFFICIENT_STOCK'),
          ),
        ),
      );

      final db = await DatabaseHelper.instance.database;
      expect(await db.query('invoices'), isEmpty);
      expect(await db.query('invoice_items'), isEmpty);
      expect(await db.query('cash_ledger'), isEmpty);
      expect(await itemsRepository.getProductStock(productId), 20.0);
    });

    test('walk-in overpayment records only the invoice total as inflow',
        () async {
      final invoiceId = await invoiceRepository.createInvoiceWithTransaction(
        customerId: 1,
        items: saleItems(),
        grandTotal: saleTotal,
        cashAmount: 12000,
      );
      final db = await DatabaseHelper.instance.database;

      final cashEntries = await db.query(
        'cash_ledger',
        where: 'ref_type = ? AND ref_id = ?',
        whereArgs: ['INVOICE', invoiceId],
      );
      expect(cashEntries, hasLength(1));
      expect(cashEntries.single['amount'], saleTotal);
      expect(cashEntries.single['balance_after'], saleTotal);
    });

    test('cancellation reverses effects exactly once', () async {
      final invoiceId = await invoiceRepository.createInvoiceWithTransaction(
        customerId: creditCustomerId,
        items: saleItems(),
        grandTotal: saleTotal,
        cashAmount: 3000,
        bankAmount: 2000,
        creditAmount: 5000,
      );

      await invoiceRepository.cancelInvoice(
        invoiceId: invoiceId,
        cancelledBy: 'test-user',
        reason: 'Regression test',
      );
      final db = await DatabaseHelper.instance.database;

      final invoice = await db.query(
        'invoices',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
      expect(invoice.single['status'], 'CANCELLED');
      expect(await itemsRepository.getProductStock(productId), 20.0);

      final customer = await db.query(
        'customers',
        columns: ['outstanding_balance'],
        where: 'id = ?',
        whereArgs: [creditCustomerId],
      );
      expect(customer.single['outstanding_balance'], 0);

      final stockEvents = await db.query(
        'stock_activities',
        where: 'ref_type = ? AND ref_id = ?',
        whereArgs: ['INVOICE', invoiceId],
      );
      final cashEntries = await db.query(
        'cash_ledger',
        where: 'ref_type = ? AND ref_id = ?',
        whereArgs: ['INVOICE', invoiceId],
      );
      final customerEntries = await db.query(
        'customer_ledger',
        where: 'customer_id = ? AND ref_id = ?',
        whereArgs: [creditCustomerId, invoiceId],
      );
      expect(stockEvents, hasLength(2));
      expect(cashEntries, hasLength(4));
      expect(customerEntries, hasLength(2));

      await expectLater(
        invoiceRepository.cancelInvoice(
          invoiceId: invoiceId,
          cancelledBy: 'test-user',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('INVOICE_NOT_FOUND'),
          ),
        ),
      );

      expect(
        await db.query(
          'stock_activities',
          where: 'ref_type = ? AND ref_id = ?',
          whereArgs: ['INVOICE', invoiceId],
        ),
        hasLength(2),
      );
      expect(
        await db.query(
          'cash_ledger',
          where: 'ref_type = ? AND ref_id = ?',
          whereArgs: ['INVOICE', invoiceId],
        ),
        hasLength(4),
      );
    });
  });
}
