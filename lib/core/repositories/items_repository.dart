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
    final cachedStock =
        (productRows.first['current_stock'] as num?)?.toDouble() ?? 0.0;
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
      if (product.id != null &&
          product.itemCode != null &&
          product.itemCode!.isNotEmpty) {
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

  /// Page the management catalog without changing sales search or barcode caches.
  Future<List<Product>> getCatalogProducts({
    String query = '',
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final search = '%${query.trim().toLowerCase()}%';
    final rows = await db.query('products',
        where:
            'is_active = 1 AND (LOWER(name_english) LIKE ? OR LOWER(name_urdu) LIKE ? OR LOWER(item_code) LIKE ?)',
        whereArgs: [search, search, search],
        orderBy: 'name_english ASC, id ASC',
        limit: limit,
        offset: offset);
    return rows.map(Product.fromMap).toList();
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
    updates.remove(
        'created_at'); // Metadata edits preserve original creation time.
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

      final adjustmentId =
          await txn.insert('stock_adjustments', adjustmentRecord.toMap());
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
      OR LOWER(item_code) LIKE ?
      OR barcode = ?)
      AND is_active = 1
      ORDER BY name_english ASC
      LIMIT ?
    ''', [q, q, q, query.trim(), limit]);

    return result.map((map) => Product.fromMap(map)).toList();
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

  // ========================================
  // BARCODE MANAGEMENT
  // ========================================

  // ========================================
  // PRICING
  // ========================================

  // Stock Adjustments for product

  // Bulk update sale prices (by category or percentage)
}
