import 'dart:convert';
import 'package:intl/intl.dart';
import '../../bloc/stock/stock_bloc.dart';
import '../../bloc/stock/stock_event.dart';
import '../database/database_helper.dart';
import '../utils/logger.dart';

class SupplierPurchaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Create a purchase transaction
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

  /// Cancel a purchase
  Future<void> cancelPurchase({
    required int purchaseId,
    required String cancelledBy,
    String? reason,
    StockBloc? stockBloc,
  }) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // 1. Fetch purchase
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

      // 3. Revert Stock
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

      // 4. Reverse Supplier Ledger
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
}
