// lib/core/repositories/settings_repository.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';
import '../utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SecureStorageException implements Exception {
  final String operation;
  final Object cause;

  const SecureStorageException({
    required this.operation,
    required this.cause,
  });

  @override
  String toString() =>
      'SecureStorageException($operation): ${cause.toString()}';
}

class SettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _legacyPasswordKey = 'app_password';
  static const String _legacyPasswordMigratedKey = 'legacy_password_migrated';
  static bool _restoreInProgress = false;

  // ========================================
  // BACKUP MANAGEMENT
  // ========================================

  bool _isBackupFile(File file) {
    final name = p.basename(file.path);
    return name.endsWith('.backup.db') ||
        RegExp(r'^manual_backup_\d{8}_\d{6}(?:_\d+)?\.db$').hasMatch(name);
  }

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
          if (file is File && _isBackupFile(file)) {
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
    if (maxBackups < 1) {
      throw ArgumentError.value(maxBackups, 'maxBackups', 'Must be at least 1');
    }
    final db = await _dbHelper.database;
    try {
      final String dbPath = db.path;
      final now = DateTime.now();
      final String timestamp =
          '${DateFormat('yyyyMMdd_HHmmss').format(now)}_${now.microsecondsSinceEpoch}';
      final String backupFileName = 'manual_backup_$timestamp.db';
      final String backupPath = p.join(p.dirname(dbPath), backupFileName);

      AppLogger.info('Creating manual backup: $backupPath',
          tag: 'SettingsRepo');

      // SQLite writes a consistent standalone snapshot, including committed
      // WAL data that a direct copy of the main database file would miss.
      final file = File(dbPath);
      if (await file.exists()) {
        await db.execute('VACUUM INTO ?', [backupPath]);
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
        final backupFiles =
            files.whereType<File>().where(_isBackupFile).toList();

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
    if (_restoreInProgress) return false;
    _restoreInProgress = true;
    String? currentDbPath;
    String? emergencyBackup;
    File? stagedBackup;
    var databaseClosed = false;
    try {
      final db = await _dbHelper.database;
      currentDbPath = db.path;
      final sourceFile = File(backupPath);
      if (!await sourceFile.exists() ||
          p.equals(await sourceFile.resolveSymbolicLinks(),
              await File(currentDbPath).resolveSymbolicLinks())) {
        return false;
      }

      final timestamp = DateTime.now().microsecondsSinceEpoch;
      stagedBackup = File('$currentDbPath.restore.$timestamp.tmp');
      final source = await databaseFactory.openDatabase(backupPath,
          options: OpenDatabaseOptions(readOnly: true, singleInstance: false));
      try {
        await _validateRestoreSource(source, db);
        // Snapshot the source first so its WAL is included and the selected
        // backup remains unchanged during restore and any upgrade.
        await source.execute('VACUUM INTO ?', [stagedBackup.path]);
      } finally {
        await source.close();
      }

      emergencyBackup = '$currentDbPath.emergency.$timestamp.bak';
      await db.execute('VACUUM INTO ?', [emergencyBackup]);
      await _dbHelper.close();
      databaseClosed = true;
      await stagedBackup.copy(currentDbPath);
      await _dbHelper.database;

      AppLogger.info('Database restored from: $backupPath',
          tag: 'SettingsRepo');
      return true;
    } catch (e) {
      AppLogger.error('Restore Failed: $e', tag: 'SettingsRepo');
      if (databaseClosed && currentDbPath != null && emergencyBackup != null) {
        try {
          await _dbHelper.close();
          await File(emergencyBackup).copy(currentDbPath);
          await _dbHelper.database;
        } catch (rollbackError) {
          AppLogger.error(
              'Restore rollback failed; emergency backup retained at '
              '$emergencyBackup: $rollbackError',
              tag: 'SettingsRepo');
        }
      }
      return false;
    } finally {
      try {
        if (stagedBackup != null && await stagedBackup.exists()) {
          await stagedBackup.delete();
        }
      } catch (e) {
        AppLogger.error('Restore staging cleanup failed: $e',
            tag: 'SettingsRepo');
      }
      _restoreInProgress = false;
    }
  }

  Future<void> _validateRestoreSource(Database source, Database current) async {
    final integrity = await source.rawQuery('PRAGMA integrity_check');
    if (integrity.length != 1 || integrity.single.values.single != 'ok') {
      throw StateError('Backup integrity check failed');
    }
    final version = await source.getVersion();
    final currentVersion = await current.getVersion();
    if (version < 1 || version > currentVersion) {
      throw StateError('Unsupported backup database version: $version');
    }
    final tables = await current.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'");
    final sourceTables = (await source
            .rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'"))
        .map((row) => row['name'])
        .toSet();
    // Older backups go through the existing upgrade callbacks after replacement.
    // Verify their core tables now; upgrade failures restore the emergency copy.
    final requiredTables = version == currentVersion
        ? tables.map((row) => row['name'] as String)
        : [
            'shop_profile',
            'products',
            'customers',
            'invoices',
            'units',
            'unit_categories'
          ];
    for (final table in requiredTables) {
      if (!sourceTables.contains(table)) {
        throw StateError('Backup is missing table: $table');
      }
      if (version == currentVersion) {
        final quoted = '"${table.replaceAll('"', '""')}"';
        final expected = await current.rawQuery('PRAGMA table_info($quoted)');
        final actual = (await source.rawQuery('PRAGMA table_info($quoted)'))
            .map((row) => row['name'])
            .toSet();
        if (expected.any((column) => !actual.contains(column['name']))) {
          throw StateError('Backup has incompatible columns in: $table');
        }
      }
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

  // ========================================
  // APP PREFERENCES (Future Enhancement)
  // ========================================

  /// These could be stored in SharedPreferences or a settings table
  /// Placeholder methods for future implementation

  /// Throws [SecureStorageException] when secure storage is unavailable while
  /// reading the startup password.
  Future<Map<String, dynamic>> getAppPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyPasswordIfNeeded(prefs);
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
    if (preferences.containsKey('password')) {
      final password = preferences['password'];
      if (password is String && password.trim().isNotEmpty) {
        await _writeAppPassword(password.trim());
      }
    }
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

  Future<void> _migrateLegacyPasswordIfNeeded(SharedPreferences prefs) async {
    final alreadyMigrated = prefs.getBool(_legacyPasswordMigratedKey) ?? false;
    if (alreadyMigrated) return;

    await prefs.remove(_legacyPasswordKey);
    await prefs.setBool(_legacyPasswordMigratedKey, true);
  }

  /// Returns the configured startup password, or `null` when no password is
  /// stored.
  ///
  /// Throws [SecureStorageException] if secure storage cannot be accessed.
  Future<String?> _readAppPassword() async {
    try {
      return await _secureStorage.read(key: 'app_password');
    } on PlatformException catch (e) {
      if (_isExpectedSecureStorageMiss(e)) {
        return null;
      }

      AppLogger.error('Error reading secure app password: $e',
          tag: 'SettingsRepo');
      throw SecureStorageException(operation: 'read', cause: e);
    } on MissingPluginException catch (e) {
      AppLogger.error(
          'Secure storage plugin unavailable while reading app password: $e',
          tag: 'SettingsRepo');
      throw SecureStorageException(operation: 'read', cause: e);
    }
  }

  bool _isExpectedSecureStorageMiss(PlatformException exception) {
    final code = exception.code.toLowerCase();
    final message = (exception.message ?? '').toLowerCase();

    return code.contains('notfound') ||
        code.contains('not_found') ||
        message.contains('not found') ||
        message.contains('no value') ||
        message.contains('does not exist');
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
