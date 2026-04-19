import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/res/app_tokens.dart';
import '../../../../core/repositories/cash_repository.dart';
import '../../../../domain/entities/money.dart';
import '../../../../models/cash_ledger_model.dart';

class AddTransactionDialog extends StatefulWidget {
  final String initialType;
  final CashRepository repository;
  final VoidCallback onSaved;

  const AddTransactionDialog({
    super.key,
    required this.initialType,
    required this.repository,
    required this.onSaved,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  late String _selectedType;
  late DateTime _selectedDate;
  PaymentMode _paymentMode = PaymentMode.cash;

  final List<PaymentMode> _paymentModes = [
    PaymentMode.cash,
    PaymentMode.card,
    PaymentMode.bank,
    PaymentMode.easyPaisa,
    PaymentMode.jazzCash,
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.dialogBorderRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppTokens.dialogWidth,
          maxHeight: AppTokens.dialogHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedType == 'IN' ? loc.newCashIn : loc.newCashOut,
                style: textTheme.titleLarge
                    ?.copyWith(color: colorScheme.onSurface),
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Type Selector
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _selectedType = 'IN'),
                              child: Container(
                                padding: const EdgeInsets.all(
                                    AppTokens.spacingStandard),
                                decoration: BoxDecoration(
                                  color: _selectedType == 'IN'
                                      ? colorScheme.primaryContainer
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.buttonBorderRadius),
                                  border: Border.all(
                                    color: _selectedType == 'IN'
                                        ? colorScheme.primary
                                        : colorScheme.outline,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(loc.cashIn,
                                    style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _selectedType == 'IN'
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurfaceVariant)),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTokens.spacingStandard),
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedType = 'OUT'),
                              child: Container(
                                padding: const EdgeInsets.all(
                                    AppTokens.spacingStandard),
                                decoration: BoxDecoration(
                                  color: _selectedType == 'OUT'
                                      ? colorScheme.errorContainer
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.buttonBorderRadius),
                                  border: Border.all(
                                    color: _selectedType == 'OUT'
                                        ? colorScheme.error
                                        : colorScheme.outline,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(loc.cashOut,
                                    style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _selectedType == 'OUT'
                                            ? colorScheme.onErrorContainer
                                            : colorScheme.onSurfaceVariant)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.spacingMedium),

                      // Date Picker & Payment Mode row
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) => Theme(
                                      data: Theme.of(context)
                                          .copyWith(colorScheme: colorScheme),
                                      child: child!),
                                );
                                if (picked != null) {
                                  setState(() => _selectedDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(
                                    AppTokens.spacingStandard),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: colorScheme.outline),
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.buttonBorderRadius),
                                  color: colorScheme.surface,
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: AppTokens.iconSizeMedium,
                                        color: colorScheme.onSurfaceVariant),
                                    const SizedBox(
                                        width: AppTokens.spacingStandard),
                                    Expanded(
                                      child: Text(
                                        DateFormat.yMMMd(
                                                Localizations.localeOf(context)
                                                    .toString())
                                            .format(_selectedDate),
                                        style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurface),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTokens.spacingMedium),
                          Expanded(
                            child: DropdownButtonFormField<PaymentMode>(
                              value: _paymentMode,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: colorScheme.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppTokens.spacingMedium),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.buttonBorderRadius),
                                  borderSide:
                                      BorderSide(color: colorScheme.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.buttonBorderRadius),
                                  borderSide:
                                      BorderSide(color: colorScheme.outline),
                                ),
                              ),
                              items: _paymentModes
                                  .map((m) => DropdownMenuItem(
                                      value: m, child: Text(m.dbValue)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _paymentMode = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.spacingMedium),

                      // Amount, Description, Remarks
                      TextField(
                        controller: _amountCtrl,
                        decoration: InputDecoration(
                            labelText: loc.amount,
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTokens.buttonBorderRadius))),
                        keyboardType: TextInputType.number,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: AppTokens.spacingStandard),
                      TextField(
                        controller: _descCtrl,
                        decoration: InputDecoration(
                            labelText: loc.description,
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTokens.buttonBorderRadius))),
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: AppTokens.spacingStandard),
                      TextField(
                        controller: _remarksCtrl,
                        decoration: InputDecoration(
                            labelText: loc.remarks,
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTokens.buttonBorderRadius))),
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.cancel,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ),
                  const SizedBox(width: AppTokens.spacingStandard),
                  ElevatedButton(
                    onPressed: () async {
                      Money? amount;
                      try {
                        amount =
                            Money.fromRupeesString(_amountCtrl.text.trim());
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(loc.invalidAmount),
                            backgroundColor: colorScheme.error));
                        return;
                      }
                      if (amount > Money.zero &&
                          _descCtrl.text.trim().isNotEmpty) {
                        try {
                          await widget.repository.addCashEntry(
                            _descCtrl.text.trim(),
                            _selectedType,
                            amount,
                            _remarksCtrl.text.trim(),
                            paymentMode: _paymentMode.dbValue,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          widget.onSaved();
                          Navigator.pop(context);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Error saving: $e"),
                              backgroundColor: colorScheme.error));
                        }
                      } else if (_descCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(loc.descriptionRequired),
                            backgroundColor: colorScheme.error));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(loc.invalidAmount),
                            backgroundColor: colorScheme.error));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedType == 'IN'
                          ? colorScheme.primary
                          : colorScheme.error,
                      foregroundColor: _selectedType == 'IN'
                          ? colorScheme.onPrimary
                          : colorScheme.onError,
                      minimumSize: const Size(0, AppTokens.buttonHeight),
                    ),
                    child: Text(loc.save,
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
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
