import '../../bloc/stock/stock_bloc.dart';
import '../../bloc/stock/stock_event.dart';
import '../database/database_helper.dart';
import '../../models/purchase_models.dart';
import '../utils/logger.dart';
import 'package:intl/intl.dart';

class PurchaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // CREATE PURCHASE WITH TRANSACTION
  // ========================================
  Future<int> createPurchaseWithTransaction({
    required int supplierId,
    required List<Map<String, dynamic>> items,
    int totalAmount = 0,
    String? invoiceNumber,
    String? notes,
    StockBloc? stockBloc,
  }) async {
    final db = await _dbHelper.database;

    if (items.isEmpty) {
      throw ArgumentError('Purchase must have at least one item');
    }

    final now = DateTime.now();
    final String purchaseDate = DateFormat('yyyy-MM-dd HH:mm').format(now);

    final purchaseId = await db.transaction<int>((txn) async {
      // 1. Insert Purchase
      final id = await txn.insert('purchases', {
        'supplier_id': supplierId,
        'invoice_number': invoiceNumber,
        'purchase_date': purchaseDate,
        'total_amount': totalAmount,
        'notes': notes,
        'status': 'COMPLETED',
      });

      // 2. Insert Items & Update Stock
      for (var item in items) {
        final productId = item['product_id'];
        final quantity = (item['quantity'] as num).toDouble();
        final costPrice = (item['cost_price'] as num).toInt();
        final total = (item['total_amount'] as num).toInt();
        final batchNumber = item['batch_number'] as String?;
        final expiryDate = item['expiry_date'];
        final DateTime? parsedExpiry = expiryDate is String
            ? DateTime.tryParse(expiryDate)
            : (expiryDate is DateTime ? expiryDate : null);

        await txn.insert('purchase_items', {
          'purchase_id': id,
          'product_id': productId,
          'quantity': quantity,
          'cost_price': costPrice,
          'total_amount': total,
          'batch_number': batchNumber,
          'expiry_date': parsedExpiry?.toIso8601String(),
        });

        // Batch-level stock activity
        await txn.insert('stock_activities', {
          'product_id': productId,
          'quantity_change': quantity,
          'transaction_type': 'PURCHASE',
          'reference_type': 'PURCHASE',
          'reference_id': id,
          'batch_number': batchNumber,
          'expiry_date': parsedExpiry?.toIso8601String(),
          'user': 'SYSTEM',
          'created_at': DateTime.now().toIso8601String(),
        });

        // Update total stock
        await txn.rawUpdate(
          'UPDATE products SET current_stock = current_stock + ? WHERE id = ?',
          [quantity, productId],
        );
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
        'description': 'Purchase #$id',
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

    // Refresh stock in BLoC
    stockBloc?.add(LoadStock());

    return purchaseId;
  }

  // Alias for backward compatibility
  Future<int> createPurchase({
    required int supplierId,
    required List<Map<String, dynamic>> items,
    int totalAmount = 0,
    String? invoiceNumber,
    String? notes,
    StockBloc? stockBloc,
  }) {
    return createPurchaseWithTransaction(
      supplierId: supplierId,
      items: items,
      totalAmount: totalAmount,
      invoiceNumber: invoiceNumber,
      notes: notes,
      stockBloc: stockBloc,
    );
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
      // 1. Fetch Purchase
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

      // 2. Mark as CANCELLED
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

      // 3. Revert Stock & Stock Activities
      final items = await txn.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
      );

      for (var item in items) {
        final productId = item['product_id'] as int;
        final quantity = (item['quantity'] as num).toDouble();
        final batchNumber = item['batch_number'] as String;
        final expiryRaw = item['expiry_date']?.toString();
        final expiryDate =
            expiryRaw != null ? DateTime.tryParse(expiryRaw) : null;

        // Reduce total stock with underflow protection
        final updated = await txn.rawUpdate(
          'UPDATE products SET current_stock = current_stock - ? WHERE id = ? AND current_stock >= ?',
          [quantity, productId, quantity],
        );
        if (updated == 0) {
          throw Exception(
              'Cannot cancel purchase: stock underflow for product $productId');
        }

        // Log stock activity
        await txn.insert('stock_activities', {
          'product_id': productId,
          'quantity_change': -quantity,
          'transaction_type': 'PURCHASE_CANCEL',
          'reference_type': 'PURCHASE',
          'reference_id': purchaseId,
          'batch_number': batchNumber,
          'expiry_date': expiryDate?.toIso8601String(),
          'user': cancelledBy,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 4. Reverse Supplier Ledger
      final lastEntry = await txn.rawQuery(
        'SELECT balance FROM supplier_ledger WHERE supplier_id = ? ORDER BY transaction_date DESC, id DESC LIMIT 1',
        [supplierId],
      );
      int prevBalance =
          lastEntry.isNotEmpty ? (lastEntry.first['balance'] as int) : 0;
      int newBalance = prevBalance - (purchase['total_amount'] as int);

      await txn.insert('supplier_ledger', {
        'supplier_id': supplierId,
        'transaction_date': DateTime.now().toIso8601String(),
        'description': 'Purchase Cancelled: #$purchaseId',
        'ref_type': 'ADJUSTMENT',
        'ref_id': purchaseId,
        'debit': 0,
        'credit': purchase['total_amount'],
        'balance': newBalance,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('Purchase cancelled: ID $purchaseId', tag: 'PurchaseRepo');
    });

    // Refresh stock in BLoC
    stockBloc?.add(LoadStock());
  }

  // ========================================
  // QUERIES
  // ========================================
  Future<Purchase?> getPurchaseWithItems(int purchaseId) async {
    final db = await _dbHelper.database;
    final purchaseMap = await db.query(
      'purchases',
      where: 'id = ?',
      whereArgs: [purchaseId],
      limit: 1,
    );

    if (purchaseMap.isEmpty) return null;

    final purchase = Purchase.fromMap(purchaseMap.first);

    return Purchase(
      id: purchase.id,
      supplierId: purchase.supplierId,
      invoiceNumber: purchase.invoiceNumber,
      purchaseDate: purchase.purchaseDate,
      totalAmount: purchase.totalAmount,
      notes: purchase.notes,
      status: purchase.status,
      createdAt: purchase.createdAt,
    );
  }

  Future<List<Purchase>> getRecentPurchases({int limit = 20}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'purchases',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return result.map((map) => Purchase.fromMap(map)).toList();
  }

  Future<List<Purchase>> getPurchasesBySupplier(int supplierId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'purchases',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'purchase_date DESC',
    );
    return result.map((map) => Purchase.fromMap(map)).toList();
  }

  Future<List<Purchase>> getPurchasesByDateRange(
      String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'purchases',
      where: 'purchase_date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'purchase_date DESC',
    );
    return result.map((map) => Purchase.fromMap(map)).toList();
  }
}
