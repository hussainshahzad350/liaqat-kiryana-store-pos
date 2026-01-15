// test/integration/repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/customers_repository.dart';
import 'package:liaqat_store/core/repositories/sales_repository.dart';
import 'package:liaqat_store/core/repositories/cash_repository.dart';
import 'package:liaqat_store/core/repositories/stock_repository.dart';
import 'package:liaqat_store/domain/entities/money.dart';
import 'package:liaqat_store/models/customer_model.dart';

void main() {
  // Initialize FFI for desktop testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Reset database before each test
    await DatabaseHelper.instance.resetDatabase();
  });

  group('Money Class Integration Tests', () {
    test('converts paisas to Money correctly', () {
      final money = Money.fromPaisas(15000);
      expect(money.paisas, equals(15000));
      expect(money.rupees, equals(150.0));
    });

    test('converts Money to paisas correctly', () {
      final money = Money.fromPaisas(25050);
      expect(money.paisas, equals(25050));
      expect(money.toRupeesString(), equals('250.50'));
    });

    test('handles zero values', () {
      const money = Money.zero;
      expect(money.paisas, equals(0));
      expect(money.isZero, isTrue);
      expect(money.rupees, equals(0.0));
    });

    test('handles negative values', () {
      const money = Money(-5000);
      expect(money.paisas, equals(-5000));
      expect(money.isNegative, isTrue);
      expect(money.rupees, equals(-50.0));
    });

    test('preserves precision in calculations', () {
      final money1 = Money.fromPaisas(10050); // 100.50
      final money2 = Money.fromPaisas(5025); // 50.25

      final sum = money1 + money2;
      expect(sum.paisas, equals(15075)); // 150.75

      final diff = money1 - money2;
      expect(diff.paisas, equals(5025)); // 50.25
    });

    test('Money arithmetic operations work correctly', () {
      final money = Money.fromPaisas(10000); // 100.00

      final doubled = money * 2;
      expect(doubled.paisas, equals(20000));

      final halved = money / 2;
      expect(halved.paisas, equals(5000));
    });

    test('Money formatting works correctly', () {
      final money = Money.fromPaisas(123456); // 1234.56
      expect(money.formatted, equals('Rs 1,234.56'));
      expect(money.formattedNoDecimal, equals('Rs 1,235'));
    });
  });

  group('Database Schema Alignment Tests', () {
    test('all monetary columns are INTEGER type', () async {
      final db = await DatabaseHelper.instance.database;

      // Check customers table
      final customersInfo = await db.rawQuery('PRAGMA table_info(customers)');
      final creditLimitCol =
          customersInfo.firstWhere((col) => col['name'] == 'credit_limit');
      final outstandingBalanceCol = customersInfo
          .firstWhere((col) => col['name'] == 'outstanding_balance');

      expect(creditLimitCol['type'], equals('INTEGER'));
      expect(outstandingBalanceCol['type'], equals('INTEGER'));

      // Check invoices table (renamed from sales)
      final invoicesInfo = await db.rawQuery('PRAGMA table_info(invoices)');
      final grandTotalCol =
          invoicesInfo.firstWhere((col) => col['name'] == 'grand_total');
      final subTotalCol =
          invoicesInfo.firstWhere((col) => col['name'] == 'sub_total');
      final discountCol =
          invoicesInfo.firstWhere((col) => col['name'] == 'discount_total');

      expect(grandTotalCol['type'], equals('INTEGER'));
      expect(subTotalCol['type'], equals('INTEGER'));
      expect(discountCol['type'], equals('INTEGER'));

      // Check receipts table (renamed from payments)
      final receiptsInfo = await db.rawQuery('PRAGMA table_info(receipts)');
      final amountCol =
          receiptsInfo.firstWhere((col) => col['name'] == 'amount');

      expect(amountCol['type'], equals('INTEGER'));

      // Check products table
      final productsInfo = await db.rawQuery('PRAGMA table_info(products)');
      final avgCostCol =
          productsInfo.firstWhere((col) => col['name'] == 'avg_cost_price');
      final salePriceCol =
          productsInfo.firstWhere((col) => col['name'] == 'sale_price');

      expect(avgCostCol['type'], equals('INTEGER'));
      expect(salePriceCol['type'], equals('INTEGER'));
    });

    test('renamed tables exist with correct schema', () async {
      final db = await DatabaseHelper.instance.database;

      // Verify invoices table exists (was sales)
      final invoicesExists = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='invoices'");
      expect(invoicesExists.isNotEmpty, isTrue);

      // Verify receipts table exists (was payments)
      final receiptsExists = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='receipts'");
      expect(receiptsExists.isNotEmpty, isTrue);

      // Verify invoice_items table exists (was sale_items)
      final invoiceItemsExists = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='invoice_items'");
      expect(invoiceItemsExists.isNotEmpty, isTrue);
    });

    test('foreign key relationships are intact', () async {
      final db = await DatabaseHelper.instance.database;

      // Check invoices foreign key to customers
      final invoicesFk = await db.rawQuery('PRAGMA foreign_key_list(invoices)');
      final customerFk = invoicesFk.firstWhere(
        (fk) => fk['table'] == 'customers',
        orElse: () => {},
      );
      expect(customerFk.isNotEmpty, isTrue);

      // Check invoice_items foreign key to invoices
      final invoiceItemsFk =
          await db.rawQuery('PRAGMA foreign_key_list(invoice_items)');
      final invoiceFk = invoiceItemsFk.firstWhere(
        (fk) => fk['table'] == 'invoices',
        orElse: () => {},
      );
      expect(invoiceFk.isNotEmpty, isTrue);
    });
  });

  group('CustomersRepository Tests', () {
    late CustomersRepository customersRepo;

    setUp(() {
      customersRepo = CustomersRepository();
    });

    test('stores outstanding_balance as paisas', () async {
      final customer = Customer(
        nameEnglish: 'Test Customer',
        nameUrdu: 'ٹیسٹ کسٹمر',
        contactPrimary: '0300-1234567',
        creditLimit: 100000, // 1000.00 rupees in paisas
        outstandingBalance: 50000, // 500.00 rupees in paisas
      );

      final customerId = await customersRepo.addCustomer(customer);
      expect(customerId, greaterThan(0));

      final retrieved = await customersRepo.getCustomerById(customerId);
      expect(retrieved, isNotNull);
      expect(retrieved!.outstandingBalance, equals(50000));
      expect(retrieved.creditLimit, equals(100000));
    });

    test('addPayment updates balance correctly with paisas', () async {
      // Create customer with balance
      final customer = Customer(
        nameEnglish: 'Payment Test',
        nameUrdu: 'پیمنٹ ٹیسٹ',
        contactPrimary: '0300-9999999',
        creditLimit: 200000,
        outstandingBalance: 100000, // 1000.00 rupees
      );

      final customerId = await customersRepo.addCustomer(customer);

      // Add payment of 50000 paisas (500.00 rupees)
      await customersRepo.addPayment(
        customerId,
        50000,
        '2026-01-15',
        'Test payment',
      );

      // Verify balance reduced
      final updated = await customersRepo.getCustomerById(customerId);
      expect(updated!.outstandingBalance, equals(50000)); // 1000 - 500 = 500
    });

    test('checkCreditLimit uses paisas correctly', () async {
      final customer = Customer(
        nameEnglish: 'Credit Test',
        nameUrdu: 'کریڈٹ ٹیسٹ',
        contactPrimary: '0300-8888888',
        creditLimit: 100000, // 1000.00 rupees
        outstandingBalance: 80000, // 800.00 rupees
      );

      final customerId = await customersRepo.addCustomer(customer);

      // Try to purchase 30000 paisas (300.00 rupees) - should exceed limit
      final result = await customersRepo.checkCreditLimit(customerId, 30000);

      expect(result['allowed'], isFalse);
      expect(result['potentialBalance'], equals(110000)); // 800 + 300 = 1100
      expect(result['excess'], equals(10000)); // 1100 - 1000 = 100
    });

    test('getTotalOutstandingBalance returns paisas', () async {
      // Add multiple customers with balances
      await customersRepo.addCustomer(Customer(
        nameEnglish: 'Customer 1',
        contactPrimary: '0300-1111111',
        outstandingBalance: 50000,
      ));

      await customersRepo.addCustomer(Customer(
        nameEnglish: 'Customer 2',
        contactPrimary: '0300-2222222',
        outstandingBalance: 75000,
      ));

      final total = await customersRepo.getTotalOutstandingBalance();
      expect(total, equals(125000)); // 50000 + 75000
    });
  });

  group('SalesRepository Tests', () {
    late SalesRepository salesRepo;

    setUp(() {
      salesRepo = SalesRepository();
    });

    test('createSale stores grand_total as paisas', () async {
      final saleData = {
        'customer_id': null,
        'grand_total_paisas': 145000, // 1450.00 rupees (after 50 discount)
        'discount_paisas': 5000, // 50.00 rupees
        'cash_paisas': 145000,
        'bank_paisas': 0,
        'items': [
          {
            'id': 1,
            'name_english': 'Test Product',
            'quantity': 10,
            'sale_price': 15000, // 150.00 per unit
            'total': 150000, // 10 * 150 = 1500
          }
        ],
      };

      final saleId = await salesRepo.createSale(saleData);
      expect(saleId, greaterThan(0));

      final sale = await salesRepo.getSaleById(saleId);
      expect(sale, isNotNull);
      expect(sale!.grandTotal, equals(145000));
    });

    test('validates Money values before insert', () async {
      final invalidSaleData = {
        'customer_id': null,
        'grand_total_paisas': 'invalid', // Should be int
        'items': [],
      };

      expect(
        () => salesRepo.createSale(invalidSaleData),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getTodaySales returns paisas', () async {
      // Create a sale
      final saleData = {
        'customer_id': null,
        'grand_total_paisas': 100000,
        'discount_paisas': 0,
        'cash_paisas': 100000,
        'bank_paisas': 0,
        'items': [
          {
            'id': 1,
            'name_english': 'Product',
            'quantity': 5,
            'sale_price': 20000,
            'total': 100000,
          }
        ],
      };

      await salesRepo.createSale(saleData);

      final todayTotal = await salesRepo.getTodaySales();
      expect(todayTotal, greaterThanOrEqualTo(100000));
    });
  });

  group('CashRepository Tests', () {
    late CashRepository cashRepo;

    setUp(() {
      cashRepo = CashRepository();
    });

    test('getCurrentCashBalance returns Money', () async {
      final balance = await cashRepo.getCurrentCashBalance();
      expect(balance, isA<Money>());
      expect(balance.paisas, isA<int>());
    });

    test('recordTransaction uses Money correctly', () async {
      final amount = Money.fromPaisas(50000); // 500.00 rupees

      await cashRepo.addCashIn(
        'Test cash in',
        amount,
        remarks: 'Testing',
      );

      final balance = await cashRepo.getCurrentCashBalance();
      expect(balance.paisas, greaterThanOrEqualTo(50000));
    });

    test('running balance calculated correctly with Money', () async {
      // Record multiple transactions
      await cashRepo.addCashIn('Sale 1', Money.fromPaisas(100000));
      await cashRepo.addCashIn('Sale 2', Money.fromPaisas(50000));
      await cashRepo.addCashOut('Expense', Money.fromPaisas(30000));

      final balance = await cashRepo.getCurrentCashBalance();
      expect(balance.paisas, equals(120000)); // 100000 + 50000 - 30000
    });
  });

  group('StockRepository Tests', () {
    late StockRepository stockRepo;

    setUp(() {
      stockRepo = StockRepository();
    });

    test('getStockSummary returns Money objects', () async {
      final summary = await stockRepo.getStockSummary();

      expect(summary.totalStockCost, isA<Money>());
      expect(summary.totalStockSalesValue, isA<Money>());
      expect(summary.totalStockCost.paisas, isA<int>());
    });

    test('product prices stored as paisas', () async {
      final db = await DatabaseHelper.instance.database;

      // Get a product
      final products = await db.query('products', limit: 1);
      if (products.isNotEmpty) {
        final product = products.first;
        expect(product['avg_cost_price'], isA<int>());
        expect(product['sale_price'], isA<int>());
      }
    });
  });

  group('All Repositories Schema Alignment', () {
    test('PurchaseRepository aligns with purchases table', () async {
      final db = await DatabaseHelper.instance.database;

      final tableInfo = await db.rawQuery('PRAGMA table_info(purchases)');
      final totalAmountCol =
          tableInfo.firstWhere((col) => col['name'] == 'total_amount');

      expect(totalAmountCol['type'], equals('INTEGER'));
    });

    test('SupplierRepository aligns with suppliers table', () async {
      final db = await DatabaseHelper.instance.database;

      final tableInfo = await db.rawQuery('PRAGMA table_info(suppliers)');
      final balanceCol =
          tableInfo.firstWhere((col) => col['name'] == 'outstanding_balance');

      expect(balanceCol['type'], equals('INTEGER'));
    });

    test('customer_ledger uses INTEGER for debit/credit/balance', () async {
      final db = await DatabaseHelper.instance.database;

      final tableInfo = await db.rawQuery('PRAGMA table_info(customer_ledger)');
      final debitCol = tableInfo.firstWhere((col) => col['name'] == 'debit');
      final creditCol = tableInfo.firstWhere((col) => col['name'] == 'credit');
      final balanceCol =
          tableInfo.firstWhere((col) => col['name'] == 'balance');

      expect(debitCol['type'], equals('INTEGER'));
      expect(creditCol['type'], equals('INTEGER'));
      expect(balanceCol['type'], equals('INTEGER'));
    });
  });

  group('Data Integrity Tests', () {
    test('transaction rollback on error preserves data', () async {
      final customersRepo = CustomersRepository();

      final customer = Customer(
        nameEnglish: 'Rollback Test',
        contactPrimary: '0300-7777777',
        outstandingBalance: 50000,
      );

      final customerId = await customersRepo.addCustomer(customer);

      // Try to add invalid payment (should fail and rollback)
      try {
        await customersRepo.addPayment(
            customerId, -1000, '2026-01-15', 'Invalid');
      } catch (e) {
        // Expected to fail
      }

      // Verify balance unchanged
      final retrieved = await customersRepo.getCustomerById(customerId);
      expect(retrieved!.outstandingBalance, equals(50000));
    });

    test('ledger balance consistency after multiple operations', () async {
      final customersRepo = CustomersRepository();

      final customer = Customer(
        nameEnglish: 'Ledger Test',
        contactPrimary: '0300-6666666',
        outstandingBalance: 0,
      );

      final customerId = await customersRepo.addCustomer(customer);

      // Add payment
      await customersRepo.addPayment(
          customerId, 100000, '2026-01-15', 'Payment 1');

      // Check ledger
      final ledger = await customersRepo.getCustomerLedger(customerId);
      expect(ledger.isNotEmpty, isTrue);

      // Verify balance in ledger matches customer balance
      final customerData = await customersRepo.getCustomerById(customerId);
      final lastLedgerEntry = ledger.first;

      expect(
          lastLedgerEntry['balance'], equals(customerData!.outstandingBalance));
    });
  });
}
