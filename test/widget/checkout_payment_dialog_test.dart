import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:liaqat_store/bloc/sales/sales_bloc.dart';
import 'package:liaqat_store/bloc/sales/sales_event.dart';
import 'package:liaqat_store/bloc/sales/sales_state.dart';
import 'package:liaqat_store/core/theme/app_themes.dart';
import 'package:liaqat_store/domain/entities/money.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/models/customer_model.dart';
import 'package:liaqat_store/screens/sales/dialogs/checkout_payment_dialog.dart';
import 'package:liaqat_store/screens/sales/dialogs/credit_limit_warning_dialog.dart';

class _SalesBloc extends MockBloc<SalesEvent, SalesState>
    implements SalesBloc {}

Future<_SalesBloc> _openCheckout(
  WidgetTester tester, {
  String language = 'en',
  Brightness brightness = Brightness.light,
  Customer? customer,
  double scale = 1,
}) async {
  final bloc = _SalesBloc();
  whenListen(bloc, const Stream<SalesState>.empty(),
      initialState: SalesState(
        status: SalesStatus.ready,
        grandTotal: const Money(20025),
        selectedCustomer: customer,
      ));
  await tester.pumpWidget(BlocProvider<SalesBloc>.value(
    value: bloc,
    child: MaterialApp(
      theme: AppThemes.getTheme('green', brightness, isRTL: language == 'ur'),
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => BlocProvider<SalesBloc>.value(
                            value: bloc, child: const CheckoutPaymentDialog())),
                    child: const Text('Open checkout'),
                  ))),
    ),
  ));
  await tester.tap(find.text('Open checkout'));
  await tester.pumpAndSettle();
  return bloc;
}

void main() {
  setUpAll(() => registerFallbackValue(SalesStarted()));
  for (final language in ['en', 'ur']) {
    for (final brightness in Brightness.values) {
      for (final cash in [true, false]) {
        testWidgets(
            'full ${cash ? 'cash' : 'bank'} $language $brightness sends exact total',
            (tester) async {
          final bloc = await _openCheckout(tester,
              language: language,
              brightness: brightness,
              customer: Customer(
                  id: 2,
                  nameEnglish: 'Ali',
                  nameUrdu: 'علی',
                  creditLimit: 100));
          expect(find.byType(TextField), findsNothing);
          expect(find.text(const Money(20025).toString()), findsOneWidget);
          expect(
              tester
                  .widget<ElevatedButton>(find.byType(ElevatedButton))
                  .onPressed,
              isNull);
          // Switching a choice must clear the previous tender completely.
          await tester.tap(
              find.byKey(ValueKey(cash ? 'checkout-bank' : 'checkout-cash')));
          await tester.pumpAndSettle();
          await tester.tap(
              find.byKey(ValueKey(cash ? 'checkout-cash' : 'checkout-bank')));
          await tester.pumpAndSettle();
          expect(
              tester
                  .widget<ChoiceChip>(find.byKey(
                      ValueKey(cash ? 'checkout-cash' : 'checkout-bank')))
                  .selected,
              isTrue);
          await tester.tap(find.byType(ElevatedButton));
          await tester.pumpAndSettle();
          final event =
              verify(() => bloc.add(captureAny(that: isA<InvoiceProcessed>())))
                  .captured
                  .single as InvoiceProcessed;
          expect(event.cash, cash ? const Money(20025) : Money.zero);
          expect(event.bank, cash ? Money.zero : const Money(20025));
          expect(event.credit, Money.zero);
          expect(event.change, Money.zero);
          expect(event.languageCode, language);
          expect(find.byType(CreditLimitWarningDialog), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  testWidgets('walk-in custom amount keeps underpayment validation and change',
      (tester) async {
    final bloc = await _openCheckout(tester);
    await tester
        .tap(find.byKey(const ValueKey('checkout-other-payment-options')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).first, '199');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
    await tester.enterText(find.byType(TextField).first, '-1');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
    await tester.enterText(find.byType(TextField).first, '201');
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    final event =
        verify(() => bloc.add(captureAny(that: isA<InvoiceProcessed>())))
            .captured
            .single as InvoiceProcessed;
    expect(event.cash, const Money(20100));
    expect(event.change, const Money(75));
    expect(event.bank, Money.zero);
  });
  testWidgets('custom split still computes remaining credit', (tester) async {
    final bloc = await _openCheckout(tester,
        customer: Customer(id: 2, nameEnglish: 'Ali', creditLimit: 100000));
    await tester
        .tap(find.byKey(const ValueKey('checkout-other-payment-options')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '100');
    await tester.enterText(find.byType(TextField).at(1), '50');
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    final event =
        verify(() => bloc.add(captureAny(that: isA<InvoiceProcessed>())))
            .captured
            .single as InvoiceProcessed;
    expect(event.cash, const Money(10000));
    expect(event.bank, const Money(5000));
    expect(event.credit, const Money(5025));
    expect(event.change, Money.zero);
  });
  for (final language in ['en', 'ur']) {
    testWidgets('compact checkout wraps at enlarged text $language',
        (tester) async {
      tester.view.physicalSize = const Size(520, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _openCheckout(tester, language: language, scale: 1.3);
      await tester.tap(find.byKey(const ValueKey('checkout-bank')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsNothing);
    });
  }
}
