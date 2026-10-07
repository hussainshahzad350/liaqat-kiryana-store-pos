import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/theme/theme_provider.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/screens/auth/login_screen.dart';
import 'package:liaqat_store/screens/sales/dialogs/checkout_payment_dialog.dart';
import 'package:liaqat_store/screens/sales/dialogs/post_sale_dialog.dart';
import 'package:liaqat_store/screens/sales/widgets/product_card.dart';
import 'package:liaqat_store/screens/sales/widgets/sales_product_panel.dart';
import 'package:liaqat_store/screens/sales/widgets/cart_item_row.dart';
import 'package:liaqat_store/screens/sales/widgets/sales_totals_section.dart';
import 'package:liaqat_store/widgets/app_shell.dart';
import 'package:liaqat_store/widgets/on_screen_keyboard.dart';
import 'support/desktop_fixture.dart';

Future<void> _capture(WidgetTester tester, String name) async {
  final view = tester.binding.renderViews.first;
  final scene = view.debugLayer!.buildScene(ui.SceneBuilder());
  final picture = await scene.toImage(
      view.flutterView.physicalSize.width.round(),
      view.flutterView.physicalSize.height.round());
  scene.dispose();
  final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
  final folder = Directory('build/mouse-input-review');
  await folder.create(recursive: true);
  await File('${folder.path}/$name.png')
      .writeAsBytes(bytes!.buffer.asUint8List());
  picture.dispose();
}

Future<void> _typeWithMouse(WidgetTester tester, Finder field, String text,
    {bool urdu = false, String? capture}) async {
  await tester.tap(field);
  await settleDesktop(tester);
  await tester.tap(find.byKey(const ValueKey('open-on-screen-keyboard')));
  await settleDesktop(tester);
  expect(find.byType(OnScreenKeyboard), findsOneWidget);
  final loc =
      AppLocalizations.of(tester.element(find.byType(OnScreenKeyboard)))!;
  await tester.tap(find.text(loc.clearInput));
  if (urdu) {
    await tester.tap(find.widgetWithText(ChoiceChip, 'اردو'));
    await settleDesktop(tester);
  }
  for (final character in text.characters) {
    final key = find.byKey(ValueKey('keyboard-key-$character'));
    await tester.ensureVisible(key);
    await tester.tap(key);
    await tester.pump();
  }
  if (capture != null) await _capture(tester, capture);
  await tester.tap(find.byKey(const ValueKey('keyboard-apply')));
  await tester.pump(const Duration(milliseconds: 650));
  await settleDesktop(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final language in ['en', 'ur']) {
    testWidgets(
        'mouse-only PIN, search, quantity, price, discount and payment $language',
        (tester) async {
      await withDesktopFixture(tester, (_) async {
        await windowManager.setSize(const Size(1024, 720));
        await settleDesktop(tester);
        await _typeWithMouse(tester, find.byType(TextField).first, '2468',
            capture: '$language-pin');
        await tester.tap(find.descendant(
            of: find.byType(LoginScreen), matching: find.byType(FilledButton)));
        await settleDesktop(tester);
        expect(find.byType(AppShell), findsOneWidget);
        final shell = tester.element(find.byType(AppShell));
        app.LiaqatStoreApp.setLocale(shell, Locale(language));
        await shell
            .read<ThemeProvider>()
            .setMode(language == 'ur' ? ThemeMode.dark : ThemeMode.light);
        await settleDesktop(tester);
        await _typeWithMouse(
            tester,
            find.descendant(
                of: find.byType(SalesProductPanel),
                matching: find.byType(TextField)),
            language == 'ur' ? 'چاول' : 'rice',
            urdu: language == 'ur',
            capture: '$language-search');
        expect(find.byType(ProductCard), findsWidgets);
        await tester.tap(find.byType(ProductCard).first);
        await settleDesktop(tester);
        await tester.tap(find.byKey(const ValueKey('quantity-increase-1')));
        await tester.pump(const Duration(milliseconds: 650));
        await settleDesktop(tester);
        expect(
            tester.widget<CartItemRow>(find.byType(CartItemRow)).item.quantity,
            2);
        await _typeWithMouse(
            tester,
            find
                .descendant(
                    of: find.byType(CartItemRow),
                    matching: find.byType(TextField))
                .first,
            '100.50');
        await _typeWithMouse(
            tester,
            find.descendant(
                of: find.byType(SalesTotalsSection),
                matching: find.byType(TextField)),
            '1');
        expect(
            tester
                .widget<SalesTotalsSection>(find.byType(SalesTotalsSection))
                .grandTotal
                .paisas,
            20000);
        await _capture(tester, '$language-cart');
        await tester.tap(find.descendant(
            of: find.byType(SalesTotalsSection),
            matching: find.byType(ElevatedButton)));
        await settleDesktop(tester);
        await tester.tap(find.byKey(
            ValueKey(language == 'ur' ? 'checkout-bank' : 'checkout-cash')));
        await settleDesktop(tester);
        await tester.tap(find.descendant(
            of: find.byType(CheckoutPaymentDialog),
            matching: find.byType(ElevatedButton)));
        await settleDesktop(tester);
        expect(find.byType(PostSaleDialog), findsOneWidget);
        final db = await DatabaseHelper.instance.database;
        final invoice = (await db.query('invoices')).single;
        expect(invoice['grand_total'], 20000);
        final line = (await db.query('invoice_items')).single;
        expect(line['quantity'], 2);
        expect(line['unit_price'], 10050);
        expect((await db.query('cash_ledger')).single['payment_mode'],
            language == 'ur' ? 'BANK' : 'CASH');
        final loc =
            AppLocalizations.of(tester.element(find.byType(PostSaleDialog)))!;
        await tester.tap(find.text(loc.startNewSale));
        await settleDesktop(tester);
        expect(find.byType(CartItemRow), findsNothing);
      });
    });
  }
}
