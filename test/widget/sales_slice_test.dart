import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/bloc/sales/sales_bloc.dart';
import 'package:liaqat_store/bloc/sales/sales_event.dart';
import 'package:liaqat_store/bloc/sales/sales_state.dart';
import 'package:liaqat_store/core/services/sales_kpi_service.dart';
import 'package:liaqat_store/core/theme/app_themes.dart';
import 'package:liaqat_store/domain/entities/money.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/models/cart_item_model.dart';
import 'package:liaqat_store/models/invoice_model.dart';
import 'package:liaqat_store/models/product_model.dart';
import 'package:liaqat_store/screens/sales/dialogs/post_sale_dialog.dart';
import 'package:liaqat_store/screens/sales/sales_screen.dart';
import 'package:liaqat_store/screens/sales/widgets/product_card.dart';
import 'package:liaqat_store/screens/sales/widgets/sales_product_panel.dart';
import 'package:liaqat_store/widgets/loading_overlay.dart';
import 'package:mocktail/mocktail.dart';

class _SalesBloc extends MockBloc<SalesEvent, SalesState>
    implements SalesBloc {}

class _Kpis extends Mock implements SalesKpiService {}

void main() {
  setUpAll(() => registerFallbackValue(SalesStarted()));
  for (final language in ['en', 'ur']) {
    for (final brightness in Brightness.values) {
      testWidgets('Sales $language $brightness loading, errors and success',
          (tester) async {
        tester.view.physicalSize = const Size(1024, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final stream = StreamController<SalesState>();
        final bloc = _SalesBloc();
        whenListen(bloc, stream.stream,
            initialState: const SalesState(status: SalesStatus.ready));
        final kpis = _Kpis();
        when(() => kpis.getSnapshot(forceRefresh: any(named: 'forceRefresh')))
            .thenAnswer((_) async => SalesKpiSnapshot(
                todaySalesTotal: 0,
                lowStockCount: 0,
                latestInvoice: null,
                cashSnapshot: Money.zero,
                fetchedAt: DateTime(2026)));
        await tester.pumpWidget(RepositoryProvider<SalesKpiService>.value(
            value: kpis,
            child: BlocProvider<SalesBloc>.value(
                value: bloc,
                child: MaterialApp(
                  theme: AppThemes.getTheme('green', brightness,
                      isRTL: language == 'ur'),
                  locale: Locale(language),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: const Scaffold(body: SalesScreen()),
                ))));
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(SalesProductPanel));
        final loc = AppLocalizations.of(context)!;
        expect(Theme.of(context).brightness, brightness);
        expect(find.text(loc.noData), findsOneWidget);
        await tester.tap(find.text(loc.recentSales));
        await tester.pumpAndSettle();
        expect(find.text(loc.noData), findsNWidgets(2));
        await tester.tap(find.text(loc.recentSales));
        await tester.pumpAndSettle();
        expect(find.text(loc.cartEmpty), findsOneWidget);
        final disabled = tester.widget<ElevatedButton>(find.widgetWithText(
            ElevatedButton, loc.checkoutButton.toUpperCase()));
        expect(disabled.onPressed, isNull);
        stream.add(const SalesState(status: SalesStatus.loading));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(LoadingOverlay), findsOneWidget);
        final product = Product(
            id: 1,
            itemCode: 'SLICE',
            nameEnglish: 'Rice',
            nameUrdu: 'چاول',
            currentStock: 45,
            salePrice: const Money(10001),
            avgCostPrice: const Money(5000));
        final ready = SalesState(
            status: SalesStatus.ready,
            filteredProducts: [product],
            cartItems: const [
              CartItem(
                  id: 1,
                  nameEnglish: 'Rice',
                  nameUrdu: 'چاول',
                  currentStock: 45,
                  unitPrice: Money(10001),
                  quantity: 1,
                  total: Money(10001))
            ],
            subtotal: const Money(10001),
            grandTotal: const Money(10001));
        stream.add(ready);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(LoadingOverlay), findsNothing);
        await tester.tap(find.byType(ProductCard));
        verify(() => bloc.add(any(that: isA<ProductAddedToCart>()))).called(1);
        stream.add(ready.copyWith(
            status: SalesStatus.error, errorMessage: 'INSUFFICIENT_STOCK'));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(find.text(loc.retry), findsOneWidget);
        expect(find.text('100.01'), findsWidgets);
        verify(() => bloc.add(any(that: isA<ClearSalesError>()))).called(1);
        await tester.tap(find.text(loc.retry));
        verify(() => bloc.add(any(that: isA<SalesStarted>()))).called(2);
        stream.add(ready.copyWith(
            status: SalesStatus.success,
            successMessage: 'Receipt sent to printer'));
        await tester.pumpAndSettle();
        expect(find.text(loc.receiptSentToPrinter), findsOneWidget);
        final invoice = Invoice(
            id: 1,
            invoiceNumber: 'SLICE-1',
            customerId: 1,
            date: DateTime(2026),
            totalAmount: 10001,
            status: Invoice.statusCompleted);
        stream.add(ready.copyWith(
            status: SalesStatus.success, completedInvoice: invoice));
        await tester.pumpAndSettle();
        expect(find.byType(PostSaleDialog), findsOneWidget);
        expect(
            Theme.of(tester.element(find.byType(PostSaleDialog))).colorScheme,
            Theme.of(context).colorScheme);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await stream.close();
      });
    }
  }
}
