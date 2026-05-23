import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/services/sales_kpi_service.dart';
import 'package:liaqat_store/domain/entities/money.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/models/invoice_model.dart';
import 'package:liaqat_store/screens/sales/widgets/sales_kpi_header.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesKpiService extends Mock implements SalesKpiService {}

void main() {
  late MockSalesKpiService mockSalesKpiService;

  setUp(() {
    mockSalesKpiService = MockSalesKpiService();
  });

  testWidgets('SalesKpiHeader renders snapshot data', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(
      () => mockSalesKpiService.getSnapshot(
          forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer(
      (_) async => SalesKpiSnapshot(
        todaySalesTotal: 1234500,
        lowStockCount: 2,
        latestInvoice: Invoice(
          invoiceNumber: 'INV-001',
          customerId: 1,
          date: DateTime(2024, 1, 1, 10, 30),
          totalAmount: 4000,
          status: Invoice.statusCompleted,
        ),
        cashSnapshot: const Money(500000),
        fetchedAt: DateTime(2024, 1, 1, 10, 30),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SalesKpiHeader(service: mockSalesKpiService),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('12,345'), findsOneWidget);
    expect(find.text('INV-001'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('5,000'), findsOneWidget);
  });
}
