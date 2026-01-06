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
      version: 16, 
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

        case 10:
          await db.execute('''
            CREATE TABLE IF NOT EXISTS unit_categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              is_system INTEGER DEFAULT 0,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
          ''');

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

          // Insert default categories
          await db.insert('unit_categories', {'id': 1, 'name': 'Weight', 'is_system': 1});
          await db.insert('unit_categories', {'id': 2, 'name': 'Volume', 'is_system': 1});
          await db.insert('unit_categories', {'id': 3, 'name': 'Count', 'is_system': 1});
          await db.insert('unit_categories', {'id': 4, 'name': 'Length', 'is_system': 1});

          // Insert default units
          await db.insert('units', {'name': 'Kilogram', 'code': 'KG', 'category_id': 1, 'is_system': 1, 'multiplier': 1});
          await db.insert('units', {'name': 'Gram', 'code': 'G', 'category_id': 1, 'is_system': 1, 'multiplier': 1});
          await db.insert('units', {'name': 'Liter', 'code': 'L', 'category_id': 2, 'is_system': 1, 'multiplier': 1});
          await db.insert('units', {'name': 'Milliliter', 'code': 'ML', 'category_id': 2, 'is_system': 1, 'multiplier': 1});
          await db.insert('units', {'name': 'Piece', 'code': 'PCS', 'category_id': 3, 'is_system': 1, 'multiplier': 1});
          await db.insert('units', {'name': 'Dozen', 'code': 'DZN', 'category_id': 3, 'is_system': 1, 'multiplier': 12});

          AppLogger.db('Performed migration to v10 (Units & Unit Categories)');
          break;

        case 11:
          // Create Departments
          await db.execute('''
            CREATE TABLE IF NOT EXISTS departments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name_english TEXT NOT NULL,
              name_urdu TEXT,
              is_active INTEGER DEFAULT 1,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          // Create Subcategories
          await db.execute('''
            CREATE TABLE IF NOT EXISTS subcategories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category_id INTEGER NOT NULL,
              name_english TEXT NOT NULL,
              name_urdu TEXT,
              is_active INTEGER DEFAULT 1,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
            )
          ''');

          // Update Categories
          if (!await _columnExists(db, 'categories', 'department_id')) {
            await db.execute("ALTER TABLE categories ADD COLUMN department_id INTEGER REFERENCES departments(id) ON DELETE SET NULL");
          }
          if (!await _columnExists(db, 'categories', 'is_active')) {
            await db.execute("ALTER TABLE categories ADD COLUMN is_active INTEGER DEFAULT 1");
          }
          
          AppLogger.db('Performed migration to v11 (Departments, Subcategories)');
          break;

        case 12:
          // Add is_visible_in_pos to departments, categories, subcategories
          if (!await _columnExists(db, 'departments', 'is_visible_in_pos')) {
            await db.execute("ALTER TABLE departments ADD COLUMN is_visible_in_pos INTEGER DEFAULT 1");
          }
          if (!await _columnExists(db, 'categories', 'is_visible_in_pos')) {
            await db.execute("ALTER TABLE categories ADD COLUMN is_visible_in_pos INTEGER DEFAULT 1");
          }
          if (!await _columnExists(db, 'subcategories', 'is_visible_in_pos')) {
            await db.execute("ALTER TABLE subcategories ADD COLUMN is_visible_in_pos INTEGER DEFAULT 1");
          }
          AppLogger.db('Performed migration to v12 (Visibility flags)');
          break;

        case 13:
          if (!await _columnExists(db, 'products', 'brand')) {
            await db.execute("ALTER TABLE products ADD COLUMN brand TEXT");
          }
          if (!await _columnExists(db, 'products', 'unit_id')) {
            await db.execute("ALTER TABLE products ADD COLUMN unit_id INTEGER");
          }
          if (!await _columnExists(db, 'products', 'packing_type')) {
            await db.execute("ALTER TABLE products ADD COLUMN packing_type TEXT");
          }
          if (!await _columnExists(db, 'products', 'search_tags')) {
            await db.execute("ALTER TABLE products ADD COLUMN search_tags TEXT");
          }
          AppLogger.db('Performed migration to v13 (Product Master Data fields)');
          break;

        case 14:
          if (!await _columnExists(db, 'products', 'sub_category_id')) {
            await db.execute("ALTER TABLE products ADD COLUMN sub_category_id INTEGER");
          }
          AppLogger.db('Performed migration to v14 (Added sub_category_id to products)');
          break;

        case 15:
          await _migrateToV15(db);
          AppLogger.db('Performed migration to v15 (Accounting Overhaul & Ledger)');
          break;

        case 16:
          await db.execute('''
            CREATE TABLE IF NOT EXISTS purchases (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              supplier_id INTEGER NOT NULL,
              invoice_number TEXT,
              purchase_date TEXT,
              total_amount INTEGER DEFAULT 0,
              notes TEXT,
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
              FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE
            )
          ''');
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
          AppLogger.db('Performed migration to v16 (Supplier Tables)');
          break;

        default:
          AppLogger.db('No migration logic defined for v$i');
      }
    }
  }

  // 🛠️ Migration v15: Accounting Overhaul
  Future<void> _migrateToV15(Database db) async {
    // 1. Rename conflicting 'receipts' table (used for print logs) to 'sale_print_logs'
    if (await _tableExists(db, 'receipts')) {
      await db.execute('ALTER TABLE receipts RENAME TO sale_print_logs');
    }

    // 2. Create New Accounting Tables
    
    // Customers: Add Unique Index on Phone if not exists
    // (SQLite doesn't support adding UNIQUE constraint easily via ALTER, so we rely on index)
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_phone_unique ON customers(contact_primary)');

    // Trigger: Prevent Customer Name/Phone Update
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS prevent_customer_identity_change
      BEFORE UPDATE OF name_english, name_urdu, contact_primary ON customers
      BEGIN
          SELECT RAISE(ABORT, 'Critical Identity Fields (Name/Phone) are immutable.')
          WHERE OLD.name_english != NEW.name_english
             OR OLD.name_urdu != NEW.name_urdu
             OR OLD.contact_primary != NEW.contact_primary;
      END;
    ''');

    // Invoices (Replaces Sales)
    await db.execute('''
      CREATE TABLE invoices (
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
    await db.execute('CREATE INDEX idx_invoices_customer ON invoices(customer_id)');
    await db.execute('CREATE INDEX idx_invoices_date ON invoices(invoice_date)');

    // Invoice Items (Replaces Sale Items)
    await db.execute('''
      CREATE TABLE invoice_items (
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
    await db.execute('CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id)');

    // Receipts (Replaces Payments)
    await db.execute('''
      CREATE TABLE receipts (
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
    await db.execute('CREATE INDEX idx_receipts_customer ON receipts(customer_id)');
    await db.execute('CREATE INDEX idx_receipts_date ON receipts(receipt_date)');

    // Customer Ledger (Single Source of Truth)
    await db.execute('''
      CREATE TABLE customer_ledger (
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
    await db.execute('CREATE INDEX idx_ledger_customer_date ON customer_ledger(customer_id, transaction_date)');
    await db.execute('CREATE INDEX idx_ledger_ref ON customer_ledger(ref_type, ref_id)');

    // 3. Migrate Data
    
    // Migrate Sales -> Invoices
    await db.execute('''
      INSERT INTO invoices (id, invoice_number, customer_id, invoice_date, sub_total, discount_total, grand_total, created_at, status)
      SELECT id, bill_number, customer_id, sale_date || ' ' || sale_time, (grand_total + discount), discount, grand_total, created_at, status
      FROM sales
    ''');

    // Migrate SaleItems -> InvoiceItems
    await db.execute('''
      INSERT INTO invoice_items (invoice_id, product_id, item_name_snapshot, quantity, unit_price, total_price)
      SELECT sale_id, product_id, item_name_english, quantity_sold, unit_price, total_price
      FROM sale_items
    ''');

    // Migrate Payments -> Receipts
    // Generate receipt numbers like RCP-OLD-{id}
    await db.execute('''
      INSERT INTO receipts (receipt_number, customer_id, receipt_date, amount, notes)
      SELECT 'RCP-OLD-' || id, customer_id, date, amount, notes
      FROM payments
    ''');

    // 4. Populate Ledger (Complex: Needs to be done per customer, ordered by date)
    // We will use a temporary approach to insert all events then calculate running balance is hard in pure SQL without window functions (which might not be available on all target OS versions of SQLite).
    // However, Flutter FFI usually bundles a recent SQLite. We'll assume basic window functions or use a cursor approach in Dart if needed.
    // For robustness in migration script, we'll just insert raw rows and then update balance? No, balance must be correct.
    // Let's insert all events into ledger with 0 balance, then update.
    
    // Insert Invoices (Debit)
    await db.execute('''
      INSERT INTO customer_ledger (customer_id, transaction_date, description, ref_type, ref_id, debit, credit, balance)
      SELECT customer_id, invoice_date, 'Invoice #' || invoice_number, 'INVOICE', id, grand_total, 0, 0
      FROM invoices WHERE status = 'COMPLETED' AND customer_id IS NOT NULL
    ''');

    // Insert Receipts (Credit)
    await db.execute('''
      INSERT INTO customer_ledger (customer_id, transaction_date, description, ref_type, ref_id, debit, credit, balance)
      SELECT customer_id, receipt_date, 'Payment Received', 'RECEIPT', id, 0, amount, 0
      FROM receipts
    ''');

    // Recalculate Running Balance
    // Since we can't easily do this in one SQL statement for all customers without window functions, 
    // and we want to be safe, we will leave the balance as 0 here and rely on the application 
    // or a more complex query if supported. 
    // BUT, the requirement is "Ledger balance must be a running balance".
    // Let's try to update it using a correlated subquery or just reset it.
    // Given this is a migration run once, we can iterate in Dart if we were in the app logic, but here we are in DB helper.
    // We will use a standard SQL approach for running sum if possible, or just leave it for the Repositories to handle/recalc on first load? 
    // No, data integrity is key.
    
    // We will use a CTE to calculate running balance and update.
    // SQLite 3.25+ supports Window Functions. sqflite_common_ffi usually includes a recent version.
    try {
      await db.execute('''
        WITH CalculatedLedger AS (
          SELECT 
            id, 
            SUM(debit - credit) OVER (
              PARTITION BY customer_id 
              ORDER BY transaction_date, id
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) as running_bal
          FROM customer_ledger
        )
        UPDATE customer_ledger 
        SET balance = (SELECT running_bal FROM CalculatedLedger WHERE CalculatedLedger.id = customer_ledger.id);
      ''');
    } catch (e) {
      AppLogger.error('Window functions not supported, ledger balance might be 0. Re-calc required.', tag: 'DB');
    }

    // 5. Update Customer Outstanding Balance Cache
    await db.execute('''
      UPDATE customers 
      SET outstanding_balance = (
        SELECT COALESCE(SUM(debit - credit), 0)
        FROM customer_ledger
        WHERE customer_ledger.customer_id = customers.id
      )
    ''');
  }

  Future<bool> _tableExists(Database db, String table) async {
    final result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name=?", [table]);
    return result.isNotEmpty;
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
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
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
        credit_limit INTEGER DEFAULT 0,
        outstanding_balance INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 7. Sales
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

    // 8. Sale Items
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

    // 11. Payments Table
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

    // 12. Expense Categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_english TEXT NOT NULL,
        name_urdu TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 13. Receipt Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        receipt_type TEXT NOT NULL,
        generated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE
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

    // 16. Supplier Tables
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        invoice_number TEXT,
        purchase_date TEXT,
        total_amount INTEGER DEFAULT 0,
        notes TEXT,
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
        FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE
      )
    ''');

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

      // Departments
      await db.insert('departments', {'id': 1, 'name_english': 'Food', 'name_urdu': 'خوراک'}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('departments', {'id': 2, 'name_english': 'Cosmetics', 'name_urdu': 'کاسمیٹکس'}, conflictAlgorithm: ConflictAlgorithm.ignore);

      // Categories
      List<Map<String, dynamic>> categories = [
        {'name_urdu': 'چاول', 'name_english': 'Rice', 'department_id': 1},
        {'name_urdu': 'دال', 'name_english': 'Pulses', 'department_id': 1},
        {'name_urdu': 'تیل', 'name_english': 'Oil', 'department_id': 1},
      ];
      for(var cat in categories) {
        await db.insert('categories', cat, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      // Subcategories
      await db.insert('subcategories', {'category_id': 1, 'name_english': 'Basmati', 'name_urdu': 'باسمتی'}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('subcategories', {'category_id': 1, 'name_english': 'Irri', 'name_urdu': 'ایری'}, conflictAlgorithm: ConflictAlgorithm.ignore);

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

      // Unit Categories
      await db.insert('unit_categories', {'id': 1, 'name': 'Weight', 'is_system': 1});
      await db.insert('unit_categories', {'id': 2, 'name': 'Volume', 'is_system': 1});
      await db.insert('unit_categories', {'id': 3, 'name': 'Count', 'is_system': 1});
      await db.insert('unit_categories', {'id': 4, 'name': 'Length', 'is_system': 1});

      // Units
      await db.insert('units', {'name': 'Kilogram', 'code': 'KG', 'category_id': 1, 'is_system': 1, 'multiplier': 1});
      await db.insert('units', {'name': 'Gram', 'code': 'G', 'category_id': 1, 'is_system': 1, 'multiplier': 1});
      await db.insert('units', {'name': 'Liter', 'code': 'L', 'category_id': 2, 'is_system': 1, 'multiplier': 1});
      await db.insert('units', {'name': 'Milliliter', 'code': 'ML', 'category_id': 2, 'is_system': 1, 'multiplier': 1});
      await db.insert('units', {'name': 'Piece', 'code': 'PCS', 'category_id': 3, 'is_system': 1, 'multiplier': 1});
      await db.insert('units', {'name': 'Dozen', 'code': 'DZN', 'category_id': 3, 'is_system': 1, 'multiplier': 12});

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