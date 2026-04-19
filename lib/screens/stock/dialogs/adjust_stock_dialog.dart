import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/entity/stock_item_entity.dart';
import '../../../core/res/app_tokens.dart';

class AdjustStockDialog extends StatefulWidget {
  final StockItemEntity item;
  final Function(double, String) onSave;
  final VoidCallback onCancel;

  const AdjustStockDialog({
    super.key,
    required this.item,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<AdjustStockDialog> {
  late TextEditingController _quantityCtrl;
  final _reasonCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _quantityCtrl = TextEditingController(
      text: widget.item.currentStock
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'\.00$'), ''),
    );
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
      ),
      child: Container(
        constraints: const BoxConstraints(minWidth: 400, maxWidth: 480),
        padding: const EdgeInsets.all(AppTokens.spacingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.adjustStock, style: textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onCancel,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(height: AppTokens.spacingLarge),
              // Current stock info
              Container(
                padding: const EdgeInsets.all(AppTokens.spacingMedium),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius:
                      BorderRadius.circular(AppTokens.cardBorderRadius),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: AppTokens.iconSizeMedium,
                        color: colorScheme.primary),
                    const SizedBox(width: AppTokens.spacingSmall),
                    Text(
                      '${loc.stock}: ${widget.item.currentStock} ${widget.item.unit}',
                      style: textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spacingMedium),
              // New quantity
              TextFormField(
                controller: _quantityCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: loc.quantity,
                  border: const OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return loc.required;
                  if (double.tryParse(value.trim()) == null) {
                    return loc.invalidAmount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.spacingMedium),
              TextFormField(
                controller: _reasonCtrl,
                decoration: InputDecoration(
                  labelText: loc.description,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? loc.required : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              // Actions — right-aligned per gold standard
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: AppTokens.spacingMedium),
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(loc.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newQty = double.tryParse(_quantityCtrl.text.trim());
      if (newQty == null) {
        return;
      }
      final diff = newQty - widget.item.currentStock;
      if (diff != 0) {
        widget.onSave(diff, _reasonCtrl.text);
      } else {
        widget.onCancel();
      }
    }
  }
}
