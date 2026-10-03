import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/models/product_model.dart';
import 'package:liaqat_store/screens/items/widgets/items_table.dart';
import 'package:liaqat_store/screens/items/widgets/items_toolbar.dart';

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
  group('ItemsToolbar', () {
    testWidgets('forwards search, clear, and add actions', (tester) async {
      final searchController = TextEditingController();
      addTearDown(searchController.dispose);
      var searchCount = 0;
      var clearCount = 0;
      var addCount = 0;

      await tester.pumpWidget(_buildLocalizedApp(
        ItemsToolbar(
          searchController: searchController,
          onSearch: () => searchCount++,
          onClearSearch: () => clearCount++,
          onAddItem: () => addCount++,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.tap(find.byIcon(Icons.clear));
      await tester.tap(find.byIcon(Icons.add));

      expect(searchCount, 1);
      expect(clearCount, 1);
      expect(addCount, 1);
    });
  });

  group('ItemsTable', () {
    testWidgets('shows the localized empty state', (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(_buildLocalizedApp(
        ItemsTable(
          items: const [],
          categoryNames: const {},
          subCategoryNames: const {},
          scrollController: scrollController,
          isInitialLoading: false,
          isLoadingMore: false,
          hasNextPage: false,
          onEditItem: (_) {},
          onDeleteItem: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No items found'), findsOneWidget);
      expect(find.byType(DataTable), findsNothing);
    });

    testWidgets('renders item data and forwards row actions', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      final item = Product(
        id: 7,
        nameEnglish: 'Flour',
        nameUrdu: 'آٹا',
        categoryId: 2,
        subCategoryId: 3,
        brand: 'Test Brand',
        unitType: 'KG',
        packingType: 'Bag',
      );
      Product? editedItem;
      int? deletedId;

      await tester.pumpWidget(_buildLocalizedApp(
        ItemsTable(
          items: [item],
          categoryNames: const {2: 'Grocery'},
          subCategoryNames: const {3: 'Flour'},
          scrollController: scrollController,
          isInitialLoading: false,
          isLoadingMore: false,
          hasNextPage: true,
          onEditItem: (value) => editedItem = value,
          onDeleteItem: (value) => deletedId = value,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Test Brand'), findsOneWidget);
      expect(find.text('KG'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.tap(find.byIcon(Icons.delete_outline));

      expect(editedItem, same(item));
      expect(deletedId, 7);
    });
  });
}
