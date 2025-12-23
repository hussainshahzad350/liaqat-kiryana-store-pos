// lib/core/repositories/settings_repository.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';
import '../utils/logger.dart';
import 'package:intl/intl.dart';

class SettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

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
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String backupFileName = 'manual_backup_$timestamp.db';
      final String backupPath = p.join(p.dirname(dbPath), backupFileName);
      
      AppLogger.info('Creating manual backup: $backupPath', tag: 'SettingsRepo');

      // Create backup
      final file = File(dbPath);
      if (await file.exists()) {
        await file.copy(backupPath);
        AppLogger.info('Manual backup created: $backupPath', tag: 'SettingsRepo');
        
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
        final backupFiles = files.whereType<File>()
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
            AppLogger.info('Deleted old backup: ${backupFiles[i].path}', tag: 'SettingsRepo');
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
      
      AppLogger.info('Database restored from: $backupPath', tag: 'SettingsRepo');
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
      AppLogger.error('Error getting total backup storage: $e', tag: 'SettingsRepo');
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
      batch.rawQuery('SELECT COUNT(*) as count FROM sales');
      batch.rawQuery('SELECT COUNT(*) as count FROM sale_items');
      batch.rawQuery('SELECT COUNT(*) as count FROM payments');
      batch.rawQuery('SELECT COUNT(*) as count FROM suppliers');
      batch.rawQuery('SELECT COUNT(*) as count FROM cash_ledger');
      
      final results = await batch.commit();
      
      return {
        'products': (results[0] as List).first['count'] ?? 0,
        'customers': (results[1] as List).first['count'] ?? 0,
        'sales': (results[2] as List).first['count'] ?? 0,
        'saleItems': (results[3] as List).first['count'] ?? 0,
        'payments': (results[4] as List).first['count'] ?? 0,
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
    // TODO: Implement with SharedPreferences
    return {
      'language': 'en',
      'theme': 'light',
      'soundEnabled': true,
      'printOnSale': false,
    };
  }

  Future<void> updateAppPreferences(Map<String, dynamic> preferences) async {
    // TODO: Implement with SharedPreferences
    AppLogger.info('App preferences updated', tag: 'SettingsRepo');
  }
}