// lib/core/repositories/sales_repository.dart
import '../database/database_helper.dart';
import '../../models/sale_model.dart';
import 'package:intl/intl.dart';
import '../utils/logger.dart';

class SalesRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // SALE CREATION & PROCESSING
  // ========================================

  /// Create a new sale with full transaction safety
  /// Moved from DatabaseHelper.createSale()
  Future<void> createSale(Map<String, dynamic> saleData) async {
    final db = await _dbHelper.database;
    
    // Prepare Financials
    double grandTotal = (saleData['grand_total'] as num).toDouble();
    double cash = (saleData['cash_amount'] as num?)?.toDouble() ?? 0.0;
    double bank = (saleData['bank_amount'] as num?)?.toDouble() ?? 0.0;
    
    double totalPaid = cash + bank;
    double remainingBalance = grandTotal - totalPaid;

    if (remainingBalance < 0) remainingBalance = 0;

    // Prepare Date Components for Bill Number
    final now = DateTime.now();
    final String yy = (now.year % 100).toString();
    final String mm = now.month.toString().padLeft(2, '0');

    final String saleDate = DateFormat('yyyy-MM-dd').format(now);
    final String saleTime = DateFormat('HH:mm').format(now);

    try {
      await db.transaction((txn) async {
        // Step A: Insert with Temporary Bill Number
        final tempBillNo = 'TEMP-${now.microsecondsSinceEpoch}';

        final saleId = await txn.insert('sales', {
          'bill_number': tempBillNo, 
          'customer_id': saleData['customer_id'],
          'sale_date': saleDate,
          'sale_time': saleTime,
          'grand_total': grandTotal,
          'discount': saleData['discount'] ?? 0.0,
          'cash_amount': cash,
          'bank_amount': bank,
          'credit_amount': remainingBalance,
          'total_paid': totalPaid,
          'remaining_balance': remainingBalance,
        });

        // Step B: Generate Final Atomic Bill Number (SB-YYMMXXXXXX)
        final String sequence = saleId.toString().padLeft(4, '0');
        final String finalBillNumber = 'SB-$yy$mm$sequence';

        // Step C: Update the Sale Record with Final Bill Number
        await txn.rawUpdate(
          'UPDATE sales SET bill_number = ? WHERE id = ?',
          [finalBillNumber, saleId]
        );

        // Step D: Insert Items & Handle Stock (Atomic)
        final items = saleData['items'] as List<Map<String, dynamic>>;
        for (var item in items) {
          final productId = item['id'];
          final quantity = (item['quantity'] as num).toDouble();

          await txn.insert('sale_items', {
            'sale_id': saleId,
            'product_id': productId,
            'quantity_sold': quantity,
            'unit_price': item['sale_price'],
            'total_price': item['total'],
          });

          // Atomic check and update: ensures stock is > quantity
          int count = await txn.rawUpdate('''
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
           await txn.rawUpdate(
             'UPDATE customers SET outstanding_balance = outstanding_balance + ? WHERE id = ?',
             [remainingBalance, saleData['customer_id']]
           );
        }
      });
      AppLogger.info('Sale created successfully', tag: 'SalesRepo');
    } catch (e) {
      AppLogger.error('Error creating sale: $e', tag: 'SalesRepo');
      throw Exception('Transaction Failed: ${e.toString()}');
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
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Fetch sale (validate)
      final saleRes = await txn.query(
        'sales',
        where: 'id = ? AND status = ?',
        whereArgs: [saleId, 'COMPLETED'],
        limit: 1,
      );

      if (saleRes.isEmpty) {
        throw Exception('Sale not found or already cancelled');
      }
      final sale = saleRes.first;
      final double cashAmount = (sale['cash_amount'] as num).toDouble();
      final double creditAmount = (sale['credit_amount'] as num).toDouble();
      final int? customerId = sale['customer_id'] as int?;

      // 2. Mark sale as CANCELLED
      await txn.update(
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
      final items = await txn.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );

      for (final item in items) {
        await txn.rawUpdate(
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
        await txn.rawUpdate(
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

        final balRes = await txn.rawQuery(
          'SELECT balance_after FROM cash_ledger ORDER BY id DESC LIMIT 1'
        );

        double currentBalance = 0.0;
        if (balRes.isNotEmpty) {
          currentBalance = (balRes.first['balance_after'] as num).toDouble();
        }

        final newBalance = currentBalance - cashAmount;

        await txn.insert('cash_ledger', {
          'transaction_date': dateStr,
          'transaction_time': timeStr,
          'description': 'Sale Cancelled (Bill #${sale['bill_number']})',
          'type': 'OUT',
          'amount': cashAmount,
          'balance_after': newBalance,
          'remarks': reason ?? 'Sale cancellation',
        });
      }
    });
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
  Future<double> getTodaySales() async {
    try {
      final db = await _dbHelper.database;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final result = await db.rawQuery(
        'SELECT SUM(grand_total) as total FROM sales WHERE sale_date = ? AND status = ?',
        [today, 'COMPLETED']
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      AppLogger.error("Error fetching today's sales: $e", tag: 'SalesRepo');
      return 0.0;
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
          ? ((results[0] as List).first['total'] as num?)?.toDouble() ?? 0.0  
          : 0.0,
      'todayCustomers': (results[1] as List).map((e) => e as Map<String, dynamic>).toList(),
      'lowStockItems': (results[2] as List).map((e) => e as Map<String, dynamic>).toList(),
      'recentSales': (results[3] as List).map((e) => e as Map<String, dynamic>).toList(),
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
      
      activities.addAll(sales);
      activities.addAll(payments);
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