// test/unit/purchase_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/purchase_repository.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';

void main() {
  late PurchaseRepository purchaseRepo;
  late ItemsRepository itemsRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper.instance.resetDatabase();
    purchaseRepo = PurchaseRepository();
    itemsRepo = ItemsRepository();
  });

  group('PurchaseRepository.cancelPurchase', () {
    test('should cancel purchase when sufficient stock exists', () async {
      // Create a purchase first
      final purchaseId = await purchaseRepo.createPurchase({
        'supplier_id': 1,
        'invoice_number': 'TEST-001',
        'purchase_date': DateTime.now().toIso8601String(),
        'total_amount': 100000,
        'notes': 'Test purchase',
        'items': [
          {
            'product_id': 1,
            'quantity': 10,
            'cost_price': 10000,
            'total_amount': 100000,
            'batch_number': null,
            'expiry_date': null,
          }
        ],
      });

      expect(purchaseId, greaterThan(0));

      // Verify stock increased
      final stockAfterPurchase = await itemsRepo.getProductStock(1);
      expect(stockAfterPurchase, greaterThanOrEqualTo(10));

      // Cancel the purchase - should succeed
      await purchaseRepo.cancelPurchase(purchaseId, reason: 'Test cancellation');

      // Verify stock decreased
      final stockAfterCancel = await itemsRepo.getProductStock(1);
      expect(stockAfterCancel, equals(stockAfterPurchase - 10));
    });

    test('should throw exception when cancellation would cause negative stock', () async {
      // Get initial stock
      final initialStock = await itemsRepo.getProductStock(1);

      // Create a purchase that adds stock
      final purchaseId = await purchaseRepo.createPurchase({
        'supplier_id': 1,
        'invoice_number': 'TEST-002',
        'purchase_date': DateTime.now().toIso8601String(),
        'total_amount': 200000,
        'notes': 'Test purchase',
        'items': [
          {
            'product_id': 1,
            'quantity': 20,
            'cost_price': 10000,
            'total_amount': 200000,
            'batch_number': null,
            'expiry_date': null,
          }
        ],
      });

      // Simulate selling more than the initial stock (but less than total)
      // by manually reducing stock
      final db = await DatabaseHelper.instance.database;
      await db.rawUpdate(
        'UPDATE products SET current_stock = ? WHERE id = ?',
        [5, 1], // Set stock to 5, less than the 20 we purchased
      );

      // Try to cancel - should fail because we'd need to subtract 20 from 5
      expect(
        () => purchaseRepo.cancelPurchase(purchaseId, reason: 'Should fail'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('insufficient stock'),
          ),
        ),
      );

      // Verify stock unchanged after failed cancellation
      final stockAfterFailedCancel = await itemsRepo.getProductStock(1);
      expect(stockAfterFailedCancel, equals(5));
    });

    test('should throw exception for already cancelled purchase', () async {
      // Create and cancel a purchase
      final purchaseId = await purchaseRepo.createPurchase({
        'supplier_id': 1,
        'invoice_number': 'TEST-003',
        'purchase_date': DateTime.now().toIso8601String(),
        'total_amount': 50000,
        'notes': 'Test purchase',
        'items': [
          {
            'product_id': 1,
            'quantity': 5,
            'cost_price': 10000,
            'total_amount': 50000,
            'batch_number': null,
            'expiry_date': null,
          }
        ],
      });

      await purchaseRepo.cancelPurchase(purchaseId);

      // Try to cancel again
      expect(
        () => purchaseRepo.cancelPurchase(purchaseId),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('already cancelled'),
          ),
        ),
      );
    });

    test('should throw exception for non-existent purchase', () async {
      expect(
        () => purchaseRepo.cancelPurchase(99999),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not found'),
          ),
        ),
      );
    });

    test('should provide helpful error message with product name', () async {
      // Create a purchase
      final purchaseId = await purchaseRepo.createPurchase({
        'supplier_id': 1,
        'invoice_number': 'TEST-004',
        'purchase_date': DateTime.now().toIso8601String(),
        'total_amount': 100000,
        'notes': 'Test purchase',
        'items': [
          {
            'product_id': 1,
            'quantity': 100,
            'cost_price': 1000,
            'total_amount': 100000,
            'batch_number': null,
            'expiry_date': null,
          }
        ],
      });

      // Reduce stock to simulate sales
      final db = await DatabaseHelper.instance.database;
      await db.rawUpdate(
        'UPDATE products SET current_stock = ? WHERE id = ?',
        [10, 1],
      );

      // Try to cancel - error should include product name
      try {
        await purchaseRepo.cancelPurchase(purchaseId);
        fail('Expected exception was not thrown');
      } catch (e) {
        final errorMessage = e.toString();
        expect(errorMessage, contains('insufficient stock'));
        expect(errorMessage, contains('Current stock: 10'));
        expect(errorMessage, contains('required to subtract: 100'));
      }
    });

    test('should validate all items before making any changes', () async {
      // Get a second product ID or use product 1
      final db = await DatabaseHelper.instance.database;
      
      // Insert a second product for this test
      await db.insert('products', {
        'item_code': 'TEST-PROD-2',
        'name_urdu': 'ٹیسٹ پروڈکٹ 2',
        'name_english': 'Test Product 2',
        'current_stock': 50,
        'avg_cost_price': 5000,
        'sale_price': 7000,
      });
      
      final product2Result = await db.query(
        'products',
        where: 'item_code = ?',
        whereArgs: ['TEST-PROD-2'],
      );
      final product2Id = product2Result.first['id'] as int;

      // Create a purchase with two items
      final purchaseId = await purchaseRepo.createPurchase({
        'supplier_id': 1,
        'invoice_number': 'TEST-005',
        'purchase_date': DateTime.now().toIso8601String(),
        'total_amount': 150000,
        'notes': 'Multi-item purchase',
        'items': [
          {
            'product_id': 1,
            'quantity': 10,
            'cost_price': 10000,
            'total_amount': 100000,
            'batch_number': null,
            'expiry_date': null,
          },
          {
            'product_id': product2Id,
            'quantity': 50,
            'cost_price': 1000,
            'total_amount': 50000,
            'batch_number': null,
            'expiry_date': null,
          }
        ],
      });

      // Get stock after purchase
      final stock1After = await itemsRepo.getProductStock(1);
      final stock2After = await itemsRepo.getProductStock(product2Id);

      // Reduce stock of product 2 to make cancellation fail
      await db.rawUpdate(
        'UPDATE products SET current_stock = ? WHERE id = ?',
        [10, product2Id], // Less than the 50 we purchased
      );

      // Try to cancel - should fail on product 2
      expect(
        () => purchaseRepo.cancelPurchase(purchaseId),
        throwsA(isA<Exception>()),
      );

      // Verify NEITHER product's stock was changed (transaction rolled back)
      final stock1Final = await itemsRepo.getProductStock(1);
      expect(stock1Final, equals(stock1After)); // Should be unchanged

      final stock2Final = await itemsRepo.getProductStock(product2Id);
      expect(stock2Final, equals(10)); // Should still be 10 (what we set it to)
    });
  });

  group('PurchaseRepository.createPurchase', () {
    test('should create purchase and update stock', () async {
      final initialStock = await itemsRepo.getProductStock(1);

      final purchaseId = await purchaseRepo.createPurchase({
        'supplier_id': 1,
        'invoice_number': 'CREATE-001',
        'purchase_date': DateTime.now().toIso8601String(),
        'total_amount': 50000,
        'notes': 'Test',
        'items': [
          {
            'product_id': 1,
            'quantity': 5,
            'cost_price': 10000,
            'total_amount': 50000,
            'batch_number': null,
            'expiry_date': null,
          }
        ],
      });

      expect(purchaseId, greaterThan(0));

      final finalStock = await itemsRepo.getProductStock(1);
      expect(finalStock, equals(initialStock + 5));
    });
  });
}
