import '../database/database_helper.dart';
import '../entity/stock_activity_entity.dart';
import '../../domain/entities/money.dart';

class StockActivityRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Fetch paginated stock activities (Audit Log)
  /// Uses stock event ledger as the single activity source.
  Future<List<StockActivityEntity>> getActivities({
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;

    // Chronological stock events with cancellation state derived from reversals.
    final result = await db.rawQuery('''
      SELECT 
        sa.id,
        sa.transaction_type,
        sa.ref_type,
        sa.ref_id,
        sa.quantity_change,
        sa.user,
        sa.created_at,
        p.name_english as product_name,
        CASE
          WHEN sa.reversal_of_stock_activity_id IS NOT NULL THEN 'COMPLETED'
          WHEN EXISTS (
            SELECT 1
            FROM stock_activities rev
            WHERE rev.reversal_of_stock_activity_id = sa.id
          ) THEN 'CANCELLED'
          ELSE 'COMPLETED'
        END as status
      FROM stock_activities sa
      LEFT JOIN products p ON p.id = sa.product_id
      ORDER BY datetime(sa.created_at) DESC, sa.id DESC
      LIMIT ? OFFSET ?
    ''', [limit, offset]);

    return result.map((row) => _mapToEntity(row)).toList();
  }

  StockActivityEntity _mapToEntity(Map<String, dynamic> row) {
    final typeStr = (row['transaction_type'] as String?) ?? 'ADJUSTMENT';
    final refType = (row['ref_type'] as String?) ?? 'ADJUSTMENT';
    final refId = (row['ref_id'] as num?)?.toInt();
    final qtyChange = (row['quantity_change'] as num?)?.toDouble() ?? 0;
    ActivityType type;

    if (typeStr == 'SALE') {
      type = ActivityType.sale;
    } else if (typeStr == 'PURCHASE') {
      type = ActivityType.purchase;
    } else if (typeStr == 'SALE_CANCEL') {
      type = ActivityType.returnIn;
    } else if (typeStr == 'PURCHASE_CANCEL') {
      type = ActivityType.returnOut;
    } else {
      type = ActivityType.adjustment;
    }

    // Handle date parsing safely
    DateTime timestamp;
    try {
      timestamp = DateTime.parse(row['created_at']?.toString() ?? '');
    } catch (_) {
      timestamp = DateTime.now();
    }

    return StockActivityEntity(
      id: "EVENT_${row['id']}",
      timestamp: timestamp,
      type: type,
      referenceNumber: '$refType #${refId ?? '-'}',
      referenceId: refId,
      description: row['product_name']?.toString() ?? '-',
      quantityChange: qtyChange,
      financialImpact: const Money(0),
      user: (row['user'] as String?) ?? 'SYSTEM',
      status: (row['status'] as String?) ?? 'COMPLETED',
    );
  }
}
