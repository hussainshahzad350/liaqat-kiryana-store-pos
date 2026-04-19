import 'package:flutter/material.dart';
import '../../../../core/repositories/suppliers_repository.dart';
import '../../../../domain/entities/money.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/supplier_model.dart';
import '../../../../core/res/app_tokens.dart';

class ReceiveSupplierPaymentDialog extends StatefulWidget {
  final Supplier supplier;
  final SuppliersRepository repository;
  final VoidCallback onPaymentAdded;

  const ReceiveSupplierPaymentDialog({
    super.key,
    required this.supplier,
    required this.repository,
    required this.onPaymentAdded,
  });

  @override
  State<ReceiveSupplierPaymentDialog> createState() =>
      _ReceiveSupplierPaymentDialogState();
}

class _ReceiveSupplierPaymentDialogState
    extends State<ReceiveSupplierPaymentDialog> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;

  void _showInvalidAmountSnack() {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.invalidAmount),
        backgroundColor: colorScheme.error,
      ),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final onPaymentAdded = widget.onPaymentAdded;

    Money? amount;
    try {
      amount = Money.fromRupeesString(_amountCtrl.text);
      if (amount <= Money.zero ||
          amount.paisas > widget.supplier.outstandingBalance) {
        throw Exception();
      }
    } catch (_) {
      _showInvalidAmountSnack();
      return;
    }

    setState(() => _isSaving = true);
    final notes = _notesCtrl.text.trim();

    try {
      await widget.repository
          .addPayment(widget.supplier.id!, amount.paisas, notes);
      onPaymentAdded();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.error}: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return WillPopScope(
      onWillPop: () async => !_isSaving,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.dialogBorderRadius),
        ),
        child: Container(
          constraints: const BoxConstraints(minWidth: 400, maxWidth: 450),
          padding: const EdgeInsets.all(AppTokens.dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Make Payment to Supplier",
                      style: textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppTokens.spacingMedium),
              Text(
                loc.currentBalanceLabel,
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              Text(
                Money(widget.supplier.outstandingBalance).toString(),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: loc.amount,
                  prefixIcon:
                      Icon(Icons.monetization_on, color: colorScheme.primary),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTokens.buttonBorderRadius)),
                ),
              ),
              const SizedBox(height: AppTokens.spacingMedium),
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: loc.notesOptional,
                  prefixIcon: Icon(Icons.note, color: colorScheme.primary),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTokens.buttonBorderRadius)),
                ),
              ),
              const SizedBox(height: AppTokens.spacingLarge),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: AppTokens.spacingMedium),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? SizedBox(
                            width: AppTokens.iconSizeMedium,
                            height: AppTokens.iconSizeMedium,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: colorScheme.onPrimary),
                          )
                        : Text(loc.save),
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
