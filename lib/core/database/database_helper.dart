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

    return await openDatabase(
      path,
      version: 6, 
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

  Future<int> updateCustomerCreditLimit(int customerId, double newLimit) async {
  final db = await database;
  return await db.update(
    'customers',
    {'credit_limit': newLimit},
    where: 'id = ?',
    whereArgs: [customerId],
  );
  }


  // 🛠️ Proper Migration Logic with Auto-Backup
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    AppLogger.db('Upgrading database from v$oldVersion to v$newVersion');

    // FIX: Auto-Backup before critical migration
    // ✅ CORRECT: Call with both parameters (db, oldVersion)
    await backupDatabase(db, oldVersion);
    
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      switch (i) {
        case 2:
          // ADDED: Columns needed for v2 features (e.g., reports, discounts)
          if (!await _columnExists(db, 'customers', 'email')) {
             await db.execute("ALTER TABLE customers ADD COLUMN email TEXT");
          }
          if (!await _columnExists(db, 'sales', 'discount')) {
             await db.execute("ALTER TABLE sales ADD COLUMN discount INTEGER DEFAULT 0");
          }
          AppLogger.db('Performed migration to v2');
          break;

        case 3:
          // Reserved for cash_ledger future changes
          break;

        case 4:
         // Add all performance indexes
          await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name_english ON products(name_english)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_products_item_code ON products(item_code)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_name_english ON customers(name_english)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_contact ON customers(contact_primary)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(sale_date)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_status ON sales(status)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_date_status ON sales(sale_date, status)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_products_stock ON products(current_stock)');
          AppLogger.db('Performed migration to v4 (Performance Indexes)');
          break;

        case 5:
          await db.execute('''
            CREATE TABLE IF NOT EXISTS payments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              customer_id INTEGER NOT NULL,
              amount INTEGER NOT NULL,
              date TEXT NOT NULL,
              notes TEXT,
              FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
            )
          ''');

          await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_customer ON payments(customer_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(date)');
          AppLogger.db('Performed migration to v5 (Payments Table)');
          break;

        case 6:
          // Example: Add a new column to products table
          if (!await _columnExists(db, 'products', 'barcode')) {
          await db.execute("ALTER TABLE products ADD COLUMN barcode TEXT");
        }
  
          // Example: Create a new table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS expense_categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name_english TEXT NOT NULL,
              name_urdu TEXT,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
          ''');
  
          AppLogger.db('Performed migration to v6 (Added barcode & expense categories)');
          break;

          default:
          AppLogger.db('No migration logic defined for v$i');
      }
    }
  }

  // Helper: Creates a backup file like 'liaqat_store.db.v1.bak'
  // ✅ FIXED: Use the passed Database parameter instead of getting a new one
  Future<String?> backupDatabase(Database db, int version) async {
  try {
    final String dbPath = db.path;  // Use the passed db parameter
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String backupFileName = 'liaqat_store.v$version.$timestamp.backup.db';
    final String backupPath = join(dirname(dbPath), backupFileName);
    
    AppLogger.db('Attempting database backup to: $backupPath');

    try {
      await db.execute('VACUUM INTO ?', [backupPath]);
      AppLogger.info('Database backup created (VACUUM)', tag: 'DB');
      return backupPath; // Return the backup file path
    } catch (e) {
      // Fallback for devices that don't support VACUUM INTO
      final file = File(dbPath);
      if (await file.exists()) {
        await file.copy(backupPath);
        AppLogger.info('Database backup created (File Copy)', tag: 'DB');
        return backupPath;
      }
    }
  } catch (e) {
    AppLogger.error('Backup Failed: $e', tag: 'DB');
  }
  return null;
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
        min_stock_alert INTEGER DEFAULT 10,
        current_stock INTEGER DEFAULT 0,
        avg_cost_price INTEGER DEFAULT 0,
        sale_price INTEGER DEFAULT 0,
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
        credit_limit INTEGER DEFAULT 0,
        outstanding_balance INTEGER DEFAULT 0,
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
        grand_total INTEGER NOT NULL DEFAULT 0.0,
        cash_amount INTEGER NOT NULL DEFAULT 0.0,
        bank_amount INTEGER NOT NULL DEFAULT 0.0,
        credit_amount INTEGER NOT NULL DEFAULT 0.0,
        total_paid INTEGER NOT NULL DEFAULT 0.0,
        remaining_balance INTEGER NOT NULL DEFAULT 0.0,
        discount INTEGER DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT,
        status TEXT NOT NULL DEFAULT 'COMPLETED',
        cancelled_at TEXT,
        cancelled_by TEXT,
        cancel_reason TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE SET NULL
      )
    ''');

    // 6. Sale Items
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity_sold INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        total_price INTEGER NOT NULL,
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
        outstanding_balance INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 8. Database db
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cash_ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_date TEXT NOT NULL,
        transaction_time TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL, -- 'IN' or 'OUT'
        amount INTEGER NOT NULL,
        balance_after INTEGER, 
        remarks TEXT
      )
    ''');

    // 9. Payments Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_payments_customer ON payments(customer_id)');
    await db.execute('CREATE INDEX idx_payments_date ON payments(date)');

    // Expense Categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_english TEXT NOT NULL,
        name_urdu TEXT,
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

  Future<double> getCurrentCashBalance() async {
    try {
      final db = await database;
      final res = await db.rawQuery('SELECT balance_after FROM cash_ledger ORDER BY id DESC LIMIT 1');
      if (res.isNotEmpty) {
        return (res.first['balance_after'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> addCashEntry(String desc, String type, double amount, String remarks) async {
    final db = await database;
    final now = DateTime.now();
    
    // This uses the 'intl' package, fixing the "Unused import" error
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final timeStr = DateFormat('hh:mm a').format(now);

    await db.transaction((txn) async {
      final res = await txn.rawQuery('SELECT balance_after FROM cash_ledger ORDER BY id DESC LIMIT 1');
      double currentBalance = 0.0;
      if (res.isNotEmpty) {
        currentBalance = (res.first['balance_after'] as num).toDouble();
      }

      double newBalance = currentBalance;
      if (type == 'IN') {
        newBalance += amount;
      } else {
        newBalance -= amount;
      }

      await txn.insert('cash_ledger', {
        'transaction_date': dateStr,
        'transaction_time': timeStr,
        'description': desc,
        'type': type,
        'amount': amount,
        'balance_after': newBalance,
        'remarks': remarks,
      });
    });
  }

  Future<List<Map<String, dynamic>>> getCashLedger({int limit = 50, int offset = 0}) async {
    try {
      final db = await database;
      return await db.query(
        'cash_ledger',
        orderBy: 'id DESC',
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerLedger(int customerId) async {
    final db = await database;

    // Fetch Sales (Debits)
    final salesResult = await db.rawQuery('''
      SELECT 
        'SALE' as type,
        s.sale_date as date,
        s.bill_number as ref_no,
        si.product_id as prod_id, -- Used for lookups if needed
        p.name_english || ' (' || si.quantity_sold || ' x ' || si.unit_price || ')' as description,
        si.quantity_sold as qty,
        si.unit_price as rate,
        si.total_price as debit,
        0 as credit
      FROM sales s
      JOIN sale_items si ON s.id = si.sale_id
      JOIN products p ON si.product_id = p.id
      WHERE s.customer_id = ? AND s.status = 'COMPLETED'
    ''', [customerId]);

    // Fetch Payments (Credits)
    final paymentsResult = await db.rawQuery('''
      SELECT 
        'PAYMENT' as type,
        date as date,
        id as ref_no,
        notes as description,
        0 as qty,
        0 as rate,
        0 as debit,
        amount as credit
      FROM payments
      WHERE customer_id = ?
    ''', [customerId]);

    // Combine and Sort by Date (Descending)
    List<Map<String, dynamic>> ledger = [...salesResult, ...paymentsResult];
    ledger.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));

    return ledger;
  }

  // FIX: getTodayCustomers (Missing method fix)
  Future<List<Map<String, dynamic>>> getTodayCustomers() async {
  try {
    final db = await database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // ✅ FIXED: Filter by status = 'COMPLETED'
    return await db.rawQuery('''
      SELECT 
        c.name_urdu, 
        c.name_english, 
        SUM(s.grand_total) as total_amount,
        COUNT(s.id) as sale_count
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE s.sale_date = ? AND c.id IS NOT NULL AND s.status = 'COMPLETED'
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

  // --- GROUPED LEDGER LOGIC ---
  Future<List<Map<String, dynamic>>> getCustomerLedgerGrouped(int customerId) async {
    final db = await database;

    // 1. Fetch Sales (Bills) - The Parent Rows
    final sales = await db.rawQuery('''
      SELECT 
        'BILL' as type,
        id as ref_id,
        sale_date as date,
        bill_number as bill_no,
        total_amount as dr,   -- Debit (Udhar)
        0 as cr,              -- Credit (Jama)
        remarks as desc
      FROM sales 
      WHERE customer_id = ? 
    ''', [customerId]);

    // 2. Fetch Items - The Child Rows
    final saleItems = await db.rawQuery('''
      SELECT 
        si.sale_id,
        p.name_english || ' (' || p.name_urdu || ')' as name,
        si.quantity_sold as qty,
        si.unit_price as rate,
        si.total_price as total
      FROM sale_items si
      JOIN sales s ON si.sale_id = s.id
      JOIN products p ON si.product_id = p.id
      WHERE s.customer_id = ?
    ''', [customerId]);

    // 3. Fetch Payments
    final payments = await db.rawQuery('''
      SELECT 
        'PAYMENT' as type,
        id as ref_id,
        date as date,
        'Payment Received' as bill_no,
        0 as dr,
        amount as cr,
        notes as desc
      FROM payments
      WHERE customer_id = ?
    ''', [customerId]);

    // 4. Organize Items by Sale ID
    Map<int, List<Map<String, dynamic>>> itemsMap = {};
    for (var item in saleItems) {
      int saleId = item['sale_id'] as int;
      if (!itemsMap.containsKey(saleId)) itemsMap[saleId] = [];
      itemsMap[saleId]!.add(item);
    }

    // 5. Merge Sales & Payments into one Timeline
    List<Map<String, dynamic>> timeline = [];

    for (var sale in sales) {
      int saleId = sale['ref_id'] as int;
      Map<String, dynamic> row = Map.from(sale);
      row['items'] = itemsMap[saleId] ?? []; // Attach items to the bill
      timeline.add(row);
    }

    for (var pay in payments) {
      timeline.add(pay);
    }

    // 6. Sort by Date (OLDEST First) to calculate Running Balance
    timeline.sort((a, b) {
      DateTime dA = DateTime.tryParse(a['date'].toString()) ?? DateTime(1900);
      DateTime dB = DateTime.tryParse(b['date'].toString()) ?? DateTime(1900);
      return dA.compareTo(dB);
    });

    // 7. Calculate Running Balance
    double runningBal = 0.0;
    List<Map<String, dynamic>> finalLedger = [];

    for (var row in timeline) {
      double dr = (row['dr'] as num).toDouble();
      double cr = (row['cr'] as num).toDouble();
      runningBal += (dr - cr); // Formula: Previous + Debit - Credit

      Map<String, dynamic> newRow = Map.from(row);
      newRow['balance'] = runningBal;
      finalLedger.add(newRow);
    }

    // 8. Return Reversed (Newest First) for Display
    return finalLedger.reversed.toList();
  }

  // =======================================================
  //         CORE TRANSACTION & CRUD METHODS
  // =======================================================
  

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

  Future<int> addPayment(int customerId, double amount, String date, String notes) async {
    final db = await database;
    
    return await db.transaction((txn) async {
      // Record the payment
      int id = await txn.insert('payments', {
        'customer_id': customerId,
        'amount': amount,
        'date': date,
        'notes': notes
      });

      // Update Customer Balance (Decrease balance by paid amount)
      await txn.rawUpdate(
        'UPDATE customers SET outstanding_balance = outstanding_balance - ? WHERE id = ?',
        [amount, customerId]
      );
      
      // Also record in cash ledger as an 'IN' entry
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final timeStr = DateFormat('hh:mm a').format(DateTime.now());
      
      final res = await txn.rawQuery('SELECT balance_after FROM cash_ledger ORDER BY id DESC LIMIT 1');
      double currentBalance = res.isNotEmpty ? (res.first['balance_after'] as num).toDouble() : 0.0;

      await txn.insert('cash_ledger', {
        'transaction_date': dateStr,
        'transaction_time': timeStr,
        'description': 'Payment from Customer (ID: $customerId)',
        'type': 'IN',
        'amount': amount,
        'balance_after': currentBalance + amount,
        'remarks': notes,
      });

      return id;
    });
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