import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/screens/items/dialogs/item_form_dialog.dart';
import 'package:liaqat_store/screens/items/widgets/items_toolbar.dart';
import 'package:liaqat_store/screens/items/widgets/items_table.dart';
import 'package:liaqat_store/screens/product/product_screen.dart';
import 'package:liaqat_store/screens/stock/stock_screen.dart';
import 'package:liaqat_store/widgets/app_navigation_sidebar.dart';
import 'package:liaqat_store/widgets/app_shell.dart';

import 'support/desktop_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  for (final language in ['en', 'ur']) {
    testWidgets('$language product create edit and archive', (tester) async {
      await withDesktopFixture(tester, (_) async {
        await loginDesktop(tester);
        app.LiaqatStoreApp.setLocale(
            tester.element(find.byType(AppShell)), Locale(language));
        await settleDesktop(tester);
        final loc = AppLocalizations.of(tester.element(find.byType(AppShell)))!;
        final db = await DatabaseHelper.instance.database;
        final productsBefore = await db.query('products', orderBy: 'id');
        final historyTables = [
          'stock_activities',
          'stock_adjustments',
          'customers',
          'suppliers',
          'customer_ledger',
          'supplier_ledger',
          'cash_ledger',
          'invoices',
          'purchases'
        ];
        final before = <String, List<Map<String, Object?>>>{};
        for (final table in historyTables) {
          before[table] = await db.query(table, orderBy: 'id');
        }
        await tester.tap(find.descendant(
            of: find.byType(AppNavigationSidebar),
            matching: find.text(loc.productsAndStock)));
        await settleDesktop(tester);
        await tester.tap(find.descendant(
            of: find.byType(StockScreen),
            matching: find.widgetWithText(OutlinedButton, loc.items)));
        await settleDesktop(tester);
        expect(find.byType(ProductScreen), findsOneWidget);
        await tester.tap(find.widgetWithText(ElevatedButton, loc.addItem));
        await settleDesktop(tester);
        final fields = find.descendant(
            of: find.byType(ItemFormDialog), matching: find.byType(TextField));
        final save = find.descendant(
            of: find.byType(ItemFormDialog),
            matching: find.widgetWithText(ElevatedButton, loc.save));
        await tester.enterText(fields.first, '   ');
        await tester.tap(save);
        await settleDesktop(tester);
        expect(find.byType(ItemFormDialog), findsOneWidget);
        expect(await db.query('products', orderBy: 'id'), productsBefore);
        await tester.pump(const Duration(seconds: 5));
        await settleDesktop(tester);
        await tester.enterText(fields.at(0), '  AA Desktop Product  ');
        await tester.enterText(fields.at(1), '  نئی چیز  ');
        await tester.enterText(fields.at(2), 'Initial brand');
        final dropdowns = find.descendant(
            of: find.byType(ItemFormDialog),
            matching: find.byType(DropdownButtonFormField<int>));
        await tester.tap(dropdowns.first);
        await settleDesktop(tester);
        await tester.tap(find.text('Rice').last);
        await settleDesktop(tester);
        final unit =
            (await db.query('units', where: 'code = ?', whereArgs: ['KG']))
                .single;
        await tester.ensureVisible(dropdowns.last);
        await tester.tap(dropdowns.last);
        await settleDesktop(tester);
        await tester.tap(find.text('${unit['name']} (KG)').last);
        await settleDesktop(tester);
        await tester.tap(save);
        await settleDesktop(tester);
        expect(find.byType(ItemFormDialog), findsNothing);
        final created = (await db.query('products',
                where: 'name_english = ?', whereArgs: ['AA Desktop Product']))
            .single;
        final id = created['id'];
        expect(created['name_urdu'], 'نئی چیز');
        expect(created['category_id'], 1);
        expect(created['unit_id'], unit['id']);
        expect(created['unit_type'], 'KG');
        expect(created['current_stock'], 0);

        Future<void> search(String query) async {
          await tester.enterText(
              find.descendant(
                  of: find.byType(ItemsToolbar),
                  matching: find.byType(TextField)),
              query);
          await tester.testTextInput.receiveAction(TextInputAction.search);
          await settleDesktop(tester);
          await tester.pump(const Duration(seconds: 5));
          await settleDesktop(tester);
        }

        await search('AA Desktop Product');
        await tester.ensureVisible(find.byTooltip(loc.editItem));
        await tester.tap(find.byTooltip(loc.editItem));
        await settleDesktop(tester);
        await tester.enterText(fields.at(2), '');
        await tester.tap(find.widgetWithText(ElevatedButton, loc.update));
        await settleDesktop(tester);
        expect(
            (await db.query('products', where: 'id = ?', whereArgs: [id]))
                .single['brand'],
            '');

        // Existing stock and prices must survive metadata editing and archive.
        await search(productsBefore.single['name_english'] as String);
        await tester.ensureVisible(find.byTooltip(loc.editItem));
        await tester.tap(find.byTooltip(loc.editItem));
        await settleDesktop(tester);
        await tester.enterText(fields.at(2), 'Edited seed brand');
        await tester.tap(find.widgetWithText(ElevatedButton, loc.update));
        await settleDesktop(tester);
        await tester.pump(const Duration(seconds: 5));
        await settleDesktop(tester);
        await tester.ensureVisible(find.byTooltip(loc.deleteItem));
        await tester.tap(find.byTooltip(loc.deleteItem));
        await settleDesktop(tester);
        await tester.tap(find.widgetWithText(TextButton, loc.no));
        await settleDesktop(tester);
        expect(
            (await db.query('products', where: 'id = 1')).single['is_active'],
            1);
        await tester.tap(find.byTooltip(loc.deleteItem));
        await settleDesktop(tester);
        await tester.tap(find.widgetWithText(ElevatedButton, loc.yesDelete));
        await settleDesktop(tester);
        final archived = (await db.query('products', where: 'id = 1')).single;
        expect(archived['is_active'], 0);
        for (final field in [
          'current_stock',
          'avg_cost_price',
          'sale_price',
          'created_at'
        ]) {
          expect(archived[field], productsBefore.single[field]);
        }
        expect(
            find.descendant(
                of: find.byType(ItemsTable),
                matching:
                    find.text(productsBefore.single['name_english'] as String)),
            findsNothing);
        for (final table in historyTables) {
          expect(await db.query(table, orderBy: 'id'), before[table]);
        }
      });
    });
  }
}
