import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/l10n/app_localizations.dart';
import 'package:liaqat_store/models/product_model.dart';
import 'package:liaqat_store/screens/items/items_screen.dart';
import 'package:liaqat_store/screens/items/widgets/items_table.dart';

import '../support/test_database.dart';

void main() {
  useTestDatabase();
  testWidgets('catalog loads distinct pages and search resets the offset',
      (tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = ItemsRepository();
    addTearDown(repository.dispose);
    await tester.runAsync(() async {
      for (var index = 0; index < 25; index++) {
        await repository.addProduct(Product(
            nameEnglish: 'Paging ${index.toString().padLeft(2, '0')}',
            nameUrdu: 'صفحہ $index'));
      }
    });
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ItemsScreen()),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pumpAndSettle();
    ItemsTable table() => tester.widget<ItemsTable>(find.byType(ItemsTable));
    expect(table().items, hasLength(20));
    expect(table().items.map((product) => product.id).toSet(), hasLength(20));
    table()
        .scrollController
        .jumpTo(table().scrollController.position.maxScrollExtent);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pumpAndSettle();
    expect(table().items, hasLength(26));
    expect(table().items.map((product) => product.id).toSet(), hasLength(26));
    expect(table().hasNextPage, isFalse);
    await tester.enterText(find.byType(TextField), 'Paging 24');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pumpAndSettle();
    expect(table().items.single.nameEnglish, 'Paging 24');
    expect(table().hasNextPage, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
