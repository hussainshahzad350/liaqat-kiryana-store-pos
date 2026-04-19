import 'package:flutter/material.dart';
import '../../../../core/res/app_tokens.dart';
import '../../../../models/unit_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../utils/unit_validator.dart';

class AddUnitDialog extends StatefulWidget {
  final List<UnitCategory> categories;
  final List<Unit> allUnits;
  final Function(Unit) onSave;

  const AddUnitDialog({
    super.key,
    required this.categories,
    required this.allUnits,
    required this.onSave,
  });

  @override
  State<AddUnitDialog> createState() => _AddUnitDialogState();
}

class _AddUnitDialogState extends State<AddUnitDialog> {
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
    _nameCtrl = TextEditingController();
    _codeCtrl = TextEditingController();
    _multiplierCtrl = TextEditingController(text: '1');
    if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
      _checkBaseUnitAvailability();
    }
  }

  void _checkBaseUnitAvailability() {
    if (_selectedCategory == null) return;

    final categoryUnits =
        widget.allUnits.where((u) => u.category.id == _selectedCategory!.id);
    final existingBase = categoryUnits.where((u) => u.isBase).firstOrNull;

    setState(() {
      if (existingBase == null) {
        _isBase = true; // Must be base if none exists
        _baseUnit = null;
      } else {
        _isBase = false;
        _baseUnit = existingBase;
      }
    });
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
    final inputUnitCode = _codeCtrl.text.trim();
    final displayUnitCode =
        inputUnitCode.isEmpty ? loc.unitCodeFallback : inputUnitCode;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      title: Text(loc.addItem, style: textTheme.titleLarge),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Selection
                DropdownButtonFormField<UnitCategory>(
                  value: _selectedCategory,
                  decoration: InputDecoration(labelText: loc.category),
                  items: widget.categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _checkBaseUnitAvailability();
                    });
                  },
                  validator: (v) => v == null ? loc.required : null,
                ),
                const SizedBox(height: AppTokens.spacingMedium),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: loc.name),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? loc.required : null,
                ),
                const SizedBox(height: AppTokens.spacingMedium),

                // Code
                TextFormField(
                  controller: _codeCtrl,
                  decoration: InputDecoration(labelText: loc.codeInputLabel),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? loc.required : null,
                ),
                const SizedBox(height: AppTokens.spacingLarge),

                // Base Unit Toggle (read-only; determined by category base availability)
                SwitchListTile(
                  title: Text(loc.isBaseUnitTitle),
                  subtitle: Text(_isBase
                      ? loc.isBaseUnitPrimarySubtitle
                      : loc.isBaseUnitDerivedSubtitle),
                  value: _isBase,
                  onChanged: null,
                ),

                // Multiplier (only for derived units)
                if (!_isBase && _baseUnit != null) ...[
                  const SizedBox(height: AppTokens.spacingMedium),
                  Text(
                    loc.conversionFromBaseUnit(_baseUnit!.code),
                    style: textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppTokens.spacingSmall),
                  TextFormField(
                    controller: _multiplierCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: loc.multiplier,
                      prefixText: loc.conversionPrefix(displayUnitCode),
                      suffixText: _baseUnit!.code,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return loc.required;
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed <= 0) {
                        return loc.invalidAmount;
                      }
                      if (parsed % 1 != 0) {
                        return loc.numericError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTokens.spacingSmall),
                  Container(
                    padding: const EdgeInsets.all(AppTokens.spacingSmall),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius:
                          BorderRadius.circular(AppTokens.borderRadiusSmall),
                    ),
                    child: Text(
                      loc.multiplierHint(
                          displayUnitCode.toUpperCase(), _baseUnit!.code),
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final hasExistingBase = _baseUnit != null;
              final shouldSaveAsBase = hasExistingBase ? false : _isBase;

              final multiplier = shouldSaveAsBase
                  ? 1
                  : UnitValidator.parsePositiveWholeMultiplier(
                      _multiplierCtrl.text);
              if (!shouldSaveAsBase && multiplier == null) {
                return;
              }

              final unit = Unit(
                id: 0,
                name: _nameCtrl.text,
                code: _codeCtrl.text,
                category: _selectedCategory!,
                baseUnitId: shouldSaveAsBase ? null : _baseUnit?.id,
                multiplier: multiplier!,
                isSystem: false,
                isActive: true,
              );

              final validationError = shouldSaveAsBase
                  ? UnitValidator.validateBaseUnit(
                      unit.category,
                      [...widget.allUnits, unit],
                    )
                  : UnitValidator.validateDerivedUnit(unit, widget.allUnits);
              if (validationError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(validationError),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
                return;
              }

              widget.onSave(unit);
              Navigator.pop(context);
            }
          },
          child: Text(loc.save),
        ),
      ],
    );
  }
}
