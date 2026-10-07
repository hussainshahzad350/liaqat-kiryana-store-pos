import 'dart:convert';
import 'dart:io';
import 'dart:ffi';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/core/repositories/stock_repository.dart';
import 'package:liaqat_store/core/repositories/invoice_repository.dart';
import 'package:liaqat_store/core/repositories/receipt_repository.dart';
import 'package:liaqat_store/core/services/pin_auth_service.dart';
import 'package:liaqat_store/core/routes/app_routes.dart';
import 'package:liaqat_store/bloc/stock/stock_overview/stock_overview_bloc.dart';
import 'package:liaqat_store/bloc/stock/stock_overview/stock_overview_state.dart';
import 'package:liaqat_store/screens/auth/login_screen.dart';
import 'package:liaqat_store/screens/stock/stock_screen.dart';
import 'package:liaqat_store/screens/sales/widgets/product_card.dart';
import 'package:liaqat_store/screens/sales/widgets/sales_product_panel.dart';
import 'package:liaqat_store/widgets/app_shell.dart';
import 'package:liaqat_store/widgets/app_navigation_sidebar.dart';
import 'package:liaqat_store/screens/items/widgets/items_table.dart';
import 'package:liaqat_store/screens/customers/widgets/customer_list.dart';
import 'package:liaqat_store/screens/customers/controller/customer_controller.dart';
import 'package:liaqat_store/screens/suppliers/widgets/supplier_list.dart';
import 'package:liaqat_store/screens/suppliers/controller/supplier_controller.dart';
import '../test/support/large_store_fixture.dart';

// This entry point is copied to its own executable. The normal app is unchanged.
const labRoot = String.fromEnvironment('PERFORMANCE_LAB_ROOT');
List<Element> elements<T extends Widget>([Element? start]) {
  final result = <Element>[];
  void visit(Element e) {
    if (e.widget is Offstage && (e.widget as Offstage).offstage) return;
    if (e.widget is T) result.add(e);
    e.visitChildren(visit);
  }

  final root = start ?? WidgetsBinding.instance.rootElement;
  if (root != null) visit(root);
  return result;
}

