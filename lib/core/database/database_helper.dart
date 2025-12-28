// lib/core/database/database_helper.dart
import 'dart:io';
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
    // Platform check for Desktop support
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 9, 
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    AppLogger.db('Creating Database v$version...');
    await _createTables(db);
    await _insertSampleData(db);
    AppLogger.db('Database created successfully');
  }

  // 🛠️ Proper Migration Logic with Auto-Backup
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    AppLogger.db('Upgrading database from v$oldVersion to v$newVersion');

    // Auto-Backup before critical migration
    await backupDatabase(db, oldVersion);
    
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      switch (i) {
        case 2:
          if (!await _columnExists(db, 'customers', 'email')) {
             await db.execute("ALTER TABLE customers ADD COLUMN email TEXT");
          }
          if (!await _columnExists(db, 'sales', 'discount')) {
             await db.execute("ALTER TABLE sales ADD COLUMN discount INTEGER DEFAULT 0");
          }
          AppLogger.db('Performed migration to v2');
          break;

        case 3:
          // Reserved for future changes
          break;

        case 4:
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
          if (!await _columnExists(db, 'products', 'barcode')) {
            await db.execute("ALTER TABLE products ADD COLUMN barcode TEXT");
          }
  
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

        case 7:
          if (!await _columnExists(db, 'sales', 'receipt_number')) {
            await db.execute("ALTER TABLE sales ADD COLUMN receipt_number TEXT");
          }
          if (!await _columnExists(db, 'sales', 'sale_snapshot')) {
            await db.execute("ALTER TABLE sales ADD COLUMN sale_snapshot TEXT");
          }
          if (!await _columnExists(db, 'sales', 'original_sale_id')) {
            await db.execute("ALTER TABLE sales ADD COLUMN original_sale_id INTEGER");
          }
          if (!await _columnExists(db, 'sales', 'printed_count')) {
            await db.execute("ALTER TABLE sales ADD COLUMN printed_count INTEGER DEFAULT 0");
          }
          if (!await _columnExists(db, 'sales', 'language_code')) {
            await db.execute("ALTER TABLE sales ADD COLUMN language_code TEXT DEFAULT 'ur'");
          }

          await db.execute('''
            CREATE TABLE IF NOT EXISTS receipts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sale_id INTEGER NOT NULL,
              receipt_type TEXT NOT NULL,
              generated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE
            )
          ''');

          AppLogger.db('Performed migration to v7 (Receipts & Snapshots)');
          break;

        case 8:
          if (!await _columnExists(db, 'sales', 'receipt_language')) {
            await db.execute("ALTER TABLE sales ADD COLUMN receipt_language TEXT DEFAULT 'ur'");
          }
          if (!await _columnExists(db, 'sales', 'receipt_printed')) {
            await db.execute("ALTER TABLE sales ADD COLUMN receipt_printed INTEGER DEFAULT 0");
          }
          if (!await _columnExists(db, 'sales', 'receipt_print_count')) {
            await db.execute("ALTER TABLE sales ADD COLUMN receipt_print_count INTEGER DEFAULT 0");
          }
          if (!await _columnExists(db, 'sales', 'receipt_pdf_path')) {
            await db.execute("ALTER TABLE sales ADD COLUMN receipt_pdf_path TEXT");
          }
          if (!await _columnExists(db, 'sales', 'original_sale_id')) {
            await db.execute("ALTER TABLE sales ADD COLUMN original_sale_id INTEGER");
          }
          if (!await _columnExists(db, 'sales', 'edited_at')) {
            await db.execute("ALTER TABLE sales ADD COLUMN edited_at TEXT");
          }
          AppLogger.db('Performed migration to v8 (Receipt & Audit columns)');
          break;

        case 9:
          if (!await _columnExists(db, 'sale_items', 'item_name_english')) {
            await db.execute("ALTER TABLE sale_items ADD COLUMN item_name_english TEXT");
          }
          if (!await _columnExists(db, 'sale_items', 'item_name_urdu')) {
            await db.execute("ALTER TABLE sale_items ADD COLUMN item_name_urdu TEXT");
          }
          if (!await _columnExists(db, 'sale_items', 'unit_name')) {
            await db.execute("ALTER TABLE sale_items ADD COLUMN unit_name TEXT");
          }
          AppLogger.db('Performed migration to v9 (Sale Items Snapshot)');
          break;

        default:
          AppLogger.db('No migration logic defined for v$i');
      }
    }
  }

  // Backup database during migrations
  Future<String?> backupDatabase(Database db, int version) async {
    try {
      final String dbPath = db.path;
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String backupFileName = 'liaqat_store.v$version.$timestamp.backup.db';
      final String backupPath = join(dirname(dbPath), backupFileName);
      
      AppLogger.db('Attempting database backup to: $backupPath');

      try {
        await db.execute('VACUUM INTO ?', [backupPath]);
        AppLogger.info('Database backup created (VACUUM)', tag: 'DB');
        return backupPath;
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

  // Helper function to check if a column exists
  Future<bool> _columnExists(Database db, String table, String column) async {
    final result = await db.rawQuery("PRAGMA table_info($table)");
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
        receipt_number TEXT UNIQUE,
        sale_status TEXT,
        original_sale_id INTEGER NULL,
        sale_snapshot TEXT,
        printed_count INTEGER DEFAULT 0,
        language_code TEXT DEFAULT 'ur',
        receipt_language TEXT DEFAULT 'ur',
        receipt_printed INTEGER DEFAULT 0,
        receipt_print_count INTEGER DEFAULT 0,
        receipt_pdf_path TEXT,
        edited_at TEXT,
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
        item_name_english TEXT,
        item_name_urdu TEXT,
        unit_name TEXT,
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

    // 8. Cash Ledger
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cash_ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_date TEXT NOT NULL,
        transaction_time TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
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

    await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_customer ON payments(customer_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(date)');

    // 10. Expense Categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_english TEXT NOT NULL,
        name_urdu TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 11. Receipt Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        receipt_type TEXT NOT NULL,
        generated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE
      )
    ''');

    // 12. Performance Indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_customer ON sales(customer_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_product ON sale_items(product_id)');

    // Performance Indexes (Ensure these exist on fresh install)
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name_english ON products(name_english)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_item_code ON products(item_code)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_name_english ON customers(name_english)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_contact ON customers(contact_primary)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(sale_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_status ON sales(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_date_status ON sales(sale_date, status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_stock ON products(current_stock)');
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
         'avg_cost_price': 17000, // 170 rupees in paisas
         'sale_price': 18000,    // 180 rupees in paisas
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      // Customers
      await db.insert('customers', {
        'name_english': 'Ali Khan',
        'name_urdu': 'علی خان',
        'contact_primary': '0300-1111111',
        'credit_limit': 1000000,
        'outstanding_balance': 250000,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      // Suppliers
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

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}