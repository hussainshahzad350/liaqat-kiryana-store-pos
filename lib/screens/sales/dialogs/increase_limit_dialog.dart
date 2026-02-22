import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/sales/sales_bloc.dart';
import '../../../bloc/sales/sales_event.dart';
import '../../../bloc/sales/sales_state.dart';
import '../../../core/constants/desktop_dimensions.dart';
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
    limitCtrl.text = widget.currentLimit.toRupeesString();
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

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(DesktopDimensions.dialogBorderRadius)),
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 450,
          maxWidth: 550,
        ),
        padding: const EdgeInsets.all(DesktopDimensions.dialogPadding),
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
            const SizedBox(height: DesktopDimensions.spacingMedium),
            Text(
              '${loc.current}: ${widget.currentLimit.toString()}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: DesktopDimensions.spacingMedium),
            TextField(
              controller: limitCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: loc.newCreditLimit,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: DesktopDimensions.spacingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.cancel),
                ),
                const SizedBox(width: DesktopDimensions.spacingMedium),
                ElevatedButton(
                  onPressed: () async {
                    Money newLimit;
                    // Check if dialog is still mounted before async operations
                    final dialogMounted = context.mounted;
                    if (!dialogMounted) return;
                    try {
                      newLimit = Money.fromRupeesString(limitCtrl.text);
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.invalidLimit)),
                      );
                      return;
                    }

                    // Capture localized strings before async call
                    final successLabel = loc.creditLimitUpdated;
                    final errorLabel = loc.error;
                    final newLimitStr = newLimit.toString();

                    try {
                      salesBloc.add(
                        CustomerCreditLimitUpdateRequested(
                          customerId: widget.customerId,
                          newLimitPaisas: newLimit.paisas,
                        ),
                      );

                      final updateResult = await salesBloc.stream.firstWhere(
                        (state) =>
                            state.creditLimitUpdateCustomerId ==
                                widget.customerId &&
                            (state.creditLimitUpdateStatus ==
                                    CreditLimitUpdateStatus.success ||
                                state.creditLimitUpdateStatus ==
                                    CreditLimitUpdateStatus.error),
                      );

                      if (!mounted) return;

                      final successMsg = '$successLabel: $newLimitStr';
                      final errorMsg = updateResult.creditLimitUpdateError ==
                              null
                          ? errorLabel
                          : '$errorLabel: ${updateResult.creditLimitUpdateError}';

                      if (updateResult.creditLimitUpdateStatus ==
                          CreditLimitUpdateStatus.success) {
                        final state = salesBloc.state;
                        final int? sid = state.selectedCustomer?.id;
                        if (sid == widget.customerId &&
                            state.selectedCustomer != null) {
                          salesBloc.add(CustomerSelected(state.selectedCustomer!
                              .copyWith(creditLimit: newLimit.paisas)));
                        }

                        // Show success message, then close dialog and call callback
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(successMsg)),
                          );
                        }

                        // Close dialog first before calling callback
                        if (context.mounted && Navigator.of(context).canPop()) {
                          Navigator.pop(context);
                        }

                        // Callback will trigger checkout payment dialog
                        widget.onLimitUpdated();
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMsg),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('$errorLabel: $e'),
                              backgroundColor: colorScheme.error),
                        );
                      }
                    }
                  },
                  child: Text(loc.updateLimit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
