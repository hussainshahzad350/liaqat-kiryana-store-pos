import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/widgets/app_state_view.dart';

Widget _buildApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('AppStateView', () {
    testWidgets('renders an indeterminate loading state', (tester) async {
      await tester.pumpWidget(_buildApp(const AppStateView.loading()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('renders an empty-state icon and message', (tester) async {
      await tester.pumpWidget(_buildApp(
        const AppStateView.empty(
          message: 'Nothing here yet',
          icon: Icons.inventory_2_outlined,
        ),
      ));

      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      expect(find.text('Nothing here yet'), findsOneWidget);
    });

    testWidgets('forwards the recoverable error action', (tester) async {
      var retryCount = 0;
      await tester.pumpWidget(_buildApp(
        AppStateView.error(
          message: 'Could not load records',
          actionLabel: 'Retry',
          onRetry: () => retryCount++,
        ),
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Could not load records'), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, Theme.of(tester.element(find.byType(AppStateView)))
          .colorScheme
          .error);

      await tester.tap(find.text('Retry'));
      expect(retryCount, 1);
    });
  });
}
