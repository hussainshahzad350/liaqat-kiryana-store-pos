// lib/core/repositories/suppliers_repository.dart
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../utils/logger.dart';
import '../../models/supplier_model.dart';

class SuppliersRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ========================================
  // SUPPLIER CRUD OPERATIONS
  // ========================================

  /// Get all suppliers
  /// Moved from DatabaseHelper.getSuppliers()
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    try {
      final db = await _dbHelper.database;
      return await db.query('suppliers', orderBy: 'name_english ASC');
    } catch (e) {
      AppLogger.error('Error getting suppliers: $e', tag: 'SupplierRepo');
      return [];
    }
  }

  /// Get supplier by ID
  Future<Map<String, dynamic>?> getSupplierById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return result.first;
  }

  /// Add new supplier
  Future<int> addSupplier(Map<String, dynamic> supplierData) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'suppliers',
      supplierData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update supplier
  Future<int> updateSupplier(int id, Map<String, dynamic> supplierData) async {
    final db = await _dbHelper.database;
    return await db.update(
      'suppliers',
      supplierData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete supplier
  Future<int> deleteSupplier(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================================
  // SUPPLIER SEARCH & FILTER
  // ========================================

  /// Search suppliers by name or contact
  Future<List<Map<String, dynamic>>> searchSuppliers(String query) async {
    final db = await _dbHelper.database;
    final q = '%${query.toLowerCase()}%';
    
    return await db.rawQuery('''
      SELECT * FROM suppliers 
      WHERE LOWER(name_english) LIKE ? 
      OR LOWER(name_urdu) LIKE ?
      OR contact_primary LIKE ?
      ORDER BY name_english ASC
    ''', [q, q, query]);
  }

  /// Get paged suppliers with optional search
  Future<List<Supplier>> getSuppliersPaged({
    required int limit,
    required int offset,
    String? query,
  }) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps;

    if (query != null && query.isNotEmpty) {
      final q = '%$query%';
      maps = await db.query(
        'suppliers',
        where: 'name_english LIKE ? OR name_urdu LIKE ? OR contact_primary LIKE ?',
        whereArgs: [q, q, q],
        orderBy: 'name_english ASC',
        limit: limit,
        offset: offset,
      );
    } else {
      maps = await db.query(
        'suppliers',
        orderBy: 'name_english ASC',
        limit: limit,
        offset: offset,
      );
    }
    return maps.map((e) => Supplier.fromMap(e)).toList();
  }

  /// Get active suppliers only
  Future<List<Map<String, dynamic>>> getActiveSuppliers() async {
    final db = await _dbHelper.database;
    return await db.query(
      'suppliers',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name_english ASC',
    );
  }

  /// Get inactive suppliers
  Future<List<Map<String, dynamic>>> getInactiveSuppliers() async {
    final db = await _dbHelper.database;
    return await db.query(
      'suppliers',
      where: 'is_active = ?',
      whereArgs: [0],
      orderBy: 'name_english ASC',
    );
  }

  // ========================================
  // SUPPLIER BALANCE MANAGEMENT
  // ========================================

  /// Update supplier outstanding balance
  Future<int> updateSupplierBalance(int supplierId, int balance) async {
    final db = await _dbHelper.database;
    return await db.update(
      'suppliers',
      {'outstanding_balance': balance},
      where: 'id = ?',
      whereArgs: [supplierId],
    );
  }

  /// Adjust supplier balance (add or subtract)
  Future<int> adjustSupplierBalance(
    int supplierId,
    int adjustment,
  ) async {
    final db = await _dbHelper.database;
    
    return await db.transaction((txn) async {
      // Get current balance
      final result = await txn.query(
        'suppliers',
        columns: ['outstanding_balance'],
        where: 'id = ?',
        whereArgs: [supplierId],
        limit: 1,
      );

      if (result.isEmpty) {
        throw Exception('Supplier not found');
      }

      final currentBalance = (result.first['outstanding_balance'] as num).toInt();
      final newBalance = currentBalance + adjustment;

      // Update balance
      return await txn.update(
        'suppliers',
        {'outstanding_balance': newBalance},
        where: 'id = ?',
        whereArgs: [supplierId],
      );
    });
  }

  /// Add payment and update balance transactionally
  Future<void> addPayment(int supplierId, int amount, String notes) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('supplier_payments', {
        'supplier_id': supplierId,
        'amount': amount,
        'payment_date': DateTime.now().toIso8601String(),
        'notes': notes,
      });

      await txn.rawUpdate(
        'UPDATE suppliers SET outstanding_balance = outstanding_balance - ? WHERE id = ?',
        [amount, supplierId]
      );
    });
  }

  /// Get suppliers with outstanding balance
  Future<List<Map<String, dynamic>>> getSuppliersWithBalance() async {
    final db = await _dbHelper.database;
    return await db.query(
      'suppliers',
      where: 'outstanding_balance > 0',
      orderBy: 'outstanding_balance DESC',
    );
  }

  /// Get total outstanding balance to suppliers
  Future<int> getTotalOutstandingBalance() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(outstanding_balance) as total FROM suppliers'
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  // ========================================
  // SUPPLIER STATUS MANAGEMENT
  // ========================================

  /// Activate supplier
  Future<int> activateSupplier(int supplierId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'suppliers',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [supplierId],
    );
  }

  /// Deactivate supplier
  Future<int> deactivateSupplier(int supplierId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'suppliers',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [supplierId],
    );
  }

  /// Toggle supplier active status
  Future<int> toggleSupplierStatus(int supplierId) async {
    final supplier = await getSupplierById(supplierId);
    if (supplier == null) return 0;
    
    final isActive = (supplier['is_active'] as int) == 1;
    return await (isActive 
        ? deactivateSupplier(supplierId)
        : activateSupplier(supplierId));
  }

  // ========================================
  // STATISTICS
  // ========================================

  /// Get total supplier count
  Future<int> getTotalSupplierCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM suppliers');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get active supplier count
  Future<int> getActiveSupplierCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM suppliers WHERE is_active = 1'
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get supplier summary
  Future<Map<String, dynamic>> getSupplierSummary(int supplierId) async {
    final supplier = await getSupplierById(supplierId);
    if (supplier == null) {
      return {
        'error': 'Supplier not found',
      };
    }

    // You can extend this with purchase history, payment history, etc.
    // For now, returning basic info
    return {
      'supplier': supplier,
      'totalBalance': (supplier['outstanding_balance'] as num).toInt(),
      'isActive': (supplier['is_active'] as int) == 1,
      // Add more metrics as needed:
      // 'totalPurchases': ...,
      // 'lastPurchaseDate': ...,
      // 'paymentCount': ...,
    };
  }

  /// Get supplier statistics
  Future<Map<String, dynamic>> getSupplierStats() async {
    final db = await _dbHelper.database;

    final activeRes = await db.rawQuery('SELECT COUNT(*) as count, SUM(outstanding_balance) as total FROM suppliers WHERE is_active = 1');
    final countActive = (activeRes.first['count'] as int?) ?? 0;
    final balActive = (activeRes.first['total'] as num? ?? 0).toInt();

    final archRes = await db.rawQuery('SELECT COUNT(*) as count, SUM(outstanding_balance) as total FROM suppliers WHERE is_active = 0');
    final countArchived = (archRes.first['count'] as int?) ?? 0;
    final balArchived = (archRes.first['total'] as num? ?? 0).toInt();

    return {
      'countTotal': countActive + countArchived,
      'balTotal': balActive + balArchived,
      'countActive': countActive,
      'balActive': balActive,
      'countArchived': countArchived,
      'balArchived': balArchived,
    };
  }

  // ========================================
  // BULK OPERATIONS
  // ========================================

  /// Bulk activate suppliers
  Future<int> bulkActivateSuppliers(List<int> supplierIds) async {
    if (supplierIds.isEmpty) return 0;
    
    final db = await _dbHelper.database;
    final placeholders = List.filled(supplierIds.length, '?').join(',');
    
    return await db.rawUpdate(
      'UPDATE suppliers SET is_active = 1 WHERE id IN ($placeholders)',
      supplierIds,
    );
  }

  /// Bulk deactivate suppliers
  Future<int> bulkDeactivateSuppliers(List<int> supplierIds) async {
    if (supplierIds.isEmpty) return 0;
    
    final db = await _dbHelper.database;
    final placeholders = List.filled(supplierIds.length, '?').join(',');
    
    return await db.rawUpdate(
      'UPDATE suppliers SET is_active = 0 WHERE id IN ($placeholders)',
      supplierIds,
    );
  }

  /// Bulk delete suppliers
  Future<int> bulkDeleteSuppliers(List<int> supplierIds) async {
    if (supplierIds.isEmpty) return 0;
    
    final db = await _dbHelper.database;
    final placeholders = List.filled(supplierIds.length, '?').join(',');
    
    return await db.rawDelete(
      'DELETE FROM suppliers WHERE id IN ($placeholders)',
      supplierIds,
    );
  }

  // ========================================
  // VALIDATION
  // ========================================

  /// Check if supplier name exists
  Future<bool> supplierNameExists(String name, {int? excludeId}) async {
    final db = await _dbHelper.database;
    
    String query = 'SELECT COUNT(*) as count FROM suppliers WHERE name_english = ?';
    List<dynamic> args = [name];
    
    if (excludeId != null) {
      query += ' AND id != ?';
      args.add(excludeId);
    }
    
    final result = await db.rawQuery(query, args);
    final count = (result.first['count'] as int?) ?? 0;
    
    return count > 0;
  }

  /// Check if supplier contact exists
  Future<bool> supplierContactExists(String contact, {int? excludeId}) async {
    final db = await _dbHelper.database;
    
    String query = 'SELECT COUNT(*) as count FROM suppliers WHERE contact_primary = ?';
    List<dynamic> args = [contact];
    
    if (excludeId != null) {
      query += ' AND id != ?';
      args.add(excludeId);
    }
    
    final result = await db.rawQuery(query, args);
    final count = (result.first['count'] as int?) ?? 0;
    
    return count > 0;
  }

  // ========================================
  // FUTURE ENHANCEMENTS (Placeholder)
  // ========================================

  /// Get purchase history for supplier
  Future<List<Map<String, dynamic>>> getSupplierPurchaseHistory(
    int supplierId,
  ) async {
    final db = await _dbHelper.database;
    return await db.query(
      'purchases',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'purchase_date DESC',
    );
  }

  /// Get payment history for supplier
  Future<List<Map<String, dynamic>>> getSupplierPaymentHistory(
    int supplierId,
  ) async {
    final db = await _dbHelper.database;
    return await db.query(
      'supplier_payments',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'payment_date DESC',
    );
  }

  /// Get supplier ledger
  Future<List<Map<String, dynamic>>> getSupplierLedger(int supplierId, {DateTime? startDate, DateTime? endDate}) async {
    final db = await _dbHelper.database;

    // 1. Fetch Purchases (Bills)
    final purchases = await db.rawQuery('''
        SELECT 
          'BILL' as type,
          id as ref_id,
          purchase_date as date,
          invoice_number as bill_no,
          total_amount as cr, -- We owe them (Credit)
          0 as dr,
          'Bill #' || COALESCE(invoice_number, '-') as desc
        FROM purchases 
        WHERE supplier_id = ?
      ''', [supplierId]);

    // 2. Fetch Payments
    final payments = await db.rawQuery('''
        SELECT 
          'PAYMENT' as type,
          id as ref_id,
          payment_date as date,
          'Payment Sent' as bill_no,
          0 as cr,
          amount as dr, -- We paid them (Debit)
          notes as desc
        FROM supplier_payments
        WHERE supplier_id = ?
      ''', [supplierId]);

    // Combine
    List<Map<String, dynamic>> timeline = [...purchases, ...payments];

    // Sort by Date
    timeline.sort((a, b) {
      DateTime dA = DateTime.tryParse(a['date'].toString()) ?? DateTime(1900);
      DateTime dB = DateTime.tryParse(b['date'].toString()) ?? DateTime(1900);
      return dA.compareTo(dB);
    });

    // Calculate Running Balance
    double runningBal = 0.0;
    List<Map<String, dynamic>> finalLedger = [];

    for (var row in timeline) {
      int cr = (row['cr'] as num).toInt(); // Bill
      int dr = (row['dr'] as num).toInt(); // Payment
      runningBal += (cr - dr); // Payable Balance
      if (runningBal < 0) runningBal = 0; // Balance always >= 0

      Map<String, dynamic> newRow = Map.from(row);
      newRow['balance'] = runningBal;
      finalLedger.add(newRow);
    }

    // Filter by date after calculation to preserve running balance
    if (startDate != null || endDate != null) {
      final start = startDate ?? DateTime(1900);
      final end = endDate != null ? DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59) : DateTime(2100);
      finalLedger = finalLedger.where((row) {
        final date = DateTime.tryParse(row['date'].toString()) ?? DateTime.now();
        return date.isAfter(start.subtract(const Duration(seconds: 1))) && date.isBefore(end);
      }).toList();
    }

    return finalLedger.reversed.toList();
  }

  /// Get items for a specific purchase bill
  Future<List<Map<String, dynamic>>> getBillItems(int billId) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
        SELECT 
          pi.quantity,
          pi.cost_price,
          pi.total_amount,
          p.name_english,
          p.name_urdu,
          u.name as unit_name
        FROM purchase_items pi
        LEFT JOIN products p ON pi.product_id = p.id
        LEFT JOIN units u ON p.unit_id = u.id
        WHERE pi.purchase_id = ?
      ''', [billId]);
  }
}