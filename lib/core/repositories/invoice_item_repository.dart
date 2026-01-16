import '../database/database_helper.dart';
import '../../models/invoice_item_models.dart';
import '../utils/logger.dart';

class InvoiceItemRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // BASIC CRUD
  // ========================================

  /// Insert a single item
  Future<int> insertItem(InvoiceItem item) async {
    final db = await _dbHelper.database;
    return await db.insert('invoice_items', item.toMap());
  }

  /// Update a single item
  Future<int> updateItem(InvoiceItem item) async {
    final db = await _dbHelper.database;
    return await db.update(
      'invoice_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Delete a single item
  Future<int> deleteItem(int itemId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'invoice_items',
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  /// Get all items for an invoice
  Future<List<InvoiceItem>> getItemsByInvoice(int invoiceId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'id ASC',
    );
    return result.map((e) => InvoiceItem.fromMap(e)).toList();
  }

  /// Get a single item by ID
  Future<InvoiceItem?> getItemById(int itemId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'invoice_items',
      where: 'id = ?',
      whereArgs: [itemId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return InvoiceItem.fromMap(result.first);
  }

  // ========================================
  // BATCH OPERATIONS
  // ========================================

  /// Insert multiple items (for invoice creation)
  Future<void> insertItems(List<InvoiceItem> items) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (var item in items) {
      batch.insert('invoice_items', item.toMap());
    }

    await batch.commit(noResult: true);
    AppLogger.info('Inserted ${items.length} invoice items', tag: 'InvoiceItemRepo');
  }

  /// Delete all items for an invoice
  Future<int> deleteItemsByInvoice(int invoiceId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
  }

  /// Update multiple items (for invoice editing)
  Future<void> updateItems(List<InvoiceItem> items) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (var item in items) {
      batch.update(
        'invoice_items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
    }

    await batch.commit(noResult: true);
  }

  // ========================================
  // QUERIES & ANALYTICS
  // ========================================

  /// Get items with product details (JOIN)
  Future<List<Map<String, dynamic>>> getItemsWithProductDetails(
      int invoiceId) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT 
        ii.*,
        p.name_english,
        p.name_urdu,
        p.unit_type,
        p.current_stock
      FROM invoice_items ii
      LEFT JOIN products p ON ii.product_id = p.id
      WHERE ii.invoice_id = ?
      ORDER BY ii.id ASC
    ''', [invoiceId]);
  }

  /// Get total quantity sold for a product
  Future<double> getTotalQuantitySoldForProduct(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(quantity) as total
      FROM invoice_items
      WHERE product_id = ?
    ''', [productId]);

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total revenue for a product
  Future<int> getTotalRevenueForProduct(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(total_price) as total
      FROM invoice_items
      WHERE product_id = ?
    ''', [productId]);

    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  /// Get top selling items (by quantity)
  Future<List<Map<String, dynamic>>> getTopSellingItems({
    int limit = 10,
    String? startDate,
    String? endDate,
  }) async {
    final db = await _dbHelper.database;

    String query = '''
      SELECT 
        ii.product_id,
        ii.item_name_snapshot,
        SUM(ii.quantity) as total_quantity,
        SUM(ii.total_price) as total_revenue,
        COUNT(DISTINCT ii.invoice_id) as invoice_count
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      WHERE i.status = 'COMPLETED'
    ''';

    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      query += ' AND i.invoice_date BETWEEN ? AND ?';
      args.add(startDate);
      args.add(endDate);
    }

    query += '''
      GROUP BY ii.product_id
      ORDER BY total_quantity DESC
      LIMIT ?
    ''';
    args.add(limit);

    return await db.rawQuery(query, args);
  }

  /// Get items count for an invoice
  Future<int> getItemsCountByInvoice(int invoiceId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM invoice_items WHERE invoice_id = ?',
      [invoiceId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get total items value for an invoice
  Future<int> getTotalItemsValue(int invoiceId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(total_price) as total FROM invoice_items WHERE invoice_id = ?',
      [invoiceId],
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  // ========================================
  // SEARCH
  // ========================================

  /// Search items by product name across all invoices
  Future<List<Map<String, dynamic>>> searchItemsByProductName(
      String query) async {
    final db = await _dbHelper.database;
    final q = '%${query.toLowerCase()}%';

    return await db.rawQuery('''
      SELECT 
        ii.*,
        i.invoice_number,
        i.invoice_date,
        i.status
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      WHERE LOWER(ii.item_name_snapshot) LIKE ?
      ORDER BY i.invoice_date DESC
      LIMIT 50
    ''', [q]);
  }

  // ========================================
  // VALIDATION
  // ========================================

  /// Check if an invoice has items
  Future<bool> invoiceHasItems(int invoiceId) async {
    final count = await getItemsCountByInvoice(invoiceId);
    return count > 0;
  }

  /// Validate item quantity against product stock
  Future<Map<String, dynamic>> validateItemStock(
    int productId,
    double quantity,
  ) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      columns: ['current_stock', 'name_english'],
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );

    if (result.isEmpty) {
      return {
        'valid': false,
        'error': 'Product not found',
      };
    }

    final currentStock = (result.first['current_stock'] as num).toDouble();
    final productName = result.first['name_english'];

    if (currentStock < quantity) {
      return {
        'valid': false,
        'error': 'Insufficient stock',
        'productName': productName,
        'available': currentStock,
        'requested': quantity,
      };
    }

    return {'valid': true};
  }
}
