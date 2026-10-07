import 'dart:ui' as ui;
import 'package:flutter/painting.dart' as flutter;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/money.dart';
import '../../models/invoice_model.dart';
import '../../models/receipt_model.dart';

/// Receipt presentation only: all amounts and quantities come from saved data.
class ReceiptPdf {
  static Future<void>? _fontLoaded;

  static Future<void> _loadFont() => _fontLoaded ??= (FontLoader('ReceiptUrdu')
        ..addFont(rootBundle.load('assets/fonts/NooriNastaleeq.ttf')))
      .load();

  static PdfPageFormat pageFormat(String width) => width == 'A4'
      ? PdfPageFormat.a4
      : PdfPageFormat((width == '58mm' ? 58 : 80) * PdfPageFormat.mm,
          297 * PdfPageFormat.mm);
  static Future<pw.Document> build({
    Invoice? invoice,
    Receipt? receipt,
    required Map<String, dynamic> shop,
    required Map<String, dynamic> preferences,
    Map<String, dynamic>? snapshot,
    Map<String, dynamic>? paymentDetails,
  }) async {
    final urdu = preferences['language'] == 'ur';
    String label(String en, String ur) => urdu ? ur : en;
    final size = preferences['receiptFontSize'] == 'small'
        ? 9.0
        : preferences['receiptFontSize'] == 'large'
            ? 13.0
            : 11.0;
    final format = pageFormat(preferences['paperWidth'] as String? ?? '80mm');
    final pdf = pw.Document();

    String money(int amount) => Money(amount).formatted;
    // Flutter shapes Nastaleeq using the font's OpenType tables. The PDF
    // library cannot embed this font reliably; rasterize only Arabic text.
    Future<pw.Widget> text(String value, {double? fontSize}) async {
      if (!RegExp(r'[\u0600-\u06ff]').hasMatch(value)) {
        return pw.Text(value, style: pw.TextStyle(fontSize: fontSize ?? size));
      }
      await _loadFont();
      final painter = flutter.TextPainter(
        text: flutter.TextSpan(
            text: value,
            style: flutter.TextStyle(
                fontFamily: 'ReceiptUrdu',
                fontSize: fontSize ?? size,
                color: const ui.Color(0xff000000))),
        textDirection: ui.TextDirection.rtl,
      )..layout(maxWidth: format.width - 20);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)..scale(3);
      painter.paint(canvas, const ui.Offset(2, 2));
      final picture = recorder.endRecording();
      final image = await picture.toImage(
          ((painter.width + 4) * 3).ceil(), ((painter.height + 4) * 3).ceil());
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final widget = pw.Image(pw.MemoryImage(data!.buffer.asUint8List()),
          width: painter.width + 4, height: painter.height + 4);
      image.dispose();
      picture.dispose();
      painter.dispose();
      return widget;
    }

    Future<pw.Widget> total(String title, String value) async => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(children: [
            if (urdu) pw.Text(value, textDirection: pw.TextDirection.ltr),
            pw.Expanded(
                child: pw.Align(
                    alignment: urdu
                        ? pw.Alignment.centerRight
                        : pw.Alignment.centerLeft,
                    child: await text(title))),
            if (!urdu) pw.Text(value, textDirection: pw.TextDirection.ltr),
          ]),
        );
    final name = shop[urdu ? 'shop_name_urdu' : 'shop_name_english'] ??
        shop[urdu ? 'name_urdu' : 'name_english'] ??
        shop[urdu ? 'name_ur' : 'name_en'] ??
        label('Liaqat Kiryana Store', 'لیاقت کریانہ اسٹور');
    final customer = snapshot?['customer'] as Map<String, dynamic>?;
    final snapshotItems = snapshot?['items'] as List<dynamic>?;
    final address = shop['shop_address'] ?? shop['address'];
    final phone = shop['contact_primary'] ?? shop['contact'] ?? shop['phone'];
    final content = <pw.Widget>[
      pw.Align(
          alignment: pw.Alignment.center,
          child: await text(name.toString(), fontSize: size + 3)),
      if (preferences['showAddress'] != false &&
          (address?.toString().isNotEmpty ?? false))
        await text(address.toString()),
      if (preferences['showPhone'] != false &&
          (phone?.toString().isNotEmpty ?? false))
        await text(phone.toString()),
      pw.Divider(),
      await total(
          label(invoice == null ? 'Receipt' : 'Invoice',
              invoice == null ? 'رسید' : 'بل'),
          invoice?.invoiceNumber ?? receipt!.receiptNumber),
      if (preferences['showDateTime'] != false)
        await total(
            label('Date', 'تاریخ'),
            DateFormat('yyyy-MM-dd HH:mm')
                .format(invoice?.date ?? receipt!.receiptDate)),
      if (invoice != null &&
          preferences['showCustomer'] != false &&
          (customer != null || invoice.customerName != null))
        await text(
            '${label('Customer', 'گاہک')}: ${customer?[urdu ? 'name_urdu' : 'name_english'] ?? invoice.customerName ?? ''}'),
      pw.Divider(),
      if (invoice != null) ...[
        for (var index = 0; index < invoice.items.length; index++)
          pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    await text(urdu &&
                            snapshotItems != null &&
                            index < snapshotItems.length
                        ? (snapshotItems[index]['name_ur'] ??
                                invoice.items[index].itemName)
                            .toString()
                        : invoice.items[index].itemName),
                    await total(
                        '${invoice.items[index].quantity} x ${money(invoice.items[index].unitPrice)}',
                        money(invoice.items[index].totalPrice)),
                  ])),
        pw.Divider(),
        await total(label('Subtotal', 'ذیلی کل'),
            money(invoice.totalAmount + invoice.discount)),
        if (invoice.discount != 0)
          await total(label('Discount', 'رعایت'), money(invoice.discount)),
        await total(label('Total', 'کل رقم'), money(invoice.totalAmount)),
        if (preferences['showPayment'] != false) ...[
          for (final entry in const {
            'cash': ['Cash', 'نقد'],
            'bank': ['Bank', 'بینک'],
            'credit': ['Credit', 'ادھار']
          }.entries)
            if (paymentDetails?[entry.key] is int &&
                paymentDetails![entry.key] != 0)
              await total(label(entry.value[0], entry.value[1]),
                  money(paymentDetails[entry.key] as int)),
        ],
      ] else ...[
        await total(label('Amount', 'رقم'), money(receipt!.amount)),
        if (preferences['showPayment'] != false)
          await total(label('Payment mode', 'ادائیگی'), receipt.paymentMode),
        if (receipt.notes?.isNotEmpty ?? false) await text(receipt.notes!),
      ],
    ];
    pdf.addPage(pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(10),
        maxPages: 100,
        theme: pw.ThemeData.withFont(
                base: pw.Font.helvetica(), bold: pw.Font.helveticaBold())
            .copyWith(defaultTextStyle: pw.TextStyle(fontSize: size)),
        build: (_) => content));
    return pdf;
  }
}
