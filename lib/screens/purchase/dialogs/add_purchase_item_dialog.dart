import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/product_model.dart';
import '../../../../core/entity/purchase_bill_entity.dart';
import '../../../../domain/entities/money.dart';

class AddPurchaseItemDialog extends StatefulWidget {
  final Product product;
  final ValueChanged<PurchaseItemEntity> onConfirm;

  const AddPurchaseItemDialog({
    super.key,
    required this.product,
    required this.onConfirm,
  });

  @override
  State<AddPurchaseItemDialog> createState() => _AddPurchaseItemDialogState();
}

class _AddPurchaseItemDialogState extends State<AddPurchaseItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _batchCtrl;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: '1');
    _costCtrl = TextEditingController(
      text: (Money.tryParse(widget.product.avgCostPrice.toInputString()) ?? Money.zero).toInputString()
    );
    _batchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _batchCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final qty = double.tryParse(_qtyCtrl.text) ?? 1.0;
    final cost = Money.tryParse(_costCtrl.text) ?? Money.zero;

    final entity = PurchaseItemEntity(
      productId: widget.product.id ?? 0,
      productName: widget.product.nameEnglish,
      quantity: qty,
      costPrice: cost,
      batchNumber: _batchCtrl.text.isEmpty ? null : _batchCtrl.text.trim(),
      expiryDate: _expiryDate?.toIso8601String(),
    );

    if (!context.mounted) return;
    Navigator.of(context).pop();
    widget.onConfirm(entity);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(minWidth: 400, maxWidth: 480),
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.product.nameEnglish,
                      style: textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: loc.cancel,
                    onPressed: () {
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              const Divider(),
              const SizedBox(height: 16.0),

              // Quantity
              TextFormField(
                controller: _qtyCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: loc.quantity,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return loc.fieldRequired(loc.quantity);
                  }
                  final num = double.tryParse(val);
                  if (num == null || num <= 0) return loc.invalidQuantity;
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Cost Price
              TextFormField(
                controller: _costCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: loc.costPrice,
                  prefixText: 'Rs ',
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return loc.fieldRequired(loc.costPrice);
                  }
                  final money = Money.tryParse(val);
                  if (money == null || money.isNegative) return loc.invalidAmount;
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Batch Number (Optional)
              TextFormField(
                controller: _batchCtrl,
                decoration: InputDecoration(
                  labelText: loc.batchNumber,
                  hintText: loc.batchNumberOptional,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),

              // Expiry Date (Optional)
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
                  );
                  if (picked != null) {
                    if (!context.mounted) return;
                    setState(() {
                      _expiryDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: loc.expiryDate,
                    border: const OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _expiryDate == null
                            ? loc.none
                            : DateFormat('yyyy-MM-dd').format(_expiryDate!),
                        style: textTheme.bodyMedium?.copyWith(
                          color: _expiryDate == null
                              ? Theme.of(context).hintColor
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24.0),
              const Divider(),
              const SizedBox(height: 8.0),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(loc.addItemToBill),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
