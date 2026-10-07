import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/core/services/pin_auth_service.dart';
import 'package:liaqat_store/domain/entities/money.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/models/customer_model.dart';
import 'package:liaqat_store/screens/auth/login_screen.dart';
import 'package:liaqat_store/screens/sales/dialogs/cancel_sale_dialog.dart';
import 'package:liaqat_store/screens/sales/dialogs/checkout_payment_dialog.dart';
import 'package:liaqat_store/screens/sales/dialogs/post_sale_dialog.dart';
import 'package:liaqat_store/screens/sales/widgets/customer_section.dart';
import 'package:liaqat_store/screens/sales/widgets/product_card.dart';
import 'package:liaqat_store/screens/sales/widgets/cart_item_row.dart';
import 'package:liaqat_store/widgets/app_shell.dart';

import 'support/desktop_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PIN lockout, recovery, logout and re-login', (tester) async {
    await withDesktopFixture(tester, (recovery) async {
      final loc =
          AppLocalizations.of(tester.element(find.byType(LoginScreen)))!;
      for (var attempt = 0; attempt < PinAuthService.maxAttempts; attempt++) {
        await tester.enterText(find.byType(TextField).first, '9999');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await settleDesktop(tester);
        expect(find.byType(AppShell), findsNothing);
      }
      expect((await PinAuthService().getLockoutStatus()).isLocked, isTrue);
      expect(tester.widget<TextField>(find.byType(TextField).first).enabled,
          isFalse);
      await tester.tap(find.text(loc.forgotPassword));
      await settleDesktop(tester);
      await tester.enterText(find.byType(TextField).first, 'INVALID-CODE');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settleDesktop(tester);
      expect(find.text(loc.recoveryCodeInvalid), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, recovery);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settleDesktop(tester);
      await tester.enterText(find.byType(TextField).at(0), '5678');
      await tester.enterText(find.byType(TextField).at(1), '5678');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settleDesktop(tester);
      expect(find.text(loc.recoveryCodeTitle), findsOneWidget);
      await tester.tap(find.text(loc.save));
      await settleDesktop(tester);
      expect(find.byType(AppShell), findsOneWidget);
      expect((await PinAuthService().getLockoutStatus()).isLocked, isFalse);
      expect(await PinAuthService().verifyRecoveryCode(recovery), isFalse);
      await tester.tap(find.text(loc.logout));
      await settleDesktop(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(await PinAuthService().verifyPin('2468'), PinVerifyResult.invalid);
      await loginDesktop(tester, pin: '5678');
    });
  });

  for (final payment in [
    (name: 'cash', cash: 180, bank: 0, credit: 0),
    (name: 'bank', cash: 0, bank: 180, credit: 0),
    (name: 'credit', cash: 0, bank: 0, credit: 180),
    (name: 'mixed', cash: 60, bank: 40, credit: 80),
  ]) {
    testWidgets('${payment.name} checkout and exactly-once cancellation',
        (tester) async {
      await withDesktopFixture(tester, (_) async {
        final customerId = await CustomersRepository().addCustomer(Customer(
          nameEnglish: 'Desktop Credit Customer',
          contactPrimary: '0300-1234567',
          creditLimit: 1000000,
        ));
        await loginDesktop(tester);
        final loc = AppLocalizations.of(tester.element(find.byType(AppShell)))!;
        await tester.enterText(
            find.descendant(
                of: find.byType(CustomerSection),
                matching: find.byType(TextField)),
            'Desktop Credit');
        for (var attempt = 0;
            attempt < 100 &&
                find.text('Desktop Credit Customer').evaluate().isEmpty;
            attempt++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await settleDesktop(tester);
        expect(find.text('Desktop Credit Customer'), findsOneWidget);
        await tester.tap(find.text('Desktop Credit Customer'));
        await settleDesktop(tester);
        await tester.tap(find.byType(ProductCard).first);
        // pumpAndSettle does not await the asynchronous repository read used
        // by AddCartItem. Wait for the resulting cart before sending F9.
        for (var attempt = 0;
            attempt < 100 && find.byType(CartItemRow).evaluate().isEmpty;
            attempt++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(CartItemRow), findsOneWidget);
        await settleDesktop(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.f9);
        await settleDesktop(tester);
        expect(find.byType(CheckoutPaymentDialog), findsOneWidget);
        await tester
            .tap(find.byKey(const ValueKey('checkout-other-payment-options')));
        await settleDesktop(tester);
        final fields = find.descendant(
            of: find.byType(CheckoutPaymentDialog),
            matching: find.byType(TextField));
        final save = find.widgetWithText(ElevatedButton, loc.proceedPayment);
        expect(tester.widget<ElevatedButton>(save).onPressed, isNull);
        final db = await DatabaseHelper.instance.database;
        expect(await db.query('invoices'), isEmpty);
        await tester.enterText(fields.at(0), '181');
        await tester.enterText(fields.at(1), '0');
        await tester.enterText(fields.at(2), '0');
        await settleDesktop(tester);
        expect(tester.widget<ElevatedButton>(save).onPressed, isNull);
        expect(await db.query('invoices'), isEmpty);
        await tester.enterText(fields.at(0), '${payment.cash}');
        await tester.enterText(fields.at(1), '${payment.bank}');
        await tester.enterText(fields.at(2), '${payment.credit}');
        await settleDesktop(tester);
        expect(tester.widget<ElevatedButton>(save).onPressed, isNotNull);
        await tester.tap(save);
        await settleDesktop(tester);
        expect(find.byType(PostSaleDialog), findsOneWidget);
        final invoice = (await db.query('invoices')).single;
        expect(invoice['customer_id'], customerId);
        expect(invoice['grand_total'], 18000);
        expect(
            (await db.query('products', where: 'id = 1'))
                .single['current_stock'],
            44);
        expect(
            (await db.query('customers',
                    where: 'id = ?', whereArgs: [customerId]))
                .single['outstanding_balance'],
            payment.credit * 100);
        final cash = await db.rawQuery(
            'SELECT COALESCE(SUM(amount), 0) AS total FROM cash_ledger');
        expect(cash.single['total'], (payment.cash + payment.bank) * 100);
        await tester.tap(find.text(loc.startNewSale));
        await settleDesktop(tester);
        await tester.tap(find.byType(ExpansionTile));
        await settleDesktop(tester);
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await settleDesktop(tester);
        await tester.tap(find.text(loc.cancel).last);
        await settleDesktop(tester);
        expect(find.byType(CancelSaleDialog), findsOneWidget);
        await tester.enterText(
            find
                .descendant(
                    of: find.byType(CancelSaleDialog),
                    matching: find.byType(TextField))
                .first,
            'Disposable desktop smoke test');
        await settleDesktop(tester);
        await tester.tap(find.widgetWithText(ElevatedButton, loc.cancelSale));
        await settleDesktop(tester);
        expect((await db.query('invoices')).single['status'], 'CANCELLED');
        expect(
            (await db.query('products', where: 'id = 1'))
                .single['current_stock'],
            45);
        expect(
            (await db.query('customers',
                    where: 'id = ?', whereArgs: [customerId]))
                .single['outstanding_balance'],
            0);
        expect(
            (await db.rawQuery(
                    "SELECT COALESCE(SUM(CASE WHEN type = 'IN' THEN amount ELSE -amount END), 0) AS total FROM cash_ledger"))
                .single['total'],
            0);
        final after = await db.query('stock_activities', orderBy: 'id');
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await settleDesktop(tester);
        expect(find.text(loc.cancelled), findsOneWidget);
        expect(find.text(loc.cancel).hitTestable(), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settleDesktop(tester);
        expect(await db.query('stock_activities', orderBy: 'id'), after);
      });
    });
  }

  testWidgets('walk-in underpayment rejection and overpayment change',
      (tester) async {
    await withDesktopFixture(tester, (_) async {
      await loginDesktop(tester);
      final loc = AppLocalizations.of(tester.element(find.byType(AppShell)))!;
      await tester.tap(find.byType(ProductCard).first);
      // pumpAndSettle does not await the asynchronous repository read used
      // by AddCartItem. Wait for the resulting cart before sending F9.
      for (var attempt = 0;
          attempt < 100 && find.byType(CartItemRow).evaluate().isEmpty;
          attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(CartItemRow), findsOneWidget);
      await settleDesktop(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f9);
      await settleDesktop(tester);
      expect(find.byType(CheckoutPaymentDialog), findsOneWidget);
      await tester
          .tap(find.byKey(const ValueKey('checkout-other-payment-options')));
      await settleDesktop(tester);
      final fields = find.descendant(
          of: find.byType(CheckoutPaymentDialog),
          matching: find.byType(TextField));
      expect(fields, findsNWidgets(2)); // Walk-in checkout has no credit input.
      final save = find.widgetWithText(ElevatedButton, loc.proceedPayment);
      await tester.enterText(fields.at(0), '179');
      await tester.enterText(fields.at(1), '0');
      await settleDesktop(tester);
      expect(tester.widget<ElevatedButton>(save).onPressed, isNull);
      final db = await DatabaseHelper.instance.database;
      expect(await db.query('invoices'), isEmpty);
      expect(await db.query('cash_ledger'), isEmpty);
      final customersBefore = await db.query('customers', orderBy: 'id');
      final customerLedgerBefore =
          await db.query('customer_ledger', orderBy: 'id');
      expect((await db.query('products')).single['current_stock'], 45);
      await tester.enterText(fields.at(0), '181');
      await settleDesktop(tester);
      expect(tester.widget<ElevatedButton>(save).onPressed, isNotNull);
      expect(find.text(const Money(100).toString()), findsOneWidget);
      await tester.tap(save);
      await settleDesktop(tester);
      expect(find.byType(PostSaleDialog), findsOneWidget);
      final invoice = (await db.query('invoices')).single;
      expect(invoice['customer_id'], 1);
      expect(invoice['grand_total'], 18000);
      expect((await db.query('cash_ledger')).single['amount'], 18000);
      expect(await db.query('customers', orderBy: 'id'), customersBefore);
      expect(await db.query('customer_ledger', orderBy: 'id'),
          customerLedgerBefore);
      expect((await db.query('products')).single['current_stock'], 44);
    });
  });
}
