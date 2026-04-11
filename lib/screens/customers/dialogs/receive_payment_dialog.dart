import 'package:flutter/material.dart';
import '../../../core/repositories/customers_repository.dart';
import '../../../domain/entities/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/customer_model.dart';
import '../../../core/res/app_tokens.dart';
import 'package:intl/intl.dart';

class ReceivePaymentDialog extends StatefulWidget {
  final Customer customer;
  final CustomersRepository repository;
  final VoidCallback onPaymentAdded;

  const ReceivePaymentDialog({
    super.key,
    required this.customer,
    required this.repository,
    required this.onPaymentAdded,
  });

  @override
  State<ReceivePaymentDialog> createState() => _ReceivePaymentDialogState();
}

class _ReceivePaymentDialogState extends State<ReceivePaymentDialog> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final amount = Money.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= Money.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.invalidAmount),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final date = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      await widget.repository.addPayment(
        widget.customer.id!,
        amount.paisas,
        date,
        _notesCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onPaymentAdded();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.dialogBorderRadius),
      ),
      child: Container(
        constraints: const BoxConstraints(minWidth: 400, maxWidth: 500),
        padding: const EdgeInsets.all(AppTokens.dialogPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.receivePaymentTitle, style: textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppTokens.spacingMedium),

            // Customer name hint
            Container(
              padding: const EdgeInsets.all(AppTokens.spacingSmall),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius:
                    BorderRadius.circular(AppTokens.buttonBorderRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.person,
                      size: AppTokens.iconSizeSmall,
                      color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: AppTokens.spacingSmall),
                  Text(
                    widget.customer.nameEnglish,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${loc.balanceShort}: ${Money(widget.customer.outstandingBalance)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTokens.spacingMedium),

            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style:
                  textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: loc.amount,
                prefixIcon: Icon(Icons.money,
                    size: AppTokens.iconSizeMedium, color: colorScheme.primary),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTokens.buttonBorderRadius),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacingMedium),
            TextField(
              controller: _notesCtrl,
              style:
                  textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: loc.notesOptionalLabel,
                prefixIcon: Icon(Icons.note,
                    size: AppTokens.iconSizeMedium, color: colorScheme.primary),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTokens.buttonBorderRadius),
                ),
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
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? SizedBox(
                          width: AppTokens.iconSizeMedium,
                          height: AppTokens.iconSizeMedium,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Text(loc.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
