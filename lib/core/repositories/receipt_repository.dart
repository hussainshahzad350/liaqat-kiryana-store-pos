import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../../models/sale_model.dart';
import '../utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/utils/currency_utils.dart';

class ReceiptRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Generate structured data for receipt printing
  Future<Map<String, dynamic>> generateReceiptData(Sale sale) async {
    if (sale.status != 'COMPLETED') {
      throw Exception('Cannot generate receipt for non-completed sale (Status: ${sale.status})');
    }

    final db = await _dbHelper.database;
    
    // 1. Fetch Shop Profile
    final shopProfile = await db.query('shop_profile', limit: 1);
    final shop = shopProfile.isNotEmpty ? shopProfile.first : {};

    // 2. Fetch Sale Items (Snapshot only - NO JOIN)
    final itemsResult = await db.query(
      'sale_items',
      columns: [
        'quantity_sold',
        'unit_price',
        'total_price',
        'item_name_english',
        'item_name_urdu',
        'unit_name'
      ],
      where: 'sale_id = ?',
      whereArgs: [sale.id],
    );

    // 3. Fetch Customer (if any)
    Map<String, dynamic>? customer;
    if (sale.customerId != null) {
      final cResult = await db.query('customers', where: 'id = ?', whereArgs: [sale.customerId], limit: 1);
      if (cResult.isNotEmpty) customer = cResult.first;
    }

    return {
      'meta': {
        'language': sale.receiptLanguage,
        'direction': sale.receiptLanguage == 'ur' ? 'RTL' : 'LTR',
      },
      'shop': {
        'name_en': shop['shop_name_english'] ?? 'Liaqat Kiryana Store',
        'name_ur': shop['shop_name_urdu'] ?? 'لیاقت کریانہ اسٹور',
        'address': shop['shop_address'] ?? '',
        'contact': shop['contact_primary'] ?? '',
      },
      'bill': {
        'number': sale.billNumber,
        'date': DateFormat('yyyy-MM-dd').format(sale.date),
        'time': DateFormat('hh:mm a').format(sale.date),
        'grand_total': sale.grandTotalPaisas,
        'sub_total': sale.subTotalPaisas,
        'discount': sale.discountPaisas,
        'cash_received': sale.cashPaisas,
        'bank_received': sale.bankPaisas,
        'change': (sale.cashPaisas + sale.bankPaisas) - sale.grandTotalPaisas, // int calculation
        'prev_balance': customer?['outstanding_balance'] ?? 0, // Note: This is current balance, logic might need snapshot for historical balance
      },
      'customer': customer != null ? {
        'name': customer['name_english'],
        'contact': customer['contact_primary'],
      } : null,
      'items': itemsResult.map((item) => {
        'name_en': item['item_name_english'] ?? 'Unknown',
        'name_ur': item['item_name_urdu'] ?? '',
        'unit': item['unit_name'] ?? '',
        'qty': item['quantity_sold'],
        'price': item['unit_price'],
        'total': item['total_price'],
      }).toList(),
    };
  }

  /// Track that a receipt was generated/printed
  Future<void> trackPrint(int saleId, {String type = 'THERMAL'}) async {
    final db = await _dbHelper.database;
    try {
      await db.insert('receipts', {
        'sale_id': saleId,
        'receipt_type': type,
        'generated_at': DateTime.now().toIso8601String(),
      });
      
      // Also update the counter on the sale record
      await db.rawUpdate('''
        UPDATE sales 
        SET receipt_printed = 1, 
            receipt_print_count = receipt_print_count + 1,
            printed_count = printed_count + 1 
        WHERE id = ?
      ''', [saleId]);
    } catch (e) {
      AppLogger.error('Error tracking print: $e', tag: 'ReceiptRepo');
    }
  }

  /// Generate PDF Document (Internal Helper)
  Future<pw.Document> _generatePdfDocument(Map<String, dynamic> receiptData) async {
    final pdf = pw.Document();

    // Load fonts for Urdu support
    // Note: In a strictly offline environment, these fonts should be bundled in assets
    // and loaded via rootBundle. For now, we use PdfGoogleFonts which caches them.
    final font = await PdfGoogleFonts.notoNaskhArabicRegular();
    final fontBold = await PdfGoogleFonts.notoNaskhArabicBold();

    final isRtl = receiptData['meta']['direction'] == 'RTL';
    final textDirection = isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final align = isRtl ? pw.TextAlign.right : pw.TextAlign.left;
    final alignOpposite = isRtl ? pw.TextAlign.left : pw.TextAlign.right;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // --- Header ---
              pw.Text(
                isRtl ? receiptData['shop']['name_ur'] : receiptData['shop']['name_en'],
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
                textDirection: textDirection,
              ),
              pw.Text(
                receiptData['shop']['address'],
                style: const pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center,
                textDirection: textDirection,
              ),
              pw.Text(
                receiptData['shop']['contact'],
                style: const pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center,
                textDirection: textDirection,
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // --- Bill Info ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill: ${receiptData['bill']['number']}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('${receiptData['bill']['date']} ${receiptData['bill']['time']}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              if (receiptData['customer'] != null)
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text(
                    'Customer: ${receiptData['customer']['name']}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    textAlign: align,
                    textDirection: textDirection,
                  ),
                ),
              
              pw.Divider(),

              // --- Items Header ---
              pw.Row(
                children: [
                  pw.Expanded(flex: 4, child: pw.Text('Item', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: align, textDirection: textDirection)),
                  pw.Expanded(flex: 1, child: pw.Text('Qty', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Expanded(flex: 2, child: pw.Text('Price', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: alignOpposite)),
                  pw.Expanded(flex: 2, child: pw.Text('Total', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: alignOpposite)),
                ],
              ),
              pw.SizedBox(height: 4),

              // --- Items List ---
              ...((receiptData['items'] as List).map((item) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4, 
                        child: pw.Text(
                          isRtl ? item['name_ur'] : item['name_en'], 
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: align,
                          textDirection: textDirection,
                          maxLines: 2,
                        )
                      ),
                      pw.Expanded(
                        flex: 1, 
                        child: pw.Text(
                          '${item['qty']}', 
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.center
                        )
                      ),
                      pw.Expanded(
                        flex: 2, 
                        child: pw.Text(
                          CurrencyUtils.formatRupees(item['price']).replaceAll('Rs ', ''), 
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: alignOpposite
                        )
                      ),
                      pw.Expanded(
                        flex: 2, 
                        child: pw.Text(
                          CurrencyUtils.formatRupees(item['total']).replaceAll('Rs ', ''), 
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: alignOpposite
                        )
                      ),
                    ],
                  ),
                );
              }).toList()),

              pw.Divider(),

              // --- Totals ---
              _buildTotalRow('Subtotal', receiptData['bill']['sub_total']),
              _buildTotalRow('Discount', receiptData['bill']['discount']),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              _buildTotalRow('Grand Total', receiptData['bill']['grand_total'], isBold: true, fontSize: 14),
              pw.SizedBox(height: 4),
              _buildTotalRow('Cash', receiptData['bill']['cash_received']),
              if (receiptData['bill']['bank_received'] > 0)
                _buildTotalRow('Bank', receiptData['bill']['bank_received']),
              _buildTotalRow('Change', receiptData['bill']['change']),
              
              if (receiptData['bill']['prev_balance'] > 0) ...[
                 pw.SizedBox(height: 4),
                 pw.Divider(borderStyle: pw.BorderStyle.dashed),
                 _buildTotalRow('Prev Balance', receiptData['bill']['prev_balance']),
              ],

              // --- Footer ---
              pw.SizedBox(height: 10),
              pw.Text(
                'Thank you for shopping!',
                style: const pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Software by Liaqat Tech',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  /// Generate and print 80mm thermal receipt
  Future<void> printReceipt(Map<String, dynamic> receiptData) async {
    final pdf = await _generatePdfDocument(receiptData);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt-${receiptData['bill']['number']}',
    );
  }

  /// Save receipt as PDF to app documents
  Future<String> saveReceiptAsPDF(Sale sale) async {
    final receiptData = await generateReceiptData(sale);
    final pdf = await _generatePdfDocument(receiptData);
    final bytes = await pdf.save();

    final appDocDir = await getApplicationDocumentsDirectory();
    final dateFolder = DateFormat('yyyy-MM-dd').format(sale.date);
    final fileName = '${sale.billNumber}.pdf';
    
    final directory = Directory('${appDocDir.path}/receipts/$dateFolder');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // Store path in sales.receipt_pdf_path
    final db = await _dbHelper.database;
    await db.update(
      'sales',
      {'receipt_pdf_path': filePath},
      where: 'id = ?',
      whereArgs: [sale.id],
    );

    return filePath;
  }

  /// Open saved receipt with system viewer
  Future<void> openSavedReceipt(String path) async {
    if (Platform.isWindows) {
      await Process.run('explorer', [path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
    }
  }

  /// Get all saved PDFs
  Future<List<File>> getReceiptHistory() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${appDocDir.path}/receipts');
      
      if (await receiptsDir.exists()) {
        final List<File> files = [];
        await for (final entity in receiptsDir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('.pdf')) {
            files.add(entity);
          }
        }
        // Sort by modification time desc
        files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        return files;
      }
    } catch (e) {
      AppLogger.error('Error getting receipt history: $e', tag: 'ReceiptRepo');
    }
    return [];
  }

  pw.Widget _buildTotalRow(String label, int amount, {bool isBold = false, double fontSize = 10}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : null)),
        pw.Text(
          CurrencyUtils.formatRupees(amount),
          style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : null),
        ),
      ],
    );
  }

}