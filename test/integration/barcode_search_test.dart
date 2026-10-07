import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import '../support/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTestDatabase();
  test('sales search finds stored barcode without changing names or SKU',
      () async {
    final db = await DatabaseHelper.instance.database;
    await db.update('products', {'barcode': '2000000000015'}, where: 'id = 1');
    final repo = ItemsRepository();
    final matches = await repo.searchProducts('2000000000015');
    expect(matches.map((p) => p.id), [1]);
    expect(await repo.searchProducts('2000000000016'), isEmpty);
    expect((await db.query('products')).single['barcode'], '2000000000015');
    repo.dispose();
  });
}
