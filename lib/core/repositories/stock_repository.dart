import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../entity/stock_item_entity.dart';
import '../entity/stock_summary_entity.dart';
import '../../domain/entities/money.dart';

class StockRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Fetch all stock items with optional filtering
  Future<List<StockItemEntity>> getStockItems({
    String? query,
    String? status, // 'LOW', 'OUT', 'EXPIRED', 'OLD'
    int? supplierId, // Note: Requires product-supplier link in DB, currently placeholder
    int? categoryId,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;

    String whereClause = 'WHERE 1=1';
    List<dynamic> args = [];

    if (query != null && query.isNotEmpty) {
      whereClause += ' AND (p.name_english LIKE ? OR p.name_urdu LIKE ? OR p.item_code LIKE ?)';
      args.addAll(['%$query%', '%$query%', '%$query%']);
    }

    if (status == 'LOW') {
      whereClause += ' AND p.current_stock > 0 AND p.current_stock <= p.min_stock_alert';
    } else if (status == 'OUT') {
      whereClause += ' AND p.current_stock <= 0';
    } else if (status == 'EXPIRED') {
      whereClause += " AND p.expiry_date IS NOT NULL AND DATE(p.expiry_date) <= DATE('now', '+30 day')";
    } else if (status == 'OLD') {
      whereClause += " AND DATE(p.created_at) <= DATE('now', '-90 day')";
    }

    if (categoryId != null) {
      whereClause += ' AND p.category_id = ?';
      args.add(categoryId);
    }
    
    // supplierId filter is not implemented as the DB schema doesn't support it yet.

    final String sql = '''
      SELECT p.*, c.name_english as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      $whereClause
      ORDER BY p.name_english ASC
      LIMIT $limit OFFSET $offset
    ''';

    final result = await db.rawQuery(sql, args);

    return result.map((row) => _mapToEntity(row)).toList();
  }

  /// Get comprehensive Stock KPIs
  Future<StockSummaryEntity> getStockSummary() async {
    final db = await _dbHelper.database;

    // 1. Total Items
    final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    final totalItems = Sqflite.firstIntValue(countRes) ?? 0;

    // 2. Financials (Cost & Sales Value)
    final valueRes = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(current_stock * avg_cost_price), 0) as total_cost,
        COALESCE(SUM(current_stock * sale_price), 0) as total_sale
      FROM products
      WHERE current_stock > 0
    ''');
    
    final totalCost = valueRes.first['total_cost'] as int;
    final totalSale = valueRes.first['total_sale'] as int;

    // 3. Risk Metrics
    final lowStockRes = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE current_stock > 0 AND current_stock <= min_stock_alert'
    );
    final outStockRes = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE current_stock <= 0'
    );

    // 4. Expiry Count
    final expiryRes = await db.rawQuery(
      "SELECT COUNT(*) as count FROM products WHERE expiry_date IS NOT NULL AND DATE(expiry_date) <= DATE('now', '+30 day')"
    );

    return StockSummaryEntity(
      totalItemsCount: totalItems,
      totalStockCost: Money(totalCost),
      totalStockSalesValue: Money(totalSale),
      lowStockItemsCount: Sqflite.firstIntValue(lowStockRes) ?? 0,
      outOfStockItemsCount: Sqflite.firstIntValue(outStockRes) ?? 0,
      expiredOrNearExpiryCount: Sqflite.firstIntValue(expiryRes) ?? 0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get a single stock item by ID
  Future<StockItemEntity?> getStockItemById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query('products', where: 'id = ?', whereArgs: [id]);
    
    if (result.isEmpty) return null;
    return _mapToEntity(result.first);
  }

  /// Adjust stock manually (Audit safe wrapper)
  /// Note: This updates the product table. A separate log entry should be created via StockActivityRepository.
  Future<void> adjustStockQuantity(int productId, double newQuantity) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {'current_stock': newQuantity},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // --- Mapper ---
  StockItemEntity _mapToEntity(Map<String, dynamic> row) {
    return StockItemEntity(
      id: row['id'] as int,
      nameEnglish: row['name_english'] as String,
      nameUrdu: row['name_urdu'] as String? ?? '',
      code: row['item_code'] as String?,
      barcode: row['barcode'] as String?,
      currentStock: (row['current_stock'] as num?)?.toDouble() ?? 0.0,
      minStockThreshold: (row['min_stock_alert'] as num?)?.toDouble() ?? 0.0,
      unit: row['unit_type'] as String? ?? 'Unit',
      costPrice: Money((row['avg_cost_price'] as num?)?.toInt() ?? 0),
      salePrice: Money((row['sale_price'] as num?)?.toInt() ?? 0),
      categoryName: row['category_name'] as String?,
      lastUpdated: DateTime.now(), // DB doesn't have update_at on products yet
      expiryDate: row['expiry_date'] != null ? DateTime.tryParse(row['expiry_date'] as String) : null,
    );
  }
}