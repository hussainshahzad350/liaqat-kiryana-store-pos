import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/customer_model.dart';
import '../models/supplier_model.dart';
import '../domain/entities/money.dart';

class LedgerExportService {
  
  /// Generate and Print/Share PDF Ledger
  Future<void> exportToPdf(
    List<Map<String, dynamic>> ledgerData, 
    Customer customer, 
    {bool isUrdu = false}
  ) async {
    final doc = pw.Document();
    
    // Load Fonts
    // Ensure you have this font asset or fallback to a standard font
    pw.Font font;
    try {
      final fontData = await rootBundle.load('assets/fonts/NooriNastaleeq.ttf');
      font = pw.Font.ttf(fontData);
    } catch (e) {
      font = pw.Font.courier();
    }
    
    final baseFont = isUrdu ? font : pw.Font.courier();

    // Headers
    final headers = ['Date', 'Doc No', 'Description', 'Debit', 'Credit', 'Balance'];
    
    // Map Data
    final data = ledgerData.map((row) {
      final date = DateTime.tryParse(row['date'].toString()) ?? DateTime.now();
      final dateStr = DateFormat('dd-MM-yyyy').format(date);
      
      // Handle potential key mismatch from repo (dr/debit)
      final debit = (row['debit'] ?? row['dr'] ?? 0) as int;
      final credit = (row['credit'] ?? row['cr'] ?? 0) as int;
      final balance = (row['balance'] ?? 0) as int;
      
      final type = row['type'].toString();
      final refId = row['ref_no'].toString();
      final docNo = type == 'SALE' ? 'INV-$refId' : 'RCP-';

      return [
        dateStr,
        docNo,
        row['description'] ?? '',
        debit > 0 ? Money(debit).formattedNoDecimal : '-',
        credit > 0 ? Money(credit).formattedNoDecimal : '-',
        Money(balance).formattedNoDecimal,
      ];
    }).toList();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: baseFont),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(customer.nameEnglish, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      pw.Text(customer.contactPrimary ?? '', style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('CUSTOMER LEDGER', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Generated: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Table
              pw.Table.fromTextArray(
                headers: headers,
                data: data,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                },
                columnWidths: {
                  0: const pw.FlexColumnWidth(2), // Date
                  1: const pw.FlexColumnWidth(2), // Doc No
                  2: const pw.FlexColumnWidth(4), // Desc
                  3: const pw.FlexColumnWidth(2), // Dr
                  4: const pw.FlexColumnWidth(2), // Cr
                  5: const pw.FlexColumnWidth(2), // Bal
                }
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Ledger_${customer.nameEnglish}_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  /// Generate and Print/Share PDF Ledger for Supplier
  Future<void> exportSupplierLedgerToPdf(
    List<Map<String, dynamic>> ledgerData, 
    Supplier supplier, 
    {bool isUrdu = false, PdfColor? headerColor}
  ) async {
    final doc = pw.Document();
    
    pw.Font font;
    try {
      final fontData = await rootBundle.load('assets/fonts/NooriNastaleeq.ttf');
      font = pw.Font.ttf(fontData);
    } catch (e) {
      font = pw.Font.courier();
    }
    final baseFont = isUrdu ? font : pw.Font.courier();

    final headers = ['Date', 'Description', 'Purchase Bill', 'Payment Sent', 'Payable Balance'];
    
    final data = ledgerData.map((row) {
      final date = DateTime.tryParse(row['date'].toString()) ?? DateTime.now();
      final dateStr = DateFormat('dd-MM-yyyy').format(date);
      
      final cr = (row['cr'] as num?)?.toInt() ?? 0;
      final dr = (row['dr'] as num?)?.toInt() ?? 0;
      final balance = (row['balance'] as num?)?.toInt() ?? 0;

      return [
        dateStr,
        row['desc'] ?? '',
        cr > 0 ? Money(cr).formattedNoDecimal : '-',
        dr > 0 ? Money(dr).formattedNoDecimal : '-',
        Money(balance).formattedNoDecimal,
      ];
    }).toList();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: baseFont),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(supplier.nameEnglish, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text('SUPPLIER LEDGER', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: headers,
                data: data,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: headerColor ?? PdfColors.grey800),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Supplier_Ledger_${supplier.nameEnglish}_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  /// Generate CSV for Excel
  Future<String> exportToCsv(List<Map<String, dynamic>> ledgerData, Customer customer) async {
    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln('Date,Doc No,Description,Debit,Credit,Balance');

    for (var row in ledgerData) {
      final date = DateTime.tryParse(row['date'].toString()) ?? DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(date); // ISO format better for Excel
      
      final debit = (row['debit'] ?? row['dr'] ?? 0) as int;
      final credit = (row['credit'] ?? row['cr'] ?? 0) as int;
      final balance = (row['balance'] ?? 0) as int;
      
      final type = row['type'].toString();
      final refId = row['ref_no'].toString();
      final docNo = type == 'SALE' ? 'INV-$refId' : 'RCP-$refId';
      
      // Escape description for CSV
      String desc = row['description'] ?? '';
      if (desc.contains(',')) desc = '"$desc"';

      buffer.writeln('$dateStr,$docNo,$desc,${debit/100},${credit/100},${balance/100}');
    }

    // Save File
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/Ledger_${customer.nameEnglish}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(buffer.toString());
    
    return path;
  }

  /// Generate CSV for Supplier Ledger
  Future<String> exportSupplierLedgerToCsv(List<Map<String, dynamic>> ledgerData, Supplier supplier) async {
    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln('Date,Description,Purchase Bill,Payment Sent,Payable Balance');

    for (var row in ledgerData) {
      final date = DateTime.tryParse(row['date'].toString()) ?? DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      final cr = (row['cr'] as num?)?.toInt() ?? 0;
      final dr = (row['dr'] as num?)?.toInt() ?? 0;
      final balance = (row['balance'] as num?)?.toInt() ?? 0;
      
      // Escape description
      String desc = row['desc'] ?? '';
      if (desc.contains(',')) desc = '"$desc"';

      buffer.writeln('$dateStr,$desc,${cr/100},${dr/100},${balance/100}');
    }

    // Save File
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/Supplier_Ledger_${supplier.nameEnglish}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(buffer.toString());
    
    return path;
  }
}
