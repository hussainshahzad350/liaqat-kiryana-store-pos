import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/core/repositories/purchase_repository.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/models/customer_model.dart';
import 'package:liaqat_store/screens/accounts/accounts_screen.dart';
import 'package:liaqat_store/screens/sales/sales_screen.dart';
import 'package:liaqat_store/screens/cash_ledger/cash_ledger_screen.dart';
import 'package:liaqat_store/screens/cash_ledger/dialogs/add_transaction_dialog.dart';
import 'package:liaqat_store/screens/customers/dialogs/receive_payment_dialog.dart';
import 'package:liaqat_store/screens/customers/widgets/customer_ledger_panel.dart';
import 'package:liaqat_store/screens/customers/widgets/customer_list.dart';
import 'package:liaqat_store/screens/customers/widgets/customer_list_tile.dart';
import 'package:liaqat_store/screens/stock/dialogs/cancel_activity_dialog.dart';
import 'package:liaqat_store/screens/stock/dialogs/adjust_stock_dialog.dart';
import 'package:liaqat_store/screens/stock/stock_screen.dart';
import 'package:liaqat_store/screens/stock/widgets/activity_detail_panel_widget.dart';
import 'package:liaqat_store/screens/stock/widgets/recent_activities_table_widget.dart';
import 'package:liaqat_store/screens/stock/widgets/stock_table_widget.dart';
import 'package:liaqat_store/widgets/app_navigation_sidebar.dart';
import 'package:liaqat_store/widgets/app_shell.dart';

import 'support/desktop_fixture.dart';

