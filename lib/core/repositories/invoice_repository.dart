import '../database/database_helper.dart';
import '../../models/invoice_model.dart';
import '../../models/invoice_item_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../utils/logger.dart';

class InvoiceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert a new invoice with its items atomically
  Future<int> insertInvoiceWithItems(Invoice invoice) async {
    final db = await _dbHelper.database;

    return await db.transaction<int>((txn) async {
      // Step 1: Insert invoice with temporary number
      final tempNumber = 'TEMP-${DateTime.now().microsecondsSinceEpoch}';
      final invoiceId = await txn.insert('invoices', {
        'invoice_number': tempNumber,
        'customer_id': invoice.customerId,
        'invoice_date': invoice.date.toIso8601String(),
        'sub_total': invoice.totalAmount + invoice.discount,
        'grand_total': invoice.totalAmount,
        'discount_total': invoice.discount,
        'status': invoice.status,
        'notes': invoice.notes,
      });

      // Step 2: Generate final invoice number (SB-YYMMXXXX)
      final now = DateTime.now();
      final yy = (now.year % 100).toString().padLeft(2, '0');
      final mm = now.month.toString().padLeft(2, '0');
      final sequence = invoiceId.toString().padLeft(4, '0');
      final finalNumber = 'SB-$yy$mm$sequence';

      await txn.update(
        'invoices',
        {'invoice_number': finalNumber},
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      // Step 3: Insert items
      for (var item in invoice.items) {
        await txn.insert('invoice_items', {
          'invoice_id': invoiceId,
          'product_id': item.productId,
          'item_name_snapshot': item.itemName,
          'quantity': item.quantity,
          'unit_price': item.rate,
          'total_price': item.subtotal,
        });
      }

      return invoiceId;
    });
  }

  /// Get invoice by ID and auto-load items
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

  /// Update invoice info (does not auto-update items)
  Future<void> updateInvoice(Invoice invoice) async {
    final db = await _dbHelper.database;
    await db.update(
      'invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  }

  /// Delete invoice (optionally delete items as well)
  Future<void> deleteInvoice(int invoiceId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
      await txn.delete('invoices', where: 'id = ?', whereArgs: [invoiceId]);
    });
  }
}
