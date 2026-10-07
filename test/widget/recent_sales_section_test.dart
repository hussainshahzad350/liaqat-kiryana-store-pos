import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/theme/app_ui_theme.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/models/invoice_model.dart';
import 'package:liaqat_store/screens/sales/widgets/recent_sales_section.dart';

void main() {
  for (final language in ['en', 'ur']) {
    for (final brightness in Brightness.values) {
      testWidgets('$language $brightness history reveals existing actions',
          (tester) async {
        final invoice = Invoice(
            id: 7,
            invoiceNumber: 'BILL-007',
            customerId: 1,
            date: DateTime(2026, 10, 4),
            totalAmount: 18000,
            status: 'COMPLETED');
        Invoice? printed;
        int? cancelled;
        await tester.pumpWidget(MaterialApp(
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppUiTheme.build('green', brightness, isRTL: language == 'ur'),
          home: Scaffold(
              body: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                      width: 420,
                      child: RecentSalesSection(
                          recentInvoices: [invoice],
                          onPrint: (value) => printed = value,
                          onEdit: (_) {},
                          onCancel: (id, _) => cancelled = id)))),
        ));
        final section = find.byType(RecentSalesSection);
        final loc = AppLocalizations.of(tester.element(section))!;
        final compactHeight = tester.getSize(section).height;
        expect(find.text(invoice.invoiceNumber), findsNothing);
        await tester.tap(find.text(loc.recentSales));
        await tester.pumpAndSettle();
        expect(
            tester.getSize(section).height, greaterThan(compactHeight + 100));
        expect(find.text(invoice.invoiceNumber), findsOneWidget);
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(loc.printReceipt));
        await tester.pumpAndSettle();
        expect(printed, same(invoice));
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(loc.cancel));
        await tester.pumpAndSettle();
        expect(cancelled, 7);
        await tester.tap(find.text(loc.recentSales));
        await tester.pumpAndSettle();
        expect(tester.getSize(section).height, compactHeight);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
