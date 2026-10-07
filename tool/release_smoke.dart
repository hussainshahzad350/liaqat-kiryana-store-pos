import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/core/repositories/invoice_repository.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/core/repositories/suppliers_repository.dart';
import 'package:liaqat_store/core/repositories/purchase_repository.dart';
import 'package:liaqat_store/core/repositories/settings_repository.dart';
import 'package:liaqat_store/core/repositories/stock_repository.dart';
import 'package:liaqat_store/core/repositories/cash_repository.dart';
import 'package:liaqat_store/core/services/pin_auth_service.dart';
import 'package:liaqat_store/domain/entities/money.dart';
import 'package:liaqat_store/models/customer_model.dart';
import 'package:liaqat_store/models/supplier_model.dart';
import 'package:liaqat_store/screens/auth/login_screen.dart';
import 'package:liaqat_store/screens/sales/widgets/product_card.dart';
import 'package:liaqat_store/screens/sales/widgets/sales_product_panel.dart';
import 'package:liaqat_store/screens/sales/widgets/cart_item_row.dart';
import 'package:liaqat_store/screens/sales/widgets/sales_totals_section.dart';
import 'package:liaqat_store/screens/sales/dialogs/checkout_payment_dialog.dart';
import 'package:liaqat_store/screens/sales/dialogs/post_sale_dialog.dart';
import '../test/support/large_store_fixture.dart';

/// Callback-driven AOT smoke harness; checks do not rely on release assertions.
void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> rejected(Future<void> Function() action, String code) async {
  try {
    await action();
  } catch (error) {
    check(error.toString().contains(code), 'Unexpected rejection: $error');
    return;
  }
  throw StateError('Expected rejection: $code');
}

List<Element> elements<T extends Widget>([Element? start]) {
  final result = <Element>[];
  void visit(Element element) {
    if (element.widget is Offstage && (element.widget as Offstage).offstage) {
      return;
    }
    if (element.widget is T) result.add(element);
    element.visitChildren(visit);
  }

  final root = start ?? WidgetsBinding.instance.rootElement;
  if (root != null) visit(root);
  return result;
}

