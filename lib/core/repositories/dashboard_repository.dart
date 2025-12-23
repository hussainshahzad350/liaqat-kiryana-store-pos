// lib/core/repositories/dashboard_repository.dart
import '../database/database_helper.dart';
import '../utils/logger.dart';
import 'package:intl/intl.dart';

class DashboardRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // MAIN DASHBOARD DATA
  // ========================================

  /// Get comprehensive dashboard data
  /// Combines multiple queries for dashboard overview
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
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
    } catch (e) {
      AppLogger.error('Error getting dashboard data: $e', tag: 'DashboardRepo');
      return {
        'todaySales': 0.0,
        'todayCustomers': [],
        'lowStockItems': [],
        'recentSales': [],
      };
    }
  }

  // ========================================
  // SALES STATISTICS
  // ========================================

  /// Get today's sales total
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
      AppLogger.error("Error fetching today's sales: $e", tag: 'DashboardRepo');
      return 0.0;
    }
  }

  /// Get this week's sales
  Future<double> getWeeklySales() async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateFormat('yyyy-MM-dd').format(weekStart);
      final endDate = DateFormat('yyyy-MM-dd').format(now);
      
      final result = await db.rawQuery('''
        SELECT SUM(grand_total) as total 
        FROM sales 
        WHERE sale_date BETWEEN ? AND ? AND status = ?
      ''', [startDate, endDate, 'COMPLETED']);
      
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      AppLogger.error("Error fetching weekly sales: $e", tag: 'DashboardRepo');
      return 0.0;
    }
  }

  /// Get this month's sales
  Future<double> getMonthlySales() async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final startDate = DateFormat('yyyy-MM-dd').format(
        DateTime(now.year, now.month, 1)
      );
      final endDate = DateFormat('yyyy-MM-dd').format(now);
      
      final result = await db.rawQuery('''
        SELECT SUM(grand_total) as total 
        FROM sales 
        WHERE sale_date BETWEEN ? AND ? AND status = ?
      ''', [startDate, endDate, 'COMPLETED']);
      
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      AppLogger.error("Error fetching monthly sales: $e", tag: 'DashboardRepo');
      return 0.0;
    }
  }

  /// Get sales for date range
  Future<double> getSalesByDateRange(String startDate, String endDate) async {
    try {
      final db = await _dbHelper.database;
      
      final result = await db.rawQuery('''
        SELECT SUM(grand_total) as total 
        FROM sales 
        WHERE sale_date BETWEEN ? AND ? AND status = ?
      ''', [startDate, endDate, 'COMPLETED']);
      
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      AppLogger.error("Error fetching sales by date range: $e", tag: 'DashboardRepo');
      return 0.0;
    }
  }

  /// Get sales count for period
  Future<int> getSalesCount({String? startDate, String? endDate}) async {
    try {
      final db = await _dbHelper.database;
      
      String query = 'SELECT COUNT(*) as count FROM sales WHERE status = ?';
      List<dynamic> args = ['COMPLETED'];
      
      if (startDate != null && endDate != null) {
        query += ' AND sale_date BETWEEN ? AND ?';
        args.add(startDate);
        args.add(endDate);
      }
      
      final result = await db.rawQuery(query, args);
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      AppLogger.error("Error fetching sales count: $e", tag: 'DashboardRepo');
      return 0;
    }
  }

  // ========================================
  // TOP PERFORMERS
  // ========================================

  /// Get today's top customers
  Future<List<Map<String, dynamic>>> getTodayTopCustomers({int limit = 5}) async {
    try {
      final db = await _dbHelper.database;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      return await db.rawQuery('''
        SELECT 
          c.id,
          c.name_urdu, 
          c.name_english, 
          SUM(s.grand_total) as total_amount,
          COUNT(s.id) as sale_count
        FROM sales s
        LEFT JOIN customers c ON s.customer_id = c.id
        WHERE s.sale_date = ? AND c.id IS NOT NULL AND s.status = 'COMPLETED'
        GROUP BY c.id
        ORDER BY total_amount DESC
        LIMIT ?
      ''', [today, limit]);
    } catch (e) {
      AppLogger.error("Error fetching today's customers: $e", tag: 'DashboardRepo');
      return [];
    }
  }

  /// Get top selling products
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    int limit = 10,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final db = await _dbHelper.database;
      
      String query = '''
        SELECT 
          p.id,
          p.name_english,
          p.name_urdu,
          p.sale_price,
          SUM(si.quantity_sold) as total_sold,
          SUM(si.total_price) as total_revenue,
          COUNT(DISTINCT si.sale_id) as sale_count
        FROM products p
        JOIN sale_items si ON p.id = si.product_id
        JOIN sales s ON si.sale_id = s.id
        WHERE s.status = 'COMPLETED'
      ''';

      List<dynamic> args = [];

      if (startDate != null && endDate != null) {
        query += ' AND s.sale_date BETWEEN ? AND ?';
        args.add(startDate);
        args.add(endDate);
      }

      query += '''
        GROUP BY p.id
        ORDER BY total_sold DESC
        LIMIT ?
      ''';
      args.add(limit);

      return await db.rawQuery(query, args);
    } catch (e) {
      AppLogger.error("Error fetching top selling products: $e", tag: 'DashboardRepo');
      return [];
    }
  }

  /// Get top customers by revenue
  Future<List<Map<String, dynamic>>> getTopCustomersByRevenue({
    int limit = 10,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final db = await _dbHelper.database;
      
      String query = '''
        SELECT 
          c.id,
          c.name_english,
          c.name_urdu,
          c.contact_primary,
          SUM(s.grand_total) as total_revenue,
          COUNT(s.id) as purchase_count,
          AVG(s.grand_total) as avg_order_value
        FROM customers c
        JOIN sales s ON c.id = s.customer_id
        WHERE s.status = 'COMPLETED'
      ''';

      List<dynamic> args = [];

      if (startDate != null && endDate != null) {
        query += ' AND s.sale_date BETWEEN ? AND ?';
        args.add(startDate);
        args.add(endDate);
      }

      query += '''
        GROUP BY c.id
        ORDER BY total_revenue DESC
        LIMIT ?
      ''';
      args.add(limit);

      return await db.rawQuery(query, args);
    } catch (e) {
      AppLogger.error("Error fetching top customers: $e", tag: 'DashboardRepo');
      return [];
    }
  }

  // ========================================
  // RECENT ACTIVITIES
  // ========================================

  /// Get recent activities (sales, payments, alerts)
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
      AppLogger.error('Error getting recent activities: $e', tag: 'DashboardRepo');
      return [];
    }
  }

  // ========================================
  // ALERTS & NOTIFICATIONS
  // ========================================

  /// Get low stock items
  Future<List<Map<String, dynamic>>> getLowStockItems({int limit = 5}) async {
    try {
      final db = await _dbHelper.database;
      return await db.rawQuery('''
        SELECT 
          name_urdu, 
          name_english, 
          current_stock, 
          min_stock_alert,
          sale_price
        FROM products 
        WHERE current_stock > 0 AND current_stock <= min_stock_alert
        ORDER BY (current_stock / min_stock_alert) ASC
        LIMIT ?
      ''', [limit]);
    } catch (e) {
      AppLogger.error("Error fetching low stock items: $e", tag: 'DashboardRepo');
      return [];
    }
  }

  /// Get out of stock items count
  Future<int> getOutOfStockCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE current_stock = 0'
      );
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      AppLogger.error("Error fetching out of stock count: $e", tag: 'DashboardRepo');
      return 0;
    }
  }

  /// Get customers near credit limit
  Future<List<Map<String, dynamic>>> getCustomersNearCreditLimit({
    double threshold = 0.8,
    int limit = 5,
  }) async {
    try {
      final db = await _dbHelper.database;
      return await db.rawQuery('''
        SELECT 
          id,
          name_english,
          name_urdu,
          contact_primary,
          credit_limit,
          outstanding_balance,
          (outstanding_balance * 1.0 / credit_limit) as usage_ratio
        FROM customers
        WHERE credit_limit > 0 
        AND outstanding_balance > 0
        AND (outstanding_balance * 1.0 / credit_limit) >= ?
        ORDER BY usage_ratio DESC
        LIMIT ?
      ''', [threshold, limit]);
    } catch (e) {
      AppLogger.error("Error fetching customers near limit: $e", tag: 'DashboardRepo');
      return [];
    }
  }

  // ========================================
  // SALES TRENDS
  // ========================================

  /// Get daily sales trend for last N days
  Future<List<Map<String, dynamic>>> getDailySalesTrend({int days = 7}) async {
    try {
      final db = await _dbHelper.database;
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      return await db.rawQuery('''
        SELECT 
          sale_date as date,
          COUNT(*) as sale_count,
          SUM(grand_total) as total_sales,
          AVG(grand_total) as avg_sale_value
        FROM sales
        WHERE sale_date >= ? AND status = 'COMPLETED'
        GROUP BY sale_date
        ORDER BY sale_date ASC
      ''', [DateFormat('yyyy-MM-dd').format(startDate)]);
    } catch (e) {
      AppLogger.error("Error fetching daily sales trend: $e", tag: 'DashboardRepo');
      return [];
    }
  }

  /// Get hourly sales trend for today
  Future<List<Map<String, dynamic>>> getHourlySalesTrend() async {
    try {
      final db = await _dbHelper.database;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      return await db.rawQuery('''
        SELECT 
          CAST(strftime('%H', sale_time) AS INTEGER) as hour,
          COUNT(*) as sale_count,
          SUM(grand_total) as total_sales
        FROM sales
        WHERE sale_date = ? AND status = 'COMPLETED'
        GROUP BY hour
        ORDER BY hour ASC
      ''', [today]);
    } catch (e) {
      AppLogger.error("Error fetching hourly sales trend: $e", tag: 'DashboardRepo');
      return [];
    }
  }

  // ========================================
  // KEY METRICS
  // ========================================

  /// Get comprehensive business metrics
  Future<Map<String, dynamic>> getBusinessMetrics() async {
    try {
      final db = await _dbHelper.database;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Get multiple metrics in one go
      final batch = db.batch();
      
      // Total sales today
      batch.rawQuery(
        'SELECT SUM(grand_total) as total FROM sales WHERE sale_date = ? AND status = ?',
        [today, 'COMPLETED']
      );
      
      // Total customers
      batch.rawQuery('SELECT COUNT(*) as count FROM customers');
      
      // Total products
      batch.rawQuery('SELECT COUNT(*) as count FROM products');
      
      // Total stock value
      batch.rawQuery('SELECT SUM(current_stock * avg_cost_price) as total FROM products');
      
      // Outstanding balance
      batch.rawQuery('SELECT SUM(outstanding_balance) as total FROM customers');
      
      // Low stock count
      batch.rawQuery('''
        SELECT COUNT(*) as count FROM products 
        WHERE current_stock > 0 AND current_stock <= min_stock_alert
      ''');
      
      final results = await batch.commit();
      
      return {
        'todaySales': (results[0] as List).first['total'] ?? 0.0,
        'totalCustomers': (results[1] as List).first['count'] ?? 0,
        'totalProducts': (results[2] as List).first['count'] ?? 0,
        'stockValue': (results[3] as List).first['total'] ?? 0.0,
        'outstandingBalance': (results[4] as List).first['total'] ?? 0.0,
        'lowStockCount': (results[5] as List).first['count'] ?? 0,
      };
    } catch (e) {
      AppLogger.error("Error fetching business metrics: $e", tag: 'DashboardRepo');
      return {
        'todaySales': 0.0,
        'totalCustomers': 0,
        'totalProducts': 0,
        'stockValue': 0.0,
        'outstandingBalance': 0.0,
        'lowStockCount': 0,
      };
    }
  }

  /// Get profit estimate
  Future<Map<String, dynamic>> getProfitEstimate({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final db = await _dbHelper.database;
      
      String query = '''
        SELECT 
          SUM(si.total_price) as revenue,
          SUM(si.quantity_sold * p.avg_cost_price) as cost
        FROM sale_items si
        JOIN products p ON si.product_id = p.id
        JOIN sales s ON si.sale_id = s.id
        WHERE s.status = 'COMPLETED'
      ''';
      
      List<dynamic> args = [];
      
      if (startDate != null && endDate != null) {
        query += ' AND s.sale_date BETWEEN ? AND ?';
        args.add(startDate);
        args.add(endDate);
      }
      
      final result = await db.rawQuery(query, args);
      
      if (result.isEmpty) {
        return {
          'revenue': 0.0,
          'cost': 0.0,
          'profit': 0.0,
          'margin': 0.0,
        };
      }
      
      final revenue = (result.first['revenue'] as num?)?.toDouble() ?? 0.0;
      final cost = (result.first['cost'] as num?)?.toDouble() ?? 0.0;
      final profit = revenue - cost;
      final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;
      
      return {
        'revenue': revenue,
        'cost': cost,
        'profit': profit,
        'margin': margin,
      };
    } catch (e) {
      AppLogger.error("Error fetching profit estimate: $e", tag: 'DashboardRepo');
      return {
        'revenue': 0.0,
        'cost': 0.0,
        'profit': 0.0,
        'margin': 0.0,
      };
    }
  }
}