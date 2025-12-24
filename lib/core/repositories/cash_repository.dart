// lib/core/repositories/cash_repository.dart
import '../database/database_helper.dart';
import '../utils/logger.dart';
import 'package:intl/intl.dart';
import '../../models/cash_ledger_model.dart';

class CashRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // CASH BALANCE
  // ========================================

  /// Get current cash balance
  /// Moved from DatabaseHelper.getCurrentCashBalance()
  Future<double> getCurrentCashBalance() async {
    try {
      final db = await _dbHelper.database;
      final res = await db.rawQuery(
        'SELECT balance_after FROM cash_ledger ORDER BY id DESC LIMIT 1'
      );
      if (res.isNotEmpty) {
        return (res.first['balance_after'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      AppLogger.error('Error getting cash balance: $e', tag: 'CashRepo');
      return 0.0;
    }
  }

  /// Get cash balance at specific date
  Future<double> getCashBalanceAtDate(String date) async {
    try {
      final db = await _dbHelper.database;
      final res = await db.rawQuery('''
        SELECT balance_after 
        FROM cash_ledger 
        WHERE transaction_date <= ?
        ORDER BY id DESC 
        LIMIT 1
      ''', [date]);
      
      if (res.isNotEmpty) {
        return (res.first['balance_after'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      AppLogger.error('Error getting cash balance at date: $e', tag: 'CashRepo');
      return 0.0;
    }
  }

  // ========================================
  // CASH ENTRY MANAGEMENT
  // ========================================

  /// Add cash entry (IN or OUT)
  /// Moved from DatabaseHelper.addCashEntry()
  Future<void> addCashEntry(
    String description,
    String type,
    double amount,
    String remarks,
  ) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final timeStr = DateFormat('hh:mm a').format(now);

    await db.transaction((txn) async {
      final res = await txn.rawQuery(
        'SELECT balance_after FROM cash_ledger ORDER BY id DESC LIMIT 1'
      );
      double currentBalance = 0.0;
      if (res.isNotEmpty) {
        currentBalance = (res.first['balance_after'] as num).toDouble();
      }

      double newBalance = currentBalance;
      if (type == 'IN') {
        newBalance += amount;
      } else if (type == 'OUT') {
        newBalance -= amount;
      }

      await txn.insert('cash_ledger', {
        'transaction_date': dateStr,
        'transaction_time': timeStr,
        'description': description,
        'type': type,
        'amount': amount,
        'balance_after': newBalance,
        'remarks': remarks,
      });
    });
  }

  /// Add cash IN entry (shorthand)
  Future<void> addCashIn(
    String description,
    double amount, {
    String? remarks,
  }) async {
    await addCashEntry(description, 'IN', amount, remarks ?? '');
  }

  /// Add cash OUT entry (shorthand)
  Future<void> addCashOut(
    String description,
    double amount, {
    String? remarks,
  }) async {
    await addCashEntry(description, 'OUT', amount, remarks ?? '');
  }

  // ========================================
  // CASH LEDGER QUERIES
  // ========================================

  /// Get cash ledger with pagination
  /// Moved from DatabaseHelper.getCashLedger()
  Future<List<CashLedger>> getCashLedger({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'cash_ledger',
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
  }) async {
    try {
      final db = await _dbHelper.database;
      
      String query = '''
        SELECT * FROM cash_ledger 
        WHERE transaction_date BETWEEN ? AND ?
        ORDER BY transaction_date DESC, transaction_time DESC
      ''';
      
      List<dynamic> args = [startDate, endDate];
      
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

  /// Get today's cash ledger
  Future<List<CashLedger>> getTodayCashLedger() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await getCashLedgerByDateRange(today, today);
  }

  /// Get cash ledger by type (IN or OUT)
  Future<List<CashLedger>> getCashLedgerByType(
    String type, {
    int? limit,
  }) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'cash_ledger',
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'id DESC',
        limit: limit,
      );
      return result.map((map) => CashLedger.fromMap(map)).toList();
    } catch (e) {
      AppLogger.error('Error getting cash ledger by type: $e', tag: 'CashRepo');
      return [];
    }
  }

  /// Search cash ledger by description
  Future<List<CashLedger>> searchCashLedger(String query) async {
    try {
      final db = await _dbHelper.database;
      final q = '%${query.toLowerCase()}%';
      
      final result = await db.rawQuery('''
        SELECT * FROM cash_ledger 
        WHERE LOWER(description) LIKE ? OR LOWER(remarks) LIKE ?
        ORDER BY id DESC
      ''', [q, q]);
      return result.map((map) => CashLedger.fromMap(map)).toList();
    } catch (e) {
      AppLogger.error('Error searching cash ledger: $e', tag: 'CashRepo');
      return [];
    }
  }

  // ========================================
  // CASH SUMMARY & ANALYTICS
  // ========================================

  /// Get cash summary for a date range
  Future<Map<String, dynamic>> getCashSummary(
    String startDate,
    String endDate,
  ) async {
    try {
      final db = await _dbHelper.database;
      
      final result = await db.rawQuery('''
        SELECT 
          SUM(CASE WHEN type = 'IN' THEN amount ELSE 0 END) as total_in,
          SUM(CASE WHEN type = 'OUT' THEN amount ELSE 0 END) as total_out,
          COUNT(CASE WHEN type = 'IN' THEN 1 END) as in_count,
          COUNT(CASE WHEN type = 'OUT' THEN 1 END) as out_count,
          COUNT(*) as total_transactions
        FROM cash_ledger
        WHERE transaction_date BETWEEN ? AND ?
      ''', [startDate, endDate]);

      if (result.isEmpty) {
        return {
          'totalIn': 0.0,
          'totalOut': 0.0,
          'netChange': 0.0,
          'inCount': 0,
          'outCount': 0,
          'totalTransactions': 0,
        };
      }

      final data = result.first;
      final totalIn = (data['total_in'] as num?)?.toDouble() ?? 0.0;
      final totalOut = (data['total_out'] as num?)?.toDouble() ?? 0.0;

      return {
        'totalIn': totalIn,
        'totalOut': totalOut,
        'netChange': totalIn - totalOut,
        'inCount': data['in_count'] ?? 0,
        'outCount': data['out_count'] ?? 0,
        'totalTransactions': data['total_transactions'] ?? 0,
        'startDate': startDate,
        'endDate': endDate,
      };
    } catch (e) {
      AppLogger.error('Error getting cash summary: $e', tag: 'CashRepo');
      return {
        'totalIn': 0.0,
        'totalOut': 0.0,
        'netChange': 0.0,
        'inCount': 0,
        'outCount': 0,
        'totalTransactions': 0,
      };
    }
  }

  /// Get today's cash summary
  Future<Map<String, dynamic>> getTodayCashSummary() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await getCashSummary(today, today);
  }

  /// Get this month's cash summary
  Future<Map<String, dynamic>> getThisMonthCashSummary() async {
    final now = DateTime.now();
    final startDate = DateFormat('yyyy-MM-dd').format(
      DateTime(now.year, now.month, 1)
    );
    final endDate = DateFormat('yyyy-MM-dd').format(now);
    return await getCashSummary(startDate, endDate);
  }

  /// Get cash flow trend (daily totals for a period)
  Future<List<Map<String, dynamic>>> getCashFlowTrend(
    String startDate,
    String endDate,
  ) async {
    try {
      final db = await _dbHelper.database;
      
      return await db.rawQuery('''
        SELECT 
          transaction_date as date,
          SUM(CASE WHEN type = 'IN' THEN amount ELSE 0 END) as cash_in,
          SUM(CASE WHEN type = 'OUT' THEN amount ELSE 0 END) as cash_out,
          SUM(CASE WHEN type = 'IN' THEN amount ELSE -amount END) as net_change
        FROM cash_ledger
        WHERE transaction_date BETWEEN ? AND ?
        GROUP BY transaction_date
        ORDER BY transaction_date ASC
      ''', [startDate, endDate]);
    } catch (e) {
      AppLogger.error('Error getting cash flow trend: $e', tag: 'CashRepo');
      return [];
    }
  }

  // ========================================
  // TRANSACTION MANAGEMENT
  // ========================================

  /// Get transaction by ID
  Future<Map<String, dynamic>?> getTransactionById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'cash_ledger',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return result.first;
  }

  /// Update cash ledger entry (for corrections)
  Future<int> updateCashEntry(
    int id,
    Map<String, dynamic> updates,
  ) async {
    final db = await _dbHelper.database;
    
    // Recalculate balance if amount changes
    if (updates.containsKey('amount') || updates.containsKey('type')) {
      await _recalculateBalancesFrom(id);
    }
    
    return await db.update(
      'cash_ledger',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete cash entry (and recalculate subsequent balances)
  Future<int> deleteCashEntry(int id) async {
    final db = await _dbHelper.database;
    
    final deleted = await db.delete(
      'cash_ledger',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (deleted > 0) {
      await _recalculateBalancesFrom(id);
    }
    
    return deleted;
  }

  /// Recalculate all balances from a specific entry onwards
  Future<void> _recalculateBalancesFrom(int fromId) async {
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      // Get all entries from this point onwards
      final entries = await txn.query(
        'cash_ledger',
        where: 'id >= ?',
        whereArgs: [fromId],
        orderBy: 'id ASC',
      );

      // Get the balance before this entry
      final prevEntries = await txn.query(
        'cash_ledger',
        where: 'id < ?',
        whereArgs: [fromId],
        orderBy: 'id DESC',
        limit: 1,
      );

      double runningBalance = prevEntries.isNotEmpty
          ? (prevEntries.first['balance_after'] as num).toDouble()
          : 0.0;

      // Recalculate balances for all subsequent entries
      for (var entry in entries) {
        final type = entry['type'] as String;
        final amount = (entry['amount'] as num).toDouble();

        if (type == 'IN') {
          runningBalance += amount;
        } else if (type == 'OUT') {
          runningBalance -= amount;
        }

        await txn.update(
          'cash_ledger',
          {'balance_after': runningBalance},
          where: 'id = ?',
          whereArgs: [entry['id']],
        );
      }
    });
  }

  // ========================================
  // STATISTICS
  // ========================================

  /// Get total cash IN for period
  Future<double> getTotalCashIn(String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM cash_ledger 
      WHERE type = 'IN' AND transaction_date BETWEEN ? AND ?
    ''', [startDate, endDate]);
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total cash OUT for period
  Future<double> getTotalCashOut(String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM cash_ledger 
      WHERE type = 'OUT' AND transaction_date BETWEEN ? AND ?
    ''', [startDate, endDate]);
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get transaction count
  Future<int> getTransactionCount({String? type, String? date}) async {
    final db = await _dbHelper.database;
    
    String query = 'SELECT COUNT(*) as count FROM cash_ledger WHERE 1=1';
    List<dynamic> args = [];
    
    if (type != null) {
      query += ' AND type = ?';
      args.add(type);
    }
    
    if (date != null) {
      query += ' AND transaction_date = ?';
      args.add(date);
    }
    
    final result = await db.rawQuery(query, args);
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get average transaction amount
  Future<double> getAverageTransactionAmount({
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    final db = await _dbHelper.database;
    
    String query = 'SELECT AVG(amount) as avg FROM cash_ledger WHERE 1=1';
    List<dynamic> args = [];
    
    if (type != null) {
      query += ' AND type = ?';
      args.add(type);
    }
    
    if (startDate != null && endDate != null) {
      query += ' AND transaction_date BETWEEN ? AND ?';
      args.add(startDate);
      args.add(endDate);
    }
    
    final result = await db.rawQuery(query, args);
    return (result.first['avg'] as num?)?.toDouble() ?? 0.0;
  }
}