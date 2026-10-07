import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/theme/theme_provider.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/screens/sales/dialogs/checkout_payment_dialog.dart';
import 'package:liaqat_store/screens/sales/dialogs/post_sale_dialog.dart';
import 'package:liaqat_store/screens/sales/widgets/product_card.dart';
import 'package:liaqat_store/widgets/app_shell.dart';
import 'desktop_sales_visual.dart' show captureSales;
import 'support/desktop_fixture.dart';
import 'desktop_workflows.dart' as existing_workflows;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  existing_workflows.main();
  for (final language in ['en', 'ur']) {
    for (final cash in [true, false]) {
      testWidgets('native full ${cash ? 'cash' : 'bank'} checkout $language',
          (tester) async {
        await withDesktopFixture(tester, (_) async {
          await loginDesktop(tester);
          final shell = tester.element(find.byType(AppShell));
          app.LiaqatStoreApp.setLocale(shell, Locale(language));
          await shell
              .read<ThemeProvider>()
              .setMode(cash ? ThemeMode.light : ThemeMode.dark);
          await settleDesktop(tester);
          final product = tester
              .widget<ProductCard>(find.byType(ProductCard).first)
              .product;
          await tester.tap(find.byType(ProductCard).first);
          await settleDesktop(tester);
          await tester.sendKeyEvent(LogicalKeyboardKey.f9);
          await settleDesktop(tester);
          final fields = find.descendant(
              of: find.byType(CheckoutPaymentDialog),
              matching: find.byType(TextField));
          expect(fields, findsNothing);
          await tester.tap(
              find.byKey(ValueKey(cash ? 'checkout-cash' : 'checkout-bank')));
          await settleDesktop(tester);
          await captureSales(
              tester, 'checkout-ux-$language-${cash ? 'cash' : 'bank'}');
          await tester.tap(find.descendant(
              of: find.byType(CheckoutPaymentDialog),
              matching: find.byType(ElevatedButton)));
          await settleDesktop(tester);
          expect(find.byType(PostSaleDialog), findsOneWidget);
          final db = await DatabaseHelper.instance.database;
          final invoice = (await db.query('invoices')).single;
          expect(invoice['grand_total'], product.salePrice.paisas);
          final payment =
              jsonDecode(invoice['notes'] as String) as Map<String, dynamic>;
          expect(payment['cash'], cash ? product.salePrice.paisas : 0);
          expect(payment['bank'], cash ? 0 : product.salePrice.paisas);
          expect(payment['credit'], 0);
          final ledger = (await db.query('cash_ledger')).single;
          expect(ledger['payment_mode'], cash ? 'CASH' : 'BANK');
          expect(ledger['amount'], product.salePrice.paisas);
        });
      });
    }
  }
}
