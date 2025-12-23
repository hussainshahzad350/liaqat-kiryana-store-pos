// lib/core/repositories/items_repository.dart
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../utils/logger.dart';

class ItemsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Fetch all products that can be sold.
  Future<List<Map<String, dynamic>>> getSellableItems() async {
    try {
      final db = await _dbHelper.database;
      // Fetching all items, could be filtered for active items in a real scenario
      final items = await db.query('products', orderBy: 'name_english ASC');
      return items;
    } catch (e) {
      AppLogger.error('Error fetching sellable items: $e', tag: 'ItemsRepo');
      return [];
    }
  }

  /// Get the current stock for a single product.
  Future<double> getProductStock(int productId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'products',
        columns: ['current_stock'],
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return (result.first['current_stock'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      AppLogger.error('Error fetching product stock for ID $productId: $e', tag: 'ItemsRepo');
      return 0.0;
    }
  }
}
