import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory credentials/settings for the separate verification executable.
void initializeVerificationPreferences() {
  SharedPreferences.setMockInitialValues(
      {'printOnSale': false, 'soundEnabled': false});
  FlutterSecureStorage.setMockInitialValues({});
}

/// Synthetic catalog/contact volume; never reads an installed store database.
Future<void> seedLargeStore(Database db,
    {int products = 10000, int customers = 2000}) async {
  final product = Map<String, Object?>.from((await db.query('products')).first)
    ..remove('id');
  final customer =
      Map<String, Object?>.from((await db.query('customers')).first)
        ..remove('id');
  await db.transaction((txn) async {
    final batch = txn.batch();
    for (var index = 0; index < products; index++) {
      final number = index.toString().padLeft(5, '0');
      batch.insert('products', {
        ...product,
        'item_code': 'PH5-$number',
        'name_english': 'Phase5 Product $number',
        'name_urdu': 'مصنوعی چیز $number',
        'current_stock': 0
      });
    }
    for (var index = 0; index < customers; index++) {
      batch.insert('customers', {
        ...customer,
        'name_english': 'Phase5 Customer $index',
        'name_urdu': 'مصنوعی گاہک $index',
        'contact_primary': '0399${index.toString().padLeft(7, '0')}',
        'outstanding_balance': 0,
        'credit_limit': 1000000
      });
    }
    await batch.commit(noResult: true);
  });
}
