// lib/core/database/database_helper.dart - مکمل Fixed
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/logger.dart';
import 'dart:io' show Platform;
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
    // ✅ Desktop کے لیے path مختلف ہوتا ہے
    String dbPath;
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop: current directory میں database folder بنائیں
      dbPath = await databaseFactoryFfi.getDatabasesPath();
    } else {
      // Mobile
      dbPath = await getDatabasesPath();
    }
    
    final path = join(dbPath, filePath);
    
    AppLogger.db('📂 Database path: $path');
    
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await _createTables(db);
    await _insertSampleData(db);
    AppLogger.db('✅ Database created (v$version)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    AppLogger.db('🔄 Upgrading database from v$oldVersion to v$newVersion');
    
    if (oldVersion < 3) {
      // Drop all tables and recreate
      await db.execute('DROP TABLE IF EXISTS sale_items');
      await db.execute('DROP TABLE IF EXISTS sales');
      await db.execute('DROP TABLE IF EXISTS products');
      await db.execute('DROP TABLE IF EXISTS customers');
      await db.execute('DROP TABLE IF EXISTS suppliers');
      await db.execute('DROP TABLE IF EXISTS categories');
      await db.execute('DROP TABLE IF EXISTS shop_profile');
      
      await _createTables(db);
      await _insertSampleData(db);
    }
  }

  Future<void> _createTables(Database db) async {
    // 1. Shop Profile
    await db.execute('''
      CREATE TABLE shop_profile (
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
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_urdu TEXT NOT NULL,
        name_english TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 3. Products
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_code TEXT UNIQUE,
        name_urdu TEXT NOT NULL,
        name_english TEXT NOT NULL,
        category_id INTEGER,
        unit_type TEXT DEFAULT 'KG',
        min_stock_alert REAL DEFAULT 10,
        current_stock REAL DEFAULT 0,
        avg_cost_price REAL DEFAULT 0,
        sale_price REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 4. Customers
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_english TEXT NOT NULL,
        name_urdu TEXT,
        contact_primary TEXT,
        address TEXT,
        credit_limit REAL DEFAULT 0,
        outstanding_balance REAL DEFAULT 0,
        total_purchases REAL DEFAULT 0,
        total_payments REAL DEFAULT 0,
        last_sale_date TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 5. Suppliers
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_english TEXT NOT NULL,
        name_urdu TEXT,
        contact_primary TEXT,
        address TEXT,
        outstanding_balance REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 6. Sales
    await db.execute('''
      CREATE TABLE sales (
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

    // 7. Sale Items
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity_sold REAL NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (sale_id) REFERENCES sales (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    AppLogger.db('✅ All tables created');
  }

  Future<void> _insertSampleData(Database db) async {
    try {
      // Shop Profile
      await db.insert('shop_profile', {
        'shop_name_urdu': 'لیاقت کریانہ اسٹور',
        'shop_name_english': 'Liaqat Kiryana Store',
        'shop_address': 'مین بازار، لاہور',
        'contact_primary': '0300-1234567',
      });

      // Categories
      final categories = [
        {'name_urdu': 'چاول', 'name_english': 'Rice'},
        {'name_urdu': 'دال', 'name_english': 'Pulses'},
        {'name_urdu': 'تیل', 'name_english': 'Oil'},
        {'name_urdu': 'مصالحے', 'name_english': 'Spices'},
      ];
      
      for (var cat in categories) {
        await db.insert('categories', cat);
      }

      // Products
      final products = [
        {
          'item_code': 'PRD001',
          'name_urdu': 'چاول سپر باسمتی',
          'name_english': 'Super Basmati Rice',
          'category_id': 1,
          'unit_type': 'KG',
          'min_stock_alert': 50.0,
          'current_stock': 45.0,
          'avg_cost_price': 170.0,
          'sale_price': 180.0,
          'is_active': 1,
        },
        {
          'item_code': 'PRD002',
          'name_urdu': 'مسور دال',
          'name_english': 'Masoor Daal',
          'category_id': 2,
          'unit_type': 'KG',
          'min_stock_alert': 20.0,
          'current_stock': 15.0,
          'avg_cost_price': 190.0,
          'sale_price': 200.0,
          'is_active': 1,
        },
        {
          'item_code': 'PRD003',
          'name_urdu': 'کھانے کا تیل',
          'name_english': 'Cooking Oil',
          'category_id': 3,
          'unit_type': 'Liter',
          'min_stock_alert': 10.0,
          'current_stock': 12.0,
          'avg_cost_price': 310.0,
          'sale_price': 320.0,
          'is_active': 1,
        },
        {
          'item_code': 'PRD004',
          'name_urdu': 'چنا دال',
          'name_english': 'Chana Daal',
          'category_id': 2,
          'unit_type': 'KG',
          'min_stock_alert': 15.0,
          'current_stock': 8.0,
          'avg_cost_price': 150.0,
          'sale_price': 160.0,
          'is_active': 1,
        },
        {
          'item_code': 'PRD005',
          'name_urdu': 'دیسی گھی',
          'name_english': 'Desi Ghee',
          'category_id': 3,
          'unit_type': 'KG',
          'min_stock_alert': 5.0,
          'current_stock': 3.0,
          'avg_cost_price': 820.0,
          'sale_price': 850.0,
          'is_active': 1,
        },
      ];

      for (var product in products) {
        await db.insert('products', product);
      }

      // Customers
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final customers = [
        {
          'name_english': 'Ali Khan',
          'name_urdu': 'علی خان',
          'contact_primary': '0300-1111111',
          'credit_limit': 10000.0,
          'outstanding_balance': 2500.0,
          'total_purchases': 15000.0,
          'last_sale_date': today,
          'is_active': 1,
        },
        {
          'name_english': 'Sami Ahmed',
          'name_urdu': 'سامی احمد',
          'contact_primary': '0321-2222222',
          'credit_limit': 5000.0,
          'outstanding_balance': 1200.0,
          'total_purchases': 8000.0,
          'last_sale_date': today,
          'is_active': 1,
        },
        {
          'name_english': 'Cash Customer',
          'name_urdu': 'کیش گاہک',
          'credit_limit': 0.0,
          'outstanding_balance': 0.0,
          'is_active': 1,
        },
      ];

      for (var customer in customers) {
        await db.insert('customers', customer);
      }

      // Sample Sales
      final sales = [
        {
          'bill_number': 'SALE-1001',
          'customer_id': 1,
          'sale_date': today,
          'sale_time': '10:30',
          'grand_total': 1800.0,
          'cash_amount': 1000.0,
          'credit_amount': 800.0,
          'total_paid': 1000.0,
          'remaining_balance': 800.0,
        },
        {
          'bill_number': 'SALE-1002',
          'customer_id': 2,
          'sale_date': today,
          'sale_time': '11:15',
          'grand_total': 2500.0,
          'cash_amount': 2500.0,
          'total_paid': 2500.0,
          'remaining_balance': 0.0,
        },
      ];

      for (var sale in sales) {
        await db.insert('sales', sale);
      }

      AppLogger.db('✅ Sample data inserted');
    } catch (e) {
      AppLogger.error('❌ Error inserting sample data: $e');
    }
  }

  // ✅ Helper Methods
  Future<double> getTodaySales() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      'SELECT SUM(grand_total) as total FROM sales WHERE date(sale_date) = ?',
      [today]
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
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

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}