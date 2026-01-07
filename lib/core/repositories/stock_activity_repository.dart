import '../database/database_helper.dart';
import '../entity/stock_activity_entity.dart';
import '../../domain/entities/money.dart';

class StockActivityRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Fetch paginated stock activities (Audit Log)
  /// Combines Sales (Stock Out) and Purchases (Stock In)
  Future<List<StockActivityEntity>> getActivities({
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;

    // Union Query to get chronological events
    final result = await db.rawQuery('''
      SELECT 
        'SALE' as type,
        id,
        invoice_number as ref_no,
        invoice_date as date,
        grand_total as amount,
        'Sale to Customer' as description
      FROM invoices
      WHERE status = 'COMPLETED'

      UNION ALL

      SELECT 
        'PURCHASE' as type,
        id,
        invoice_number as ref_no,
        purchase_date as date,
        total_amount as amount,
        'Purchase from Supplier' as description
      FROM purchases

      ORDER BY date DESC
      LIMIT ? OFFSET ?
    ''', [limit, offset]);

    return result.map((row) => _mapToEntity(row)).toList();
  }

  StockActivityEntity _mapToEntity(Map<String, dynamic> row) {
    final typeStr = row['type'] as String;
    ActivityType type;
    double qtyChange = 0; // Aggregate not available in summary view

    if (typeStr == 'SALE') {
      type = ActivityType.sale;
      qtyChange = -1; // Indicative
    } else if (typeStr == 'PURCHASE') {
      type = ActivityType.purchase;
      qtyChange = 1; // Indicative
    } else {
      type = ActivityType.adjustment;
    }

    // Handle date parsing safely
    DateTime timestamp;
    try {
      timestamp = DateTime.parse(row['date'] as String);
    } catch (_) {
      timestamp = DateTime.now();
    }

    return StockActivityEntity(
      id: "${typeStr}_${row['id']}",
      timestamp: timestamp,
      type: type,
      referenceNumber: row['ref_no'] as String? ?? '-',
      referenceId: row['id'] as int,
      description: row['description'] as String,
      quantityChange: qtyChange,
      financialImpact: Money((row['amount'] as num?)?.toInt() ?? 0),
      user: 'Admin', // Placeholder until Auth system is linked
      status: 'COMPLETED',
    );
  }
}