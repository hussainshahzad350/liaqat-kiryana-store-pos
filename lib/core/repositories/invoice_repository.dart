import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../../models/invoice_model.dart';
import '../../models/invoice_item_model.dart';
import '../utils/logger.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class InvoiceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // INVOICE CREATION (Full Transaction)
  // ========================================

  /// Create invoice with all items, stock updates, ledger entries, and cash flow
  Future<int> createInvoiceWithTransaction({
    required int customerId,
    required List<Map<String, dynamic>> items,
    required int grandTotal,
    int discount = 0,
    String? notes,
    Map<String, dynamic>? shopProfile,
    Map<String, dynamic>? customerData,
  }) async {
    final db = await _dbHelper.database;

    // Validation
    if (items.isEmpty) {
      throw ArgumentError('Invoice must have at least one item');
    }

    final now = DateTime.now();
    final String yy = (now.year % 100).toString().padLeft(2, '0');
    final String mm = now.month.toString().padLeft(2, '0');
    final String invoiceDate = DateFormat('yyyy-MM-dd HH:mm').format(now);

    return await db.transaction<int>((txn) async {
      // 1. Validate Customer Credit Limit
      final custRes = await txn.query(
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
          throw Exception(
              'Credit limit exceeded. Current: $balance, Limit: $limit, Invoice: $grandTotal');
        }
      }

      // 2. Validate Invoice Math
      int calculatedSubTotal = 0;
      for (var item in items) {
        calculatedSubTotal += (item['total'] as int);
      }
      if ((calculatedSubTotal - discount) != grandTotal) {
        throw Exception(
            'Invoice math error: Items ($calculatedSubTotal) - Discount ($discount) != Total ($grandTotal)');
      }

      // 3. Insert Invoice with Temp Number
      final tempNumber = 'TEMP-${now.microsecondsSinceEpoch}';
      final invoiceId = await txn.insert('invoices', {
        'invoice_number': tempNumber,
        'customer_id': customerId,
        'invoice_date': invoiceDate,
        'sub_total': grandTotal + discount,
        'discount_total': discount,
        'grand_total': grandTotal,
        'status': 'COMPLETED',
        'notes': notes,
      });

      // 4. Generate Final Invoice Number (SB-YYMMXXXX)
      final sequence = invoiceId.toString().padLeft(4, '0');
      final finalNumber = 'SB-$yy$mm$sequence';

      await txn.update(
        'invoices',
        {'invoice_number': finalNumber},
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      // 5. Insert Items & Update Stock
      for (var item in items) {
        final productId = item['product_id'];
        final quantity = (item['quantity'] as num).toDouble();

        await txn.insert('invoice_items', {
          'invoice_id': invoiceId,
          'product_id': productId,
          'item_name_snapshot': item['name_english'],
          'quantity': quantity,
          'unit_price': item['unit_price'],
          'total_price': item['total'],
        });

        // Atomic Stock Update
        int updated = await txn.rawUpdate(
          'UPDATE products SET current_stock = current_stock - ? WHERE id = ? AND current_stock >= ?',
          [quantity, productId, quantity],
        );

        if (updated == 0) {
          throw Exception('Insufficient stock for product ID: $productId');
        }
      }

      // 6. Update Customer Ledger
      final lastEntry = await txn.rawQuery(
        'SELECT balance FROM customer_ledger WHERE customer_id = ? ORDER BY transaction_date DESC, id DESC LIMIT 1',
        [customerId],
      );
      int prevBalance =
          lastEntry.isNotEmpty ? (lastEntry.first['balance'] as int) : 0;
      int newBalance = prevBalance + grandTotal;

      await txn.insert('customer_ledger', {
        'customer_id': customerId,
        'transaction_date': invoiceDate,
        'description': 'Invoice #$finalNumber',
        'ref_type': 'INVOICE',
        'ref_id': invoiceId,
        'debit': grandTotal,
        'credit': 0,
        'balance': newBalance,
      });

      // 7. Update Customer Balance Cache
      await txn.update(
        'customers',
        {'outstanding_balance': newBalance},
        where: 'id = ?',
        whereArgs: [customerId],
      );

      // 8. Store Invoice Snapshot (for printing)
      if (shopProfile != null && customerData != null) {
        final snapshot = {
          'shop': shopProfile,
          'invoice': {
            'number': finalNumber,
            'date': DateFormat('yyyy-MM-dd').format(now),
            'time': DateFormat('hh:mm a').format(now),
          },
          'customer': customerData,
          'items': items.map((item) => {
            'name_en': item['name_english'],
            'name_ur': item['name_urdu'],
            'qty': item['quantity'],
            'price': item['unit_price'],
            'total': item['total'],
          }).toList(),
          'totals': {
            'sub_total': grandTotal + discount,
            'discount': discount,
            'grand_total': grandTotal,
          },
        };

        Map<String, dynamic> notesMap = {};
        if (notes != null && notes.isNotEmpty) {
          try {
            notesMap = jsonDecode(notes);
          } catch (e) {
            // It's not a valid JSON, so treat it as a plain string
            notesMap['payment_details'] = notes;
          }
        }
        notesMap['snapshot'] = snapshot;

        await txn.update(
          'invoices',
          {'notes': jsonEncode(notesMap)},
          where: 'id = ?',
          whereArgs: [invoiceId],
        );
      }

      AppLogger.info('Invoice created: $finalNumber (ID: $invoiceId)',
          tag: 'InvoiceRepo');
      return invoiceId;
    });
  }

  // ========================================
  // INVOICE CANCELLATION
  // ========================================

  /// Cancel invoice and revert all changes (stock, ledger, balance)
  Future<void> cancelInvoice({
    required int invoiceId,
    required String cancelledBy,
    String? reason,
  }) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // 1. Fetch Invoice
      final invoiceRes = await txn.query(
        'invoices',
        where: 'id = ? AND status = ?',
        whereArgs: [invoiceId, 'COMPLETED'],
        limit: 1,
      );

      if (invoiceRes.isEmpty) {
        throw Exception('Invoice not found or already cancelled');
      }

      final invoice = invoiceRes.first;
      final grandTotal = (invoice['grand_total'] as num).toInt();
      final customerId = invoice['customer_id'] as int;
      final invoiceNumber = invoice['invoice_number'] as String;

      // 2. Mark as CANCELLED
      await txn.update(
        'invoices',
        {
          'status': 'CANCELLED',
          'notes': '${invoice['notes'] ?? ''}\n[Cancelled by $cancelledBy: ${reason ?? 'No reason'}]',
        },
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      // 3. Revert Stock
      final items = await txn.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );

      for (var item in items) {
        await txn.rawUpdate(
          'UPDATE products SET current_stock = current_stock + ? WHERE id = ?',
          [(item['quantity'] as num).toDouble(), item['product_id']],
        );
      }

      // 4. Reverse Customer Ledger
      final lastEntry = await txn.rawQuery(
        'SELECT balance FROM customer_ledger WHERE customer_id = ? ORDER BY transaction_date DESC, id DESC LIMIT 1',
        [customerId],
      );
      int prevBalance =
          lastEntry.isNotEmpty ? (lastEntry.first['balance'] as int) : 0;
      int newBalance = prevBalance - grandTotal;
      if (newBalance < 0) newBalance = 0;

      await txn.insert('customer_ledger', {
        'customer_id': customerId,
        'transaction_date': DateTime.now().toIso8601String(),
        'description': 'Invoice Cancelled: #$invoiceNumber',
        'ref_type': 'ADJUSTMENT',
        'ref_id': invoiceId,
        'debit': 0,
        'credit': grandTotal,
        'balance': newBalance,
      });

      // 5. Update Customer Balance
      await txn.update(
        'customers',
        {'outstanding_balance': newBalance},
        where: 'id = ?',
        whereArgs: [customerId],
      );

      AppLogger.info('Invoice cancelled: #$invoiceNumber', tag: 'InvoiceRepo');
    });
  }

  // ========================================
  // INVOICE QUERIES
  // ========================================

  /// Get invoice with items by ID
  Future<Invoice?> getInvoiceWithItems(int invoiceId) async {
    final db = await _dbHelper.database;
    final invoiceMap = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );

    if (invoiceMap.isEmpty) return null;

    final itemsMap = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );

    final items = itemsMap.map((e) => InvoiceItem.fromMap(e)).toList();
    final invoice = Invoice.fromMap(invoiceMap.first);

    return Invoice(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      customerId: invoice.customerId,
      date: invoice.date,
      totalAmount: invoice.totalAmount,
      discount: invoice.discount,
      status: invoice.status,
      notes: invoice.notes,
      items: items,
    );
  }

  /// Get recent invoices
  Future<List<Invoice>> getRecentInvoices({int limit = 20}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'invoices',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return result.map((map) => Invoice.fromMap(map)).toList();
  }

  /// Get invoices by date range
  Future<List<Invoice>> getInvoicesByDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'invoices',
      where: 'invoice_date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'invoice_date DESC',
    );
    return result.map((map) => Invoice.fromMap(map)).toList();
  }

  /// Get invoices by customer
  Future<List<Invoice>> getInvoicesByCustomer(int customerId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'invoices',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'invoice_date DESC',
    );
    return result.map((map) => Invoice.fromMap(map)).toList();
  }

  /// Get recent invoices with customer names.
  Future<List<Invoice>> getRecentInvoicesWithCustomer({int limit = 20}) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT
        i.*,
        c.name_english as customer_name
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      ORDER BY i.created_at DESC
      LIMIT ?
    ''', [limit]);

    return result.map((map) {
      final invoice = Invoice.fromMap(map);
      return invoice.copyWith(customerName: map['customer_name'] as String?);
    }).toList();
  }

  /// Get today's sales total
  Future<int> getTodaySalesTotal() async {
    final db = await _dbHelper.database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final result = await db.rawQuery(
      'SELECT SUM(grand_total) as total FROM invoices WHERE DATE(invoice_date) = ? AND status = ?',
      [today, 'COMPLETED'],
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  /// Delete invoice (and items)
  Future<void> deleteInvoice(int invoiceId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('invoice_items',
          where: 'invoice_id = ?', whereArgs: [invoiceId]);
      await txn.delete('invoices', where: 'id = ?', whereArgs: [invoiceId]);
    });
  }

  /// Update invoice (without items)
  Future<void> updateInvoice(Invoice invoice) async {
    final db = await _dbHelper.database;
    await db.update(
      'invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  }

  /// Validate stock before creating invoice
  Future<Map<String, dynamic>> validateStock(
      List<Map<String, dynamic>> items) async {
    final db = await _dbHelper.database;

    for (var item in items) {
      final productId = item['product_id'];
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
