import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liaqat_store/core/routes/app_routes.dart';
import 'package:liaqat_store/core/theme/theme_provider.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/screens/purchase/dialogs/add_purchase_item_dialog.dart';
import 'package:liaqat_store/screens/purchase/purchase_screen.dart';
import 'package:liaqat_store/screens/purchase/widgets/purchase_item_list_widget.dart';
import 'package:liaqat_store/widgets/app_shell.dart';
import 'package:liaqat_store/widgets/app_navigation_sidebar.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'desktop_keyboard.dart' as keyboard;
import 'desktop_purchase.dart' as purchase;
import 'desktop_sales_visual.dart' as sales;
import 'support/desktop_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!const bool.fromEnvironment('UI_WORKSPACE_VISUAL_ONLY')) {
    keyboard.main();
    purchase.main();
  }
  sales.main();
  for (final language in ['en', 'ur']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Purchase $language ${mode.name} minimum workspace',
          (tester) async {
        Size? originalSize;
        try {
          await withDesktopFixture(tester, (_) async {
            await loginDesktop(tester);
            originalSize = await windowManager.getSize();
            final context = tester.element(find.byType(AppShell));
            app.LiaqatStoreApp.setLocale(context, Locale(language));
            await context.read<ThemeProvider>().setMode(mode);
            AppShell.navigateTo(
                tester.element(find.byType(AppNavigationSidebar)),
                AppRoutes.purchase);
            await windowManager.setSize(const Size(1024, 720));
            await settleDesktop(tester);
            expect(find.byType(PurchaseScreen), findsOneWidget);
            final loc =
                AppLocalizations.of(tester.element(find.byType(AppShell)))!;
            final save = find.widgetWithText(ElevatedButton, loc.savePurchase);
            expect(save.hitTestable(), findsOneWidget);
            await sales.captureSales(
                tester, 'workspace-$language-${mode.name}-purchase-empty');
            await tester.tap(find
                .descendant(
                    of: find.byType(PurchaseItemListWidget),
                    matching: find.byType(ListTile))
                .first);
            await settleDesktop(tester);
            final fields = find.descendant(
                of: find.byType(AddPurchaseItemDialog),
                matching: find.byType(TextFormField));
            await tester.enterText(fields.at(0), '2');
            await tester.enterText(fields.at(1), '150');
            await tester
                .tap(find.widgetWithText(ElevatedButton, loc.addItemToBill));
            await settleDesktop(tester);
            expect(save.hitTestable(), findsOneWidget);
            await sales.captureSales(
                tester, 'workspace-$language-${mode.name}-purchase-cart');
          });
        } finally {
          if (originalSize != null) await windowManager.setSize(originalSize!);
        }
      });
    }
  }
}
