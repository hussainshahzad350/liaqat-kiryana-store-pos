import 'package:flutter/material.dart';
import '../../../core/res/app_tokens.dart';
import '../../../core/utils/rtl_helper.dart';
import '../../../l10n/app_localizations.dart';

// This dialog just returns true/false or the reason string.
// Or it can return logic.
// In sales_screen.dart, _cancelSale returns Future<void> and calls BLoC.
// Here we can return the reason if confirmed, or null if cancelled.

class CancelSaleDialog extends StatefulWidget {
  const CancelSaleDialog({super.key});

  @override
  State<CancelSaleDialog> createState() => _CancelSaleDialogState();
}

class _CancelSaleDialogState extends State<CancelSaleDialog> {
  final reasonCtrl = TextEditingController();

  @override
  void dispose() {
    reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppTokens.dialogBorderRadius)),
      child: Container(
        constraints: RTLHelper.getDialogConstraints(
          context: context,
          size: DialogSize.small,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppTokens.dialogPadding,
          vertical: RTLHelper.isRTL(context) 
              ? AppTokens.dialogPadding + 12
              : AppTokens.dialogPadding,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.cancelSaleTitle,
                        style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context, null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spacingMedium),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.cancelSaleMessage,
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: AppTokens.spacingMedium),
                        TextField(
                          controller: reasonCtrl,
                          textAlign: TextAlign.center,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: loc.cancelReasonLabel,
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
                      onPressed: () => Navigator.pop(context, null),
                      child: Text(loc.cancel),
                    ),
                    const SizedBox(width: AppTokens.spacingMedium),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                          minimumSize: const Size(120, 48),
                        ),
                        onPressed: reasonCtrl.text.trim().isEmpty
                            ? null
                            : () =>
                                Navigator.pop(context, reasonCtrl.text.trim()),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(loc.cancelSale),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
