import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/routes/app_routes.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/screens/categories/dialogs/department_dialog.dart';
import 'package:liaqat_store/screens/categories/widgets/department_list_widget.dart';
import 'package:liaqat_store/screens/categories/widgets/details_panel_widget.dart';
import 'package:liaqat_store/screens/units/dialogs/add_unit_dialog.dart';
import 'package:liaqat_store/screens/units/dialogs/edit_unit_dialog.dart';
import 'package:liaqat_store/screens/units/dialogs/delete_unit_dialog.dart';
import 'package:liaqat_store/screens/units/widgets/unit_list_item.dart';
import 'package:liaqat_store/screens/units/units_screen.dart';
import 'package:liaqat_store/widgets/app_navigation_sidebar.dart';
import 'package:liaqat_store/widgets/app_shell.dart';
import 'support/desktop_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final language in ['en', 'ur']) {
    testWidgets('$language taxonomy and custom unit CRUD preserves history',
        (tester) async {
      await withDesktopFixture(tester, (_) async {
        await loginDesktop(tester);
        final shell = tester.element(find.byType(AppShell));
        app.LiaqatStoreApp.setLocale(shell, Locale(language));
        await settleDesktop(tester);
        final loc = AppLocalizations.of(shell)!;
        final db = await DatabaseHelper.instance.database;
        final protectedTables = [
          'products',
          'stock_activities',
          'stock_adjustments',
          'invoices',
          'invoice_items',
          'purchases',
          'purchase_items',
          'cash_ledger',
          'customer_ledger',
          'supplier_ledger',
          'customers',
          'suppliers'
        ];
        final before = {
          for (final table in protectedTables)
            table: await db.query(table, orderBy: 'id')
        };
        final systemUnits =
            await db.query('units', where: 'is_system = 1', orderBy: 'id');
        AppShell.navigateTo(tester.element(find.byType(AppNavigationSidebar)),
            AppRoutes.product);
        await settleDesktop(tester);
        await tester.tap(find.widgetWithText(Tab, loc.categories));
        await settleDesktop(tester);
        await tester.tap(find.byTooltip(loc.addDepartment));
        await settleDesktop(tester);
        final fields = find.descendant(
            of: find.byType(DepartmentDialog),
            matching: find.byType(TextFormField));
        await tester.enterText(fields.first, 'Phase4 Department');
        await tester.enterText(fields.last, 'نیا شعبہ');
        await tester.tap(find.widgetWithText(ElevatedButton, loc.save));
        await settleDesktop(tester);
        final department = (await db.query('departments',
                where: 'name_english = ?', whereArgs: ['Phase4 Department']))
            .single;
        final tile = find.descendant(
            of: find.byType(DepartmentListWidget),
            matching: find.text('Phase4 Department'));
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await settleDesktop(tester);
        final edit = find.descendant(
            of: find.byType(DetailsPanelWidget),
            matching: find.widgetWithText(OutlinedButton, loc.editAction));
        await tester.ensureVisible(edit);
        await tester.tap(edit);
        await settleDesktop(tester);
        await tester.enterText(fields.first, 'Phase4 Department edited');
        await tester.tap(find.widgetWithText(ElevatedButton, loc.save));
        await settleDesktop(tester);
        expect(
            (await db.query('departments',
                    where: 'id = ?', whereArgs: [department['id']]))
                .single['name_english'],
            'Phase4 Department edited');
        await tester.tap(find.widgetWithText(Tab, loc.units));
        await settleDesktop(tester);
        await tester.tap(find.descendant(
            of: find.byType(UnitsScreen),
              matching: find.widgetWithText(ElevatedButton, loc.addUnit)));
        await settleDesktop(tester);
        final unitFields = find.descendant(
            of: find.byType(AddUnitDialog),
            matching: find.byType(TextFormField));
        await tester.enterText(unitFields.at(0), 'Phase4 Bag');
        await tester.enterText(unitFields.at(1), 'P4B');
        await tester.enterText(unitFields.last, '2');
        await tester.tap(find.widgetWithText(ElevatedButton, loc.save));
        await settleDesktop(tester);
        final unit =
            (await db.query('units', where: 'code = ?', whereArgs: ['P4B']))
                .single;
        expect(unit['is_system'], 0);
        expect(unit['multiplier'], 2);
        expect(unit['base_unit_id'], isNotNull);
        var row = find.ancestor(
            of: find.text('Phase4 Bag'), matching: find.byType(UnitListItem));
        await tester.ensureVisible(row);
        await tester
            .tap(find.descendant(of: row, matching: find.byTooltip(loc.edit)));
        await settleDesktop(tester);
        final editFields = find.descendant(
            of: find.byType(EditUnitDialog),
            matching: find.byType(TextFormField));
        await tester.enterText(editFields.first, 'Phase4 Bag edited');
        await tester.tap(find.widgetWithText(ElevatedButton, loc.save));
        await settleDesktop(tester);
        expect(
            (await db.query('units', where: 'id = ?', whereArgs: [unit['id']]))
                .single['name'],
            'Phase4 Bag edited');
        row = find.ancestor(
            of: find.text('Phase4 Bag edited'),
            matching: find.byType(UnitListItem));
        await tester.ensureVisible(row);
        await tester.tap(
            find.descendant(of: row, matching: find.byTooltip(loc.delete)));
        await settleDesktop(tester);
        expect(find.byType(DeleteUnitDialog), findsOneWidget);
        await tester.tap(find.widgetWithText(ElevatedButton, loc.yesDelete));
        await settleDesktop(tester);
        expect(
            await db.query('units', where: 'id = ?', whereArgs: [unit['id']]),
            isEmpty);
        expect(await db.query('units', where: 'is_system = 1', orderBy: 'id'),
            systemUnits);
        for (final table in protectedTables) {
          expect(await db.query(table, orderBy: 'id'), before[table],
              reason: table);
        }
      });
    });
  }
}
