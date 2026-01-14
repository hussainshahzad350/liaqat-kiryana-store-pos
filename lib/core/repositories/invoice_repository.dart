// lib/core/repositories/invoice_repository.dart
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/database_helper.dart';
import '../../models/invoice_model.dart';
import '../utils/logger.dart';

class InvoiceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createInvoice(Invoice invoice, {Transaction? txn}) async {
    final db = await _dbHelper.database;

    Future<int> performCreate(Transaction t) async {
      // 1. Validate Customer Credit Limit if applicable
      if (invoice.customerId != null) {
        final custRes = await t.query(
          'customers',
          columns: ['credit_limit', 'outstanding_balance'],
          where: 'id = ?',
          whereArgs: [invoice.customerId],
          limit: 1,
        );
        if (custRes.isNotEmpty) {
          final limit = (custRes.first['credit_limit'] as num).toInt();
          final balance = (custRes.first['outstanding_balance'] as num).toInt();
          if (limit > 0 && (balance + invoice.grandTotal) > limit) {
            throw Exception(
                'Credit limit exceeded. Current: $balance, Limit: $limit, Bill: ${invoice.grandTotal}');
          }
        }
      }

      // 2. Insert Invoice with a temporary number
      final tempBillNo = 'TEMP-${DateTime.now().microsecondsSinceEpoch}';
      final invoiceMap = invoice.toMap();
      invoiceMap['invoice_number'] = tempBillNo;

      final invoiceId = await t.insert('invoices', invoiceMap);

      // 3. Generate and update the final invoice number
      final now = DateTime.now();
      final String yy = (now.year % 100).toString();
      final String mm = now.month.toString().padLeft(2, '0');
      final String sequence = invoiceId.toString().padLeft(4, '0');
      final String finalBillNumber = 'SB-$yy$mm$sequence';
      await t.update('invoices', {'invoice_number': finalBillNumber},
          where: 'id = ?', whereArgs: [invoiceId]);

      // 4. Insert Invoice Items and update stock
      for (var item in invoice.items) {
        final itemMap = item.toMap();
        itemMap['invoice_id'] = invoiceId;
        await t.insert('invoice_items', itemMap);

        int count = await t.rawUpdate('''
          UPDATE products
          SET current_stock = current_stock - ?
          WHERE id = ? AND current_stock >= ?
        ''', [item.quantity, item.productId, item.quantity]);

        if (count == 0) {
          throw Exception(
              'Insufficient stock for product ID: ${item.productId}');
        }
      }

      // 5. Update Customer Ledger
      if (invoice.customerId != null) {
        final lastEntry = await t.rawQuery(
          'SELECT balance FROM customer_ledger WHERE customer_id = ? ORDER BY transaction_date DESC, id DESC LIMIT 1',
          [invoice.customerId],
        );
        int prevBal =
            lastEntry.isNotEmpty ? (lastEntry.first['balance'] as int) : 0;
        int newBal = prevBal + invoice.grandTotal;

        await t.insert('customer_ledger', {
          'customer_id': invoice.customerId,
          'transaction_date': invoice.date.toIso8601String(),
          'description': 'Invoice #$finalBillNumber',
          'ref_type': 'INVOICE',
          'ref_id': invoiceId,
          'debit': invoice.grandTotal,
          'credit': 0,
          'balance': newBal
        });

        await t.update('customers', {'outstanding_balance': newBal},
            where: 'id = ?', whereArgs: [invoice.customerId]);
      }
      return invoiceId;
    }

