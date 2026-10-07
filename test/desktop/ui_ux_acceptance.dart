import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/core/routes/app_routes.dart';
import 'package:liaqat_store/core/theme/theme_provider.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/models/customer_model.dart';
import 'package:liaqat_store/screens/customers/dialogs/add_customer_dialog.dart';
import 'package:liaqat_store/screens/customers/widgets/customer_ledger_panel.dart';
import 'package:liaqat_store/core/repositories/invoice_repository.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/screens/units/dialogs/add_unit_dialog.dart';
import 'package:liaqat_store/core/repositories/units_repository.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/widgets/app_shell.dart';
import 'package:liaqat_store/widgets/app_navigation_sidebar.dart';
import 'package:liaqat_store/screens/customers/widgets/customer_list_tile.dart';
import 'package:liaqat_store/screens/settings/settings_screen.dart';
import 'package:liaqat_store/bloc/settings/settings_cubit.dart';
import 'package:liaqat_store/bloc/settings/settings_state.dart';
import 'desktop_remaining_visual.dart' show captureRemaining;
import 'support/desktop_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => windowManager.ensureInitialized());
  for (final language in ['en', 'ur']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Acceptance $language ${mode.name} enlarged text and records',
          (tester) async {
        Size? originalSize;
        try {
          await withDesktopFixture(tester, (_) async {
            originalSize = await windowManager.getSize();
            for (var i = 0; i < 24; i++) {
              await CustomersRepository().addCustomer(Customer(
                  nameEnglish: 'Audit Customer $i',
                  nameUrdu: 'ٹیسٹ گاہک $i',
                  contactPrimary: '0399${i.toString().padLeft(7, '0')}',
                  creditLimit: 500000));
            }
            await loginDesktop(tester);
            final shell = tester.element(find.byType(AppShell));
            app.LiaqatStoreApp.setLocale(shell, Locale(language));
            await shell.read<ThemeProvider>().setMode(mode);
            await windowManager.setSize(const Size(1366, 768));
            await settleDesktop(tester);
            void navigate(String route) => AppShell.navigateTo(
                tester.element(find.byType(AppNavigationSidebar)), route);
            navigate(AppRoutes.accounts);
            await settleDesktop(tester);
            expect(
                find.byType(CustomerListTile).hitTestable().evaluate().length,
                greaterThanOrEqualTo(4),
                reason:
                    'At least twice the original two visible account records');
            await captureRemaining(tester,
                '$language-${mode.name}-wide-records', find.byType(AppShell));
            tester.platformDispatcher.textScaleFactorTestValue = 1.25;
            await windowManager.setSize(const Size(1024, 720));
            for (final route in [
              AppRoutes.sales,
              AppRoutes.purchase,
              AppRoutes.product,
              AppRoutes.accounts,
              AppRoutes.cashLedger,
              AppRoutes.stock,
              AppRoutes.settings
            ]) {
              navigate(route);
              await settleDesktop(tester);
              await captureRemaining(
                  tester,
                  '$language-${mode.name}-scaled-${route.replaceAll('/', '')}',
                  find.byType(AppShell));
            }
            for (final category in [
              SettingsCategory.profile,
              SettingsCategory.backup,
              SettingsCategory.receipt,
              SettingsCategory.preferences,
              SettingsCategory.security
            ]) {
              tester
                  .element(find.byType(SettingsView))
                  .read<SettingsCubit>()
                  .selectCategory(category);
              await settleDesktop(tester);
              await captureRemaining(
                  tester,
                  '$language-${mode.name}-scaled-settings-${category.name}',
                  find.byType(AppShell));
            }
            final loc =
                AppLocalizations.of(tester.element(find.byType(AppShell)))!;
            navigate(AppRoutes.accounts);
            await settleDesktop(tester);
            final customer = Customer(
                nameEnglish:
                    'Long account name for a wholesale customer with multiple branches',
                nameUrdu: 'متعدد شاخوں والے تھوک کاروبار کے گاہک کا طویل نام',
                creditLimit: 999999999999);
            showDialog<void>(
                context: tester.element(find.byType(AppNavigationSidebar)),
                builder: (_) => AddCustomerDialog(
                    customer: customer,
                    repository: CustomersRepository(),
                    onSaved: () {}));
            await settleDesktop(tester);
            await captureRemaining(
                tester,
                '$language-${mode.name}-scaled-customer-dialog',
                find.byType(AddCustomerDialog));
            Navigator.of(tester.element(find.byType(AddCustomerDialog))).pop();
            await settleDesktop(tester);
            final existing =
                (await CustomersRepository().getActiveCustomers()).first;
            showDialog<void>(
                context: tester.element(find.byType(AppNavigationSidebar)),
                builder: (_) => Material(
                    color: Colors.transparent,
                    child: CustomerLedgerPanel(
                        customer: existing,
                        customersRepository: CustomersRepository(),
                        invoiceRepository: InvoiceRepository(ItemsRepository()),
                        onClose: () {},
                        onDataChanged: () {})));
            await settleDesktop(tester);
            await captureRemaining(
                tester,
                '$language-${mode.name}-scaled-ledger',
                find.byType(CustomerLedgerPanel));
            Navigator.of(tester.element(find.byType(CustomerLedgerPanel)))
                .pop();
            await settleDesktop(tester);
            final categories = await UnitsRepository().getCategories();
            final units = await UnitsRepository().getUnits();
            showDialog<void>(
                context: tester.element(find.byType(AppNavigationSidebar)),
                builder: (_) => AddUnitDialog(
                    categories: categories, allUnits: units, onSave: (_) {}));
            await settleDesktop(tester);
            expect(find.text(loc.addUnit), findsOneWidget);
            await tester.tap(find.widgetWithText(ElevatedButton, loc.save));
            await settleDesktop(tester);
            await captureRemaining(
                tester,
                '$language-${mode.name}-scaled-unit-validation',
                find.byType(AddUnitDialog));
            Navigator.of(tester.element(find.byType(AddUnitDialog))).pop();
            await settleDesktop(tester);
          });
        } finally {
          tester.platformDispatcher.clearTextScaleFactorTestValue();
          if (originalSize != null) await windowManager.setSize(originalSize!);
        }
      });
    }
  }
}
