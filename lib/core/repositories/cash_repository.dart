import '../../domain/entities/money.dart';
import '../database/database_helper.dart';
import '../utils/logger.dart';
import 'package:intl/intl.dart';
import '../../models/cash_ledger_model.dart';

class CashRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // -----------------------------
  // PRIVATE HELPERS
  // -----------------------------

  Money _moneyFromDb(Map<String, dynamic> row, String key) {
    return Money.fromPaisas((row[key] as num?)?.toInt() ?? 0);
  }

  ({String? where, List<dynamic> args}) _paymentModeFilterClause(
      String paymentModeFilter) {
    switch (paymentModeFilter) {
      case 'CASH':
        return (
          where:
              '(payment_mode = ? OR payment_mode IS NULL OR payment_mode = \'\')',
          args: [PaymentMode.cash.dbValue],
        );
      case 'DIGITAL':
        return (
          where:
              '(payment_mode IS NOT NULL AND payment_mode != \'\' AND payment_mode != ?)',
          args: [PaymentMode.cash.dbValue],
        );
      default:
        return (where: null, args: <dynamic>[]);
    }
  }

  // ========================================
  // CASH BALANCE
  // ========================================

  /// Get current TOTAL balance (Cash + Digital)
  Future<Money> getCurrentCashBalance() async {
    try {
      final db = await _dbHelper.database;
      final res = await db.rawQuery(
          'SELECT balance_after FROM cash_ledger ORDER BY id DESC LIMIT 1');
      if (res.isNotEmpty) {
        return _moneyFromDb(res.first, 'balance_after');
      }
      return Money.zero;
    } catch (e) {
      AppLogger.error('Error getting total cash balance: $e', tag: 'CashRepo');
      return Money.zero;
    }
  }

  /// Get current PHYSICAL cash balance (CASH only)
  Future<Money> getPhysicalCashBalance() async {
    try {
      final db = await _dbHelper.database;
      final res = await db.rawQuery('''
        SELECT 
          SUM(CASE WHEN type = 'IN' THEN amount ELSE -amount END) as balance 
        FROM cash_ledger 
        WHERE payment_mode = '${PaymentMode.cash.dbValue}'
      ''');
      if (res.isNotEmpty && res.first['balance'] != null) {
        return Money.fromPaisas((res.first['balance'] as num).toInt());
      }
      return Money.zero;
    } catch (e) {
      AppLogger.error('Error getting physical cash balance: $e',
          tag: 'CashRepo');
      return Money.zero;
    }
  }

  // ========================================
  // CASH ENTRY MANAGEMENT
  // ========================================

  /// Add cash entry (IN or OUT).
  ///
  /// A unique `transaction_id` is automatically generated for every manual
  /// entry so that the cash_ledger satisfies the identity-enforcement rule
  /// (Rule 4) and the unique-constraint on transaction_id (Rule 11).
  Future<void> addCashEntry(
    String description,
    String type,
    Money amount,
    String remarks, {
    String paymentMode = 'CASH',
    DateTime? transactionDate,
  }) async {
    final db = await _dbHelper.database;
    final now = transactionDate ?? DateTime.now();

    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final timeStr = DateFormat('hh:mm a').format(now);

    final normalizedPaymentMode = PaymentModeX.fromString(paymentMode).dbValue;

    await db.transaction((txn) async {
      final res = await txn.rawQuery(
          'SELECT balance_after FROM cash_ledger ORDER BY id DESC LIMIT 1');
      Money currentBalance = res.isNotEmpty
          ? _moneyFromDb(res.first, 'balance_after')
          : Money.zero;

      type = type.toUpperCase(); // normalize

      Money newBalance;
      if (type == 'IN') {
        newBalance = currentBalance + amount;
      } else if (type == 'OUT') {
        newBalance = currentBalance - amount;
      } else {
        newBalance = currentBalance;
      }

      // Generate a stable, unique transaction_id for this manual entry.
      final txnId = 'MANUAL_CASH:${now.microsecondsSinceEpoch}';

      await txn.insert('cash_ledger', {
        'transaction_date': dateStr,
        'transaction_time': timeStr,
        'description': description,
        'type': type,
        'amount': amount.paisas,
        'balance_after': newBalance.paisas,
        'remarks': remarks,
        'payment_mode': normalizedPaymentMode,
        'transaction_id': txnId,
      });
    });
  }

  /// Add cash IN entry (shorthand)
  Future<void> addCashIn(
    String description,
    Money amount, {
    String? remarks,
    String paymentMode = 'CASH',
    DateTime? transactionDate,
  }) async {
    await addCashEntry(
      description,
      'IN',
      amount,
      remarks ?? '',
      paymentMode: paymentMode,
      transactionDate: transactionDate,
    );
  }

  /// Add cash OUT entry (shorthand)
  Future<void> addCashOut(
    String description,
    Money amount, {
    String? remarks,
    String paymentMode = 'CASH',
    DateTime? transactionDate,
  }) async {
    await addCashEntry(
      description,
      'OUT',
      amount,
      remarks ?? '',
      paymentMode: paymentMode,
      transactionDate: transactionDate,
    );
  }

  // ========================================
  // CASH LEDGER QUERIES
  // ========================================

  /// Get cash ledger with pagination
  /// Moved from DatabaseHelper.getCashLedger()
  Future<List<CashLedger>> getCashLedger({
    int limit = 50,
    int offset = 0,
    String paymentModeFilter = 'ALL',
  }) async {
    try {
      final db = await _dbHelper.database;
      final filter = _paymentModeFilterClause(paymentModeFilter);
      final result = await db.query(
        'cash_ledger',
        where: filter.where,
        whereArgs: filter.args.isEmpty ? null : filter.args,
        orderBy: 'id DESC',
        limit: limit,
        offset: offset,
      );
      return result.map((map) => CashLedger.fromMap(map)).toList();
    } catch (e) {
      AppLogger.error('Error getting cash ledger: $e', tag: 'CashRepo');
      return [];
    }
  }

  /// Get cash ledger by date range
  Future<List<CashLedger>> getCashLedgerByDateRange(
    String startDate,
    String endDate, {
    int? limit,
    String paymentModeFilter = 'ALL',
  }) async {
    try {
      final db = await _dbHelper.database;
      final filter = _paymentModeFilterClause(paymentModeFilter);

      String query = '''
        SELECT * FROM cash_ledger 
        WHERE transaction_date BETWEEN ? AND ?
      ''';

      if (filter.where != null) {
        query += '\n        AND ${filter.where}';
      }

      query += '''
        ORDER BY transaction_date DESC, transaction_time DESC
      ''';

      List<dynamic> args = [startDate, endDate, ...filter.args];

      if (limit != null) {
        query += ' LIMIT ?';
        args.add(limit);
      }

      final result = await db.rawQuery(query, args);
      return result.map((map) => CashLedger.fromMap(map)).toList();
    } catch (e) {
      AppLogger.error('Error getting cash ledger by date: $e', tag: 'CashRepo');
      return [];
    }
  }

  /// Search cash ledger by description
  Future<List<CashLedger>> searchCashLedger(
    String query, {
    String paymentModeFilter = 'ALL',
  }) async {
    try {
      final db = await _dbHelper.database;
      final q = '%${query.toLowerCase()}%';
      final filter = _paymentModeFilterClause(paymentModeFilter);

      String sql = '''
        SELECT * FROM cash_ledger 
        WHERE (LOWER(description) LIKE ? OR LOWER(remarks) LIKE ?)
      ''';

      if (filter.where != null) {
        sql += '\n        AND ${filter.where}';
      }

      sql += '\n        ORDER BY id DESC';

      final result = await db.rawQuery(sql, [q, q, ...filter.args]);
      return result.map((map) => CashLedger.fromMap(map)).toList();
    } catch (e) {
      AppLogger.error('Error searching cash ledger: $e', tag: 'CashRepo');
      return [];
    }
  }

  // ========================================
  // CASH SUMMARY & ANALYTICS
  // ========================================

  // ========================================
  // TRANSACTION MANAGEMENT
  // ========================================

  /// Update cash ledger entry.
  ///
  /// BLOCKED: Mutating existing cash_ledger rows violates the event-immutability
  /// rule (Rule 3) and delete-safety rule (Rule 8).  To correct a cash entry,
  /// create a reversal event and then insert a new correcting event.
  Future<int> updateCashEntry(
    int id,
    Map<String, dynamic> updates,
  ) {
    throw UnsupportedError(
      'RULE_VIOLATION: updateCashEntry() mutates an immutable cash_ledger row. '
      'Create a reversal event instead (Rule 3).',
    );
  }

  /// Delete cash entry.
  ///
  /// BLOCKED: Deleting cash_ledger rows violates the event-immutability rule
  /// (Rule 3) and delete-safety rule (Rule 8).  Use a reversal event instead.
  Future<int> deleteCashEntry(int id) {
    throw UnsupportedError(
      'RULE_VIOLATION: deleteCashEntry() deletes an immutable cash_ledger row. '
      'Create a reversal event instead (Rule 3 / Rule 8).',
    );
  }

  // ========================================
  // STATISTICS
  // ========================================
}
