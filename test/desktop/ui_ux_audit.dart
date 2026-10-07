import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:integration_test/integration_test.dart';
import 'package:window_manager/window_manager.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/routes/app_routes.dart';
import 'package:liaqat_store/core/theme/theme_provider.dart';
import 'package:liaqat_store/domain/entities/money.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/core/repositories/suppliers_repository.dart';
import 'package:liaqat_store/core/repositories/categories_repository.dart';
import 'package:liaqat_store/core/repositories/units_repository.dart';
import 'package:liaqat_store/models/product_model.dart';
import 'package:liaqat_store/models/customer_model.dart';
import 'package:liaqat_store/models/supplier_model.dart';
import 'package:liaqat_store/models/category_models.dart';
import 'package:liaqat_store/models/unit_model.dart';
import 'package:liaqat_store/core/entity/stock_item_entity.dart';
import 'package:liaqat_store/bloc/sales/sales_bloc.dart';
import 'package:liaqat_store/bloc/sales/sales_event.dart';
import 'package:liaqat_store/bloc/settings/settings_cubit.dart';
import 'package:liaqat_store/bloc/settings/settings_state.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/widgets/app_shell.dart';
import 'package:liaqat_store/widgets/app_navigation_sidebar.dart';
import 'package:liaqat_store/screens/auth/login_screen.dart';
import 'package:liaqat_store/screens/sales/widgets/sales_product_panel.dart';
import 'package:liaqat_store/screens/sales/widgets/product_card.dart';
import 'package:liaqat_store/screens/settings/settings_screen.dart';
import 'package:liaqat_store/screens/sales/dialogs/add_customer_dialog.dart'
    as quick;
import 'package:liaqat_store/screens/sales/dialogs/cancel_sale_dialog.dart';
import 'package:liaqat_store/screens/sales/dialogs/checkout_payment_dialog.dart';
import 'package:liaqat_store/screens/sales/dialogs/clear_cart_dialog.dart';
import 'package:liaqat_store/screens/sales/dialogs/credit_limit_warning_dialog.dart';
import 'package:liaqat_store/screens/sales/dialogs/exit_confirmation_dialog.dart';
import 'package:liaqat_store/screens/sales/dialogs/increase_limit_dialog.dart';
import 'package:liaqat_store/screens/sales/dialogs/post_sale_dialog.dart';
import 'package:liaqat_store/screens/customers/dialogs/add_customer_dialog.dart'
    as customer;
import 'package:liaqat_store/screens/customers/dialogs/delete_customer_dialog.dart';
import 'package:liaqat_store/screens/customers/dialogs/receive_payment_dialog.dart';
import 'package:liaqat_store/screens/suppliers/dialogs/add_supplier_dialog.dart';
import 'package:liaqat_store/screens/suppliers/dialogs/receive_supplier_payment_dialog.dart';
import 'package:liaqat_store/screens/items/dialogs/item_form_dialog.dart';
import 'package:liaqat_store/screens/categories/dialogs/department_dialog.dart';
import 'package:liaqat_store/screens/categories/dialogs/category_dialog.dart';
import 'package:liaqat_store/screens/categories/dialogs/sub_category_dialog.dart';
import 'package:liaqat_store/screens/units/dialogs/add_unit_dialog.dart';
import 'package:liaqat_store/screens/units/dialogs/edit_unit_dialog.dart';
import 'package:liaqat_store/screens/units/dialogs/delete_unit_dialog.dart';
import 'package:liaqat_store/screens/stock/dialogs/adjust_stock_dialog.dart';
import 'package:liaqat_store/screens/stock/dialogs/cancel_activity_dialog.dart';
import 'package:liaqat_store/screens/purchase/dialogs/add_purchase_item_dialog.dart';
import 'package:liaqat_store/screens/purchase/dialogs/supplier_selector_dialog.dart';
import 'package:liaqat_store/screens/cash_ledger/dialogs/add_transaction_dialog.dart';
import 'package:liaqat_store/core/repositories/cash_repository.dart';
import 'package:liaqat_store/screens/customers/controller/customer_controller.dart';
import 'package:liaqat_store/screens/customers/widgets/customer_list.dart';
import 'package:liaqat_store/screens/customers/widgets/customer_ledger_panel.dart';
import 'package:liaqat_store/screens/suppliers/controller/supplier_controller.dart';
import 'package:liaqat_store/screens/suppliers/widgets/supplier_list.dart';
import 'package:liaqat_store/screens/suppliers/widgets/supplier_ledger_panel.dart';
import '../support/receipt_fixture.dart' as receipt;
import 'support/desktop_fixture.dart';
import 'support/ui_audit_specimens.dart';

