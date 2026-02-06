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
  Future<List<Customer>> getAllCustomers({int limit = 50, int offset = 0}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'customers', 
      orderBy: 'name_english ASC',
      limit: limit,
      offset: offset,
    );
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
  Future<List<Customer>> searchCustomers(String query, {bool activeOnly = false, int limit = 50}) async {
    final db = await _dbHelper.database;
    final q = '%${query.toLowerCase()}%';
    
    String whereClause = '(LOWER(name_english) LIKE ? OR LOWER(name_urdu) LIKE ? OR contact_primary LIKE ?)';
    List<dynamic> args = [q, q, '%$query%'];

    if (activeOnly) {
      whereClause += ' AND is_active = 1';
    }

    final result = await db.query(
      'customers',
      where: whereClause,
      whereArgs: args,
      orderBy: 'name_english ASC',
      limit: limit,
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

  /// Returns true if a customer with the exact phone number exists.
  Future<bool> customerExistsByPhone(String phone) async {
    final db = await _dbHelper.database;
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) return false;

    final result = await db.query(
      'customers',
      columns: ['id'],
      where: 'contact_primary = ?',
      whereArgs: [normalizedPhone],
      limit: 1,
    );
    return result.isNotEmpty;
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
    {String paymentMode = 'CASH'}
  ) async {
    if (amount <= 0) {
      throw ArgumentError('Payment amount must be greater than zero');
    }

    final db = await _dbHelper.database;
    
    try {
      return await db.transaction((txn) async {
        // 1. Record the Receipt (Financial Event)
        final receiptNumber = 'RCP-${DateTime.now().millisecondsSinceEpoch}';
        int receiptId = await txn.insert('receipts', {
          'receipt_number': receiptNumber,
          'customer_id': customerId,
          'amount': amount,
          'receipt_date': date,
          'notes': notes,
          'payment_mode': paymentMode
        });

        // 2. Insert into Ledger
        // Get current balance first (to ensure running balance integrity, though we calculate it)
        // Actually, for running balance, we need the previous balance.
        final lastEntry = await txn.rawQuery(
          'SELECT balance FROM customer_ledger WHERE customer_id = ? ORDER BY transaction_date DESC, id DESC LIMIT 1',
          [customerId]
        );
        
        // Edge Case: Overpayment is allowed (results in negative balance)
        int previousBalance = lastEntry.isNotEmpty ? (lastEntry.first['balance'] as int) : 0;
        // Rule: balance = previous balance - credit
        int newBalance = previousBalance - amount;

        await txn.insert('customer_ledger', {
          'customer_id': customerId,
          'transaction_date': date,
          'description': 'Payment Received ($notes)',
          'ref_type': 'RECEIPT',
          'ref_id': receiptId,
          // Rule: credit = received amount
          'debit': 0,
          'credit': amount,
          'balance': newBalance,
        });

        // 3. Update Customer Cache
        await txn.rawUpdate(
          'UPDATE customers SET outstanding_balance = outstanding_balance - ? WHERE id = ?',
          [amount, customerId]
        );
        
        // 4. Record in cash ledger as an 'IN' entry (Shop Cash Flow)
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

        return receiptId;
      });
    } catch (e) {
      AppLogger.error('Error adding payment: $e', tag: 'CustomersRepo');
      throw Exception('Payment Failed: ${e.toString()}');
    }
  }

  /// Get all payments for a customer
  Future<List<Map<String, dynamic>>> getCustomerPayments(int customerId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'receipts',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'receipt_date DESC',
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
      FROM receipts p
      JOIN customers c ON p.customer_id = c.id
      WHERE p.receipt_date BETWEEN ? AND ?
      ORDER BY p.receipt_date DESC
    ''', [startDate, endDate]);
  }

  // ========================================
  // CUSTOMER LEDGER
  // ========================================

  /// Get customer ledger (simple view)
  /// Moved from DatabaseHelper.getCustomerLedger()
  Future<List<Map<String, dynamic>>> getCustomerLedger(
    int customerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;

    String whereClause = 'customer_id = ?';
    List<dynamic> args = [customerId];

    if (startDate != null) {
      whereClause += ' AND transaction_date >= ?';
      args.add(DateFormat('yyyy-MM-dd').format(startDate));
    }

    if (endDate != null) {
      whereClause += ' AND transaction_date <= ?';
      args.add('${DateFormat('yyyy-MM-dd').format(endDate)} 23:59:59');
    }

    // Query the single source of truth
    final result = await db.rawQuery('''
      SELECT 
        CASE WHEN ref_type = 'INVOICE' THEN 'SALE' ELSE 'PAYMENT' END as type,
        transaction_date as date,
        ref_id as ref_no,
        description,
        debit,
        credit,
        balance
      FROM customer_ledger
      WHERE $whereClause
      ORDER BY transaction_date DESC, id DESC
    ''', args);
    
    return result;
  }

  /// Get customer ledger (grouped by bills with items)
  /// Moved from DatabaseHelper.getCustomerLedgerGrouped()
  Future<List<Map<String, dynamic>>> getCustomerLedgerGrouped(
    int customerId, {
    DateTime? startDate,
    DateTime? endDate,
  }
  ) async {
    final db = await _dbHelper.database;

    String whereClause = 'customer_id = ?';
    List<dynamic> args = [customerId];
    
    // For items query
    String itemsWhereClause = 'i.customer_id = ?';
    List<dynamic> itemsArgs = [customerId];

    if (startDate != null) {
      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      whereClause += ' AND transaction_date >= ?';
      args.add(startStr);
      
      itemsWhereClause += ' AND i.invoice_date >= ?';
      itemsArgs.add(startStr);
    }

    if (endDate != null) {
      final endStr = '${DateFormat('yyyy-MM-dd').format(endDate)} 23:59:59';
      whereClause += ' AND transaction_date <= ?';
      args.add(endStr);
      
      itemsWhereClause += ' AND i.invoice_date <= ?';
      itemsArgs.add(endStr);
    }

    // 1. Fetch Ledger Entries
    final ledgerEntries = await db.rawQuery('''
      SELECT 
        CASE WHEN ref_type = 'INVOICE' THEN 'BILL' ELSE 'PAYMENT' END as type,
        ref_id,
        transaction_date as date,
        description as desc,
        debit as dr,
        credit as cr,
        balance
      FROM customer_ledger
      WHERE $whereClause
      ORDER BY transaction_date ASC, id ASC
    ''', args);

    if (ledgerEntries.isEmpty) return [];

    // 2. Fetch Items for Invoices (Filtered by same date range for performance)
    final invoiceItems = await db.rawQuery('''
      SELECT 
        ii.invoice_id,
        ii.item_name_snapshot as name,
        ii.quantity as qty,
        ii.unit_price as rate,
        ii.total_price as total
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      WHERE $itemsWhereClause
    ''', itemsArgs);

    // 3. Organize Items by Invoice ID
    Map<int, List<Map<String, dynamic>>> itemsMap = {};
    for (var item in invoiceItems) {
      int invId = item['invoice_id'] as int;
      if (!itemsMap.containsKey(invId)) itemsMap[invId] = [];
      itemsMap[invId]!.add(item);
    }

    // 4. Merge
    List<Map<String, dynamic>> finalLedger = [];
    for (var row in ledgerEntries) {
      Map<String, dynamic> newRow = Map.from(row);
      if (row['type'] == 'BILL') {
        newRow['bill_no'] = (row['desc'] as String).replaceAll('Invoice #', '');
        newRow['items'] = itemsMap[row['ref_id']] ?? [];
      }
      finalLedger.add(newRow);
    }

    // 5. Return Reversed (Newest First) for Display
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
        SUM(grand_total) as total_sales
      FROM invoices
      WHERE customer_id = ? AND status = 'COMPLETED'
    ''', [customerId]);

    // Get total payments
    final paymentsResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as payment_count,
        SUM(amount) as total_payments
      FROM receipts
      WHERE customer_id = ?
    ''', [customerId]);

    final sales = salesResult.first;
    final payments = paymentsResult.first;

    return {
      'customer': customer,
      'saleCount': sales['sale_count'] ?? 0,
      'totalSales': (sales['total_sales'] as num?)?.toInt() ?? 0,
      'totalCredit': 0, // Deprecated concept, use balance
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
          SUM(i.grand_total) as total_amount,
          COUNT(i.id) as sale_count
        FROM invoices i
        LEFT JOIN customers c ON i.customer_id = c.id
        WHERE i.invoice_date LIKE ? AND c.id IS NOT NULL AND i.status = 'COMPLETED'
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
      FROM invoices
      WHERE invoice_date >= ? AND status = 'COMPLETED'
    ''', [dateStr]); // Note: invoice_date is datetime string, might need substring for date comparison if not careful, but >= works for ISO8601
    
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
