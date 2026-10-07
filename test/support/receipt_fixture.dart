import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/models/invoice_model.dart';
import 'package:liaqat_store/models/invoice_item_model.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';

class TestPrinter extends PrintingPlatform {
  bool accepted = false;
  int calls = 0;
  PdfPageFormat? lastFormat;
  @override
  Future<bool> layoutPdf(
      Printer? printer,
      LayoutCallback onLayout,
      String name,
      PdfPageFormat format,
      bool dynamicLayout,
      bool usePrinterSettings,
      OutputType outputType,
      bool forceCustomPrintPaper) async {
    calls++;
    lastFormat = format;
    expect(ascii.decode((await onLayout(format)).take(4).toList()), '%PDF');
    return accepted;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Invoice invoice({int count = 1}) => Invoice(
      id: 1,
      invoiceNumber: 'QA/001',
      customerId: 1,
      date: DateTime(2026, 10, 4, 12, 30),
      totalAmount: 15075 * count,
      status: Invoice.statusCompleted,
      customerName: 'QA customer',
      notes: jsonEncode({
        'cash': 15075 * count,
        'snapshot': {
          'shop': {
            'shop_name_english': 'Receipt QA Store',
            'shop_name_urdu': 'لیاقت کریانہ اسٹور',
            'shop_address': 'QA address',
            'contact_primary': '0300 0000000'
          },
          'customer': {'name_english': 'QA customer', 'name_urdu': 'ٹیسٹ گاہک'},
          'items': List.generate(count, (_) => {'name_ur': 'چینی'})
        }
      }),
      items: List.generate(
          count,
          (index) => InvoiceItem.fromMap({
                'product_id': 1,
                'item_name_snapshot': 'Sugar ${index + 1}',
                'quantity': 1.5,
                'unit_price': 10050,
                'total_price': 15075
              })),
    );
