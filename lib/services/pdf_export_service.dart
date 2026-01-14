import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/entity/stock_activity_entity.dart';
import '../core/utils/logger.dart';

class PdfExportService {
  Future<pw.Font> _getFont() async {
    final fontData = await rootBundle.load('assets/fonts/NooriNastaleeq.ttf');
    return pw.Font.ttf(fontData);
  }

  Future<void> exportActivityPdf(StockActivityEntity activity, {bool openFile = true, String languageCode = 'en'}) async {
    try {
      final pdf = pw.Document();
      final font = await _getFont();
      
      _buildLedgerStylePage(pdf, font, activity, languageCode);

      final output = await getApplicationDocumentsDirectory();
      final fileName = 'activity_${activity.referenceNumber.replaceAll('/', '_')}.pdf';
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(await pdf.save());

      AppLogger.info('PDF saved to ${file.path}', tag: 'PdfExportService');

      if (openFile) {
        await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
      }
    } catch (e) {
      AppLogger.error('Failed to export PDF: $e', tag: 'PdfExportService');
      rethrow;
    }
  }

  void _buildLedgerStylePage(pw.Document pdf, pw.Font font, StockActivityEntity activity, String languageCode) {
    final isRtl = languageCode == 'ur';
    final textDirection = isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: font),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: isRtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Activity Report', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
                    pw.Text(DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now())),
                  ],
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),

              // Details
              _buildDetailRow('Activity Type:', activity.type.name.toUpperCase(), textDirection),
              _buildDetailRow('Reference:', activity.referenceNumber, textDirection),
              _buildDetailRow('Date:', DateFormat('yyyy-MM-dd hh:mm a').format(activity.timestamp), textDirection),
              _buildDetailRow('User:', activity.user, textDirection),
              _buildDetailRow('Status:', activity.status, textDirection),
              
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Body
              pw.Text('Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16), textDirection: textDirection),
              pw.SizedBox(height: 10),
              
              pw.Text(activity.description, textDirection: textDirection),
              pw.SizedBox(height: 10),

              if (activity.quantityChange != 0)
                _buildDetailRow('Quantity Impact:', '${activity.quantityChange > 0 ? '+' : ''}${activity.quantityChange}', textDirection),
              
              if (activity.financialImpact != null)
                _buildDetailRow('Financial Impact:', activity.financialImpact!.formatted, textDirection),

              // Footer
              pw.Spacer(),
              pw.Divider(),
              pw.Text('Liaqat Kiryana Store - POS System', textAlign: pw.TextAlign.center, style: const pw.TextStyle(color: PdfColors.grey)),
            ],
          );
        },
      ),
    );
  }

  pw.Widget _buildDetailRow(String label, String value, pw.TextDirection direction) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Directionality(
        textDirection: direction,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(value),
          ],
        ),
      ),
    );
  }
}