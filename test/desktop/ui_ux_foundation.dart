import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liaqat_store/core/theme/theme_provider.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/screens/cash_ledger/cash_ledger_screen.dart';
import 'package:liaqat_store/screens/stock/stock_screen.dart';
import 'package:liaqat_store/widgets/app_navigation_sidebar.dart';
import 'package:liaqat_store/widgets/app_shell.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'desktop_keyboard.dart' as keyboard;
import 'desktop_sales_visual.dart' as sales;
import 'support/desktop_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  keyboard.main();
  sales.main();
  for (final language in ['en', 'ur']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Foundation $language ${mode.name} rail navigation',
          (tester) async {
        final originalSize = await windowManager.getSize();
        try {
          await withDesktopFixture(tester, (_) async {
            await loginDesktop(tester);
            final context = tester.element(find.byType(AppShell));
            app.LiaqatStoreApp.setLocale(context, Locale(language));
            await context.read<ThemeProvider>().setMode(mode);
            await windowManager.setSize(const Size(1366, 768));
            await settleDesktop(tester);
            await sales.captureSales(
                tester, 'foundation-$language-${mode.name}-wide');
            await windowManager.setSize(const Size(1024, 720));
            await settleDesktop(tester);
            final sidebar = find.byType(AppNavigationSidebar);
            expect(tester.getSize(sidebar).width, 64);
            final loc = AppLocalizations.of(tester.element(sidebar))!;
            await sales.captureSales(
                tester, 'foundation-$language-${mode.name}-min');
            final cash = find.descendant(
                of: find.byTooltip(loc.cashLedger),
                matching: find.byType(InkWell));
            await tester.tap(cash);
            await settleDesktop(tester);
            expect(find.byType(CashLedgerScreen), findsOneWidget);
            final stock = find.descendant(
                of: find.byTooltip(loc.productsAndStock),
                matching: find.byType(InkWell));
            await tester.tap(stock);
            await settleDesktop(tester);
            expect(find.byType(StockScreen), findsOneWidget);
          });
        } finally {
          await windowManager.setSize(originalSize);
        }
      });
    }
  }
}
