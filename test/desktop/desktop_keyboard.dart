import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/models/customer_model.dart';
import 'package:liaqat_store/screens/sales/dialogs/add_customer_dialog.dart';
import 'package:liaqat_store/screens/sales/dialogs/checkout_payment_dialog.dart';
import 'package:liaqat_store/screens/sales/dialogs/clear_cart_dialog.dart';
import 'package:liaqat_store/screens/sales/widgets/customer_section.dart';
import 'package:liaqat_store/screens/sales/widgets/product_card.dart';
import 'package:liaqat_store/screens/sales/widgets/sales_product_panel.dart';
import 'package:liaqat_store/screens/sales/widgets/cart_item_row.dart';
import 'package:liaqat_store/screens/sales/widgets/sales_totals_section.dart';
import 'package:liaqat_store/screens/sales/dialogs/post_sale_dialog.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/widgets/app_navigation_sidebar.dart';
import 'package:liaqat_store/screens/stock/stock_screen.dart';
import 'package:liaqat_store/screens/accounts/accounts_screen.dart';
import 'package:liaqat_store/screens/purchase/purchase_screen.dart';
import 'package:liaqat_store/screens/settings/settings_screen.dart';
import 'package:liaqat_store/screens/customers/customers_screen.dart';
import 'package:liaqat_store/screens/suppliers/suppliers_screen.dart';
import 'package:liaqat_store/screens/auth/login_screen.dart';
import 'package:liaqat_store/core/repositories/settings_repository.dart';
import 'package:liaqat_store/screens/settings/pages/backup_page.dart';
import 'package:liaqat_store/screens/sales/widgets/sales_kpi_header.dart';
import 'package:window_manager/window_manager.dart';
import 'package:liaqat_store/widgets/app_shell.dart';

import 'support/desktop_fixture.dart';

