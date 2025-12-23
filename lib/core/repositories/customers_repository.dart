// lib/core/repositories/customers_repository.dart
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../utils/logger.dart';

class CustomersRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Fetch all customers.
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    try {
      final db = await _dbHelper.database;
      final customers = await db.query('customers', orderBy: 'name_english ASC');
      return customers;
    } catch (e) {
      AppLogger.error('Error fetching all customers: $e', tag: 'CustomersRepo');
      return [];
    }
  }

  /// Add a new customer.
  Future<int> addCustomer(Map<String, dynamic> customerData) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert('customers', customerData, conflictAlgorithm: ConflictAlgorithm.replace);
      return id;
    } catch (e) {
      AppLogger.error('Error adding customer: $e', tag: 'CustomersRepo');
      return 0;
    }
  }

  /// Check if a customer exists with a given phone number.
  Future<bool> customerExistsByPhone(String phone) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'customers',
        where: 'contact_primary = ?',
        whereArgs: [phone],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      AppLogger.error('Error checking customer existence by phone: $e', tag: 'CustomersRepo');
      return false; // Assume not exists on error
    }
  }

  /// Update the credit limit for a specific customer.
  Future<int> updateCustomerCreditLimit(int customerId, double newCreditLimit) async {
    try {
      final db = await _dbHelper.database;
      return await db.update(
        'customers',
        {'credit_limit': newCreditLimit},
        where: 'id = ?',
        whereArgs: [customerId],
      );
    } catch (e) {
      AppLogger.error('Error updating credit limit for customer $customerId: $e', tag: 'CustomersRepo');
      return 0;
    }
  }
}
