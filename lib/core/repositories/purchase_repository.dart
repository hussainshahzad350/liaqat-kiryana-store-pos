import '../../bloc/stock/stock_bloc.dart';
import '../../bloc/stock/stock_event.dart';
import '../database/database_helper.dart';
import '../../models/purchase_model.dart';
import '../../models/purchase_item_model.dart';
import '../utils/logger.dart';
import 'package:intl/intl.dart';

class PurchaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // CREATE PURCHASE WITH ITEMS & LEDGER
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
      final tempInvoiceNumber = invoiceNumber ?? 'TEMP-${now.microsecondsSinceEpoch}';
      final id = await txn.insert('purchases', {
        'supplier_id': supplierId,
        'invoice_number': tempInvoiceNumber,
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

        await txn.insert('purchase_items', {
          'purchase_id': id,
          'product_id': productId,
          'quantity': quantity,
          'cost_price': costPrice,
          'total_amount': total,
          'batch_number': item['batch_number'],
          'expiry_date': item['expiry_date']?.toIso8601String(),
        });

        // Update product stock
        await txn.rawUpdate(
          'UPDATE products SET current_stock = current_stock + ? WHERE id = ?',
          [quantity, productId],
        );

        // Optional: Stock activities log
        await txn.insert('stock_activities', {
          'product_id': productId,
          'quantity_change': quantity,
          'transaction_type': 'PURCHASE',
          'reference_type': 'PURCHASE',
          'reference_id': id,
          'user': 'SYSTEM',
          'created_at': now.toIso8601String(),
        });
      }

      // 3. Update Supplier Ledger
      final lastEntry = await txn.rawQuery(
        'SELECT balance FROM supplier_ledger WHERE supplier_id = ? ORDER BY transaction_date DESC, id DESC LIMIT 1',
        [supplierId],
      );
      int prevBalance = lastEntry.isNotEmpty ? (lastEntry.first['balance'] as int) : 0;
      int newBalance = prevBalance + totalAmount;

      await txn.insert('supplier_ledger', {
        'supplier_id': supplierId,
        'transaction_date': purchaseDate,
        'description': 'Purchase #$tempInvoiceNumber',
        'ref_type': 'PURCHASE',
        'ref_id': id,
        'debit': totalAmount,
        'credit': 0,
        'balance': newBalance,
        'created_at': now.toIso8601String(),
      });

      // 4. Update Supplier balance cache
      await txn.update('suppliers', {'outstanding_balance': newBalance},
          where: 'id = ?', whereArgs: [supplierId]);

      AppLogger.info('Purchase created: (ID: $id)', tag: 'PurchaseRepo');
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
      // Fetch Purchase
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
      final invoiceNumber = purchase['invoice_number'] as String?;

      // 1. Mark as CANCELLED
      await txn.update('purchases', {
        'status': 'CANCELLED',
        'notes': '${purchase['notes'] ?? ''}\n[Cancelled by $cancelledBy: ${reason ?? 'No reason'}]',
      }, where: 'id = ?', whereArgs: [purchaseId]);

      // 2. Revert Stock
      final items = await txn.query('purchase_items', where: 'purchase_id = ?', whereArgs: [purchaseId]);
      for (var item in items) {
        final productId = item['product_id'] as int;
        final quantity = (item['quantity'] as num).toDouble();

        await txn.rawUpdate(
          'UPDATE products SET current_stock = current_stock - ? WHERE id = ?',
          [quantity, productId],
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

      // 3. Reverse Supplier Ledger
      final lastEntry = await txn.rawQuery(
        'SELECT balance FROM supplier_ledger WHERE supplier_id = ? ORDER BY transaction_date DESC, id DESC LIMIT 1',
        [supplierId],
      );
      int prevBalance = lastEntry.isNotEmpty ? (lastEntry.first['balance'] as int) : 0;
      int totalAmount = (purchase['total_amount'] as num?)?.toInt() ?? 0;
      int newBalance = prevBalance - totalAmount;
      if (newBalance < 0) newBalance = 0;

      await txn.insert('supplier_ledger', {
        'supplier_id': supplierId,
        'transaction_date': DateTime.now().toIso8601String(),
        'description': 'Purchase Cancelled: #$invoiceNumber',
        'ref_type': 'ADJUSTMENT',
        'ref_id': purchaseId,
        'debit': 0,
        'credit': totalAmount,
        'balance': newBalance,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update supplier balance cache
      await txn.update('suppliers', {'outstanding_balance': newBalance},
          where: 'id = ?', whereArgs: [supplierId]);

      AppLogger.info('Purchase cancelled: #$invoiceNumber', tag: 'PurchaseRepo');
    });

    stockBloc?.add(LoadStock());
  }

  // ========================================
  // QUERIES
  // ========================================
  Future<Purchase?> getPurchaseWithItems(int purchaseId) async {
    final db = await _dbHelper.database;

    final purchaseMap = await db.query('purchases', where: 'id = ?', whereArgs: [purchaseId], limit: 1);
    if (purchaseMap.isEmpty) return null;

    final itemsMap = await db.query('purchase_items', where: 'purchase_id = ?', whereArgs: [purchaseId]);
    final items = itemsMap.map((e) => PurchaseItem.fromMap(e)).toList();

    return Purchase.fromMap(purchaseMap.first, items: items);
  }

  Future<List<Purchase>> getRecentPurchases({int limit = 20}) async {
    final db = await _dbHelper.database;
    final result = await db.query('purchases', orderBy: 'created_at DESC', limit: limit);
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

  Future<void> deletePurchase(int purchaseId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('purchase_items', where: 'purchase_id = ?', whereArgs: [purchaseId]);
      await txn.delete('purchases', where: 'id = ?', whereArgs: [purchaseId]);
    });
  }

  Future<void> updatePurchase(Purchase purchase) async {
    final db = await _dbHelper.database;
    await db.update('purchases', purchase.toMap(), where: 'id = ?', whereArgs: [purchase.id]);
  }
}