    try {
      if (txn != null) {
        return await performCreate(txn);
      } else {
        return await db.transaction((t) => performCreate(t));
      }
    } catch (e) {
      AppLogger.error('Error creating invoice: $e', tag: 'InvoiceRepo');
      rethrow;
    }
  }

  Future<int> createInvoiceWithSnapshot(Map<String, dynamic> invoiceData) async {
    final db = await _dbHelper.database;
    final shopProfile = await db.query('shop_profile', limit: 1);
    final shop = shopProfile.isNotEmpty ? shopProfile.first : {};
    Map<String, dynamic>? customer;
    if (invoiceData['customer_id'] != null) {
      final cResult = await db.query('customers', where: 'id = ?', whereArgs: [invoiceData['customer_id']], limit: 1);
      if (cResult.isNotEmpty) customer = cResult.first;
    }
    final now = DateTime.now();
    final snapshotMap = {
      'shop': {
        'name_en': shop['shop_name_english'],
        'name_ur': shop['shop_name_urdu'],
        'address': shop['shop_address'],
        'contact': shop['contact_primary'],
      },
      'invoice': {
        'date': DateFormat('yyyy-MM-dd').format(now),
        'time': DateFormat('hh:mm a').format(now),
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
        'grand_total': invoiceData['grand_total'],
        'discount': invoiceData['discount_total'],
      },
      'language': invoiceData['receipt_language'] ?? 'ur'
    };
    invoiceData['sale_snapshot'] = jsonEncode(snapshotMap);
    final invoice = Invoice.fromMap(invoiceData);
    return await createInvoice(invoice);
  }

  Future<void> editInvoice(int oldInvoiceId, Invoice newInvoice) async {
    final db = await _dbHelper.database;
    try {
      await db.transaction((txn) async {
        await cancelInvoice(
          invoiceId: oldInvoiceId,
          cancelledBy: 'System (Edit)',
          reason: 'Edited Invoice',
          txn: txn
        );
        final newInvoiceMap = newInvoice.toMap();
        newInvoiceMap['original_sale_id'] = oldInvoiceId;
        newInvoiceMap['status'] = 'EDITED_VERSION';
        final editedInvoice = Invoice.fromMap(newInvoiceMap);
        await createInvoice(editedInvoice, txn: txn);
      });
      AppLogger.info('Invoice edited successfully (ID: $oldInvoiceId)', tag: 'InvoiceRepo');
    } catch (e) {
      AppLogger.error('Error editing invoice: $e', tag: 'InvoiceRepo');
      rethrow;
    }
  }

  Future<void> cancelInvoice({
    required int invoiceId,
    required String cancelledBy,
    String? reason,
    Transaction? txn,
  }) async {
    final db = await _dbHelper.database;
    Future<void> performCancel(Transaction t) async {
      final invoiceRes = await t.query(
        'invoices',
        where: 'id = ? AND status = ?',
        whereArgs: [invoiceId, 'COMPLETED'],
        limit: 1,
      );
      if (invoiceRes.isEmpty) {
        throw Exception('Invoice not found or already cancelled');
      }
      final invoice = Invoice.fromMap(invoiceRes.first);
      await t.update(
        'invoices',
        {
          'status': 'CANCELLED',
          'cancelled_at': DateTime.now().toIso8601String(),
          'cancelled_by': cancelledBy,
          'cancel_reason': reason,
        },
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
      final items = await t.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );
      for (final item in items) {
        await t.rawUpdate(
          'UPDATE products SET current_stock = current_stock + ? WHERE id = ?',
          [item['quantity'], item['product_id']],
        );
      }
      if (invoice.customerId != null) {
         final lastEntry = await t.rawQuery(
          'SELECT balance FROM customer_ledger WHERE customer_id = ? ORDER BY transaction_date DESC, id DESC LIMIT 1',
          [invoice.customerId],
        );
        int prevBal = lastEntry.isNotEmpty ? (lastEntry.first['balance'] as int) : 0;
        int newBal = prevBal - invoice.grandTotal;

        await t.insert('customer_ledger', {
          'customer_id': invoice.customerId,
          'transaction_date': DateTime.now().toIso8601String(),
          'description': 'Cancelled Invoice #${invoice.invoiceNumber}',
          'ref_type': 'ADJUSTMENT',
          'ref_id': invoiceId,
          'debit': 0,
          'credit': invoice.grandTotal,
          'balance': newBal
        });
        await t.update('customers', {'outstanding_balance': newBal}, where: 'id = ?', whereArgs: [invoice.customerId]);
      }
    }
     try {
      if (txn != null) {
        await performCancel(txn);
      } else {
        await db.transaction((t) => performCancel(t));
      }
      AppLogger.info('Invoice cancelled successfully (ID: $invoiceId)', tag: 'InvoiceRepo');
    } catch (e) {
      AppLogger.error('Error cancelling invoice: $e', tag: 'InvoiceRepo');
      rethrow;
    }
  }

  Future<List<Invoice>> getRecentInvoices({int limit = 20}) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT
        i.*,
        COALESCE(c.name_english, 'Walk-in Customer') as customer_name
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      ORDER BY i.created_at DESC
      LIMIT ?
    ''', [limit]);
    return result.map((map) => Invoice.fromMap(map)).toList();
  }

  Future<int> getTodayInvoiceTotal() async {
    try {
      final db = await _dbHelper.database;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final result = await db.rawQuery(
        'SELECT SUM(grand_total) as total FROM invoices WHERE invoice_date LIKE ? AND status = ?',
        ['$today%', 'COMPLETED']
      );
      return (result.first['total'] as num?)?.toInt() ?? 0;
    } catch (e) {
      AppLogger.error("Error fetching today's invoice total: $e", tag: 'InvoiceRepo');
      return 0;
    }
  }

  Future<Invoice?> getInvoiceById(int invoiceId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    final invoice = Invoice.fromMap(result.first);
    final items = await getInvoiceItems(invoiceId);
    return Invoice.fromMap({...invoice.toMap(), 'items': items.map((e) => e.toMap()).toList()});
  }

  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT
        ii.id,
        ii.invoice_id,
        ii.product_id,
        COALESCE(p.name_english, p.name_urdu) as name,
        ii.quantity,
        ii.unit_price,
        ii.total_price
      FROM invoice_items ii
      JOIN products p ON ii.product_id = p.id
      WHERE ii.invoice_id = ?
      ORDER BY ii.id
    ''', [invoiceId]);
    return result.map((map) => InvoiceItem.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>?> getInvoiceSnapshot(int invoiceId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'invoices',
      columns: ['sale_snapshot'],
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );
    if (result.isNotEmpty && result.first['sale_snapshot'] != null) {
      return jsonDecode(result.first['sale_snapshot'] as String);
    }
    return null;
  }

  Future<void> incrementPrintCount(int invoiceId) async {
    final db = await _dbHelper.database;
    await db.rawUpdate('UPDATE invoices SET printed_count = printed_count + 1 WHERE id = ?', [invoiceId]);
  }

  Future<List<Invoice>> getInvoicesByDateRange(String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT
        i.*,
        COALESCE(c.name_english, 'Walk-in Customer') as customer_name
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      WHERE DATE(i.invoice_date) BETWEEN ? AND ?
      AND i.status = 'COMPLETED'
      ORDER BY i.invoice_date DESC
    ''', [startDate, endDate]);
    return result.map((map) => Invoice.fromMap(map)).toList();
  }

  Future<List<Invoice>> getInvoicesByCustomer(int customerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT
        i.*,
        c.name_english as customer_name
      FROM invoices i
      JOIN customers c ON i.customer_id = c.id
      WHERE i.customer_id = ?
      AND i.status = 'COMPLETED'
      ORDER BY i.invoice_date DESC
    ''', [customerId]);
    return result.map((map) => Invoice.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> validateStock(
      List<Map<String, dynamic>> cartItems) async {
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
          'error': 'Insufficient stock for $productName',
          'productName': productName,
          'available': currentStock,
          'requested': requestedQty,
        };
      }
    }
    return {'valid': true};
  }
}
