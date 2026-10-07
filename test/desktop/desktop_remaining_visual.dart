import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liaqat_store/core/routes/app_routes.dart';
import 'package:liaqat_store/core/theme/theme_provider.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/screens/auth/login_screen.dart';
import 'package:liaqat_store/screens/product/product_screen.dart';
import 'package:liaqat_store/screens/accounts/accounts_screen.dart';
import 'package:liaqat_store/screens/stock/stock_screen.dart';
import 'package:liaqat_store/screens/purchase/purchase_screen.dart';
import 'package:liaqat_store/screens/cash_ledger/cash_ledger_screen.dart';
import 'package:liaqat_store/screens/settings/settings_screen.dart';
import 'package:liaqat_store/widgets/app_navigation_sidebar.dart';
import 'package:liaqat_store/widgets/app_shell.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'support/desktop_fixture.dart';

Future<void> captureRemaining(
    WidgetTester tester, String name, Finder target) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.ancestor(of: target, matching: find.byType(RepaintBoundary)).first);
  final screenshot = await boundary.toImage();
  try {
    final bytes = await screenshot.toByteData(format: ui.ImageByteFormat.png);
    final side = Platform.environment['PHASE4_EVIDENCE_SIDE'] ?? 'after';
    final directory = Directory('build/remaining-phase4-review');
    await directory.create(recursive: true);
    await File('${directory.path}/$side-$name.png').writeAsBytes(
        bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
  } finally {
    screenshot.dispose();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => windowManager.ensureInitialized());
  for (final language in ['en', 'ur']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Remaining features $language ${mode.name} minimum layouts',
          (tester) async {
        Size? originalSize;
        try {
          await withDesktopFixture(tester, (_) async {
            originalSize = await windowManager.getSize();
            final baselineFailures = <String>[];
            Future<void> settleRemaining() async {
              if (Platform.environment['PHASE4_EVIDENCE_SIDE'] != 'before') {
                return settleDesktop(tester);
              }
              // Collect all baseline panes even when a known layout overflows.
              // The before target still fails at the end if any errors occurred.
              await tester.pumpAndSettle();
              final error = tester.takeException();
              if (error != null) baselineFailures.add(error.toString());
            }

            var appContext = tester.element(find.byType(LoginScreen));
            app.LiaqatStoreApp.setLocale(appContext, Locale(language));
            await appContext.read<ThemeProvider>().setMode(mode);
            await windowManager.setSize(const Size(1024, 720));
            await settleDesktop(tester);
            final prefix = '$language-${mode.name}';
            await captureRemaining(
                tester, '$prefix-login', find.byType(LoginScreen));
            await loginDesktop(tester);
            appContext = tester.element(find.byType(AppShell));
            final loc = AppLocalizations.of(appContext)!;
            final sidebarContext =
                tester.element(find.byType(AppNavigationSidebar));
            for (final route in [
              (AppRoutes.product, ProductScreen, 'items'),
              (AppRoutes.accounts, AccountsScreen, 'customers'),
              (AppRoutes.stock, StockScreen, 'stock'),
              (AppRoutes.purchase, PurchaseScreen, 'purchase'),
              (AppRoutes.cashLedger, CashLedgerScreen, 'cash'),
              (AppRoutes.settings, SettingsScreen, 'settings'),
            ]) {
              AppShell.navigateTo(sidebarContext, route.$1);
              await settleRemaining();
              expect(find.byType(route.$2), findsOneWidget);
              await captureRemaining(
                  tester, '$prefix-${route.$3}', find.byType(AppShell));
              if (route.$2 == ProductScreen) {
                for (final tab in [
                  (loc.categories, 'categories'),
                  (loc.units, 'units')
                ]) {
                  await tester.tap(find.widgetWithText(Tab, tab.$1));
                  await settleRemaining();
                  await captureRemaining(
                      tester, '$prefix-${tab.$2}', find.byType(AppShell));
                }
              }
              if (route.$2 == AccountsScreen) {
                await tester.tap(find.widgetWithText(Tab, loc.suppliers));
                await settleRemaining();
                await captureRemaining(
                    tester, '$prefix-suppliers', find.byType(AppShell));
              }
            }
            if (baselineFailures.isNotEmpty) {
              fail(
                  'Baseline layout defects recorded: ${baselineFailures.join('\n')}');
            }
          });
        } finally {
          if (originalSize != null) await windowManager.setSize(originalSize!);
        }
      });
    }
  }
}