/// Visual audit only. Saves observed errors instead of repairing production UI.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => windowManager.ensureInitialized());
  final output = Directory(
      Platform.environment['UI_AUDIT_SCREENS_ONLY'] == 'true'
          ? 'build/ui-ux-redesign-matched'
          : 'build/ui-ux-audit')
    ..createSync(recursive: true);
  final records = <Map<String, Object?>>[];
  const dialogsOnly = bool.fromEnvironment('AUDIT_DIALOGS_ONLY');
  if (dialogsOnly && File('${output.path}/captures.json').existsSync()) {
    records.addAll(
        (jsonDecode(File('${output.path}/captures.json').readAsStringSync())
                as List)
            .map((r) => Map<String, Object?>.from(r as Map)));
  }
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
      {String kind = 'screen', String provenance = 'live app'}) async {
    await tester.pump(const Duration(milliseconds: 50));
    final view = tester.binding.renderViews.first;
    final scene = view.debugLayer!.buildScene(ui.SceneBuilder());
    final screenshot = await scene.toImage(
        view.flutterView.physicalSize.width.round(),
        view.flutterView.physicalSize.height.round());
    scene.dispose();
    final file = '$prefix-$name.png';
    try {
      final bytes = await screenshot.toByteData(format: ui.ImageByteFormat.png);
      await File('${output.path}/$file').writeAsBytes(
          bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    } finally {
      screenshot.dispose();
    }
    final texts = <Map<String, Object?>>[];
    for (final element in find.byType(Text).evaluate()) {
      final widget = element.widget as Text;
      final box = element.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final point = box.localToGlobal(Offset.zero);
      if (!point.dx.isFinite || !point.dy.isFinite) continue;
      if (point.dx < 0 ||
          point.dy < 0 ||
          point.dx >= view.size.width ||
          point.dy >= view.size.height) {
        continue;
      }
      texts.add({
        'text': widget.data ?? widget.textSpan?.toPlainText(),
        'x': point.dx,
        'y': point.dy,
        'w': box.size.width,
        'h': box.size.height,
        'fontSize': widget.style?.fontSize
      });
    }
    records.add({
      'file': file,
      'name': name,
      'variant': prefix,
      'kind': kind,
      'provenance': provenance,
      'width': view.flutterView.physicalSize.width,
      'height': view.flutterView.physicalSize.height,
      'visibleTexts': texts,
      'layoutErrors': List<String>.from(errors)
    });
    errors.clear();
    File('${output.path}/captures.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(records));
    debugPrint('AUDIT_CAPTURE $file');
  }

  testWidgets('all current UI surfaces and feedback specimens', (tester) async {
    Size? originalSize;
    try {
      await withDesktopFixture(tester, (recoveryCode) async {
        originalSize = await windowManager.getSize();
        await windowManager.setSize(const Size(1366, 768));
        await settle(tester);
        prefix = 'en-light-wide';
        await capture(tester, 'login');
        var loc =
            AppLocalizations.of(tester.element(find.byType(LoginScreen)))!;
        await tester.tap(find.text(loc.forgotPassword));
        await settle(tester);
        await capture(tester, 'recovery');
        await tester.enterText(find.byType(TextField).first, recoveryCode);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await settle(tester);
        await capture(tester, 'reset-pin');
        await tester.enterText(find.byType(TextField).at(0), '2468');
        await tester.enterText(find.byType(TextField).at(1), '2468');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await settle(tester);
        await capture(tester, 'recovery-code', kind: 'dialog');
        await tester.tap(find.widgetWithText(FilledButton, loc.save));
        await settle(tester);
        expect(find.byType(AppShell), findsOneWidget);

        final items = ItemsRepository();
        final customers = CustomersRepository();
        final suppliers = SuppliersRepository();
        final db = await DatabaseHelper.instance.database;
        final base =
            Product.fromMap((await db.query('products', limit: 1)).first);
        for (var i = 0; i < 24; i++) {
          await items.addProduct(Product(
              nameEnglish: 'Audit Rice & Grocery $i',
              nameUrdu: 'ٹیسٹ چاول اور کریانہ $i',
              itemCode: 'AUDIT-$i',
              currentStock: 45,
              unitId: base.unitId,
              categoryId: base.categoryId,
              avgCostPrice: base.avgCostPrice,
              salePrice: base.salePrice));
          await customers.addCustomer(Customer(
              nameEnglish: 'Audit Customer $i',
              nameUrdu: 'ٹیسٹ گاہک $i',
              contactPrimary: '0399${i.toString().padLeft(7, '0')}',
              address: 'Audit Market, Lahore',
              creditLimit: 500000));
        }
        for (var i = 0; i < 12; i++) {
          await suppliers.addSupplier({
            'name_english': 'Audit Supplier $i',
            'name_urdu': 'ٹیسٹ سپلائر $i',
            'contact_primary': '0388${i.toString().padLeft(7, '0')}',
            'address': 'Audit Wholesale Market',
            'supplier_type': 'General',
            'outstanding_balance': 0,
            'is_active': 1,
            'created_at': DateTime.now().toIso8601String()
          });
        }
        var ledgerCustomer =
            (await customers.getActiveCustomers()).firstWhere((c) => c.id != 1);
        await customers.addPayment(ledgerCustomer.id!, 10000,
            DateTime.now().toIso8601String(), 'Audit sample receipt');
        ledgerCustomer = (await customers.getCustomerById(ledgerCustomer.id!))!;
        var ledgerSupplier =
            Supplier.fromMap((await suppliers.getActiveSuppliers()).first);
        await suppliers.addPayment(
            ledgerSupplier.id!, 10000, 'Audit sample payment');
        ledgerSupplier = Supplier.fromMap(
            (await suppliers.getSupplierById(ledgerSupplier.id!))!);
        tester
            .element(find.byType(SalesProductPanel))
            .read<SalesBloc>()
            .add(SalesStarted());
        await settle(tester);

        Future<void> navigate(String route) async {
          AppShell.navigateTo(
              tester.element(find.byType(AppNavigationSidebar)), route);
          await settle(tester);
        }

        for (final language in dialogsOnly ? <String>[] : ['en', 'ur']) {
          for (final mode in [ThemeMode.light, ThemeMode.dark]) {
            for (final width
                in (mode == ThemeMode.light ? [1366.0, 1024.0] : [1024.0])) {
              await windowManager
                  .setSize(Size(width, width == 1024 ? 720 : 768));
              final shell = tester.element(find.byType(AppShell));
              app.LiaqatStoreApp.setLocale(shell, Locale(language));
              await shell.read<ThemeProvider>().setMode(mode);
              await settle(tester);
              prefix =
                  '$language-${mode.name}-${width == 1024 ? 'min' : 'wide'}';
              for (final route in [
                (AppRoutes.sales, 'sales'),
                (AppRoutes.product, 'products'),
                (AppRoutes.accounts, 'customers'),
                (AppRoutes.stock, 'stock'),
                (AppRoutes.purchase, 'purchase'),
                (AppRoutes.cashLedger, 'cash'),
                (AppRoutes.settings, 'settings'),
              ]) {
                await navigate(route.$1);
                loc =
                    AppLocalizations.of(tester.element(find.byType(AppShell)))!;
                if (route.$1 == AppRoutes.accounts) {
                  await tester.tap(find.widgetWithText(Tab, loc.customers));
                  await settle(tester);
                }
                if (route.$1 == AppRoutes.product) {
                  await tester.tap(find.widgetWithText(Tab, loc.items));
                  await settle(tester);
                }
                if (route.$1 == AppRoutes.settings) {
                  tester
                      .element(find.byType(SettingsView))
                      .read<SettingsCubit>()
                      .selectCategory(SettingsCategory.dashboard);
                  await settle(tester);
                }
                await capture(tester, route.$2);
                loc =
                    AppLocalizations.of(tester.element(find.byType(AppShell)))!;
                if (route.$1 == AppRoutes.product) {
                  for (final tab in [
                    (loc.categories, 'categories'),
                    (loc.units, 'units')
                  ]) {
                    await tester.tap(find.widgetWithText(Tab, tab.$1));
                    await settle(tester);
                    await capture(tester, tab.$2);
                  }
                }
                if (route.$1 == AppRoutes.accounts) {
                  final customerController = tester
                      .element(find.byType(CustomerList))
                      .read<CustomerController>();
                  customerController.openLedger(ledgerCustomer);
                  await settle(tester);
                  await capture(tester, 'customer-ledger', kind: 'overlay');
                  if (width == 1366) {
                    final panel = find.byType(CustomerLedgerPanel);
                    await tester.tap(find.descendant(
                        of: panel,
                        matching: find.byTooltip(loc.exportTooltip)));
                    await settle(tester);
                    await capture(tester, 'customer-export',
                        kind: 'bottom-sheet');
                    Navigator.of(tester.element(find.byType(BottomSheet)))
                        .pop();
                    await settle(tester);
                  }
                  customerController.closeLedger();
                  customerController.toggleArchiveView();
                  await settle(tester);
                  await capture(tester, 'customers-archived', kind: 'overlay');
                  customerController.closeArchiveView();
                  await settle(tester);
                  await tester.tap(find.widgetWithText(Tab, loc.suppliers));
                  await settle(tester);
                  await capture(tester, 'suppliers');
                  final supplierController = tester
                      .element(find.byType(SupplierList))
                      .read<SupplierController>();
                  supplierController.openLedger(ledgerSupplier);
                  await settle(tester);
                  await capture(tester, 'supplier-ledger', kind: 'overlay');
                  if (width == 1366) {
                    await tester.tap(find.descendant(
                        of: find.byType(SupplierLedgerPanel),
                        matching: find.byTooltip(loc.exportTooltip)));
                    await settle(tester);
                    await capture(tester, 'supplier-export',
                        kind: 'bottom-sheet');
                    Navigator.of(tester.element(find.byType(BottomSheet)))
                        .pop();
                    await settle(tester);
                  }
                  supplierController.closeLedger();
                  supplierController.toggleArchiveView();
                  await settle(tester);
                  await capture(tester, 'suppliers-archived');
                  supplierController.closeArchiveView();
                  await settle(tester);
                }
                if (route.$1 == AppRoutes.settings) {
                  final controller = tester
                      .element(find.byType(SettingsView))
                      .read<SettingsCubit>();
                  for (final category in [
                    SettingsCategory.profile,
                    SettingsCategory.backup,
                    SettingsCategory.receipt,
                    SettingsCategory.preferences,
                    SettingsCategory.security
                  ]) {
                    controller.selectCategory(category);
                    await settle(tester);
                    await capture(tester, 'settings-${category.name}');
                  }
                }
              }
            }
          }
        }

        if (Platform.environment['UI_AUDIT_SCREENS_ONLY'] == 'true') {
          expect(
              records
                  .expand((record) => record['layoutErrors'] as List<String>),
              isEmpty);
          return;
        }
        await navigate(AppRoutes.sales);
        await windowManager.setSize(const Size(1366, 768));
        var salesContext = tester.element(find.byType(SalesProductPanel));
        final salesBloc = salesContext.read<SalesBloc>();
        salesBloc.add(SalesStarted());
        await settle(tester);
        await tester.tap(find.byType(ProductCard).first);
        await settle(tester);
        for (final language in ['en', 'ur']) {
          final shell = tester.element(find.byType(AppShell));
          app.LiaqatStoreApp.setLocale(shell, Locale(language));
          await shell.read<ThemeProvider>().setMode(ThemeMode.light);
          await settle(tester);
          prefix = '$language-light-wide';
          await capture(tester, 'sales-cart');
          salesContext = tester.element(find.byType(SalesProductPanel));
          Future<void> dialog(String name, Widget widget) async {
            showDialog<void>(
                context: salesContext,
                builder: (_) =>
                    BlocProvider.value(value: salesBloc, child: widget));
            await settle(tester);
            await capture(tester, name,
                kind: 'dialog',
                provenance:
                    'production component; inert callbacks; synthetic data');
            Navigator.of(salesContext, rootNavigator: true).pop();
            await settle(tester);
          }

          final sampleCustomer = (await customers.getActiveCustomers())
              .firstWhere((c) => c.id != 1);
          final sampleSupplier =
              Supplier.fromMap((await suppliers.getActiveSuppliers()).first);
          final departments = await CategoriesRepository().getAllDepartments();
          final categories = await CategoriesRepository().getAllCategories();
          final category = categories.first;
          final unitCategories = await UnitsRepository().getCategories();
          final units = await UnitsRepository().getUnits();
          final customUnit = Unit(
              id: 999,
              name: 'Audit Pack',
              code: 'APK',
              category: unitCategories.last);
          final named = <(String, Widget)>[
            ('sales-add-customer', const quick.AddCustomerDialog()),
            ('sales-cancel', const CancelSaleDialog()),
            ('sales-checkout', const CheckoutPaymentDialog()),
            (
              'sales-checkout-override',
              const CheckoutPaymentDialog(ignoreCreditLimit: true)
            ),
            ('sales-clear-cart', ClearCartDialog(onClear: () {})),
            (
              'sales-credit-warning',
              CreditLimitWarningDialog(
                  creditLimit: const Money(500000),
                  currentBalance: const Money(490000),
                  billTotal: const Money(18000),
                  potentialBalance: const Money(508000),
                  onContinueAnyway: () {},
                  onIncreaseLimit: () {})
            ),
            ('sales-exit', const ExitConfirmationDialog()),
            (
              'sales-increase-limit',
              IncreaseLimitDialog(
                  customerId: sampleCustomer.id!,
                  currentLimit: const Money(500000),
                  onLimitUpdated: () {})
            ),
            ('sales-post-sale', PostSaleDialog(invoice: receipt.invoice())),
            (
              'customer-add',
              customer.AddCustomerDialog(repository: customers, onSaved: () {})
            ),
            (
              'customer-edit',
              customer.AddCustomerDialog(
                  customer: sampleCustomer,
                  repository: customers,
                  onSaved: () {})
            ),
            ('customer-cannot-delete', CannotDeleteDialog(onArchive: () {})),
            ('customer-delete', const ConfirmDeleteDialog()),
            (
              'customer-payment',
              ReceivePaymentDialog(
                  customer: sampleCustomer,
                  repository: customers,
                  onPaymentAdded: () {})
            ),
            (
              'supplier-add',
              AddSupplierDialog(repository: suppliers, onSaved: () {})
            ),
            (
              'supplier-edit',
              AddSupplierDialog(
                  supplier: sampleSupplier,
                  repository: suppliers,
                  onSaved: () {})
            ),
            (
              'supplier-payment',
              ReceiveSupplierPaymentDialog(
                  supplier: sampleSupplier,
                  repository: suppliers,
                  onPaymentAdded: () {})
            ),
            (
              'item-add',
              ItemFormDialog(
                  categoriesRepository: CategoriesRepository(),
                  unitsRepository: UnitsRepository())
            ),
            (
              'item-edit',
              ItemFormDialog(
                  product: base,
                  categoriesRepository: CategoriesRepository(),
                  unitsRepository: UnitsRepository())
            ),
            (
              'department-add',
              DepartmentDialog(
                  onValidate: (name, {excludeId}) async => true, onSave: (_) {})
            ),
            (
              'department-edit',
              DepartmentDialog(
                  department: departments.first,
                  onValidate: (name, {excludeId}) async => true,
                  onSave: (_) {})
            ),
            (
              'category-add',
              CategoryDialog(
                  departments: departments,
                  parentDeptId: departments.first.id,
                  onValidate: (id, name, {excludeId}) async => true,
                  onSave: (_) {})
            ),
            (
              'category-edit',
              CategoryDialog(
                  category: category,
                  departments: departments,
                  onValidate: (id, name, {excludeId}) async => true,
                  onSave: (_) {})
            ),
            (
              'subcategory-add',
              SubCategoryDialog(
                  categories: categories,
                  parentCatId: category.id,
                  onValidate: (id, name, {excludeId}) async => true,
                  onSave: (_) {})
            ),
            (
              'subcategory-edit',
              SubCategoryDialog(
                  subCategory: SubCategory(
                      id: 999,
                      categoryId: category.id!,
                      nameEn: 'Audit Dry Goods',
                      nameUr: 'ٹیسٹ خشک اشیاء'),
                  categories: categories,
                  onValidate: (id, name, {excludeId}) async => true,
                  onSave: (_) {})
            ),
            (
              'unit-add',
              AddUnitDialog(
                  categories: unitCategories, allUnits: units, onSave: (_) {})
            ),
            (
              'unit-edit',
              EditUnitDialog(
                  unit: customUnit,
                  categories: unitCategories,
                  allUnits: units,
                  onSave: (_) {})
            ),
            (
              'unit-delete',
              DeleteUnitDialog(
                  unit: customUnit,
                  repository: UnitsRepository(),
                  onDeleteConfirmed: () {})
            ),
            (
              'stock-adjust',
              AdjustStockDialog(
                  item: StockItemEntity(
                      id: 1,
                      nameEnglish: base.nameEnglish,
                      nameUrdu: base.nameUrdu ?? '',
                      currentStock: 45,
                      minStockThreshold: 10,
                      unit: 'Kg',
                      costPrice: base.avgCostPrice,
                      salePrice: base.salePrice,
                      lastUpdated: DateTime(2026, 10, 4)),
                  onSave: (_, reason) {},
                  onCancel: () {})
            ),
            ('stock-cancel', CancelActivityDialog(onConfirm: () {})),
            (
              'purchase-add-item',
              AddPurchaseItemDialog(product: base, onConfirm: (_) {})
            ),
            (
              'purchase-supplier',
              SupplierSelectorDialog(
                  suppliers: await suppliers.getActiveSuppliers(),
                  onSelected: (_) {})
            ),
            (
              'cash-in',
              AddTransactionDialog(
                  initialType: 'IN',
                  repository: CashRepository(),
                  onSaved: () {})
            ),
            (
              'cash-out',
              AddTransactionDialog(
                  initialType: 'OUT',
                  repository: CashRepository(),
                  onSaved: () {})
            ),
          ];
          for (final item in named) {
            await dialog(item.$1, item.$2);
            if ([
              'item-add',
              'customer-add',
              'supplier-add',
              'sales-checkout',
              'purchase-add-item'
            ].contains(item.$1)) {
              await windowManager.setSize(const Size(1024, 720));
              await settle(tester);
              prefix = '$language-light-min';
              await dialog(item.$1, item.$2);
              await windowManager.setSize(const Size(1366, 768));
              await settle(tester);
              prefix = '$language-light-wide';
            }
          }
          for (final item in inlineDialogSpecimens(salesContext)) {
            await dialog(item.$1, item.$2);
          }
          await dialog(
              'date-picker',
              DatePickerDialog(
                  initialDate: DateTime(2026, 10, 4),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030)));
          await dialog(
              'date-range-picker',
              DateRangePickerDialog(
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDateRange: DateTimeRange(
                      start: DateTime(2026, 10, 1),
                      end: DateTime(2026, 10, 4))));
          final messenger = ScaffoldMessenger.of(salesContext);
          for (final item in feedbackSpecimens(salesContext)) {
            messenger.clearSnackBars();
            messenger.showSnackBar(item.$2);
            await settle(tester);
            await capture(tester, item.$1,
                kind: 'snackbar',
                provenance:
                    'exact constructor specimen; sample dynamic message; not a triggered business operation');
            messenger.removeCurrentSnackBar();
            await tester.pump(const Duration(milliseconds: 50));
          }
          messenger.showSnackBar(feedbackSpecimens(salesContext, isError: true)
              .firstWhere((item) => item.$1 == 'feedback-51')
              .$2);
          await settle(tester);
          await capture(tester, 'feedback-51-error',
              kind: 'snackbar',
              provenance: 'settings feedback helper; error branch specimen');
          messenger.removeCurrentSnackBar();
          await settle(tester);
        }
      });
    } finally {
      if (originalSize != null) await windowManager.setSize(originalSize!);
    }
  });
}
