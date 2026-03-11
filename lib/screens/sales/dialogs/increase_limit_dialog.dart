import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/sales/sales_bloc.dart';
import '../../../bloc/sales/sales_event.dart';
import '../../../bloc/sales/sales_state.dart';
import '../../../core/res/app_tokens.dart';
import '../../../core/utils/rtl_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/entities/money.dart';

class IncreaseLimitDialog extends StatefulWidget {
  final int customerId;
  final Money currentLimit;
  final VoidCallback onLimitUpdated;

  const IncreaseLimitDialog({
    super.key,
    required this.customerId,
    required this.currentLimit,
    required this.onLimitUpdated,
  });

  @override
  State<IncreaseLimitDialog> createState() => _IncreaseLimitDialogState();
}

class _IncreaseLimitDialogState extends State<IncreaseLimitDialog> {
  final limitCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    limitCtrl.text = widget.currentLimit.toInputString();
  }

  @override
  void dispose() {
    limitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final salesBloc = context.read<SalesBloc>();

    return BlocListener<SalesBloc, SalesState>(
      listener: (context, state) {
        if (state.creditLimitUpdateCustomerId == widget.customerId) {
          if (state.creditLimitUpdateStatus == CreditLimitUpdateStatus.success) {
             // Close dialog first
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            }
            
            // Show success snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.creditLimitUpdated),
                backgroundColor: colorScheme.primary,
              ),
            );

            // Trigger callback
            widget.onLimitUpdated();
          } else if (state.creditLimitUpdateStatus == CreditLimitUpdateStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.creditLimitUpdateError ?? loc.error),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppTokens.dialogBorderRadius)),
        child: Container(
          constraints: RTLHelper.getDialogConstraints(
            context: context,
            size: DialogSize.medium,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppTokens.dialogPadding,
            vertical: RTLHelper.isRTL(context) 
                ? AppTokens.dialogPadding + 12
                : AppTokens.dialogPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.increaseCreditLimit,
                      style: Theme.of(context).textTheme.titleLarge),
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
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${loc.current}: ${widget.currentLimit.toString()}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppTokens.spacingMedium),
                      TextField(
                        controller: limitCtrl,
                        textAlign: TextAlign.center,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: loc.newCreditLimit,
                          border: const OutlineInputBorder(),
                        ),
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
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: AppTokens.spacingMedium),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(120, 48),
                      ),
                      onPressed: () {
                        try {
                          final newLimit = Money.fromRupeesString(limitCtrl.text);
                          salesBloc.add(
                            CustomerCreditLimitUpdateRequested(
                              customerId: widget.customerId,
                              newLimitPaisas: newLimit.paisas,
                            ),
                          );
                        } catch (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.invalidLimit)),
                          );
                        }
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(loc.updateLimit),
                      ),
                    ),
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
