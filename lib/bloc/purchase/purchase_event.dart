import 'package:flutter/foundation.dart';
import '../../../core/entity/purchase_bill_entity.dart';

@immutable
abstract class PurchaseEvent {}

class InitializePurchase extends PurchaseEvent {}

class SelectPurchaseSupplier extends PurchaseEvent {
  final int supplierId;
  SelectPurchaseSupplier(this.supplierId);
}

class AddPurchaseItem extends PurchaseEvent {
  final PurchaseItemEntity item;
  AddPurchaseItem(this.item);
}

class RemovePurchaseItem extends PurchaseEvent {
  final int index;
  RemovePurchaseItem(this.index);
}

class UpdatePurchaseItem extends PurchaseEvent {
  final int index;
  final PurchaseItemEntity item;
  UpdatePurchaseItem(this.index, this.item);
}

class SubmitPurchase extends PurchaseEvent {
  final String invoiceNumber;
  final String? notes;
  SubmitPurchase({required this.invoiceNumber, this.notes});
}