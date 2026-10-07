import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/screens/accounts/accounts_screen.dart';
import 'package:liaqat_store/screens/customers/dialogs/add_customer_dialog.dart';
import 'package:liaqat_store/screens/customers/widgets/customer_list.dart';
import 'package:liaqat_store/screens/customers/widgets/customer_list_tile.dart';
import 'package:liaqat_store/screens/customers/widgets/archived_customers_overlay.dart';
import 'package:liaqat_store/screens/suppliers/dialogs/add_supplier_dialog.dart';
import 'package:liaqat_store/screens/suppliers/widgets/supplier_list.dart';
import 'package:liaqat_store/screens/suppliers/widgets/supplier_list_tile.dart';
import 'package:liaqat_store/screens/suppliers/widgets/archived_suppliers_overlay.dart';
import 'package:liaqat_store/widgets/app_navigation_sidebar.dart';
import 'package:liaqat_store/widgets/app_shell.dart';

import 'support/desktop_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  for (final language in ['en', 'ur']) {
    testWidgets('$language account create edit archive and restore',
        (tester) async {
      await withDesktopFixture(tester, (_) async {
        await loginDesktop(tester);
        app.LiaqatStoreApp.setLocale(
            tester.element(find.byType(AppShell)), Locale(language));
        await settleDesktop(tester);
        final loc = AppLocalizations.of(tester.element(find.byType(AppShell)))!;
        await tester.tap(find.descendant(
            of: find.byType(AppNavigationSidebar),
            matching: find.text(loc.accounts)));
        await settleDesktop(tester);
        expect(find.byType(AccountsScreen), findsOneWidget);
        final db = await DatabaseHelper.instance.database;
        final stockBefore = await db.query('stock_activities', orderBy: 'id');
        for (final supplier in [false, true]) {
          if (supplier) {
            await tester.tap(find.widgetWithText(Tab, loc.suppliers));
            await settleDesktop(tester);
          }
          final table = supplier ? 'suppliers' : 'customers';
          final dialogType = supplier ? AddSupplierDialog : AddCustomerDialog;
          final tileType = supplier ? SupplierListTile : CustomerListTile;
          final listType = supplier ? SupplierList : CustomerList;
          final englishName =
              supplier ? 'AA Desktop Supplier' : 'AA Desktop Customer';
          final urduName = supplier ? 'نیا سپلائر' : 'نیا گاہک';
          final displayName = language == 'ur' ? urduName : englishName;
          final before = await db.query(table, orderBy: 'id');
          await tester.tap(find.widgetWithText(
              ElevatedButton, supplier ? loc.addSupplier : loc.addCustomer));
          await settleDesktop(tester);
          final fields = find.descendant(
              of: find.byType(dialogType),
              matching: find.byType(TextFormField));
          final save = find.descendant(
              of: find.byType(dialogType),
              matching: find.widgetWithText(ElevatedButton, loc.save));
          await tester.tap(save);
          await settleDesktop(tester);
          expect(find.byType(dialogType), findsOneWidget);
          expect(await db.query(table, orderBy: 'id'), before);
          await tester.pump(const Duration(seconds: 5));
          await settleDesktop(tester);
          await tester.enterText(fields.at(0), englishName);
          await tester.enterText(fields.at(1), urduName);
          await tester.enterText(
              fields.at(2), supplier ? '0300-8000002' : '0300-8000001');
          await tester.ensureVisible(fields.last);
          await tester.enterText(fields.last, supplier ? '100.25' : '250.50');
          await tester.tap(save);
          await settleDesktop(tester);
          expect(find.byType(dialogType), findsNothing);
          final created = (await db.query(table,
                  where: 'name_english = ?', whereArgs: [englishName]))
              .single;
          final id = created['id'];
          expect(created['outstanding_balance'], supplier ? 10025 : 0);
          if (!supplier) expect(created['credit_limit'], 25050);
          final ledgerTable = supplier ? 'supplier_ledger' : 'customer_ledger';
          final ledgerBefore = await db.query(ledgerTable, orderBy: 'id');
          if (supplier) {
            final opening = (await db.query(ledgerTable,
                    where: 'supplier_id = ?', whereArgs: [id]))
                .single;
            expect(opening['balance'], 10025);
            expect(opening['debit'], 10025);
          }
          final name = find.text(displayName);
          await tester.scrollUntilVisible(name, 120,
              scrollable: find
                  .descendant(
                      of: find.byType(listType),
                      matching: find.byType(Scrollable))
                  .first);
          final tile = find.ancestor(of: name, matching: find.byType(tileType));
          Future<void> menu(String action) async {
            await tester.tap(find.descendant(
                of: tile, matching: find.byIcon(Icons.more_vert)));
            await settleDesktop(tester);
            await tester.tap(find.text(action));
            await settleDesktop(tester);
          }

          await menu(loc.editAction);
          expect(find.byType(dialogType), findsOneWidget);
          if (supplier) {
            expect(
                tester
                    .widget<TextField>(find.descendant(
                        of: fields.last, matching: find.byType(TextField)))
                    .readOnly,
                isTrue);
          }
          await tester.ensureVisible(fields.at(3));
          await tester.enterText(fields.at(3), 'Edited desktop address');
          await tester.tap(find.descendant(
              of: find.byType(dialogType),
              matching: find.widgetWithText(
                  ElevatedButton, supplier ? loc.update : loc.save)));
          await settleDesktop(tester);
          final edited =
              (await db.query(table, where: 'id = ?', whereArgs: [id])).single;
          expect(edited['address'], 'Edited desktop address');
          expect(edited['outstanding_balance'], created['outstanding_balance']);
          expect(await db.query(ledgerTable, orderBy: 'id'), ledgerBefore);
          await menu(loc.archiveAction);
          expect(
              (await db.query(table, where: 'id = ?', whereArgs: [id]))
                  .single['is_active'],
              0);
          expect(find.descendant(of: find.byType(listType), matching: name),
              findsNothing);
          await tester.tap(find.text(loc.dashboardArchived));
          await settleDesktop(tester);
          if (supplier) {
            expect(find.byType(ArchivedSuppliersOverlay), findsOneWidget);
            await tester.tap(find.descendant(
                of: find.byType(ArchivedSuppliersOverlay),
                matching: find.byIcon(Icons.unarchive)));
          } else {
            expect(find.byType(ArchivedCustomersOverlay), findsOneWidget);
            await menu(loc.archiveAction);
          }
          await settleDesktop(tester);
          expect(
              (await db.query(table, where: 'id = ?', whereArgs: [id]))
                  .single['is_active'],
              1);
          expect(await db.query(ledgerTable, orderBy: 'id'), ledgerBefore);
        }
        expect(await db.query('stock_activities', orderBy: 'id'), stockBefore);
        for (final table in [
          'cash_ledger',
          'receipts',
          'supplier_payments',
          'invoices',
          'purchases'
        ]) {
          expect(await db.query(table), isEmpty);
        }
      });
    });
  }
}
