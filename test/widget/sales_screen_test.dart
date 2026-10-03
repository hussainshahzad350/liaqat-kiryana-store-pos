import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/screens/sales/sales_screen.dart';
import 'package:liaqat_store/screens/sales/widgets/sales_actions_toolbar.dart';

Widget _buildLocalizedApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('Sales screen import test', (tester) async {
    // This test primarily verifies that the file imports correctly and compiles.
    // A full smoke test for SalesScreen requires injecting SalesBloc and Repositories.
    // For now, we verify that the Type exists.
    expect(SalesScreen, isNotNull);
  });

  group('SalesActionsToolbar', () {
    testWidgets('renders the refresh and clear-cart actions', (tester) async {
      await tester.pumpWidget(
        _buildLocalizedApp(
          SalesActionsToolbar(
            onRefresh: () {},
            onClearCart: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
    });

    testWidgets('forwards toolbar taps to the screen callbacks',
        (tester) async {
      var refreshCount = 0;
      var clearCount = 0;

      await tester.pumpWidget(
        _buildLocalizedApp(
          SalesActionsToolbar(
            onRefresh: () => refreshCount++,
            onClearCart: () => clearCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.tap(find.byIcon(Icons.delete_sweep));

      expect(refreshCount, 1);
      expect(clearCount, 1);
    });
  });
}
