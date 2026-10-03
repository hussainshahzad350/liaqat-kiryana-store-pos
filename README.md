# 🏪 Liaqat Kiryana Store POS

A desktop-focused, bilingual (Urdu/English) Point of Sale system built with
Flutter for small to medium retail businesses. The application is currently in
a structured stabilization and UI/UX improvement cycle; production readiness
must be established through the checks in the repository baseline.

> **Current project direction:** preserve the existing business-critical core
> and improve it incrementally rather than starting a full rewrite. See the
> [restructuring plan](docs/RESTRUCTURE_PLAN.md) and
> [recorded baseline](docs/BASELINE.md).

📋 Table of Contents

What is This Project? Key Features Technology Stack Project Structure Code Architecture Installation Database Schema Localization Performance Optimizations Known Issues & Roadmap Contributing License

🎯 What is This Project?

Liaqat Kiryana Store is a full-featured desktop POS system designed specifically for Pakistani retail stores (Kiryana shops). It addresses the unique challenges of South Asian retail:

Bilingual Interface: Seamless Urdu/English switching with proper RTL support

Credit Management: Track customer "Udhar" (credit) with balance aging reports

Offline-First: 100% local SQLite database—works without internet

Low-Stock Alerts: Automatic inventory reordering notifications

Thermal Printer Support: Generate 58mm/80mm receipts

Multi-Currency: PKR (Pakistani Rupee) formatting with localized number systems

🎬 Use Case Example

A shop owner in Lahore can: Quickly add items to cart by clicking product tiles Select a customer or create new one on-the-fly Accept mixed payments (Cash + Bank + Credit) Print thermal receipt in Urdu View real-time dashboard showing today's sales and low-stock items ✨ Key Features 🛒 Sales & POS Smart Cart System: Real-time price/quantity editing with live totals Fast Item Search: Barcode scanning + fuzzy search (English/Urdu) Flexible Payments: Split transactions (Cash + Bank + Credit) Customer Quick-Add: Create customers without leaving POS screen Recent Sales Sidebar: One-click bill cancellation with stock restoration

📦 Inventory Management

Paginated Stock View: Handles 10,000+ items smoothly (lazy loading) Low-Stock Dashboard: Color-coded alerts (red = critical, yellow = warning) Atomic Stock Updates: Race-condition-proof stock deduction Multi-Unit Support: KG, Liters, Pieces, Bags, Cartons

👥 Customer Management

Archive System: Hide inactive customers without deletion Balance Aging: Track debts by 30/60/90+ day buckets Credit Limit Enforcement: Prevent over-extension Search & Filter: Find customers by name/phone/balance

📊 Reports & Analytics

5 Report Types: Sales, Profit, Purchase, Customer Balance, Stock Value Date Range Filters: Compare "This Month vs Last Month" Visual Graphs: Sales trends and category-wise distribution Export Ready: Data structured for PDF/Excel generation (future)

🔧 System Features

Auto-Backup: Database snapshots before critical migrations Crash Recovery: Failed transactions don't corrupt data Multi-Language: Switch between Urdu ↔ English instantly Settings Hub: Configure receipt format, printer, notifications

🛠️ Technology Stack

Frontend Framework Flutter 3.0+: Cross-platform UI toolkit (Desktop-focused) Material Design 3: Modern, accessible component library Custom Widgets: Reusable cards, dialogs, and form components State Management BLoC Pattern: Feature modules use BLoC for events/state (see `lib/bloc/`) StatefulWidget Pattern: Local widget state is still used for screen-level UI interactions Provider (Ready): Architecture can still support Provider/Riverpod where needed Database Layer SQLite 3: Embedded relational database sqflite_ffi: Desktop SQLite adapter (Windows/Linux/macOS) Migration System: Version-controlled schema with auto-backup Localization (i18n) flutter_localizations: Official Flutter i18n support intl Package: Date/number formatting with locale awareness ARB Files: Standard translation format (.arb) RTL Support: Proper BiDi rendering for Urdu Code Paradigm Dart 3.0: Null-safe, type-safe language Async/Await: Future-based asynchronous programming SQL Transactions: ACID-compliant operations MVC-Inspired: Separation of database logic, UI, and business rules

