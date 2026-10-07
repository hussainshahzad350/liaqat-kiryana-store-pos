import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/theme/app_ui_theme.dart';
import 'package:liaqat_store/domain/entities/money.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/screens/sales/widgets/sales_totals_section.dart';

void main() {
  for (final language in ['en', 'ur']) {
    testWidgets(
        '$language long financial values remain complete in narrow cart',
        (tester) async {
      final discount = TextEditingController();
      addTearDown(discount.dispose);
      const amount = Money(99999999999999);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppUiTheme.build('green', Brightness.light,
            isRTL: language == 'ur'),
        home: Scaffold(
            body: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.25)),
                child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                        width: 360,
                        child: SalesTotalsSection(
                            discountController: discount,
                            subtotal: amount,
                            discount: Money.zero,
                            previousBalance: amount,
                            grandTotal: amount,
                            isCheckoutEnabled: true,
                            onCheckout: () {},
                            onDiscountChanged: (_) {}))))),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(amount.toString()), findsNWidgets(3));
      for (final text in find.text(amount.toString()).evaluate()) {
        final paragraph = text.renderObject! as RenderParagraph;
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(paragraph.overflow, isNot(TextOverflow.ellipsis));
      }
    });
  }
}