bool focusedWithin(Finder target) {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  final elements = target.evaluate().toSet();
  if (elements.contains(context)) return true;
  var found = false;
  context.visitAncestorElements((element) {
    if (elements.contains(element)) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

Future<void> tabTo(WidgetTester tester, Finder target,
    {bool reverse = false}) async {
  expect(target, findsOneWidget);
  for (var attempt = 0; attempt < 80; attempt++) {
    if (focusedWithin(target)) return;
    if (reverse) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    if (reverse) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await settleDesktop(tester);
  }
  debugDumpFocusTree();
  fail(
      'Tab traversal cannot reach $target; focus: ${FocusManager.instance.primaryFocus}');
}

Future<void> keyboardActivate(WidgetTester tester, Finder target) async {
  await tabTo(tester, target);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await settleDesktop(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final language in ['en', 'ur']) {
    testWidgets(
        '$language complete Tab checkout and navigation at minimum size',
        (tester) async {
      await withDesktopFixture(tester, (_) async {
        final customerId = await CustomersRepository().addCustomer(Customer(
            nameEnglish: 'Keyboard Complete',
            nameUrdu: 'کی بورڈ گاہک',
            creditLimit: 1000000));
        await loginDesktop(tester);
        app.LiaqatStoreApp.setLocale(
            tester.element(find.byType(AppShell)), Locale(language));
        await settleDesktop(tester);
        final originalSize = await windowManager.getSize();
        try {
          await windowManager.setSize(const Size(1024, 720));
          await settleDesktop(tester);
          final loc =
              AppLocalizations.of(tester.element(find.byType(AppShell)))!;
          final db = await DatabaseHelper.instance.database;
          final product = (await db.query('products')).single;
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await settleDesktop(tester);
          final search = find.descendant(
              of: find.byType(SalesProductPanel),
              matching: find.byType(TextField));
          expect(focusedWithin(search), isTrue);
          await keyboardActivate(
              tester,
              find.descendant(
                  of: find.byType(ProductCard).first,
                  matching: find.byType(InkWell)));
          expect(find.byType(CartItemRow), findsOneWidget);
          final customerSearch = find.descendant(
              of: find.byType(CustomerSection),
              matching: find.byType(TextField));
          await tabTo(tester, customerSearch);
          tester.testTextInput.enterText('Keyboard Complete');
          await tester.pump(const Duration(milliseconds: 500));
          await settleDesktop(tester);
          final customerTile = find.ancestor(
              of: find.text(
                  language == 'ur' ? 'کی بورڈ گاہک' : 'Keyboard Complete'),
              matching: find.byType(ListTile));
          await keyboardActivate(tester, customerTile);
          final cartFields = find.descendant(
              of: find.byType(CartItemRow), matching: find.byType(TextField));
          await tabTo(tester, cartFields.first);
          await tabTo(tester, cartFields.last);
          await tabTo(tester, cartFields.first, reverse: true);
          final totals = find.byType(SalesTotalsSection);
          await tabTo(tester,
              find.descendant(of: totals, matching: find.byType(TextField)));
          await keyboardActivate(
              tester,
              find.descendant(
                  of: totals, matching: find.byType(ElevatedButton)));
          expect(find.byType(CheckoutPaymentDialog), findsOneWidget);
          await keyboardActivate(tester,
              find.byKey(const ValueKey('checkout-other-payment-options')));
          final paymentFields = find.descendant(
              of: find.byType(CheckoutPaymentDialog),
              matching: find.byType(TextField));
          expect(paymentFields, findsNWidgets(3));
          await tabTo(tester, paymentFields.first);
          tester.testTextInput.enterText(
              ((product['sale_price'] as num) / 100).toStringAsFixed(2));
          await settleDesktop(tester);
          await tabTo(tester, paymentFields.at(1));
          await tabTo(tester, paymentFields.last);
          await tabTo(tester, paymentFields.at(1), reverse: true);
          final save = find.widgetWithText(ElevatedButton, loc.proceedPayment);
          await keyboardActivate(tester, save);
          expect(find.byType(PostSaleDialog), findsOneWidget);
          final invoice = (await db.query('invoices')).single;
          expect(invoice['customer_id'], customerId);
          expect(invoice['grand_total'], product['sale_price']);
          expect((await db.query('products')).single['current_stock'],
              (product['current_stock'] as num) - 1);
          await tabTo(
              tester, find.widgetWithText(OutlinedButton, loc.printReceipt));
          await tabTo(
              tester, find.widgetWithText(OutlinedButton, loc.saveAsPdf));
          await keyboardActivate(
              tester, find.widgetWithText(ElevatedButton, loc.startNewSale));
          expect(find.byType(PostSaleDialog), findsNothing);
          expect(find.text(loc.cartEmpty).hitTestable(), findsOneWidget);
          final sidebar = find.byType(AppNavigationSidebar);
          for (final route in [
            (loc.productsAndStock, StockScreen),
            (loc.purchase, PurchaseScreen),
            (loc.accounts, AccountsScreen),
            (loc.settings, SettingsScreen),
            (loc.salesPos, SalesProductPanel)
          ]) {
            final menu = find.descendant(
                of: find.descendant(
                    of: sidebar, matching: find.byTooltip(route.$1)),
                matching: find.byType(InkWell));
            await keyboardActivate(tester, menu);
            // A screen's empty center need not handle pointer hits. Offstage
            // routes are excluded by the finder; verify its laid-out viewport.
            final activeRoute = find.byType(route.$2);
            expect(activeRoute, findsOneWidget);
            expect(tester.getSize(activeRoute).height, greaterThan(0));
            if (route.$2 == AccountsScreen) {
              for (final tab in [
                (loc.suppliers, SuppliersScreen),
                (loc.customers, CustomersScreen)
              ]) {
                final target = find.ancestor(
                    of: find.descendant(
                        of: find.byType(TabBar), matching: find.text(tab.$1)),
                    matching: find.byType(InkWell));
                await keyboardActivate(tester, target);
                expect(find.byType(tab.$2), findsOneWidget);
                expect(
                    tester.getSize(find.byType(tab.$2)).height, greaterThan(0));
              }
            }
            if (route.$2 == SettingsScreen) {
              await keyboardActivate(
                  tester,
                  find.ancestor(
                      of: find.text(loc.backup),
                      matching: find.byType(InkWell)));
              expect(find.byType(BackupPage), findsOneWidget);
              Future<Map<String, dynamic>> savedRows() async {
                final current = await DatabaseHelper.instance.database;
                final tables = await current.rawQuery(
                    "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name");
                return {
                  for (final table in tables)
                    table['name'] as String: await current
                        .query(table['name'] as String, orderBy: 'rowid')
                };
              }

              final original = await savedRows();
              await keyboardActivate(tester,
                  find.widgetWithText(ElevatedButton, loc.createBackupNow));
              final backups = await SettingsRepository().getBackupFiles();
              expect(backups, hasLength(1));
              expect(await File(backups.single['path'] as String).exists(),
                  isTrue);
              await db.update(
                  'shop_profile', {'shop_name_english': 'After backup QA'});
              await keyboardActivate(tester, find.byTooltip(loc.restore));
              await keyboardActivate(
                  tester, find.widgetWithText(ElevatedButton, loc.restore));
              expect(await savedRows(), original);
              // The restore message can queue behind the backup-created snackbar.
              for (var attempt = 0;
                  attempt < 60 &&
                      find.text(loc.restoreSuccess).evaluate().isEmpty;
                  attempt++) {
                await tester.pump(const Duration(milliseconds: 100));
                await settleDesktop(tester);
              }
              expect(find.text(loc.restoreSuccess), findsOneWidget);
            }
          }
          final header = find.byType(SalesKpiHeader);
          await keyboardActivate(
              tester,
              find
                  .descendant(of: header, matching: find.byType(IconButton))
                  .first);
          expect(
              find.descendant(
                  of: header,
                  matching:
                      find.textContaining(invoice['invoice_number'] as String)),
              findsOneWidget);
          final boundary = tester.renderObject<RenderRepaintBoundary>(find
              .ancestor(
                  of: find.byType(AppShell),
                  matching: find.byType(RepaintBoundary))
              .first);
          final screenshot = await boundary.toImage();
          try {
            final bytes =
                await screenshot.toByteData(format: ui.ImageByteFormat.png);
            final output = await Directory('build/desktop-keyboard-review')
                .create(recursive: true);
            await File('${output.path}/$language-minimum.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            screenshot.dispose();
          }
          expect(
              await (await DatabaseHelper.instance.database).query('invoices'),
              hasLength(1));
          await keyboardActivate(
              tester,
              find.descendant(
                  of: find.descendant(
                      of: sidebar, matching: find.byTooltip(loc.logout)),
                  matching: find.byType(InkWell)));
          expect(find.byType(LoginScreen), findsOneWidget);
        } finally {
          await windowManager.setSize(originalSize);
        }
      });
    });
  }

  testWidgets('F9 checkout after selecting a product', (tester) async {
    await withDesktopFixture(tester, (_) async {
      await loginDesktop(tester);
      await tester.tap(find.byType(ProductCard).first);
      await settleDesktop(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f9);
      await settleDesktop(tester);
      expect(find.byType(CheckoutPaymentDialog), findsOneWidget);
    });
  });

  testWidgets('F9 checkout after selecting a customer and product',
      (tester) async {
    await withDesktopFixture(tester, (_) async {
      await CustomersRepository().addCustomer(
          Customer(nameEnglish: 'Keyboard Customer', creditLimit: 1000000));
      await loginDesktop(tester);
      await tester.enterText(
          find.descendant(
              of: find.byType(CustomerSection),
              matching: find.byType(TextField)),
          'Keyboard Customer');
      for (var attempt = 0;
          attempt < 100 && find.text('Keyboard Customer').evaluate().isEmpty;
          attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await settleDesktop(tester);
      await tester.tap(find.text('Keyboard Customer'));
      await settleDesktop(tester);
      await tester.tap(find.byType(ProductCard).first);
      await settleDesktop(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f9);
      await settleDesktop(tester);
      expect(find.byType(CheckoutPaymentDialog), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleDesktop(tester);
      expect(find.byType(CheckoutPaymentDialog), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleDesktop(tester);
      expect(find.byType(ClearCartDialog), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleDesktop(tester);
      expect(find.byType(ClearCartDialog), findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settleDesktop(tester);
      final search = tester.widget<TextField>(find.descendant(
          of: find.byType(SalesProductPanel),
          matching: find.byType(TextField)));
      expect(search.focusNode!.hasFocus, isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settleDesktop(tester);
      expect(find.byType(AddCustomerDialog), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleDesktop(tester);
      expect(find.byType(AddCustomerDialog), findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settleDesktop(tester);
      final loc = AppLocalizations.of(tester.element(find.byType(AppShell)))!;
      expect(find.text(loc.cartEmpty).hitTestable(), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.f9);
      await settleDesktop(tester);
      expect(find.byType(CheckoutPaymentDialog), findsNothing);
      final db = await DatabaseHelper.instance.database;
      expect(await db.query('invoices'), isEmpty);
      expect((await db.query('products')).single['current_stock'], 45);
      expect(await db.query('customers'), hasLength(2));
    });
  });
}