📁 Project Structure

lib/ ├── core/ │ ├── database/ │ │ └── database_helper.dart # 🗄️ SQLite operations, migrations, CRUD │ └── utils/ │ └── logger.dart # 📝 Debug logging utility │ ├── l10n/ # 🌍 Internationalization │ ├── app_en.arb # English translations │ ├── app_ur.arb # Urdu translations │ ├── app_localizations.dart # Generated localization delegate │ ├── app_localizations_en.dart # Generated English class │ └── app_localizations_ur.dart # Generated Urdu class │ ├── screens/ │ ├── auth/ │ │ └── login_screen.dart # 🔐 Password authentication │ │ │ ├── home/ │ │ └── home_screen.dart # 🏠 Dashboard (sales summary, low stock) │ │ │ ├── sales/ │ │ └── sales_screen.dart # 💰 POS terminal (cart, checkout) │ │ │ ├── stock/ │ │ └── stock_screen.dart # 📦 Purchase/Sales/Stock tabs │ │ │ ├── master_data/ │ │ ├── items_screen.dart # 🛍️ Product management (paginated) │ │ ├── customers_screen.dart # 👤 Customer CRUD (archive/restore) │ │ ├── suppliers_screen.dart # 🚚 Supplier management │ │ ├── categories_screen.dart # 🏷️ Category hierarchy │ │ └── units_screen.dart # 📏 Unit conversions (KG, Liter) │ │ │ ├── reports/ │ │ └── reports_screen.dart # 📊 5 report types (tabs) │ │ │ ├── cash_ledger/ │ │ └── cash_ledger_screen.dart # 💵 Cash in/out tracking │ │ │ ├── settings/ │ │ └── settings_screen.dart # ⚙️ 5 settings tabs (profile, backup, etc.) │ │ │ └── about/ │ └── about_screen.dart # ℹ️ System info and credits │ └── main.dart # 🚀 App entry point, MaterialApp config

File Responsibilities

File Lines Purpose database_helper.dart ~600 Singleton database manager, migrations, all SQL queries sales_screen.dart ~900 Full POS logic (cart, checkout, bill deletion) home_screen.dart ~400 Dashboard with live stats, navigation drawer customers_screen.dart ~500 Paginated customer list with archive system items_screen.dart ~300 Product CRUD with infinite scroll app_localizations.dart ~2000 Auto-generated from .arb files

🏗️ Code Architecture

