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
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 20,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // ========================
  // CREATE DATABASE TABLES
  // ========================
  Future<void> _createDB(Database db, int version) async {
    AppLogger.db('Creating Database v$version...');
    await _createTables(db);
    await _insertSampleData(db);
    AppLogger.db('Database created successfully');
  }

  Future<void> _createTables(Database db) async {
    // Shop Profile
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

    // Departments
    await db.execute('''
      CREATE TABLE IF NOT EXISTS departments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_english TEXT NOT NULL,
        name_urdu TEXT,
        is_active INTEGER DEFAULT 1,
        is_visible_in_pos INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        department_id INTEGER,
        name_urdu TEXT NOT NULL,
        name_english TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        is_visible_in_pos INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL
      )
    ''');

    // Subcategories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subcategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name_english TEXT NOT NULL,
        name_urdu TEXT,
        is_active INTEGER DEFAULT 1,
        is_visible_in_pos INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    // Products
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_code TEXT UNIQUE,
        name_urdu TEXT NOT NULL,
        name_english TEXT NOT NULL,
        category_id INTEGER,
        sub_category_id INTEGER,
        brand TEXT,
        unit_id INTEGER,
        unit_type TEXT,
        packing_type TEXT,
        search_tags TEXT,
        min_stock_alert INTEGER DEFAULT 10,
        current_stock INTEGER DEFAULT 0,
        avg_cost_price INTEGER DEFAULT 0,
        sale_price INTEGER DEFAULT 0,
        barcode TEXT,
        expiry_date TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Customers
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_english TEXT NOT NULL,
        name_urdu TEXT,
        contact_primary TEXT,
        address TEXT,
        email TEXT,
        credit_limit INTEGER DEFAULT 0,
        outstanding_balance INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_phone_unique ON customers(contact_primary)');

    // Invoices
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        customer_id INTEGER,
        invoice_date TEXT NOT NULL,
        sub_total INTEGER NOT NULL,
        discount_total INTEGER DEFAULT 0,
        grand_total INTEGER NOT NULL,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        status TEXT DEFAULT 'COMPLETED',
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT
      )
    ''');

    // Invoice Items
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        item_name_snapshot TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        total_price INTEGER NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE RESTRICT
      )
    ''');

    // Suppliers
    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_english TEXT NOT NULL,
        name_urdu TEXT,
        contact_primary TEXT,
        address TEXT,
        supplier_type TEXT,
        outstanding_balance INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Cash Ledger
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

    // Receipts
    await db.execute('''
      CREATE TABLE IF NOT EXISTS receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_number TEXT UNIQUE NOT NULL,
        customer_id INTEGER NOT NULL,
        receipt_date TEXT NOT NULL,
        amount INTEGER NOT NULL,
        payment_mode TEXT DEFAULT 'CASH',
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT
      )
    ''');

    // Expense Categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_english TEXT NOT NULL,
        name_urdu TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // sale_print_logs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_print_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        receipt_type TEXT NOT NULL,
        generated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Unit Categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS unit_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_system INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Units
    await db.execute('''
      CREATE TABLE IF NOT EXISTS units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        is_system INTEGER DEFAULT 0,
        base_unit_id INTEGER,
        multiplier INTEGER DEFAULT 1,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES unit_categories(id) ON DELETE CASCADE,
        FOREIGN KEY (base_unit_id) REFERENCES units(id) ON DELETE SET NULL
      )
    ''');

    // Purchases
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        invoice_number TEXT,
        purchase_date TEXT,
        total_amount INTEGER DEFAULT 0,
        notes TEXT,
        status TEXT DEFAULT 'COMPLETED',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER NOT NULL,
        product_id INTEGER,
        quantity INTEGER DEFAULT 0,
        cost_price INTEGER DEFAULT 0,
        total_amount INTEGER DEFAULT 0,
        batch_number TEXT,
        expiry_date TEXT,
        FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE
      )
    ''');

    // Supplier Payments
    await db.execute('''
      CREATE TABLE IF NOT EXISTS supplier_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        amount INTEGER DEFAULT 0,
        payment_date TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE
      )
    ''');

    // Customer Ledger
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customer_ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        transaction_date TEXT NOT NULL,
        description TEXT NOT NULL,
        ref_type TEXT NOT NULL CHECK (ref_type IN ('INVOICE', 'RECEIPT', 'RETURN', 'ADJUSTMENT')),
        ref_id INTEGER NOT NULL,
        debit INTEGER DEFAULT 0,
        credit INTEGER DEFAULT 0,
        balance INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT
      )
    ''');

    // ===== Performance Indexes =====
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name_english ON products(name_english)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_item_code ON products(item_code)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_name_english ON customers(name_english)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_contact ON customers(contact_primary)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_stock ON products(current_stock)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_customer ON invoices(customer_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices(invoice_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON invoice_items(invoice_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_receipts_customer ON receipts(customer_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_receipts_date ON receipts(receipt_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ledger_customer_date ON customer_ledger(customer_id, transaction_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ledger_ref ON customer_ledger(ref_type, ref_id)');
  }

  // ========================
  // MIGRATION LOGIC
  // ========================
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    AppLogger.db('Upgrading database from v$oldVersion to v$newVersion');

    // Backup before migration
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
          AppLogger.db('Performed migration v2');
          break;

        case 3:
          break;

        case 4:
          // Indexes already handled in _createTables()
          break;

        case 5:
          await db.execute('''
            CREATE TABLE IF NOT EXISTS payments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              customer_id INTEGER NOT NULL,
              amount INTEGER NOT NULL,
              date TEXT NOT NULL,
              notes TEXT,
              FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
            )
          ''');
          AppLogger.db('Performed migration v5');
          break;

        // v6-v14 skipped for brevity
        case 15:
          await _migrateToV15(db);
          AppLogger.db('Performed migration v15');
          break;

        case 16:
          // Already created in _createTables()
          break;

        case 17:
          break;

        case 18:
          break;

        case 19:
          break;

        case 20:
          AppLogger.db('v20 skipped (already applied)');
          break;

        default:
          AppLogger.db('No migration logic for v$i');
      }
    }
  }

  // ========================
  // MIGRATION v15
  // ========================
  Future<void> _migrateToV15(Database db) async {
    AppLogger.db('Starting migration v15');

    await db.transaction((txn) async {
      // Rename old receipts
      final hasReceipts = await _tableExists(txn, 'receipts');
      final hasPrintLogs = await _tableExists(txn, 'sale_print_logs');
      if (hasReceipts && !hasPrintLogs) {
        await txn.execute('ALTER TABLE receipts RENAME TO sale_print_logs');
      }

      // Ensure unique customer phone
      await txn.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_phone_unique ON customers(contact_primary)'
      );

      // Sales → Invoices
      await txn.execute('''
        INSERT INTO invoices (id, invoice_number, customer_id, invoice_date, sub_total, discount_total, grand_total, created_at, status)
        SELECT id, bill_number, customer_id, sale_date || ' ' || IFNULL(sale_time,'00:00:00'), (grand_total + discount), discount, grand_total, created_at, status
        FROM sales
      ''');

      await txn.execute('''
        INSERT INTO invoice_items (invoice_id, product_id, item_name_snapshot, quantity, unit_price, total_price)
        SELECT sale_id, product_id, item_name_english, quantity, unit_price, total_price
        FROM sale_items
      ''');

      // Payments → Receipts
      await txn.execute('''
        INSERT INTO receipts (receipt_number, customer_id, receipt_date, amount, notes)
        SELECT 'RCP-OLD-' || id, customer_id, date, amount, notes
        FROM payments
      ''');

      // Ledger
      await txn.execute('DELETE FROM customer_ledger');
      await txn.execute('''
        INSERT INTO customer_ledger (customer_id, transaction_date, description, ref_type, ref_id, debit, credit, balance)
        SELECT customer_id, invoice_date, 'Invoice #' || invoice_number, 'INVOICE', id, grand_total, 0, 0
        FROM invoices
      ''');
      await txn.execute('''
        INSERT INTO customer_ledger (customer_id, transaction_date, description, ref_type, ref_id, debit, credit, balance)
        SELECT customer_id, receipt_date, 'Payment Received', 'RECEIPT', id, 0, amount, 0
        FROM receipts
      ''');

      // Running balances (SQLite optimized)
      await txn.execute('''
        UPDATE customer_ledger
        SET balance = (
          SELECT SUM(debit - credit)
          FROM customer_ledger AS cl
          WHERE cl.customer_id = customer_ledger.customer_id
            AND cl.id <= customer_ledger.id
        )
      ''');

      // Update customers outstanding_balance
      await txn.execute('''
        UPDATE customers
        SET outstanding_balance = (
          SELECT COALESCE(SUM(debit - credit), 0)
          FROM customer_ledger
          WHERE customer_ledger.customer_id = customers.id
        )
      ''');

      // Drop old tables
      await txn.execute('DROP TABLE IF EXISTS sales');
      await txn.execute('DROP TABLE IF EXISTS sale_items');
      await txn.execute('DROP TABLE IF EXISTS payments');
    });

    AppLogger.db('Migration v15 completed successfully');
  }

  // ========================
  // SAMPLE DATA INSERTION
  // ========================
  Future<void> _insertSampleData(Database db) async {
    try {
      // Only insert defaults if tables are empty
      final shopCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM shop_profile')) ?? 0;
      if (shopCount == 0) {
        await db.insert('shop_profile', {
          'shop_name_urdu': 'لیاقت کریانہ اسٹور',
          'shop_name_english': 'Liaqat Kiryana Store',
          'shop_address': 'مین بازار، لاہور',
          'contact_primary': '0300-1234567',
        });
      }

      final deptCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM departments')) ?? 0;
      if (deptCount == 0) {
        await db.insert('departments', {'id': 1, 'name_english': 'Food', 'name_urdu': 'خوراک'});
        await db.insert('departments', {'id': 2, 'name_english': 'Cosmetics', 'name_urdu': 'کاسمیٹکس'});
      }

      final catCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories')) ?? 0;
      if (catCount == 0) {
        List<Map<String, dynamic>> categories = [
          {'name_urdu': 'چاول', 'name_english': 'Rice', 'department_id': 1},
          {'name_urdu': 'دال', 'name_english': 'Pulses', 'department_id': 1},
          {'name_urdu': 'تیل', 'name_english': 'Oil', 'department_id': 1},
        ];
        for (var cat in categories) await db.insert('categories', cat);
      }

      AppLogger.db('Sample data inserted successfully');
    } catch (e) {
      AppLogger.error('Error inserting sample data: $e');
    }
  }

  // ========================
  // UTILITY FUNCTIONS
  // ========================
  Future<bool> _tableExists(Database db, String table) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [table]
    );
    return result.isNotEmpty;
  }

  Future<bool> _columnExists(Database db, String table, String column) async {
    final result = await db.rawQuery("PRAGMA table_info($table)");
    return result.any((map) => map['name'] == column);
  }

  Future<String?> backupDatabase(Database db, int version) async {
    try {
      final String dbPath = db.path!;
      final dir = Directory(join(dirname(dbPath), 'backup'));
      if (!await dir.exists()) await dir.create(recursive: true);

      final backupPath = join(dir.path, 'liaqat_store_backup_v$version.db');

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await db.execute("VACUUM INTO '$backupPath'");
      } else {
        await File(dbPath).copy(backupPath);
      }

      AppLogger.db('Database backup created: $backupPath');
      return backupPath;
    } catch (e) {
      AppLogger.error('Backup failed: $e');
      return null;
    }
  }
}
