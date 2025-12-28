// lib/core/repositories/customers_repository.dart
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../utils/logger.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';

class CustomersRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // CUSTOMER CRUD OPERATIONS
  // ========================================

  /// Get all customers
  Future<List<Customer>> getAllCustomers() async {
    final db = await _dbHelper.database;
    final result = await db.query('customers', orderBy: 'name_english ASC');
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  /// Get active customers
  Future<List<Customer>> getActiveCustomers() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'customers',
      where: 'is_active = 1',
      orderBy: 'name_english ASC',
    );
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  /// Get customer by ID
  Future<Customer?> getCustomerById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return Customer.fromMap(result.first);
  }

  /// Add new customer
  Future<int> addCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update customer details
  Future<int> updateCustomer(int id, Customer customer) async {
    final db = await _dbHelper.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete customer
  Future<int> deleteCustomer(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Search customers by name or phone
  Future<List<Customer>> searchCustomers(String query, {bool activeOnly = false}) async {
    final db = await _dbHelper.database;
    final q = '%${query.toLowerCase()}%';
    
    String whereClause = '(LOWER(name_english) LIKE ? OR LOWER(name_urdu) LIKE ? OR contact_primary LIKE ?)';
    List<dynamic> args = [q, q, query];

    if (activeOnly) {
      whereClause += ' AND is_active = 1';
    }

    final result = await db.query(
      'customers',
      where: whereClause,
      whereArgs: args,
      orderBy: 'name_english ASC',
    );
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  /// Get archived customers
  Future<List<Customer>> getArchivedCustomers() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'customers',
      where: 'is_active = 0',
      orderBy: 'name_english ASC',
    );
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  /// Check if phone number is unique
  Future<bool> isPhoneUnique(String phone, {int? excludeId}) async {
    final db = await _dbHelper.database;
    String whereClause = 'contact_primary = ?';
    List<dynamic> whereArgs = [phone];
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    final result = await db.query(
      'customers',
      where: whereClause,
      whereArgs: whereArgs,
    );
    return result.isEmpty;
  }

  // ========================================
  // CREDIT LIMIT MANAGEMENT
  // ========================================

  /// Update customer credit limit
  /// Moved from DatabaseHelper.updateCustomerCreditLimit()
  Future<int> updateCustomerCreditLimit(int customerId, int newLimit) async {
    final db = await _dbHelper.database;
    return await db.update(
      'customers',
      {'credit_limit': newLimit},
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  /// Update customer outstanding balance
  Future<int> updateCustomerBalance(int customerId, int balance) async {
    final db = await _dbHelper.database;
    return await db.update(
      'customers',
      {'outstanding_balance': balance},
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  /// Check if customer can make purchase (credit limit check)
  Future<Map<String, dynamic>> checkCreditLimit(
    int customerId,
    int purchaseAmount,
  ) async {
    final customer = await getCustomerById(customerId);
    
    if (customer == null) {
      return {
        'allowed': false,
        'error': 'Customer not found',
      };
    }

    final creditLimit = customer.creditLimit;
    final currentBalance = customer.outstandingBalance;
    final potentialBalance = currentBalance + purchaseAmount;

    if (potentialBalance > creditLimit) {
      return {
        'allowed': false,
        'creditLimit': creditLimit,
        'currentBalance': currentBalance,
        'purchaseAmount': purchaseAmount,
        'potentialBalance': potentialBalance,
        'excess': potentialBalance - creditLimit,
      };
    }

    return {
      'allowed': true,
      'creditLimit': creditLimit,
      'currentBalance': currentBalance,
      'purchaseAmount': purchaseAmount,
      'potentialBalance': potentialBalance,
      'remaining': creditLimit - potentialBalance,
    };
  }

  // ========================================
  // PAYMENT MANAGEMENT
  // ========================================

  /// Add payment and update customer balance
  /// Moved from DatabaseHelper.addPayment()
  Future<int> addPayment(
    int customerId,
    int amount,
    String date,
    String notes,
  ) async {
    final db = await _dbHelper.database;
    
    return await db.transaction((txn) async {
      // Record the payment
      int id = await txn.insert('payments', {
        'customer_id': customerId,
        'amount': amount,
        'date': date,
        'notes': notes
      });

      // Update Customer Balance (Decrease balance by paid amount)
      await txn.rawUpdate(
        'UPDATE customers SET outstanding_balance = outstanding_balance - ? WHERE id = ?',
        [amount, customerId]
      );
      
      // Record in cash ledger as an 'IN' entry
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final timeStr = DateFormat('hh:mm a').format(DateTime.now());
      
      final res = await txn.rawQuery(
        'SELECT balance_after FROM cash_ledger ORDER BY id DESC LIMIT 1'
      );
      int currentBalance = res.isNotEmpty 
          ? (res.first['balance_after'] as num).toInt() 
          : 0;

      await txn.insert('cash_ledger', {
        'transaction_date': dateStr,
        'transaction_time': timeStr,
        'description': 'Payment from Customer (ID: $customerId)',
        'type': 'IN',
        'amount': amount,
        'balance_after': currentBalance + amount,
        'remarks': notes,
      });

      return id;
    });
  }

  /// Get all payments for a customer
  Future<List<Map<String, dynamic>>> getCustomerPayments(int customerId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'payments',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
  }

  /// Get payments by date range
  Future<List<Map<String, dynamic>>> getPaymentsByDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT 
        p.*,
        c.name_english,
        c.name_urdu,
        c.contact_primary
      FROM payments p
      JOIN customers c ON p.customer_id = c.id
      WHERE p.date BETWEEN ? AND ?
      ORDER BY p.date DESC
    ''', [startDate, endDate]);
  }

  // ========================================
  // CUSTOMER LEDGER
  // ========================================

  /// Get customer ledger (simple view)
  /// Moved from DatabaseHelper.getCustomerLedger()
  Future<List<Map<String, dynamic>>> getCustomerLedger(int customerId) async {
    final db = await _dbHelper.database;

    // Fetch Sales (Debits)
    final salesResult = await db.rawQuery('''
      SELECT 
        'SALE' as type,
        s.sale_date as date,
        s.bill_number as ref_no,
        si.product_id as prod_id,
        p.name_english || ' (' || si.quantity_sold || ' x ' || si.unit_price || ')' as description,
        si.quantity_sold as qty,
        si.unit_price as rate,
        si.total_price as debit,
        0 as credit
      FROM sales s
      JOIN sale_items si ON s.id = si.sale_id
      JOIN products p ON si.product_id = p.id
      WHERE s.customer_id = ? AND s.status = 'COMPLETED'
    ''', [customerId]);

    // Fetch Payments (Credits)
    final paymentsResult = await db.rawQuery('''
      SELECT 
        'PAYMENT' as type,
        date as date,
        id as ref_no,
        notes as description,
        0 as qty,
        0 as rate,
        0 as debit,
        amount as credit
      FROM payments
      WHERE customer_id = ?
    ''', [customerId]);

    // Combine and Sort by Date (Descending)
    List<Map<String, dynamic>> ledger = [...salesResult, ...paymentsResult];
    ledger.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));

    return ledger;
  }

  /// Get customer ledger (grouped by bills with items)
  /// Moved from DatabaseHelper.getCustomerLedgerGrouped()
  Future<List<Map<String, dynamic>>> getCustomerLedgerGrouped(
    int customerId
  ) async {
    final db = await _dbHelper.database;

    // 1. Fetch Sales (Bills) - The Parent Rows
    final sales = await db.rawQuery('''
      SELECT 
        'BILL' as type,
        id as ref_id,
        sale_date as date,
        bill_number as bill_no,
        grand_total as dr,
        0 as cr,
        '' as desc
      FROM sales 
      WHERE customer_id = ? AND status = 'COMPLETED'
    ''', [customerId]);

    // 2. Fetch Items - The Child Rows
    final saleItems = await db.rawQuery('''
      SELECT 
        si.sale_id,
        p.name_english || ' (' || p.name_urdu || ')' as name,
        si.quantity_sold as qty,
        si.unit_price as rate,
        si.total_price as total
      FROM sale_items si
      JOIN sales s ON si.sale_id = s.id
      JOIN products p ON si.product_id = p.id
      WHERE s.customer_id = ? AND s.status = 'COMPLETED'
    ''', [customerId]);

    // 3. Fetch Payments
    final payments = await db.rawQuery('''
      SELECT 
        'PAYMENT' as type,
        id as ref_id,
        date as date,
        'Payment Received' as bill_no,
        0 as dr,
        amount as cr,
        notes as desc
      FROM payments
      WHERE customer_id = ?
    ''', [customerId]);

    // 4. Organize Items by Sale ID
    Map<int, List<Map<String, dynamic>>> itemsMap = {};
    for (var item in saleItems) {
      int saleId = item['sale_id'] as int;
      if (!itemsMap.containsKey(saleId)) itemsMap[saleId] = [];
      itemsMap[saleId]!.add(item);
    }

    // 5. Merge Sales & Payments into one Timeline
    List<Map<String, dynamic>> timeline = [];

    for (var sale in sales) {
      int saleId = sale['ref_id'] as int;
      Map<String, dynamic> row = Map.from(sale);
      row['items'] = itemsMap[saleId] ?? [];
      timeline.add(row);
    }

    for (var pay in payments) {
      timeline.add(pay);
    }

    // 6. Sort by Date (OLDEST First) to calculate Running Balance
    timeline.sort((a, b) {
      DateTime dA = DateTime.tryParse(a['date'].toString()) ?? DateTime(1900);
      DateTime dB = DateTime.tryParse(b['date'].toString()) ?? DateTime(1900);
      return dA.compareTo(dB);
    });

    // 7. Calculate Running Balance
    int runningBal = 0;
    List<Map<String, dynamic>> finalLedger = [];

    for (var row in timeline) {
      int dr = (row['dr'] as num).toInt();
      int cr = (row['cr'] as num).toInt();
      runningBal += (dr - cr);

      Map<String, dynamic> newRow = Map.from(row);
      newRow['balance'] = runningBal;
      finalLedger.add(newRow);
    }

    // 8. Return Reversed (Newest First) for Display
    return finalLedger.reversed.toList();
  }

  /// Get customer summary (total sales, payments, balance)
  Future<Map<String, dynamic>> getCustomerSummary(int customerId) async {
    final db = await _dbHelper.database;

    // Get customer info
    final customer = await getCustomerById(customerId);
    if (customer == null) {
      return {
        'error': 'Customer not found',
      };
    }

    // Get total sales
    final salesResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as sale_count,
        SUM(grand_total) as total_sales,
        SUM(credit_amount) as total_credit
      FROM sales
      WHERE customer_id = ? AND status = 'COMPLETED'
    ''', [customerId]);

    // Get total payments
    final paymentsResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as payment_count,
        SUM(amount) as total_payments
      FROM payments
      WHERE customer_id = ?
    ''', [customerId]);

    final sales = salesResult.first;
    final payments = paymentsResult.first;

    return {
      'customer': customer,
      'saleCount': sales['sale_count'] ?? 0,
      'totalSales': (sales['total_sales'] as num?)?.toInt() ?? 0,
      'totalCredit': (sales['total_credit'] as num?)?.toInt() ?? 0,
      'paymentCount': payments['payment_count'] ?? 0,
      'totalPayments': (payments['total_payments'] as num?)?.toInt() ?? 0,
      'currentBalance': customer.outstandingBalance,
      'creditLimit': customer.creditLimit,
    };
  }

  // ========================================
  // DASHBOARD QUERIES
  // ========================================

  /// Get today's top customers
  /// Moved from DatabaseHelper.getTodayCustomers()
  Future<List<Map<String, dynamic>>> getTodayCustomers() async {
    try {
      final db = await _dbHelper.database;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      return await db.rawQuery('''
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
    } catch (e) {
      AppLogger.error("Error fetching today's customers: $e", tag: 'CustomerRepo');
      return [];
    }
  }

  /// Get customers with outstanding balance
  Future<List<Map<String, dynamic>>> getCustomersWithBalance() async {
    final db = await _dbHelper.database;
    return await db.query(
      'customers',
      where: 'outstanding_balance > 0',
      orderBy: 'outstanding_balance DESC',
    );
  }

  /// Get customers near credit limit
  Future<List<Map<String, dynamic>>> getCustomersNearLimit({
    double threshold = 0.8,
  }) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT 
        *,
        (outstanding_balance * 1.0 / credit_limit) as usage_ratio
      FROM customers
      WHERE credit_limit > 0 
      AND outstanding_balance > 0
      AND (outstanding_balance * 1.0 / credit_limit) >= ?
      ORDER BY usage_ratio DESC
    ''', [threshold]);
  }

  // ========================================
  // STATISTICS
  // ========================================

  /// Get total customer count
  Future<int> getTotalCustomerCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get active customer count (with recent purchases)
  Future<int> getActiveCustomerCount({int daysBack = 30}) async {
    final db = await _dbHelper.database;
    final date = DateTime.now().subtract(Duration(days: daysBack));
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT customer_id) as count
      FROM sales
      WHERE sale_date >= ? AND status = 'COMPLETED'
    ''', [dateStr]);
    
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get total outstanding balance across all customers
  Future<int> getTotalOutstandingBalance() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(outstanding_balance) as total FROM customers'
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  /// Get customer statistics for the dashboard
  Future<Map<String, dynamic>> getCustomerStats() async {
    final db = await _dbHelper.database;

    final activeRes = await db.rawQuery('SELECT COUNT(*) as count, SUM(outstanding_balance) as total FROM customers WHERE is_active = 1');
    final countActive = (activeRes.first['count'] as int?) ?? 0;
    final balActive = (activeRes.first['total'] as num? ?? 0).toInt();

    final archRes = await db.rawQuery('SELECT COUNT(*) as count, SUM(outstanding_balance) as total FROM customers WHERE is_active = 0');
    final countArchived = (archRes.first['count'] as int?) ?? 0;
    final balArchived = (archRes.first['total'] as num? ?? 0).toInt();

    return {
      'countTotal': countActive + countArchived,
      'balTotal': balActive + balArchived,
      'countActive': countActive,
      'balActive': balActive,
      'countArchived': countArchived,
      'balArchived': balArchived,
    };
  }
}