Future<void> openWorkflow(
    WidgetTester tester, String label, Type screen) async {
  await tester.tap(find.descendant(
      of: find.byType(AppNavigationSidebar), matching: find.text(label)));
  await settleDesktop(tester);
  expect(find.byType(screen), findsOneWidget);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  for (final language in ['en', 'ur']) {
    testWidgets('$language customer payment validation', (tester) async {
      await withDesktopFixture(tester, (_) async {
        final id = await CustomersRepository().addCustomer(Customer(
            nameEnglish: 'Desktop Payment Customer',
            outstandingBalance: 30000,
            creditLimit: 1000000));
        await loginDesktop(tester);
        app.LiaqatStoreApp.setLocale(
            tester.element(find.byType(AppShell)), Locale(language));
        await settleDesktop(tester);
        final loc = AppLocalizations.of(tester.element(find.byType(AppShell)))!;
        await openWorkflow(tester, loc.accounts, AccountsScreen);
        final tile = find.ancestor(
            of: find.text('Desktop Payment Customer'),
            matching: find.byType(CustomerListTile));
        await tester.scrollUntilVisible(
            find.text('Desktop Payment Customer'), 120,
            scrollable: find
                .descendant(
                    of: find.byType(CustomerList),
                    matching: find.byType(Scrollable))
                .first);
        await settleDesktop(tester);
        await tester.tap(find.descendant(
            of: tile, matching: find.byTooltip(loc.viewLedgerTooltip)));
        await settleDesktop(tester);
        expect(find.byType(CustomerLedgerPanel), findsOneWidget);
        final db = await DatabaseHelper.instance.database;
        final ledgerBefore = await db.query('customer_ledger', orderBy: 'id');
        for (final payment in [100, 250]) {
          await tester.tap(
              find.widgetWithText(ElevatedButton, loc.receivePaymentButton));
          await settleDesktop(tester);
          expect(find.byType(ReceivePaymentDialog), findsOneWidget);
          final amount = find
              .descendant(
                  of: find.byType(ReceivePaymentDialog),
                  matching: find.byType(TextField))
              .first;
          final save = find.descendant(
              of: find.byType(ReceivePaymentDialog),
              matching: find.widgetWithText(ElevatedButton, loc.save));
          if (payment == 100) {
            await tester.enterText(amount, '0');
            await tester.tap(save);
            await settleDesktop(tester);
            expect(find.text(loc.invalidAmount), findsOneWidget);
            expect(await db.query('receipts'), isEmpty);
            expect(await db.query('cash_ledger'), isEmpty);
            expect(
                await db.query('customer_ledger', orderBy: 'id'), ledgerBefore);
            await tester.pump(const Duration(seconds: 5));
            await settleDesktop(tester);
          }
          await tester.enterText(amount, '$payment');
          await tester.tap(save);
          await settleDesktop(tester);
          expect(find.byType(ReceivePaymentDialog), findsNothing);
          final balance = payment == 100 ? 20000 : -5000;
          expect(
              (await db.query('customers', where: 'id = ?', whereArgs: [id]))
                  .single['outstanding_balance'],
              balance);
          final ledger = (await db.query('customer_ledger',
                  where: 'customer_id = ?', whereArgs: [id], orderBy: 'id'))
              .last;
          expect(ledger['credit'], payment * 100);
          expect(ledger['balance'], balance);
          final cash = (await db.query('cash_ledger', orderBy: 'id')).last;
          expect(cash['type'], 'IN');
          expect(cash['amount'], payment * 100);
          expect(cash['ref_type'], 'CUSTOMER_RECEIPT');
        }
        expect(await db.query('receipts'), hasLength(2));
        expect(
            (await db.query('cash_ledger', orderBy: 'id'))
                .last['balance_after'],
            35000);
        expect((await db.query('products')).single['current_stock'], 45);
      });
    });
  }

  testWidgets('purchase cancellation from stock activity reverses once',
      (tester) async {
    await withDesktopFixture(tester, (_) async {
      final db = await DatabaseHelper.instance.database;
      final previousBalance =
          (await db.query('suppliers')).single['outstanding_balance'];
      final purchaseId = await PurchaseRepository(ItemsRepository())
          .createPurchaseWithTransaction(
              supplierId: 1,
              totalAmount: 30000,
              invoiceNumber: 'DESKTOP-CANCEL-001',
              items: [
            {
              'product_id': 1,
              'quantity': 2.0,
              'cost_price': 15000,
              'total_amount': 30000
            }
          ]);
      await loginDesktop(tester);
      final loc = AppLocalizations.of(tester.element(find.byType(AppShell)))!;
      await openWorkflow(tester, loc.productsAndStock, StockScreen);
      final activity = find.descendant(
          of: find.byType(RecentActivitiesTableWidget),
          matching: find.text('PURCHASE #$purchaseId'));
        await tester.tap(find.widgetWithText(ExpansionTile, loc.recentActivities));
        await settleDesktop(tester);
      final row =
          find.ancestor(of: activity, matching: find.byType(Table)).first;
      // The purchase is newest; its visibility action is the first data row.
      final view = find
          .descendant(of: row, matching: find.byIcon(Icons.visibility))
          .first;
      await tester.ensureVisible(view);
      await settleDesktop(tester);
      await tester.tap(view);
      await settleDesktop(tester);
      expect(find.byType(ActivityDetailPanelWidget), findsOneWidget);
      final cancel = find.descendant(
          of: find.byType(ActivityDetailPanelWidget),
          matching: find.widgetWithText(OutlinedButton, loc.cancel));
      await tester.scrollUntilVisible(cancel, 150,
          scrollable: find
              .descendant(
                  of: find.byType(ActivityDetailPanelWidget),
                  matching: find.byType(Scrollable))
              .first);
      await settleDesktop(tester);
      await tester.tap(cancel);
      await settleDesktop(tester);
      expect(find.byType(CancelActivityDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, loc.no));
      await settleDesktop(tester);
      expect((await db.query('purchases')).single['status'], 'COMPLETED');
      expect((await db.query('products')).single['current_stock'], 47);
      await tester.tap(cancel);
      await settleDesktop(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, loc.yes));
      await settleDesktop(tester);
      expect((await db.query('purchases')).single['status'], 'CANCELLED');
      expect((await db.query('products')).single['current_stock'], 45);
      expect((await db.query('suppliers')).single['outstanding_balance'],
          previousBalance);
      expect(await db.query('cash_ledger'), isEmpty);
      final events = await db.query('stock_activities', orderBy: 'id');
      final ledger = await db.query('supplier_ledger', orderBy: 'id');
      expect(events.where((e) => e['transaction_type'] == 'PURCHASE_CANCEL'),
          hasLength(1));
      await tester.pump(const Duration(seconds: 5));
      await settleDesktop(tester);
      expect(find.byType(ActivityDetailPanelWidget), findsNothing);
      // The new reversal is first; reopen the original purchase in row two.
      final originalView = find
          .descendant(of: row, matching: find.byIcon(Icons.visibility))
          .at(1);
      await tester.ensureVisible(originalView);
      await tester.tap(originalView);
      await settleDesktop(tester);
      expect(find.byType(ActivityDetailPanelWidget), findsOneWidget);
      expect(cancel, findsNothing);
      await expectLater(
          PurchaseRepository(ItemsRepository())
              .cancelPurchase(purchaseId: purchaseId, cancelledBy: 'TEST'),
          throwsA(isA<Exception>()));
      expect(await db.query('stock_activities', orderBy: 'id'), events);
      expect(await db.query('supplier_ledger', orderBy: 'id'), ledger);
    });
  });

  for (final language in ['en', 'ur']) {
    testWidgets('$language stock adjustment and cash ledger', (tester) async {
      await withDesktopFixture(tester, (_) async {
        await loginDesktop(tester);
        app.LiaqatStoreApp.setLocale(
            tester.element(find.byType(AppShell)), Locale(language));
        await settleDesktop(tester);
        final loc = AppLocalizations.of(tester.element(find.byType(AppShell)))!;
        final db = await DatabaseHelper.instance.database;
        final customersBefore = await db.query('customers', orderBy: 'id');
        final suppliersBefore = await db.query('suppliers', orderBy: 'id');
        await openWorkflow(tester, loc.productsAndStock, StockScreen);
        final eventsBefore = await db.query('stock_activities', orderBy: 'id');
        for (final quantity in [50, 43]) {
          final menu = find.descendant(
              of: find.byType(StockTableWidget),
              matching: find.byIcon(Icons.more_vert));
          await tester.ensureVisible(menu);
          await tester.tap(menu);
          await settleDesktop(tester);
          await tester.tap(find.text(loc.adjustStock));
          await settleDesktop(tester);
          final fields = find.descendant(
              of: find.byType(AdjustStockDialog),
              matching: find.byType(TextFormField));
          final save = find.descendant(
              of: find.byType(AdjustStockDialog),
              matching: find.widgetWithText(ElevatedButton, loc.save));
          if (quantity == 50) {
            await tester.enterText(fields.first, 'invalid');
            await tester.tap(save);
            await settleDesktop(tester);
            expect(find.text(loc.invalidAmount), findsOneWidget);
            expect(await db.query('stock_activities', orderBy: 'id'),
                eventsBefore);
          }
          await tester.enterText(fields.first, '$quantity');
          await tester.enterText(fields.at(1), 'Desktop stock count $quantity');
          await tester.tap(save);
          await settleDesktop(tester);
          expect(find.byType(AdjustStockDialog), findsNothing);
          expect(
              (await db.query('products')).single['current_stock'], quantity);
          final events = await db.query('stock_activities', orderBy: 'id');
          expect(events.last['quantity_change'], quantity == 50 ? 5 : -7);
          await tester.pump(const Duration(seconds: 5));
          await settleDesktop(tester);
        }
        expect(await db.query('cash_ledger'), isEmpty);
        await openWorkflow(
            tester,
            loc.salesPos,
            // The sales cash snapshot is the cash-ledger entry point.
            SalesScreen);
        await tester.tap(find.text('${loc.cashSnapshot}: '));
        await settleDesktop(tester);
        expect(find.byType(CashLedgerScreen), findsOneWidget);
        for (final cashIn in [true, false]) {
          await tester.tap(find.widgetWithText(
              ElevatedButton, cashIn ? loc.cashIn : loc.cashOut));
          await settleDesktop(tester);
          final fields = find.descendant(
              of: find.byType(AddTransactionDialog),
              matching: find.byType(TextField));
          final save = find.descendant(
              of: find.byType(AddTransactionDialog),
              matching: find.widgetWithText(ElevatedButton, loc.save));
          await tester.enterText(
              fields.at(1), cashIn ? 'Desktop cash in' : 'Desktop cash out');
          if (cashIn) {
            await tester.enterText(fields.first, '0');
            await tester.tap(save);
            await settleDesktop(tester);
            expect(find.text(loc.invalidAmount), findsOneWidget);
            expect(await db.query('cash_ledger'), isEmpty);
            await tester.pump(const Duration(seconds: 5));
            await settleDesktop(tester);
          }
          await tester.enterText(fields.first, cashIn ? '100.25' : '20.10');
          await tester.tap(save);
          await settleDesktop(tester);
          expect(find.byType(AddTransactionDialog), findsNothing);
          final entry = (await db.query('cash_ledger', orderBy: 'id')).last;
          expect(entry['type'], cashIn ? 'IN' : 'OUT');
          expect(entry['amount'], cashIn ? 10025 : 2010);
          expect(entry['balance_after'], cashIn ? 10025 : 8015);
        }
        expect(await db.query('cash_ledger'), hasLength(2));
        expect(await db.query('customers', orderBy: 'id'), customersBefore);
        expect(await db.query('suppliers', orderBy: 'id'), suppliersBefore);
        expect((await db.query('products')).single['current_stock'], 43);
        expect(await db.query('invoices'), isEmpty);
        expect(await db.query('purchases'), isEmpty);
      });
    });
  }
}
