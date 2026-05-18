// lib/core/repositories/items_repository.dart
import 'dart:async';
import '../database/database_helper.dart';
import '../utils/logger.dart';
import '../../models/product_model.dart';
import '../../models/stock_adjustment_model.dart';
import 'package:sqflite/sqflite.dart';

class ItemsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  final Map<String, int> _barcodeIndex = {};

  // Stream that emits whenever stock levels change in the database.
  // Repositories and BLoCs listen to this for stock update signals.
  final StreamController<void> _stockChangedController =
      StreamController<void>.broadcast();

  Stream<void> get stockChanged => _stockChangedController.stream;

  Future<double> _getEventStock(
    DatabaseExecutor txn,
    int productId,
  ) async {
    final rows = await txn.rawQuery(
      'SELECT COALESCE(SUM(quantity_change), 0) AS stock_total FROM stock_activities WHERE product_id = ?',
      [productId],
    );
    return (rows.first['stock_total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> _assertProductStockConsistency(
    DatabaseExecutor txn,
    int productId,
  ) async {
    final productRows = await txn.query(
      'products',
      columns: ['current_stock'],
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (productRows.isEmpty) {
      throw Exception('PRODUCT_NOT_FOUND');
    }
    final cachedStock = (productRows.first['current_stock'] as num?)?.toDouble() ?? 0.0;
    final eventStock = await _getEventStock(txn, productId);
    if ((cachedStock - eventStock).abs() > 0.000001) {
      AppLogger.error(
        'Stock inconsistency detected (productId=$productId, cached=$cachedStock, events=$eventStock)',
        tag: 'ItemsRepo',
      );
      throw Exception('STOCK_INCONSISTENCY_REPORTED');
    }
  }

  Future<void> _recordStockEvent(
    DatabaseExecutor txn, {
    required int productId,
    required double quantityChange,
    required String transactionType,
    required String refType,
    required int refId,
    required String transactionId,
    required String user,
    int? reversalOfStockActivityId,
  }) async {
    await _assertProductStockConsistency(txn, productId);
    final currentStock = await _getEventStock(txn, productId);
    final nextStock = currentStock + quantityChange;
    if (nextStock < 0) {
      throw Exception('NEGATIVE_STOCK');
    }

    await txn.insert('stock_activities', {
      'product_id': productId,
      'quantity_change': quantityChange,
      'transaction_type': transactionType,
      'ref_type': refType,
      'ref_id': refId,
      'transaction_id': transactionId,
      'reversal_of_stock_activity_id': reversalOfStockActivityId,
      'reference_type': refType,
      'reference_id': refId,
      'user': user,
      'created_at': DateTime.now().toIso8601String(),
    });

    await txn.update(
      'products',
      {'current_stock': nextStock},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  /// Call this after any database operation that modifies stock quantities.
  void notifyStockChanged() {
    if (!_stockChangedController.isClosed) {
      _stockChangedController.add(null);
    }
  }

  void dispose() {
    _stockChangedController.close();
  }

  // ========================================
  // PRODUCT CRUD OPERATIONS
  // ========================================

  /// Get all active products
  Future<List<Product>> getAllProducts() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'is_active = 1',
      orderBy: 'name_english ASC',
    );
    
    final products = result.map((map) => Product.fromMap(map)).toList();

    _barcodeIndex.clear();
    for (final product in products) {
      if (product.id != null && product.itemCode != null && product.itemCode!.isNotEmpty) {
        _barcodeIndex[product.itemCode!] = product.id!;
      }
    }
    
    for (final row in result) {
      if (row['id'] != null && row['barcode'] != null) {
        final code = row['barcode'].toString().trim();
        if (code.isNotEmpty) {
          _barcodeIndex[code] = row['id'] as int;
        }
      }
    }

    return products;
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
    final id = await db.transaction<int>((txn) async {
      final map = Map<String, dynamic>.from(product.toMap());
      map['current_stock'] = 0;
      final productId = await txn.insert('products', map);
      if (product.currentStock > 0) {
        final adjustmentId = await txn.insert('stock_adjustments', {
          'product_id': productId,
          'adjustment_date': DateTime.now().toIso8601String(),
          'quantity_change': product.currentStock,
          'reason': 'Initial stock',
          'reference': 'PRODUCT_CREATE',
          'user': 'SYSTEM',
          'created_at': DateTime.now().toIso8601String(),
        });
        await _recordStockEvent(
          txn,
          productId: productId,
          quantityChange: product.currentStock,
          transactionType: 'ADJUSTMENT',
          refType: 'ADJUSTMENT',
          refId: adjustmentId,
          transactionId: 'ADJUSTMENT:$adjustmentId:INITIAL',
          user: 'SYSTEM',
        );
      }
      return productId;
    });

    if (product.itemCode != null && product.itemCode!.isNotEmpty) {
      _barcodeIndex[product.itemCode!] = id;
    }
    return id;
  }

  /// Update product
  Future<int> updateProduct(int id, Product product) async {
    final db = await _dbHelper.database;
    final updates = product.toMap();
    updates.remove('current_stock');
    updates.remove('is_active'); // is_active is managed only by deleteProduct()
    final result = await db.update(
      'products',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    _barcodeIndex.removeWhere((key, value) => value == id);
    if (product.itemCode != null && product.itemCode!.isNotEmpty) {
      _barcodeIndex[product.itemCode!] = id;
    }
    return result;
  }

  /// Soft-delete a product (Rule 8: hard deletes of business entities are
  /// prohibited; set is_active = 0 instead).
  Future<int> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    final result = await db.update(
      'products',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    _barcodeIndex.removeWhere((key, value) => value == id);
    return result;
  }

  // ========================================
  // STOCK MANAGEMENT
  // ========================================

  /// Get current stock for a product (Real-time)
  Future<double> getProductStock(int id) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(quantity_change), 0) AS stock_total FROM stock_activities WHERE product_id = ?',
      [id],
    );
    return (result.first['stock_total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Update product stock (for manual adjustments)
  Future<int> updateProductStock(int id, double newStock) async {
    final db = await _dbHelper.database;
    final result = await db.transaction<int>((txn) async {
      final productRes = await txn.query(
        'products',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (productRes.isEmpty) {
        throw Exception('PRODUCT_NOT_FOUND');
      }
      final currentStock = await _getEventStock(txn, id);
      final adjustment = newStock - currentStock;
      if (adjustment == 0) {
        return 0;
      }
      final adjustmentId = await txn.insert('stock_adjustments', {
        'product_id': id,
        'adjustment_date': DateTime.now().toIso8601String(),
        'quantity_change': adjustment,
        'reason': 'Manual stock set',
        'reference': 'MANUAL_SET',
        'user': 'SYSTEM',
        'created_at': DateTime.now().toIso8601String(),
      });
      await _recordStockEvent(
        txn,
        productId: id,
        quantityChange: adjustment,
        transactionType: 'ADJUSTMENT',
        refType: 'ADJUSTMENT',
        refId: adjustmentId,
        transactionId: 'ADJUSTMENT:$adjustmentId:SET',
        user: 'SYSTEM',
      );
      return 1;
    });
    if (result > 0) {
      notifyStockChanged();
    }
    return result;
  }

  /// Adjust stock (add or subtract)
  Future<int> adjustStock(
    int id,
    num adjustment, {
    String? reason,
    String? reference,
    String? user,
  }) async {
    final db = await _dbHelper.database;

    final result = await db.transaction((txn) async {
      final result = await txn.query(
        'products',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) {
        throw Exception('PRODUCT_NOT_FOUND');
      }

      final adjustmentRecord = StockAdjustment(
        productId: id,
        adjustmentDate: DateTime.now(),
        quantityChange: adjustment.toDouble(),
        reason: reason ?? 'Manual Adjustment',
        reference: reference ?? 'MANUAL',
        user: user ?? 'SYSTEM',
      );

      final adjustmentId = await txn.insert('stock_adjustments', adjustmentRecord.toMap());
      await _recordStockEvent(
        txn,
        productId: id,
        quantityChange: adjustment.toDouble(),
        transactionType: 'ADJUSTMENT',
        refType: 'ADJUSTMENT',
        refId: adjustmentId,
        transactionId: 'ADJUSTMENT:$adjustmentId',
        user: user ?? 'SYSTEM',
      );
      return 1;
    });
    notifyStockChanged();
    return result;
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
        columns: ['avg_cost_price'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) {
        throw Exception('PRODUCT_NOT_FOUND');
      }

      // Derive current stock from events (Rule 13 — cache is not source of truth)
      final currentStock = await _getEventStock(txn, id);
      final currentAvgPrice = (result.first['avg_cost_price'] as num).toInt();

      // Calculate new weighted average
      final totalValue = (currentStock * currentAvgPrice) +
          (purchaseQuantity * newPurchasePrice);
      final totalQuantity = currentStock + purchaseQuantity;
      final newAvgPrice = totalQuantity > 0 ? totalValue / totalQuantity : 0.0;

      return await txn.update(
        'products',
        {
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
  Future<List<Product>> searchProducts(String query, {int limit = 100}) async {
    if (query.trim().isEmpty) return [];
    final db = await _dbHelper.database;

    try {
      // Fast path: FTS5 search
      final ftsQuery = query
          .trim()
          .split(' ')
          .where((w) => w.isNotEmpty)
          .map((w) => '$w*')
          .join(' ');

      final ftsResult = await db.rawQuery('''
        SELECT p.* FROM products p
        INNER JOIN products_fts ON p.id = products_fts.rowid
        WHERE products_fts MATCH ?
        AND p.is_active = 1
        ORDER BY p.name_english ASC
        LIMIT ?
      ''', [ftsQuery, limit]);

      if (ftsResult.isNotEmpty) {
        return ftsResult.map((map) => Product.fromMap(map)).toList();
      }
    } catch (_) {
      // FTS5 table may not exist yet — fall through to LIKE search
    }

    // Fallback: LIKE search
    final q = '%${query.toLowerCase()}%';
    final result = await db.rawQuery('''
      SELECT * FROM products
      WHERE (LOWER(name_english) LIKE ?
      OR LOWER(name_urdu) LIKE ?
      OR LOWER(item_code) LIKE ?)
      AND is_active = 1
      ORDER BY name_english ASC
      LIMIT ?
    ''', [q, q, q, limit]);

    return result.map((map) => Product.fromMap(map)).toList();
  }

  /// Get products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(
      int categoryId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'products',
      where: 'category_id = ? AND is_active = 1',
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
        AND is_active = 1
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
      where: 'current_stock = 0 AND is_active = 1',
      orderBy: 'name_english ASC',
    );
  }

  /// Get products with stock above threshold
  Future<List<Map<String, dynamic>>> getProductsAboveStock(
      double threshold) async {
    final db = await _dbHelper.database;
    return await db.query(
      'products',
      where: 'current_stock >= ? AND is_active = 1',
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
    final result = await db
        .rawQuery('SELECT COUNT(*) as count FROM products WHERE is_active = 1');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get total stock value (cost price based)
  /// Moved from DatabaseHelper.getTotalStockValue()
  Future<int> getTotalStockValue() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
        'SELECT SUM(current_stock * avg_cost_price) as total FROM products WHERE is_active = 1');
    return (result.first['total'] as num?)?.round() ?? 0;
  }

  /// Get total stock value (sale price based)
  Future<int> getTotalStockValueAtSalePrice() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
        'SELECT SUM(current_stock * sale_price) as total FROM products WHERE is_active = 1');
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
      AND is_active = 1
    ''');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get out of stock count
  Future<int> getOutOfStockCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE current_stock = 0 AND is_active = 1');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get product sales statistics
  Future<Map<String, dynamic>> getProductSalesStats(int productId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as sale_count,
        SUM(si.quantity) as total_sold,
        SUM(si.total_price) as total_revenue,
        AVG(si.unit_price) as avg_price
        FROM invoice_items si
        JOIN invoices s ON si.invoice_id = s.id
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
        SUM(si.quantity) as total_sold,
        SUM(si.total_price) as total_revenue,
        COUNT(DISTINCT si.invoice_id) as sale_count
        FROM products p
        JOIN invoice_items si ON p.id = si.product_id
        JOIN invoices s ON si.invoice_id = s.id
        WHERE s.status = 'COMPLETED' AND p.is_active = 1
      ''';

    List<dynamic> args = [];

    if (dateFrom != null) {
      query += ' AND s.invoice_date >= ?';
      args.add(dateFrom);
    }

    if (dateTo != null) {
      query += ' AND s.invoice_date <= ?';
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
        COALESCE(SUM(si.quantity), 0) as total_sold
      FROM products p
      LEFT JOIN invoice_items si ON p.id = si.product_id
      LEFT JOIN invoices s ON si.invoice_id = s.id AND s.invoice_date >= ? AND s.status = 'COMPLETED'
      WHERE p.current_stock > 0 AND p.is_active = 1
      GROUP BY p.id
      ORDER BY total_sold ASC
      LIMIT ?
    ''', [dateStr, limit]);
  }

  // ========================================
  // BARCODE MANAGEMENT
  // ========================================

  Future<int?> getProductIdByBarcode(String barcode) async {
    if (_barcodeIndex.isNotEmpty && _barcodeIndex.containsKey(barcode)) {
      return _barcodeIndex[barcode];
    }
    // Fallback to DB if index not yet populated
    final product = await getProductByBarcode(barcode);
    return product?['id'] as int?;
  }

  /// Get product by barcode
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'barcode = ? AND is_active = 1',
      whereArgs: [barcode],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first;
  }

  /// Update product barcode
  Future<int> updateProductBarcode(int id, String barcode) async {
    final db = await _dbHelper.database;
    
    // Fetch product first to preserve itemCode in cache
    final product = await getProductById(id);
    
    final result = await db.update(
      'products',
      {'barcode': barcode},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result > 0) {
      // Sync barcode index
      _barcodeIndex.removeWhere((key, value) => value == id);
      
      // Re-add itemCode if it exists
      if (product?.itemCode != null && product!.itemCode!.isNotEmpty) {
        _barcodeIndex[product.itemCode!] = id;
      }
      
      // Add new barcode
      if (barcode.trim().isNotEmpty) {
        _barcodeIndex[barcode.trim()] = id;
      }
    }
    return result;
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

  // Stock Adjustments for product

  Future<List<StockAdjustment>> getStockAdjustmentsForProduct(
      int productId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'stock_adjustments',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'adjustment_date DESC',
    );
    return result.map((map) => StockAdjustment.fromMap(map)).toList();
  }

  // Bulk update sale prices (by category or percentage)
  Future<int> bulkUpdateSalePrices({
    int? categoryId,
    double? percentageIncrease,
    int? fixedIncrease,
  }) async {
    if (percentageIncrease == null && fixedIncrease == null) {
      throw Exception('INVALID_PRICE_ADJUSTMENT');
    }

    final db = await _dbHelper.database;

    String updateClause;
    if (percentageIncrease != null) {
      updateClause =
          'sale_price = CAST(ROUND(sale_price * (1 + ?)) AS INTEGER)';
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
