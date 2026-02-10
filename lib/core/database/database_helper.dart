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
    // Platform-specific initialization is handled in main.dart

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    AppLogger.db('Creating Database v$version...');
    await _createTables(db);
    await _insertSampleData(db);
    AppLogger.db('Database created successfully');
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

    // 2. Departments
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

    // 3. Categories
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

    // 4. SubCategories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subcategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name_english TEXT NOT NULL,
        name_urdu TEXT,
        is_active INTEGER DEFAULT 1,
        is_visible_in_pos INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // 5. Products
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
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
        FOREIGN KEY (sub_category_id) REFERENCES subcategories(id) ON DELETE SET NULL,
        FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE SET NULL
      )
    ''');

    // 6. Customers
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
    await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_phone_unique ON customers(contact_primary)');

    // 7. Invoices (Replaces Sales)
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

    // 8. Invoice Items (Replaces Sale Items)
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

    // 9. Suppliers
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

    // 10. Cash Ledger
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

    // 11. Receipts (Replaces Payments)
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

    // 12. Expense Categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_english TEXT NOT NULL,
        name_urdu TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 13. sale_print_logs (was old receipts table)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_print_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        receipt_type TEXT NOT NULL,
        generated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 14. Unit Categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS unit_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_system INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 15. Units
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
        FOREIGN KEY (category_id) REFERENCES unit_categories (id) ON DELETE CASCADE,
        FOREIGN KEY (base_unit_id) REFERENCES units (id) ON DELETE SET NULL
      )
    ''');

    // 16. Supplier Purchases
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
    // 17. Purchase Items
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

    // 18. Supplier Payments
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

    // 19. Customer Ledger
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
    // 20. Stock Adjustments
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_adjustments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        adjustment_date TEXT NOT NULL,
        quantity_change REAL NOT NULL,
        reason TEXT,
        reference TEXT DEFAULT 'ADJUSTMENT',
        user TEXT DEFAULT 'SYSTEM',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    // Index for faster queries by product
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_stock_adjustments_product 
      ON stock_adjustments(product_id)
    ''');

    // 21. Supplier Ledger
    await db.execute('''
      CREATE TABLE IF NOT EXISTS supplier_ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        transaction_date TEXT NOT NULL,
        description TEXT NOT NULL,
        ref_type TEXT NOT NULL CHECK (ref_type IN ('PURCHASE', 'PURCHASE_RETURN', 'PAYMENT', 'ADJUSTMENT')),
        ref_id INTEGER NOT NULL,
        debit INTEGER DEFAULT 0,
        credit INTEGER DEFAULT 0,
        balance INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE
      )
    ''');

    // 22. Stock Activities
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        quantity_change INTEGER NOT NULL,
        transaction_type TEXT NOT NULL,
        reference_type TEXT NOT NULL,
        reference_id INTEGER NOT NULL,
        user TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_stock_activities_product
      ON stock_activities(product_id)
    ''');

    // Performance Indexes (Ensure these exist on fresh install)
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_name_english ON products(name_english)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_item_code ON products(item_code)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_name_english ON customers(name_english)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_contact ON customers(contact_primary)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_stock ON products(current_stock)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_invoices_customer ON invoices(customer_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices(invoice_date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON invoice_items(invoice_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_receipts_customer ON receipts(customer_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_receipts_date ON receipts(receipt_date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ledger_customer_date ON customer_ledger(customer_id, transaction_date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ledger_ref ON customer_ledger(ref_type, ref_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_supplier_ledger_supplier_date ON supplier_ledger(supplier_id, transaction_date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_supplier_ledger_ref ON supplier_ledger(ref_type, ref_id)');
  }

  Future<void> _insertSampleData(Database db) async {
    try {
      // Shop Profile
      await db.insert(
          'shop_profile',
          {
            'shop_name_urdu': 'لیاقت کریانہ اسٹور',
            'shop_name_english': 'Liaqat Kiryana Store',
            'shop_address': 'مین بازار، لاہور',
            'contact_primary': '0300-1234567',
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);

      // Departments
      await db.insert('departments',
          {'id': 1, 'name_english': 'Food', 'name_urdu': 'خوراک'},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('departments',
          {'id': 2, 'name_english': 'Cosmetics', 'name_urdu': 'کاسمیٹکس'},
          conflictAlgorithm: ConflictAlgorithm.ignore);

      // Categories
      List<Map<String, dynamic>> categories = [
        {'name_urdu': 'چاول', 'name_english': 'Rice', 'department_id': 1},
        {'name_urdu': 'دال', 'name_english': 'Pulses', 'department_id': 1},
        {'name_urdu': 'تیل', 'name_english': 'Oil', 'department_id': 1},
      ];
      for (var cat in categories) {
        await db.insert('categories', cat,
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      // Subcategories
      await db.insert('subcategories',
          {'category_id': 1, 'name_english': 'Basmati', 'name_urdu': 'باسمتی'},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('subcategories',
          {'category_id': 1, 'name_english': 'Irri', 'name_urdu': 'ایری'},
          conflictAlgorithm: ConflictAlgorithm.ignore);

      // Products
      await db.insert(
          'products',
          {
            'item_code': 'PRD001',
            'name_urdu': 'چاول سپر باسمتی',
            'name_english': 'Super Basmati Rice',
            'category_id': 1,
            'unit_type': 'KG',
            'min_stock_alert': 50,
            'current_stock': 45,
            'avg_cost_price': 17000, // 170 rupees in paisas
            'sale_price': 18000, // 180 rupees in paisas
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);

      // Customers
      await db.insert(
          'customers',
          {
            'name_english': 'Ali Khan',
            'name_urdu': 'علی خان',
            'contact_primary': '0300-1111111',
            'credit_limit': 1000000,
            'outstanding_balance': 250000,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);

      // Suppliers
      await db.insert(
          'suppliers',
          {
            'name_english': 'Ali Traders',
            'name_urdu': 'علی ٹریڈرز',
            'contact_primary': '0321-0000001',
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);

      // Unit Categories
      await db.insert(
          'unit_categories', {'id': 1, 'name': 'Weight', 'is_system': 1});
      await db.insert(
          'unit_categories', {'id': 2, 'name': 'Volume', 'is_system': 1});
      await db.insert(
          'unit_categories', {'id': 3, 'name': 'Count', 'is_system': 1});
      await db.insert(
          'unit_categories', {'id': 4, 'name': 'Length', 'is_system': 1});

      // Units
      await db.insert('units', {
        'name': 'Kilogram',
        'code': 'KG',
        'category_id': 1,
        'is_system': 1,
        'multiplier': 1
      });
      await db.insert('units', {
        'name': 'Gram',
        'code': 'G',
        'category_id': 1,
        'is_system': 1,
        'multiplier': 1
      });
      await db.insert('units', {
        'name': 'Liter',
        'code': 'L',
        'category_id': 2,
        'is_system': 1,
        'multiplier': 1
      });
      await db.insert('units', {
        'name': 'Milliliter',
        'code': 'ML',
        'category_id': 2,
        'is_system': 1,
        'multiplier': 1
      });
      await db.insert('units', {
        'name': 'Piece',
        'code': 'PCS',
        'category_id': 3,
        'is_system': 1,
        'multiplier': 1
      });
      await db.insert('units', {
        'name': 'Dozen',
        'code': 'DZN',
        'category_id': 3,
        'is_system': 1,
        'multiplier': 12
      });

      AppLogger.db('Sample data inserted');
    } catch (e) {
      AppLogger.error('Error inserting sample data: $e');
    }
  }

  // =========================================================================
  // ⚠️ DEVELOPER ONLY: WIPE & RECREATE DATABASE
  // =========================================================================
  // WARNING: THIS METHOD WILL PERMANENTLY DELETE ALL DATA.
  // REMOVE THIS FUNCTION BEFORE GOING INTO PRODUCTION.
  // =========================================================================
  Future<void> resetDatabase() async {
    AppLogger.info('⚠️ Wiping and Recreating Database...', tag: 'DB');

    // 1. Close current connection
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // 2. Get path and delete file
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'liaqat_store.db');
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
      AppLogger.info('Database file deleted: $path', tag: 'DB');
    }

    // 3. Re-initialize
    await database; // This will trigger _initDB -> _createDB -> _createTables
    AppLogger.db('Database successfully reset and recreated.');
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
