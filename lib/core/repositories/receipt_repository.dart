import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../../models/receipt_model.dart';
import '../../domain/entities/money.dart';
import '../utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert a new receipt
  Future<int> insertReceipt(Receipt receipt) async {
    final db = await _dbHelper.database;
    return await db.insert('receipts', receipt.toMap());
  }

  /// Update an existing receipt
  Future<void> updateReceipt(Receipt receipt) async {
    final db = await _dbHelper.database;
    await db.update(
      'receipts',
      receipt.toMap(),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );
  }

  /// Delete a receipt
  Future<void> deleteReceipt(int receiptId) async {
    final db = await _dbHelper.database;
    await db.delete('receipts', where: 'id = ?', whereArgs: [receiptId]);
  }

  /// Get receipt by ID
  Future<Receipt?> getReceiptById(int receiptId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'receipts',
      where: 'id = ?',
      whereArgs: [receiptId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Receipt.fromMap(result.first);
  }

  /// Get all receipts for a customer
  Future<List<Receipt>> getReceiptsByCustomer(int customerId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'receipts',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
    return result.map((e) => Receipt.fromMap(e)).toList();
  }

  /// Generate PDF receipt from receipt data
  Future<pw.Document> generatePdf(Receipt receipt, {Map<String, dynamic>? shopData}) async {
    final pdf = pw.Document();

    // Use default shop info if not provided
    shopData ??= {
      'name_en': 'Liaqat Kiryana Store',
      'name_ur': 'لیاقت کریانہ اسٹور',
      'address': '',
      'contact': '',
    };

    // Load font for Urdu support
    final fontData = await rootBundle.load('assets/fonts/NooriNastaleeq.ttf');
    final font = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(shopData['name_en'], textAlign: pw.TextAlign.center),
              pw.Text(shopData['address'], textAlign: pw.TextAlign.center),
              pw.Text(shopData['contact'], textAlign: pw.TextAlign.center),
              pw.Divider(),
              pw.Text('Receipt: ${receipt.receiptNumber}'),
              pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(receipt.receiptDate)}'),
              pw.Divider(),
              _buildTotalRow('Amount', receipt.amount),
              _buildTotalRow('Payment Mode', receipt.paymentMode),
              if (receipt.notes != null) pw.Text('Notes: ${receipt.notes}'),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Save PDF to app documents
  Future<String> savePdf(Receipt receipt, {Map<String, dynamic>? shopData}) async {
    final pdf = await generatePdf(receipt, shopData: shopData);
    final bytes = await pdf.save();

    final appDocDir = await getApplicationDocumentsDirectory();
    final dateFolder = DateFormat('yyyy-MM-dd').format(receipt.receiptDate);
    final dir = Directory('${appDocDir.path}/receipts/$dateFolder');
    if (!await dir.exists()) await dir.create(recursive: true);

    final filePath = '${dir.path}/${receipt.receiptNumber}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // Update DB with PDF path
    final db = await _dbHelper.database;
    await db.update(
      'receipts',
      {'receipt_pdf_path': filePath},
      where: 'id = ?',
      whereArgs: [receipt.id],
    );

    return filePath;
  }

  /// Open PDF with system viewer
  Future<void> openPdf(String path) async {
    if (Platform.isWindows) {
      await Process.run('explorer', [path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
    }
  }

  /// Helper: Build a row for totals / labels
  pw.Widget _buildTotalRow(String label, dynamic value) {
    final text = value is int ? Money(value).formattedNoDecimal : value.toString();
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label),
        pw.Text(text),
      ],
    );
  }
}
