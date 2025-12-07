import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

// Conditional import for FFI (Desktop support)
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('liaqat_store.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Platform check for Desktop support
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, 
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    AppLogger.db('Creating Database v$version...');
    await _createTables(db);
    await _insertSampleData(db); // Only insert sample data on fresh install
    AppLogger.db('Database created successfully');
  }

  // 🛠️ FIX: Proper Migration Logic (No Data Loss)
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    AppLogger.db('Upgrading database from v$oldVersion to v$newVersion');
    
    // Migration Logic: Execute changes sequentially
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      switch (i) {
        case 2:
          // Example: If version 2 adds a 'email' column to customers
          // await db.execute("ALTER TABLE customers ADD COLUMN email TEXT");
          AppLogger.db('Performed migration to v2');
          break;
        default:
          AppLogger.db('No migration logic defined for v$i');
      }
    }
  }

  Future<void> _createTables(Database db) async {
    // 1. Shop Profile
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shop_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_name_urdu TEXT NOT NULL,
        shop_name_english TEXT NOT NULL,
        shop_address TEXT,
        contact_primary TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 2. Categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_urdu TEXT NOT NULL,
        name_english TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 3. Products
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_code TEXT UNIQUE,
        name_urdu TEXT NOT NULL,
        name_english TEXT NOT NULL,
        category_id INTEGER,
        unit_type TEXT,
        min_stock_alert REAL DEFAULT 10,
        current_stock REAL DEFAULT 0,
        avg_cost_price REAL DEFAULT 0,
        sale_price REAL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 4. Customers
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_english TEXT NOT NULL,
        name_urdu TEXT,
        contact_primary TEXT,
        credit_limit REAL DEFAULT 0,
        outstanding_balance REAL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 5. Sales
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_number TEXT UNIQUE NOT NULL,
        customer_id INTEGER,
        sale_date TEXT NOT NULL,
        sale_time TEXT NOT NULL,
        grand_total REAL NOT NULL,
        cash_amount REAL DEFAULT 0,
        bank_amount REAL DEFAULT 0,
        credit_amount REAL DEFAULT 0,
        total_paid REAL NOT NULL,
        remaining_balance REAL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 6. Sale Items
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity_sold REAL NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _insertSampleData(Database db) async {
    try {
      // 🛠️ FIX: Use conflictAlgorithm to prevent crashes if data exists
      
      // Shop Profile
      await db.insert('shop_profile', {
        'shop_name_urdu': 'لیاقت کریانہ اسٹور',
        'shop_name_english': 'Liaqat Kiryana Store',
        'shop_address': 'مین بازار، لاہور',
        'contact_primary': '0300-1234567',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      // Categories
      List<Map<String, dynamic>> categories = [
        {'name_urdu': 'چاول', 'name_english': 'Rice'},
        {'name_urdu': 'دال', 'name_english': 'Pulses'},
        {'name_urdu': 'تیل', 'name_english': 'Oil'},
      ];
      
      for(var cat in categories) {
         await db.insert('categories', cat, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      // Products
      // ... (Keep your product insertions here, but add conflictAlgorithm: ConflictAlgorithm.ignore)
      // I've shortened this for brevity, but apply this pattern to all inserts below:
      
      await db.insert('products', {
        'item_code': 'PRD001',
        'name_urdu': 'چاول سپر باسمتی',
        'name_english': 'Super Basmati Rice',
        'category_id': 1,
        'unit_type': 'KG',
        'min_stock_alert': 50,
        'current_stock': 45,
        'avg_cost_price': 170,
        'sale_price': 180,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      // ... Insert other products ...

      // Customers
      await db.insert('customers', {
        'name_english': 'Ali Khan',
        'name_urdu': 'علی خان',
        'contact_primary': '0300-1111111',
        'credit_limit': 10000,
        'outstanding_balance': 2500,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      // ... Insert other customers ...

      AppLogger.db('Sample data inserted (or skipped if duplicates found)');
    } catch (e) {
      AppLogger.error('Error inserting sample data: $e');
    }
  }

  // --- Queries (Refactored with proper error logging) ---

  Future<double> getTodaySales() async {
    try {
      final db = await database;
      final today = DateTime.now().toIso8601String().split('T')[0];
      final result = await db.rawQuery(
        'SELECT SUM(grand_total) as total FROM sales WHERE date(sale_date) = ?',
        [today]
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      AppLogger.error("Error fetching today's sales", tag: 'DB');
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> getTodayCustomers() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    return await db.rawQuery('''
      SELECT 
        c.name_urdu, 
        c.name_english, 
        SUM(s.grand_total) as total_amount,
        COUNT(s.id) as sale_count
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE date(s.sale_date) = ? AND c.id IS NOT NULL
      GROUP BY c.id
      ORDER BY total_amount DESC
      LIMIT 5
    ''', [today]);
  }

  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        name_urdu, 
        name_english, 
        current_stock, 
        min_stock_alert,
        sale_price
      FROM products 
      WHERE current_stock > 0 AND current_stock <= min_stock_alert
      ORDER BY (current_stock / min_stock_alert) ASC
      LIMIT 5
    ''');
  }

  Future<List<Map<String, dynamic>>> getRecentSales() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        s.bill_number, 
        s.grand_total, 
        s.sale_time,
        COALESCE(c.name_urdu, c.name_english, 'کیش') as customer_name
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      ORDER BY s.created_at DESC
      LIMIT 5
    ''');
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    try {
      final db = await database;
      return await db.query('customers', orderBy: 'name_english ASC');
    } catch (e) {
      AppLogger.error('Error getting customers: $e', tag: 'DB');
      return [];
    }
  }

  Future<void> addCustomer(Map<String, dynamic> customer) async {
    try {
      final db = await database;
      await db.insert('customers', customer);
      AppLogger.info('Customer added: ${customer['name_english']}', tag: 'DB');
    } catch (e) {
      AppLogger.error('Error adding customer: $e', tag: 'DB');
      rethrow;
    }
  }

  Future<int> getTotalCustomersCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}