import 'package:equatable/equatable.dart';
import '../../domain/entities/money.dart';

class CartItem extends Equatable {
  final int id;
  final String nameUrdu;
  final String nameEnglish;
  final String? unitName;
  final String? itemCode;
  final double currentStock;
  final Money unitPrice;
  final double quantity;
  final Money total;

  const CartItem({
    required this.id,
    required this.nameUrdu,
    required this.nameEnglish,
    this.unitName,
    this.itemCode,
    required this.currentStock,
    required this.unitPrice,
    required this.quantity,
    required this.total,
  });

  CartItem copyWith({
    int? id,
    String? nameUrdu,
    String? nameEnglish,
    String? unitName,
    String? itemCode,
    double? currentStock,
    Money? unitPrice,
    double? quantity,
    Money? total,
  }) {
    return CartItem(
      id: id ?? this.id,
      nameUrdu: nameUrdu ?? this.nameUrdu,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      unitName: unitName ?? this.unitName,
      itemCode: itemCode ?? this.itemCode,
      currentStock: currentStock ?? this.currentStock,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nameUrdu,
        nameEnglish,
        unitName,
        itemCode,
        currentStock,
        unitPrice,
        quantity,
        total,
      ];
}