Future<void> waitFor(bool Function() ready) async {
  final timeout = Stopwatch()..start();
  while (!ready()) {
    if (timeout.elapsed > const Duration(seconds: 30)) {
      throw StateError('Native UI did not reach expected state');
    }
    WidgetsBinding.instance.scheduleFrame();
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  WidgetsBinding.instance.scheduleFrame();
  await WidgetsBinding.instance.endOfFrame;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final report = <String, Object>{'releaseMode': kReleaseMode};
  final output = File('build/cleanup-phase5-review/release-smoke.json');
  Directory? directory;
  var code = 0;
  try {
    check(kReleaseMode, 'This target must be compiled in release mode');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    directory = await Directory.systemTemp.createTemp('liaqat_phase5_release_');
    await databaseFactory.setDatabasesPath(directory.path);
    initializeVerificationPreferences();
    await PinAuthService().setupPin('2468');
    var db = await DatabaseHelper.instance.database;
    check(db.path.startsWith(directory.path),
        'Database escaped isolated directory');
    await seedLargeStore(db);
    final items = ItemsRepository();
    final invoices = InvoiceRepository(items);
    Future<int> post(
            {int customer = 1,
            int cash = 18000,
            int bank = 0,
            int credit = 0}) =>
        invoices.createInvoiceWithTransaction(
            customerId: customer,
            items: [
              {
                'product_id': 1,
                'name_english': 'Synthetic rice',
                'quantity': 1.0,
                'unit_price': 18000,
                'total': 18000
              }
            ],
            grandTotal: 18000,
            cashAmount: cash,
            bankAmount: bank,
            creditAmount: credit);
    Future<void> cancel(int id) => invoices.cancelInvoice(
        invoiceId: id,
        cancelledBy: 'phase5-fixture',
        reason: 'Synthetic verification');
    for (var index = 0; index < 50; index++) {
      await cancel(await post());
    }
    final source = File('${directory.path}/synthetic-source.db');
    await db.execute('VACUUM INTO ?', [source.path]);
    final sourceHash = sha256.convert(await source.readAsBytes()).toString();
    final dbPath = db.path;
    await DatabaseHelper.instance.close();
    await source.copy(dbPath);
    final boot = Stopwatch()..start();
    app.main();
    await waitFor(() => elements<LoginScreen>().isNotEmpty);
    report['startupToLoginMs'] = boot.elapsedMicroseconds / 1000;
    final pin = elements<TextField>(elements<LoginScreen>().single).first.widget
        as TextField;
    pin.controller!.text = '2468';
    pin.onSubmitted!('2468');
    await waitFor(() => elements<ProductCard>().isNotEmpty);
    final search = elements<TextField>(elements<SalesProductPanel>().single)
        .first
        .widget as TextField;
    final seedName = (await (await DatabaseHelper.instance.database)
            .query('products', where: 'id = 1'))
        .single['name_english'] as String;
    search.controller!.text = seedName;
    search.onChanged!(seedName);
    await waitFor(() => elements<ProductCard>()
        .any((e) => (e.widget as ProductCard).product.id == 1));
    final stocked = elements<ProductCard>()
        .map((e) => e.widget as ProductCard)
        .where((card) => card.product.id == 1);
    check(stocked.isNotEmpty, 'Seeded stocked product is not visible');
    stocked.single.onTap();
    await waitFor(() => elements<CartItemRow>().isNotEmpty);
    final checkout = Stopwatch()..start();
    (elements<SalesTotalsSection>().single.widget as SalesTotalsSection)
        .onCheckout();
    await waitFor(() => elements<CheckoutPaymentDialog>().isNotEmpty);
    final dialog = elements<CheckoutPaymentDialog>().single;
    (elements<TextButton>(dialog)
            .singleWhere((e) =>
                e.widget.key ==
                const ValueKey('checkout-other-payment-options'))
            .widget as TextButton)
        .onPressed!();
    await waitFor(() => elements<TextField>(dialog).isNotEmpty);
    final fields = elements<TextField>(dialog);
    for (var index = 0; index < fields.length; index++) {
      final field = fields[index].widget as TextField;
      field.controller!.text = index == 0 ? '180' : '0';
      field.onChanged?.call(field.controller!.text);
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final save = elements<ElevatedButton>(dialog)
        .map((e) => e.widget as ElevatedButton)
        .where((button) => button.onPressed != null)
        .single;
    save.onPressed!();
    await waitFor(() => elements<PostSaleDialog>().isNotEmpty);
    report['nativeCheckoutMs'] = checkout.elapsedMicroseconds / 1000;
    db = await DatabaseHelper.instance.database;
    final posted =
        (await db.query('invoices', where: "status = 'COMPLETED'")).single;
    check(posted['grand_total'] == 18000, 'Release UI posted the wrong amount');
    runApp(const SizedBox.shrink());
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await cancel(posted['id'] as int);
    final timings = <String, List<double>>{};
    Future<void> measure(String name, Future<void> Function() action) async {
      await action();
      timings[name] = [];
      for (var index = 0; index < 7; index++) {
        final watch = Stopwatch()..start();
        await action();
        timings[name]!.add(watch.elapsedMicroseconds / 1000);
      }
    }

    await measure('catalogFirstPage', () async {
      check((await items.getCatalogProducts()).length == 20,
          'Catalog page is not bounded');
    });
    await measure('catalogSearch', () async {
      check(
          (await items.getCatalogProducts(query: 'Phase5 Product 09999'))
                  .length ==
              1,
          'Search lost its match');
    });
    await measure('catalogDeepPage', () async {
      check((await items.getCatalogProducts(offset: 9980)).length == 20,
          'Deep page mismatch');
    });
    await measure('stockPage', () async {
      check((await StockRepository().getStockItems(limit: 100)).length == 100,
          'Stock page is not bounded');
    });
    await measure('postAndCancel', () async {
      await cancel(await post());
    });
    final customerId = await CustomersRepository().addCustomer(
        Customer(nameEnglish: 'Release credit fixture', creditLimit: 1000000));
    for (final mode in [
      (18000, 0, 0),
      (0, 18000, 0),
      (0, 0, 18000),
      (6000, 4000, 8000)
    ]) {
      final id = await post(
          customer: customerId, cash: mode.$1, bank: mode.$2, credit: mode.$3);
      check(
          (await db.query('customers',
                      where: 'id = ?', whereArgs: [customerId]))
                  .single['outstanding_balance'] ==
              mode.$3,
          'Credit mismatch');
      await cancel(id);
      final beforeRepeat =
          jsonEncode(await db.query('stock_activities', orderBy: 'id'));
      await rejected(() => cancel(id), 'INVOICE_NOT_FOUND');
      check(
          jsonEncode(await db.query('stock_activities', orderBy: 'id')) ==
              beforeRepeat,
          'Duplicate sale reversal');
      check(
          (await db.query('customers',
                      where: 'id = ?', whereArgs: [customerId]))
                  .single['outstanding_balance'] ==
              0,
          'Cancellation mismatch');
    }
    await CustomersRepository().addPayment(
        customerId, 100, DateTime.now().toIso8601String(), 'Release');
    final suppliers = SuppliersRepository();
    final supplierId = await suppliers
        .addSupplier(Supplier(nameEnglish: 'Release supplier').toMap());
    final purchases = PurchaseRepository(items);
    final purchaseId = await purchases.createPurchaseWithTransaction(
        supplierId: supplierId,
        items: [
          {
            'product_id': 1,
            'quantity': 2.0,
            'cost_price': 12000,
            'total_amount': 24000
          }
        ],
        totalAmount: 24000);
    await purchases.cancelPurchase(
        purchaseId: purchaseId, cancelledBy: 'phase5-fixture');
    final beforeRepeatPurchase =
        jsonEncode(await db.query('stock_activities', orderBy: 'id'));
    await rejected(
        () => purchases.cancelPurchase(
            purchaseId: purchaseId, cancelledBy: 'phase5-fixture'),
        'PURCHASE_NOT_FOUND');
    check(
        jsonEncode(await db.query('stock_activities', orderBy: 'id')) ==
            beforeRepeatPurchase,
        'Duplicate purchase reversal');
    await suppliers.addPayment(supplierId, 100, 'Release');
    check(
        (await db.query('customers', where: 'id = ?', whereArgs: [customerId]))
                .single['outstanding_balance'] ==
            -100,
        'Customer payment mismatch');
    check(
        (await db.query('suppliers', where: 'id = ?', whereArgs: [supplierId]))
                .single['outstanding_balance'] ==
            -100,
        'Supplier payment mismatch');
    await items.adjustStock(1, 2, reason: 'Release');
    await items.adjustStock(1, -2, reason: 'Release');
    await CashRepository().addCashIn('Release', const Money(100));
    await CashRepository().addCashOut('Release', const Money(100));
    check(
        (await db.rawQuery(
                    "SELECT COALESCE(SUM(CASE WHEN type='IN' THEN amount ELSE -amount END), 0) AS n FROM cash_ledger"))
                .single['n'] ==
            0,
        'Cash reversals/payment flow mismatch');
    check(
        (await db.query('products', where: 'id = 1')).single['current_stock'] ==
            45,
        'Stock mismatch');
    final settings = SettingsRepository();
    await measure('backup', () async {
      check(await settings.createManualBackup() != null, 'Backup failed');
    });
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name");
    Future<String> rows(Database database) async => jsonEncode({
          for (final table in tables)
            table['name'] as String:
                await database.query(table['name'] as String, orderBy: 'rowid')
        });
    final original = await rows(db);
    final backup = await settings.createManualBackup();
    await db
        .update('shop_profile', {'shop_name_english': 'Changed after backup'});
    check(await settings.restoreBackup(backup!), 'Restore failed');
    db = await DatabaseHelper.instance.database;
    check(await rows(db) == original, 'Restore changed saved rows');
    check(
        (await db.rawQuery('PRAGMA integrity_check')).single.values.single ==
            'ok',
        'Integrity failure');
    check((await db.rawQuery('PRAGMA foreign_key_check')).isEmpty,
        'Foreign key failure');
    check(sha256.convert(await source.readAsBytes()).toString() == sourceHash,
        'Synthetic source changed');
    report.addAll({
      'timingsMs': timings,
      'products': (await db.rawQuery('SELECT COUNT(*) AS n FROM products'))
          .single['n']!,
      'customers': (await db.rawQuery('SELECT COUNT(*) AS n FROM customers'))
          .single['n']!,
      'sourceBytes': await source.length(),
      'sourceHashUnchanged': true,
      'checks':
          'native PIN/cash checkout; four payment/reversal modes; customer/supplier payments; purchase/reversal; stock adjustment; cash in/out; all-table backup/restore; integrity',
      'passed': true
    });
  } catch (error, stack) {
    code = 1;
    report.addAll({
      'passed': false,
      'error': error.toString(),
      'stack': stack.toString()
    });
  } finally {
    await DatabaseHelper.instance.close();
    if (directory != null) await directory.delete(recursive: true);
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(report)}\n');
    exit(code);
  }
}
