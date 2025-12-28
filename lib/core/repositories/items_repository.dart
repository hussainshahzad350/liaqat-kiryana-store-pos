// lib/core/repositories/items_repository.dart
import '../database/database_helper.dart';
import '../utils/logger.dart';
import '../../models/product_model.dart';

class ItemsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // PRODUCT CRUD OPERATIONS
  // ========================================

  /// Get all products
  Future<List<Product>> getAllProducts() async {
    final db = await _dbHelper.database;
    final result = await db.query('products', orderBy: 'name_english ASC');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  /// Get product by ID
  Future<Product?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  /// Get product by item code
  Future<Product?> getProductByItemCode(String itemCode) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'item_code = ?',
      whereArgs: [itemCode],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  /// Add new product
  Future<int> addProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.insert('products', product.toMap());
  }

  /// Update product
  Future<int> updateProduct(int id, Product product) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete product
  Future<int> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================================
  // STOCK MANAGEMENT
  // ========================================

  /// Get current stock for a product (Real-time)
  Future<double> getProductStock(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      columns: ['current_stock'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty && result.first['current_stock'] != null) {
      return (result.first['current_stock'] as num).toDouble();
    }
    return 0.0;
  }

  /// Update product stock (for manual adjustments)
  Future<int> updateProductStock(int id, double newStock) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      {'current_stock': newStock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Adjust stock (add or subtract)
  Future<int> adjustStock(int id, num adjustment, {String? reason}) async {
    final db = await _dbHelper.database;
    
    return await db.transaction((txn) async {
      // Get current stock
      final result = await txn.query(
        'products',
        columns: ['current_stock'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) {
        throw Exception('Product not found');
      }

      final currentStock = (result.first['current_stock'] as num).toDouble();
      final newStock = currentStock + adjustment;

      if (newStock < 0) {
        throw Exception('Stock cannot be negative');
      }

      // Update stock
      return await txn.update(
        'products',
        {'current_stock': newStock},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Update average cost price (FIFO/Weighted Average)
  Future<int> updateAverageCostPrice(
    int id,
    int newPurchasePrice,
    num purchaseQuantity,
  ) async {
    final db = await _dbHelper.database;
    
    return await db.transaction((txn) async {
      final result = await txn.query(
        'products',
        columns: ['current_stock', 'avg_cost_price'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) {
        throw Exception('Product not found');
      }

      final currentStock = (result.first['current_stock'] as num).toDouble();
      final currentAvgPrice = (result.first['avg_cost_price'] as num).toInt();

      // Calculate new weighted average
      final totalValue = (currentStock * currentAvgPrice) + 
                        (purchaseQuantity * newPurchasePrice);
      final totalQuantity = currentStock + purchaseQuantity;
      final newAvgPrice = totalQuantity > 0 ? totalValue / totalQuantity : 0.0;

      return await txn.update(
        'products',
        {
          'current_stock': totalQuantity,
          'avg_cost_price': newAvgPrice.round(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // ========================================
  // SEARCH & FILTER
  // ========================================

  /// Search products by name or item code
  Future<List<Product>> searchProducts(String query) async {
    final db = await _dbHelper.database;
    final q = '%${query.toLowerCase()}%';
    
    final result = await db.rawQuery('''
      SELECT * FROM products 
      WHERE LOWER(name_english) LIKE ? 
      OR LOWER(name_urdu) LIKE ?
      OR LOWER(item_code) LIKE ?
      ORDER BY name_english ASC
    ''', [q, q, q]);
    
    return result.map((map) => Product.fromMap(map)).toList();
  }

  /// Get products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(
    int categoryId
  ) async {
    final db = await _dbHelper.database;
    return await db.query(
      'products',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name_english ASC',
    );
  }

  /// Get low stock items
  /// Moved from DatabaseHelper.getLowStockItems()
  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    try {
      final db = await _dbHelper.database;
      return await db.rawQuery('''
        SELECT 
          name_urdu, 
          name_english, 
          current_stock, 
          min_stock_alert,
          sale_price
        FROM products 
        WHERE current_stock > 0 AND current_stock <= min_stock_alert
        ORDER BY (current_stock / min_stock_alert) ASC
        LIMIT 5
      ''');
    } catch (e) {
      AppLogger.error("Error fetching low stock items: $e", tag: 'ItemsRepo');
      return [];
    }
  }

  /// Get out of stock items
  Future<List<Map<String, dynamic>>> getOutOfStockItems() async {
    final db = await _dbHelper.database;
    return await db.query(
      'products',
      where: 'current_stock = 0',
      orderBy: 'name_english ASC',
    );
  }

  /// Get products with stock above threshold
  Future<List<Map<String, dynamic>>> getProductsAboveStock(
    double threshold
  ) async {
    final db = await _dbHelper.database;
    return await db.query(
      'products',
      where: 'current_stock >= ?',
      whereArgs: [threshold],
      orderBy: 'current_stock DESC',
    );
  }

  // ========================================
  // STATISTICS & ANALYTICS
  // ========================================

  /// Get total products count
  /// Moved from DatabaseHelper.getTotalProductsCount()
  Future<int> getTotalProductsCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get total stock value (cost price based)
  /// Moved from DatabaseHelper.getTotalStockValue()
  Future<int> getTotalStockValue() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(current_stock * avg_cost_price) as total FROM products'
    );
    return (result.first['total'] as num?)?.round() ?? 0;
  }

  /// Get total stock value (sale price based)
  Future<int> getTotalStockValueAtSalePrice() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(current_stock * sale_price) as total FROM products'
    );
    return (result.first['total'] as num?)?.round() ?? 0;
  }

  /// Get potential profit (difference between sale and cost)
  Future<int> getPotentialProfit() async {
    final saleValue = await getTotalStockValueAtSalePrice();
    final costValue = await getTotalStockValue();
    return saleValue - costValue;
  }

  /// Get low stock count
  Future<int> getLowStockCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM products 
      WHERE current_stock > 0 AND current_stock <= min_stock_alert
    ''');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get out of stock count
  Future<int> getOutOfStockCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE current_stock = 0'
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get product sales statistics
  Future<Map<String, dynamic>> getProductSalesStats(int productId) async {
    final db = await _dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as sale_count,
        SUM(si.quantity_sold) as total_sold,
        SUM(si.total_price) as total_revenue,
        AVG(si.unit_price) as avg_price
      FROM sale_items si
      JOIN sales s ON si.sale_id = s.id
      WHERE si.product_id = ? AND s.status = 'COMPLETED'
    ''', [productId]);

    if (result.isEmpty) {
      return {
        'saleCount': 0,
        'totalSold': 0.0,
        'totalRevenue': 0.0,
        'avgPrice': 0.0,
      };
    }

    final data = result.first;
    return {
      'saleCount': data['sale_count'] ?? 0,
      'totalSold': (data['total_sold'] as num?)?.toDouble() ?? 0.0,
      'totalRevenue': (data['total_revenue'] as num?)?.toInt() ?? 0,
      'avgPrice': (data['avg_price'] as num?)?.round() ?? 0,
    };
  }

  /// Get top selling products
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    int limit = 10,
    String? dateFrom,
    String? dateTo,
  }) async {
    final db = await _dbHelper.database;
    
    String query = '''
      SELECT 
        p.*,
        SUM(si.quantity_sold) as total_sold,
        SUM(si.total_price) as total_revenue,
        COUNT(DISTINCT si.sale_id) as sale_count
      FROM products p
      JOIN sale_items si ON p.id = si.product_id
      JOIN sales s ON si.sale_id = s.id
      WHERE s.status = 'COMPLETED'
    ''';

    List<dynamic> args = [];

    if (dateFrom != null) {
      query += ' AND s.sale_date >= ?';
      args.add(dateFrom);
    }

    if (dateTo != null) {
      query += ' AND s.sale_date <= ?';
      args.add(dateTo);
    }

    query += '''
      GROUP BY p.id
      ORDER BY total_sold DESC
      LIMIT ?
    ''';
    args.add(limit);

    return await db.rawQuery(query, args);
  }

  /// Get slow moving products (low sales)
  Future<List<Map<String, dynamic>>> getSlowMovingProducts({
    int limit = 10,
    int daysBack = 30,
  }) async {
    final db = await _dbHelper.database;
    final date = DateTime.now().subtract(Duration(days: daysBack));
    final dateStr = date.toIso8601String().split('T')[0];
    
    return await db.rawQuery('''
      SELECT 
        p.*,
        COALESCE(SUM(si.quantity_sold), 0) as total_sold
      FROM products p
      LEFT JOIN sale_items si ON p.id = si.product_id
      LEFT JOIN sales s ON si.sale_id = s.id AND s.sale_date >= ? AND s.status = 'COMPLETED'
      WHERE p.current_stock > 0
      GROUP BY p.id
      ORDER BY total_sold ASC
      LIMIT ?
    ''', [dateStr, limit]);
  }

  // ========================================
  // BARCODE MANAGEMENT
  // ========================================

  /// Get product by barcode
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return result.first;
  }

  /// Update product barcode
  Future<int> updateProductBarcode(int id, String barcode) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      {'barcode': barcode},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Check if barcode exists
  Future<bool> barcodeExists(String barcode) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      columns: ['id'],
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ========================================
  // PRICING
  // ========================================

  /// Update product prices
  Future<int> updateProductPrices(
    int id, {
    int? costPrice,
    int? salePrice,
  }) async {
    final db = await _dbHelper.database;
    
    Map<String, dynamic> updates = {};
    if (costPrice != null) updates['avg_cost_price'] = costPrice;
    if (salePrice != null) updates['sale_price'] = salePrice;
    
    if (updates.isEmpty) return 0;
    
    return await db.update(
      'products',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Bulk update sale prices (by category or percentage)
  Future<int> bulkUpdateSalePrices({
    int? categoryId,
    double? percentageIncrease,
    int? fixedIncrease,
  }) async {
    if (percentageIncrease == null && fixedIncrease == null) {
      throw Exception('Must provide either percentage or fixed increase');
    }

    final db = await _dbHelper.database;
    
    String updateClause;
    if (percentageIncrease != null) {
      updateClause = 'sale_price = CAST(ROUND(sale_price * (1 + ?)) AS INTEGER)';
    } else {
      updateClause = 'sale_price = sale_price + ?';
    }

    String whereClause = categoryId != null ? 'category_id = ?' : '1=1';
    List<dynamic> args = [
      percentageIncrease ?? fixedIncrease,
      if (categoryId != null) categoryId,
    ];

    return await db.rawUpdate(
      'UPDATE products SET $updateClause WHERE $whereClause',
      args,
    );
  }
}