import 'package:flutter/material.dart';
import '../../../../core/res/app_tokens.dart';
import '../../../../models/unit_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../utils/unit_validator.dart';

class EditUnitDialog extends StatefulWidget {
  final Unit unit;
  final List<UnitCategory> categories;
  final List<Unit> allUnits;
  final Function(Unit) onSave;

  const EditUnitDialog({
    super.key,
    required this.unit,
    required this.categories,
    required this.allUnits,
    required this.onSave,
  });

  @override
  State<EditUnitDialog> createState() => _EditUnitDialogState();
}

class _EditUnitDialogState extends State<EditUnitDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _multiplierCtrl;

  UnitCategory? _selectedCategory;
  bool _isBase = false;
  Unit? _baseUnit;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.unit.name);
    _codeCtrl = TextEditingController(text: widget.unit.code);
    _multiplierCtrl =
        TextEditingController(text: widget.unit.multiplier.toString());
    _selectedCategory =
        widget.categories.firstWhere((c) => c.id == widget.unit.category.id);
    _isBase = widget.unit.isBase;

    if (!_isBase) {
      _baseUnit = widget.allUnits.firstWhere(
          (u) => u.id == widget.unit.baseUnitId,
          orElse: () => widget.unit);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _multiplierCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      title: Text(loc.editItem, style: textTheme.titleLarge),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Section
                Text(
                  'Category: ${_selectedCategory?.name}',
                  style: textTheme.labelLarge
                      ?.copyWith(color: colorScheme.outline),
                ),
                const SizedBox(height: AppTokens.spacingMedium),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: loc.name),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: AppTokens.spacingMedium),

                // Code
                TextFormField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(labelText: 'Code'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: AppTokens.spacingLarge),

                // Base Status
                if (_isBase)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTokens.spacingMedium),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppTokens.borderRadiusSmall),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: AppTokens.spacingMedium),
                        Expanded(
                          child: Text(
                            'This is the Base Unit for ${_selectedCategory?.name}.',
                            style: textTheme.bodySmall
                                ?.copyWith(color: Colors.brown),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  TextFormField(
                  TextFormField(
                    controller: _multiplierCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Multiplier (Conversion to Base)',
                      prefixText: '1 ${_codeCtrl.text} = ',
                      suffixText: _baseUnit?.code ?? '',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = int.tryParse(v);
                      if (val == null || val <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final unit = widget.unit.copyWith(
                name: _nameCtrl.text,
                code: _codeCtrl.text,
              );
              // Note: multiplier/baseUnitId change during edit might be restricted in some systems, 
              // but here we allow it if the current model supports it via copyWith.
              // However, copyWith in unit_model.dart doesn't have multiplier/baseUnitId yet.
              // I'll update the model later if needed, but for now I'll just use the constructor.
              
              final updatedUnit = Unit(
                id: unit.id,
                name: _nameCtrl.text,
                code: _codeCtrl.text,
                category: unit.category,
                baseUnitId: unit.baseUnitId, // Usually fixed on edit for simplicity
                multiplier: _isBase ? 1 : int.parse(_multiplierCtrl.text.trim()),
                isSystem: unit.isSystem,
                isActive: unit.isActive,
              );

              final unitsForValidation = widget.allUnits
                  .where((existingUnit) => existingUnit.id != updatedUnit.id)
                  .toList()
                ..add(updatedUnit);

              final validationError = updatedUnit.isBase
                  ? UnitValidator.validateBaseUnit(
                      updatedUnit.category,
                      unitsForValidation,
                    )
                  : UnitValidator.validateDerivedUnit(
                      updatedUnit,
                      unitsForValidation,
                    );
              if (validationError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(validationError),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
                return;
              }

              widget.onSave(updatedUnit);
              Navigator.pop(context);
            }
          },
          child: Text(loc.save),
        ),
      ],
    );
  }
}
