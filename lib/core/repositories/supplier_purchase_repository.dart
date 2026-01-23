import 'dart:convert';
import 'package:intl/intl.dart';
import '../../bloc/stock/stock_bloc.dart';
import '../../bloc/stock/stock_event.dart';
import '../database/database_helper.dart';
import '../utils/logger.dart';

class SupplierPurchaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // CREATE PURCHASE (Full Transaction)
  // ========================================
  Future<int> createPurchase({
    required int supplierId,
    required List<Map<String, dynamic>> items,
    required int totalAmount,
    String? invoiceNumber,
    String? notes,
    StockBloc? stockBloc,
  }) async {
    final db = await _dbHelper.database;

    if (items.isEmpty) {
      throw ArgumentError('Purchase must have at least one item');
    }

    final now = DateTime.now();
    final purchaseDate = DateFormat('yyyy-MM-dd HH:mm').format(now);

    final purchaseId = await db.transaction<int>((txn) async {
      // 1. Insert Purchase
      final id = await txn.insert('purchases', {
        'supplier_id': supplierId,
        'invoice_number': invoiceNumber,
        'purchase_date': purchaseDate,
        'total_amount': totalAmount,
        'notes': notes,
        'status': 'COMPLETED',
        'created_at': purchaseDate,
      });

      // 2. Insert Items & Update Stock
      for (var item in items) {
        final productId = item['product_id'];
        final quantity = (item['quantity'] as num).toDouble();
        final costPrice = (item['cost_price'] as num).toInt();

        await txn.insert('purchase_items', {
          'purchase_id': id,
          'product_id': productId,
          'quantity': quantity,
          'cost_price': costPrice,
          'total_amount': costPrice * quantity,
          'batch_number': item['batch_number'],
          'expiry_date': item['expiry_date'],
        });

        // Update Stock
        await txn.rawUpdate(
          'UPDATE products SET current_stock = current_stock + ? WHERE id = ?',
          [quantity, productId],
        );

        await txn.insert('stock_activities', {
          'product_id': productId,
          'quantity_change': quantity,
          'transaction_type': 'PURCHASE',
          'reference_type': 'PURCHASE',
          'reference_id': id,
          'user': 'SYSTEM',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 3. Update Supplier Ledger
      final lastEntry = await txn.rawQuery(
        'SELECT balance FROM supplier_ledger WHERE supplier_id = ? ORDER BY transaction_date DESC, id DESC LIMIT 1',
        [supplierId],
      );

      int prevBalance =
          lastEntry.isNotEmpty ? (lastEntry.first['balance'] as int) : 0;
      int newBalance = prevBalance + totalAmount;

      await txn.insert('supplier_ledger', {
        'supplier_id': supplierId,
        'transaction_date': purchaseDate,
        'description': 'Purchase ID #$id',
        'ref_type': 'PURCHASE',
        'ref_id': id,
        'debit': totalAmount,
        'credit': 0,
        'balance': newBalance,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('Purchase created: ID $id', tag: 'PurchaseRepo');
      return id;
    });

    stockBloc?.add(LoadStock());
    return purchaseId;
  }

  // ========================================
  // CANCEL PURCHASE
  // ========================================
  Future<void> cancelPurchase({
    required int purchaseId,
    required String cancelledBy,
    String? reason,
    StockBloc? stockBloc,
  }) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final purchaseRes = await txn.query(
        'purchases',
        where: 'id = ? AND status = ?',
        whereArgs: [purchaseId, 'COMPLETED'],
        limit: 1,
      );

      if (purchaseRes.isEmpty) {
        throw Exception('Purchase not found or already cancelled');
      }

      final purchase = purchaseRes.first;
      final supplierId = purchase['supplier_id'] as int;
      final totalAmount = (purchase['total_amount'] as num).toInt();

      // Mark purchase as CANCELLED
      await txn.update(
        'purchases',
        {
          'status': 'CANCELLED',
          'notes':
              '${purchase['notes'] ?? ''}\n[Cancelled by $cancelledBy: ${reason ?? 'No reason'}]',
        },
        where: 'id = ?',
        whereArgs: [purchaseId],
      );

      // Revert stock
      final items = await txn.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
      );

      for (var item in items) {
        final productId = item['product_id'] as int;
        final quantity = (item['quantity'] as num).toDouble();

        await txn.rawUpdate(
          'UPDATE products SET current_stock = current_stock - ? WHERE id = ? AND current_stock >= ?',
          [quantity, productId, quantity],
        );

        await txn.insert('stock_activities', {
          'product_id': productId,
          'quantity_change': -quantity,
          'transaction_type': 'PURCHASE_CANCEL',
          'reference_type': 'PURCHASE',
          'reference_id': purchaseId,
          'user': cancelledBy,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Reverse Supplier Ledger
      final lastEntry = await txn.rawQuery(
        'SELECT balance FROM supplier_ledger WHERE supplier_id = ? ORDER BY transaction_date DESC, id DESC LIMIT 1',
        [supplierId],
      );

      int prevBalance =
          lastEntry.isNotEmpty ? (lastEntry.first['balance'] as int) : 0;
      int newBalance = prevBalance - totalAmount;
      if (newBalance < 0) newBalance = 0;

      await txn.insert('supplier_ledger', {
        'supplier_id': supplierId,
        'transaction_date': DateTime.now().toIso8601String(),
        'description': 'Purchase Cancelled: #$purchaseId',
        'ref_type': 'ADJUSTMENT',
        'ref_id': purchaseId,
        'debit': 0,
        'credit': totalAmount,
        'balance': newBalance,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('Purchase cancelled: #$purchaseId', tag: 'PurchaseRepo');
    });

    stockBloc?.add(LoadStock());
  }

  // ========================================
  // PURCHASE QUERIES
  // ========================================

  /// Get purchase with items by ID
  Future<Map<String, dynamic>?> getPurchaseWithItems(int purchaseId) async {
    final db = await _dbHelper.database;

    final purchaseList =
        await db.query('purchases', where: 'id = ?', whereArgs: [purchaseId]);

    if (purchaseList.isEmpty) return null;

    final items = await db.query(
      'purchase_items',
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );

    return {
      'purchase': purchaseList.first,
      'items': items,
    };
  }

  /// Get recent purchases
  Future<List<Map<String, dynamic>>> getRecentPurchases({int limit = 20}) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'purchases',
      orderBy: 'purchase_date DESC',
      limit: limit,
    );

    return result;
  }

  /// Get purchases by supplier
  Future<List<Map<String, dynamic>>> getPurchasesBySupplier(int supplierId) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'purchases',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'purchase_date DESC',
    );

    return result;
  }

  /// Get purchases by date range
  Future<List<Map<String, dynamic>>> getPurchasesByDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'purchases',
      where: 'purchase_date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'purchase_date DESC',
    );

    return result;
  }

  /// Get supplier purchase total
  Future<int> getSupplierTotalPurchases(int supplierId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      'SELECT SUM(total_amount) as total FROM purchases WHERE supplier_id = ? AND status = ?',
      [supplierId, 'COMPLETED'],
    );

    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  /// Validate stock before purchase (optional, for bulk validation)
  Future<Map<String, dynamic>> validatePurchaseStock(List<Map<String, dynamic>> items) async {
    final db = await _dbHelper.database;

    for (var item in items) {
      final productId = item['product_id'];
      final qty = (item['quantity'] as num).toDouble();

      final result = await db.query(
        'products',
        columns: ['current_stock', 'name_english'],
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );

      if (result.isEmpty) {
        return {'valid': false, 'error': 'Product not found: $productId'};
      }

      final currentStock = (result.first['current_stock'] as num).toDouble();
      final productName = result.first['name_english'];

      if (currentStock < 0) {
        return {
          'valid': false,
          'error': 'Stock cannot be negative',
          'productName': productName,
        };
      }
    }

    return {'valid': true};
  }
}
