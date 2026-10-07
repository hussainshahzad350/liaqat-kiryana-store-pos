import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/receipt_repository.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/main.dart' as app;
import 'package:liaqat_store/screens/sales/dialogs/post_sale_dialog.dart';
import 'package:liaqat_store/widgets/app_shell.dart';
import 'package:printing/src/interface.dart';
import '../support/receipt_fixture.dart' as fixture;
import 'support/desktop_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final language in ['en', 'ur']) {
    testWidgets('$language print once, cancel and export receipt',
        (tester) async {
      await withDesktopFixture(tester, (_) async {
        await loginDesktop(tester);
        final context = tester.element(find.byType(AppShell));
        app.LiaqatStoreApp.setLocale(context, Locale(language));
        await settleDesktop(tester);
        final loc = AppLocalizations.of(context)!;
        final original = PrintingPlatform.instance;
        final printer = fixture.TestPrinter();
        PrintingPlatform.instance = printer;
        try {
          final db = await DatabaseHelper.instance.database;
          final tables = [
            'invoices',
            'invoice_items',
            'receipts',
            'products',
            'customers',
            'customer_ledger',
            'supplier_ledger',
            'cash_ledger',
            'stock_activities'
          ];
          final before = {
            for (final table in tables) table: await db.query(table)
          };
          final output =
              await Directory('${File(db.path).parent.path}/exports').create();
          final repository =
              ReceiptRepository(documentsDirectory: () async => output);
          // Exercise the real post-sale buttons without issuing physical print jobs.
          showDialog<void>(
              context: context,
              builder: (_) => PostSaleDialog(
                  invoice: fixture.invoice(), receiptRepository: repository));
          await settleDesktop(tester);
          final print = find.widgetWithText(OutlinedButton, loc.printReceipt);
          await tester.tap(print);
          await settleDesktop(tester);
          expect(printer.calls, 1);
          expect(find.textContaining(loc.receiptSentToPrinter), findsNothing);
          printer.accepted = true;
          await tester.tap(print);
          await settleDesktop(tester);
          expect(printer.calls, 2);
          expect(find.textContaining(loc.receiptSentToPrinter), findsOneWidget);
          await tester.tap(find.widgetWithText(OutlinedButton, loc.saveAsPdf));
          await settleDesktop(tester);
          final file = File('${output.path}/Invoice_QA_001.pdf');
          expect(await file.exists(), isTrue);
          expect(await file.length(), greaterThan(1000));
          for (final table in tables) {
            expect(await db.query(table), before[table], reason: table);
          }
        } finally {
          PrintingPlatform.instance = original;
        }
      });
    });
  }
}
