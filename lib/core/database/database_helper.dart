// lib/core/database/database_helper.dart
import 'dart:io';
import 'package:path/path.dart';
import '../utils/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart'; //

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

    // Version 2 ensures migration logic runs if upgrading from a v1 schema
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

  // 🛠️ Proper Migration Logic with Auto-Backup
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    AppLogger.db('Upgrading database from v$oldVersion to v$newVersion');

    // FIX: Auto-Backup before critical migration
    await _backupDatabase(db, oldVersion);
    
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      switch (i) {
        case 2:
          // ADDED: Columns needed for v2 features (e.g., reports, discounts)
          if (!await _columnExists(db, 'customers', 'email')) {
             await db.execute("ALTER TABLE customers ADD COLUMN email TEXT");
          }
          if (!await _columnExists(db, 'sales', 'discount')) {
             await db.execute("ALTER TABLE sales ADD COLUMN discount REAL DEFAULT 0");
          }
          AppLogger.db('Performed migration to v2');
          break;
        default:
          AppLogger.db('No migration logic defined for v$i');
      }
    }
  }

  // Helper: Creates a backup file like 'liaqat_store.db.v1.bak'
  Future<void> _backupDatabase(Database db, int version) async {
    try {
      final String dbPath = db.path;
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String backupPath = '$dbPath.v$version.$timestamp.bak';
      
      AppLogger.db('Attempting database backup to: $backupPath');

      // Strategy 1: SQLite Native Backup (Best for open databases)
      // VACUUM INTO creates a transaction-safe copy.
      try {
        await db.execute('VACUUM INTO ?', [backupPath]);
        AppLogger.info('Database backup created successfully (VACUUM)', tag: 'DB');
        return;
      } catch (e) {
        AppLogger.info('VACUUM INTO not supported or failed ($e). Switching to File Copy strategy.', tag: 'DB');
      }

      // Strategy 2: File Copy Fallback
      // Works if the database file is not exclusively locked by the OS.
      final file = File(dbPath);
      if (await file.exists()) {
        await file.copy(backupPath);
        AppLogger.info('Database backup created successfully (File Copy)', tag: 'DB');
      }
    } catch (e) {
      // We log but do not crash the app, as we want the upgrade to try and proceed if possible,
      // though in a strict environment you might want to throw here.
      AppLogger.error('CRITICAL: Failed to backup database before upgrade: $e', tag: 'DB');
    }
  }
  
  // Helper function to check if a column exists before adding it (prevents crashes)
  Future<bool> _columnExists(Database db, String table, String column) async {
    final result = await db.rawQuery(
      "PRAGMA table_info($table)"
    );
    return result.any((map) => map['name'] == column);
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
        address TEXT,
        credit_limit REAL DEFAULT 0,
        outstanding_balance REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 5. Sales
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_number TEXT NOT NULL UNIQUE,
        customer_id INTEGER,
        sale_date TEXT NOT NULL,
        sale_time TEXT NOT NULL,
        grand_total REAL NOT NULL DEFAULT 0.0,
        cash_amount REAL NOT NULL DEFAULT 0.0,
        bank_amount REAL NOT NULL DEFAULT 0.0,
        credit_amount REAL NOT NULL DEFAULT 0.0,
        total_paid REAL NOT NULL DEFAULT 0.0,
        remaining_balance REAL NOT NULL DEFAULT 0.0,
        discount REAL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE SET NULL
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

    // 7. Suppliers
    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
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

    // 8. PERFORMANCE FIX: ADD INDEXES ON FOREIGN KEYS (Task 7 Fix)
    await db.execute('CREATE INDEX idx_sales_customer ON sales(customer_id)');
    await db.execute('CREATE INDEX idx_sale_items_sale ON sale_items(sale_id)');
    await db.execute('CREATE INDEX idx_sale_items_product ON sale_items(product_id)');
  }

  Future<void> _insertSampleData(Database db) async {
    try {
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

      // Customers
      await db.insert('customers', {
        'name_english': 'Ali Khan',
        'name_urdu': 'علی خان',
        'contact_primary': '0300-1111111',
        'credit_limit': 10000,
        'outstanding_balance': 2500,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await db.insert('suppliers', {
        'name_english': 'Ali Traders',
        'name_urdu': 'علی ٹریڈرز',
        'contact_primary': '0321-0000001',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      AppLogger.db('Sample data inserted');
    } catch (e) {
      AppLogger.error('Error inserting sample data: $e');
    }
  }
  
  // =======================================================
  //         DASHBOARD & REPORTS QUERIES (FIXED & ADDED)
  // =======================================================
  
  // FIX: getTodaySales (Missing method fix)
  Future<double> getTodaySales() async {
    try {
      final db = await database;
      // FIX: Use DateFormat for reliable date string
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final result = await db.rawQuery(
        'SELECT SUM(grand_total) as total FROM sales WHERE sale_date = ?',
        [today]
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      AppLogger.error("Error fetching today's sales: $e", tag: 'DB');
      return 0.0;
    }
  }

  // FIX: getTodayCustomers (Missing method fix)
  Future<List<Map<String, dynamic>>> getTodayCustomers() async {
    try {
      final db = await database;
      // FIX: Use DateFormat
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      return await db.rawQuery('''
        SELECT 
          c.name_urdu, 
          c.name_english, 
          SUM(s.grand_total) as total_amount,
          COUNT(s.id) as sale_count
        FROM sales s
        LEFT JOIN customers c ON s.customer_id = c.id
        WHERE s.sale_date = ? AND c.id IS NOT NULL
        GROUP BY c.id
        ORDER BY total_amount DESC
        LIMIT 5
      ''', [today]);
    } catch (e) {
       AppLogger.error("Error fetching today's customers: $e", tag: 'DB');
       return [];
    }
  }

  // FIX: getLowStockItems (Missing method fix)
  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    try {
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
    } catch (e) {
      AppLogger.error("Error fetching low stock items: $e", tag: 'DB');
      return [];
    }
  }

  // FIX: getRecentSales (Missing method fix)
  Future<List<Map<String, dynamic>>> getRecentSales() async {
    try {
      final db = await database;
      return await db.rawQuery('''
        SELECT 
          s.bill_number, 
          s.grand_total, 
          s.sale_time,
          COALESCE(c.name_urdu, c.name_english, 'Walk-in Customer') as customer_name
        FROM sales s
        LEFT JOIN customers c ON s.customer_id = c.id
        ORDER BY s.created_at DESC
        LIMIT 5
      ''');
    } catch (e) {
      AppLogger.error("Error fetching recent sales: $e", tag: 'DB');
      return [];
    }
  }

  // =======================================================
  //         CORE TRANSACTION & CRUD METHODS
  // =======================================================
  
  // FIX: Atomic and Validated Sale Creation (Tasks 3, 4, 5, 8 Fixes)
  Future<void> createSale(Map<String, dynamic> saleData) async {
    final db = await database;
    
    // NOTE: Removed non-atomic timestamp based generation.
    // We now use the SQLite ID to generate sequential Bill Numbers atomically.
    // 1. Prepare Financials
    double grandTotal = (saleData['grand_total'] as num).toDouble();
    double cash = (saleData['cash_amount'] as num?)?.toDouble() ?? 0.0;
    double bank = (saleData['bank_amount'] as num?)?.toDouble() ?? 0.0;
    
    double totalPaid = cash + bank;
    double remainingBalance = grandTotal - totalPaid;

    if (remainingBalance < 0) remainingBalance = 0;

    // 2. Prepare Date Components for Bill Number

    final now = DateTime.now();
    final String yy = (now.year % 100).toString(); // e.g., '25'
    final String mm = now.month.toString().padLeft(2, '0'); // e.g., '12'

    // sale_date and sale_time logic
    final String saleDate = DateFormat('yyyy-MM-dd').format(now);
    final String saleTime = DateFormat('HH:mm').format(now);

    try {
      await db.transaction((txn) async {
        // ---------------------------------------------------------
        // Step A: Insert with Temporary Bill Number
        // ---------------------------------------------------------
        // We use a temp string to satisfy the NOT NULL constraint.
        // The real ID is generated by SQLite here.
        final tempBillNo = 'TEMP-${now.microsecondsSinceEpoch}';

        final saleId = await txn.insert('sales', {
          'bill_number': tempBillNo, 
          'customer_id': saleData['customer_id'],
          'sale_date': saleDate,
          'sale_time': saleTime,
          'grand_total': grandTotal,
          'discount': saleData['discount'] ?? 0.0,
          'cash_amount': cash,
          'bank_amount': bank,
          'credit_amount': remainingBalance,
          'total_paid': totalPaid,
          'remaining_balance': remainingBalance,
        });

        // ---------------------------------------------------------
        // Step B: Generate Final Atomic Bill Number (SB-YYMMXXXXXX)
        // ---------------------------------------------------------
        // format: SB + Year(25) + Month(12) + ID(000001)
        // Example: SB-2512000001
        final String sequence = saleId.toString().padLeft(4, '0');
        final String finalBillNumber = 'SB-$yy$mm$sequence';

        // ---------------------------------------------------------
        // Step C: Update the Sale Record with Final Bill Number
        // ---------------------------------------------------------

        await txn.rawUpdate(
          'UPDATE sales SET bill_number = ? WHERE id = ?',
          [finalBillNumber, saleId]
        );

        // ---------------------------------------------------------
        // Step D: Insert Items & Handle Stock (Atomic)
        // ---------------------------------------------------------

        // 4. Insert Items & Atomic Stock Deduction (Race Condition & Validation Fix)
        final items = saleData['items'] as List<Map<String, dynamic>>;
        for (var item in items) {
          final productId = item['id'];
          final quantity = (item['quantity'] as num).toDouble();

          await txn.insert('sale_items', {
            'sale_id': saleId,
            'product_id': productId,
            'quantity_sold': quantity,
            'unit_price': item['sale_price'],
            'total_price': item['total'],
          });

          // Atomic check and update: ensures stock is > quantity and prevents race condition
          int count = await txn.rawUpdate('''
            UPDATE products 
            SET current_stock = current_stock - ? 
            WHERE id = ? AND current_stock >= ?
          ''', [quantity, productId, quantity]);

          if (count == 0) {
            throw Exception('Insufficient stock or invalid product ID: $productId');
          }
        }

        // 5. Update Customer Balance (Debt Fix)
        if (saleData['customer_id'] != null && remainingBalance > 0) {
           await txn.rawUpdate(
             'UPDATE customers SET outstanding_balance = outstanding_balance + ? WHERE id = ?',
             [remainingBalance, saleData['customer_id']]
           );
        }
      });
      AppLogger.info('Sale created successfully', tag: 'DB');
    } catch (e) {
      AppLogger.error('Error creating sale: $e', tag: 'DB');
      throw Exception('Transaction Failed: ${e.toString()}');
    }
  }

  // --- Utility Getters ---

  Future<Map<String, dynamic>> getDashboardData() async {
    final db = await database;
    final batch = db.batch();
    
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. Today's Sales Total
    batch.rawQuery('SELECT SUM(grand_total) as total FROM sales WHERE sale_date = ?', [today]);

    // 2. Today's Top Customers
    batch.rawQuery('''
        SELECT 
          c.name_urdu, 
          c.name_english, 
          SUM(s.grand_total) as total_amount,
          COUNT(s.id) as sale_count
        FROM sales s
        LEFT JOIN customers c ON s.customer_id = c.id
        WHERE s.sale_date = ? AND c.id IS NOT NULL
        GROUP BY c.id
        ORDER BY total_amount DESC
        LIMIT 5
    ''', [today]);

    // 3. Low Stock Items
    batch.rawQuery('''
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

    // 4. Recent Sales
    batch.rawQuery('''
        SELECT 
          s.bill_number, 
          s.grand_total, 
          s.sale_time,
          COALESCE(c.name_urdu, c.name_english, 'Walk-in Customer') as customer_name
        FROM sales s
        LEFT JOIN customers c ON s.customer_id = c.id
        ORDER BY s.created_at DESC
        LIMIT 5
    ''');

    final results = await batch.commit();

    // Parse results safely
    return {
      'todaySales': (results[0] as List).isNotEmpty 
          ? ((results[0] as List).first['total'] as num?)?.toDouble() ?? 0.0 
          : 0.0,
      'todayCustomers': (results[1] as List).map((e) => e as Map<String, dynamic>).toList(),
      'lowStockItems': (results[2] as List).map((e) => e as Map<String, dynamic>).toList(),
      'recentSales': (results[3] as List).map((e) => e as Map<String, dynamic>).toList(),
    };
  }

  Future<List<Map<String, dynamic>>> getSuppliers() async {
    try {
      final db = await database;
      return await db.query('suppliers', orderBy: 'name_english ASC');
    } catch (e) {
      AppLogger.error('Error getting suppliers: $e', tag: 'DB');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
     try {
       final db = await database;
       return await db.query('products', orderBy: 'name_english ASC');
     } catch (e) {
       return [];
     }
  }
  
  Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      final db = await database;
      return await db.query('customers', orderBy: 'name_english ASC');
    } catch (e) {
      return [];
    }
  }
  
  Future<int> getTotalProductsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return (result.first['count'] as int?) ?? 0;
  }
  
  Future<double> getTotalStockValue() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(current_stock * avg_cost_price) as total FROM products');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }


  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}