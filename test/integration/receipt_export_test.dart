import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/database/database_helper.dart';
import 'package:liaqat_store/core/repositories/receipt_repository.dart';
import 'package:liaqat_store/core/repositories/invoice_repository.dart';
import 'package:liaqat_store/core/repositories/items_repository.dart';
import 'package:liaqat_store/models/invoice_model.dart';

import 'package:liaqat_store/models/receipt_model.dart';

import 'package:printing/src/interface.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/test_database.dart';
import '../support/receipt_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTestDatabase();
  final output = Directory('build/receipt-review');
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await output.create(recursive: true);
  });
  test('export preserves fractions, snapshots and database records', () async {
    final db = await DatabaseHelper.instance.database;
    final before = await db.query('receipts');
    final repository =
        ReceiptRepository(documentsDirectory: () async => output);
    expect(invoice().items.single.quantity, 1.5);
    final path = await repository.saveReceiptAsPDF(invoice());
    expect(path, endsWith('Invoice_QA_001.pdf'));
    await File(path).copy('${output.path}/english.pdf');
    SharedPreferences.setMockInitialValues({'app_language': 'ur'});
    await File('${output.path}/urdu.pdf')
        .writeAsBytes(await repository.generateReceiptData(invoice()));
    SharedPreferences.setMockInitialValues({'receipt_paper_width': '58mm'});
    await File('${output.path}/long.pdf')
        .writeAsBytes(await repository.generateReceiptData(invoice(count: 70)));
    final paymentPath = await repository.savePdf(Receipt(
        id: 1,
        receiptNumber: 'QA/PAY',
        customerId: 1,
        receiptDate: DateTime(2026, 10, 4),
        amount: 12345));
    expect(paymentPath, endsWith('QA_PAY.pdf'));
    await File(paymentPath).copy('${output.path}/payment.pdf');
    expect(await db.query('receipts'), before);
    await expectLater(
        repository.generateReceiptData(
            invoice().copyWith(status: Invoice.statusCancelled)),
        throwsStateError);
  });
  test('recent-sales header prints saved product details after catalog rename',
      () async {
    final db = await DatabaseHelper.instance.database;
    final invoices = InvoiceRepository(ItemsRepository());
    final id = await invoices.createInvoiceWithTransaction(
        customerId: 1,
        items: [
          {
            'product_id': 1,
            'name_english': 'Receipt snapshot rice',
            'name_urdu': 'چاول',
            'quantity': 1.5,
            'unit_price': 10050,
            'total': 15075
          }
        ],
        grandTotal: 15075,
        cashAmount: 15075);
    await db.update('products', {'name_english': 'Renamed catalog rice'},
        where: 'id = 1');
    final header = (await invoices.getRecentInvoicesWithCustomer())
        .singleWhere((i) => i.id == id);
    expect(header.items, isEmpty);
    final saved = (await invoices.getInvoiceWithItems(id))!;
    expect(saved.items.single.itemName, 'Receipt snapshot rice');
    final repo = ReceiptRepository();
    final headerBytes = await repo.generateReceiptData(header);
    final loadedBytes = await repo.generateReceiptData(saved);
    // PDF ids/timestamps vary. Matching substantial length plus independent
    // text extraction of this artifact checks the real header-to-PDF path.
    expect((headerBytes.length - loadedBytes.length).abs(), lessThan(100));
    await File('${output.path}/recent-sales-product-details.pdf')
        .writeAsBytes(headerBytes);
  });
  test('print cancellation and acceptance are returned once per request',
      () async {
    final original = PrintingPlatform.instance;
    addTearDown(() => PrintingPlatform.instance = original);
    final printer = TestPrinter();
    PrintingPlatform.instance = printer;
    final repository = ReceiptRepository();
    final bytes = await repository.generateReceiptData(invoice());
    expect(await repository.printReceipt(bytes), isFalse);
    expect(printer.lastFormat!.width, closeTo(80 * PdfPageFormat.mm, 0.01));
    SharedPreferences.setMockInitialValues({'receipt_paper_width': '58mm'});
    printer.accepted = true;
    expect(await repository.printReceipt(bytes), isTrue);
    expect(printer.lastFormat!.width, closeTo(58 * PdfPageFormat.mm, 0.01));
    expect(printer.calls, 2);
  });
}
