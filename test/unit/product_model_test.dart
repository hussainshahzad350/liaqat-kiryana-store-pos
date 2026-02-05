import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/models/product_model.dart';
import 'package:liaqat_store/domain/entities/money.dart';

void main() {
  group('Product Model Tests', () {
    final testDate = DateTime(2023, 1, 1);
    
    final testProduct = Product(
      id: 1,
      itemCode: 'CODE123',
      nameEnglish: 'Test Product',
      nameUrdu: 'ٹیسٹ پروڈکٹ',
      categoryId: 1,
      subCategoryId: 2,
      brand: 'Test Brand',
      unitId: 3,
      unitType: 'KG',
      packingType: 'Box',
      searchTags: 'test, product',
      minStockAlert: 10,
      currentStock: 100,
      avgCostPrice: const Money(50),
      salePrice: const Money(100),
      expiryDate: testDate,
      createdAt: testDate,
    );

    test('should create Product from map correctly', () {
      final map = {
        'id': 1,
        'item_code': 'CODE123',
        'name_english': 'Test Product',
        'name_urdu': 'ٹیسٹ پروڈکٹ',
        'category_id': 1,
        'sub_category_id': 2,
        'brand': 'Test Brand',
        'unit_id': 3,
        'unit_type': 'KG',
        'packing_type': 'Box',
        'search_tags': 'test, product',
        'min_stock_alert': 10,
        'current_stock': 100,
        'avg_cost_price': 50,
        'sale_price': 100,
        'expiry_date': testDate.toIso8601String(),
        'created_at': testDate.toIso8601String(),
      };

      final product = Product.fromMap(map);

      expect(product.id, 1);
      expect(product.itemCode, 'CODE123');
      expect(product.nameEnglish, 'Test Product');
      expect(product.nameUrdu, 'ٹیسٹ پروڈکٹ');
      expect(product.currentStock, 100);
      expect(product.expiryDate, testDate);
      expect(product.createdAt, testDate);
    });


    test('should parse numeric fields when SQLite returns doubles', () {
      final map = {
        'id': 2,
        'item_code': 'CODE456',
        'name_english': 'Numeric Product',
        'min_stock_alert': 10.0,
        'current_stock': 25.5,
        'avg_cost_price': 50.0,
        'sale_price': 100.0,
      };

      final product = Product.fromMap(map);

      expect(product.minStockAlert, 10);
      expect(product.currentStock, 25.5);
      expect(product.avgCostPrice, const Money(50));
      expect(product.salePrice, const Money(100));
    });

    test('should convert Product to map correctly', () {
      final map = testProduct.toMap();

      expect(map['id'], 1);
      expect(map['item_code'], 'CODE123');
      expect(map['name_english'], 'Test Product');
      expect(map['current_stock'], 100);
      expect(map['expiry_date'], testDate.toIso8601String());
      expect(map['created_at'], testDate.toIso8601String());
    });

    test('copyWith should return a new instance with updated fields', () {
      final updatedProduct = testProduct.copyWith(
        nameEnglish: 'Updated Product',
        currentStock: 200,
      );

      expect(updatedProduct.nameEnglish, 'Updated Product');
      expect(updatedProduct.currentStock, 200);
      expect(updatedProduct.itemCode, testProduct.itemCode); // Unchanged field
    });

    test('isLowStock should return true when stock is equal to or less than minStockAlert', () {
      final lowStockProduct = testProduct.copyWith(
        currentStock: 10,
        minStockAlert: 10,
      );
      expect(lowStockProduct.isLowStock, true);

      final veryLowStockProduct = testProduct.copyWith(
        currentStock: 5,
        minStockAlert: 10,
      );
      expect(veryLowStockProduct.isLowStock, true);
    });

    test('isLowStock should return false when stock is greater than minStockAlert', () {
      final highStockProduct = testProduct.copyWith(
        currentStock: 11,
        minStockAlert: 10,
      );
      expect(highStockProduct.isLowStock, false);
    });

    test('profitPerUnit should calculate correctly', () {
      expect(testProduct.profitPerUnit, const Money(50)); // 100 - 50 = 50
    });

    test('equality operator should work correctly', () {
      final product1 = Product(
        id: 1, 
        itemCode: 'A', 
        nameEnglish: 'Name', 
        createdAt: testDate
      );
      final product2 = Product(
        id: 1, 
        itemCode: 'A', 
        nameEnglish: 'Name', 
        createdAt: testDate
      );
      final product3 = Product(
        id: 2, 
        itemCode: 'B', 
        nameEnglish: 'Other', 
        createdAt: testDate
      );

      expect(product1, equals(product2));
      expect(product1, isNot(equals(product3)));
    });
  });
}
