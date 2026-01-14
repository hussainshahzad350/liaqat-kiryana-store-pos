import 'package:intl/intl.dart';

class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final int productId;
  final String itemName;
  final String? unit;
  final int quantity;
  final int rate;
  final int subtotal;

  const InvoiceItem({
    this.id,
    this.invoiceId,
    required this.productId,
    required this.itemName,
    this.unit,
    required this.quantity,
    required this.rate,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'item_name_snapshot': itemName,
      'quantity': quantity,
      'unit_price': rate,
      'total_price': subtotal,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'],
      invoiceId: map['invoiceId'] ?? map['invoice_id'],
      productId: map['productId'] ?? map['product_id'],
      itemName: map['name'] ?? map['item_name_snapshot'] ?? 'Unknown',
      quantity: (map['quantity'] ?? map['quantity_sold'] as num).toInt(),
      rate: (map['price'] ?? map['unit_price'] as num).toInt(),
      subtotal: (map['total'] ?? map['total_price'] as num).toInt(),
      unit: map['unit_name'] as String?,
    );
  }
}

class Invoice {
  final int? id;
  final int? customerId;
  final String? customerName;
  final String invoiceNumber;

  final int subTotal;
  final int discount;
  final int grandTotal;

  final DateTime date;
  final String status;
  final String? notes;
  final List<InvoiceItem> items;

  final String? saleSnapshot;
  final int? originalSaleId;
  final int printedCount;
  final String receiptLanguage;
  final String? receiptPdfPath;

  const Invoice({
    this.id,
    this.customerId,
    this.customerName,
    required this.invoiceNumber,
    required this.subTotal,
    required this.discount,
    required this.grandTotal,
    required this.date,
    this.status = 'COMPLETED',
    this.notes,
    this.items = const [],
    this.saleSnapshot,
    this.originalSaleId,
    this.printedCount = 0,
    this.receiptLanguage = 'ur',
    this.receiptPdfPath,
  });

  bool get isReadOnly => status == 'POSTED' || status == 'VOID';

  bool get isMathematicallyValid {
    final sumItems = items.fold<int>(0, (sum, item) => sum + item.subtotal);
    return (sumItems - discount) == grandTotal;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'invoice_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(date),
      'sub_total': subTotal,
      'discount_total': discount,
      'grand_total': grandTotal,
      'status': status,
      'notes': notes,
      'sale_snapshot': saleSnapshot,
      'original_sale_id': originalSaleId,
      'printed_count': printedCount,
      'receipt_language': receiptLanguage,
      'receipt_pdf_path': receiptPdfPath,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    final dateString = map['invoice_date'] ?? map['sale_date'];
    try {
      parsedDate = DateTime.parse(dateString as String);
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return Invoice(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] ?? map['bill_number'] as String,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
      date: parsedDate,
      subTotal: (map['sub_total'] as num?)?.toInt() ?? 0,
      discount: (map['discount_total'] ?? map['discount'] as num?)?.toInt() ?? 0,
      grandTotal: (map['grand_total'] as num).toInt(),
      status: map['status'] as String? ?? 'COMPLETED',
      notes: map['notes'] as String?,
      saleSnapshot: map['sale_snapshot'] as String?,
      originalSaleId: map['original_sale_id'] as int?,
      printedCount: (map['printed_count'] as num?)?.toInt() ?? 0,
      receiptLanguage: map['receipt_language'] as String? ?? 'ur',
      receiptPdfPath: map['receipt_pdf_path'] as String?,
      items: (map['items'] as List?)
              ?.map((item) => InvoiceItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}