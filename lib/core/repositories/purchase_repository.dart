import 'items_repository.dart';
import '../database/database_helper.dart';
import '../../models/purchase_models.dart';
import '../utils/logger.dart';
import 'package:intl/intl.dart';

class PurchaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ItemsRepository _itemsRepository;

  PurchaseRepository(this._itemsRepository);

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

      // 4. Update the actual Supplier table's outstanding_balance
      await txn.rawUpdate(
        'UPDATE suppliers SET outstanding_balance = outstanding_balance + ? WHERE id = ?',
        [totalAmount, supplierId],
      );

      // 5. Auto-record in Cash Ledger (Cash OUT for purchase)
      if (totalAmount > 0) {
        final dateStr = DateFormat('yyyy-MM-dd').format(now);
        final timeStr = DateFormat('hh:mm a').format(now);
        final res = await txn.rawQuery(
            'SELECT balance_after FROM cash_ledger ORDER BY id DESC LIMIT 1');
        int currentCashBalance =
            res.isNotEmpty ? (res.first['balance_after'] as num).toInt() : 0;

        await txn.insert('cash_ledger', {
          'transaction_date': dateStr,
          'transaction_time': timeStr,
          'description': 'Purchase #$id from Supplier',
          'type': 'OUT',
          'amount': totalAmount,
          'balance_after': currentCashBalance - totalAmount,
          'remarks': notes ?? '',
          'payment_mode': 'CASH',
        });
      }

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
        final batchNumber = item['batch_number'] as String?;
        final expiryRaw = item['expiry_date']?.toString();
        final expiryDate =
            expiryRaw != null ? DateTime.tryParse(expiryRaw) : null;

        // Fetch product details for better error message
        final productRes = await txn.query(
          'products',
          columns: ['name_english', 'current_stock'],
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );

        if (productRes.isEmpty) {
          throw Exception('Product $productId not found');
        }

        final productName = productRes.first['name_english'] as String;
        final currentStock = (productRes.first['current_stock'] as num).toDouble();

        if (currentStock < quantity) {
          throw Exception(
              'Cannot cancel purchase: insufficient stock for product $productName. '
              'Current stock: $currentStock, required to subtract: $quantity');
        }

        // Reduce total stock
        await txn.rawUpdate(
          'UPDATE products SET current_stock = current_stock - ? WHERE id = ?',
          [quantity, productId],
        );

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

      // 5. Reverse Supplier outstanding_balance
      await txn.rawUpdate(
        'UPDATE suppliers SET outstanding_balance = outstanding_balance - ? WHERE id = ?',
        [purchase['total_amount'], supplierId],
      );

      // 6. Reverse Cash Ledger Entries
      final cashEntries = await txn.query(
        'cash_ledger',
        where: 'description LIKE ?',
        whereArgs: ['%Purchase #$purchaseId%'],
      );

      for (var entry in cashEntries) {
        final entryAmount = (entry['amount'] as num).toInt();
        final entryType = entry['type'] as String;
        final entryMode = (entry['payment_mode'] as String?) ?? 'CASH';

        // Reversal: OUT becomes IN, IN becomes OUT
        final reversalType = entryType == 'IN' ? 'OUT' : 'IN';
        
        final res = await txn.rawQuery(
          'SELECT balance_after FROM cash_ledger ORDER BY id DESC LIMIT 1'
        );
        int currentCashBalance = res.isNotEmpty 
            ? (res.first['balance_after'] as num).toInt() 
            : 0;

        await txn.insert('cash_ledger', {
          'transaction_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'transaction_time': DateFormat('hh:mm a').format(DateTime.now()),
          'description': 'Reversal: Purchase #$purchaseId cancelled',
          'type': reversalType,
          'amount': entryAmount,
          'balance_after': reversalType == 'IN' 
              ? currentCashBalance + entryAmount 
              : currentCashBalance - entryAmount,
          'remarks': 'Auto-reversal for cancelled purchase',
          'payment_mode': entryMode,
        });
      }

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
