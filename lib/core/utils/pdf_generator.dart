import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  static Future<void> exportLedger({
    required String customerName,
    required List<Map<String, dynamic>> ledgerData,
    required bool isUrdu,
  }) async {
    
    final font = isUrdu 
        ? await PdfGoogleFonts.notoSansArabicRegular() 
        : await PdfGoogleFonts.notoSansRegular();

    final doc = pw.Document();

    final headers = isUrdu 
      ? ['تاریخ', 'تفصیل', 'Udhar (Dr)', 'Jama (Cr)', 'بیلنس']
      : ['Date', 'Description', 'Bill Amt (Dr)', 'Received (Cr)', 'Balance'];

    final data = ledgerData.map((row) {
      final date = row['date'].toString().substring(0, 10);
      final desc = row['type'] == 'BILL' ? "Bill #${row['bill_no']}" : "Payment";
      return [
        date, desc, 
        row['dr'] > 0 ? row['dr'].toString() : '-',
        row['cr'] > 0 ? row['cr'].toString() : '-',
        row['balance'].toStringAsFixed(0),
      ];
    }).toList();

    doc.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: font).copyWith(textAlign: pw.TextAlign.start),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0, 
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(isUrdu ? "$customerName :لیجر" : "Ledger: $customerName", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text(DateFormat('dd-MM-yyyy').format(DateTime.now())),
                  ],
                )
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                headers: headers,
                data: data,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: {
                  0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(4),
                  2: const pw.FlexColumnWidth(2), 3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2),
                }
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }
}