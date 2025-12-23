class SaleItem {
  final int? id;
  final int saleId;
  final int itemId;
  final String itemName;
  final int quantity;
  final double price;
  final double total;

  SaleItem({
    this.id,
    required this.saleId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'saleId': saleId,
      'itemId': itemId,
      'quantity': quantity,
      'price': price,
      'total': total,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['saleId'],
      itemId: map['itemId'],
      itemName: map['name'] ?? 'Unknown',
      quantity: map['quantity'],
      price: map['price'],
      total: map['total'],
    );
  }
}

class Sale {
  final int? id;
  final int? customerId;
  final String? customerName; // Added
  final String billNumber;   // Changed from invoiceId
  final double totalAmount;
  final double discount;
  final double grandTotal;
  final double cashAmount;
  final double bankAmount;
  final double creditAmount;
  final DateTime date;
  final String status;

  Sale({
    this.id,
    this.customerId,
    this.customerName,
    required this.billNumber,
    required this.totalAmount,
    required this.discount,
    required this.grandTotal,
    required this.cashAmount,
    required this.bankAmount,
    required this.creditAmount,
    required this.date,
    this.status = 'COMPLETED',
  });

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      billNumber: map['bill_number'] ?? 'N/A',
      totalAmount: ((map['total_amount'] ?? 0) as num).toDouble(),
      discount: ((map['discount'] ?? 0) as num).toDouble(),
      grandTotal: ((map['grand_total'] ?? 0) as num).toDouble(),
      cashAmount: ((map['cash_amount'] ?? 0) as num).toDouble(),
      bankAmount: ((map['bank_amount'] ?? 0) as num).toDouble(),
      creditAmount: ((map['credit_amount'] ?? 0) as num).toDouble(),
      date: DateTime.tryParse(map['sale_date'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'COMPLETED',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bill_number': billNumber,
      'customer_id': customerId,
      'grand_total': grandTotal,
      'discount': discount,
      'cash_amount': cashAmount,
      'bank_amount': bankAmount,
      'credit_amount': creditAmount,
      'sale_time': date.toIso8601String(),
      'created_at': date.toIso8601String(),
      'status': status,
    };
  }
}