import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/screens/home/home_screen.dart';
import 'package:liaqat_store/core/repositories/invoice_repository.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';

class MockInvoiceRepository extends Mock implements InvoiceRepository {}
class MockCustomersRepository extends Mock implements CustomersRepository {}
class MockItemsRepository extends Mock implements ItemsRepository {}

void main() {
  late MockInvoiceRepository mockInvoiceRepository;
  late MockCustomersRepository mockCustomersRepository;
  late MockItemsRepository mockItemsRepository;

  setUp(() {
    mockInvoiceRepository = MockInvoiceRepository();
    mockCustomersRepository = MockCustomersRepository();
    mockItemsRepository = MockItemsRepository();
  });

  testWidgets('HomeScreen renders dashboard data from injected loaders', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
        home: HomeScreen(
          invoiceRepository: mockInvoiceRepository,
          customersRepository: mockCustomersRepository,
          itemsRepository: mockItemsRepository,
          todaySalesLoader: () async => 1234500, // paisas
          todayCustomersLoader: () async => [
            {'name_english': 'Ali', 'total_amount': 4000},
          ],
          lowStockItemsLoader: () async => [
            {'name_english': 'Sugar', 'current_stock': 2},
          ],
          recentSalesLoader: () async => [
            {
              'activity_type': 'SALE',
              'title': 'INV-001',
              'customer_name': 'Ali',
              'amount': 4000,
              'timestamp': DateTime(2024, 1, 1, 10, 30).toIso8601String(),
              'status': 'COMPLETED',
            },
          ],
        ),
      ),
    );

    // Pump for 2 seconds to allow timers/animations to settle without hitting infinite loops
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Rs 12,345'), findsOneWidget);
    expect(find.text('Ali'), findsWidgets);
    expect(find.text('Sugar'), findsOneWidget);
    expect(find.text('INV-001'), findsOneWidget);
  });
}