Design Pattern: MVC-Inspired ┌─────────────────┐ │ UI Layer │ ← StatefulWidgets, Material Design │ (screens/*) │ └────────┬────────┘ │ ↓ Calls ┌─────────────────┐ │ Business Logic │ ← Validation, calculations │ (in screens) │ └────────┬────────┘ │ ↓ Uses ┌─────────────────┐ │ Data Layer │ ← DatabaseHelper singleton │ (database_helper)│ ← Raw SQL queries └─────────────────┘ │ ↓ Stores ┌─────────────────┐ │ SQLite (FFI) │ ← liaqat_store.db file └─────────────────┘ Key Architectural Decisions

1️⃣ Database-First Approach

All data operations go through DatabaseHelper.instance No ORM layer—direct SQL for performance Transactions for multi-step operations (e.g., creating sale + updating stock) // Example: Atomic sale creation await db.transaction((txn) async { final saleId = await txn.insert('sales', saleData); await txn.insert('sale_items', itemData); await txn.rawUpdate('UPDATE products SET stock = stock - ?'); });

2️⃣ Pagination Pattern

Prevents memory overflow with large datasets: // Implemented in: items_screen, customers_screen, suppliers_screen class _ItemsScreenState extends State { int _page = 0; final int _limit = 20;

Future _loadMore() async { final result = await db.query( 'products', limit: _limit, offset: _page * _limit, ); setState(() => items.addAll(result)); } }

3️⃣ Localization Strategy

All user-facing strings use AppLocalizations.of(context)!.keyName Supports runtime language switching (no restart required) RTL-aware layouts with Directionality widget // Automatic RTL for Urdu return MaterialApp( locale: _locale, // ur or en supportedLocales: [Locale('en'), Locale('ur')], localizationsDelegates: AppLocalizations.localizationsDelegates, );

4️⃣ Error Recovery

Failed sales don't clear cart (user can retry) Stock validation happens atomically in database Backup created before schema migrations

💾 Database Schema

Core Tables sales (Main transaction table) CREATE TABLE sales ( id INTEGER PRIMARY KEY AUTOINCREMENT, bill_number TEXT NOT NULL UNIQUE, -- SB-YYMMXXXXXX format customer_id INTEGER, sale_date TEXT NOT NULL, -- YYYY-MM-DD sale_time TEXT NOT NULL, -- HH:MM grand_total REAL NOT NULL, cash_amount REAL NOT NULL, bank_amount REAL NOT NULL, credit_amount REAL NOT NULL, discount REAL DEFAULT 0, FOREIGN KEY (customer_id) REFERENCES customers(id) );

-- Performance Index CREATE INDEX idx_sales_customer ON sales(customer_id); sale_items (Line items) CREATE TABLE sale_items ( id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER NOT NULL, product_id INTEGER NOT NULL, quantity_sold REAL NOT NULL, unit_price REAL NOT NULL, total_price REAL NOT NULL, FOREIGN KEY (sale_id) REFERENCES sales(id), FOREIGN KEY (product_id) REFERENCES products(id) );

CREATE INDEX idx_sale_items_sale ON sale_items(sale_id); products CREATE TABLE products ( id INTEGER PRIMARY KEY AUTOINCREMENT, item_code TEXT UNIQUE, name_urdu TEXT NOT NULL, name_english TEXT NOT NULL, category_id INTEGER, current_stock REAL DEFAULT 0, min_stock_alert REAL DEFAULT 10, sale_price REAL DEFAULT 0, avg_cost_price REAL DEFAULT 0 ); customers CREATE TABLE customers ( id INTEGER PRIMARY KEY AUTOINCREMENT, name_english TEXT NOT NULL, name_urdu TEXT, contact_primary TEXT, credit_limit REAL DEFAULT 0, outstanding_balance REAL DEFAULT 0, is_active INTEGER DEFAULT 1 -- 1=Active, 0=Archived ); cash_ledger (Cash flow tracking) CREATE TABLE cash_ledger ( id INTEGER PRIMARY KEY AUTOINCREMENT, transaction_date TEXT NOT NULL, transaction_time TEXT NOT NULL, description TEXT NOT NULL, type TEXT NOT NULL, -- 'IN' or 'OUT' amount REAL NOT NULL, balance_after REAL, remarks TEXT ); Migration System // database_helper.dart Future _upgradeDB(Database db, int oldVersion, int newVersion) async { await backupDatabase(db, oldVersion); // Auto-backup!

for (int i = oldVersion + 1; i <= newVersion; i++) { switch (i) { case 2: await db.execute("ALTER TABLE customers ADD COLUMN email TEXT"); break; case 3: await db.execute("CREATE TABLE IF NOT EXISTS cash_ledger (...)"); break; } } }

🌍 Localization

Supported Languages Language Code Completeness RTL English en 100% (250+ strings) ❌ Urdu ur 100% ✅ Adding Translations Edit lib/l10n/app_en.arb: { "newKey": "Hello World", "@newKey": { "description": "Greeting message" } } Edit lib/l10n/app_ur.arb: { "newKey": "ہیلو ورلڈ" } Run code generation: flutter gen-l10n Use in code: Text(AppLocalizations.of(context)!.newKey) Parametrized Translations // app_en.arb { "itemsNeedReordering": "{count} items need reordering.", "@itemsNeedReordering": { "placeholders": { "count": { "type": "int" } } } } // Usage Text(loc.itemsNeedReordering(45)) // "45 items need reordering." ⚡ Performance Optimizations

Pagination Everywhere Items: Loads 20 at a time, infinite scroll Customers: 20 per page with SQL aggregation for stats Sales History: Limited to last 20 bills on POS screen
Database Indexes -- Critical indexes for joins CREATE INDEX idx_sales_customer ON sales(customer_id); CREATE INDEX idx_sale_items_sale ON sale_items(sale_id); CREATE INDEX idx_sale_items_product ON sale_items(product_id);
Lazy Widget Building // Only visible items are built ListView.builder( itemCount: items.length, itemBuilder: (context, index) => ItemCard(items[index]), )
Atomic SQL Operations // Single query instead of N+1 problem UPDATE products SET current_stock = current_stock - ? WHERE id = ? AND current_stock >= ? -- ✅ Check + Update in one atomic step 🐛 Known Issues & Roadmap
🔴 Critical (Fix Before Production)

[ ] Memory Leak: TextControllers in cart not disposed on WillPopScope exit [ ] ARB Metadata: Add placeholder definitions for parametrized strings [ ] Backup Method: Make backupDatabase() public in DatabaseHelper

🟡 High Priority

[ ] Add CASCADE DELETE for sale_items foreign key [ ] Implement barcode scanning with camera [ ] Add PDF receipt generation [ ] Customer photo upload/display

🟢 Future Enhancements

[ ] Cloud sync (Firebase/Supabase) [ ] Multi-user access with roles [ ] WhatsApp receipt sharing [ ] Purchase order management [ ] Expense tracking module

🚀 Installation

Prerequisites flutter --version # Flutter 3.0.0 or higher dart --version # Dart 3.0.0 or higher Setup Steps Clone Repository git clone https://github.com/yourusername/liaqat-store.git cd liaqat-store Install Dependencies flutter pub get Generate Localizations flutter gen-l10n Run on Desktop

Windows
flutter run -d windows

Linux
flutter run -d linux

macOS
flutter run -d macos Build Release flutter build windows --release

Output: build/windows/runner/Release/
First Launch Default password: 1234 (change in login_screen.dart) Sample data is auto-created (1 shop, 3 categories, 1 product, 1 customer) Database location: C:\Users[Username]\AppData\Local\liaqat_store\databases\

🤝 Contributing

Code Style Follow Effective Dart Use flutter analyze before committing Format with dart format lib/ Commit Messages feat: Add barcode scanner integration fix: Resolve memory leak in cart disposal docs: Update README installation steps style: Format code with dart format refactor: Extract checkout dialog to separate widget Pull Request Process Fork the repository Create feature branch (git checkout -b feat/amazing-feature) Commit changes (git commit -m 'feat: Add amazing feature') Push to branch (git push origin feat/amazing-feature) Open Pull Request

📜 License

This project is licensed under the MIT License.

MIT License

Copyright (c) 2024 Liaqat Kiryana Store

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

👨‍💻 Author

Hussain Shahzad 📧 hussainshahzad350@gmail.com 📱 +92 310-4523235

🙏 Acknowledgments

Flutter Team: For the amazing cross-platform framework sqflite_ffi: Desktop SQLite support Material Design: Beautiful, accessible components Pakistani Retail Community: For feature requirements and testing

📊 Project Stats

Repository counts and test coverage change over time. Do not rely on historical
counts in this README; use [the dated baseline](docs/BASELINE.md) and measured
coverage from a Flutter-capable environment.

🔗 Related Projects Flutter Desktop Samples sqflite_ffi Documentation Flutter Internationalization �

⭐ Star this repo if you find it useful! Made with ❤️ in Pakistan 🇵🇰 �
