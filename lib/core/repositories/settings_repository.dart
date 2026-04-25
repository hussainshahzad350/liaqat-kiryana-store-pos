// lib/core/repositories/settings_repository.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';
import '../utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // ========================================
  // BACKUP MANAGEMENT
  // ========================================

  /// Get list of all backup files
  /// Moved from DatabaseHelper.getBackupFiles()
  Future<List<Map<String, dynamic>>> getBackupFiles() async {
    try {
      final db = await _dbHelper.database;
      final String dbPath = db.path;
      final String dbDir = p.dirname(dbPath);
      final Directory dir = Directory(dbDir);

      List<Map<String, dynamic>> backups = [];

      if (await dir.exists()) {
        final files = await dir.list().toList();

        for (var file in files) {
          if (file is File && file.path.contains('.backup.db')) {
            final stat = await file.stat();
            backups.add({
              'path': file.path,
              'name': p.basename(file.path),
              'size': stat.size,
              'modified': stat.modified,
            });
          }
        }

        // Sort by modified date (newest first)
        backups.sort((a, b) => b['modified'].compareTo(a['modified']));
      }

      return backups;
    } catch (e) {
      AppLogger.error('Error getting backup files: $e', tag: 'SettingsRepo');
      return [];
    }
  }

  /// Create manual backup
  /// Moved from DatabaseHelper.createManualBackup()
  Future<String?> createManualBackup([int maxBackups = 5]) async {
    final db = await _dbHelper.database;
    try {
      final String dbPath = db.path;
      final String timestamp =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String backupFileName = 'manual_backup_$timestamp.db';
      final String backupPath = p.join(p.dirname(dbPath), backupFileName);

      AppLogger.info('Creating manual backup: $backupPath',
          tag: 'SettingsRepo');

      // Create backup
      final file = File(dbPath);
      if (await file.exists()) {
        await file.copy(backupPath);
        AppLogger.info('Manual backup created: $backupPath',
            tag: 'SettingsRepo');

        // Clean old backups
        await _cleanOldBackups(Directory(p.dirname(dbPath)), maxBackups);

        return backupPath;
      }
    } catch (e) {
      AppLogger.error('Manual Backup Failed: $e', tag: 'SettingsRepo');
    }
    return null;
  }

  /// Clean old backup files
  Future<void> _cleanOldBackups(Directory backupDir, int maxBackups) async {
    try {
      if (await backupDir.exists()) {
        final files = await backupDir.list().toList();
        final backupFiles = files
            .whereType<File>()
            .where((file) => file.path.contains('.backup.db'))
            .toList();

        // Sort by modified date (oldest first)
        backupFiles.sort((a, b) {
          final aStat = a.statSync();
          final bStat = b.statSync();
          return aStat.modified.compareTo(bStat.modified);
        });

        // Delete oldest files if exceeding maxBackups
        if (backupFiles.length > maxBackups) {
          for (int i = 0; i < backupFiles.length - maxBackups; i++) {
            await backupFiles[i].delete();
            AppLogger.info('Deleted old backup: ${backupFiles[i].path}',
                tag: 'SettingsRepo');
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error cleaning old backups: $e', tag: 'SettingsRepo');
    }
  }

  /// Restore database from backup
  /// Moved from DatabaseHelper.restoreBackup()
  Future<bool> restoreBackup(String backupPath) async {
    try {
      final db = await _dbHelper.database;
      final String currentDbPath = db.path;

      // 1. Close current database
      await db.close();

      // 2. Backup current database first (emergency backup)
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String emergencyBackup = '$currentDbPath.emergency.$timestamp.bak';
      await File(currentDbPath).copy(emergencyBackup);

      // 3. Copy backup file over current database
      await File(backupPath).copy(currentDbPath);

      // 4. Re-open database
      // Note: You'll need to handle database reinitialization in your app

      AppLogger.info('Database restored from: $backupPath',
          tag: 'SettingsRepo');
      return true;
    } catch (e) {
      AppLogger.error('Restore Failed: $e', tag: 'SettingsRepo');
      return false;
    }
  }

  /// Delete a backup file
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        AppLogger.info('Backup deleted: $backupPath', tag: 'SettingsRepo');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error deleting backup: $e', tag: 'SettingsRepo');
      return false;
    }
  }

  /// Get backup file size in MB
  Future<double> getBackupSize(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size / (1024 * 1024); // Convert to MB
      }
      return 0.0;
    } catch (e) {
      AppLogger.error('Error getting backup size: $e', tag: 'SettingsRepo');
      return 0.0;
    }
  }

  /// Get total backup storage used
  Future<double> getTotalBackupStorage() async {
    try {
      final backups = await getBackupFiles();
      double total = 0.0;

      for (var backup in backups) {
        final size = backup['size'] as int;
        total += size;
      }

      return total / (1024 * 1024); // Convert to MB
    } catch (e) {
      AppLogger.error('Error getting total backup storage: $e',
          tag: 'SettingsRepo');
      return 0.0;
    }
  }

  // ========================================
  // SHOP PROFILE
  // ========================================

  /// Get shop profile
  Future<Map<String, dynamic>?> getShopProfile() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query('shop_profile', limit: 1);

      if (result.isEmpty) return null;
      return result.first;
    } catch (e) {
      AppLogger.error('Error getting shop profile: $e', tag: 'SettingsRepo');
      return null;
    }
  }

  /// Update shop profile
  Future<int> updateShopProfile(Map<String, dynamic> data) async {
    try {
      final db = await _dbHelper.database;

      // Check if profile exists
      final existing = await db.query('shop_profile', limit: 1);

      if (existing.isEmpty) {
        // Insert new profile
        return await db.insert('shop_profile', data);
      } else {
        // Update existing profile
        return await db.update(
          'shop_profile',
          data,
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      }
    } catch (e) {
      AppLogger.error('Error updating shop profile: $e', tag: 'SettingsRepo');
      return 0;
    }
  }

  // ========================================
  // DATABASE MAINTENANCE
  // ========================================

  /// Get database size in MB
  Future<double> getDatabaseSize() async {
    try {
      final db = await _dbHelper.database;
      final file = File(db.path);

      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size / (1024 * 1024); // Convert to MB
      }
      return 0.0;
    } catch (e) {
      AppLogger.error('Error getting database size: $e', tag: 'SettingsRepo');
      return 0.0;
    }
  }

  /// Vacuum database (optimize and compact)
  Future<bool> vacuumDatabase() async {
    try {
      final db = await _dbHelper.database;
      await db.execute('VACUUM');
      AppLogger.info('Database vacuumed successfully', tag: 'SettingsRepo');
      return true;
    } catch (e) {
      AppLogger.error('Error vacuuming database: $e', tag: 'SettingsRepo');
      return false;
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();

      // Count records in each table
      batch.rawQuery('SELECT COUNT(*) as count FROM products');
      batch.rawQuery('SELECT COUNT(*) as count FROM customers');
      batch.rawQuery('SELECT COUNT(*) as count FROM invoices');
      batch.rawQuery('SELECT COUNT(*) as count FROM invoice_items');
      batch.rawQuery('SELECT COUNT(*) as count FROM receipts');
      batch.rawQuery('SELECT COUNT(*) as count FROM suppliers');
      batch.rawQuery('SELECT COUNT(*) as count FROM cash_ledger');

      final results = await batch.commit();

      return {
        'products': (results[0] as List).first['count'] ?? 0,
        'customers': (results[1] as List).first['count'] ?? 0,
        'invoices': (results[2] as List).first['count'] ?? 0,
        'invoiceItems': (results[3] as List).first['count'] ?? 0,
        'receipts': (results[4] as List).first['count'] ?? 0,
        'suppliers': (results[5] as List).first['count'] ?? 0,
        'cashLedger': (results[6] as List).first['count'] ?? 0,
        'databaseSize': await getDatabaseSize(),
      };
    } catch (e) {
      AppLogger.error('Error getting database stats: $e', tag: 'SettingsRepo');
      return {};
    }
  }

  // ========================================
  // DATA EXPORT
  // ========================================

  /// Export data to CSV (placeholder - implement based on requirements)
  Future<String?> exportToCSV(String tableName) async {
    try {
      final db = await _dbHelper.database;
      final data = await db.query(tableName);

      if (data.isEmpty) return null;

      // Create CSV content
      final keys = data.first.keys.toList();
      final csv = StringBuffer();

      // Header
      csv.writeln(keys.join(','));

      // Data rows
      for (var row in data) {
        final values = keys.map((key) => row[key]?.toString() ?? '').toList();
        csv.writeln(values.join(','));
      }

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = p.join(directory.path, '${tableName}_$timestamp.csv');

      final file = File(filePath);
      await file.writeAsString(csv.toString());

      AppLogger.info('Data exported to: $filePath', tag: 'SettingsRepo');
      return filePath;
    } catch (e) {
      AppLogger.error('Error exporting to CSV: $e', tag: 'SettingsRepo');
      return null;
    }
  }

  // ========================================
  // CATEGORIES & UNITS MANAGEMENT
  // ========================================

  /// Get all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await _dbHelper.database;
    return await db.query('categories', orderBy: 'name_english ASC');
  }

  /// Add category
  Future<int> addCategory(Map<String, dynamic> data) async {
    final db = await _dbHelper.database;
    return await db.insert('categories', data);
  }

  /// Update category
  Future<int> updateCategory(int id, Map<String, dynamic> data) async {
    final db = await _dbHelper.database;
    return await db.update(
      'categories',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete category
  Future<int> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get expense categories
  Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    final db = await _dbHelper.database;
    return await db.query('expense_categories', orderBy: 'name_english ASC');
  }

  /// Add expense category
  Future<int> addExpenseCategory(Map<String, dynamic> data) async {
    final db = await _dbHelper.database;
    return await db.insert('expense_categories', data);
  }

  // ========================================
  // APP PREFERENCES (Future Enhancement)
  // ========================================

  /// These could be stored in SharedPreferences or a settings table
  /// Placeholder methods for future implementation

  Future<Map<String, dynamic>> getAppPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final password = await _readAppPassword();
    return {
      'language': prefs.getString('app_language') ?? 'en',
      'theme': prefs.getString('app_theme') ?? 'green',
      'themeMode': prefs.getString('app_theme_mode') ?? 'system',
      'dateFormat': prefs.getString('date_format') ?? 'DD-MM-YYYY',
      'currencySymbol': prefs.getString('currency_symbol') ?? 'Rs',
      'currencyPosition': prefs.getString('currency_position') ?? 'before',
      'requirePassword': prefs.getBool('require_password') ?? false,
      'password': password,
      'autoBackupEnabled': prefs.getBool('auto_backup_enabled') ?? false,
      'backupFrequency': prefs.getString('backup_frequency') ?? 'Daily',
      'lowStockAlert': prefs.getBool('low_stock_alert') ?? true,
      'dayCloseReminder': prefs.getBool('day_close_reminder') ?? true,
      'soundEnabled': prefs.getBool('soundEnabled') ?? true,
      'printOnSale': prefs.getBool('printOnSale') ?? false,
      // Receipt Options (Normalized to lowercase to match UI keys)
      'showLogo': prefs.getBool('receipt_show_logo') ?? true,
      'showAddress': prefs.getBool('receipt_show_address') ?? true,
      'showPhone': prefs.getBool('receipt_show_phone') ?? true,
      'showDateTime': prefs.getBool('receipt_show_datetime') ?? true,
      'showCustomer': prefs.getBool('receipt_show_customer') ?? true,
      'showPayment': prefs.getBool('receipt_show_payment') ?? true,
      'receiptFontSize':
          (prefs.getString('receipt_font_size') ?? 'medium').toLowerCase(),
      'paperWidth': prefs.getString('receipt_paper_width') ?? '80mm',
      'printerType':
          (prefs.getString('receipt_printer_type') ?? 'usb').toLowerCase(),
    };
  }

  Future<void> updateAppPreferences(Map<String, dynamic> preferences) async {
    final prefs = await SharedPreferences.getInstance();

    await _setStringIf(preferences, prefs, 'language', 'app_language');
    await _setStringIf(preferences, prefs, 'theme', 'app_theme');
    await _setStringIf(preferences, prefs, 'themeMode', 'app_theme_mode');
    await _setStringIf(preferences, prefs, 'dateFormat', 'date_format');
    await _setStringIf(preferences, prefs, 'currencySymbol', 'currency_symbol');
    await _setStringIf(
        preferences, prefs, 'currencyPosition', 'currency_position');
    await _setBoolIf(preferences, prefs, 'requirePassword', 'require_password');
    await _writeAppPassword(preferences['password']);
    await prefs.remove('app_password');
    await _setBoolIf(
        preferences, prefs, 'autoBackupEnabled', 'auto_backup_enabled');
    await _setStringIf(
        preferences, prefs, 'backupFrequency', 'backup_frequency');
    await _setBoolIf(preferences, prefs, 'lowStockAlert', 'low_stock_alert');
    await _setBoolIf(
        preferences, prefs, 'dayCloseReminder', 'day_close_reminder');
    await _setBoolIf(preferences, prefs, 'soundEnabled', 'soundEnabled');
    await _setBoolIf(preferences, prefs, 'printOnSale', 'printOnSale');

    // Receipt Options
    await _setBoolIf(preferences, prefs, 'showLogo', 'receipt_show_logo');
    await _setBoolIf(preferences, prefs, 'showAddress', 'receipt_show_address');
    await _setBoolIf(preferences, prefs, 'showPhone', 'receipt_show_phone');
    await _setBoolIf(
        preferences, prefs, 'showDateTime', 'receipt_show_datetime');
    await _setBoolIf(
        preferences, prefs, 'showCustomer', 'receipt_show_customer');
    await _setBoolIf(preferences, prefs, 'showPayment', 'receipt_show_payment');
    await _setStringIf(
        preferences, prefs, 'receiptFontSize', 'receipt_font_size');
    await _setStringIf(preferences, prefs, 'paperWidth', 'receipt_paper_width');
    await _setStringIf(
        preferences, prefs, 'printerType', 'receipt_printer_type');

    AppLogger.info('App preferences updated', tag: 'SettingsRepo');
  }

  Future<void> _setStringIf(
    Map<String, dynamic> preferences,
    SharedPreferences prefs,
    String sourceKey,
    String storageKey,
  ) async {
    if (!preferences.containsKey(sourceKey)) return;
    final value = preferences[sourceKey];
    if (value is String) {
      await prefs.setString(storageKey, value);
    }
  }

  Future<void> _setBoolIf(
    Map<String, dynamic> preferences,
    SharedPreferences prefs,
    String sourceKey,
    String storageKey,
  ) async {
    if (!preferences.containsKey(sourceKey)) return;
    final value = preferences[sourceKey];
    if (value is bool) {
      await prefs.setBool(storageKey, value);
    }
  }

  Future<String> _readAppPassword() async {
    try {
      return await _secureStorage.read(key: 'app_password') ?? '';
    } catch (e) {
      AppLogger.error('Error reading secure app password: $e',
          tag: 'SettingsRepo');
      return '';
    }
  }

  Future<void> _writeAppPassword(dynamic value) async {
    if (value is! String) return;

    try {
      await _secureStorage.write(key: 'app_password', value: value);
    } catch (e) {
      AppLogger.error('Error writing secure app password: $e',
          tag: 'SettingsRepo');
    }
  }
}
