import '../database/database_helper.dart';
import '../utils/logger.dart';

class PurchaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createPurchase(Map<String, dynamic> purchaseData) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      // 1. Insert Purchase
      final purchaseId = await txn.insert('purchases', {
        'supplier_id': purchaseData['supplier_id'],
        'invoice_number': purchaseData['invoice_number'],
        'purchase_date': purchaseData['purchase_date'],
        'total_amount': purchaseData['total_amount'],
        'notes': purchaseData['notes'],
        'status': 'COMPLETED',
      });

      // 2. Insert Items & Update Stock
      for (var item in purchaseData['items']) {
        await txn.insert('purchase_items', {
          'purchase_id': purchaseId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'cost_price': item['cost_price'],
          'total_amount': item['total_amount'],
          'batch_number': item['batch_number'],
          'expiry_date': item['expiry_date'],
        });

        // Update Product Stock
        await txn.rawUpdate(
          'UPDATE products SET current_stock = current_stock + ? WHERE id = ?',
          [item['quantity'], item['product_id']]
        );
      }
      
      // 3. Update Supplier Balance (Payable increases)
      if (purchaseData['supplier_id'] != null) {
        await txn.rawUpdate(
          'UPDATE suppliers SET outstanding_balance = outstanding_balance + ? WHERE id = ?',
          [purchaseData['total_amount'], purchaseData['supplier_id']]
        );
      }

      AppLogger.info('Purchase created successfully: $purchaseId', tag: 'PurchaseRepo');
      return purchaseId;
    });
  }

  /// Cancel a purchase and revert all effects (Stock, Balance)
  Future<void> cancelPurchase(int purchaseId, {String reason = 'Cancelled'}) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Fetch Purchase
      final purchaseRes = await txn.query(
        'purchases',
        where: 'id = ?',
        whereArgs: [purchaseId],
      );

      if (purchaseRes.isEmpty) throw Exception('Purchase not found');
      final purchase = purchaseRes.first;

      if (purchase['status'] == 'CANCELLED') {
        throw Exception('Purchase is already cancelled');
      }

      // 2. Fetch Items
      final items = await txn.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
      );

      // 3. Reverse Stock (Subtract quantity)
      for (var item in items) {
        await txn.rawUpdate(
          'UPDATE products SET current_stock = current_stock - ? WHERE id = ?',
          [item['quantity'], item['product_id']]
        );
      }

      // 4. Reverse Supplier Balance (Decrease payable)
      if (purchase['supplier_id'] != null) {
        await txn.rawUpdate(
          'UPDATE suppliers SET outstanding_balance = outstanding_balance - ? WHERE id = ?',
          [purchase['total_amount'], purchase['supplier_id']]
        );
      }

      // 5. Mark Cancelled
      await txn.update(
        'purchases',
        {
          'status': 'CANCELLED',
          'notes': '${purchase['notes'] ?? ''}\n[Cancelled: $reason]',
        },
        where: 'id = ?',
        whereArgs: [purchaseId],
      );

      AppLogger.info('Purchase #$purchaseId cancelled', tag: 'PurchaseRepo');
    });
  }
}