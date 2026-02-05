import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/screens/home/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders dashboard data from injected loaders', (
    WidgetTester tester,
  ) async {
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
          todaySalesLoader: () async => 12345,
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

    await tester.pumpAndSettle();

    expect(find.text('Rs 12,345'), findsOneWidget);
    expect(find.text('Ali'), findsWidgets);
    expect(find.text('Sugar'), findsOneWidget);
    expect(find.text('INV-001'), findsOneWidget);
  });
}
