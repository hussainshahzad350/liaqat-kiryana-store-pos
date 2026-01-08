import 'package:equatable/equatable.dart';
import '../../../core/entity/purchase_bill_entity.dart';

abstract class PurchaseEvent extends Equatable {
  const PurchaseEvent();

  @override
  List<Object?> get props => [];
}

class InitializePurchase extends PurchaseEvent {}

class SelectPurchaseSupplier extends PurchaseEvent {
  final int? supplierId;
  const SelectPurchaseSupplier(this.supplierId);

  @override
  List<Object?> get props => [supplierId];
}

class AddPurchaseItem extends PurchaseEvent {
  final PurchaseItemEntity item;
  const AddPurchaseItem(this.item);

  @override
  List<Object?> get props => [item];
}

class RemovePurchaseItem extends PurchaseEvent {
  final int index;
  const RemovePurchaseItem(this.index);

  @override
  List<Object?> get props => [index];
}

class UpdatePurchaseItem extends PurchaseEvent {
  final int index;
  final PurchaseItemEntity item;
  const UpdatePurchaseItem(this.index, this.item);

  @override
  List<Object?> get props => [index, item];
}

class SubmitPurchase extends PurchaseEvent {
  final String invoiceNumber;
  final String notes;

  const SubmitPurchase({required this.invoiceNumber, required this.notes});

  @override
  List<Object?> get props => [invoiceNumber, notes];
}