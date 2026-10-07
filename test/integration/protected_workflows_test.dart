@Tags(['database'])
library protected_workflows_test;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/core/repositories/invoice_repository.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/core/repositories/purchase_repository.dart';
import 'package:liaqat_store/core/repositories/suppliers_repository.dart';
import 'package:liaqat_store/domain/entities/money.dart';
import 'package:liaqat_store/models/customer_model.dart';

import '../support/test_database.dart';

void main() {
  useTestDatabase();
  late InvoiceRepository invoices;
  late PurchaseRepository purchases;
  late int customerId;

  setUp(() async {
    invoices = InvoiceRepository(ItemsRepository());
    purchases = PurchaseRepository(ItemsRepository());
    customerId = await CustomersRepository().addCustomer(Customer(
      nameEnglish: 'Protected workflow customer',
      creditLimit: 100000,
    ));
  });

  List<Map<String, dynamic>> items({double quantity = 1, int total = 10001}) =>
      [
        {
          'product_id': 1,
          'name_english': 'Protected product',
          'quantity': quantity,
          'unit_price': 10001,
          'total': total,
        },
      ];

  // Snapshot all application tables, including caches and history. Rejected
  // commands must leave all persisted rows unchanged, not merely their header.
  Future<Map<String, Object>> snapshot() async {
    final db = await DatabaseHelper.instance.database;
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name");
    return {
      for (final table in tables)
        table['name'] as String:
            await db.query(table['name'] as String, orderBy: 'rowid'),
    };
  }

  Matcher errorCode(String code) => throwsA(isA<Exception>()
      .having((error) => error.toString(), 'error code', contains(code)));

  // Optional review artifact. Preserve financial columns and reversal links;
  // remove only clock-derived identifiers so separate fixture runs compare.
  Future<void> capture(String name) async {
    final side = Platform.environment['PHASE3_EVIDENCE_SIDE'];
    if (side == null) return;
    final rows = await snapshot();
    final normalized = {
      for (final entry in rows.entries)
        entry.key: [
          for (final row in entry.value as List<Map<String, Object?>>)
            {
              for (final column in row.entries)
                if (!column.key.contains('date') &&
                    !column.key.contains('time') &&
                    !column.key.endsWith('_at') &&
                    column.key != 'transaction_id' &&
                    column.key != 'invoice_number')
                  column.key: column.value,
            },
        ],
    };
    final directory = Directory('build/sales-phase3-review');
    await directory.create(recursive: true);
    await File('${directory.path}/$side-$name.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(normalized));
  }

  for (final payment in [
    (name: 'cash', cash: 10001, bank: 0, credit: 0),
    (name: 'bank', cash: 0, bank: 10001, credit: 0),
    (name: 'credit', cash: 0, bank: 0, credit: 10001),
    (name: 'mixed', cash: 3333, bank: 3333, credit: 3335),
  ]) {
    test('${payment.name} sale posts exact paisas and linked reversals',
        () async {
      final id = await invoices.createInvoiceWithTransaction(
        customerId: customerId,
        items: items(),
        grandTotal: 10001,
        cashAmount: payment.cash,
        bankAmount: payment.bank,
        creditAmount: payment.credit,
      );
      final db = await DatabaseHelper.instance.database;
      final invoice = (await invoices.getInvoiceWithItems(id))!;
      expect(invoice.totalAmount, 10001);
      expect(Money(invoice.totalAmount).formatted, 'Rs 100.01');
      expect(invoice.items.single.totalPrice, 10001);
      expect(await ItemsRepository().getProductStock(1), 44);
      final stock = (await db.query('stock_activities',
              where: 'ref_type = ? AND ref_id = ?', whereArgs: ['INVOICE', id]))
          .single;
      expect(stock['quantity_change'], -1);
      final cash = await db.query('cash_ledger',
          where: 'ref_type = ? AND ref_id = ?', whereArgs: ['INVOICE', id]);
      expect({
        for (final row in cash) row['payment_mode']: row['amount']
      }, {
        if (payment.cash > 0) 'CASH': payment.cash,
        if (payment.bank > 0) 'BANK': payment.bank,
      });
      expect(cash.every((row) => row['type'] == 'IN'), isTrue);
      final customer = await db.query('customer_ledger',
          where: 'customer_id = ? AND ref_type = ? AND ref_id = ?',
          whereArgs: [customerId, 'INVOICE', id]);
      expect(customer, hasLength(payment.credit > 0 ? 1 : 0));
      if (payment.credit > 0) {
        expect(customer.single['debit'], payment.credit);
        expect(customer.single['balance'], payment.credit);
      }
      expect(
          (await CustomersRepository().getCustomerById(customerId))!
              .outstandingBalance,
          payment.credit);

      await capture('${payment.name}-posted');

      await invoices.cancelInvoice(invoiceId: id, cancelledBy: 'TEST');
      expect(await ItemsRepository().getProductStock(1), 45);
      expect(
          (await CustomersRepository().getCustomerById(customerId))!
              .outstandingBalance,
          0);
      final stockReturn = await db.query('stock_activities',
          where: 'reversal_of_stock_activity_id = ?', whereArgs: [stock['id']]);
      expect(stockReturn, hasLength(1));
      expect(stockReturn.single['quantity_change'], 1);
      for (final original in cash) {
        final reversal = await db.query('cash_ledger',
            where: 'reversal_of_cash_ledger_id = ?',
            whereArgs: [original['id']]);
        expect(reversal, hasLength(1));
        expect(reversal.single['type'], 'OUT');
        expect(reversal.single['amount'], original['amount']);
        expect(reversal.single['payment_mode'], original['payment_mode']);
      }
      if (payment.credit > 0) {
        final reversal = await db.query('customer_ledger',
            where: 'reversal_of_customer_ledger_id = ?',
            whereArgs: [customer.single['id']]);
        expect(reversal, hasLength(1));
        expect(reversal.single['credit'], payment.credit);
      }
      final after = await snapshot();
      await expectLater(
          invoices.cancelInvoice(invoiceId: id, cancelledBy: 'TEST'),
          errorCode('INVOICE_NOT_FOUND'));
      expect(await snapshot(), after);
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      await capture('${payment.name}-cancelled');
    });
  }

  for (final invalid in [
    (
      name: 'walk-in credit',
      walkIn: true,
      cash: 0,
      credit: 10001,
      code: 'WALK_IN_CREDIT_NOT_ALLOWED'
    ),
    (
      name: 'walk-in underpayment',
      walkIn: true,
      cash: 10000,
      credit: 0,
      code: 'PAYMENT_SPLIT_MISMATCH'
    ),
    (
      name: 'named customer overpayment',
      walkIn: false,
      cash: 10002,
      credit: 0,
      code: 'PAYMENT_SPLIT_MISMATCH'
    ),
    (
      name: 'negative payment',
      walkIn: false,
      cash: -1,
      credit: 10002,
      code: 'PAYMENT_NEGATIVE'
    ),
    (
      name: 'credit limit exceeded',
      walkIn: false,
      cash: 0,
      credit: 100001,
      code: 'CREDIT_LIMIT_EXCEEDED'
    ),
  ]) {
    test('${invalid.name} preserves every persisted row', () async {
      final before = await snapshot();
      final total = invalid.code == 'CREDIT_LIMIT_EXCEEDED' ? 100001 : 10001;
      await expectLater(
          invoices.createInvoiceWithTransaction(
              customerId: invalid.walkIn ? 1 : customerId,
              items: items(total: total),
              grandTotal: total,
              cashAmount: invalid.cash,
              creditAmount: invalid.credit),
          errorCode(invalid.code));
      expect(await snapshot(), before);
    });
  }

  test(
      'discounted invoice preserves exact subtotal, discount and displayed total',
      () async {
    final id = await invoices.createInvoiceWithTransaction(
        customerId: customerId,
        items: items(),
        grandTotal: 9876,
        discount: 125,
        cashAmount: 9876);
    final db = await DatabaseHelper.instance.database;
    final saved =
        (await db.query('invoices', where: 'id = ?', whereArgs: [id])).single;
    expect(saved['sub_total'], 10001);
    expect(saved['discount_total'], 125);
    expect(saved['grand_total'], 9876);
    final invoice = (await invoices.getInvoiceWithItems(id))!;
    expect(invoice.isMathematicallyValid, isTrue);
    expect(Money(invoice.totalAmount).formatted, 'Rs 98.76');
    expect((await db.query('cash_ledger')).single['amount'], 9876);
  });

  test('incorrect invoice math preserves every persisted row', () async {
    final before = await snapshot();
    await expectLater(
        invoices.createInvoiceWithTransaction(
            customerId: customerId,
            items: items(),
            grandTotal: 10000,
            cashAmount: 10000),
        errorCode('INVOICE_MATH_ERROR'));
    expect(await snapshot(), before);
  });

  test('competing checkouts cannot oversell the same stock', () async {
    await setTestStock(1, 10);
    Future<Object> checkout() async {
      try {
        return await invoices.createInvoiceWithTransaction(
            customerId: 1,
            items: items(quantity: 6, total: 60006),
            grandTotal: 60006,
            cashAmount: 60006);
      } catch (error) {
        return error;
      }
    }

    final outcomes = await Future.wait([checkout(), checkout()]);
    expect(outcomes.whereType<int>(), hasLength(1));
    expect(outcomes.whereType<Exception>().single.toString(),
        contains('INSUFFICIENT_STOCK'));
    final db = await DatabaseHelper.instance.database;
    expect(await ItemsRepository().getProductStock(1), 4);
    expect(await db.query('invoices'), hasLength(1));
    expect(await db.query('invoice_items'), hasLength(1));
    expect((await db.query('cash_ledger')).single['amount'], 60006);
    final stock = await db.rawQuery(
        'SELECT SUM(quantity_change) AS total FROM stock_activities WHERE product_id = 1');
    expect(stock.single['total'], 4);
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });

  test('competing cancellations produce exactly one reversal', () async {
    final id = await invoices.createInvoiceWithTransaction(
        customerId: customerId,
        items: items(),
        grandTotal: 10001,
        creditAmount: 10001);
    Future<Object> cancel() async {
      try {
        await invoices.cancelInvoice(invoiceId: id, cancelledBy: 'TEST');
        return true;
      } catch (error) {
        return error;
      }
    }

    final outcomes = await Future.wait([cancel(), cancel()]);
    expect(outcomes.whereType<bool>(), [true]);
    expect(outcomes.whereType<Exception>().single.toString(),
        contains('INVOICE_NOT_FOUND'));
    final db = await DatabaseHelper.instance.database;
    expect(await ItemsRepository().getProductStock(1), 45);
    expect(
        (await CustomersRepository().getCustomerById(customerId))!
            .outstandingBalance,
        0);
    expect(
        await db.query('stock_activities',
            where: 'ref_type = ? AND ref_id = ?', whereArgs: ['INVOICE', id]),
        hasLength(2));
    expect(
        await db.query('customer_ledger',
            where: 'customer_id = ?', whereArgs: [customerId]),
        hasLength(2));
  });

  test('later sale item failure rolls back earlier stock and header writes',
      () async {
    final before = await snapshot();
    await expectLater(
        invoices.createInvoiceWithTransaction(
            customerId: 1,
            items: [...items(), ...items(quantity: 46)],
            grandTotal: 20002,
            cashAmount: 20002),
        errorCode('INSUFFICIENT_STOCK'));
    expect(await snapshot(), before);
  });

  test('later purchase item failure rolls back earlier stock and header writes',
      () async {
    final before = await snapshot();
    await expectLater(
        purchases.createPurchaseWithTransaction(
            supplierId: 1,
            totalAmount: 20002,
            items: [
              {
                'product_id': 1,
                'quantity': 1,
                'cost_price': 10001,
                'total_amount': 10001
              },
              {
                'product_id': 999999,
                'quantity': 1,
                'cost_price': 10001,
                'total_amount': 10001
              },
            ]),
        throwsException);
    expect(await snapshot(), before);
  });

  test('purchase reversal links original events and preserves later payments',
      () async {
    final id = await purchases.createPurchaseWithTransaction(
        supplierId: 1,
        totalAmount: 10001,
        items: [
          {
            'product_id': 1,
            'quantity': 1,
            'cost_price': 10001,
            'total_amount': 10001
          },
        ]);
    final db = await DatabaseHelper.instance.database;
    final stock = (await db.query('stock_activities',
            where: 'ref_type = ? AND ref_id = ?', whereArgs: ['PURCHASE', id]))
        .single;
    final bill = (await db.query('supplier_ledger',
            where: 'ref_type = ? AND ref_id = ?', whereArgs: ['PURCHASE', id]))
        .single;
    expect(stock['quantity_change'], 1);
    expect(bill['debit'], 10001);
    expect(
        (await db.query('suppliers', where: 'id = 1'))
            .single['outstanding_balance'],
        10001);
    await SuppliersRepository().addPayment(1, 3333, 'Partial settlement');
    final paymentCash = await db.query('cash_ledger');
    expect(paymentCash.single['amount'], 3333);
    expect(paymentCash.single['type'], 'OUT');
    await purchases.cancelPurchase(purchaseId: id, cancelledBy: 'TEST');
    expect(await ItemsRepository().getProductStock(1), 45);
    expect(
        (await db.query('suppliers', where: 'id = 1'))
            .single['outstanding_balance'],
        -3333);
    final reversal = (await db.query('supplier_ledger',
            where: 'reversal_of_supplier_ledger_id = ?',
            whereArgs: [bill['id']]))
        .single;
    expect(reversal['credit'], 10001);
    expect(reversal['balance'], -3333);
    expect(
        (await db.query('stock_activities',
                where: 'reversal_of_stock_activity_id = ?',
                whereArgs: [stock['id']]))
            .single['quantity_change'],
        -1);
    expect(await db.query('cash_ledger'), paymentCash);
    final after = await snapshot();
    await expectLater(
        purchases.cancelPurchase(purchaseId: id, cancelledBy: 'TEST'),
        errorCode('PURCHASE_NOT_FOUND'));
    expect(await snapshot(), after);
  });

  for (final mode in ['CASH', 'BANK']) {
    test('$mode customer payment atomically records exact paisas', () async {
      await invoices.createInvoiceWithTransaction(
          customerId: customerId,
          items: items(),
          grandTotal: 10001,
          creditAmount: 10001);
      final receiptId = await CustomersRepository().addPayment(
          customerId, 3333, '2026-10-04T12:00:00Z', 'Partial payment',
          paymentMode: mode);
      final db = await DatabaseHelper.instance.database;
      final receipt =
          (await db.query('receipts', where: 'id = ?', whereArgs: [receiptId]))
              .single;
      expect(receipt['amount'], 3333);
      expect(receipt['payment_mode'], mode);
      final ledger = (await db.query('customer_ledger',
              where: 'ref_type = ? AND ref_id = ?',
              whereArgs: ['RECEIPT', receiptId]))
          .single;
      expect(ledger['credit'], 3333);
      expect(ledger['balance'], 6668);
      expect(
          (await CustomersRepository().getCustomerById(customerId))!
              .outstandingBalance,
          6668);
      final cash = (await db.query('cash_ledger',
              where: 'ref_type = ? AND ref_id = ?',
              whereArgs: ['CUSTOMER_RECEIPT', receiptId]))
          .single;
      expect(cash['amount'], 3333);
      expect(cash['type'], 'IN');
      expect(cash['payment_mode'], mode);
    });
  }

  test('invalid customer and supplier payments preserve every row', () async {
    final before = await snapshot();
    for (final amount in [0, -1]) {
      await expectLater(
          CustomersRepository()
              .addPayment(customerId, amount, '2026-10-04', 'Invalid'),
          throwsArgumentError);
      await expectLater(SuppliersRepository().addPayment(1, amount, 'Invalid'),
          throwsArgumentError);
      expect(await snapshot(), before);
    }
  });

  for (final command in [
    'sale',
    'purchase',
    'customer payment',
    'supplier payment'
  ]) {
    test('$command final ledger failure rolls back all preceding writes',
        () async {
      final db = await DatabaseHelper.instance.database;
      final table = command == 'purchase' ? 'supplier_ledger' : 'cash_ledger';
      // Fault injection is confined to the disposable fixture. Failure occurs
      // after earlier header, item, stock or balance writes in the transaction.
      await db.execute('CREATE TRIGGER phase1_fail BEFORE INSERT ON $table '
          "BEGIN SELECT RAISE(ABORT, 'phase1 injected write failure'); END");
      final before = await snapshot();
      final Future<Object?> result;
      switch (command) {
        case 'sale':
          result = invoices.createInvoiceWithTransaction(
              customerId: customerId,
              items: items(),
              grandTotal: 10001,
              cashAmount: 5000,
              creditAmount: 5001);
        case 'purchase':
          result = purchases.createPurchaseWithTransaction(
              supplierId: 1,
              totalAmount: 10001,
              items: [
                {
                  'product_id': 1,
                  'quantity': 1,
                  'cost_price': 10001,
                  'total_amount': 10001
                },
              ]);
        case 'customer payment':
          result = CustomersRepository()
              .addPayment(customerId, 3333, '2026-10-04', 'Failure injection');
        default:
          result =
              SuppliersRepository().addPayment(1, 3333, 'Failure injection');
      }
      await expectLater(result, throwsException);
      expect(await snapshot(), before);
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    });
  }

  for (final command in ['sale', 'purchase']) {
    test('$command reversal ledger failure preserves original completed event',
        () async {
      final id = command == 'sale'
          ? await invoices.createInvoiceWithTransaction(
              customerId: customerId,
              items: items(),
              grandTotal: 10001,
              cashAmount: 5000,
              creditAmount: 5001)
          : await purchases.createPurchaseWithTransaction(
              supplierId: 1,
              totalAmount: 10001,
              items: [
                  {
                    'product_id': 1,
                    'quantity': 1,
                    'cost_price': 10001,
                    'total_amount': 10001
                  },
                ]);
      final db = await DatabaseHelper.instance.database;
      final table = command == 'sale' ? 'cash_ledger' : 'supplier_ledger';
      await db.execute('CREATE TRIGGER phase1_fail BEFORE INSERT ON $table '
          "BEGIN SELECT RAISE(ABORT, 'phase1 injected reversal failure'); END");
      final before = await snapshot();
      await expectLater(
          command == 'sale'
              ? invoices.cancelInvoice(invoiceId: id, cancelledBy: 'TEST')
              : purchases.cancelPurchase(purchaseId: id, cancelledBy: 'TEST'),
          throwsException);
      expect(await snapshot(), before);
      await db.execute('DROP TRIGGER phase1_fail');
      // A failed reversal must remain retryable after the fault is removed.
      if (command == 'sale') {
        await invoices.cancelInvoice(invoiceId: id, cancelledBy: 'TEST');
      } else {
        await purchases.cancelPurchase(purchaseId: id, cancelledBy: 'TEST');
      }
      expect(await ItemsRepository().getProductStock(1), 45);
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    });
  }

  test('purchase cancellation rejects consumed stock without partial reversal',
      () async {
    await setTestStock(1, 0);
    final id = await purchases.createPurchaseWithTransaction(
        supplierId: 1,
        totalAmount: 10001,
        items: [
          {
            'product_id': 1,
            'quantity': 1,
            'cost_price': 10001,
            'total_amount': 10001
          },
        ]);
    await invoices.createInvoiceWithTransaction(
        customerId: 1, items: items(), grandTotal: 10001, cashAmount: 10001);
    final before = await snapshot();
    await expectLater(
        purchases.cancelPurchase(purchaseId: id, cancelledBy: 'TEST'),
        errorCode('NEGATIVE_STOCK'));
    expect(await snapshot(), before);
    expect(await ItemsRepository().getProductStock(1), 0);
  });
}
