import 'package:liaqat_store/domain/entities/money.dart';

class SaleItem {
  final int? id;
  final int saleId;
  final int itemId;
  final String itemName;
  final int quantity;
  final Money price;
  final Money total;
  final String itemNameEnglish;
  final String itemNameUrdu;
  final String unitName;

  SaleItem({
    this.id,
    required this.saleId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.total,
    required this.itemNameEnglish,
    required this.itemNameUrdu,
    required this.unitName,
  });

  /// Convert SaleItem to a database map
  Map<String, dynamic> toMap() {
    return {
      'saleId': saleId,
      'itemId': itemId,
      'quantity': quantity,
      'price': price.paisas,
      'total': total.paisas,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['saleId'] ?? map['sale_id'] ?? 0,
      itemId: map['itemId'] ?? map['product_id'] ?? 0,
      itemName: map['name'] ?? 'Unknown',
      quantity: map['quantity'] ?? map['quantity_sold'] ?? 0,
      price: Money((map['price'] ?? map['unit_price'] ?? 0) as int),
      total: Money((map['total'] ?? map['total_price'] ?? 0) as int),
      itemNameEnglish: map['item_name_english'] ?? '',
      itemNameUrdu: map['item_name_urdu'] ?? '',
      unitName: map['unit_name'] ?? '',
    );
  }
}

class Sale {
  final int? id;
  final int? customerId;
  final String? customerName; 
  final String billNumber;   

  final Money subTotal;
  final Money discount;
  final Money grandTotal;
  final Money cash;
  final Money bank;
  final Money credit;
  final DateTime date;
  final String status;
  final String? saleStatus;
  final String? receiptNumber;
  final String? saleSnapshot;
  final int? originalSaleId;
  final int printedCount;
  final String receiptLanguage;
  final int receiptPrinted;
  final int receiptPrintCount;
  final String? receiptPdfPath;

  Sale({
    this.id,
    this.customerId,
    this.customerName,
    required this.billNumber,
    required this.subTotal,
    required this.discount,
    required this.grandTotal,
    required this.cash,
    required this.bank,
    required this.credit,
    required this.date,
    this.status = 'COMPLETED',
    this.saleStatus,
    this.receiptNumber,
    this.saleSnapshot,
    this.originalSaleId,
    this.printedCount = 0,
    this.receiptLanguage = 'ur',
    this.receiptPrinted = 0,
    this.receiptPrintCount = 0,
    this.receiptPdfPath,
  });

  factory Sale.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['sale_date'] != null && map['sale_time'] != null) {
      try {
        parsedDate = DateTime.parse("${map['sale_date']} ${map['sale_time']}");
      } catch (_) {
        parsedDate = DateTime.tryParse(map['sale_date'] ?? '') ?? DateTime.now();
      }
    } else {
      parsedDate = DateTime.tryParse(map['sale_date'] ?? '') ?? DateTime.now();
    }

    return Sale(
      id: map['id'],
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      billNumber: map['bill_number'] ?? 'N/A',
      subTotal: Money(((map['grand_total'] ?? 0) as num).toInt() + ((map['discount'] ?? 0) as num).toInt()), // Reconstruct subtotal
      discount: Money(((map['discount'] ?? 0) as num).toInt()),
      grandTotal: Money(((map['grand_total'] ?? 0) as num).toInt()),
      cash: Money(((map['cash_amount'] ?? 0) as num).toInt()),
      bank: Money(((map['bank_amount'] ?? 0) as num).toInt()),
      credit: Money(((map['credit_amount'] ?? 0) as num).toInt()),
      date: parsedDate,
      status: map['status'] ?? 'COMPLETED',
      saleStatus: map['sale_status'],
      receiptNumber: map['receipt_number'],
      saleSnapshot: map['sale_snapshot'],
      originalSaleId: map['original_sale_id'],
      printedCount: map['printed_count'] ?? 0,
      receiptLanguage: map['receipt_language'] ?? 'ur',
      receiptPrinted: map['receipt_printed'] ?? 0,
      receiptPrintCount: map['receipt_print_count'] ?? 0,
      receiptPdfPath: map['receipt_pdf_path'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bill_number': billNumber,
      'customer_id': customerId,
      'grand_total': grandTotal.paisas,
      'discount': discount.paisas,
      'cash_amount': cash.paisas,
      'bank_amount': bank.paisas,
      'credit_amount': credit.paisas,
      'sale_time': date.toIso8601String(),
      'created_at': date.toIso8601String(),
      'status': status,
      'sale_status': saleStatus,
      'receipt_number': receiptNumber,
      'sale_snapshot': saleSnapshot,
      'original_sale_id': originalSaleId,
      'printed_count': printedCount,
      'receipt_language': receiptLanguage,
      'receipt_printed': receiptPrinted,
      'receipt_print_count': receiptPrintCount,
      'receipt_pdf_path': receiptPdfPath,
    };
  }
}