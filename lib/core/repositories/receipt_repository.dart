import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/receipt_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/invoice_model.dart';
import '../utils/receipt_pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'invoice_repository.dart';
import 'items_repository.dart';

class ReceiptRepository {
  final Future<Directory> Function() _documentsDirectory;

  ReceiptRepository({Future<Directory> Function()? documentsDirectory})
      : _documentsDirectory =
            documentsDirectory ?? getApplicationDocumentsDirectory;

  /// Generate PDF receipt from receipt data
  Future<pw.Document> generatePdf(Receipt receipt,
      {Map<String, dynamic>? shopData}) async {
    return ReceiptPdf.build(
        receipt: receipt,
        shop: shopData ?? const {},
        preferences: await _receiptPreferences());
  }

  /// Save PDF to app documents
  Future<String> savePdf(Receipt receipt,
      {Map<String, dynamic>? shopData}) async {
    final pdf = await generatePdf(receipt, shopData: shopData);
    final bytes = await pdf.save();

    final appDocDir = await _documentsDirectory();
    final dateFolder = DateFormat('yyyy-MM-dd').format(receipt.receiptDate);
    final dir = Directory('${appDocDir.path}/receipts/$dateFolder');
    if (!await dir.exists()) await dir.create(recursive: true);

    final filePath = '${dir.path}/${_fileName(receipt.receiptNumber)}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  static String _fileName(String number) =>
      number.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_');

  // ========================================
  // INVOICE RECEIPT EXTENSIONS
  // ========================================

  /// Generate PDF data for an Invoice
  Future<Uint8List> generateReceiptData(Invoice invoice,
      {Map<String, dynamic>? shopData}) async {
    if (invoice.isCancelled) throw StateError('Cannot print cancelled invoice');
    // Recent-invoice rows contain document headers only. Print the immutable
    // saved item snapshots rather than an empty bill or today's catalog names.
    if (invoice.items.isEmpty && invoice.id != null) {
      final saved = await InvoiceRepository(ItemsRepository())
          .getInvoiceWithItems(invoice.id!);
      if (saved != null) invoice = invoice.copyWith(items: saved.items);
    }
    Map<String, dynamic>? snapshot;
    Map<String, dynamic>? paymentDetails;
    try {
      paymentDetails =
          jsonDecode(invoice.notes ?? '{}') as Map<String, dynamic>;
      snapshot = paymentDetails['snapshot'] as Map<String, dynamic>?;
    } catch (_) {
      // Legacy invoice notes may be plain text.
    }
    final pdf = await ReceiptPdf.build(
        invoice: invoice,
        shop: shopData ??
            (snapshot?['shop'] as Map<String, dynamic>?) ??
            const {},
        snapshot: snapshot,
        paymentDetails: paymentDetails,
        preferences: await _receiptPreferences());
    return pdf.save();
  }

  Future<Map<String, dynamic>> _receiptPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'language': prefs.getString('app_language') ?? 'en',
      'paperWidth': prefs.getString('receipt_paper_width') ?? '80mm',
      'receiptFontSize': prefs.getString('receipt_font_size') ?? 'medium',
      'showAddress': prefs.getBool('receipt_show_address') ?? true,
      'showPhone': prefs.getBool('receipt_show_phone') ?? true,
      'showDateTime': prefs.getBool('receipt_show_datetime') ?? true,
      'showCustomer': prefs.getBool('receipt_show_customer') ?? true,
      'showPayment': prefs.getBool('receipt_show_payment') ?? true,
    };
  }

  /// Track that an invoice has been printed
  Future<void> trackPrint(int invoiceId) async {
    // Optional implementation: update a 'print_count' or similar field in DB
  }

  /// Print the receipt using the system print dialog
  Future<bool> printReceipt(Uint8List receiptData) async {
    final preferences = await _receiptPreferences();
    return await Printing.layoutPdf(
        format: ReceiptPdf.pageFormat(preferences['paperWidth'] as String),
        dynamicLayout: false,
        onLayout: (PdfPageFormat format) async => receiptData);
  }

  /// Save the invoice as a PDF file and return the path
  Future<String> saveReceiptAsPDF(Invoice invoice) async {
    final bytes = await generateReceiptData(invoice);
    final dir = await _documentsDirectory();
    final file =
        File('${dir.path}/Invoice_${_fileName(invoice.invoiceNumber)}.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
