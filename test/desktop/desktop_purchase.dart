import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/screens/accounts/accounts_screen.dart';
import 'package:liaqat_store/screens/purchase/dialogs/add_purchase_item_dialog.dart';
import 'package:liaqat_store/screens/purchase/dialogs/supplier_selector_dialog.dart';
import 'package:liaqat_store/screens/purchase/purchase_screen.dart';
import 'package:liaqat_store/screens/purchase/widgets/purchase_cart_widget.dart';
import 'package:liaqat_store/screens/purchase/widgets/purchase_item_list_widget.dart';
import 'package:liaqat_store/screens/sales/sales_screen.dart';
import 'package:liaqat_store/screens/settings/settings_screen.dart';
import 'package:liaqat_store/screens/stock/stock_screen.dart';
import 'package:liaqat_store/screens/suppliers/dialogs/receive_supplier_payment_dialog.dart';
import 'package:liaqat_store/screens/suppliers/widgets/supplier_ledger_panel.dart';
import 'package:liaqat_store/screens/suppliers/widgets/supplier_list_tile.dart';
import 'package:liaqat_store/widgets/app_navigation_sidebar.dart';
import 'package:liaqat_store/widgets/app_shell.dart';

import 'support/desktop_fixture.dart';

Future<void> navigateDesktop(
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
    testWidgets('$language sidebar navigation and account tabs',
        (tester) async {
      await withDesktopFixture(tester, (_) async {
        await loginDesktop(tester);
        app.LiaqatStoreApp.setLocale(
            tester.element(find.byType(AppShell)), Locale(language));
        await settleDesktop(tester);
        final loc = AppLocalizations.of(tester.element(find.byType(AppShell)))!;
        expect(
            Localizations.localeOf(tester.element(find.byType(AppShell)))
                .languageCode,
            language);
        await navigateDesktop(tester, loc.productsAndStock, StockScreen);
        await navigateDesktop(tester, loc.accounts, AccountsScreen);
        await tester.tap(find.widgetWithText(Tab, loc.suppliers));
        await settleDesktop(tester);
        await tester.tap(find.widgetWithText(Tab, loc.customers));
        await settleDesktop(tester);
        await navigateDesktop(tester, loc.settings, SettingsScreen);
        await navigateDesktop(tester, loc.purchase, PurchaseScreen);
        await navigateDesktop(tester, loc.salesPos, SalesScreen);
        expect(Directionality.of(tester.element(find.byType(SalesScreen))),
            language == 'ur' ? TextDirection.rtl : TextDirection.ltr);
        final db = await DatabaseHelper.instance.database;
        expect(await db.query('invoices'), isEmpty);
        expect(await db.query('purchases'), isEmpty);
      });
    });
  }

  testWidgets('purchase validation, supplier payment and persisted effects',
      (tester) async {
    await withDesktopFixture(tester, (_) async {
      await loginDesktop(tester);
      final loc = AppLocalizations.of(tester.element(find.byType(AppShell)))!;
      await navigateDesktop(tester, loc.purchase, PurchaseScreen);
      final db = await DatabaseHelper.instance.database;
      final supplier = (await db.query('suppliers')).single;
      final previousBalance = supplier['outstanding_balance'] as int;
      await tester.tap(find.widgetWithText(ElevatedButton, loc.savePurchase));
      await settleDesktop(tester);
      expect(await db.query('purchases'), isEmpty);
      await tester.pump(const Duration(seconds: 5));
      await settleDesktop(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, loc.selectSupplier));
      await settleDesktop(tester);
      expect(find.byType(SupplierSelectorDialog), findsOneWidget);
      await tester.tap(find.descendant(
          of: find.byType(SupplierSelectorDialog),
          matching: find.text(supplier['name_english'] as String)));
      await settleDesktop(tester);
      await tester.tap(find
          .descendant(
              of: find.byType(PurchaseItemListWidget),
              matching: find.byType(ListTile))
          .first);
      await settleDesktop(tester);
      expect(find.byType(AddPurchaseItemDialog), findsOneWidget);
      final fields = find.descendant(
          of: find.byType(AddPurchaseItemDialog),
          matching: find.byType(TextFormField));
      await tester.enterText(fields.at(0), '0');
      await tester.tap(find.widgetWithText(ElevatedButton, loc.addItemToBill));
      await settleDesktop(tester);
      expect(find.text(loc.invalidQuantity), findsOneWidget);
      expect(await db.query('purchases'), isEmpty);
      await tester.enterText(fields.at(0), '2');
      await tester.enterText(fields.at(1), '150');
      await tester.tap(find.widgetWithText(ElevatedButton, loc.addItemToBill));
      await settleDesktop(tester);
      expect(find.byType(AddPurchaseItemDialog), findsNothing);
      final invoice = find
          .descendant(
              of: find.byType(PurchaseCartWidget),
              matching: find.byType(TextField))
          .first;
      await tester.enterText(invoice, 'DESKTOP-PURCHASE-001');
      await tester.tap(find.widgetWithText(ElevatedButton, loc.savePurchase));
      await settleDesktop(tester);
      expect(find.text(loc.purchaseSavedSuccess), findsOneWidget);
      expect(await db.query('purchases'), hasLength(1));
      expect((await db.query('purchase_items')).single['quantity'], 2);
      expect((await db.query('products')).single['current_stock'], 47);
      expect((await db.query('suppliers')).single['outstanding_balance'],
          previousBalance + 30000);
      expect((await db.query('supplier_ledger', orderBy: 'id')).last['debit'],
          30000);
      expect(await db.query('cash_ledger'), isEmpty);
      await navigateDesktop(tester, loc.accounts, AccountsScreen);
      await tester.tap(find.widgetWithText(Tab, loc.suppliers));
      await settleDesktop(tester);
      await tester.tap(find.descendant(
          of: find.byType(SupplierListTile),
          matching: find.byTooltip(loc.viewLedgerTooltip)));
      await settleDesktop(tester);
      expect(find.byType(SupplierLedgerPanel), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, loc.makePayment));
      await settleDesktop(tester);
      expect(find.byType(ReceiveSupplierPaymentDialog), findsOneWidget);
      final amount = find
          .descendant(
              of: find.byType(ReceiveSupplierPaymentDialog),
              matching: find.byType(TextField))
          .first;
      final save = find.descendant(
          of: find.byType(ReceiveSupplierPaymentDialog),
          matching: find.widgetWithText(ElevatedButton, loc.save));
      await tester.enterText(amount, '0');
      await tester.tap(save);
      await settleDesktop(tester);
      expect(await db.query('supplier_payments'), isEmpty);
      expect(await db.query('cash_ledger'), isEmpty);
      expect((await db.query('suppliers')).single['outstanding_balance'],
          previousBalance + 30000);
      await tester.pump(const Duration(seconds: 5));
      await settleDesktop(tester);
      await tester.enterText(amount, '100');
      await tester.tap(save);
      await settleDesktop(tester);
      expect(find.byType(ReceiveSupplierPaymentDialog), findsNothing);
      expect((await db.query('supplier_payments')).single['amount'], 10000);
      expect((await db.query('suppliers')).single['outstanding_balance'],
          previousBalance + 20000);
      final ledger = (await db.query('supplier_ledger', orderBy: 'id')).last;
      expect(ledger['credit'], 10000);
      expect(ledger['balance'], previousBalance + 20000);
      final cash = (await db.query('cash_ledger')).single;
      expect(cash['type'], 'OUT');
      expect(cash['amount'], 10000);
      expect(cash['balance_after'], -10000);
      expect(cash['ref_type'], 'SUPPLIER_PAYMENT');
      expect((await db.query('products')).single['current_stock'], 47);
      expect(await db.query('purchases'), hasLength(1));
    });
  });
}
