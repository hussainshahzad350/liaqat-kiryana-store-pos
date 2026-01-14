// lib/core/repositories/invoices_repository.dart
import '../database/database_helper.dart';
import '../../models/invoice_model.dart';
import 'package:intl/intl.dart';
import '../utils/logger.dart';
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class InvoicesRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // INVOICE CREATION & PROCESSING
  // ========================================

  /// Create a new invoice with full transaction safety
  /// Moved from DatabaseHelper.createInvoice()
  Future<int> createInvoice(Map<String, dynamic> invoiceData, {Transaction? txn}) async {
    final db = await _dbHelper.database;
    
    // Validation
    void validatePaisa(String key, {bool required = false}) {
      final val = invoiceData[key];
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
    int grandTotal = invoiceData['grand_total_paisas'] as int;
    int discount = (invoiceData['discount_paisas'] as int?) ?? 0;
    int cash = (invoiceData['cash_paisas'] as int?) ?? 0;
    int bank = (invoiceData['bank_paisas'] as int?) ?? 0;
    
    int totalPaid = cash + bank;
    int remainingBalance = grandTotal - totalPaid;

    if (remainingBalance < 0) remainingBalance = 0;

    // Prepare Date Components for Bill Number
    final now = DateTime.now();
    final String yy = (now.year % 100).toString();
    final String mm = now.month.toString().padLeft(2, '0');

    final String invoiceDate = DateFormat('yyyy-MM-dd').format(now);
    final String invoiceTime = DateFormat('HH:mm').format(now);

    Future<int> performCreate(Transaction t) async {
        // 1. Validate Customer Credit Limit
        final int? customerId = invoiceData['customer_id'];
        if (customerId != null) {
          final custRes = await t.query(
            'customers',
            columns: ['credit_limit', 'outstanding_balance'],
            where: 'id = ?',
            whereArgs: [customerId],
            limit: 1,
          );

          if (custRes.isNotEmpty) {
            final limit = (custRes.first['credit_limit'] as num).toInt();
            final balance = (custRes.first['outstanding_balance'] as num).toInt();
            if (limit > 0 && (balance + grandTotal) > limit) {
              throw Exception('Credit limit exceeded. Current: $balance, Limit: $limit, Bill: $grandTotal');
            }
          }
        }

        // 2. Validate Invoice Total (Integrity Check)
        final validationItems = invoiceData['items'] as List;
        int calculatedSubTotal = 0;
        for (var item in validationItems) {
          calculatedSubTotal += (item['total'] as int);
        }
        if ((calculatedSubTotal - discount) != grandTotal) {
          throw Exception('Invoice integrity check failed: Items total ($calculatedSubTotal) - Discount ($discount) != Grand Total ($grandTotal)');
        }

        // Step A: Insert with Temporary Bill Number
        final tempBillNo = 'TEMP-${now.microsecondsSinceEpoch}';
        
        // Map to new 'invoices' schema
        final invoiceId = await t.insert('invoices', {
          'invoice_number': tempBillNo, 
          'customer_id': invoiceData['customer_id'],
          'invoice_date': '$invoiceDate $invoiceTime',
          'sub_total': grandTotal + discount, // Reconstruct subtotal
          'grand_total': grandTotal,
          'discount_total': discount,
          'status': 'COMPLETED',
        });

        // Step B: Generate Final Atomic Bill Number (SB-YYMMXXXXXX)
        final String sequence = invoiceId.toString().padLeft(4, '0');
        final String finalBillNumber = 'SB-$yy$mm$sequence';

        // Step C: Update the Invoice Record with Final Bill Number
        await t.rawUpdate(
          'UPDATE invoices SET invoice_number = ? WHERE id = ?',
          [finalBillNumber, invoiceId]
        );

        // Step D: Insert Items & Handle Stock (Atomic)
        final items = invoiceData['items'] as List<Map<String, dynamic>>;
        for (var item in items) {
          if (item['sale_price'] is! int) throw ArgumentError('Item sale_price must be int paisas');
          if (item['total'] is! int) throw ArgumentError('Item total must be int paisas');

          final productId = item['id'];
          final quantity = (item['quantity'] as num).toDouble();

          await t.insert('invoice_items', {
            'invoice_id': invoiceId,
            'product_id': productId,
            'quantity': quantity,
            'unit_price': item['sale_price'],
            'total_price': item['total'],
            'item_name_snapshot': item['name_english'], // Storing English name as snapshot
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

        // Step E: Update Customer Ledger (The Single Source of Truth)
        if (invoiceData['customer_id'] != null) {
           final customerId = invoiceData['customer_id'];
           
           // 1. Debit the Invoice Amount
           // Get previous balance
           final lastEntry = await t.rawQuery(
             'SELECT balance FROM customer_ledger WHERE customer_id = ? ORDER BY transaction_date DESC, id DESC LIMIT 1',
             [customerId]
           );
           int prevBal = lastEntry.isNotEmpty ? (lastEntry.first['balance'] as int) : 0;
           int newBal = prevBal + grandTotal;

           await t.insert('customer_ledger', {
             'customer_id': customerId,
             'transaction_date': '$invoiceDate $invoiceTime',
             'description': 'Invoice #$finalBillNumber',
             'ref_type': 'INVOICE',
             'ref_id': invoiceId,
             'debit': grandTotal,
             'credit': 0,
             'balance': newBal
           });

           // 2. Update Customer Cache
           await t.rawUpdate(
             'UPDATE customers SET outstanding_balance = ? WHERE id = ?',
             [newBal, customerId]
           );
        }
        return invoiceId;
    }

    try {
      int resultId;
      if (txn != null) {
        resultId = await performCreate(txn);
      } else {
        resultId = await db.transaction((t) => performCreate(t));
      }
      AppLogger.info('Invoice created successfully', tag: 'InvoicesRepo');
      return resultId;
    } catch (e) {
      AppLogger.error('Error creating invoice: $e', tag: 'InvoicesRepo');
      throw Exception('Transaction Failed: ${e.toString()}');
    }
  }

  /// Complete a invoice and store its snapshot
  Future<int> completeInvoiceWithSnapshot(Map<String, dynamic> invoiceData) async {
    final db = await _dbHelper.database;

    // 1. Fetch Shop Profile
    final shopProfile = await db.query('shop_profile', limit: 1);
    final shop = shopProfile.isNotEmpty ? shopProfile.first : {};

    // 2. Fetch Customer (if exists)
    Map<String, dynamic>? customer;
    if (invoiceData['customer_id'] != null) {
      final cResult = await db.query('customers', where: 'id = ?', whereArgs: [invoiceData['customer_id']], limit: 1);
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
      'invoice': {
        'date': DateFormat('yyyy-MM-dd').format(now),
        'time': DateFormat('hh:mm a').format(now),
        // bill_number is generated during createInvoice, so it's omitted here or can be patched later
      },
      'customer': customer != null ? {
        'name': customer['name_english'],
        'contact': customer['contact_primary'],
        'address': customer['address'],
      } : null,
      'items': (invoiceData['items'] as List).map((item) => {
        'name_en': item['name_english'],
        'name_ur': item['name_urdu'],
        'qty': item['quantity'],
        'price': item['sale_price'],
        'total': item['total'],
      }).toList(),
      'totals': {
        'grand_total': invoiceData['grand_total_paisas'],
        'discount': invoiceData['discount_paisas'] ?? 0,
        'cash_received': invoiceData['cash_paisas'],
      },
      'currency': 'PKR',
      'direction': 'RTL',
      'language': invoiceData['receipt_language'] ?? 'ur'
    };
    
    invoiceData['invoice_snapshot'] = jsonEncode(snapshotMap);
    return await createInvoice(invoiceData);
  }

  /// Edit an existing invoice (Void old -> Create new)
  Future<void> editInvoice(int oldInvoiceId, Map<String, dynamic> newInvoiceData) async {
    final db = await _dbHelper.database;
    
    try {
      await db.transaction((txn) async {
        // 1. Cancel the old invoice
        await cancelInvoice(
          invoiceId: oldInvoiceId,
          cancelledBy: 'System (Edit)', 
          reason: 'Edited Invoice',
          txn: txn
        );

        // 2. Link new invoice to old one
        newInvoiceData['original_invoice_id'] = oldInvoiceId;
        newInvoiceData['invoice_status'] = 'EDITED_VERSION';
        
        // 3. Create new invoice
        await createInvoice(newInvoiceData, txn: txn);
      });
      AppLogger.info('Invoice edited successfully (ID: $oldInvoiceId)', tag: 'InvoicesRepo');
    } catch (e) {
      AppLogger.error('Error editing invoice: $e', tag: 'InvoicesRepo');
      throw Exception('Edit Failed: ${e.toString()}');
    }
  }

  // ========================================
  // INVOICE CANCELLATION
  // ========================================

  /// Cancel a invoice and revert all changes
  /// Moved from DatabaseHelper.cancelInvoice()
  Future<void> cancelInvoice({
    required int invoiceId,
    required String cancelledBy,
    String? reason,
    Transaction? txn,
  }) async {
    final db = await _dbHelper.database;
    
    Future<void> performCancel(Transaction t) async {
      // 1. Fetch invoice (validate)
      final invoiceRes = await t.query(
        'invoices',
        where: 'id = ? AND status = ?',
        whereArgs: [invoiceId, 'COMPLETED'],
        limit: 1,
      );

      if (invoiceRes.isEmpty) {
        throw Exception('Invoice not found or already cancelled');
      }
      final invoice = invoiceRes.first;
      final int cashAmount = (invoice['cash_amount'] as num).toInt();
      final int creditAmount = (invoice['credit_amount'] as num).toInt();
      final int? customerId = invoice['customer_id'] as int?;

      // 2. Mark invoice as CANCELLED
      await t.update(
        'invoices',
        {
          'status': 'CANCELLED',
          'cancelled_at': DateTime.now().toIso8601String(),
          'cancelled_by': cancelledBy,
          'cancel_reason': reason,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      // 3. Revert stock
      final items = await t.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
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
          'description': 'Invoice Cancelled (Bill #${invoice['bill_number']})',
          'type': 'OUT',
          'amount': cashAmount,
          'balance_after': newBalance,
          'remarks': reason ?? 'Invoice cancellation',
        });
      }
    }

    try {
      if (txn != null) {
        await performCancel(txn);
      } else {
        await db.transaction((t) => performCancel(t));
      }
      AppLogger.info('Invoice cancelled successfully (ID: $invoiceId)', tag: 'InvoicesRepo');
    } catch (e) {
      AppLogger.error('Error cancelling invoice: $e', tag: 'InvoicesRepo');
      throw Exception('Cancellation Failed: ${e.toString()}');
    }
  }

  // ========================================
  // INVOICE QUERIES
  // ========================================

  /// Fetch recent invoices with customer info
  Future<List<Invoice>> getRecentInvoices({int limit = 20}) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        i.id, 
        i.invoice_number as bill_number, 
        SUBSTR(i.invoice_date, 1, 10) as invoice_date,
        SUBSTR(i.invoice_date, 12, 5) as invoice_time,
        i.grand_total, 
        0 as cash_amount, -- Not stored in invoice anymore
        0 as bank_amount, 
        0 as credit_amount,
        i.status,
        COALESCE(c.name_english, 'Walk-in Customer') as customer_name
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      ORDER BY i.created_at DESC
      LIMIT ?
    ''', [limit]);
    return result.map((map) => Invoice.fromMap(map)).toList();
  }

  /// Get today's invoices total
  /// Moved from DatabaseHelper.getTodayInvoices()
  Future<int> getTodayInvoices() async {
    try {
      final db = await _dbHelper.database;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final result = await db.rawQuery(
        'SELECT SUM(grand_total) as total FROM invoices WHERE invoice_date LIKE ? AND status = ?',
        ['$today%', 'COMPLETED']
      );
      return (result.first['total'] as num?)?.toInt() ?? 0;
    } catch (e) {
      AppLogger.error("Error fetching today's invoices: $e", tag: 'InvoicesRepo');
      return 0;
    }
  }

  /// Get invoice by ID with all details
  Future<Invoice?> getInvoiceById(int invoiceId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'invoices',
      columns: [
        'id', 
        'invoice_number as bill_number', 
        'customer_id',
        'grand_total',
        'discount_total as discount',
        'invoice_date as invoice_date', // Map to model
        'status'
        // Missing cash/bank/credit breakdown in new schema, model might need update or we return 0
      ],
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return Invoice.fromMap(result.first);
  }

  /// Get invoice items for a specific invoice
  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        ii.id,
        ii.invoice_id as invoice_id,
        ii.product_id as itemId,
        COALESCE(p.name_english, p.name_urdu) as name,
        ii.quantity as quantity,
        ii.unit_price as price,
        ii.total_price as total
      FROM invoice_items ii
      JOIN products p ON ii.product_id = p.id
      WHERE ii.invoice_id = ?
      ORDER BY ii.id
    ''', [invoiceId]);
    return result.map((map) => InvoiceItem.fromMap(map)).toList();
  }

  /// Get the JSON snapshot of a invoice
  Future<Map<String, dynamic>?> getInvoiceSnapshot(int invoiceId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'invoices',
      columns: ['invoice_snapshot'],
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );

    if (result.isNotEmpty && result.first['invoice_snapshot'] != null) {
      return jsonDecode(result.first['invoice_snapshot'] as String);
    }
    return null;
  }

  /// Increment the print count for a invoice
  Future<void> incrementPrintCount(int invoiceId) async {
    await _dbHelper.database;
    // await db.rawUpdate('UPDATE invoices SET printed_count = printed_count + 1 WHERE id = ?', [invoiceId]);
  }

  /// Get invoices by date range
  Future<List<Invoice>> getInvoicesByDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        i.id, i.invoice_number as bill_number, i.grand_total, i.invoice_date as invoice_date, i.status,
        COALESCE(c.name_english, 'Walk-in Customer') as customer_name
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      WHERE i.invoice_date BETWEEN ? AND ?
      AND i.status = 'COMPLETED'
      ORDER BY i.invoice_date DESC
    ''', [startDate, endDate]);
    return result.map((map) => Invoice.fromMap(map)).toList();
  }

  /// Get invoices by customer
  Future<List<Invoice>> getInvoicesByCustomer(int customerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        i.id, i.invoice_number as bill_number, i.grand_total, i.invoice_date as invoice_date, i.status,
        c.name_english as customer_name
      FROM invoices i
      JOIN customers c ON i.customer_id = c.id
      WHERE i.customer_id = ?
      AND i.status = 'COMPLETED'
      ORDER BY i.invoice_date DESC
    ''', [customerId]);
    return result.map((map) => Invoice.fromMap(map)).toList();
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

    // 1. Today's Invoices Total
    batch.rawQuery(
      'SELECT SUM(grand_total) as total FROM invoices WHERE invoice_date LIKE ? AND status = ?',
      ['$today%', 'COMPLETED']
    );

    // 2. Today's Top Customers
    batch.rawQuery('''
      SELECT 
        c.name_urdu, 
        c.name_english, 
        SUM(i.grand_total) as total_amount,
        COUNT(i.id) as invoice_count
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      WHERE i.invoice_date LIKE ? AND c.id IS NOT NULL AND i.status = 'COMPLETED'
      GROUP BY c.id
      ORDER BY total_amount DESC
      LIMIT 5
    ''', ['$today%']);

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

    // 4. Recent Invoices
    batch.rawQuery('''
      SELECT 
        i.id,
        i.invoice_number as bill_number,
        i.status, 
        i.grand_total, 
        SUBSTR(i.invoice_date, 12, 5) as invoice_time,
        COALESCE(c.name_urdu, c.name_english, 'Walk-in Customer') as customer_name
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      ORDER BY i.created_at DESC
      LIMIT 5
    ''');

    final results = await batch.commit();

    return {
      'todayInvoices': (results[0] as List).isNotEmpty
          ? ((results[0] as List).first['total'] as num?)?.toInt() ?? 0
          : 0,
      'todayCustomers': (results[1] as List).map((e) => e as Map<String, dynamic>).toList(),
      'lowStockItems': (results[2] as List).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        // Ensure sale_price is int (paisas)
        map['sale_price'] = (map['sale_price'] as num?)?.toInt() ?? 0;
        return map;
      }).toList(),
      'recentInvoices': (results[3] as List).map((e) {
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
      // 1. Recent Invoices (today)
      final invoices = await db.rawQuery('''
        SELECT 
          'INVOICE' as activity_type,
          i.invoice_number as title,
          COALESCE(c.name_english, c.name_urdu, 'Cash Invoice') as customer_name,
          i.grand_total as amount,
          i.invoice_date as timestamp,
          i.status as status
        FROM invoices i
        LEFT JOIN customers c ON i.customer_id = c.id
        WHERE DATE(i.invoice_date) = DATE('now', 'localtime')
        ORDER BY i.invoice_date DESC
        LIMIT 5
      ''');
      
      // 2. Recent Payments (today)
      final payments = await db.rawQuery('''
        SELECT 
          'PAYMENT' as activity_type,
          COALESCE(c.name_english, c.name_urdu, 'Unknown') as title,
          c.name_urdu as customer_name_urdu,
          p.amount as amount,
          p.receipt_date as timestamp,
          'COMPLETED' as status
        FROM receipts p
        JOIN customers c ON p.customer_id = c.id
        WHERE DATE(p.receipt_date) = DATE('now', 'localtime')
        ORDER BY p.receipt_date DESC
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
      activities.addAll(invoices.map((e) {
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
      AppLogger.error('Error getting recent activities: $e', tag: 'InvoicesRepo');
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

  /// Validate stock before invoice
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