import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:integration_test/integration_test.dart';
import 'package:window_manager/window_manager.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/core/routes/app_routes.dart';
import 'package:liaqat_store/core/cubits/sidebar_cubit.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/models/product_model.dart';
import 'package:liaqat_store/widgets/app_shell.dart';
import 'package:liaqat_store/widgets/app_navigation_sidebar.dart';
import 'package:liaqat_store/screens/auth/login_screen.dart';
import 'package:liaqat_store/screens/sales/widgets/sales_product_panel.dart';
import 'package:liaqat_store/screens/sales/widgets/customer_section.dart';
import 'package:liaqat_store/screens/sales/widgets/product_card.dart';
import 'package:liaqat_store/bloc/sales/sales_bloc.dart';
import 'package:liaqat_store/bloc/sales/sales_event.dart';
import 'package:liaqat_store/screens/stock/widgets/stock_table_widget.dart';
import 'package:liaqat_store/screens/stock/widgets/recent_activities_table_widget.dart';
import 'package:liaqat_store/screens/settings/settings_screen.dart';
import 'package:liaqat_store/bloc/settings/settings_cubit.dart';
import 'package:liaqat_store/bloc/settings/settings_state.dart';
import 'package:liaqat_store/bloc/stock/stock_ui/stock_ui_cubit.dart';
import 'package:liaqat_store/screens/items/dialogs/item_form_dialog.dart';
import 'package:liaqat_store/core/repositories/categories_repository.dart';
import 'package:liaqat_store/core/repositories/units_repository.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'support/desktop_fixture.dart';

