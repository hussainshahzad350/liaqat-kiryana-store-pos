import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liaqat_store/core/theme/theme_provider.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/screens/sales/dialogs/checkout_payment_dialog.dart';
import 'package:liaqat_store/screens/sales/widgets/product_card.dart';
import 'package:liaqat_store/screens/sales/widgets/sales_product_panel.dart';
import 'package:liaqat_store/widgets/app_shell.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'support/desktop_fixture.dart';

Future<void> captureSales(WidgetTester tester, String name) async {
  // Dialogs occupy a sibling overlay route, outside the shell boundary.
  final target = find.byType(CheckoutPaymentDialog).evaluate().isNotEmpty
      ? find.byType(CheckoutPaymentDialog)
      : find.byType(AppShell);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.ancestor(of: target, matching: find.byType(RepaintBoundary)).first);
  final screenshot = await boundary.toImage();
  try {
    final bytes = await screenshot.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/sales-phase3-review');
    await directory.create(recursive: true);
    await File('${directory.path}/after-$name.png').writeAsBytes(
        bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
  } finally {
    screenshot.dispose();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final language in ['en', 'ur']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Sales $language ${mode.name} minimum visual states',
          (tester) async {
        Size? originalSize;
        try {
          await withDesktopFixture(tester, (_) async {
            await loginDesktop(tester);
            originalSize = await windowManager.getSize();
            final shellContext = tester.element(find.byType(AppShell));
            app.LiaqatStoreApp.setLocale(shellContext, Locale(language));
            await shellContext.read<ThemeProvider>().setMode(mode);
            await windowManager.setSize(const Size(1024, 720));
            await settleDesktop(tester);
            final loc = AppLocalizations.of(shellContext)!;
            final panel = tester.element(find.byType(SalesProductPanel));
            expect(Theme.of(panel).brightness,
                mode == ThemeMode.dark ? Brightness.dark : Brightness.light);
            expect(Directionality.of(panel),
                language == 'ur' ? TextDirection.rtl : TextDirection.ltr);
            await captureSales(tester, '$language-${mode.name}-empty');
            final search = find.descendant(
                of: find.byType(SalesProductPanel),
                matching: find.byType(TextField));
            await tester.enterText(search, 'no-such-product-phase3');
            await settleDesktop(tester);
            expect(find.text(loc.noData), findsWidgets);
            await captureSales(tester, '$language-${mode.name}-no-results');
            await tester.enterText(search, '');
            await settleDesktop(tester);
            await tester.tap(find.byType(ProductCard).first);
            await settleDesktop(tester);
            await captureSales(tester, '$language-${mode.name}-cart');
            await tester.sendKeyEvent(LogicalKeyboardKey.f9);
            await settleDesktop(tester);
            expect(find.byType(CheckoutPaymentDialog), findsOneWidget);
            final dialogContext =
                tester.element(find.byType(CheckoutPaymentDialog));
            expect(Theme.of(dialogContext).colorScheme,
                Theme.of(panel).colorScheme);
            await captureSales(tester, '$language-${mode.name}-checkout');
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await settleDesktop(tester);
            expect(find.byType(CheckoutPaymentDialog), findsNothing);
          });
        } finally {
          if (originalSize != null) await windowManager.setSize(originalSize!);
        }
      });
    }
  }
}
