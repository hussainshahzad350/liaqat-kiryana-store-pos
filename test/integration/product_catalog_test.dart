import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/models/product_model.dart';

import '../support/test_database.dart';

void main() {
  useTestDatabase();
  test('metadata edit preserves the stored creation timestamp and stock',
      () async {
    final repository = ItemsRepository();
    addTearDown(repository.dispose);
    final db = await DatabaseHelper.instance.database;
    final before = (await db.query('products', where: 'id = 1')).single;
    final product = (await repository.getProductById(1))!;
    await repository.updateProduct(
        1, product.copyWith(brand: 'Metadata edit', currentStock: 0));
    final after = (await db.query('products', where: 'id = 1')).single;
    expect(after['created_at'], before['created_at']);
    expect(after['current_stock'], before['current_stock']);
    expect(after['avg_cost_price'], before['avg_cost_price']);
    expect(after['sale_price'], before['sale_price']);
  });
  test('catalog paging filters archives and searches beyond the first page',
      () async {
    final repository = ItemsRepository();
    addTearDown(repository.dispose);
    for (var index = 0; index < 23; index++) {
      await repository.addProduct(Product(
          nameEnglish: 'Catalog ${index.toString().padLeft(2, '0')}',
          nameUrdu: 'کیٹلاگ $index',
          itemCode: 'CAT$index'));
    }
    final first =
        await repository.getCatalogProducts(query: 'Catalog', limit: 20);
    final second = await repository.getCatalogProducts(
        query: 'Catalog', limit: 20, offset: 20);
    expect(first, hasLength(20));
    expect(second, hasLength(3));
    expect([...first, ...second].map((product) => product.id).toSet(),
        hasLength(23));
    expect(await repository.getCatalogProducts(query: 'Catalog', offset: 23),
        isEmpty);
    await repository.deleteProduct(second.last.id!);
    expect(await repository.getCatalogProducts(query: 'CAT22'), isEmpty);
    expect((await repository.getCatalogProducts(query: '  CAT21  ')).single.id,
        second[1].id);
    expect((await repository.getCatalogProducts(query: 'کیٹلاگ 21')).single.id,
        second[1].id);
  });
}