/// Additional live UI states. Business writes use only a disposable database.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => windowManager.ensureInitialized());
  final output = Directory('build/ui-ux-audit')..createSync(recursive: true);
  final records = <Map<String, Object?>>[];
  final errors = <String>[];
  var prefix = '';
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 20 && tester.binding.hasScheduledFrame; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    Object? error;
    while ((error = tester.takeException()) != null) {
      errors.add(error.toString());
    }
  }

  Future<void> capture(WidgetTester tester, String name,
      {String kind = 'screen'}) async {
    final view = tester.binding.renderViews.first;
    final scene = view.debugLayer!.buildScene(ui.SceneBuilder());
    final screenshot = await scene.toImage(
        view.flutterView.physicalSize.width.round(),
        view.flutterView.physicalSize.height.round());
    scene.dispose();
    final file = '$prefix-$name.png';
    final bytes = await screenshot.toByteData(format: ui.ImageByteFormat.png);
    await File('${output.path}/$file').writeAsBytes(
        bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    screenshot.dispose();
    records.add({
      'file': file,
      'name': name,
      'variant': prefix,
      'kind': kind,
      'provenance': name == 'item-form-validation'
          ? 'production dialog specimen from shell context; empty-form validation executed'
          : 'live app; isolated sample data',
      'width': view.flutterView.physicalSize.width,
      'height': view.flutterView.physicalSize.height,
      'layoutErrors': List<String>.from(errors)
    });
    errors.clear();
    File('${output.path}/state-captures.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(records));
    debugPrint('AUDIT_CAPTURE $file');
  }

  for (final language in ['en', 'ur']) {
    testWidgets('$language authentication and workspace states',
        (tester) async {
      final originalSize = await windowManager.getSize();
      try {
        await withDesktopFixture(tester, (recovery) async {
          await windowManager.setSize(const Size(1366, 768));
          app.LiaqatStoreApp.setLocale(
              tester.element(find.byType(LoginScreen)), Locale(language));
          await settle(tester);
          prefix = '$language-light-wide';
          await capture(tester, 'auth-verify');
          await tester.enterText(find.byType(TextField).first, '0000');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await settle(tester);
          await capture(tester, 'auth-invalid-pin');
          for (var i = 0; i < 4; i++) {
            await tester.enterText(find.byType(TextField).first, '0000');
            await tester.testTextInput.receiveAction(TextInputAction.done);
            await settle(tester);
          }
          await capture(tester, 'auth-lockout');
          await const FlutterSecureStorage().deleteAll();
          final preferences = await SharedPreferences.getInstance();
          await preferences.remove('pin_auth_lock_until');
          await preferences.remove('pin_auth_attempts');
          Navigator.of(tester.element(find.byType(LoginScreen)))
              .pushNamedAndRemoveUntil(AppRoutes.logout, (_) => false);
          await settle(tester);
          await capture(tester, 'auth-setup');
          await tester.enterText(find.byType(TextField).at(0), '2468');
          await tester.enterText(find.byType(TextField).at(1), '1357');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await settle(tester);
          await capture(tester, 'auth-pin-mismatch');
          await tester.enterText(find.byType(TextField).at(1), '2468');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await settle(tester);
          final loc =
              AppLocalizations.of(tester.element(find.byType(LoginScreen)))!;
          await tester.tap(find.widgetWithText(FilledButton, loc.save));
          await settle(tester);
          expect(find.byType(AppShell), findsOneWidget);
          final base = Product.fromMap(
              (await (await DatabaseHelper.instance.database)
                      .query('products', limit: 1))
                  .first);
          for (var i = 0; i < 18; i++) {
            await ItemsRepository().addProduct(Product(
                nameEnglish: 'Audit Grocery $i',
                nameUrdu: 'ٹیسٹ کریانہ $i',
                itemCode: 'STATES-$i',
                currentStock: 45,
                unitId: base.unitId,
                categoryId: base.categoryId,
                avgCostPrice: base.avgCostPrice,
                salePrice: base.salePrice));
          }
          final panel = tester.element(find.byType(SalesProductPanel));
          panel.read<SalesBloc>().add(SalesStarted());
          await settle(tester);
          await capture(tester, 'sales-populated');
          await tester.enterText(
              find
                  .descendant(
                      of: find.byType(SalesProductPanel),
                      matching: find.byType(TextField))
                  .first,
              'ZZZ-NO-MATCH');
          await settle(tester);
          await capture(tester, 'sales-no-results');
          await tester.enterText(
              find
                  .descendant(
                      of: find.byType(SalesProductPanel),
                      matching: find.byType(TextField))
                  .first,
              '');
          await settle(tester);
          await tester.tap(find.byType(ProductCard).first);
          await settle(tester);
          await capture(tester, 'sales-populated-cart');
          final customerFields = find.descendant(
              of: find.byType(CustomerSection),
              matching: find.byType(TextField));
          await tester.enterText(customerFields.first, 'Ali');
          await settle(tester);
          await capture(tester, 'sales-customer-suggestions', kind: 'menu');
          await tester.enterText(customerFields.first, '');
          await settle(tester);
          await windowManager.setSize(const Size(1024, 720));
          await settle(tester);
          prefix = '$language-light-min';
          await capture(tester, 'sales-populated-cart');
          tester
              .element(find.byType(AppNavigationSidebar))
              .read<SidebarCubit>()
              .toggle();
          await settle(tester);
          await capture(tester, 'sales-collapsed-sidebar');
          tester
              .element(find.byType(AppNavigationSidebar))
              .read<SidebarCubit>()
              .toggle();
          await windowManager.setSize(const Size(1366, 768));
          await settle(tester);
          prefix = '$language-light-wide';
          void navigate(String route) => AppShell.navigateTo(
              tester.element(find.byType(AppNavigationSidebar)), route);
          navigate(AppRoutes.stock);
          await settle(tester);
          final stock = find.byType(StockTableWidget);
          final menus = find.descendant(
              of: stock, matching: find.byType(PopupMenuButton<String>));
          await tester.tap(menus.first);
          await settle(tester);
          await capture(tester, 'stock-row-menu', kind: 'menu');
          await tester.tap(find.text(loc.recentActivities).last);
          await settle(tester);
          await capture(tester, 'stock-history-panel', kind: 'panel');
          tester.element(stock).read<StockUiCubit>().closeSidePanel();
          await settle(tester);
          final activities = tester.widget<RecentActivitiesTableWidget>(
              find.byType(RecentActivitiesTableWidget));
          activities.onActivityView(
              'Audit stock activity', activities.activities.first);
          await settle(tester);
          await capture(tester, 'stock-activity-panel', kind: 'panel');
          tester.element(stock).read<StockUiCubit>().closeSidePanel();
          await settle(tester);
          await tester.tap(find
              .descendant(of: stock, matching: find.byType(Checkbox))
              .at(1));
          await settle(tester);
          await capture(tester, 'stock-selection-toolbar');
          final dropdowns = find.byWidgetPredicate((w) => w is DropdownButton);
          if (dropdowns.evaluate().isNotEmpty) {
            final dropdownContext = tester.element(dropdowns.first);
            await tester.tap(dropdowns.first);
            await settle(tester);
            await capture(tester, 'stock-filter-menu', kind: 'menu');
            Navigator.of(dropdownContext, rootNavigator: true).pop();
            await settle(tester);
          }
          navigate(AppRoutes.product);
          await settle(tester);
          await tester.tap(find.widgetWithText(Tab, loc.categories));
          await settle(tester);
          await tester.tap(find.text('Food').first);
          await settle(tester);
          await capture(tester, 'categories-populated');
          await tester.tap(find.widgetWithText(Tab, loc.items));
          await settle(tester);
          final context = tester.element(find.byType(AppNavigationSidebar));
          showDialog<void>(
              context: context,
              builder: (_) => ItemFormDialog(
                  categoriesRepository: CategoriesRepository(),
                  unitsRepository: UnitsRepository()));
          await settle(tester);
          await tester.tap(find.widgetWithText(ElevatedButton, loc.save));
          await settle(tester);
          await capture(tester, 'item-form-validation', kind: 'dialog');
          Navigator.of(tester.element(find.byType(Dialog))).pop();
          await settle(tester);
          navigate(AppRoutes.settings);
          await settle(tester);
          final settings =
              tester.element(find.byType(SettingsView)).read<SettingsCubit>();
          for (final category in [
            SettingsCategory.receipt,
            SettingsCategory.preferences
          ]) {
            settings.selectCategory(category);
            await settle(tester);
            final scrolls = find.descendant(
                of: find.byType(SettingsView),
                matching: find.byType(SingleChildScrollView));
            if (scrolls.evaluate().isNotEmpty) {
              await tester.drag(scrolls.first, const Offset(0, -1000));
              await settle(tester);
              await capture(tester, 'settings-${category.name}-lower');
            }
          }
        });
      } finally {
        await windowManager.setSize(originalSize);
      }
    });
  }
}