Future<void> waitFor(bool Function() ready) async {
  final timer = Stopwatch()..start();
  while (!ready()) {
    if (timer.elapsed.inSeconds > 60) {
      throw StateError('UI benchmark timed out');
    }
    WidgetsBinding.instance.scheduleFrame();
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  WidgetsBinding.instance.scheduleFrame();
  await WidgetsBinding.instance.endOfFrame;
}

Map<String, Object> summary(List<double> times) {
  final sorted = [...times]..sort();
  double percentile(double fraction) =>
      sorted[((sorted.length - 1) * fraction).ceil()];
  return {
    'samples': sorted.length,
    'p50Ms': percentile(.5),
    'p95Ms': percentile(.95),
    'maxMs': sorted.last
  };
}

Future<void> screenshot(Directory lab, String name) async {
  await WidgetsBinding.instance.endOfFrame;
  RenderObject? render = elements<AppShell>().single.findRenderObject();
  while (render != null && render is! RenderRepaintBoundary) {
    render = render.parent;
  }
  if (render is! RenderRepaintBoundary) {
    throw StateError('Screenshot boundary unavailable');
  }
  final picture = await render.toImage();
  final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
  await File('${lab.path}/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
  picture.dispose();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final lab = Directory(labRoot);
  final report = <String, Object?>{
    'releaseMode': kReleaseMode,
    'measuredAt': DateTime.now().toIso8601String()
  };
  final benchmarking = Platform.environment['KIRYANA_BENCHMARK'] == '1';
  try {
    if (labRoot.isEmpty || !await File('${lab.path}/dataset.json').exists()) {
      throw StateError(
          'Run tool/seed_performance_lab.dart before opening the lab');
    }
    // Load the shipped SQLite library before the native-assets fallback used
    // by a standalone Windows AOT verification executable.
    DynamicLibrary.open(
        p.join(p.dirname(Platform.resolvedExecutable), 'sqlite3.dll'));
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await databaseFactory.setDatabasesPath('${lab.path}/database');
    initializeVerificationPreferences();
    await PinAuthService().setupPin('2468');
    final db = await DatabaseHelper.instance.database;
    if (!p.isWithin(
        p.normalize('${lab.path}/database'), p.normalize(db.path))) {
      throw StateError('Lab database is outside isolated directory');
    }
    report['databasePath'] = db.path;
    report['dataset'] =
        jsonDecode(await File('${lab.path}/dataset.json').readAsString());
    final boot = Stopwatch()..start();
    app.main();
    await waitFor(() => elements<LoginScreen>().isNotEmpty);
    await windowManager
        .setTitle('Kiryana Performance Lab — Synthetic data — PIN 2468');
    report['startupToLoginMs'] = boot.elapsedMicroseconds / 1000;
    if (!benchmarking) return;
    if (!kReleaseMode) throw StateError('Benchmark requires release build');
    final frameworkErrors = <String>[];
    final oldErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      frameworkErrors.add(details.exceptionAsString());
      oldErrorHandler?.call(details);
    };
    final frames = <ui.FrameTiming>[];
    void captureFrames(List<ui.FrameTiming> values) => frames.addAll(values);
    WidgetsBinding.instance.addTimingsCallback(captureFrames);
    final login = Stopwatch()..start();
    final pin = elements<TextField>(elements<LoginScreen>().single).first.widget
        as TextField;
    pin.controller!.text = '2468';
    pin.onSubmitted!('2468');
    await waitFor(() => elements<ProductCard>().isNotEmpty);
    report['loginToSalesMs'] = login.elapsedMicroseconds / 1000;
    await screenshot(lab, 'sales-20000-products');
    final searchResults = <String, Object>{};
    final barcode = (await db.query('products',
            where: 'item_code = ?', whereArgs: ['KIR-19999']))
        .single['barcode'] as String;
    for (final query in ['Rice', 'چینی', 'KIR-19999', barcode]) {
      final durations = <double>[];
      for (var i = 0; i < 5; i++) {
        var panel =
            elements<SalesProductPanel>().single.widget as SalesProductPanel;
        panel.searchController.text = '__clear_benchmark__';
        panel.onSearchChanged('__clear_benchmark__');
        await waitFor(() =>
            (elements<SalesProductPanel>().single.widget as SalesProductPanel)
                .products
                .isEmpty);
        panel =
            elements<SalesProductPanel>().single.widget as SalesProductPanel;
        final watch = Stopwatch()..start();
        panel.searchController.text = query;
        panel.onSearchChanged(query);
        await waitFor(() =>
            (elements<SalesProductPanel>().single.widget as SalesProductPanel)
                .products
                .isNotEmpty);
        durations.add(watch.elapsedMicroseconds / 1000);
      }
      searchResults[query] = summary(durations);
    }
    report['nativeSalesSearchIncludingDebounce'] = searchResults;
    await screenshot(lab, 'barcode-search');
    final stock = Stopwatch()..start();
    AppShell.navigateTo(
        elements<AppNavigationSidebar>().single, AppRoutes.stock);
    await waitFor(() =>
        elements<StockScreen>().isNotEmpty &&
        elements<StockScreen>().single.read<StockOverviewBloc>().state
            is StockOverviewLoaded);
    report['firstStockNavigationMs'] = stock.elapsedMicroseconds / 1000;
    await screenshot(lab, 'stock-20000-products');
    final navigation = <String, double>{};
    Future<void> navigate(
        String name, String route, bool Function() ready) async {
      final watch = Stopwatch()..start();
      AppShell.navigateTo(elements<AppNavigationSidebar>().single, route);
      await waitFor(ready);
      navigation[name] = watch.elapsedMicroseconds / 1000;
      await screenshot(lab, name);
    }

    await navigate(
        'catalog',
        AppRoutes.product,
        () =>
            elements<ItemsTable>().isNotEmpty &&
            !(elements<ItemsTable>().single.widget as ItemsTable)
                .isInitialLoading);
    await navigate(
        'customers',
        AppRoutes.customers,
        () =>
            elements<CustomerList>().isNotEmpty &&
            !elements<CustomerList>()
                .single
                .read<CustomerController>()
                .isLoading);
    await navigate(
        'suppliers',
        AppRoutes.suppliers,
        () =>
            elements<SupplierList>().isNotEmpty &&
            !elements<SupplierList>()
                .single
                .read<SupplierController>()
                .isLoading);
    report['firstNavigationMs'] = navigation;
    final items = ItemsRepository();
    final queries = <String, Object>{};
    Future<void> measure(String name, Future<Object?> Function() action) async {
      final times = <double>[];
      for (var i = 0; i < 10; i++) {
        final watch = Stopwatch()..start();
        final result = await action();
        times.add(watch.elapsedMicroseconds / 1000);
        if (result is List && result.isEmpty) {
          throw StateError('$name returned no data');
        }
      }
      queries[name] = summary(times);
    }

    await measure('catalogFirstPage20', () => items.getCatalogProducts());
    await measure(
        'catalogLastPage20', () => items.getCatalogProducts(offset: 19980));
    await measure(
        'catalogEnglishSearch', () => items.getCatalogProducts(query: 'Rice'));
    await measure(
        'catalogUrduSearch', () => items.getCatalogProducts(query: 'چینی'));
    await measure('salesBarcodeSearch', () => items.searchProducts(barcode));
    await measure('stockPage100', () => StockRepository().getStockItems());
    await measure('stockSummary', () => StockRepository().getStockSummary());
    report['repositoryQueries'] = queries;
    final header =
        (await InvoiceRepository(items).getRecentInvoicesWithCustomer(limit: 1))
            .single;
    final pdfWatch = Stopwatch()..start();
    await File('${lab.path}/sample-product-receipt.pdf')
        .writeAsBytes(await ReceiptRepository().generateReceiptData(header));
    report['recentSalesReceiptPdfMs'] = pdfWatch.elapsedMicroseconds / 1000;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (frames.isNotEmpty) {
      report['frameBuild'] = summary(
          frames.map((f) => f.buildDuration.inMicroseconds / 1000).toList());
      report['frameRaster'] = summary(
          frames.map((f) => f.rasterDuration.inMicroseconds / 1000).toList());
      report['framesOver16_7Ms'] = frames
          .where((f) =>
              f.buildDuration.inMicroseconds > 16700 ||
              f.rasterDuration.inMicroseconds > 16700)
          .length;
    }
    report['rssMiB'] = ProcessInfo.currentRss / 1048576;
    report['peakRssMiB'] = ProcessInfo.maxRss / 1048576;
    report['frameworkErrors'] = frameworkErrors;
    report['success'] = frameworkErrors.isEmpty;
    await File('${lab.path}/benchmark.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
    await DatabaseHelper.instance.close();
    exit(frameworkErrors.isEmpty ? 0 : 1);
  } catch (error, stack) {
    report.addAll({'success': false, 'error': '$error', 'stack': '$stack'});
    await File('${lab.path}/benchmark-error.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
    exit(1);
  }
}
