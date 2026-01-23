import 'dart:convert';
import 'package:intl/intl.dart';
import '../../bloc/stock/stock_bloc.dart';
import '../../bloc/stock/stock_event.dart';
import '../database/database_helper.dart';
import '../../models/purchase_model.dart';
import '../utils/logger.dart';

class SupplierPurchaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // CREATE PURCHASE (Full Transaction)
  // ========================================
  Future<int> createPurchaseWithTransaction({
    required int supplierId,
    required List<PurchaseItem> items,
    String? notes,
    Map<String, dynamic>? shopProfile,
    Map<String, dynamic>? supplierData,
    StockBloc? stockBloc,
  }) async {
    final db = await _dbHelper.database;

    if (items.isEmpty) {
      throw ArgumentError('Purchase must have at least one item');
    }

    final now = DateTime.now();
    final String purchaseDate = DateFormat('yyyy-MM-dd HH:mm').format(now);

    final totalAmount =
        items.fold<int>(0, (sum, item) => sum + item.totalAmount);

    final purchaseId = await db.transaction<int>((txn) async {
      // 1. Insert Purchase
      final tempNumber = 'TEMP-${now.microsecondsSinceEpoch}';
      final purchaseId = await txn.insert('purchases', {
        'supplier_id': supplierId,
        'invoice_number': tempNumber,
        'purchase_date': purchaseDate,
        'total_amount': totalAmount,
        'status': 'COMPLETED',
        'notes': notes,
      });

      // 2. Generate Final Purchase Number (SP-YYMMXXXX)
      final yy = (now.year % 100).toString().padLeft(2, '0');
      final mm = now.month.toString().padLeft(2, '0');
      final sequence = purchaseId.toString().padLeft(4, '0');
      final finalNumber = 'SP-$yy$mm$sequence';

      await txn.update(
        'purchases',
        {'invoice_number': finalNumber},
        where: 'id = ?',
        whereArgs: [purchaseId],
      );

      // 3. Insert Items & Update Stock
      for (var item in items) {
        await txn.insert('purchase_items', item.toMap()..['purchase_id'] = purchaseId);

        // Update stock
        if (item.productId != null) {
          await txn.rawUpdate(
            'UPDATE products SET current_stock = current_stock + ? WHERE id = ?',
            [item.quantity, item.productId],
          );

          await txn.insert('stock_activities', {
            'product_id': item.productId,
            'quantity_change': item.quantity,
            'transaction_type': 'PURCHASE',
            'reference_type': 'PURCHASE',
            'reference_id': purchaseId,
            'batch_number': item.batchNumber,
            'expiry_date': item.expiryDate?.toIso8601String(),
            'user': 'SYSTEM',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      // 4. Update Supplier Ledger
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
        'description': 'Purchase #$finalNumber',
        'ref_type': 'PURCHASE',
        'ref_id': purchaseId,
        'debit': totalAmount,
        'credit': 0,
        'balance': newBalance,
      });

      // 5. Snapshot for printing/audit
      if (shopProfile != null && supplierData != null) {
        final snapshot = {
          'shop': shopProfile,
          'purchase': {
            'number': finalNumber,
            'date': DateFormat('yyyy-MM-dd').format(now),
            'time': DateFormat('hh:mm a').format(now),
          },
          'supplier': supplierData,
          'items': items
              .map((e) => {
                    'name_en': e.productId,
                    'qty': e.quantity,
                    'price': e.costPrice,
                    'total': e.totalAmount,
                    'batch_number': e.batchNumber,
                    'expiry_date': e.expiryDate?.toIso8601String(),
                  })
              .toList(),
          'totals': {'total_amount': totalAmount},
        };

        Map<String, dynamic> notesMap = {};
        if (notes != null && notes.isNotEmpty) {
          try {
            notesMap = jsonDecode(notes);
          } catch (_) {
            notesMap['payment_details'] = notes;
          }
        }
        notesMap['snapshot'] = snapshot;

        await txn.update(
          'purchases',
          {'notes': jsonEncode(notesMap)},
          where: 'id = ?',
          whereArgs: [purchaseId],
        );
      }

      AppLogger.info('Purchase created: (ID: $purchaseId)', tag: 'PurchaseRepo');
      return purchaseId;
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

      final purchase = Purchase.fromMap(purchaseRes.first);
      final purchaseNumber = purchase.invoiceNumber ?? '';

      // Mark as CANCELLED
      await txn.update(
        'purchases',
        {
          'status': 'CANCELLED',
          'notes':
              '${purchase.notes ?? ''}\n[Cancelled by $cancelledBy: ${reason ?? 'No reason'}]',
        },
        where: 'id = ?',
        whereArgs: [purchaseId],
      );

      // Revert Stock & Ledger
      final items = await txn.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
      );

      for (var map in items) {
        final item = PurchaseItem.fromMap(map);
        if (item.productId != null) {
          await txn.rawUpdate(
            'UPDATE products SET current_stock = current_stock - ? WHERE id = ?',
            [item.quantity, item.productId],
          );

          await txn.insert('stock_activities', {
            'product_id': item.productId,
            'quantity_change': -item.quantity,
            'transaction_type': 'PURCHASE_CANCEL',
            'reference_type': 'PURCHASE',
            'reference_id': purchaseId,
            'batch_number': item.batchNumber,
            'user': cancelledBy,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      final lastEntry = await txn.rawQuery(
        'SELECT balance FROM supplier_ledger WHERE supplier_id = ? ORDER BY transaction_date DESC, id DESC LIMIT 1',
        [purchase.supplierId],
      );
      int prevBalance =
          lastEntry.isNotEmpty ? (lastEntry.first['balance'] as int) : 0;
      int newBalance = prevBalance - purchase.totalAmount;
      if (newBalance < 0) newBalance = 0;

      await txn.insert('supplier_ledger', {
        'supplier_id': purchase.supplierId,
        'transaction_date': DateTime.now().toIso8601String(),
        'description': 'Purchase Cancelled: #$purchaseNumber',
        'ref_type': 'ADJUSTMENT',
        'ref_id': purchaseId,
        'debit': 0,
        'credit': purchase.totalAmount,
        'balance': newBalance,
      });

      AppLogger.info('Purchase cancelled: #$purchaseNumber', tag: 'PurchaseRepo');
    });

    stockBloc?.add(LoadStock());
  }

  // ========================================
  // PURCHASE QUERIES
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

    final itemsMap = await db.query(
      'purchase_items',
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );

    final items = itemsMap.map((e) => PurchaseItem.fromMap(e)).toList();
    final purchase = Purchase.fromMap(purchaseMap.first);

    return purchase.copyWith(); // You can add items property if your model supports it
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

  Future<int> getTotalPurchasesToday() async {
    final db = await _dbHelper.database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final result = await db.rawQuery(
      'SELECT SUM(total_amount) as total FROM purchases WHERE DATE(purchase_date) = ? AND status = ?',
      [today, 'COMPLETED'],
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<void> deletePurchase(int purchaseId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('purchase_items', where: 'purchase_id = ?', whereArgs: [purchaseId]);
      await txn.delete('purchases', where: 'id = ?', whereArgs: [purchaseId]);
    });
  }
}
