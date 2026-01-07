import '../database/database_helper.dart';
import '../entity/purchase_bill_entity.dart';
import '../../domain/entities/money.dart';

class PurchaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Create a new purchase bill
  /// 1. Inserts Bill
  /// 2. Inserts Items
  /// 3. Updates Product Stock & Avg Cost
  /// 4. Updates Supplier Balance
  Future<int> createPurchase(PurchaseBillEntity bill) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      // 1. Insert Purchase Record
      final purchaseId = await txn.insert('purchases', {
        'supplier_id': bill.supplierId,
        'invoice_number': bill.invoiceNumber,
        'purchase_date': bill.purchaseDate.toIso8601String(),
        'total_amount': bill.totalAmount.paisas,
        'notes': bill.notes,
      });

      // 2. Process Items
      for (var item in bill.items) {
        // Insert Item
        await txn.insert('purchase_items', {
          'purchase_id': purchaseId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'cost_price': item.costPrice.paisas,
          'total_amount': item.totalCost.paisas,
        });

        // 3. Update Product (Stock + Weighted Avg Cost)
        // Fetch current state
        final productRes = await txn.query(
          'products',
          columns: ['current_stock', 'avg_cost_price'],
          where: 'id = ?',
          whereArgs: [item.productId],
        );

        if (productRes.isNotEmpty) {
          final currentStock = (productRes.first['current_stock'] as num).toDouble();
          final currentCost = (productRes.first['avg_cost_price'] as num).toInt();

          final newStock = currentStock + item.quantity;
          
          // Weighted Average Formula:
          // ((OldStock * OldCost) + (NewQty * NewCost)) / TotalStock
          final oldTotalVal = currentStock * currentCost;
          final newTotalVal = item.quantity * item.costPrice.paisas;
          
          int newAvgCost = currentCost;
          if (newStock > 0) {
            newAvgCost = ((oldTotalVal + newTotalVal) / newStock).round();
          }

          await txn.update(
            'products',
            {
              'current_stock': newStock,
              'avg_cost_price': newAvgCost,
            },
            where: 'id = ?',
            whereArgs: [item.productId],
          );
        }
      }

      // 4. Update Supplier Balance (We owe them money)
      await txn.rawUpdate(
        'UPDATE suppliers SET outstanding_balance = outstanding_balance + ? WHERE id = ?',
        [bill.totalAmount.paisas, bill.supplierId],
      );

      return purchaseId;
    });
  }

  /// Get purchase details by ID
  Future<PurchaseBillEntity?> getPurchaseById(int id) async {
    final db = await _dbHelper.database;
    
    // Fetch Bill
    final billRes = await db.query('purchases', where: 'id = ?', whereArgs: [id]);
    if (billRes.isEmpty) return null;
    final billRow = billRes.first;

    // Fetch Items
    final itemsRes = await db.rawQuery('''
      SELECT pi.*, p.name_english as product_name 
      FROM purchase_items pi
      LEFT JOIN products p ON pi.product_id = p.id
      WHERE pi.purchase_id = ?
    ''', [id]);

    final items = itemsRes.map((row) => PurchaseItemEntity(
      id: row['id'] as int,
      productId: row['product_id'] as int,
      productName: row['product_name'] as String? ?? 'Unknown',
      quantity: (row['quantity'] as num).toDouble(),
      costPrice: Money((row['cost_price'] as num).toInt()),
      totalCost: Money((row['total_amount'] as num).toInt()),
    )).toList();

    return PurchaseBillEntity(
      id: billRow['id'] as int,
      supplierId: billRow['supplier_id'] as int,
      invoiceNumber: billRow['invoice_number'] as String,
      purchaseDate: DateTime.parse(billRow['purchase_date'] as String),
      totalAmount: Money((billRow['total_amount'] as num).toInt()),
      notes: billRow['notes'] as String?,
      items: items,
      createdAt: DateTime.parse(billRow['created_at'] as String),
    );
  }
}