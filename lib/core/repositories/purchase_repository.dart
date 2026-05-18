import 'items_repository.dart';
import '../database/database_helper.dart';
import '../../models/purchase_models.dart';
import '../utils/logger.dart';
import 'package:sqflite/sqflite.dart';

class PurchaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ItemsRepository _itemsRepository;

  PurchaseRepository(this._itemsRepository);

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
        tag: 'PurchaseRepo',
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
    String? batchNumber,
    String? expiryDate,
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
      'batch_number': batchNumber,
      'expiry_date': expiryDate,
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

  // ========================================
  // CREATE PURCHASE WITH TRANSACTION
  // ========================================
  Future<int> createPurchaseWithTransaction({
    required int supplierId,
    required List<Map<String, dynamic>> items,
    int totalAmount = 0,
    String? invoiceNumber,
    String? notes,
  }) async {
    final db = await _dbHelper.database;

    if (items.isEmpty) {
      throw ArgumentError('Purchase must have at least one item');
    }

    final now = DateTime.now();
    final String purchaseDate = now.toUtc().toIso8601String();

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
        final productId = item['product_id'] as int;
        final quantity = (item['quantity'] as num).toDouble();
        final costPrice = (item['cost_price'] as num).toInt();
        final total = (item['total_amount'] as num).toInt();
        final batchNumber = item['batch_number'] as String?;
        final expiryDate = item['expiry_date'];
        final DateTime? parsedExpiry = expiryDate is String
            ? DateTime.tryParse(expiryDate)
            : (expiryDate is DateTime ? expiryDate : null);

        final purchaseItemId = await txn.insert('purchase_items', {
          'purchase_id': id,
          'product_id': productId,
          'quantity': quantity,
          'cost_price': costPrice,
          'total_amount': total,
          'batch_number': batchNumber,
          'expiry_date': parsedExpiry?.toIso8601String(),
        });

        await _recordStockEvent(
          txn,
          productId: productId,
          quantityChange: quantity,
          transactionType: 'PURCHASE',
          refType: 'PURCHASE',
          refId: id,
          transactionId: 'PURCHASE:$id:ITEM:$purchaseItemId',
          user: 'SYSTEM',
          batchNumber: batchNumber,
          expiryDate: parsedExpiry?.toIso8601String(),
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
        'transaction_id': 'PURCHASE:$id:SUPPLIER_LEDGER',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      // 4. Update the actual Supplier table's outstanding_balance
      await txn.rawUpdate(
        'UPDATE suppliers SET outstanding_balance = outstanding_balance + ? WHERE id = ?',
        [totalAmount, supplierId],
      );

      AppLogger.info('Purchase created: ID $id', tag: 'PurchaseRepo');
      return id;
    });

    // Refresh stock
    _itemsRepository.notifyStockChanged();

    return purchaseId;
  }

  // Alias for backward compatibility
  Future<int> createPurchase({
    required int supplierId,
    required List<Map<String, dynamic>> items,
    int totalAmount = 0,
    String? invoiceNumber,
    String? notes,
  }) {
    return createPurchaseWithTransaction(
      supplierId: supplierId,
      items: items,
      totalAmount: totalAmount,
      invoiceNumber: invoiceNumber,
      notes: notes,
    );
  }

  // ========================================
  // CANCEL PURCHASE
  // ========================================
  Future<void> cancelPurchase({
    required int purchaseId,
    required String cancelledBy,
    String? reason,
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
        throw Exception('PURCHASE_NOT_FOUND');
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

      // 3. Revert Stock by reversing original stock events
      final purchaseEvents = await txn.query(
        'stock_activities',
        columns: ['id', 'product_id', 'quantity_change', 'batch_number', 'expiry_date'],
        where:
            'ref_type = ? AND ref_id = ? AND transaction_type = ? AND reversal_of_stock_activity_id IS NULL',
        whereArgs: ['PURCHASE', purchaseId, 'PURCHASE'],
      );
      if (purchaseEvents.isEmpty) {
        throw Exception('STOCK_EVENTS_NOT_FOUND');
      }

      for (final event in purchaseEvents) {
        final originalEventId = event['id'] as int;
        final productId = event['product_id'] as int;
        final quantity = (event['quantity_change'] as num).toDouble();
        await _recordStockEvent(
          txn,
          productId: productId,
          quantityChange: -quantity,
          transactionType: 'PURCHASE_CANCEL',
          refType: 'PURCHASE',
          refId: purchaseId,
          transactionId: 'PURCHASE_CANCEL:$purchaseId:EVENT:$originalEventId',
          user: cancelledBy,
          reversalOfStockActivityId: originalEventId,
          batchNumber: event['batch_number'] as String?,
          expiryDate: event['expiry_date']?.toString(),
        );
      }

      // 4. Reverse Supplier Ledger using original purchase ledger entry
      final originalPurchaseLedger = await txn.rawQuery(
        'SELECT id, debit, credit FROM supplier_ledger WHERE supplier_id = ? AND ref_type = ? AND ref_id = ? ORDER BY transaction_date ASC, id ASC LIMIT 1',
        [supplierId, 'PURCHASE', purchaseId],
      );
      if (originalPurchaseLedger.isEmpty) {
        AppLogger.error(
          'Cancel purchase failed: original supplier ledger entry not found (purchaseId=$purchaseId)',
          tag: 'PurchaseRepository',
        );
        throw Exception('PURCHASE_LEDGER_NOT_FOUND');
      }

      final originalLedgerEntryId =
          (originalPurchaseLedger.first['id'] as num?)?.toInt();
      final originalDebit =
          (originalPurchaseLedger.first['debit'] as num?)?.toInt() ?? 0;
      final originalCredit =
          (originalPurchaseLedger.first['credit'] as num?)?.toInt() ?? 0;
      final reversalAmount = originalDebit - originalCredit;
      if (reversalAmount <= 0) {
        throw Exception('PURCHASE_LEDGER_INVALID');
      }

      final lastEntry = await txn.rawQuery(
        'SELECT balance FROM supplier_ledger WHERE supplier_id = ? ORDER BY transaction_date DESC, id DESC LIMIT 1',
        [supplierId],
      );
      final prevBalance = lastEntry.isNotEmpty
          ? (lastEntry.first['balance'] as num?)?.toInt() ?? 0
          : 0;
      final newBalance = prevBalance - reversalAmount;

      final cancelNow = DateTime.now().toUtc().toIso8601String();
      await txn.insert('supplier_ledger', {
        'supplier_id': supplierId,
        'transaction_date': cancelNow,
        'description': 'Purchase Cancelled: #$purchaseId',
        'ref_type': 'PURCHASE_RETURN',
        'ref_id': purchaseId,
        'debit': 0,
        'credit': reversalAmount,
        'balance': newBalance,
        'transaction_id': 'PURCHASE_CANCEL:$purchaseId:SUPPLIER_LEDGER',
        'reversal_of_supplier_ledger_id': originalLedgerEntryId,
        'created_at': cancelNow,
      });

      // 5. Reverse Supplier outstanding_balance to ledger balance
      await txn.update(
        'suppliers',
        {'outstanding_balance': newBalance},
        where: 'id = ?',
        whereArgs: [supplierId],
      );

      AppLogger.info('Purchase cancelled: ID $purchaseId', tag: 'PurchaseRepo');
    });

    // Refresh stock
    _itemsRepository.notifyStockChanged();
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
