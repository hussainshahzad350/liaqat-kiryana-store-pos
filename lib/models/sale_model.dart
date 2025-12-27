class SaleItem {
  final int? id;
  final int saleId;
  final int itemId;
  final String itemName;
  final int quantity;
  final int pricePaisas;
  final int totalPaisas;
  final String itemNameEnglish;
  final String itemNameUrdu;
  final String unitName;

  SaleItem({
    this.id,
    required this.saleId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.pricePaisas,
    required this.totalPaisas,
    required this.itemNameEnglish,
    required this.itemNameUrdu,
    required this.unitName,
  });

  /// Convert SaleItem to a database map
  ///
  /// Returns a map containing the fields 'saleId', 'itemId', 'quantity', 'price', and 'total'.
  ///
  /// This map is used to store the sale items in the database.
  Map<String, dynamic> toMap() {
    return {
      'saleId': saleId,
      'itemId': itemId,
      'quantity': quantity,
      'price': pricePaisas,
      'total': totalPaisas,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['saleId'] ?? map['sale_id'] ?? 0,
      itemId: map['itemId'] ?? map['product_id'] ?? 0,
      itemName: map['name'] ?? 'Unknown',
      quantity: map['quantity'] ?? map['quantity_sold'] ?? 0,
      pricePaisas: (map['price'] ?? map['unit_price'] ?? 0) as int,
      totalPaisas: (map['total'] ?? map['total_price'] ?? 0) as int,
      itemNameEnglish: map['item_name_english'] ?? '',
      itemNameUrdu: map['item_name_urdu'] ?? '',
      unitName: map['unit_name'] ?? '',
    );
  }
}

class Sale {
  final int? id;
  final int? customerId;
  final String? customerName; // Added
  final String billNumber;   // Changed from invoiceId

  // ALL PAISAS
  final int subTotalPaisas;
  final int discountPaisas;
  final int grandTotalPaisas;
  final int cashPaisas;
  final int bankPaisas;
  final int creditPaisas;
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
    required this.subTotalPaisas,
    required this.discountPaisas,
    required this.grandTotalPaisas,
    required this.cashPaisas,
    required this.bankPaisas,
    required this.creditPaisas,
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
    // Combine date and time if available for accurate timestamp
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
      subTotalPaisas: ((map['grand_total'] ?? 0) as num).toInt() + ((map['discount'] ?? 0) as num).toInt(),
      discountPaisas: ((map['discount'] ?? 0) as num).toInt(),
      grandTotalPaisas: ((map['grand_total'] ?? 0) as num).toInt(),
      cashPaisas: ((map['cash_amount'] ?? 0) as num).toInt(),
      bankPaisas: ((map['bank_amount'] ?? 0) as num).toInt(),
      creditPaisas: ((map['credit_amount'] ?? 0) as num).toInt(),
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

/// Convert this Sale object to a Map<String, dynamic> for database storage
///
/// This method is used to serialize the Sale object into a format that can be stored in the database.
///
/// The resulting Map contains the following fields:
///
/// - `bill_number`: The bill number of the sale.
/// - `customer_id`: The ID of the customer associated with the sale.
/// - `grand_total`: The grand total of the sale.
/// - `discount`: The discount applied to the sale.
/// - `cash_amount`: The amount of cash paid for the sale.
/// - `bank_amount`: The amount of bank payment made for the sale.
/// - `credit_amount`: The amount of credit given to the customer for the sale.
/// - `sale_time`: The timestamp of when the sale was made, in ISO 8601 format.
/// - `created_at`: The timestamp of when the sale record was created in the database, in ISO 8601 format.
/// - `status`: The status of the sale, either 'COMPLETED' or 'CANCELLED'.
/// - `sale_status`: The status of the sale, either 'COMPLETED', 'CANCELLED', or 'PENDING'.
/// - `receipt_number`: The number of the receipt associated with the sale.
/// - `sale_snapshot`: A JSON string representing the sale record at the time it was created.
/// - `original_sale_id`: The ID of the original sale if this sale is a cancelled sale.
/// - `printed_count`: The number of times the sale has been printed.
  Map<String, dynamic> toMap() {
    return {
      'bill_number': billNumber,
      'customer_id': customerId,
      'grand_total': grandTotalPaisas,
      'discount': discountPaisas,
      'cash_amount': cashPaisas,
      'bank_amount': bankPaisas,
      'credit_amount': creditPaisas,
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