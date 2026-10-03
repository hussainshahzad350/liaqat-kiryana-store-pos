@Tags(['database'])
library purchase_repository_test;

// test/unit/purchase_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/core/repositories/purchase_repository.dart';
import '../support/test_database.dart';

void main() {
  late PurchaseRepository purchaseRepo;
  late ItemsRepository itemsRepo;
  useTestDatabase();

  setUp(() async {
    await setTestStock(1, 45);
    itemsRepo = ItemsRepository();
    purchaseRepo = PurchaseRepository(itemsRepo);
  });

  group('PurchaseRepository.cancelPurchase', () {
    test('should cancel purchase when sufficient stock exists', () async {
      // Create a purchase first
      final purchaseId = await purchaseRepo.createPurchase(
        supplierId: 1,
        invoiceNumber: 'TEST-001',
        totalAmount: 100000,
        notes: 'Test purchase',
        items: [
          {
            'product_id': 1,
            'quantity': 10,
            'cost_price': 10000,
            'total_amount': 100000,
            'batch_number': null,
            'expiry_date': null,
          }
        ],
      );

      expect(purchaseId, greaterThan(0));

      // Verify stock increased
      final stockAfterPurchase = await itemsRepo.getProductStock(1);
      expect(stockAfterPurchase, greaterThanOrEqualTo(10));

      // Cancel the purchase - should succeed
      await purchaseRepo.cancelPurchase(
          purchaseId: purchaseId,
          cancelledBy: 'test_user',
          reason: 'Test cancellation');

      // Verify stock decreased
      final stockAfterCancel = await itemsRepo.getProductStock(1);
      expect(stockAfterCancel, equals(stockAfterPurchase - 10));
    });

    test('should throw exception when cancellation would cause negative stock',
        () async {
      // Create a purchase that adds stock
      final purchaseId = await purchaseRepo.createPurchase(
        supplierId: 1,
        invoiceNumber: 'TEST-002',
        totalAmount: 200000,
        notes: 'Test purchase',
        items: [
          {
            'product_id': 1,
            'quantity': 20,
            'cost_price': 10000,
            'total_amount': 200000,
            'batch_number': null,
            'expiry_date': null,
          }
        ],
      );

      // Simulate consumed stock with a matching fixture event and cache.
      await setTestStock(1, 5);

      // Try to cancel - should fail because we'd need to subtract 20 from 5
      await expectLater(
        () => purchaseRepo.cancelPurchase(
            purchaseId: purchaseId,
            reason: 'Should fail',
            cancelledBy: 'test_user'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('NEGATIVE_STOCK'),
          ),
        ),
      );

      // Verify stock unchanged after failed cancellation
      final stockAfterFailedCancel = await itemsRepo.getProductStock(1);
      expect(stockAfterFailedCancel, equals(5));
    });

    test('should throw exception for already cancelled purchase', () async {
      // Create and cancel a purchase
      final purchaseId = await purchaseRepo.createPurchase(
        supplierId: 1,
        invoiceNumber: 'TEST-003',
        totalAmount: 50000,
        notes: 'Test purchase',
        items: [
          {
            'product_id': 1,
            'quantity': 5,
            'cost_price': 10000,
            'total_amount': 50000,
            'batch_number': null,
            'expiry_date': null,
          }
        ],
      );

      await purchaseRepo.cancelPurchase(
          purchaseId: purchaseId, cancelledBy: 'test_user');

      // Try to cancel again
      await expectLater(
        () => purchaseRepo.cancelPurchase(
            purchaseId: purchaseId, cancelledBy: 'test_user'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('PURCHASE_NOT_FOUND'),
          ),
        ),
      );

      final db = await DatabaseHelper.instance.database;
      final stockReversals = await db.query('stock_activities',
          where: 'ref_type = ? AND ref_id = ? AND transaction_type = ?',
          whereArgs: ['PURCHASE', purchaseId, 'PURCHASE_CANCEL']);
      final ledgerReversals = await db.query('supplier_ledger',
          where: 'ref_type = ? AND ref_id = ?',
          whereArgs: ['PURCHASE_RETURN', purchaseId]);
      expect(stockReversals, hasLength(1));
      expect(stockReversals.single['reversal_of_stock_activity_id'], isNotNull);
      expect(ledgerReversals, hasLength(1));
      expect(
          ledgerReversals.single['reversal_of_supplier_ledger_id'], isNotNull);
      expect(await itemsRepo.getProductStock(1), 45);
    });

    test('should throw exception for non-existent purchase', () async {
      await expectLater(
        () => purchaseRepo.cancelPurchase(
            purchaseId: 99999, cancelledBy: 'test_user'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('PURCHASE_NOT_FOUND'),
          ),
        ),
      );
    });

    test('should include cancellation error code when stock is insufficient',
        () async {
      // Create a purchase
      final purchaseId = await purchaseRepo.createPurchase(
        supplierId: 1,
        invoiceNumber: 'TEST-004',
        totalAmount: 100000,
        notes: 'Test purchase',
        items: [
          {
            'product_id': 1,
            'quantity': 100,
            'cost_price': 1000,
            'total_amount': 100000,
            'batch_number': null,
            'expiry_date': null,
          }
        ],
      );

      // Reduce stock to simulate sales
      await setTestStock(1, 10);

      await expectLater(
        purchaseRepo.cancelPurchase(
            purchaseId: purchaseId, cancelledBy: 'test_user'),
        throwsA(isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('NEGATIVE_STOCK'),
        )),
      );
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
      await setTestStock(product2Id, 50);

      // Create a purchase with two items
      final purchaseId = await purchaseRepo.createPurchase(
        supplierId: 1,
        invoiceNumber: 'TEST-005',
        totalAmount: 150000,
        notes: 'Multi-item purchase',
        items: [
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
      );

      // Get stock after purchase for product 1 (used to verify rollback)
      final stock1After = await itemsRepo.getProductStock(1);
      // Product 2 stock is checked after modification below

      // Reduce stock of product 2 to make cancellation fail
      await setTestStock(product2Id, 10);

      // Try to cancel - should fail on product 2
      await expectLater(
        () => purchaseRepo.cancelPurchase(
            purchaseId: purchaseId, cancelledBy: 'test_user'),
        throwsA(isA<Exception>()),
      );

      // Verify NEITHER product's stock was changed (transaction rolled back)
      final stock1Final = await itemsRepo.getProductStock(1);
      expect(stock1Final, equals(stock1After)); // Should be unchanged

      final stock2Final = await itemsRepo.getProductStock(product2Id);
      expect(stock2Final, equals(10)); // Should still be 10 (what we set it to)

      final purchase =
          await db.query('purchases', where: 'id = ?', whereArgs: [purchaseId]);
      expect(purchase.single['status'], 'COMPLETED');
      final reversals = await db.query('stock_activities',
          where: 'ref_type = ? AND ref_id = ? AND transaction_type = ?',
          whereArgs: ['PURCHASE', purchaseId, 'PURCHASE_CANCEL']);
      expect(reversals, isEmpty);
      final ledgerReversals = await db.query('supplier_ledger',
          where: 'ref_type = ? AND ref_id = ?',
          whereArgs: ['PURCHASE_RETURN', purchaseId]);
      expect(ledgerReversals, isEmpty);
    });
  });

  group('PurchaseRepository.createPurchase', () {
    test('should create purchase and update stock', () async {
      final initialStock = await itemsRepo.getProductStock(1);

      final purchaseId = await purchaseRepo.createPurchase(
        supplierId: 1,
        invoiceNumber: 'CREATE-001',
        totalAmount: 50000,
        notes: 'Test',
        items: [
          {
            'product_id': 1,
            'quantity': 5,
            'cost_price': 10000,
            'total_amount': 50000,
            'batch_number': null,
            'expiry_date': null,
          }
        ],
      );

      expect(purchaseId, greaterThan(0));

      final finalStock = await itemsRepo.getProductStock(1);
      expect(finalStock, equals(initialStock + 5));
    });
  });
}
