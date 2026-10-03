import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/widgets/app_search_card.dart';

Widget _buildApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('AppSearchCard', () {
    testWidgets('forwards text changes', (tester) async {
      String? query;
      await tester.pumpWidget(_buildApp(
        AppSearchCard(
          hintText: 'Search records',
          onChanged: (value) => query = value,
          autoFocus: false,
        ),
      ));

      await tester.enterText(find.byType(TextField), 'rice');

      expect(query, 'rice');
      expect(find.text('rice'), findsOneWidget);
    });

    testWidgets('forwards desktop list-navigation keys', (tester) async {
      var moveDownCount = 0;
      var moveUpCount = 0;
      var submitCount = 0;
      await tester.pumpWidget(_buildApp(
        AppSearchCard(
          hintText: 'Search records',
          onChanged: (_) {},
          onMoveDown: () => moveDownCount++,
          onMoveUp: () => moveUpCount++,
          onSubmitSelection: () => submitCount++,
        ),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      expect(moveDownCount, 1);
      expect(moveUpCount, 1);
      expect(submitCount, 1);
    });

    testWidgets('ignores navigation keys without optional callbacks',
        (tester) async {
      await tester.pumpWidget(_buildApp(
        AppSearchCard(
          hintText: 'Search records',
          onChanged: (_) {},
        ),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
