import '../database/database_helper.dart';
import '../../models/invoice_item_model.dart';

class InvoiceItemRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertItem(InvoiceItem item) async {
    final db = await _dbHelper.database;
    return await db.insert('invoice_items', item.toMap());
  }

  Future<void> updateItem(InvoiceItem item) async {
    final db = await _dbHelper.database;
    await db.update(
      'invoice_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteItem(int itemId) async {
    final db = await _dbHelper.database;
    await db.delete('invoice_items', where: 'id = ?', whereArgs: [itemId]);
  }

  Future<List<InvoiceItem>> getItemsByInvoice(int invoiceId) async {
    final db = await _dbHelper.database;
    final result = await db.query('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
    return result.map((e) => InvoiceItem.fromMap(e)).toList();
  }
}
