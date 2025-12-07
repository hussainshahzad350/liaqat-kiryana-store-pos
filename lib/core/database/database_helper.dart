import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/logger.dart';
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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    
    return await openDatabase(
      path,
      version: 2, // Version بڑھائیں
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await _createTables(db);
    await _insertSampleData(db);
    AppLogger.db('Database created (v$version)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    AppLogger.db('Upgrading database from v$oldVersion to v$newVersion');
    
    if (oldVersion < 2) {
      await _createTables(db);
      await _insertSampleData(db);
    }
  }

  Future<void> _createTables(Database db) async {
    // پہلے موجود ٹیبلز ڈیلیٹ کریں (اگر ہوں)
    await db.execute('DROP TABLE IF EXISTS sale_items');
    await db.execute('DROP TABLE IF EXISTS sales');
    await db.execute('DROP TABLE IF EXISTS products');
    await db.execute('DROP TABLE IF EXISTS customers');
    await db.execute('DROP TABLE IF EXISTS categories');
    await db.execute('DROP TABLE IF EXISTS shop_profile');

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

    // 3. Products (نمونے کے آئٹمز)
    await db.execute('''
      CREATE TABLE products (
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

    // 4. Customers (نمونے کے کسٹمرز)
    await db.execute('''
      CREATE TABLE customers (
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

    // 6. Sale Items
    await db.execute('''
      CREATE TABLE sale_items (
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
    // Shop Profile ڈیٹا
    await db.insert('shop_profile', {
      'shop_name_urdu': 'لیاقت کریانہ اسٹور',
      'shop_name_english': 'Liaqat Kiryana Store',
      'shop_address': 'مین بازار، لاہور',
      'contact_primary': '0300-1234567',
    });

    // Categories ڈیٹا
    await db.insert('categories', {
      'name_urdu': 'چاول',
      'name_english': 'Rice',
    });
    
    await db.insert('categories', {
      'name_urdu': 'دال',
      'name_english': 'Pulses',
    });
    
    await db.insert('categories', {
      'name_urdu': 'تیل',
      'name_english': 'Oil',
    });

    // Products ڈیٹا (Low stock والے)
    await db.insert('products', {
      'item_code': 'PRD001',
      'name_urdu': 'چاول سپر باسمتی',
      'name_english': 'Super Basmati Rice',
      'category_id': 1,
      'unit_type': 'KG',
      'min_stock_alert': 50,
      'current_stock': 45, // کم اسٹاک
      'avg_cost_price': 170,
      'sale_price': 180,
    });
    
    await db.insert('products', {
      'item_code': 'PRD002',
      'name_urdu': 'مسور دال',
      'name_english': 'Masoor Daal',
      'category_id': 2,
      'unit_type': 'KG',
      'min_stock_alert': 20,
      'current_stock': 15, // کم اسٹاک
      'avg_cost_price': 190,
      'sale_price': 200,
    });
    
    await db.insert('products', {
      'item_code': 'PRD003',
      'name_urdu': 'تیل کا ڈبا',
      'name_english': 'Cooking Oil',
      'category_id': 3,
      'unit_type': 'Piece',
      'min_stock_alert': 10,
      'current_stock': 12, // کم اسٹاک
      'avg_cost_price': 310,
      'sale_price': 320,
    });
    
    await db.insert('products', {
      'item_code': 'PRD004',
      'name_urdu': 'چنی دال',
      'name_english': 'Chana Daal',
      'category_id': 2,
      'unit_type': 'KG',
      'min_stock_alert': 15,
      'current_stock': 8, // کم اسٹاک
      'avg_cost_price': 150,
      'sale_price': 160,
    });
    
    await db.insert('products', {
      'item_code': 'PRD005',
      'name_urdu': 'گھی',
      'name_english': 'Ghee',
      'category_id': 3,
      'unit_type': 'KG',
      'min_stock_alert': 5,
      'current_stock': 3, // کم اسٹاک
      'avg_cost_price': 820,
      'sale_price': 850,
    });
    
    // Normal stock والے products
    await db.insert('products', {
      'item_code': 'PRD006',
      'name_urdu': 'چینی',
      'name_english': 'Sugar',
      'category_id': 1,
      'unit_type': 'KG',
      'min_stock_alert': 30,
      'current_stock': 65,
      'avg_cost_price': 90,
      'sale_price': 100,
    });

    // Customers ڈیٹا
    await db.insert('customers', {
      'name_english': 'Ali Khan',
      'name_urdu': 'علی خان',
      'contact_primary': '0300-1111111',
      'credit_limit': 10000,
      'outstanding_balance': 2500,
    });
    
    await db.insert('customers', {
      'name_english': 'Sami Ahmed',
      'name_urdu': 'سامی احمد',
      'contact_primary': '0321-2222222',
      'credit_limit': 5000,
      'outstanding_balance': 1200,
    });
    
    await db.insert('customers', {
      'name_english': 'Bilal Hassan',
      'name_urdu': 'بلال حسن',
      'contact_primary': '0333-3333333',
      'credit_limit': 8000,
      'outstanding_balance': 0,
    });
    
    await db.insert('customers', {
      'name_english': 'Cash Customer',
      'name_urdu': 'کیش گاہک',
      'credit_limit': 0,
      'outstanding_balance': 0,
    });

    // آج کی Sales ڈیٹا
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Sale 1
    await db.insert('sales', {
      'bill_number': 'SALE-1001',
      'customer_id': 1, // علی خان
      'sale_date': today,
      'sale_time': '10:30',
      'grand_total': 1800,
      'cash_amount': 1000,
      'credit_amount': 800,
      'total_paid': 1000,
      'remaining_balance': 800,
    });
    
    // Sale 2
    await db.insert('sales', {
      'bill_number': 'SALE-1002',
      'customer_id': 2, // سامی احمد
      'sale_date': today,
      'sale_time': '11:15',
      'grand_total': 2500,
      'cash_amount': 2500,
      'total_paid': 2500,
      'remaining_balance': 0,
    });
    
    // Sale 3
    await db.insert('sales', {
      'bill_number': 'SALE-1003',
      'customer_id': 4, // کیش گاہک
      'sale_date': today,
      'sale_time': '11:45',
      'grand_total': 1200,
      'cash_amount': 1200,
      'total_paid': 1200,
      'remaining_balance': 0,
    });
    
    // Sale 4
    await db.insert('sales', {
      'bill_number': 'SALE-1004',
      'customer_id': 3, // بلال حسن
      'sale_date': today,
      'sale_time': '12:30',
      'grand_total': 3200,
      'cash_amount': 2000,
      'bank_amount': 1200,
      'total_paid': 3200,
      'remaining_balance': 0,
    });
    
    // Sale 5
    await db.insert('sales', {
      'bill_number': 'SALE-1005',
      'customer_id': 1, // علی خان
      'sale_date': today,
      'sale_time': '14:00',
      'grand_total': 1500,
      'cash_amount': 1500,
      'total_paid': 1500,
      'remaining_balance': 0,
    });

    AppLogger.db('Sample data inserted successfully');
  }

  // Get today's sales total
  Future<double> getTodaySales() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      'SELECT SUM(grand_total) as total FROM sales WHERE date(sale_date) = ?',
      [today]
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get today's customers with amounts
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

  // Get low stock items
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

  // Get recent sales
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
    print('Error getting customers: $e');
    return [];
  }
}

Future<void> addCustomer(Map<String, dynamic> customer) async {
  try {
    final db = await database;
    await db.insert('customers', customer);
  } catch (e) {
    print('Error adding customer: $e');
    rethrow;
  }
}


  // Get total customers count
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