import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/core/repositories/purchase_repository.dart';
import 'package:liaqat_store/core/repositories/invoice_repository.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/core/repositories/suppliers_repository.dart';

/// Persistent synthetic store. Call only after isolating the database path.
Future<void> seedKiryanaPerformanceStore(Database db, Directory lab) async {
  final marker = File('${lab.path}/dataset.json');
  if (await marker.exists()) return;
  final timer = Stopwatch()..start();
  final productCount =
      (await db.rawQuery('SELECT COUNT(*) n FROM products')).first['n'] as int;
  if (productCount != 1) {
    throw StateError('Refusing to seed a nonempty, unmarked store');
  }
  const catalog = [
    ('Basmati Rice', 'باسمتی چاول', 'Grains', 'اناج', 'KG', 320),
    ('Wheat Flour', 'گندم کا آٹا', 'Grains', 'اناج', 'KG', 140),
    ('Sugar', 'چینی', 'Grains', 'اناج', 'KG', 155),
    ('Masoor Dal', 'مسور کی دال', 'Pulses', 'دالیں', 'KG', 280),
    ('Moong Dal', 'مونگ کی دال', 'Pulses', 'دالیں', 'KG', 340),
    ('Chana Dal', 'چنے کی دال', 'Pulses', 'دالیں', 'KG', 260),
    ('White Chickpeas', 'سفید چنے', 'Pulses', 'دالیں', 'KG', 310),
    ('Black Chickpeas', 'کالے چنے', 'Pulses', 'دالیں', 'KG', 250),
    ('Cooking Oil', 'کوکنگ آئل', 'Oil and Ghee', 'تیل اور گھی', 'L', 520),
    ('Banaspati Ghee', 'بناسپتی گھی', 'Oil and Ghee', 'تیل اور گھی', 'KG', 510),
    (
      'Black Tea',
      'کالی چائے',
      'Tea and Drinks',
      'چائے اور مشروبات',
      'PCS',
      480
    ),
    ('Green Tea', 'سبز چائے', 'Tea and Drinks', 'چائے اور مشروبات', 'PCS', 260),
    ('Milk Powder', 'خشک دودھ', 'Dairy', 'دودھ کی مصنوعات', 'PCS', 620),
    ('UHT Milk', 'ڈبے کا دودھ', 'Dairy', 'دودھ کی مصنوعات', 'L', 280),
    ('Yogurt', 'دہی', 'Dairy', 'دودھ کی مصنوعات', 'PCS', 180),
    ('Red Chilli', 'لال مرچ', 'Spices', 'مصالحے', 'PCS', 150),
    ('Turmeric', 'ہلدی', 'Spices', 'مصالحے', 'PCS', 110),
    ('Coriander', 'دھنیا', 'Spices', 'مصالحے', 'PCS', 130),
    ('Cumin', 'زیرہ', 'Spices', 'مصالحے', 'PCS', 230),
    ('Biryani Masala', 'بریانی مصالحہ', 'Spices', 'مصالحے', 'PCS', 140),
    ('Salt', 'نمک', 'Spices', 'مصالحے', 'PCS', 70),
    ('Biscuits', 'بسکٹ', 'Snacks', 'سنیکس', 'PCS', 60),
    ('Potato Chips', 'آلو کے چپس', 'Snacks', 'سنیکس', 'PCS', 80),
    ('Chocolate', 'چاکلیٹ', 'Snacks', 'سنیکس', 'PCS', 120),
    ('Vermicelli', 'سویاں', 'Pantry', 'خشک خوراک', 'PCS', 130),
    ('Noodles', 'نوڈلز', 'Pantry', 'خشک خوراک', 'PCS', 100),
    ('Pasta', 'پاستا', 'Pantry', 'خشک خوراک', 'PCS', 240),
    ('Tomato Ketchup', 'ٹماٹر کیچپ', 'Pantry', 'خشک خوراک', 'PCS', 260),
    ('Pickle', 'اچار', 'Pantry', 'خشک خوراک', 'PCS', 220),
    (
      'Soft Drink',
      'ٹھنڈا مشروب',
      'Tea and Drinks',
      'چائے اور مشروبات',
      'PCS',
      150
    ),
    (
      'Fruit Juice',
      'پھلوں کا جوس',
      'Tea and Drinks',
      'چائے اور مشروبات',
      'PCS',
      180
    ),
    (
      'Mineral Water',
      'منرل واٹر',
      'Tea and Drinks',
      'چائے اور مشروبات',
      'PCS',
      90
    ),
    ('Bath Soap', 'نہانے کا صابن', 'Personal Care', 'ذاتی استعمال', 'PCS', 140),
    ('Shampoo', 'شیمپو', 'Personal Care', 'ذاتی استعمال', 'PCS', 340),
    ('Toothpaste', 'ٹوتھ پیسٹ', 'Personal Care', 'ذاتی استعمال', 'PCS', 220),
    (
      'Laundry Powder',
      'کپڑے دھونے کا پاؤڈر',
      'Household',
      'گھریلو سامان',
      'PCS',
      290
    ),
    (
      'Dishwashing Liquid',
      'برتن دھونے کا مائع',
      'Household',
      'گھریلو سامان',
      'PCS',
      240
    ),
    (
      'Floor Cleaner',
      'فرش صاف کرنے کا محلول',
      'Household',
      'گھریلو سامان',
      'PCS',
      310
    ),
    ('Tissue Box', 'ٹشو باکس', 'Household', 'گھریلو سامان', 'PCS', 160),
    (
      'Baby Diapers',
      'بچوں کے ڈائپر',
      'Personal Care',
      'ذاتی استعمال',
      'PCS',
      760
    ),
    ('Match Box', 'ماچس', 'Household', 'گھریلو سامان', 'PCS', 20),
    ('AA Batteries', 'بیٹریاں', 'Household', 'گھریلو سامان', 'PCS', 180),
    ('Dates', 'کھجور', 'Dry Fruit', 'خشک میوہ', 'KG', 580),
    ('Almonds', 'بادام', 'Dry Fruit', 'خشک میوہ', 'KG', 2100),
    ('Raisins', 'کشمش', 'Dry Fruit', 'خشک میوہ', 'KG', 850),
    ('Peanuts', 'مونگ پھلی', 'Dry Fruit', 'خشک میوہ', 'KG', 420),
    ('Bread', 'ڈبل روٹی', 'Bakery', 'بیکری', 'PCS', 170),
    ('Rusk', 'رس', 'Bakery', 'بیکری', 'PCS', 230),
    ('Cake', 'کیک', 'Bakery', 'بیکری', 'PCS', 180),
    ('Eggs', 'انڈے', 'Dairy', 'دودھ کی مصنوعات', 'PCS', 35),
  ];
  final units = {
    for (final row in await db.query('units'))
      row['code'] as String: row['id'] as int
  };
  final categories = <String, int>{};
  for (final item in catalog) {
    if (categories.containsKey(item.$3)) continue;
    final existing = await db
        .query('categories', where: 'name_english = ?', whereArgs: [item.$3]);
    categories[item.$3] = existing.isNotEmpty
        ? existing.first['id'] as int
        : await db.insert(
            'categories', {'name_english': item.$3, 'name_urdu': item.$4});
  }
  const names = [
    'Ali',
    'Ahmed',
    'Bilal',
    'Usman',
    'Hassan',
    'Imran',
    'Aslam',
    'Rashid',
    'Khalid',
    'Nadeem',
    'Ayesha',
    'Fatima',
    'Sana',
    'Maryam',
    'Zainab'
  ];
  const urduNames = [
    'علی',
    'احمد',
    'بلال',
    'عثمان',
    'حسن',
    'عمران',
    'اسلم',
    'راشد',
    'خالد',
    'ندیم',
    'عائشہ',
    'فاطمہ',
    'ثنا',
    'مریم',
    'زینب'
  ];
  const areas = [
    'Model Town',
    'Gulshan Colony',
    'Railway Road',
    'Main Bazaar',
    'Iqbal Town',
    'Satellite Town',
    'Sabzi Mandi',
    'New Market'
  ];
  await db.transaction((txn) async {
    final batch = txn.batch();
    final customers = (await txn.rawQuery('SELECT COUNT(*) n FROM customers'))
        .first['n'] as int;
    final suppliers = (await txn.rawQuery('SELECT COUNT(*) n FROM suppliers'))
        .first['n'] as int;
    for (var i = customers; i < 500; i++) {
      batch.insert('customers', {
        'name_english':
            '${names[i % names.length]} ${areas[i % areas.length]} ${i.toString().padLeft(3, '0')}',
        'name_urdu': '${urduNames[i % names.length]} گاہک $i',
        'contact_primary': '0398${i.toString().padLeft(7, '0')}',
        'address': 'House ${i + 1}, ${areas[i % areas.length]}, Test City',
        'credit_limit': 5000000,
        'outstanding_balance': 0,
        'is_active': 1
      });
    }
    for (var i = suppliers; i < 300; i++) {
      final c = catalog[i % catalog.length];
      batch.insert('suppliers', {
        'name_english':
            '${areas[i % areas.length]} ${c.$3} Distributors ${i.toString().padLeft(3, '0')}',
        'name_urdu': '${c.$4} سپلائر $i',
        'contact_primary': '0397${i.toString().padLeft(7, '0')}',
        'address': 'Warehouse ${i + 1}, ${areas[i % areas.length]}, Test City',
        'supplier_type': c.$3,
        'outstanding_balance': 0,
        'is_active': 1
      });
    }
    for (var i = 1; i < 20000; i++) {
      final c = catalog[i % catalog.length];
      final variant = i ~/ catalog.length;
      final brand =
          'Lab Brand ${(variant % 20 + 1).toString().padLeft(2, '0')}';
      final countPack = [
        'Tissue Box',
        'Baby Diapers',
        'Match Box',
        'AA Batteries',
        'Eggs'
      ].contains(c.$1);
      final liquidPack = [
        'Shampoo',
        'Dishwashing Liquid',
        'Floor Cleaner',
        'Soft Drink',
        'Fruit Juice',
        'Mineral Water'
      ].contains(c.$1);
      final pack = c.$5 == 'PCS'
          ? (countPack
              ? '${variant ~/ 20 + 1} piece pack'
              : '${100 + (variant ~/ 20) * 50}${liquidPack ? 'ml' : 'g'} pack')
          : 'Loose / per ${c.$5.toLowerCase()} / grade ${variant ~/ 20 + 1}';
      final cost = c.$6 * 100 + (variant % 20) * 125;
      final base = '200${i.toString().padLeft(9, '0')}';
      var sum = 0;
      for (var n = 0; n < 12; n++) {
        sum += int.parse(base[n]) * (n.isOdd ? 3 : 1);
      }
      final barcode = '$base${(10 - sum % 10) % 10}';
      batch.insert('products', {
        'item_code': 'KIR-${i.toString().padLeft(5, '0')}',
        'name_english': '$brand ${c.$1} $pack',
        'name_urdu': '${c.$2} $pack برانڈ ${variant % 20 + 1}',
        'category_id': categories[c.$3],
        'brand': brand,
        'unit_id': units[c.$5],
        'unit_type': c.$5,
        'packing_type': pack,
        'search_tags': '${c.$1} ${c.$2} ${c.$3} $brand',
        'min_stock_alert': 5,
        'current_stock': 0,
        'avg_cost_price': cost,
        'sale_price': cost + (cost ~/ 5),
        'barcode': barcode,
        'is_active': 1
      });
    }
    await batch.commit(noResult: true);
  });
  final products = await db.query('products',
      where: 'item_code LIKE ?', whereArgs: ['KIR-%'], orderBy: 'id');
  final suppliers = await db.query('suppliers', orderBy: 'id');
  final purchases = PurchaseRepository(ItemsRepository());
  final groups =
      List.generate(suppliers.length, (_) => <Map<String, dynamic>>[]);
  for (var i = 0; i < products.length; i++) {
    if (i % 13 == 0) continue; // Realistic out-of-stock catalog entries.
    final p = products[i];
    final qty = 8 + i % 33;
    final cost = p['avg_cost_price'] as int;
    groups[i % suppliers.length].add({
      'product_id': p['id'],
      'quantity': qty,
      'cost_price': cost,
      'total_amount': qty * cost,
      'batch_number': 'LAB-OPEN-${i.toString().padLeft(5, '0')}',
      'expiry_date': i % 9 == 0
          ? DateTime.now().add(Duration(days: 20 + i % 360)).toIso8601String()
          : null
    });
  }
  for (var i = 0; i < groups.length; i++) {
    if (groups[i].isEmpty) continue;
    await purchases.createPurchase(
        supplierId: suppliers[i]['id'] as int,
        items: groups[i],
        totalAmount:
            groups[i].fold<int>(0, (n, p) => n + (p['total_amount'] as int)),
        invoiceNumber: 'LAB-OPEN-${i + 1}',
        notes: 'Synthetic opening stock supplied on credit');
    if (i % 50 == 0) print('LAB_SEED purchases ${i + 1}/${groups.length}');
  }
  final customers =
      await db.query('customers', where: 'id != 1', orderBy: 'id');
  final invoices = InvoiceRepository(ItemsRepository());
  for (var i = 0; i < customers.length; i++) {
    final lines = <Map<String, dynamic>>[];
    for (var j = 0; j < 3; j++) {
      var index = (i * 7 + j * 19 + 1) % products.length;
      while (index % 13 == 0) {
        index = (index + 1) % products.length;
      }
      final p = products[index];
      final price = p['sale_price'] as int;
      lines.add({
        'product_id': p['id'],
        'name_english': p['name_english'],
        'name_urdu': p['name_urdu'],
        'quantity': 1.0,
        'unit_price': price,
        'total': price
      });
    }
    final total = lines.fold<int>(0, (n, l) => n + (l['total'] as int));
    final credit = i % 3 == 0 ? total : (i % 3 == 1 ? total ~/ 2 : 0);
    final cash = total - credit;
    final customer = customers[i];
    await invoices.createInvoiceWithTransaction(
        customerId: customer['id'] as int,
        items: lines,
        grandTotal: total,
        cashAmount: cash,
        creditAmount: credit,
        shopProfile: {
          'name_english': 'Kiryana Performance Lab',
          'name_urdu': 'کریانہ پرفارمنس لیب',
          'address': 'Synthetic Test Market'
        },
        customerData: Map<String, dynamic>.from(customer));
    if (credit > 0 && i % 5 == 0) {
      await CustomersRepository().addPayment(
          customer['id'] as int,
          credit ~/ 2,
          DateTime.now().toIso8601String(),
          'Synthetic partial udhaar collection');
    }
  }
  for (var i = 0; i < 50; i++) {
    await SuppliersRepository().addPayment(
        suppliers[i]['id'] as int, 10000, 'Synthetic supplier payment');
  }
  final checks = <String, Object>{};
  for (final table in [
    'products',
    'customers',
    'suppliers',
    'purchases',
    'purchase_items',
    'invoices',
    'invoice_items',
    'stock_activities',
    'customer_ledger',
    'supplier_ledger',
    'cash_ledger',
    'receipts'
  ]) {
    checks[table] =
        (await db.rawQuery('SELECT COUNT(*) n FROM $table')).first['n']!;
  }
  if (checks['products'] != 20000 ||
      checks['customers'] != 500 ||
      checks['suppliers'] != 300) {
    throw StateError('Fixture counts do not match');
  }
  if ((await db.rawQuery('PRAGMA foreign_key_check')).isNotEmpty) {
    throw StateError('Fixture foreign keys failed');
  }
  final stockDrift = await db.rawQuery(
      'SELECT p.id FROM products p LEFT JOIN (SELECT product_id,SUM(quantity_change) qty FROM stock_activities GROUP BY product_id) s ON s.product_id=p.id WHERE ABS(p.current_stock-COALESCE(s.qty,0))>0.000001');
  final customerDrift = await db.rawQuery(
      'SELECT c.id FROM customers c LEFT JOIN (SELECT customer_id,SUM(debit-credit) balance FROM customer_ledger GROUP BY customer_id) l ON l.customer_id=c.id WHERE c.id!=1 AND c.outstanding_balance!=COALESCE(l.balance,0)');
  final supplierDrift = await db.rawQuery(
      'SELECT s.id FROM suppliers s LEFT JOIN (SELECT supplier_id,SUM(debit-credit) balance FROM supplier_ledger GROUP BY supplier_id) l ON l.supplier_id=s.id WHERE s.outstanding_balance!=COALESCE(l.balance,0)');
  if (stockDrift.isNotEmpty ||
      customerDrift.isNotEmpty ||
      supplierDrift.isNotEmpty) {
    throw StateError('Fixture reconciliation failed');
  }
  checks.addAll({
    'synthetic': true,
    'seedMilliseconds': timer.elapsedMilliseconds,
    'stockDrift': 0,
    'customerDrift': 0,
    'supplierDrift': 0,
    'foreignKeyErrors': 0,
    'barcodeExamples': products
        .take(5)
        .map((p) => {
              'name': p['name_english'],
              'code': p['item_code'],
              'barcode': p['barcode']
            })
        .toList()
  });
  await marker
      .writeAsString(const JsonEncoder.withIndent('  ').convert(checks));
}
