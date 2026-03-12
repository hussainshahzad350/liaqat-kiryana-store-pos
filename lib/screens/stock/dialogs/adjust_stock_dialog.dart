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
    return Padding(
      padding: const EdgeInsets.all(AppTokens.spacingMedium),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
                '${loc.stock}: ${widget.item.currentStock} ${widget.item.unit}'),
            const SizedBox(height: AppTokens.spacingMedium),
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
                if (double.tryParse(value) == null) return loc.invalidAmount;
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: Text(loc.cancel),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(loc.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newQty = double.parse(_quantityCtrl.text);
      final diff = newQty - widget.item.currentStock;
      if (diff != 0) {
        widget.onSave(diff, _reasonCtrl.text);
      } else {
        widget.onCancel();
      }
    }
  }
}
