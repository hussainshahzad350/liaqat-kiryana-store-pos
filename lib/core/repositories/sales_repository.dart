// lib/core/repositories/sales_repository.dart
import '../database/database_helper.dart';
import '../../models/sale_model.dart';
import 'package:intl/intl.dart';
import '../utils/logger.dart';
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SalesRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // SALE CREATION & PROCESSING
  // ========================================

  /// Create a new sale with full transaction safety
  /// Moved from DatabaseHelper.createSale()
  Future<int> createSale(Map<String, dynamic> saleData, {Transaction? txn}) async {
    final db = await _dbHelper.database;
    
    // Validation
    void validatePaisa(String key, {bool required = false}) {
      final val = saleData[key];
      if (required && val == null) {
        throw ArgumentError('$key is required');
      }
      if (val != null && val is! int) {
        throw ArgumentError('$key must be an integer (paisas). Found: $val');
      }
    }

    validatePaisa('grand_total_paisas', required: true);
    validatePaisa('discount_paisas');
    validatePaisa('cash_paisas');
    validatePaisa('bank_paisas');

    // Prepare Financials
    int grandTotal = saleData['grand_total_paisas'] as int;
    int discount = (saleData['discount_paisas'] as int?) ?? 0;
    int cash = (saleData['cash_paisas'] as int?) ?? 0;
    int bank = (saleData['bank_paisas'] as int?) ?? 0;
    
    int totalPaid = cash + bank;
    int remainingBalance = grandTotal - totalPaid;

    if (remainingBalance < 0) remainingBalance = 0;

    // Prepare Date Components for Bill Number
    final now = DateTime.now();
    final String yy = (now.year % 100).toString();
    final String mm = now.month.toString().padLeft(2, '0');

    final String saleDate = DateFormat('yyyy-MM-dd').format(now);
    final String saleTime = DateFormat('HH:mm').format(now);

    Future<int> performCreate(Transaction t) async {
        // Step A: Insert with Temporary Bill Number
        final tempBillNo = 'TEMP-${now.microsecondsSinceEpoch}';

        final saleId = await t.insert('sales', {
          'bill_number': tempBillNo, 
          'customer_id': saleData['customer_id'],
          'sale_date': saleDate,
          'sale_time': saleTime,
          'grand_total': grandTotal,
          'discount': discount,
          'cash_amount': cash,
          'bank_amount': bank,
          'credit_amount': remainingBalance,
          'total_paid': totalPaid,
          'remaining_balance': remainingBalance,
          'sale_snapshot': saleData['sale_snapshot'],
          'original_sale_id': saleData['original_sale_id'],
          'sale_status': saleData['sale_status'] ?? 'COMPLETED',
          'receipt_language': saleData['receipt_language'] ?? 'ur',
          'receipt_printed': 0,
          'receipt_print_count': 0,
        });

        // Step B: Generate Final Atomic Bill Number (SB-YYMMXXXXXX)
        final String sequence = saleId.toString().padLeft(4, '0');
        final String finalBillNumber = 'SB-$yy$mm$sequence';

        // Step C: Update the Sale Record with Final Bill Number
        await t.rawUpdate(
          'UPDATE sales SET bill_number = ? WHERE id = ?',
          [finalBillNumber, saleId]
        );

        // Step D: Insert Items & Handle Stock (Atomic)
        final items = saleData['items'] as List<Map<String, dynamic>>;
        for (var item in items) {
          if (item['sale_price'] is! int) throw ArgumentError('Item sale_price must be int paisas');
          if (item['total'] is! int) throw ArgumentError('Item total must be int paisas');

          final productId = item['id'];
          final quantity = (item['quantity'] as num).toDouble();

          await t.insert('sale_items', {
            'sale_id': saleId,
            'product_id': productId,
            'quantity_sold': quantity,
            'unit_price': item['sale_price'],
            'total_price': item['total'],
            'item_name_english': item['name_english'],
            'item_name_urdu': item['name_urdu'],
            'unit_name': item['unit_name'],
          });

          // Atomic check and update: ensures stock is > quantity
          int count = await t.rawUpdate('''
            UPDATE products 
            SET current_stock = current_stock - ? 
            WHERE id = ? AND current_stock >= ?
          ''', [quantity, productId, quantity]);

          if (count == 0) {
            throw Exception('Insufficient stock or invalid product ID: $productId');
          }
        }

        // Step E: Update Customer Balance (Debt Fix)
        if (saleData['customer_id'] != null && remainingBalance > 0) {
           await t.rawUpdate(
             'UPDATE customers SET outstanding_balance = outstanding_balance + ? WHERE id = ?',
             [remainingBalance, saleData['customer_id']]
           );
        }
        return saleId;
    }

    try {
      int resultId;
      if (txn != null) {
        resultId = await performCreate(txn);
      } else {
        resultId = await db.transaction((t) => performCreate(t));
      }
      AppLogger.info('Sale created successfully', tag: 'SalesRepo');
      return resultId;
    } catch (e) {
      AppLogger.error('Error creating sale: $e', tag: 'SalesRepo');
      throw Exception('Transaction Failed: ${e.toString()}');
    }
  }

  /// Complete a sale and store its snapshot
  Future<int> completeSaleWithSnapshot(Map<String, dynamic> saleData) async {
    final db = await _dbHelper.database;

    // 1. Fetch Shop Profile
    final shopProfile = await db.query('shop_profile', limit: 1);
    final shop = shopProfile.isNotEmpty ? shopProfile.first : {};

    // 2. Fetch Customer (if exists)
    Map<String, dynamic>? customer;
    if (saleData['customer_id'] != null) {
      final cResult = await db.query('customers', where: 'id = ?', whereArgs: [saleData['customer_id']], limit: 1);
      if (cResult.isNotEmpty) customer = cResult.first;
    }

    // 3. Prepare Snapshot Structure (JSON Contract)
    final now = DateTime.now();
    final snapshotMap = {
      'shop': {
        'name_en': shop['shop_name_english'] ?? 'Liaqat Kiryana Store',
        'name_ur': shop['shop_name_urdu'] ?? 'لیاقت کریانہ اسٹور',
        'address': shop['shop_address'] ?? '',
        'contact': shop['contact_primary'] ?? '',
      },
      'sale': {
        'date': DateFormat('yyyy-MM-dd').format(now),
        'time': DateFormat('hh:mm a').format(now),
        // bill_number is generated during createSale, so it's omitted here or can be patched later
      },
      'customer': customer != null ? {
        'name': customer['name_english'],
        'contact': customer['contact_primary'],
        'address': customer['address'],
      } : null,
      'items': (saleData['items'] as List).map((item) => {
        'name_en': item['name_english'],
        'name_ur': item['name_urdu'],
        'qty': item['quantity'],
        'price': item['sale_price'],
        'total': item['total'],
      }).toList(),
      'totals': {
        'grand_total': saleData['grand_total_paisas'],
        'discount': saleData['discount_paisas'] ?? 0,
        'cash_received': saleData['cash_paisas'],
      },
      'currency': 'PKR',
      'direction': 'RTL',
      'language': saleData['receipt_language'] ?? 'ur'
    };
    
    saleData['sale_snapshot'] = jsonEncode(snapshotMap);
    return await createSale(saleData);
  }

  /// Edit an existing sale (Void old -> Create new)
  Future<void> editSale(int oldSaleId, Map<String, dynamic> newSaleData) async {
    final db = await _dbHelper.database;
    
    try {
      await db.transaction((txn) async {
        // 1. Cancel the old sale
        await cancelSale(
          saleId: oldSaleId, 
          cancelledBy: 'System (Edit)', 
          reason: 'Edited Sale',
          txn: txn
        );

        // 2. Link new sale to old one
        newSaleData['original_sale_id'] = oldSaleId;
        newSaleData['sale_status'] = 'EDITED_VERSION';
        
        // 3. Create new sale
        await createSale(newSaleData, txn: txn);
      });
      AppLogger.info('Sale edited successfully (ID: $oldSaleId)', tag: 'SalesRepo');
    } catch (e) {
      AppLogger.error('Error editing sale: $e', tag: 'SalesRepo');
      throw Exception('Edit Failed: ${e.toString()}');
    }
  }

  // ========================================
  // SALE CANCELLATION
  // ========================================

  /// Cancel a sale and revert all changes
  /// Moved from DatabaseHelper.cancelSale()
  Future<void> cancelSale({
    required int saleId,
    required String cancelledBy,
    String? reason,
    Transaction? txn,
  }) async {
    final db = await _dbHelper.database;
    
    Future<void> performCancel(Transaction t) async {
      // 1. Fetch sale (validate)
      final saleRes = await t.query(
        'sales',
        where: 'id = ? AND status = ?',
        whereArgs: [saleId, 'COMPLETED'],
        limit: 1,
      );

      if (saleRes.isEmpty) {
        throw Exception('Sale not found or already cancelled');
      }
      final sale = saleRes.first;
      final int cashAmount = (sale['cash_amount'] as num).toInt();
      final int creditAmount = (sale['credit_amount'] as num).toInt();
      final int? customerId = sale['customer_id'] as int?;

      // 2. Mark sale as CANCELLED
      await t.update(
        'sales',
        {
          'status': 'CANCELLED',
          'cancelled_at': DateTime.now().toIso8601String(),
          'cancelled_by': cancelledBy,
          'cancel_reason': reason,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [saleId],
      );

      // 3. Revert stock
      final items = await t.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );

      for (final item in items) {
        await t.rawUpdate(
          '''
          UPDATE products
          SET current_stock = current_stock + ?
          WHERE id = ?
          ''',
          [
            (item['quantity_sold'] as num).toDouble(),
            item['product_id']
          ],
        );
      }

      // 4. Reverse customer credit (if any)
      if (customerId != null && creditAmount > 0) {
        await t.rawUpdate(
          '''
          UPDATE customers
          SET outstanding_balance = outstanding_balance - ?
          WHERE id = ?
          ''',
          [creditAmount, customerId],
        );
      }

      // 5. Reverse cash (ledger entry)
      if (cashAmount > 0) {
        final now = DateTime.now();
        final dateStr = DateFormat('yyyy-MM-dd').format(now);
        final timeStr = DateFormat('hh:mm a').format(now);

        final balRes = await t.rawQuery(
          'SELECT balance_after FROM cash_ledger ORDER BY id DESC LIMIT 1'
        );

        int currentBalance = 0;
        if (balRes.isNotEmpty) {
          currentBalance = (balRes.first['balance_after'] as num).toInt();
        }

        final int newBalance = currentBalance - cashAmount;

        await t.insert('cash_ledger', {
          'transaction_date': dateStr,
          'transaction_time': timeStr,
          'description': 'Sale Cancelled (Bill #${sale['bill_number']})',
          'type': 'OUT',
          'amount': cashAmount,
          'balance_after': newBalance,
          'remarks': reason ?? 'Sale cancellation',
        });
      }
    }

    try {
      if (txn != null) {
        await performCancel(txn);
      } else {
        await db.transaction((t) => performCancel(t));
      }
      AppLogger.info('Sale cancelled successfully (ID: $saleId)', tag: 'SalesRepo');
    } catch (e) {
      AppLogger.error('Error cancelling sale: $e', tag: 'SalesRepo');
      throw Exception('Cancellation Failed: ${e.toString()}');
    }
  }

  // ========================================
  // SALE QUERIES
  // ========================================

  /// Fetch recent sales with customer info
  Future<List<Sale>> getRecentSales({int limit = 20}) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        s.id, 
        s.bill_number, 
        s.sale_date,
        s.sale_time, 
        s.grand_total, 
        s.cash_amount, 
        s.bank_amount, 
        s.credit_amount,
        s.status,
        COALESCE(c.name_english, 'Walk-in Customer') as customer_name
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      ORDER BY s.created_at DESC
      LIMIT ?
    ''', [limit]);
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  /// Get today's sales total
  /// Moved from DatabaseHelper.getTodaySales()
  Future<int> getTodaySales() async {
    try {
      final db = await _dbHelper.database;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final result = await db.rawQuery(
        'SELECT SUM(grand_total) as total FROM sales WHERE sale_date = ? AND status = ?',
        [today, 'COMPLETED']
      );
      return (result.first['total'] as num?)?.toInt() ?? 0;
    } catch (e) {
      AppLogger.error("Error fetching today's sales: $e", tag: 'SalesRepo');
      return 0;
    }
  }

  /// Get sale by ID with all details
  Future<Sale?> getSaleById(int saleId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [saleId],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return Sale.fromMap(result.first);
  }

  /// Get sale items for a specific sale
  Future<List<SaleItem>> getSaleItems(int saleId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        si.id,
        si.sale_id,
        si.product_id as itemId,
        COALESCE(p.name_english, p.name_urdu) as name,
        si.quantity_sold as quantity,
        si.unit_price as price,
        si.total_price as total
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      WHERE si.sale_id = ?
      ORDER BY si.id
    ''', [saleId]);
    return result.map((map) => SaleItem.fromMap(map)).toList();
  }

  /// Get the JSON snapshot of a sale
  Future<Map<String, dynamic>?> getSaleSnapshot(int saleId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sales',
      columns: ['sale_snapshot'],
      where: 'id = ?',
      whereArgs: [saleId],
      limit: 1,
    );

    if (result.isNotEmpty && result.first['sale_snapshot'] != null) {
      return jsonDecode(result.first['sale_snapshot'] as String);
    }
    return null;
  }

  /// Increment the print count for a sale
  Future<void> incrementPrintCount(int saleId) async {
    final db = await _dbHelper.database;
    await db.rawUpdate('UPDATE sales SET printed_count = printed_count + 1 WHERE id = ?', [saleId]);
  }

  /// Get sales by date range
  Future<List<Sale>> getSalesByDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        s.*,
        COALESCE(c.name_english, 'Walk-in Customer') as customer_name
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE s.sale_date BETWEEN ? AND ?
      AND s.status = 'COMPLETED'
      ORDER BY s.sale_date DESC, s.sale_time DESC
    ''', [startDate, endDate]);
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  /// Get sales by customer
  Future<List<Sale>> getSalesByCustomer(int customerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        s.*,
        c.name_english as customer_name
      FROM sales s
      JOIN customers c ON s.customer_id = c.id
      WHERE s.customer_id = ?
      AND s.status = 'COMPLETED'
      ORDER BY s.sale_date DESC, s.sale_time DESC
    ''', [customerId]);
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  // ========================================
  // DASHBOARD & ANALYTICS
  // ========================================

  /// Get comprehensive dashboard data
  /// Moved from DatabaseHelper.getDashboardData()
  Future<Map<String, dynamic>> getDashboardData() async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. Today's Sales Total
    batch.rawQuery(
      'SELECT SUM(grand_total) as total FROM sales WHERE sale_date = ? AND status = ?',
      [today, 'COMPLETED']
    );

    // 2. Today's Top Customers
    batch.rawQuery('''
      SELECT 
        c.name_urdu, 
        c.name_english, 
        SUM(s.grand_total) as total_amount,
        COUNT(s.id) as sale_count
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE s.sale_date = ? AND c.id IS NOT NULL AND s.status = 'COMPLETED'
      GROUP BY c.id
      ORDER BY total_amount DESC
      LIMIT 5
    ''', [today]);

    // 3. Low Stock Items
    batch.rawQuery('''
      SELECT 
        name_urdu, 
        name_english, 
        current_stock, 
        min_stock_alert,
        sale_price
      FROM products 
      WHERE current_stock > 0 AND current_stock <= min_stock_alert
      ORDER BY (current_stock / min_stock_alert) ASC
      LIMIT 5
    ''');

    // 4. Recent Sales
    batch.rawQuery('''
      SELECT 
        s.id,
        s.bill_number,
        s.status, 
        s.grand_total, 
        s.sale_time,
        COALESCE(c.name_urdu, c.name_english, 'Walk-in Customer') as customer_name
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      ORDER BY s.created_at DESC
      LIMIT 5
    ''');

    final results = await batch.commit();

    return {
      'todaySales': (results[0] as List).isNotEmpty 
          ? ((results[0] as List).first['total'] as num?)?.toInt() ?? 0
          : 0,
      'todayCustomers': (results[1] as List).map((e) => e as Map<String, dynamic>).toList(),
      'lowStockItems': (results[2] as List).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        // Ensure sale_price is int (paisas)
        map['sale_price'] = (map['sale_price'] as num?)?.toInt() ?? 0;
        return map;
      }).toList(),
      'recentSales': (results[3] as List).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        // Ensure grand_total is int (paisas)
        map['grand_total'] = (map['grand_total'] as num?)?.toInt() ?? 0;
        return map;
      }).toList(),
    };
  }

  /// Get recent activities for dashboard
  /// Moved from DatabaseHelper.getRecentActivities()
  Future<List<Map<String, dynamic>>> getRecentActivities({int limit = 10}) async {
    final db = await _dbHelper.database;
    
    List<Map<String, dynamic>> activities = [];
    
    try {
      // 1. Recent Sales (today)
      final sales = await db.rawQuery('''
        SELECT 
          'SALE' as activity_type,
          s.bill_number as title,
          COALESCE(c.name_english, c.name_urdu, 'Cash Sale') as customer_name,
          s.grand_total as amount,
          s.sale_date || ' ' || s.sale_time as timestamp,
          s.status as status
        FROM sales s
        LEFT JOIN customers c ON s.customer_id = c.id
        WHERE DATE(s.sale_date) = DATE('now', 'localtime')
        ORDER BY s.sale_time DESC
        LIMIT 5
      ''');
      
      // 2. Recent Payments (today)
      final payments = await db.rawQuery('''
        SELECT 
          'PAYMENT' as activity_type,
          COALESCE(c.name_english, c.name_urdu, 'Unknown') as title,
          c.name_urdu as customer_name_urdu,
          p.amount as amount,
          p.date || ' 00:00' as timestamp,
          'COMPLETED' as status
        FROM payments p
        JOIN customers c ON p.customer_id = c.id
        WHERE DATE(p.date) = DATE('now', 'localtime')
        ORDER BY p.date DESC
        LIMIT 5
      ''');
      
      // 3. Low Stock Alerts (current)
      final lowStockAlerts = await db.rawQuery('''
        SELECT 
          'ALERT' as activity_type,
          COALESCE(p.name_english, p.name_urdu) as title,
          p.current_stock as stock_level,
          p.min_stock_alert as min_level,
          p.unit_type as unit_name,
          datetime('now', 'localtime') as timestamp,
          'URGENT' as status
        FROM products p
        WHERE p.current_stock <= p.min_stock_alert
        ORDER BY (p.current_stock * 1.0 / p.min_stock_alert) ASC
        LIMIT 3
      ''');
      
      // Sanitize amounts to ensure they are int (paisas)
      activities.addAll(sales.map((e) {
        final map = Map<String, dynamic>.from(e);
        map['amount'] = (map['amount'] as num?)?.toInt() ?? 0;
        return map;
      }));
      activities.addAll(payments.map((e) {
        final map = Map<String, dynamic>.from(e);
        map['amount'] = (map['amount'] as num?)?.toInt() ?? 0;
        return map;
      }));
      activities.addAll(lowStockAlerts);
      
      activities.sort((a, b) {
        final aTime = a['timestamp']?.toString() ?? '';
        final bTime = b['timestamp']?.toString() ?? '';
        return bTime.compareTo(aTime);
      });
      
      return activities.take(limit).toList();
      
    } catch (e) {
      AppLogger.error('Error getting recent activities: $e', tag: 'SalesRepo');
      return [];
    }
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  /// Generate unique invoice/bill ID
  String generateInvoiceId() {
    return 'INV-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Validate stock before sale
  Future<Map<String, dynamic>> validateStock(
    List<Map<String, dynamic>> cartItems
  ) async {
    final db = await _dbHelper.database;
    
    for (var item in cartItems) {
      final productId = item['id'];
      final requestedQty = (item['quantity'] as num).toDouble();

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
          'error': 'Product not found: $productId',
          'productName': 'Unknown',
        };
      }

      final currentStock = (result.first['current_stock'] as num).toDouble();
      final productName = result.first['name_english'];

      if (currentStock < requestedQty) {
        return {
          'valid': false,
          'error': 'Insufficient stock',
          'productName': productName,
          'available': currentStock,
          'requested': requestedQty,
        };
      }
    }

    return {'valid': true};
  }
}